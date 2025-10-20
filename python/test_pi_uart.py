#!/usr/bin/env python3
"""
Simple test script to verify UART communication between Pi and ESP32
Tests receiving data from ESP32 on Pi's hardware UART pins
"""

import serial
import time
import json
from datetime import datetime

SERIAL_PORT = "/dev/serial0"
BAUD_RATE = 115200
TIMEOUT = 2

def format_timestamp():
    return datetime.now().strftime("%H:%M:%S.%f")[:-3]

def test_uart_connection():
    print("=" * 70)
    print("ESP32-Pi UART Communication Test")
    print("=" * 70)
    print(f"Serial Port: {SERIAL_PORT}")
    print(f"Baud Rate: {BAUD_RATE}")
    print(f"Timeout: {TIMEOUT}s")
    print("=" * 70)
    print("\nWiring Check:")
    print("  ESP32 GPIO43 (TX) → Pi Pin 10 (GPIO15 RX)")
    print("  ESP32 GPIO44 (RX) → Pi Pin 8  (GPIO14 TX)")
    print("  ESP32 GND         → Pi GND")
    print("=" * 70)
    
    try:
        print(f"\n[{format_timestamp()}] Opening serial port...")
        ser = serial.Serial(
            port=SERIAL_PORT,
            baudrate=BAUD_RATE,
            timeout=TIMEOUT,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        
        print(f"[{format_timestamp()}] ✓ Serial port opened successfully")
        print(f"[{format_timestamp()}] Waiting for data from ESP32...")
        print("\n" + "-" * 70)
        
        message_count = 0
        last_heartbeat = None
        
        while True:
            if ser.in_waiting > 0:
                try:
                    line = ser.readline().decode('utf-8').strip()
                    
                    if not line:
                        continue
                    
                    message_count += 1
                    timestamp = format_timestamp()
                    
                    try:
                        data = json.loads(line)
                        msg_type = data.get('type', 'unknown')
                        
                        if msg_type == 'startup':
                            print(f"\n[{timestamp}] 🚀 STARTUP MESSAGE")
                            print(f"  Device ID: {data.get('device_id')}")
                            print(f"  MAC: {data.get('mac_address')}")
                            print(f"  Firmware: {data.get('firmware_version')}")
                            print(f"  Status: {data.get('status')}")
                            print(f"  Capabilities: {data.get('capabilities')}")
                            
                        elif msg_type == 'heartbeat':
                            last_heartbeat = time.time()
                            uptime_sec = data.get('uptime', 0) / 1000
                            print(f"[{timestamp}] ♥ HEARTBEAT (uptime: {uptime_sec:.1f}s)")
                            
                        elif msg_type == 'status':
                            print(f"\n[{timestamp}] ℹ STATUS REPORT")
                            print(f"  Uptime: {data.get('uptime', 0) / 1000:.1f}s")
                            print(f"  Free Memory: {data.get('free_memory', 0)} bytes")
                            print(f"  Messages Sent: {data.get('messages_sent', 0)}")
                            print(f"  USB Messages: {data.get('usb_messages', 0)}")
                            print(f"  Pi Messages: {data.get('pi_messages', 0)}")
                            print(f"  Errors: {data.get('errors', 0)}")
                            print(f"  USB Connected: {data.get('usb_connected', False)}")
                            print(f"  Pi Connected: {data.get('pi_connected', False)}")
                            
                        elif msg_type == 'encoder':
                            print(f"[{timestamp}] 🎛️  ENCODER UPDATE")
                            print(f"  Encoder ID: {data.get('encoder_id')}")
                            print(f"  Value: {data.get('value'):.3f}")
                            print(f"  Direction: {data.get('direction')}")
                            
                        elif msg_type == 'error':
                            print(f"[{timestamp}] ❌ ERROR: {data.get('error')}")
                            
                        else:
                            print(f"[{timestamp}] 📨 {msg_type.upper()}")
                            print(f"  {json.dumps(data, indent=2)}")
                        
                    except json.JSONDecodeError:
                        print(f"[{timestamp}] 📝 RAW: {line}")
                    
                except UnicodeDecodeError as e:
                    print(f"[{timestamp}] ⚠️  Decode error: {e}")
                    
            else:
                time.sleep(0.01)
                
    except serial.SerialException as e:
        print(f"\n❌ Serial port error: {e}")
        print("\nTroubleshooting:")
        print("  1. Check if UART is enabled: sudo raspi-config → Interface Options → Serial")
        print("  2. Verify serial port exists: ls -l /dev/serial0")
        print("  3. Check permissions: sudo usermod -a -G dialout $USER")
        print("  4. Verify wiring connections")
        print("  5. Check ESP32 is powered and running")
        return False
        
    except KeyboardInterrupt:
        print(f"\n\n[{format_timestamp()}] Test stopped by user")
        print(f"Total messages received: {message_count}")
        if last_heartbeat:
            print(f"Last heartbeat: {time.time() - last_heartbeat:.1f}s ago")
        
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print(f"[{format_timestamp()}] Serial port closed")
    
    return True

if __name__ == '__main__':
    print("\n")
    success = test_uart_connection()
    print("\n")
    
    if not success:
        exit(1)

