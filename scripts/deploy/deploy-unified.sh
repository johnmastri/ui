#!/bin/bash

set -e

PI_ADDRESS=""
PI_USER="mastrctrl"
INSTALL=false

show_usage() {
    cat << EOF
Master Controller - Unified Deployment Script

Usage: $0 [--install] <pi-address> [pi-user]

Options:
    --install    Build UI, deploy files, and run setup on Pi
    <pi-address> IP address of Raspberry Pi (required)
    <pi-user>    SSH username (default: mastrctrl)

Examples:
    $0 192.168.1.195
    $0 --install 192.168.1.195
    $0 --install 192.168.1.195 mastrctrl

EOF
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --install)
            INSTALL=true
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            if [ -z "$PI_ADDRESS" ]; then
                PI_ADDRESS="$1"
            else
                PI_USER="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$PI_ADDRESS" ]; then
    echo "ERROR: Pi address is required"
    show_usage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
UI_DIR="$PACKAGE_DIR/ui"
PYTHON_PI_DIR="$PACKAGE_DIR/python/pi"

echo "=============================================="
echo "Master Controller - Unified Deployment"
echo "=============================================="
echo ""

echo "[1/6] Checking Pi connectivity..."
if ping -c 2 -W 2 "$PI_ADDRESS" > /dev/null 2>&1; then
    echo "  OK Pi is reachable at $PI_ADDRESS"
else
    echo "  WARNING: Cannot ping Pi, but continuing..."
fi

if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${PI_USER}@${PI_ADDRESS}" "echo 'SSH OK'" > /dev/null 2>&1; then
    echo "  OK SSH connection verified"
else
    echo "  WARNING: SSH test failed. You may need to enter password during transfer."
fi

