#!/usr/bin/env python3

import sys
import time
import argparse
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from hardware.led_controller import LEDController, LEDPattern

def main():
    parser = argparse.ArgumentParser(description='Test APA102 LED Strip')
    parser.add_argument('--brightness', type=int, default=8, help='LED brightness (0-31)')
    parser.add_argument('--count', type=int, default=72, help='Number of LEDs')
    parser.add_argument('--test', type=int, choices=[1,2,3,4,5,6], help='Run specific test only')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("APA102 LED Test Script")
    print("=" * 60)
    print(f"LEDs: {args.count}, Brightness: {args.brightness}")
    print()
    
    controller = LEDController(
        num_encoders=1,
        leds_per_encoder=args.count,
        active_leds_per_encoder=24,
        brightness=args.brightness
    )
    
    try:
        tests = {
            1: ("LED Sweep (Red)", lambda: test_sweep(controller)),
            2: ("Solid Colors", lambda: test_solid_colors(controller)),
            3: ("Ring Fill", lambda: test_ring_fill(controller)),
            4: ("Rainbow", lambda: test_rainbow(controller)),
            5: ("Scanner (Knight Rider)", lambda: test_scanner(controller)),
            6: ("Pulse", lambda: test_pulse(controller))
        }
        
        if args.test:
            name, test_func = tests[args.test]
            print(f"Running Test {args.test}: {name}")
            test_func()
        else:
            for test_num, (name, test_func) in tests.items():
                print(f"\nTest {test_num}: {name}")
                test_func()
                time.sleep(1)
        
        print("\n✓ All tests complete!")
        
    finally:
        controller.cleanup()

def test_sweep(controller):
    print("  Sweeping red LED through first 24 positions...")
    for i in range(24):
        controller.strip.clear_strip()
        controller.strip.set_pixel(i, 255, 0, 0)
        controller.strip.show()
        time.sleep(0.05)
    controller.clear_all()

def test_solid_colors(controller):
    colors = [
        ("Red", 255, 0, 0),
        ("Green", 0, 255, 0),
        ("Blue", 0, 0, 255)
    ]
    
    for name, r, g, b in colors:
        print(f"  {name}...")
        controller.update_encoder_ring(0, r, g, b, LEDPattern.SOLID, 1.0)
        controller.update()
        time.sleep(1)
    controller.clear_all()

def test_ring_fill(controller):
    print("  Filling ring 0% to 100%...")
    controller.update_encoder_ring(0, 0, 255, 0, LEDPattern.RING_FILL, 0.0)
    for i in range(101):
        controller.encoder_rings[0].value = i / 100.0
        controller.update()
        time.sleep(0.02)
    controller.clear_all()

def test_rainbow(controller):
    print("  Rainbow pattern for 3 seconds...")
    controller.update_encoder_ring(0, 255, 255, 255, LEDPattern.RAINBOW, 1.0)
    for _ in range(180):
        controller.update()
        time.sleep(0.016)
    controller.clear_all()

def test_scanner(controller):
    print("  Scanner pattern for 3 seconds...")
    controller.update_encoder_ring(0, 255, 0, 0, LEDPattern.SCANNER, 1.0)
    for _ in range(180):
        controller.update()
        time.sleep(0.016)
    controller.clear_all()

def test_pulse(controller):
    print("  Pulse pattern for 3 seconds...")
    controller.update_encoder_ring(0, 128, 0, 255, LEDPattern.PULSE, 1.0)
    for _ in range(180):
        controller.update()
        time.sleep(0.016)
    controller.clear_all()

if __name__ == '__main__':
    main()

