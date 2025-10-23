#!/bin/bash

set -e

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script is in package/scripts/deploy/, so go up two levels to get package/
PACKAGE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

show_usage() {
    cat << EOF
Master Controller - Unified Deployment Script v${VERSION}

Usage: $0 [FLAG] <pi-address> [pi-user]

Flags:
    --verify        Check current Pi configuration status
    --update        Copy code files to Pi (no configuration)
    --install       Complete setup (idempotent, safe to re-run)
    --run          Start controller with existing code

Arguments:
    pi-address      IP address of Raspberry Pi
    pi-user         SSH username (default: mastrctrl)

Examples:
    $0 --install 192.168.1.195 mastrctrl
    $0 --update 192.168.4.1
    $0 --run 192.168.4.1
    $0 --verify 192.168.1.195

EOF
    exit 1
}

verify_config() {
    local PI_ADDRESS=$1
    local PI_USER=$2
    
    echo "=============================================="
    echo "Verifying Pi Configuration"
    echo "=============================================="
    echo ""
    
    ssh "${PI_USER}@${PI_ADDRESS}" 'bash -s' << 'VERIFY_SCRIPT'
        echo "=== BOOT CONFIG ==="
        sudo grep -E "dtoverlay=dwc2|otg_mode" /boot/firmware/config.txt 2>/dev/null || \
            sudo grep -E "dtoverlay=dwc2|otg_mode" /boot/config.txt
        
        echo -e "\n=== UDC AVAILABLE ==="
        if ls /sys/class/udc/ 2>/dev/null | grep -q .; then
            echo "✓ UDC available: $(ls /sys/class/udc/)"
        else
            echo "✗ No UDC found"
        fi
        
        echo -e "\n=== MODULES LOADED ==="
        if lsmod | grep -q libcomposite; then
            echo "✓ libcomposite loaded"
        else
            echo "✗ libcomposite NOT loaded"
            echo "  Try: sudo modprobe libcomposite"
        fi
        
        echo -e "\n=== USB0 INTERFACE ==="
        if ip addr show usb0 &>/dev/null; then
            echo "✓ usb0 exists:"
            ip addr show usb0 | grep "inet "
        else
            echo "✗ usb0 does NOT exist"
            echo "  USB gadget may not be configured yet"
        fi
        
        echo -e "\n=== CONFIGFS GADGET ==="
        if [ -d /sys/kernel/config/usb_gadget/pi4 ]; then
            echo "✓ Gadget configured"
            UDC_BOUND=$(cat /sys/kernel/config/usb_gadget/pi4/UDC 2>/dev/null)
            if [ -n "$UDC_BOUND" ]; then
                echo "✓ Bound to UDC: $UDC_BOUND"
            else
                echo "⚠ Gadget exists but not bound to UDC"
            fi
        else
            echo "✗ No configfs gadget found"
            echo "  Run: sudo /usr/local/bin/usb-gadget-setup.sh"
        fi
        
        echo -e "\n=== SERVICES ==="
        if systemctl is-active --quiet usb-gadget.service 2>/dev/null; then
            echo "✓ usb-gadget.service is active"
        elif systemctl is-enabled --quiet usb-gadget.service 2>/dev/null; then
            echo "⚠ usb-gadget.service is enabled but not active"
            echo "  Try: sudo systemctl start usb-gadget.service"
        else
            echo "✗ usb-gadget.service not found or disabled"
            echo "  Service was not installed during setup"
        fi
        
        if systemctl is-active --quiet dnsmasq.service 2>/dev/null; then
            echo "✓ dnsmasq.service is active"
        else
            echo "✗ dnsmasq.service not active"
            if ! command -v dnsmasq &> /dev/null; then
                echo "  dnsmasq not installed"
            fi
        fi
        
        if systemctl is-active --quiet mastrctrl-pi.service 2>/dev/null; then
            echo "✓ mastrctrl-pi.service is active"
        elif systemctl is-enabled --quiet mastrctrl-pi.service 2>/dev/null; then
            echo "⚠ mastrctrl-pi.service is enabled but not active"
            echo "  Try: sudo systemctl start mastrctrl-pi.service"
        else
            echo "✗ mastrctrl-pi.service not found or disabled"
        fi
        
        echo -e "\n=== RUNTIME SCRIPTS ==="
        if [ -f /usr/local/bin/usb-gadget-setup.sh ]; then
            echo "✓ USB gadget runtime script installed"
            # Check for line ending issues
            if head -1 /usr/local/bin/usb-gadget-setup.sh | od -c | grep -q '\\r'; then
                echo "  ⚠ WARNING: Script has Windows line endings (CRLF)"
                echo "  Fix: sudo sed -i 's/\r$//' /usr/local/bin/usb-gadget-setup.sh"
            fi
        else
            echo "✗ USB gadget runtime script MISSING"
        fi
        
        echo -e "\n=== CODE FILES ==="
        if [ -f ~/mastrctrl/package/python/pi/main.py ]; then
            echo "✓ Controller code installed"
        else
            echo "✗ Controller code NOT found"
        fi
        
        echo -e "\n=== QUICK FIX SUGGESTIONS ==="
        NEEDS_FIX=false
        
        if ! lsmod | grep -q libcomposite; then
            echo "• Load kernel module: sudo modprobe libcomposite"
            NEEDS_FIX=true
        fi
        
        if [ ! -d /sys/kernel/config/usb_gadget/pi4 ] && [ -f /usr/local/bin/usb-gadget-setup.sh ]; then
            echo "• Setup USB gadget: sudo /usr/local/bin/usb-gadget-setup.sh"
            NEEDS_FIX=true
        fi
        
        if ! systemctl is-active --quiet usb-gadget.service 2>/dev/null && systemctl is-enabled --quiet usb-gadget.service 2>/dev/null; then
            echo "• Start service: sudo systemctl start usb-gadget.service"
            NEEDS_FIX=true
        fi
        
        if [ "$NEEDS_FIX" = false ]; then
            echo "No immediate fixes needed. Check specific items above."
        fi
VERIFY_SCRIPT
    
    echo ""
    echo "=============================================="
}

