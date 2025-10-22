#!/bin/bash

echo "=============================================="
echo "USB Gadget Diagnostic and Fix Script"
echo "=============================================="
echo ""

# Check which boot directory exists
if [ -d "/boot/firmware" ]; then
    BOOT_DIR="/boot/firmware"
    echo "Using: /boot/firmware"
elif [ -d "/boot" ]; then
    BOOT_DIR="/boot"
    echo "Using: /boot"
else
    echo "ERROR: Cannot find boot directory"
    exit 1
fi

echo ""
echo "=== Current Configuration ===" 
echo ""

echo "[1] Checking $BOOT_DIR/config.txt..."
if grep -q "dtoverlay=dwc2" "$BOOT_DIR/config.txt"; then
    echo "  ✓ dtoverlay=dwc2 is present"
else
    echo "  ✗ dtoverlay=dwc2 is MISSING"
fi

echo ""
echo "[2] Checking $BOOT_DIR/cmdline.txt..."
if grep -q "modules-load=dwc2" "$BOOT_DIR/cmdline.txt"; then
    echo "  ✓ modules-load=dwc2 is present"
else
    echo "  ✗ modules-load=dwc2 is MISSING"
fi

echo ""
echo "[3] Checking /etc/modules..."
if grep -q "^dwc2$" /etc/modules; then
    echo "  ✓ dwc2 module configured"
else
    echo "  ✗ dwc2 module MISSING"
fi

if grep -q "^g_ether$" /etc/modules; then
    echo "  ✓ g_ether module configured"
else
    echo "  ✗ g_ether module MISSING"
fi

echo ""
echo "[4] Checking loaded modules..."
if lsmod | grep -q dwc2; then
    echo "  ✓ dwc2 module is loaded"
else
    echo "  ✗ dwc2 module is NOT loaded"
fi

if lsmod | grep -q g_ether; then
    echo "  ✓ g_ether module is loaded"
else
    echo "  ✗ g_ether module is NOT loaded"
fi

echo ""
echo "[5] Checking usb0 interface..."
if ip link show usb0 &> /dev/null; then
    echo "  ✓ usb0 interface exists"
    ip addr show usb0 | grep "inet " || echo "  ⚠ No IP configured"
else
    echo "  ✗ usb0 interface does NOT exist"
fi

echo ""
echo "[6] Checking USB cable connection..."
if dmesg | tail -50 | grep -qi "usb.*connect"; then
    echo "  ✓ USB cable appears to be connected"
    dmesg | tail -10 | grep -i usb
else
    echo "  ? Cannot determine USB cable status"
fi

echo ""
echo "=== Applying Fix (requires sudo) ===="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo to apply fixes"
    echo "  sudo bash $0"
    exit 1
fi

echo "[FIX 1] Adding dtoverlay=dwc2 to config.txt..."
if ! grep -q "dtoverlay=dwc2" "$BOOT_DIR/config.txt"; then
    echo "" >> "$BOOT_DIR/config.txt"
    echo "# USB Gadget Mode" >> "$BOOT_DIR/config.txt"
    echo "dtoverlay=dwc2" >> "$BOOT_DIR/config.txt"
    echo "  ✓ Added"
else
    echo "  ✓ Already present"
fi

echo ""
echo "[FIX 2] Adding modules-load=dwc2 to cmdline.txt..."
if ! grep -q "modules-load=dwc2" "$BOOT_DIR/cmdline.txt"; then
    cp "$BOOT_DIR/cmdline.txt" "$BOOT_DIR/cmdline.txt.backup"
    sed -i 's/rootwait/rootwait modules-load=dwc2/' "$BOOT_DIR/cmdline.txt"
    echo "  ✓ Added"
else
    echo "  ✓ Already present"
fi

echo ""
echo "[FIX 3] Adding modules to /etc/modules..."
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

echo ""
echo "[FIX 4] Configuring usb0 network interface..."
cat > /etc/network/interfaces.d/usb0 << 'EOF'
auto usb0
allow-hotplug usb0
iface usb0 inet static
    address 192.168.4.1
    netmask 255.255.255.0
    broadcast 192.168.4.255
EOF
echo "  ✓ Network config created"

echo ""
echo "=============================================="
echo "Configuration Complete!"
echo "=============================================="
echo ""
echo "IMPORTANT: You MUST reboot for changes to take effect"
echo ""
echo "After reboot:"
echo "  1. Wait 30 seconds"
echo "  2. Run: ip addr show usb0"
echo "  3. Should see: inet 192.168.4.1/24"
echo "  4. From Windows: ping 192.168.4.1"
echo ""
echo "Reboot now? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    reboot
fi