if [ "$INSTALL" = true ]; then
    echo ""
    echo "[2/6] Building Vue UI..."
    cd "$UI_DIR"
    
    if [ ! -d "node_modules" ]; then
        echo "  Installing npm dependencies..."
        npm install
    fi
    
    echo "  Building Vue app..."
    npm run build
    
    if [ ! -d "dist" ]; then
        echo "  ERROR: Build failed - dist folder not created"
        exit 1
    fi
    
    echo "  Copying JUCE files to dist..."
    if [ -d "public/js/juce" ]; then
        mkdir -p dist/js/juce
        cp -r public/js/juce/* dist/js/juce/
    fi
    
    echo "  OK Vue UI built successfully"
else
    echo ""
    echo "[2/6] Skipping UI build (use --install to build before deploy)"
    if [ ! -d "$UI_DIR/dist" ]; then
        echo "  WARNING: dist folder not found. Run with --install flag."
    fi
fi

echo ""
echo "[3/6] Validating source directories..."
if [ ! -d "$PYTHON_PI_DIR" ]; then
    echo "  ERROR: Python server directory not found: $PYTHON_PI_DIR"
    exit 1
fi
echo "  OK Python server directory found"

if [ -d "$UI_DIR/dist" ]; then
    echo "  OK UI dist directory found"
else
    echo "  WARNING: UI dist directory not found"
fi

echo ""
echo "[4/6] Creating deployment packages..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEMP_DIR="/tmp/mastrctrl-deploy-$TIMESTAMP"
mkdir -p "$TEMP_DIR"

UI_PACKAGE_NAME=""
if [ -d "$UI_DIR/dist" ]; then
    UI_PACKAGE_NAME="mastrctrl-ui-$TIMESTAMP.zip"
    echo "  Packaging Vue UI..."
    cd "$UI_DIR/dist"
    zip -r "$TEMP_DIR/$UI_PACKAGE_NAME" . -q
    UI_SIZE=$(du -h "$TEMP_DIR/$UI_PACKAGE_NAME" | cut -f1)
    echo "    OK UI package: $UI_PACKAGE_NAME ($UI_SIZE)"
else
    echo "  Skipping UI package (dist folder not found)"
fi

PYTHON_PACKAGE_NAME="mastrctrl-python-$TIMESTAMP.zip"
echo "  Packaging Python server..."
cd "$PYTHON_PI_DIR"

EXCLUDE_PATTERNS=("*.zip" "__pycache__" "*.pyc" ".pytest_cache" "mastrctrl-updates")
ZIP_ARGS=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    ZIP_ARGS+=(-x "$pattern")
done

zip -r "$TEMP_DIR/$PYTHON_PACKAGE_NAME" . "${ZIP_ARGS[@]}" -q > /dev/null 2>&1 || {
    find . -type f ! -name "*.zip" ! -path "*/__pycache__/*" ! -path "*/.pytest_cache/*" ! -path "*/mastrctrl-updates/*" | \
    zip -r "$TEMP_DIR/$PYTHON_PACKAGE_NAME" -@ -q
}

PYTHON_SIZE=$(du -h "$TEMP_DIR/$PYTHON_PACKAGE_NAME" | cut -f1)
echo "    OK Python package: $PYTHON_PACKAGE_NAME ($PYTHON_SIZE)"

echo ""
echo "[5/6] Transferring packages to Pi..."
if [ -n "$UI_PACKAGE_NAME" ]; then
    echo "  Copying UI package..."
    scp -o StrictHostKeyChecking=no "$TEMP_DIR/$UI_PACKAGE_NAME" "${PI_USER}@${PI_ADDRESS}:~/" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "    OK UI package transferred"
    else
        echo "    ERROR: Failed to copy UI package"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

echo "  Copying Python package..."
scp -o StrictHostKeyChecking=no "$TEMP_DIR/$PYTHON_PACKAGE_NAME" "${PI_USER}@${PI_ADDRESS}:~/" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "    OK Python package transferred"
else
    echo "    ERROR: Failed to copy Python package"
    echo "    Make sure SSH key authentication is set up or you can enter password."
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo ""
echo "[6/6] Extracting files on Pi..."
EXTRACT_SCRIPT="
set -e
mkdir -p ~/mastrctrl/ui
mkdir -p ~/mastrctrl/package/python/pi

if [ -f ~/$UI_PACKAGE_NAME ]; then
    echo '  Extracting UI package...'
    cd ~/mastrctrl/ui
    unzip -o ~/$UI_PACKAGE_NAME 2>&1 | grep -v 'backslashes' || true
    EXIT_CODE=$?
    rm ~/$UI_PACKAGE_NAME
    if [ $EXIT_CODE -eq 0 ] || [ $EXIT_CODE -eq 1 ]; then
        echo '    OK UI files extracted'
    else
        echo '    ERROR: Extraction failed'
        exit 1
    fi
fi

if [ -f ~/$PYTHON_PACKAGE_NAME ]; then
    echo '  Extracting Python package...'
    cd ~/mastrctrl/package/python/pi
    unzip -o ~/$PYTHON_PACKAGE_NAME 2>&1 | grep -v 'backslashes' || true
    EXIT_CODE=$?
    rm ~/$PYTHON_PACKAGE_NAME
    if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 1 ]; then
        echo '    ERROR: Extraction failed'
        exit 1
    fi
    
    echo '  Fixing permissions...'
    find . -type f -name '*.sh' -exec chmod +x {} \;
    find . -type f -name '*.py' -exec chmod +x {} \;
    
    echo '  Fixing line endings...'
    find . -type f -name '*.sh' -exec sed -i 's/\r$//' {} \;
    
    echo '    OK Python files extracted'
fi
"

ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_ADDRESS}" "$EXTRACT_SCRIPT" 2>&1 | sed 's/^/  /'
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "  ERROR: Extraction failed"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "  OK Files extracted successfully"

if [ "$INSTALL" = true ]; then
    echo ""
    echo "[7/7] Running setup on Pi..."
    
    SETUP_SCRIPT="
cd ~/mastrctrl/package/python/pi

echo '  Installing dependencies...'
if [ -f setup/install_dependencies.sh ]; then
    bash setup/install_dependencies.sh
else
    echo '    WARNING: install_dependencies.sh not found'
fi

echo '  Checking USB gadget configuration...'
if ip addr show usb0 2>/dev/null | grep -q '192.168.4.1'; then
    echo '    OK USB gadget already configured'
elif [ -f setup/configure_usb_gadget_modern.sh ]; then
    echo '    Configuring USB gadget (requires reboot)...'
    echo 'n' | sudo bash setup/configure_usb_gadget_modern.sh
    echo '    WARNING: Reboot required for USB gadget to work'
else
    echo '    WARNING: USB gadget setup script not found'
fi

echo '  Installing systemd service...'
if [ -f setup/systemd/mastrctrl-pi.service ]; then
    sudo cp setup/systemd/mastrctrl-pi.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable mastrctrl-pi.service
    echo '    OK Service installed and enabled'
else
    echo '    WARNING: mastrctrl-pi.service not found'
fi

if [ -f setup/systemd/usb-gadget.service ]; then
    sudo cp setup/systemd/usb-gadget.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable usb-gadget.service
    echo '    OK USB gadget service installed and enabled'
fi

echo '  OK Setup complete'
"
    
    ssh -o StrictHostKeyChecking=no "${PI_USER}@${PI_ADDRESS}" "$SETUP_SCRIPT" 2>&1 | sed 's/^/  /'
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "  WARNING: Some setup steps may have failed"
    else
        echo "  OK Setup completed successfully"
    fi
fi

echo ""
echo "=============================================="
echo "Deployment Complete!"
echo "=============================================="
echo ""
echo "Files deployed to:"
if [ -n "$UI_PACKAGE_NAME" ]; then
    echo "  UI: ~/mastrctrl/ui/"
fi
echo "  Python: ~/mastrctrl/package/python/pi/"
echo ""

if [ "$INSTALL" = true ]; then
    echo "To start the controller:"
    echo "  ssh ${PI_USER}@${PI_ADDRESS}"
    echo "  cd ~/mastrctrl/package/python/pi"
    echo "  python3 main.py"
    echo ""
    echo "Or use systemd service:"
    echo "  ssh ${PI_USER}@${PI_ADDRESS} sudo systemctl start mastrctrl-pi.service"
else
    echo "Run with --install flag to install dependencies and configure services."
fi

rm -rf "$TEMP_DIR"