update_files() {
    local PI_ADDRESS=$1
    local PI_USER=$2
    
    echo "=============================================="
    echo "Updating Code Files on Pi"
    echo "=============================================="
    echo ""
    
    echo "[1/4] Creating deployment package..."
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    PACKAGE_NAME="mastrctrl-pi-$TIMESTAMP.zip"
    
    # Check if running on Windows (check for powershell.exe availability)
    if command -v powershell.exe &> /dev/null; then
        # Windows (Git Bash/WSL): Use PowerShell Compress-Archive
        TEMP_ZIP="$PACKAGE_DIR/python/pi/$PACKAGE_NAME"
        cd "$PACKAGE_DIR/python/pi"
        powershell.exe -Command "Compress-Archive -Path * -DestinationPath '$PACKAGE_NAME' -Force"
        if [ $? -ne 0 ]; then
            echo "  ✗ ERROR: PowerShell compress failed"
            exit 1
        fi
    elif command -v zip &> /dev/null; then
        # Linux/Mac: Use zip
        TEMP_ZIP="/tmp/$PACKAGE_NAME"
        cd "$PACKAGE_DIR"
        zip -r "$TEMP_ZIP" python/pi/ -q
        if [ $? -ne 0 ]; then
            echo "  ✗ ERROR: zip command failed"
            exit 1
        fi
    else
        echo "  ✗ ERROR: Neither PowerShell nor zip command found"
        echo "  On Windows: PowerShell should be available"
        echo "  On Linux: Install zip with 'sudo apt install zip'"
        exit 1
    fi
    
    if [ ! -f "$TEMP_ZIP" ]; then
        echo "  ✗ ERROR: Package file not created at $TEMP_ZIP"
        exit 1
    fi
    
    ZIP_SIZE=$(du -h "$TEMP_ZIP" 2>/dev/null | cut -f1)
    if [ -z "$ZIP_SIZE" ]; then
        ZIP_SIZE=$(stat -c%s "$TEMP_ZIP" 2>/dev/null || echo "unknown size")
    fi
    echo "  ✓ Package created: $PACKAGE_NAME ($ZIP_SIZE)"
    
    echo ""
    echo "[2/4] Copying to Pi..."
    scp "$TEMP_ZIP" "${PI_USER}@${PI_ADDRESS}:~/"
    echo "  ✓ Package copied"
    
    echo ""
    echo "[3/4] Extracting on Pi..."
    ssh "${PI_USER}@${PI_ADDRESS}" << EXTRACT_EOF
        PACKAGE_NAME="$PACKAGE_NAME"
        mkdir -p ~/mastrctrl/package/python/pi
        cd ~/mastrctrl/package/python/pi
        unzip -o ~/$PACKAGE_NAME
        rm ~/$PACKAGE_NAME
        
        # Fix line endings for all shell scripts (Windows -> Unix)
        echo "  → Fixing line endings..."
        find . -type f -name '*.sh' -exec sed -i 's/\r$//' {} \;
        
        # Make scripts executable
        find . -type f -name '*.sh' -exec chmod +x {} \;
        find . -type f -name '*.py' -exec chmod +x {} \;
        
        echo "  ✓ Files extracted and line endings fixed"
EXTRACT_EOF
    
    echo ""
    echo "[4/4] Cleaning up..."
    rm -f "$TEMP_ZIP"
    echo "  ✓ Temp files removed"
    
    echo ""
    echo "=============================================="
    echo "Code Update Complete!"
    echo "=============================================="
}

