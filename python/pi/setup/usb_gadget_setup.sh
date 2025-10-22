#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)"
  exit 1
fi

echo "=============================================="
echo "USB Gadget Mode Setup for Raspberry Pi 4B"
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

echo "[1/5] Backing up original config files..."
cp $BOOT_CONFIG ${BOOT_CONFIG}.backup.$(date +%Y%m%d)
cp $BOOT_CMDLINE ${BOOT_CMDLINE}.backup.$(date +%Y%m%d)
echo "  ✓ Backups created"

echo "[2/5] Configuring $BOOT_CONFIG..."
if ! grep -q "dtoverlay=dwc2" $BOOT_CONFIG; then
    echo "" >> $BOOT_CONFIG
    echo "# USB Gadget Mode" >> $BOOT_CONFIG
    echo "dtoverlay=dwc2" >> $BOOT_CONFIG
    echo "  ✓ Added dtoverlay=dwc2"
else
    echo "  ✓ dtoverlay=dwc2 already present"
fi

echo "[3/5] Configuring $BOOT_CMDLINE..."
if ! grep -q "modules-load=dwc2" $BOOT_CMDLINE; then
    sed -i 's/rootwait/rootwait modules-load=dwc2/' $BOOT_CMDLINE
    echo "  ✓ Added modules-load=dwc2"
else
    echo "  ✓ modules-load=dwc2 already present"
fi

echo "[4/5] Configuring /etc/modules..."
if ! grep -q "^dwc2$" /etc/modules; then
    echo "dwc2" >> /etc/modules
    echo "  ✓ Added dwc2"
else
    echo "  ✓ dwc2 already present"
fi

if ! grep -q "^g_ether$" /etc/modules; then
    echo "g_ether" >> /etc/modules
    echo "  ✓ Added g_ether"
else
    echo "  ✓ g_ether already present"
fi

echo "[5/5] Configuring USB network interface..."
cat > /etc/network/interfaces.d/usb0 << EOF
auto usb0
allow-hotplug usb0
iface usb0 inet static
    address 192.168.4.1
    netmask 255.255.255.0
    broadcast 192.168.4.255
EOF
echo "  ✓ Created /etc/network/interfaces.d/usb0"

echo ""
echo "=============================================="
echo "USB Gadget Mode Configuration Complete!"
echo "=============================================="
echo ""
echo "IMPORTANT: You must REBOOT for changes to take effect"
echo ""
echo "After reboot:"
echo "  1. Connect Pi USB-C port to computer"
echo "  2. Pi will appear as USB Ethernet device"
echo "  3. Pi IP: 192.168.4.1"
echo "  4. Computer should get: 192.168.4.x"
echo ""
echo "Reboot now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Reboot skipped. Run 'sudo reboot' when ready."
fi

