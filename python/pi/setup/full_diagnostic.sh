#!/bin/bash

echo "=============================================="
echo "COMPREHENSIVE USB GADGET DIAGNOSTIC"
echo "=============================================="
echo ""

echo "=== HARDWARE CHECK ==="
echo ""
echo "[1] Raspberry Pi Model:"
cat /proc/cpuinfo | grep "Model" || echo "  Could not detect model"

echo ""
echo "[2] Raspberry Pi Revision:"
cat /proc/cpuinfo | grep "Revision" || echo "  Could not detect revision"

echo ""
echo "[3] OS Version:"
cat /etc/os-release | grep "PRETTY_NAME" | cut -d= -f2

echo ""
echo "[4] Kernel Version:"
uname -r

echo ""
echo "[5] USB Hardware Detection:"
lsusb -t 2>/dev/null || echo "  lsusb not available"

echo ""
echo "=== USB GADGET DRIVER CHECK ==="
echo ""

echo "[6] dwc2 Driver Status:"
if ls /sys/module/dwc2 &> /dev/null; then
    echo "  ✓ dwc2 module directory exists"
else
    echo "  ✗ dwc2 module directory NOT found"
fi

if lsmod | grep -q dwc2; then
    echo "  ✓ dwc2 loaded in kernel"
    lsmod | grep dwc2
else
    echo "  ✗ dwc2 NOT loaded"
fi

echo ""
echo "[7] g_ether Driver Status:"
if lsmod | grep -q g_ether; then
    echo "  ✓ g_ether loaded"
    lsmod | grep g_ether
else
    echo "  ✗ g_ether NOT loaded"
fi

echo ""
echo "[8] Available USB Gadget Modules:"
ls /lib/modules/$(uname -r)/kernel/drivers/usb/gadget/ 2>/dev/null || echo "  Could not list modules"

echo ""
echo "=== BOOT CONFIGURATION CHECK ==="
echo ""

BOOT_CONFIG=""
if [ -f "/boot/firmware/config.txt" ]; then
    BOOT_CONFIG="/boot/firmware/config.txt"
elif [ -f "/boot/config.txt" ]; then
    BOOT_CONFIG="/boot/config.txt"
fi

if [ -n "$BOOT_CONFIG" ]; then
    echo "[9] Boot Config: $BOOT_CONFIG"
    if grep -q "dtoverlay=dwc2" "$BOOT_CONFIG"; then
        echo "  ✓ dtoverlay=dwc2 present"
    else
        echo "  ✗ dtoverlay=dwc2 MISSING"
    fi
else
    echo "[9] ✗ Could not find config.txt"
fi

echo ""
BOOT_CMDLINE=""
if [ -f "/boot/firmware/cmdline.txt" ]; then
    BOOT_CMDLINE="/boot/firmware/cmdline.txt"
elif [ -f "/boot/cmdline.txt" ]; then
    BOOT_CMDLINE="/boot/cmdline.txt"
fi

if [ -n "$BOOT_CMDLINE" ]; then
    echo "[10] Boot Cmdline: $BOOT_CMDLINE"
    if grep -q "modules-load=dwc2" "$BOOT_CMDLINE"; then
        echo "  ✓ modules-load=dwc2 present"
        echo "  Contents: $(cat $BOOT_CMDLINE)"
    else
        echo "  ✗ modules-load=dwc2 MISSING"
        echo "  Contents: $(cat $BOOT_CMDLINE)"
    fi
else
    echo "[10] ✗ Could not find cmdline.txt"
fi

echo ""
echo "[11] /etc/modules:"
if grep -q "^dwc2" /etc/modules; then
    echo "  ✓ dwc2 present"
else
    echo "  ✗ dwc2 MISSING"
fi
if grep -q "^g_ether" /etc/modules; then
    echo "  ✓ g_ether present"
else
    echo "  ✗ g_ether MISSING"
fi
echo "  Contents:"
cat /etc/modules | grep -v "^#" | grep -v "^$"

echo ""
echo "=== NETWORK INTERFACE CHECK ==="
echo ""

echo "[12] usb0 Interface:"
if ip link show usb0 &> /dev/null; then
    echo "  ✓ usb0 interface exists"
    ip link show usb0
    echo ""
    ip addr show usb0
else
    echo "  ✗ usb0 interface does NOT exist"
fi

echo ""
echo "[13] Network Configuration:"
if [ -f "/etc/network/interfaces.d/usb0" ]; then
    echo "  ✓ /etc/network/interfaces.d/usb0 exists"
    cat /etc/network/interfaces.d/usb0
else
    echo "  ✗ /etc/network/interfaces.d/usb0 does NOT exist"
fi

echo ""
echo "=== KERNEL MESSAGES ==="
echo ""

echo "[14] Recent USB-related kernel messages:"
dmesg | grep -i "usb\|gadget\|dwc2\|g_ether" | tail -20

echo ""
echo "=== DEVICE TREE CHECK ==="
echo ""

echo "[15] Device Tree Overlays:"
if [ -d "/proc/device-tree/hat" ]; then
    echo "  HAT detected:"
    ls -la /proc/device-tree/hat/ 2>/dev/null
fi

echo ""
echo "[16] DWC2 Device Tree Status:"
if [ -d "/proc/device-tree/soc/usb@7e980000" ]; then
    echo "  ✓ USB OTG device tree node exists"
else
    echo "  ✗ USB OTG device tree node not found"
fi

echo ""
echo "=============================================="
echo "DIAGNOSTIC COMPLETE"
echo "=============================================="
echo ""

# Provide recommendations
echo "ANALYSIS:"
echo ""

if ! lsmod | grep -q dwc2; then
    echo "❌ CRITICAL: dwc2 module is not loaded"
    echo "   This means USB gadget mode cannot work"
    echo "   Possible causes:"
    echo "   - Wrong Raspberry Pi model (Pi 3 doesn't support USB gadget)"
    echo "   - Boot configuration not applied (need reboot)"
    echo "   - Using wrong USB port (must use power port, not USB-A ports)"
fi

if ! lsmod | grep -q g_ether; then
    echo "❌ CRITICAL: g_ether module is not loaded"
    echo "   Ethernet gadget driver not active"
fi

if ! ip link show usb0 &> /dev/null; then
    echo "❌ CRITICAL: usb0 interface does not exist"
    echo "   USB cable may not be connected"
    echo "   OR drivers not working properly"
fi

if grep -q "Raspberry Pi 3" /proc/cpuinfo; then
    echo "⚠️  WARNING: Raspberry Pi 3 detected"
    echo "   Pi 3 does NOT support USB gadget mode on the main USB port!"
    echo "   You NEED a Raspberry Pi 4 or newer"
fi

if grep -q "Raspberry Pi 4" /proc/cpuinfo; then
    echo "✓ Good: Raspberry Pi 4 detected (USB gadget supported)"
fi

echo ""
echo "To manually load modules (for testing):"
echo "  sudo modprobe dwc2"
echo "  sudo modprobe g_ether"
echo "  sudo ifconfig usb0 192.168.4.1 netmask 255.255.255.0 up"