install_full() {
    local PI_ADDRESS=$1
    local PI_USER=$2
    
    echo "=============================================="
    echo "Full Installation"
    echo "=============================================="
    echo ""
    
    update_files "$PI_ADDRESS" "$PI_USER"
    
    echo ""
    echo "=========================================="
    echo "Checking and Installing Dependencies"
    echo "=========================================="
    
    ssh "${PI_USER}@${PI_ADDRESS}" 'bash -s' << 'EOF'
        NEED_DEPS=false
        
        if ! command -v i2cdetect &> /dev/null; then
            echo "  → i2c-tools not found"
            NEED_DEPS=true
        fi
        
        if ! pip3 list 2>/dev/null | grep -q websockets; then
            echo "  → Python packages not installed"
            NEED_DEPS=true
        fi
        
        if [ "$NEED_DEPS" = true ]; then
            echo "  Installing dependencies..."
            cd ~/mastrctrl/package/python/pi
            
            # Fix line endings BEFORE running the script
            sed -i 's/\r$//' setup/install_dependencies.sh 2>/dev/null
            chmod +x setup/install_dependencies.sh
            
            bash setup/install_dependencies.sh
        else
            echo "  ✓ Dependencies already installed"
        fi
EOF
    
    echo ""
    echo "=========================================="
    echo "Checking and Configuring USB Gadget"
    echo "=========================================="
    
    ssh "${PI_USER}@${PI_ADDRESS}" 'bash -s' << 'EOF'
        BOOT_CONFIG="/boot/firmware/config.txt"
        if [ ! -f "$BOOT_CONFIG" ]; then
            BOOT_CONFIG="/boot/config.txt"
        fi
        
        NEEDS_CONFIG=false
        
        # Check boot config
        if ! sudo grep -q "^dtoverlay=dwc2" "$BOOT_CONFIG"; then
            echo "  → Boot config needs update"
            NEEDS_CONFIG=true
        fi
        
        # Check runtime script
        if [ ! -f /usr/local/bin/usb-gadget-setup.sh ]; then
            echo "  → USB runtime script not installed"
            NEEDS_CONFIG=true
        fi
        
        # Check if service is installed
        if ! systemctl list-unit-files | grep -q usb-gadget.service; then
            echo "  → USB gadget service not installed"
            NEEDS_CONFIG=true
        fi
        
        # Check if dnsmasq is installed and configured
        if ! command -v dnsmasq &> /dev/null; then
            echo "  → dnsmasq not installed"
            NEEDS_CONFIG=true
        elif [ ! -f /etc/dnsmasq.d/usb-gadget.conf ]; then
            echo "  → dnsmasq USB config not found"
            NEEDS_CONFIG=true
        fi
        
        if [ "$NEEDS_CONFIG" = true ]; then
            echo "  Configuring USB gadget (boot + runtime + services)..."
            cd ~/mastrctrl/package/python/pi/setup
            
            # Ensure ALL scripts have correct line endings (critical for setup)
            echo "  → Fixing line endings on all scripts..."
            find ~/mastrctrl/package/python/pi -type f -name '*.sh' -exec sed -i 's/\r$//' {} \; 2>/dev/null
            find ~/mastrctrl/package/python/pi -type f -name '*.sh' -exec chmod +x {} \; 2>/dev/null
            
            # Run the configuration script and capture output
            echo "  → Running USB gadget configuration..."
            CONFIG_OUTPUT=$(echo "n" | sudo bash configure_usb_gadget_modern.sh 2>&1)
            CONFIG_EXIT=$?
            
            # Show output for debugging
            echo "$CONFIG_OUTPUT"
            
            if [ $CONFIG_EXIT -eq 0 ]; then
                echo "USB_CONFIGURED"
            else
                echo "USB_CONFIG_FAILED"
                echo "Exit code: $CONFIG_EXIT"
            fi
        else
            echo "  ✓ USB gadget configuration complete"
            
            # Even if configured, make sure services are enabled and running
            # First, ensure system scripts don't have line ending issues
            if [ -f /usr/local/bin/usb-gadget-setup.sh ]; then
                sudo sed -i 's/\r$//' /usr/local/bin/usb-gadget-setup.sh 2>/dev/null
            fi
            
            if ! systemctl is-enabled --quiet usb-gadget.service 2>/dev/null; then
                echo "  → Enabling USB gadget service..."
                sudo systemctl enable usb-gadget.service
            fi
            
            if ! systemctl is-active --quiet usb-gadget.service; then
                echo "  → Starting USB gadget service..."
                sudo systemctl start usb-gadget.service 2>/dev/null
                sleep 3
                
                # If service failed, try running the setup script manually
                if ! systemctl is-active --quiet usb-gadget.service; then
                    echo "  → Service failed to start, running setup script manually..."
                    sudo /usr/local/bin/usb-gadget-setup.sh 2>/dev/null || echo "  ⚠ Manual run also failed"
                    sleep 2
                fi
            fi
            
            if ! systemctl is-enabled --quiet dnsmasq.service 2>/dev/null; then
                echo "  → Enabling dnsmasq service..."
                sudo systemctl enable dnsmasq.service
            fi
            
            if ! systemctl is-active --quiet dnsmasq.service; then
                echo "  → Starting dnsmasq service..."
                sudo systemctl restart dnsmasq.service 2>/dev/null || echo "  ⚠ dnsmasq start failed"
            fi
            
            # Verify usb0 is up
            if ip addr show usb0 &>/dev/null; then
                echo "  ✓ usb0 interface is up"
                ip addr show usb0 | grep "inet " | awk '{print "    IP:", $2}'
            else
                echo "  ⚠ usb0 not up - checking what went wrong..."
                
                # Check if libcomposite loaded
                if ! lsmod | grep -q libcomposite; then
                    echo "  ✗ libcomposite module not loaded"
                    echo "  → Trying to load libcomposite..."
                    sudo modprobe libcomposite 2>/dev/null || echo "  ✗ Failed to load libcomposite"
                fi
                
                # Check if configfs gadget exists
                if [ ! -d /sys/kernel/config/usb_gadget/pi4 ]; then
                    echo "  ✗ Configfs gadget not created"
                    echo "  → Fixing line endings on setup script..."
                    sudo sed -i 's/\r$//' /usr/local/bin/usb-gadget-setup.sh 2>/dev/null
                    echo "  → Running USB gadget setup script..."
                    sudo /usr/local/bin/usb-gadget-setup.sh 2>/dev/null || echo "  ✗ Setup script failed"
                    sleep 2
                fi
                
                # Final check
                if ip addr show usb0 &>/dev/null; then
                    echo "  ✓ usb0 is now up!"
                    ip addr show usb0 | grep "inet " | awk '{print "    IP:", $2}'
                else
                    echo "  ✗ usb0 still not up - reboot required"
                    echo "NEEDS_REBOOT"
                fi
            fi
        fi
EOF
    
    # Check if configuration failed or reboot is needed
    CONFIG_RESULT=$(ssh "${PI_USER}@${PI_ADDRESS}" 'bash -s' << 'EOF' 2>&1 | grep -E "USB_CONFIGURED|USB_CONFIG_FAILED|NEEDS_REBOOT"
        if [ ! -f /sys/class/udc/*/state ] && [ ! -d /sys/kernel/config/usb_gadget/pi4 ]; then
            echo "NEEDS_REBOOT"
        fi
EOF
    )
    
    if echo "$CONFIG_RESULT" | grep -q "USB_CONFIG_FAILED"; then
        echo ""
        echo "⚠ Initial USB gadget setup encountered an error"
        echo "→ Applying comprehensive fixes and retrying..."
        echo ""
        
        RETRY_SUCCESS=$(ssh "${PI_USER}@${PI_ADDRESS}" 'bash -s' << 'RECOVERY_SCRIPT'
            # Comprehensive line ending fix on ALL files
            find ~/mastrctrl/package/python/pi -type f -name '*.sh' -exec sed -i 's/\r$//' {} \; 2>/dev/null
            find ~/mastrctrl/package/python/pi -type f -name '*.sh' -exec chmod +x {} \; 2>/dev/null
            
            # Fix any system-installed scripts
            if [ -f /usr/local/bin/usb-gadget-setup.sh ]; then
                sudo sed -i 's/\r$//' /usr/local/bin/usb-gadget-setup.sh 2>/dev/null
            fi
            
            # Load kernel module if needed
            if ! lsmod | grep -q libcomposite; then
                sudo modprobe libcomposite 2>/dev/null
            fi
            
            # Retry USB gadget configuration
            cd ~/mastrctrl/package/python/pi/setup
            CONFIG_OUTPUT=$(echo "n" | sudo bash configure_usb_gadget_modern.sh 2>&1)
            CONFIG_EXIT=$?
            
            # Show output for debugging
            echo "$CONFIG_OUTPUT"
            
            if [ $CONFIG_EXIT -eq 0 ]; then
                echo "RETRY_SUCCESS"
            else
                echo "RETRY_FAILED"
                echo "Exit code: $CONFIG_EXIT"
            fi
RECOVERY_SCRIPT
        )
        
        if echo "$RETRY_SUCCESS" | grep -q "RETRY_SUCCESS"; then
            echo "  ✓ Automatic recovery succeeded!"
            CONFIG_RESULT="USB_CONFIGURED"
        else
            echo ""
            echo "=============================================="
            echo "✗ Installation Failed"
            echo "=============================================="
            echo ""
            echo "The USB gadget setup could not complete successfully."
            echo "Please report this issue with the error messages above."
            echo ""
            exit 1
        fi
    fi
    
    echo ""
    echo "=========================================="
    echo "Checking and Installing Services"
    echo "=========================================="
    
    ssh "${PI_USER}@${PI_ADDRESS}" 'bash -s' << 'EOF'
        if ! systemctl list-unit-files | grep -q mastrctrl-pi.service; then
            echo "  Installing controller service..."
            cd ~/mastrctrl/package/python/pi
            if [ -f setup/systemd/mastrctrl-pi.service ]; then
                sudo cp setup/systemd/mastrctrl-pi.service /etc/systemd/system/
                sudo systemctl daemon-reload
                sudo systemctl enable mastrctrl-pi.service
                echo "  ✓ Controller service installed"
            fi
        else
            echo "  ✓ Controller service already installed"
        fi
EOF
    
    echo ""
    echo "=============================================="
    echo "Installation Complete!"
    echo "=============================================="
    echo ""
    
    NEEDS_REBOOT=false
    if echo "$CONFIG_RESULT" | grep -q -E "USB_CONFIGURED|NEEDS_REBOOT"; then
        NEEDS_REBOOT=true
    fi
    
    if [ "$NEEDS_REBOOT" = true ]; then
        echo "IMPORTANT: System needs a reboot for USB gadget to work properly"
        echo ""
        read -p "Reboot Pi now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ssh "${PI_USER}@${PI_ADDRESS}" "sudo reboot"
            echo "✓ Pi is rebooting..."
            echo ""
            echo "After reboot (~30 seconds):"
            echo "  1. Wait for Pi to fully boot"
            echo "  2. Verify: bash deploy.sh --verify ${PI_ADDRESS} ${PI_USER}"
            echo "  3. If verify passes, plug USB-C cable to access at 192.168.4.1"
        else
            echo "Reboot skipped. Run manually:"
            echo "  ssh ${PI_USER}@${PI_ADDRESS} sudo reboot"
            echo ""
            echo "After reboot, verify with:"
            echo "  bash deploy.sh --verify ${PI_ADDRESS} ${PI_USER}"
        fi
    else
        echo "✅ All systems operational!"
        echo ""
        echo "USB Gadget Status:"
        ssh "${PI_USER}@${PI_ADDRESS}" 'ip addr show usb0 2>/dev/null | grep "inet " || echo "  usb0 not configured yet"'
        echo ""
        echo "Next steps:"
        echo "  1. Verify everything: bash deploy.sh --verify ${PI_ADDRESS} ${PI_USER}"
        echo "  2. Start controller: bash deploy.sh --run ${PI_ADDRESS} ${PI_USER}"
        echo "  3. Or use systemd: ssh ${PI_USER}@${PI_ADDRESS} sudo systemctl start mastrctrl-pi.service"
    fi
}

run_controller() {
    local PI_ADDRESS=$1
    local PI_USER=$2
    
    echo "=============================================="
    echo "Starting Controller"
    echo "=============================================="
    echo ""
    echo "Connecting to Pi and starting controller..."
    echo "(Press Ctrl+C to stop)"
    echo ""
    
    ssh "${PI_USER}@${PI_ADDRESS}" "cd ~/mastrctrl/package/python/pi && bash start_controller.sh"
}

MODE=""
PI_ADDRESS=""
PI_USER=""
USER_SET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verify|--update|--install|--run)
            MODE="${1#--}"
            shift
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            if [ -z "$PI_ADDRESS" ]; then
                PI_ADDRESS="$1"
            elif [ "$USER_SET" = false ]; then
                PI_USER="$1"
                USER_SET=true
            else
                echo "Error: Unknown argument: $1"
                show_usage
            fi
            shift
            ;;
    esac
done

if [ -z "$PI_USER" ]; then
    PI_USER="mastrctrl"
fi

if [ -z "$MODE" ] || [ -z "$PI_ADDRESS" ]; then
    show_usage
fi

echo "Master Controller Deployment v${VERSION}"
echo "Target: ${PI_USER}@${PI_ADDRESS}"
echo "Mode: $MODE"
echo ""

case $MODE in
    verify)
        verify_config "$PI_ADDRESS" "$PI_USER"
        ;;
    update)
        update_files "$PI_ADDRESS" "$PI_USER"
        ;;
    install)
        install_full "$PI_ADDRESS" "$PI_USER"
        ;;
    run)
        run_controller "$PI_ADDRESS" "$PI_USER"
        ;;
    *)
        echo "Error: Invalid mode: $MODE"
        show_usage
        ;;
esac

