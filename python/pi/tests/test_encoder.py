#!/usr/bin/env python3

import sys
import time
import argparse
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from hardware.rotary_encoder import RotaryEncoder

def main():
    parser = argparse.ArgumentParser(description='Test Rotary Encoder')
    parser.add_argument('--gpio-a', type=int, default=17, help='GPIO pin for encoder A')
    parser.add_argument('--gpio-b', type=int, default=27, help='GPIO pin for encoder B')
    parser.add_argument('--gpio-btn', type=int, default=22, help='GPIO pin for button')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Rotary Encoder Test Script")
    print("=" * 60)
    print(f"Pins: A={args.gpio_a}, B={args.gpio_b}, Button={args.gpio_btn}")
    print("\nRotate encoder or press button. Ctrl+C to exit.")
    print()
    
    encoder = RotaryEncoder(args.gpio_a, args.gpio_b, args.gpio_btn)
    
    last_count = 0
    
    try:
        while True:
            current_count = encoder.get_count()
            
            if current_count != last_count:
                direction = "CW" if current_count > last_count else "CCW"
                value = current_count / 24.0
                print(f"Count: {current_count:2d}  Value: {value:.2f}  Direction: {direction}")
                last_count = current_count
            
            if encoder.is_button_pressed():
                print(">>> BUTTON PRESSED <<<")
            
            time.sleep(0.01)
            
    except KeyboardInterrupt:
        print("\nStopping...")
    finally:
        encoder.cleanup()
        print("Encoder cleaned up")

if __name__ == '__main__':
    main()

