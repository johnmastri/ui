#!/usr/bin/env python3

import time
from led_controller import LEDController

print("=" * 60)
print("SIMPLE LED TEST - All LEDs Off, Then Solid Red")
print("=" * 60)

controller = LEDController(
    num_encoders=1,
    leds_per_encoder=72,
    active_leds_per_encoder=24,
    brightness=8
)

try:
    print("Clearing all LEDs...")
    controller.clear_all()
    time.sleep(2)
    
    print("Setting first 24 LEDs to solid red...")
    for i in range(24):
        controller.strip.set_pixel(i, 255, 0, 0, bright_percent=100)
    controller.strip.show()
    
    print("LEDs should be red. Press Ctrl+C to exit.")
    while True:
        time.sleep(1)
        
except KeyboardInterrupt:
    print("\nStopping...")
finally:
    controller.clear_all()
    controller.cleanup()
    print("LEDs cleared")

