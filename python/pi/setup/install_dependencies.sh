#!/bin/bash

echo "=============================================="
echo "Master Controller - Dependency Installation"
echo "=============================================="
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PI_DIR="$(dirname "$SCRIPT_DIR")"

echo "[1/6] Updating package list..."
sudo apt-get update

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
pip3 install -r requirements.txt
echo "  ✓ Python packages installed"

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
echo "Installation Complete!"
echo "=============================================="
echo ""
echo "Next steps:"
echo "  1. Log out and log back in (for group changes)"
echo "  2. Run USB gadget setup: sudo bash setup/usb_gadget_setup.sh"
echo "  3. Install systemd service: sudo bash setup/install_service.sh"
echo "  4. Test LEDs: python3 tests/test_leds.py"
echo "  5. Run main controller: python3 main.py"
echo ""

