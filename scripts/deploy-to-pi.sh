#!/bin/bash

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <pi-ip-address> [pi-user]"
    echo "Example: $0 192.168.1.195 mastrctrl"
    exit 1
fi

PI_ADDRESS=$1
PI_USER=${2:-mastrctrl}

echo "=============================================="
echo "Master Controller - Raspberry Pi Deployment"
echo "=============================================="
echo ""

echo "[1/8] Checking Pi connectivity..."
if ping -c 2 $PI_ADDRESS > /dev/null 2>&1; then
    echo "  ✓ Pi is reachable at $PI_ADDRESS"
else
    echo "  ✗ ERROR: Cannot reach Pi at $PI_ADDRESS"
    exit 1
fi

echo ""
echo "[2/8] Creating deployment package..."
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PACKAGE_NAME="mastrctrl-pi-$TIMESTAMP.zip"
TEMP_ZIP="/tmp/$PACKAGE_NAME"

cd "$(dirname "$0")/.."
zip -r "$TEMP_ZIP" python/pi/ -q

if [ -f "$TEMP_ZIP" ]; then
    echo "  ✓ Package created: $PACKAGE_NAME"
else
    echo "  ✗ ERROR: Failed to create package"
    exit 1
fi

echo ""
echo "[3/8] Copying package to Pi..."
scp "$TEMP_ZIP" "${PI_USER}@${PI_ADDRESS}:~/" || {
    echo "  ✗ ERROR: Failed to copy package"
    exit 1
}
echo "  ✓ Package copied to Pi"

echo ""
echo "[4/8] Extracting files on Pi..."
ssh "${PI_USER}@${PI_ADDRESS}" << 'EOF'
mkdir -p ~/mastrctrl/package/python/pi
cd ~/mastrctrl/package/python/pi
unzip -o ~/$PACKAGE_NAME
rm ~/$PACKAGE_NAME
chmod +x setup/*.sh tests/*.py main.py
EOF
echo "  ✓ Files extracted"

echo ""
read -p "Install dependencies and configure system? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "[5/8] Installing dependencies..."
    ssh "${PI_USER}@${PI_ADDRESS}" "cd ~/mastrctrl/package/python/pi && bash setup/install_dependencies.sh"
    echo "  ✓ Dependencies installed"
    
    echo ""
    echo "[6/8] Configuring USB gadget mode..."
    read -p "Configure USB gadget mode? (requires sudo and reboot) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh "${PI_USER}@${PI_ADDRESS}" "cd ~/mastrctrl/package/python/pi && echo 'n' | sudo bash setup/usb_gadget_setup.sh"
        echo "  ✓ USB gadget configured (reboot required)"
    else
        echo "  ⊘ Skipped USB gadget configuration"
    fi
    
    echo ""
    echo "[7/8] Installing systemd service..."
    read -p "Install systemd service for auto-start? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ssh "${PI_USER}@${PI_ADDRESS}" << 'EOF'
cd ~/mastrctrl/package/python/pi
sudo cp setup/systemd/mastrctrl-pi.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mastrctrl-pi.service
EOF
        echo "  ✓ Service installed and enabled"
    else
        echo "  ⊘ Skipped service installation"
    fi
    
    echo ""
    echo "[8/8] Starting controller..."
    read -p "Start controller now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh "${PI_USER}@${PI_ADDRESS}" "sudo systemctl start mastrctrl-pi.service"
            echo "  ✓ Service started"
        else
            echo "  Starting manually (Ctrl+C to stop)..."
            ssh "${PI_USER}@${PI_ADDRESS}" "cd ~/mastrctrl/package/python/pi && python3 main.py"
        fi
    fi
else
    echo ""
    echo "[5-8] Skipped automatic setup"
fi

echo ""
echo "=============================================="
echo "Deployment Complete!"
echo "=============================================="
echo ""
echo "Files installed to: ~/mastrctrl/package/python/pi"
echo ""
echo "Next steps:"
echo "  1. Connect Pi USB-C to computer"
echo "  2. Pi will appear as USB Ethernet device"
echo "  3. Connect to: ws://192.168.4.1:8765"
echo ""
echo "Manual commands:"
echo "  ssh ${PI_USER}@${PI_ADDRESS}"
echo "  cd ~/mastrctrl/package/python/pi"
echo "  python3 tests/test_leds.py     # Test LEDs"
echo "  python3 main.py                # Run controller"
echo "  sudo systemctl status mastrctrl-pi.service  # Check status"
echo ""

rm -f "$TEMP_ZIP"

