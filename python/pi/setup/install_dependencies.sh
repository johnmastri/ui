#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

echo "=============================================="
echo "Master Controller - Dependency Installation"
echo "=============================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PI_DIR="$(dirname "$SCRIPT_DIR")"

echo "[1/6] Updating package list..."
sudo apt-get update -y

echo ""
echo "[2/6] Installing system packages..."
sudo apt-get install -y python3-pip python3-dev i2c-tools

echo ""
echo "[3/6] Enabling SPI interface..."
sudo raspi-config nonint do_spi 0
echo "  ✓ SPI enabled"

echo ""
echo "[4/6] Enabling I2C interface..."
sudo raspi-config nonint do_i2c 0
echo "  ✓ I2C enabled"

echo ""
echo "[5/6] Installing Python packages..."
cd "$PI_DIR"
if pip3 install -r requirements.txt --break-system-packages --user 2>&1; then
    echo "  ✓ Python packages installed"
elif pip3 install -r requirements.txt --user 2>&1; then
    echo "  ✓ Python packages installed"
else
    echo "  ⚠ Python package installation had issues, but continuing..."
fi

echo ""
echo "[6/6] Configuring I2C speed to 400kHz..."
BOOT_CONFIG="/boot/firmware/config.txt"
if [ ! -f "$BOOT_CONFIG" ]; then
    BOOT_CONFIG="/boot/config.txt"
fi

if ! grep -q "dtparam=i2c_arm_baudrate" $BOOT_CONFIG; then
    echo "dtparam=i2c_arm_baudrate=400000" | sudo tee -a $BOOT_CONFIG
    echo "  ✓ I2C speed configured"
else
    echo "  ✓ I2C speed already configured"
fi

echo ""
echo "[OPTIONAL] Adding user to hardware groups..."
CURRENT_USER=$(whoami)
sudo usermod -a -G gpio,spi,i2c $CURRENT_USER
echo "  ✓ User $CURRENT_USER added to gpio, spi, i2c groups"

echo ""
echo "=============================================="
echo "Dependencies Installation Complete!"
echo "=============================================="
echo ""

