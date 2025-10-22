#!/usr/bin/env python3

from apa102_pi.driver import apa102

strip = apa102.APA102(num_led=72, order='bgr')
strip.clear_strip()
strip.show()
strip.cleanup()
print("LEDs cleared")

