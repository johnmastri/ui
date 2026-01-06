#!/usr/bin/env python3

import sys
import subprocess

print("=" * 60)
print("I2C Diagnostic Script")
print("=" * 60)
print()

print("Step 1: Checking if I2C is enabled...")
try:
    result = subprocess.run(['ls', '/dev/i2c-*'], capture_output=True, text=True, shell=True)
    if result.returncode == 0:
        print(f"I2C devices found: {result.stdout.strip()}")
    else:
        print("ERROR: No I2C devices found!")
        print("Enable I2C: sudo raspi-config -> Interface Options -> I2C -> Enable")
        sys.exit(1)
except Exception as e:
    print(f"ERROR checking I2C: {e}")

print()
print("Step 2: Checking I2C permissions...")
try:
    import os
    groups = subprocess.run(['groups'], capture_output=True, text=True).stdout
    print(f"Current user groups: {groups.strip()}")
    if 'i2c' not in groups:
        print("WARNING: User not in 'i2c' group. Add with: sudo usermod -a -G i2c $USER")
except Exception as e:
    print(f"ERROR: {e}")

print()
print("Step 3: Installing/checking i2c-tools...")
try:
    result = subprocess.run(['which', 'i2cdetect'], capture_output=True, text=True)
    if result.returncode == 0:
        print(f"i2cdetect found at: {result.stdout.strip()}")
    else:
        print("i2c-tools not found. Installing...")
        subprocess.run(['sudo', 'apt-get', 'install', '-y', 'i2c-tools'])
except Exception as e:
    print(f"ERROR: {e}")

print()
print("Step 4: Scanning I2C bus 1...")
print("Running: i2cdetect -y 1")
print()
try:
    result = subprocess.run(['i2cdetect', '-y', '1'], capture_output=True, text=True)
    print(result.stdout)
    
    if '--' in result.stdout and 'UU' not in result.stdout:
        print("No devices found!")
        print()
        print("Troubleshooting checklist:")
        print("  1. Is I2C enabled? (sudo raspi-config)")
        print("  2. Is PCF8575 powered? (Check 5V connection)")
        print("  3. Are SDA/SCL wires connected correctly?")
        print("     - Pi GPIO 2 (Pin 3) -> PCF SDA")
        print("     - Pi GPIO 3 (Pin 5) -> PCF SCL")
        print("  4. Is GND connected?")
        print("  5. Try different I2C address jumper settings")
    else:
        print("Device(s) detected! Check the grid above for addresses.")
        
except Exception as e:
    print(f"ERROR running i2cdetect: {e}")

print()
print("Step 5: Testing with Python smbus2...")
try:
    from smbus2 import SMBus
    print("smbus2 library: OK")
    
    print("Attempting to open I2C bus 1...")
    bus = SMBus(1)
    print("Bus opened successfully!")
    
    print()
    print("Scanning addresses 0x20-0x27...")
    found = []
    for addr in range(0x20, 0x28):
        try:
            bus.read_byte(addr)
            print(f"  0x{addr:02X}: FOUND")
            found.append(addr)
        except:
            print(f"  0x{addr:02X}: ---")
    
    bus.close()
    
    if found:
        print()
        print(f"SUCCESS: Found {len(found)} device(s) at: {[hex(a) for a in found]}")
    else:
        print()
        print("No devices responded to Python I2C read.")
        
except ImportError:
    print("ERROR: smbus2 not installed!")
    print("Install with: pip3 install smbus2")
except Exception as e:
    print(f"ERROR: {e}")

print()
print("=" * 60)
print("Diagnostic complete")
print("=" * 60)






