#!/usr/bin/env python3

import sys
import time

from hardware.led_controller import LEDController, LEDPattern

def main():
    print("=" * 60)
    print("LED DEMO - APA102 72-LED Strip")
    print("=" * 60)
    print("GPIO 10 (Pin 19) -> DATA")
    print("GPIO 11 (Pin 23) -> CLOCK")
    print("=" * 60)
    print()
    
    controller = LEDController(
        num_encoders=1,
        leds_per_encoder=72,
        active_leds_per_encoder=24,
        brightness=8
    )
    
    try:
        print("[1/6] Red sweep through first 24 LEDs...")
        for i in range(24):
            controller.strip.clear_strip()
            controller.strip.set_pixel(i, 255, 0, 0)
            controller.strip.show()
            time.sleep(0.05)
        controller.clear_all()
        time.sleep(0.5)
        
        print("[2/6] Solid Red")
        controller.update_encoder_ring(0, 255, 0, 0, LEDPattern.SOLID, 1.0)
        controller.update()
        time.sleep(1.5)
        
        print("[3/6] Solid Green")
        controller.update_encoder_ring(0, 0, 255, 0, LEDPattern.SOLID, 1.0)
        controller.update()
        time.sleep(1.5)
        
        print("[4/6] Solid Blue")
        controller.update_encoder_ring(0, 0, 0, 255, LEDPattern.SOLID, 1.0)
        controller.update()
        time.sleep(1.5)
        
        print("[5/6] Rainbow pattern (Ctrl+C to stop)...")
        controller.update_encoder_ring(0, 255, 255, 255, LEDPattern.RAINBOW, 1.0)
        while True:
            controller.update()
            time.sleep(0.016)
        
    except KeyboardInterrupt:
        print("\nStopped by user")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()
    finally:
        controller.clear_all()
        controller.cleanup()
        print("LEDs cleared")

if __name__ == '__main__':
    main()

