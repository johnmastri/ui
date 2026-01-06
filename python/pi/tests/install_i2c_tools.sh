#!/bin/bash

echo "Installing i2c-tools..."
sudo apt-get update
sudo apt-get install -y i2c-tools

echo ""
echo "Scanning I2C bus 1..."
i2cdetect -y 1

echo ""
echo "============================================================"
echo "Hardware Checklist:"
echo "============================================================"
echo ""
echo "1. PCF8575 Power:"
echo "   - Pin 2 (5V) connected to PCF VCC?"
echo "   - Pin 6 (GND) connected to PCF GND?"
echo "   - Check with multimeter: should read ~5V between VCC and GND"
echo ""
echo "2. I2C Data Lines:"
echo "   - Pin 3 (GPIO 2 / SDA) -> PCF SDA"
echo "   - Pin 5 (GPIO 3 / SCL) -> PCF SCL"
echo ""
echo "3. PCF8575 Board:"
echo "   - Does it have a power LED? Is it lit?"
echo "   - Check all solder connections"
echo "   - Try measuring voltage at PCF chip VCC pin"
echo ""
echo "4. Address Selection:"
echo "   - A0 jumper set (address 0x21)"
echo "   - A1 and A2 should be unset (address 0x20 base)"
echo ""
echo "5. Quick Test:"
echo "   - Disconnect everything from Pi"
echo "   - Connect ONLY: 5V, GND, SDA, SCL (no encoder yet)"
echo "   - Run: i2cdetect -y 1"
echo "   - Should see the PCF address appear in grid"
echo ""
echo "If STILL nothing shows up:"
echo "   - Bad PCF8575 chip"
echo "   - Broken wire/jumper"
echo "   - Wrong pins on Pi header"
echo "============================================================"






