#!/usr/bin/env python3
"""
Comprehensive ESP32-Pi UART Diagnostic Test
"""

import serial
import time
import os
import sys

def check_uart_device():
    """Check if UART device exists and permissions"""
    print("=" * 70)
    print("STEP 1: UART Device Check")
    print("=" * 70)
    
    devices = ["/dev/serial0", "/dev/ttyAMA0", "/dev/ttyS0"]
    found_device = None
    
    for device in devices:
        print(f"Checking {device}...", end=" ")
        if os.path.exists(device):
            print("✓ EXISTS")
            
            # Check if it's a symlink
            if os.path.islink(device):
                target = os.readlink(device)
                print(f"  → Symlink to: {target}")
            
            # Check permissions
            try:
                st = os.stat(device)
                mode = oct(st.st_mode)[-3:]
                print(f"  → Permissions: {mode}")
            except Exception as e:
                print(f"  → Cannot stat: {e}")
            
            if found_device is None:
                found_device = device
        else:
            print("✗ NOT FOUND")
    
    print()
    if found_device:
        print(f"✓ Will use: {found_device}")
        return found_device
    else:
        print("✗ No UART device found!")
        print("\nTo enable UART:")
        print("  sudo raspi-config")
        print("  → Interface Options → Serial Port")
        print("  → Login shell: NO")
        print("  → Hardware enabled: YES")
        print("  → Reboot")
        return None

def check_permissions():
    """Check if user has permission to access serial"""
    print("\n" + "=" * 70)
    print("STEP 2: Permission Check")
    print("=" * 70)
    
    import grp
    import pwd
    
    username = pwd.getpwuid(os.getuid()).pw_name
    groups = [grp.getgrgid(g).gr_name for g in os.getgroups()]
    
    print(f"Current user: {username}")
    print(f"Groups: {', '.join(groups)}")
    
    if 'dialout' in groups:
        print("✓ User is in 'dialout' group")
        return True
    else:
        print("✗ User is NOT in 'dialout' group")
        print("\nTo fix:")
        print(f"  sudo usermod -a -G dialout {username}")
        print("  (then log out and back in)")
        return False

def test_raw_uart(device, baud=115200):
    """Test raw UART reading"""
    print("\n" + "=" * 70)
    print("STEP 3: Raw UART Test")
    print("=" * 70)
    print(f"Port: {device}")
    print(f"Baud: {baud}")
    print("Timeout: 5 seconds")
    print("=" * 70)
    
    try:
        print("\nOpening serial port...", end=" ")
        ser = serial.Serial(
            port=device,
            baudrate=baud,
            timeout=1,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        print("✓ OPENED")
        
        print(f"Port info:")
        print(f"  Is open: {ser.is_open}")
        print(f"  Baudrate: {ser.baudrate}")
        print(f"  Bytesize: {ser.bytesize}")
        print(f"  Parity: {ser.parity}")
        print(f"  Stopbits: {ser.stopbits}")
        
        print("\nWaiting for data (5 seconds)...")
        print("Expected: ESP32 sends startup + heartbeat messages")
        print("-" * 70)
        
        start_time = time.time()
        byte_count = 0
        line_count = 0
        
        while (time.time() - start_time) < 5:
            if ser.in_waiting > 0:
                # Read available bytes
                data = ser.read(ser.in_waiting)
                byte_count += len(data)
                
                # Try to decode and print
                try:
                    text = data.decode('utf-8', errors='replace')
                    lines = text.split('\n')
                    for line in lines:
                        if line.strip():
                            line_count += 1
                            timestamp = time.strftime("%H:%M:%S")
                            print(f"[{timestamp}] {line.strip()}")
                except Exception as e:
                    print(f"Raw bytes ({len(data)}): {data[:100]}")
            else:
                time.sleep(0.1)
        
        ser.close()
        
        print("-" * 70)
        print(f"\nResults:")
        print(f"  Bytes received: {byte_count}")
        print(f"  Lines received: {line_count}")
        
        if byte_count == 0:
            print("\n✗ NO DATA RECEIVED!")
            print("\nPossible issues:")
            print("  1. ESP32 not powered or not running")
            print("  2. Wiring problem:")
            print("     - ESP32 GPIO43 (TX) should connect to Pi Pin 10 (RX)")
            print("     - ESP32 GPIO44 (RX) should connect to Pi Pin 8  (TX)")
            print("     - Common GND connection required")
            print("  3. TX/RX wires swapped")
            print("  4. ESP32 sending to USB only, not Pi UART")
            print("  5. Wrong baud rate (should be 115200)")
            return False
        else:
            print("\n✓ DATA RECEIVED!")
            return True
            
    except serial.SerialException as e:
        print(f"\n✗ SERIAL ERROR: {e}")
        return False
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        return False

def loopback_test(device):
    """Test if Pi can send/receive on its own UART"""
    print("\n" + "=" * 70)
    print("STEP 4: Loopback Test (Optional)")
    print("=" * 70)
    print("This tests if Pi's UART hardware is working")
    print("For this test: SHORT Pi Pin 8 (TX) to Pin 10 (RX) temporarily")
    
    response = input("\nDo you want to run loopback test? (y/n): ")
    if response.lower() != 'y':
        print("Skipped.")
        return None
    
    print("\nMake sure TX and RX are connected together, then press Enter...")
    input()
    
    try:
        ser = serial.Serial(device, 115200, timeout=1)
        
        test_msg = b"LOOPBACK_TEST_12345\n"
        print(f"Sending: {test_msg.decode().strip()}")
        ser.write(test_msg)
        ser.flush()
        time.sleep(0.1)
        
        received = ser.readline()
        print(f"Received: {received.decode().strip()}")
        
        ser.close()
        
        if test_msg.strip() == received.strip():
            print("✓ Loopback successful - Pi UART hardware is working")
            return True
        else:
            print("✗ Loopback failed - Mismatch")
            return False
            
    except Exception as e:
        print(f"✗ Loopback error: {e}")
        return False

def main():
    print("\n")
    print("*" * 70)
    print("ESP32-Pi UART Comprehensive Diagnostic")
    print("*" * 70)
    print()
    
    # Step 1: Check device
    device = check_uart_device()
    if not device:
        print("\n✗ CRITICAL: No UART device available")
        return 1
    
    # Step 2: Check permissions
    has_permission = check_permissions()
    if not has_permission:
        print("\n⚠ WARNING: Permission issue may cause problems")
    
    # Step 3: Test raw UART
    received_data = test_raw_uart(device)
    
    # Step 4: Optional loopback
    if not received_data:
        loopback_test(device)
    
    print("\n" + "=" * 70)
    print("DIAGNOSTIC COMPLETE")
    print("=" * 70)
    
    if received_data:
        print("\n✓ SUCCESS: ESP32 is sending data to Pi")
        print("\nThe communication is working. Check your application code.")
        return 0
    else:
        print("\n✗ FAILURE: No data from ESP32")
        print("\nNext steps:")
        print("  1. Check ESP32 Serial Monitor - verify it's sending to Pi UART")
        print("  2. Verify wiring with multimeter")
        print("  3. Check ESP32 config.h has correct pins (GPIO43/44)")
        print("  4. Ensure ESP32 is powered and firmware uploaded")
        return 1

if __name__ == '__main__':
    try:
        exit_code = main()
        print("\n")
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n\nTest interrupted by user")
        sys.exit(1)

