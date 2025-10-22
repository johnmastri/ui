from apa102_pi.driver import apa102
import time
import math
from enum import Enum

class LEDPattern(Enum):
    OFF = 0
    SCANNER = 1
    SOLID = 2
    RING_FILL = 3
    PULSE = 4
    RAINBOW = 5
    ERROR = 6

class EncoderRing:
    def __init__(self, start_index, leds_per_encoder=72, active_leds=24):
        self.start_index = start_index
        self.leds_per_encoder = leds_per_encoder
        self.active_leds = active_leds
        self.color = (0, 0, 0)
        self.pattern = LEDPattern.OFF
        self.value = 0.0
        self.active = False
        self.animation_phase = 0.0

class LEDController:
    def __init__(self, num_encoders=1, leds_per_encoder=72, active_leds_per_encoder=24, brightness=8, color_order='bgr'):
        self.num_encoders = num_encoders
        self.leds_per_encoder = leds_per_encoder
        self.total_leds = num_encoders * leds_per_encoder
        self.active_leds_per_encoder = active_leds_per_encoder
        
        self.strip = apa102.APA102(
            num_led=self.total_leds,
            global_brightness=brightness,
            order=color_order
        )
        
        self.encoder_rings = []
        for i in range(num_encoders):
            ring = EncoderRing(i * leds_per_encoder, leds_per_encoder, active_leds_per_encoder)
            self.encoder_rings.append(ring)
        
        self.last_update = time.time()
        self.initialized = True
        
        self.clear_all()
        print(f"[LED] APA102 strip initialized: {self.total_leds} LEDs, {num_encoders} encoder rings")
    
    def update_encoder_ring(self, encoder_id, r, g, b, pattern, value):
        if 0 <= encoder_id < self.num_encoders:
            ring = self.encoder_rings[encoder_id]
            ring.color = (r, g, b)
            
            if isinstance(pattern, str):
                pattern_map = {
                    'off': LEDPattern.OFF,
                    'scanner': LEDPattern.SCANNER,
                    'solid': LEDPattern.SOLID,
                    'ring_fill': LEDPattern.RING_FILL,
                    'pulse': LEDPattern.PULSE,
                    'rainbow': LEDPattern.RAINBOW,
                    'error': LEDPattern.ERROR
                }
                ring.pattern = pattern_map.get(pattern.lower(), LEDPattern.SOLID)
            else:
                ring.pattern = pattern
            
            ring.value = max(0.0, min(1.0, value))
            ring.active = True
            print(f"[LED] Updated encoder {encoder_id}: RGB({r},{g},{b}) {ring.pattern.name} value={value:.2f}")
    
    def update(self):
        current_time = time.time()
        
        if current_time - self.last_update < 0.016:
            return
        
        for ring in self.encoder_rings:
            ring.animation_phase += 0.02
            if ring.animation_phase > 1.0:
                ring.animation_phase -= 1.0
        
        for i, ring in enumerate(self.encoder_rings):
            self._render_encoder(i, ring)
        
        self.strip.show()
        self.last_update = current_time
    
    def _render_encoder(self, encoder_id, ring):
        start = ring.start_index
        
        if ring.pattern == LEDPattern.OFF:
            self._render_off(start, ring)
        elif ring.pattern == LEDPattern.SOLID:
            self._render_solid(start, ring)
        elif ring.pattern == LEDPattern.RING_FILL:
            self._render_ring_fill(start, ring)
        elif ring.pattern == LEDPattern.PULSE:
            self._render_pulse(start, ring)
        elif ring.pattern == LEDPattern.RAINBOW:
            self._render_rainbow(start, ring)
        elif ring.pattern == LEDPattern.SCANNER:
            self._render_scanner(start, ring)
    
    def _render_off(self, start, ring):
        for i in range(ring.leds_per_encoder):
            self.strip.set_pixel(start + i, 0, 0, 0)
    
    def _render_solid(self, start, ring):
        r, g, b = ring.color
        for i in range(self.active_leds_per_encoder):
            self.strip.set_pixel(start + i, r, g, b)
        for i in range(self.active_leds_per_encoder, ring.leds_per_encoder):
            self.strip.set_pixel(start + i, 0, 0, 0)
    
    def _render_ring_fill(self, start, ring):
        r, g, b = ring.color
        lit_leds = int(ring.value * self.active_leds_per_encoder)
        
        for i in range(self.active_leds_per_encoder):
            if i < lit_leds:
                self.strip.set_pixel(start + i, r, g, b)
            else:
                self.strip.set_pixel(start + i, r//8, g//8, b//8)
        
        for i in range(self.active_leds_per_encoder, ring.leds_per_encoder):
            self.strip.set_pixel(start + i, 0, 0, 0)
    
    def _render_pulse(self, start, ring):
        r, g, b = ring.color
        pulse = 0.1 + 0.9 * (math.sin(ring.animation_phase * 2 * math.pi) + 1) / 2
        
        pr, pg, pb = int(r * pulse), int(g * pulse), int(b * pulse)
        
        for i in range(self.active_leds_per_encoder):
            self.strip.set_pixel(start + i, pr, pg, pb)
        for i in range(self.active_leds_per_encoder, ring.leds_per_encoder):
            self.strip.set_pixel(start + i, 0, 0, 0)
    
    def _render_rainbow(self, start, ring):
        for i in range(self.active_leds_per_encoder):
            hue = (ring.animation_phase + i / self.active_leds_per_encoder) % 1.0
            r, g, b = self._hsv_to_rgb(hue, 1.0, 1.0)
            self.strip.set_pixel(start + i, r, g, b)
        for i in range(self.active_leds_per_encoder, ring.leds_per_encoder):
            self.strip.set_pixel(start + i, 0, 0, 0)
    
    def _render_scanner(self, start, ring):
        r, g, b = ring.color
        scanner_width = 5
        position = int(ring.animation_phase * (self.active_leds_per_encoder * 2))
        
        if position >= self.active_leds_per_encoder:
            position = (self.active_leds_per_encoder * 2) - position - 1
        
        for i in range(self.active_leds_per_encoder):
            distance = abs(i - position)
            if distance < scanner_width:
                brightness = (1.0 - distance / scanner_width) ** 2
                sr, sg, sb = int(r * brightness), int(g * brightness), int(b * brightness)
                self.strip.set_pixel(start + i, sr, sg, sb)
            else:
                self.strip.set_pixel(start + i, 0, 0, 0)
        
        for i in range(self.active_leds_per_encoder, ring.leds_per_encoder):
            self.strip.set_pixel(start + i, 0, 0, 0)
    
    def _hsv_to_rgb(self, h, s, v):
        i = int(h * 6)
        f = h * 6 - i
        p = v * (1 - s)
        q = v * (1 - f * s)
        t = v * (1 - (1 - f) * s)
        i %= 6
        
        if i == 0: r, g, b = v, t, p
        elif i == 1: r, g, b = q, v, p
        elif i == 2: r, g, b = p, v, t
        elif i == 3: r, g, b = p, q, v
        elif i == 4: r, g, b = t, p, v
        elif i == 5: r, g, b = v, p, q
        
        return int(r * 255), int(g * 255), int(b * 255)
    
    def set_brightness(self, brightness):
        self.strip.global_brightness = max(0, min(31, brightness))
        print(f"[LED] Brightness set to {brightness}")
    
    def clear_all(self):
        self.strip.clear_strip()
        self.strip.show()
    
    def cleanup(self):
        self.clear_all()
        self.strip.cleanup()

