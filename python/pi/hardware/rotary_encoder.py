import RPi.GPIO as GPIO
import time

class RotaryEncoder:
    def __init__(self, pin_a=17, pin_b=27, pin_button=22):
        self.pin_a = pin_a
        self.pin_b = pin_b
        self.pin_button = pin_button
        
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(pin_a, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        GPIO.setup(pin_b, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        GPIO.setup(pin_button, GPIO.IN, pull_up_down=GPIO.PUD_UP)
        
        self.count = 0
        self.last_encoded = 0
        self.button_pressed = False
        self.last_button_state = GPIO.HIGH
        self.last_button_time = time.time()
        
        MSB = GPIO.input(pin_a)
        LSB = GPIO.input(pin_b)
        self.last_encoded = (MSB << 1) | LSB
        
        GPIO.add_event_detect(pin_a, GPIO.BOTH, callback=self._encoder_callback, bouncetime=5)
        GPIO.add_event_detect(pin_b, GPIO.BOTH, callback=self._encoder_callback, bouncetime=5)
        GPIO.add_event_detect(pin_button, GPIO.FALLING, callback=self._button_callback, bouncetime=50)
        
        print(f"[ROTARY] Rotary encoder initialized on GPIO {pin_a}/{pin_b}/{pin_button}")
    
    def _encoder_callback(self, channel):
        MSB = GPIO.input(self.pin_a)
        LSB = GPIO.input(self.pin_b)
        encoded = (MSB << 1) | LSB
        sum_val = (self.last_encoded << 2) | encoded
        
        if sum_val in [0b1101, 0b0100, 0b0010, 0b1011]:
            if self.count < 24:
                self.count += 1
        elif sum_val in [0b1110, 0b0111, 0b0001, 0b1000]:
            if self.count > 0:
                self.count -= 1
        
        self.last_encoded = encoded
    
    def _button_callback(self, channel):
        current_time = time.time()
        if current_time - self.last_button_time > 0.05:
            self.button_pressed = True
            self.last_button_time = current_time
    
    def get_count(self):
        return self.count
    
    def is_button_pressed(self):
        if self.button_pressed:
            self.button_pressed = False
            return True
        return False
    
    def reset(self):
        self.count = 0
    
    def cleanup(self):
        GPIO.cleanup([self.pin_a, self.pin_b, self.pin_button])

