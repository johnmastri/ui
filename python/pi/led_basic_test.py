#!/usr/bin/env python3

import time
from apa102_pi.driver import apa102

print("=" * 60)
print("BASIC APA102 TEST - Direct Hardware Control")
print("=" * 60)
print("This bypasses the controller to test raw LED communication")
print()

strip = apa102.APA102(num_led=72, order='bgr')

try:
    print("Step 1: Clear all LEDs (all black)...")
    strip.clear_strip()
    strip.show()
    time.sleep(2)
    
    print("Step 2: Set first 10 LEDs to RED...")
    for i in range(10):
        strip.set_pixel(i, 255, 0, 0, bright_percent=50)
    strip.show()
    time.sleep(3)
    
    print("Step 3: Set first 10 LEDs to GREEN...")
    for i in range(10):
        strip.set_pixel(i, 0, 255, 0, bright_percent=50)
    strip.show()
    time.sleep(3)
    
    print("Step 4: Set first 10 LEDs to BLUE...")
    for i in range(10):
        strip.set_pixel(i, 0, 0, 255, bright_percent=50)
    strip.show()
    time.sleep(3)
    
    print("Step 5: All LEDs white at low brightness...")
    for i in range(72):
        strip.set_pixel(i, 255, 255, 255, bright_percent=10)
    strip.show()
    
    print("\nTest complete. LEDs should be white. Press Ctrl+C to exit.")
    while True:
        time.sleep(1)
        
except KeyboardInterrupt:
    print("\nStopping...")
finally:
    strip.clear_strip()
    strip.show()
    strip.cleanup()
    print("LEDs cleared")

