from smbus2 import SMBus
import time

class I2CEncoderManager:
    def __init__(self, bus=1, base_address=0x20, num_encoders=8, use_interrupts=False, int_pins=None):
        self.bus_num = bus
        self.base_address = base_address
        self.num_encoders = num_encoders
        self.use_interrupts = use_interrupts
        self.int_pins = int_pins or {}
        
        self.bus = SMBus(bus)
        
        self.encoders = []
        for i in range(num_encoders):
            encoder = {
                'address': base_address + i,
                'position': 0,
                'last_state': 0,
                'value': 0.0,
                'connected': False,
                'last_update': 0
            }
            self.encoders.append(encoder)
        
        self.callbacks = []
        
        print(f"[I2C] I2C Encoder Manager initialized on bus {bus}, addresses 0x{base_address:02X}-0x{base_address+num_encoders-1:02X}")
        
        self.scan_for_encoders()
    
    def scan_for_encoders(self):
        print("[I2C] Scanning for PCF8574 encoders...")
        connected_count = 0
        
        for i, encoder in enumerate(self.encoders):
            try:
                self.bus.read_byte(encoder['address'])
                encoder['connected'] = True
                connected_count += 1
                print(f"[I2C] Encoder {i} found at address 0x{encoder['address']:02X}")
            except:
                encoder['connected'] = False
        
        print(f"[I2C] Scan complete - {connected_count} encoders connected")
    
    def update(self):
        for i, encoder in enumerate(self.encoders):
            if not encoder['connected']:
                continue
            
            try:
                current_state = self.bus.read_byte(encoder['address'])
                
                a_bit = (current_state >> 0) & 1
                b_bit = (current_state >> 1) & 1
                btn_bit = (current_state >> 2) & 1
                
                last_a = (encoder['last_state'] >> 0) & 1
                last_b = (encoder['last_state'] >> 1) & 1
                
                if a_bit != last_a or b_bit != last_b:
                    encoded = (a_bit << 1) | b_bit
                    last_encoded = (last_a << 1) | last_b
                    sum_val = (last_encoded << 2) | encoded
                    
                    direction = 0
                    if sum_val in [0b1101, 0b0100, 0b0010, 0b1011]:
                        encoder['position'] += 1
                        direction = 1
                    elif sum_val in [0b1110, 0b0111, 0b0001, 0b1000]:
                        encoder['position'] -= 1
                        direction = -1
                    
                    if direction != 0:
                        encoder['value'] = max(0.0, min(1.0, encoder['position'] / 100.0))
                        
                        for callback in self.callbacks:
                            callback(i, encoder['value'], direction)
                
                encoder['last_state'] = current_state
                encoder['last_update'] = time.time()
                
            except Exception as e:
                pass
    
    def add_callback(self, callback):
        self.callbacks.append(callback)
    
    def get_encoder_value(self, encoder_id):
        if 0 <= encoder_id < self.num_encoders:
            return self.encoders[encoder_id]['value']
        return 0.0
    
    def cleanup(self):
        self.bus.close()

