#!/usr/bin/env python3

import asyncio
import argparse
import signal
import sys
import time
from datetime import datetime

import config
from hardware.led_controller import LEDController
from hardware.rotary_encoder import RotaryEncoder
from hardware.i2c_encoders import I2CEncoderManager
from network.websocket_server import WebSocketServer
from network.usb_gadget import check_usb_gadget, print_usb_status
from utils.message_handler import build_encoder_update, build_button_press

class MasterController:
    def __init__(self, args):
        self.args = args
        self.running = True
        self.start_time = time.time()
        
        self.led_controller = None
        self.test_encoder = None
        self.i2c_encoders = None
        self.websocket_server = None
        self.websocket_ip = None
        
        self.last_encoder_count = 0
        self.last_heartbeat = 0
    
    async def initialize(self):
        print("=" * 60)
        print("Master Controller - Raspberry Pi")
        print(f"Version: {config.FIRMWARE_VERSION}")
        print(f"Device ID: {config.DEVICE_ID}")
        print("=" * 60)
        
        self.websocket_ip = config.WEBSOCKET_IP
        
        if not self.args.no_usb:
            usb_status = check_usb_gadget()
            print_usb_status(usb_status)
            
            import subprocess
            try:
                result = subprocess.run(['ip', 'addr', 'show', 'usb0'], 
                                      capture_output=True, text=True, timeout=2)
                if result.returncode == 0 and '192.168.4.1' in result.stdout:
                    self.websocket_ip = "192.168.4.1"
                    print("[INIT] USB gadget detected, using 192.168.4.1")
                else:
                    self.websocket_ip = "0.0.0.0"
                    print("[INIT] USB gadget not available, binding to all interfaces")
            except Exception as e:
                self.websocket_ip = "0.0.0.0"
                print(f"[INIT] USB gadget check failed, binding to all interfaces: {e}")
        else:
            self.websocket_ip = "0.0.0.0"
            print("[INIT] USB check disabled, binding to all interfaces")
        
        if not self.args.no_leds:
            print("[INIT] Initializing LED controller...")
            self.led_controller = LEDController(
                num_encoders=1,
                leds_per_encoder=config.LEDS_PER_ENCODER,
                active_leds_per_encoder=config.ACTIVE_LEDS_PER_ENCODER,
                brightness=config.LED_BRIGHTNESS,
                color_order=config.LED_COLOR_ORDER
            )
        
        if config.ENABLE_TEST_ENCODER and not self.args.no_encoders:
            print("[INIT] Initializing test encoder...")
            try:
                self.test_encoder = RotaryEncoder(
                    config.TEST_ENCODER_PIN_A,
                    config.TEST_ENCODER_PIN_B,
                    config.TEST_ENCODER_PIN_BTN
                )
            except Exception as e:
                print(f"[INIT] Could not initialize test encoder: {e}")
                print("[INIT] (This is normal if not running on actual Pi hardware)")
        
        if config.ENABLE_PCF_ENCODERS and not self.args.no_encoders:
            print("[INIT] Initializing I2C encoders...")
            try:
                self.i2c_encoders = I2CEncoderManager(
                    bus=config.PCF_I2C_BUS,
                    base_address=config.PCF_BASE_ADDRESS,
                    num_encoders=config.PCF_NUM_ENCODERS,
                    use_interrupts=config.USE_PCF_INTERRUPTS,
                    int_pins=config.PCF_INT_PINS
                )
                self.i2c_encoders.add_callback(self.on_i2c_encoder_change)
            except Exception as e:
                print(f"[INIT] Could not initialize I2C encoders: {e}")
        
        print("[INIT] Starting WebSocket server...")
        self.websocket_server = WebSocketServer(
            self.websocket_ip,
            config.WEBSOCKET_PORT,
            config.DEVICE_ID,
            config.FIRMWARE_VERSION
        )
        
        if self.led_controller:
            self.websocket_server.set_led_controller(self.led_controller)
        
        await self.websocket_server.start()
        
        print("=" * 60)
        print("System initialized successfully!")
        if self.websocket_ip == "0.0.0.0":
            import subprocess
            try:
                result = subprocess.run(['hostname', '-I'], capture_output=True, text=True, timeout=2)
                if result.returncode == 0:
                    ips = result.stdout.strip().split()
                    print(f"WebSocket (port {config.WEBSOCKET_PORT}):")
                    for ip in ips:
                        print(f"  ws://{ip}:{config.WEBSOCKET_PORT}")
                else:
                    print(f"WebSocket: ws://{self.websocket_ip}:{config.WEBSOCKET_PORT}")
            except Exception:
                print(f"WebSocket: ws://{self.websocket_ip}:{config.WEBSOCKET_PORT}")
        else:
            print(f"WebSocket: ws://{self.websocket_ip}:{config.WEBSOCKET_PORT}")
        print("Press Ctrl+C to stop")
        print("=" * 60)
    
    async def main_loop(self):
        while self.running:
            try:
                current_time = time.time()
                
                if self.led_controller:
                    self.led_controller.update()
                
                if self.test_encoder:
                    current_count = self.test_encoder.get_count()
                    if current_count != self.last_encoder_count:
                        value = current_count / 24.0
                        direction = 1 if current_count > self.last_encoder_count else -1
                        
                        message = build_encoder_update(
                            config.DEVICE_ID,
                            0,
                            value,
                            direction
                        )
                        await self.websocket_server.broadcast_message(message)
                        
                        self.last_encoder_count = current_count
                    
                    if self.test_encoder.is_button_pressed():
                        message = build_button_press(config.DEVICE_ID, 0)
                        await self.websocket_server.broadcast_message(message)
                
                if self.i2c_encoders:
                    self.i2c_encoders.update()
                
                if current_time - self.last_heartbeat >= config.HEARTBEAT_INTERVAL_MS / 1000.0:
                    uptime = int((current_time - self.start_time) * 1000)
                    from utils.message_handler import build_heartbeat
                    message = build_heartbeat(config.DEVICE_ID, uptime)
                    await self.websocket_server.broadcast_message(message)
                    self.last_heartbeat = current_time
                
                await asyncio.sleep(0.001)
                
            except Exception as e:
                print(f"[MAIN] Error in main loop: {e}")
                await asyncio.sleep(0.1)
    
    def on_i2c_encoder_change(self, encoder_id, value, direction):
        message = build_encoder_update(
            config.DEVICE_ID,
            encoder_id,
            value,
            direction
        )
        
        asyncio.create_task(self.websocket_server.broadcast_message(message))
    
    def cleanup(self):
        print("\n[MAIN] Shutting down...")
        self.running = False
        
        if self.led_controller:
            print("[MAIN] Cleaning up LEDs...")
            self.led_controller.cleanup()
        
        if self.test_encoder:
            print("[MAIN] Cleaning up test encoder...")
            self.test_encoder.cleanup()
        
        if self.i2c_encoders:
            print("[MAIN] Cleaning up I2C encoders...")
            self.i2c_encoders.cleanup()
        
        print("[MAIN] Goodbye!")

async def run_controller(args):
    controller = MasterController(args)
    
    def signal_handler(sig, frame):
        controller.cleanup()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    await controller.initialize()
    await controller.main_loop()

def main():
    parser = argparse.ArgumentParser(description='Master Controller - Raspberry Pi')
    parser.add_argument('--no-usb', action='store_true', help='Skip USB gadget check')
    parser.add_argument('--no-leds', action='store_true', help='Disable LED controller')
    parser.add_argument('--no-encoders', action='store_true', help='Disable all encoders')
    parser.add_argument('--debug', action='store_true', help='Enable debug output')
    parser.add_argument('--test-mode', action='store_true', help='Enable test mode')
    
    args = parser.parse_args()
    
    try:
        asyncio.run(run_controller(args))
    except KeyboardInterrupt:
        print("\nStopped by user")
    except Exception as e:
        print(f"Fatal error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()

