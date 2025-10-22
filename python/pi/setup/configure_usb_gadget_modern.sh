#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)"
  exit 1
fi

echo "=============================================="
echo "USB Gadget Mode Setup for Raspberry Pi 4B"
echo "Modern Kernel (6.x+) with configfs"
echo "=============================================="
echo ""

BOOT_CONFIG="/boot/firmware/config.txt"
BOOT_CMDLINE="/boot/firmware/cmdline.txt"

if [ ! -f "$BOOT_CONFIG" ]; then
    BOOT_CONFIG="/boot/config.txt"
    BOOT_CMDLINE="/boot/cmdline.txt"
fi

echo "Using boot files:"
echo "  Config: $BOOT_CONFIG"
echo "  Cmdline: $BOOT_CMDLINE"
echo ""

echo "[1/8] Backing up original config files..."
cp $BOOT_CONFIG ${BOOT_CONFIG}.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
cp $BOOT_CMDLINE ${BOOT_CMDLINE}.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null
echo "  ✓ Backups created"

echo "[2/8] Configuring $BOOT_CONFIG..."
if grep -q "^dtoverlay=dwc2" $BOOT_CONFIG; then
    sed -i 's/^dtoverlay=dwc2.*/dtoverlay=dwc2/' $BOOT_CONFIG
    echo "  ✓ Updated dtoverlay=dwc2"
else
    if ! grep -q "dtoverlay=dwc2" $BOOT_CONFIG; then
        sed -i '/^\[all\]/a dtoverlay=dwc2' $BOOT_CONFIG
        echo "  ✓ Added dtoverlay=dwc2"
    fi
fi

if grep -q "^otg_mode=1" $BOOT_CONFIG; then
    sed -i 's/^otg_mode=1/otg_mode=0/' $BOOT_CONFIG
    echo "  ✓ Changed otg_mode to 0"
fi

if ! grep -q "^otg_mode=0" $BOOT_CONFIG; then
    sed -i '/^\[all\]/a otg_mode=0' $BOOT_CONFIG
    echo "  ✓ Added otg_mode=0"
fi

echo "[3/8] Blacklisting dwc_otg (conflicts with dwc2)..."
echo "blacklist dwc_otg" > /etc/modprobe.d/blacklist-dwc_otg.conf
echo "  ✓ Created blacklist"

echo "[4/8] Installing dnsmasq for DHCP..."
if ! command -v dnsmasq &> /dev/null; then
    apt-get update -qq
    apt-get install -y dnsmasq
    echo "  ✓ dnsmasq installed"
else
    echo "  ✓ dnsmasq already installed"
fi

echo "[5/8] Configuring dnsmasq for USB gadget..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp "$SCRIPT_DIR/dnsmasq-usb-gadget.conf" /etc/dnsmasq.d/usb-gadget.conf
echo "  ✓ dnsmasq configuration created"

echo "[6/8] Installing USB gadget startup script..."
cp "$SCRIPT_DIR/usb_gadget_configfs.sh" /usr/local/bin/usb-gadget-setup.sh
chmod +x /usr/local/bin/usb-gadget-setup.sh
echo "  ✓ Startup script installed"

echo "[7/8] Installing systemd service..."
cp "$SCRIPT_DIR/systemd/usb-gadget.service" /etc/systemd/system/usb-gadget.service
systemctl daemon-reload
systemctl enable usb-gadget.service
systemctl enable dnsmasq.service
echo "  ✓ Services enabled"

echo "[8/8] Removing old /etc/modules entries..."
sed -i '/^dwc2$/d' /etc/modules
sed -i '/^g_ether$/d' /etc/modules
echo "  ✓ Cleaned up"

echo ""
echo "=============================================="
echo "USB Gadget Mode Configuration Complete!"
echo "=============================================="
echo ""
echo "IMPORTANT: You must REBOOT for changes to take effect"
echo ""
echo "After reboot:"
echo "  1. Connect Pi USB-C port to Windows computer"
echo "  2. Windows will auto-detect USB Ethernet device"
echo "  3. Windows will auto-configure via DHCP"
echo "  4. Pi will be accessible at: 192.168.4.1"
echo "  5. WebSocket: ws://192.168.4.1:8765"
echo ""
echo "Truly plug-and-play - no manual Windows configuration needed!"
echo ""
echo "Reboot now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    reboot
else
    echo "Reboot skipped. Run 'sudo reboot' when ready."
fi



