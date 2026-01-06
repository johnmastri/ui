#!/usr/bin/env python3

import sys
import time
import argparse
sys.path.append('..')

from smbus2 import SMBus

def read_pcf8574(bus, address):
    try:
        data = bus.read_byte(address)
        return data
    except Exception as e:
        print(f"Error reading from 0x{address:02X}: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description='Test PCF8574/PCF8575 I2C Encoder')
    parser.add_argument('--address', type=str, default='scan', help='PCF I2C address (e.g., 0x20) or "scan" to auto-detect')
    parser.add_argument('--bus', type=int, default=1, help='I2C bus number')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("PCF8574/PCF8575 I2C Encoder Test Script")
    print("=" * 60)
    print(f"I2C Bus: {args.bus}")
    print()
    print("Wiring:")
    print("  Pi GPIO 2 (Pin 3)  -> PCF SDA")
    print("  Pi GPIO 3 (Pin 5)  -> PCF SCL")
    print("  Pi GND (Pin 6)     -> PCF GND")
    print("  Pi 5V (Pin 2)      -> PCF VCC")
    print()
    print("Encoder Pins:")
    print("  P0 -> Encoder CLK (A)")
    print("  P1 -> Encoder DT (B)")
    print("  P2 -> Encoder SW (Button)")
    print()
    
    bus = SMBus(args.bus)
    
    address = None
    
    if args.address == 'scan':
        print("Scanning I2C bus for PCF device...")
        print()
        for test_addr in [0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27]:
            test_read = read_pcf8574(bus, test_addr)
            if test_read is not None:
                print(f"  Found device at 0x{test_addr:02X} - state: 0b{test_read:08b}")
                if address is None:
                    address = test_addr
        
        if address is None:
            print()
            print("ERROR: No PCF device found on I2C bus!")
            print("Check wiring and power.")
            bus.close()
            return
        
        print()
        print(f"Using address 0x{address:02X} for testing")
    else:
        address = int(args.address, 16)
        print(f"Testing address: 0x{address:02X}")
        test_read = read_pcf8574(bus, address)
        if test_read is None:
            print("ERROR: Cannot communicate with PCF device!")
            print("Check wiring and I2C address.")
            bus.close()
            return
        print(f"SUCCESS: PCF device found at 0x{address:02X}")
        print(f"Initial state: 0b{test_read:08b} (0x{test_read:02X})")
    
    print()
    print("Rotate encoder or press button. Ctrl+C to exit.")
    print()
    
    last_state = test_read
    position = 0
    last_a = 0
    last_b = 0
    
    try:
        while True:
            current_state = read_pcf8574(bus, address)
            
            if current_state is None:
                time.sleep(0.01)
                continue
            
            if current_state != last_state:
                a_bit = (current_state >> 0) & 1
                b_bit = (current_state >> 1) & 1
                btn_bit = (current_state >> 2) & 1
                
                print(f"State: 0b{current_state:08b}  P0(A)={a_bit}  P1(B)={b_bit}  P2(BTN)={btn_bit}", end="")
                
                if a_bit != last_a or b_bit != last_b:
                    encoded = (a_bit << 1) | b_bit
                    last_encoded = (last_a << 1) | last_b
                    sum_val = (last_encoded << 2) | encoded
                    
                    if sum_val in [0b1101, 0b0100, 0b0010, 0b1011]:
                        position += 1
                        print(f"  -> CW   Position: {position:3d}", end="")
                    elif sum_val in [0b1110, 0b0111, 0b0001, 0b1000]:
                        position -= 1
                        print(f"  -> CCW  Position: {position:3d}", end="")
                    
                    last_a = a_bit
                    last_b = b_bit
                
                if btn_bit == 0:
                    print("  >>> BUTTON PRESSED <<<", end="")
                
                print()
                last_state = current_state
            
            time.sleep(0.001)
            
    except KeyboardInterrupt:
        print("\nStopping...")
    finally:
        bus.close()
        print("I2C bus closed")

if __name__ == '__main__':
    main()

