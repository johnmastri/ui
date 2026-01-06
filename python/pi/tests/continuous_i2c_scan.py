#!/usr/bin/env python3

from smbus2 import SMBus
import time
import sys
import struct
import argparse

parser = argparse.ArgumentParser(description='Monitor PCF8575 I2C and decode rotary encoder')
parser.add_argument('--pin-a', type=int, default=0, help='Encoder A pin number (default: 0)')
parser.add_argument('--pin-b', type=int, default=1, help='Encoder B pin number (default: 1)')
parser.add_argument('--pin-btn', type=int, default=2, help='Encoder button pin number (default: 2)')
args = parser.parse_args()

ENCODER_PIN_A = args.pin_a
ENCODER_PIN_B = args.pin_b
ENCODER_PIN_BTN = args.pin_btn

print("=" * 60)
print("Continuous I2C & PCF8575 Input Monitor")
print("=" * 60)
print(f"Encoder configuration: A=P{ENCODER_PIN_A:02d}, B=P{ENCODER_PIN_B:02d}, BTN=P{ENCODER_PIN_BTN:02d}")
print("Scanning I2C bus and monitoring PCF8575 inputs...")
print("Press Ctrl+C to stop")
print()

bus = SMBus(1)
last_devices = set()
last_states = {}
encoder_positions = {}
encoder_last_encoded = {}
scan_count = 0

PCF_ADDRESSES = [0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27]

def read_pcf8575(addr):
    try:
        low_byte = bus.read_byte(addr)
        high_byte = bus.read_byte(addr)
        value = (high_byte << 8) | low_byte
        return value
    except:
        return None

def print_pin_states(addr, value):
    print(f"    0x{addr:02X} Raw Value: 0x{value:04X} (binary: {value:016b})")
    print(f"    Pins: ", end="")
    for i in range(16):
        bit = (value >> i) & 1
        symbol = "█" if bit else "░"
        print(f"P{i:02d}:{symbol} ", end="")
        if i == 7:
            print("\n          ", end="")
    print()
    print(f"    P0-P7  (low byte):  {(value & 0xFF):08b} (0x{(value & 0xFF):02X})")
    print(f"    P8-P15 (high byte): {(value >> 8):08b} (0x{(value >> 8):02X})")

def decode_encoder(addr, value):
    a_bit = (value >> ENCODER_PIN_A) & 1
    b_bit = (value >> ENCODER_PIN_B) & 1
    btn_bit = (value >> ENCODER_PIN_BTN) & 1
    
    if addr not in encoder_positions:
        encoder_positions[addr] = 0
        encoder_last_encoded[addr] = (a_bit << 1) | b_bit
        return None
    
    encoded = (a_bit << 1) | b_bit
    last_encoded = encoder_last_encoded[addr]
    sum_val = (last_encoded << 2) | encoded
    
    direction = None
    if sum_val in [0b1101, 0b0100, 0b0010, 0b1011]:
        encoder_positions[addr] += 1
        direction = "CW"
    elif sum_val in [0b1110, 0b0111, 0b0001, 0b1000]:
        encoder_positions[addr] -= 1
        direction = "CCW"
    
    encoder_last_encoded[addr] = encoded
    
    position = encoder_positions[addr]
    normalized_value = max(0.0, min(1.0, position / 100.0))
    
    return {
        'position': position,
        'value': normalized_value,
        'direction': direction,
        'a': a_bit,
        'b': b_bit,
        'button': btn_bit
    }

try:
    while True:
        try:
            current_devices = set()
            current_states = {}
            
            for addr in range(0x03, 0x78):
                try:
                    bus.read_byte(addr)
                    current_devices.add(addr)
                except:
                    pass
            
            for addr in PCF_ADDRESSES:
                if addr in current_devices:
                    state = read_pcf8575(addr)
                    if state is not None:
                        current_states[addr] = state
            
            scan_count += 1
            changed = False
            
            if current_devices != last_devices:
                changed = True
                print(f"\n[{time.strftime('%H:%M:%S')}] Scan #{scan_count}")
                
                if current_devices:
                    addrs = [f"0x{addr:02X}" for addr in sorted(current_devices)]
                    print(f"  I2C Devices: {', '.join(addrs)}")
                else:
                    print("  NO DEVICES")
                
                if current_devices - last_devices:
                    new = current_devices - last_devices
                    new_addrs = [f"0x{a:02X}" for a in sorted(new)]
                    print(f"  NEW: {', '.join(new_addrs)}")
                
                if last_devices - current_devices:
                    gone = last_devices - current_devices
                    gone_addrs = [f"0x{a:02X}" for a in sorted(gone)]
                    print(f"  LOST: {', '.join(gone_addrs)}")
                
                last_devices = current_devices
            
            for addr, state in current_states.items():
                if addr not in last_states or last_states[addr] != state:
                    changed = True
                    if addr not in last_states:
                        print(f"\n[{time.strftime('%H:%M:%S')}] PCF8575 0x{addr:02X} Initial State:")
                    else:
                        print(f"\n[{time.strftime('%H:%M:%S')}] PCF8575 0x{addr:02X} Changed:")
                        old_state = last_states[addr]
                        for i in range(16):
                            old_bit = (old_state >> i) & 1
                            new_bit = (state >> i) & 1
                            if old_bit != new_bit:
                                print(f"    P{i:02d}: {old_bit} -> {new_bit}")
                    
                    print_pin_states(addr, state)
                    
                    encoder_data = decode_encoder(addr, state)
                    if encoder_data:
                        print(f"    ENCODER: Position={encoder_data['position']:4d}  Value={encoder_data['value']:.3f}  ", end="")
                        if encoder_data['direction']:
                            arrow = "→" if encoder_data['direction'] == "CW" else "←"
                            print(f"{arrow} {encoder_data['direction']}  ", end="")
                        print(f"A={encoder_data['a']} B={encoder_data['b']}  ", end="")
                        if encoder_data['button'] == 0:
                            print("BTN:PRESSED", end="")
                        print()
            
            last_states = current_states.copy()
            
            if not changed:
                print(".", end="", flush=True)
                if scan_count % 50 == 0:
                    print(f" [{scan_count}]")
            
            time.sleep(0.1)
            
        except Exception as e:
            print(f"\nError during scan: {e}")
            time.sleep(0.1)

except KeyboardInterrupt:
    print("\n\nStopped.")
    if last_devices:
        addrs = [f"0x{a:02X}" for a in sorted(last_devices)]
        print(f"Final I2C devices: {', '.join(addrs)}")
    else:
        print("Final state: No devices detected")
    
    if last_states:
        print("\nFinal PCF8575 states:")
        for addr, state in sorted(last_states.items()):
            print_pin_states(addr, state)
finally:
    bus.close()

