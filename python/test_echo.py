#!/usr/bin/env python3
"""
Simple bidirectional UART test - Pi echoes back to ESP32
"""

import serial
import json
import time

SERIAL_PORT = "/dev/serial0"
BAUD_RATE = 115200

print("Bidirectional UART Test")
print("=" * 50)

ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
print(f"Listening on {SERIAL_PORT} @ {BAUD_RATE} baud\n")

msg_count = 0

try:
    while True:
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8', errors='ignore').strip()
            
            if not line:
                continue
            
            try:
                data = json.loads(line)
                msg_type = data.get('type', '?')
                msg_count += 1
                
                print(f"RX from ESP32: {msg_type} (#{msg_count})")
                
                # Send echo back to ESP32
                response = {
                    "type": "echo",
                    "original_type": msg_type,
                    "count": msg_count,
                    "timestamp": int(time.time() * 1000)
                }
                
                response_str = json.dumps(response)
                ser.write((response_str + '\n').encode('utf-8'))
                ser.flush()
                
                print(f"TX to ESP32: echo (#{msg_count}) - {len(response_str)} bytes")
                
            except json.JSONDecodeError as e:
                print(f"JSON ERROR: {line[:80]}")
        
        else:
            time.sleep(0.01)
            
except KeyboardInterrupt:
    print(f"\nTest stopped - {msg_count} messages processed")
finally:
    ser.close()

