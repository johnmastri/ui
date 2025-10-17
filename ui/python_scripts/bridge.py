#!/usr/bin/env python3
"""
ESP32 to WebSocket Bridge for Raspberry Pi
Connects ESP32 UART communication to WebSocket clients (Vue.js frontend)
"""

import asyncio
import websockets
import serial
import serial.tools.list_ports
import json
import threading
import time
import platform
from datetime import datetime
from typing import Set, Optional, Any

class ESP32WebSocketBridge:
    def __init__(self, serial_port=None, baud_rate=115200, websocket_port=8765):
        self.serial_port = serial_port or self.detect_serial_port()
        self.baud_rate = baud_rate
        self.websocket_port = websocket_port
        
        # Serial connection
        self.serial_connection: Optional[serial.Serial] = None
        self.serial_thread: Optional[threading.Thread] = None
        self.running = False
        
        # WebSocket server
        self.websocket_clients: Set[Any] = set()
        
        # Message queues
        self.esp32_to_websocket_queue = asyncio.Queue()
        
        # Parameter structure storage
        self.parameter_structure = {}
        self.structure_hash = None
        
        # Statistics
        self.stats = {
            'esp32_messages_received': 0,
            'esp32_messages_sent': 0,
            'websocket_messages_received': 0,
            'websocket_messages_sent': 0,
            'esp32_connection_attempts': 0,
            'websocket_connections': 0,
            'last_esp32_heartbeat': None,
            'bridge_start_time': datetime.now()
        }

    def detect_serial_port(self) -> str:
        """Auto-detect ESP32 serial port based on operating system"""
        ports = list(serial.tools.list_ports.comports())
        
        # Try to find ESP32 device
        for port in ports:
            if any(keyword in port.description.lower() for keyword in ['esp32', 'cp210', 'ch340', 'usb-serial']):
                print(f"🔍 Found potential ESP32 device: {port.device} - {port.description}")
                return port.device
        
        # Fallback based on OS
        if platform.system() == "Windows":
            # On Windows, try common COM ports
            for i in range(3, 20):  # COM3 to COM19
                port_name = f"COM{i}"
                if any(p.device == port_name for p in ports):
                    print(f"🔍 Using Windows serial port: {port_name}")
                    return port_name
            return "COM3"  # Default fallback
        else:
            # Linux/Mac fallback
            return "/dev/ttyACM0"

    def map_parameter_to_encoder(self, param_id: str) -> int:
        """Map parameter ID to encoder ID for ESP32"""
        # Define mapping from parameter names to encoder IDs (based on actual Vue.js parameters)
        param_mapping = {
            'input-gain': 0,
            'drive': 1,
            'tone': 2,
            'output-level': 3,
            'mix': 4,
            'attack': 5,
            'release': 6,
            'threshold': 7,
            'ratio': 8,
            'knee': 9,
            # Reserve slots for potential additional parameters
            'reverb': 10,
            'delay': 11,
            'chorus': 12,
            'eq-low': 13,
            'eq-mid': 14,
            'eq-high': 15
        }
        
        # Return mapped encoder ID or default to 0
        encoder_id = param_mapping.get(param_id, 0)
        if param_id not in param_mapping:
            print(f"⚠️ Unknown parameter ID '{param_id}', using encoder 0")
        return encoder_id

    def connect_to_esp32(self) -> bool:
        """Connect to ESP32 via UART/Serial"""
        try:
            self.stats['esp32_connection_attempts'] += 1
            print(f"🔗 Attempting to connect to ESP32 on {self.serial_port} at {self.baud_rate} baud...")
            
            self.serial_connection = serial.Serial(
                port=self.serial_port,
                baudrate=self.baud_rate,
                timeout=1,
                write_timeout=1
            )
            
            # Wait for connection to stabilize
            time.sleep(2)
            
            print(f"✅ Connected to ESP32 on {self.serial_port}")
            return True
            
        except serial.SerialException as e:
            print(f"❌ Failed to connect to ESP32: {e}")
            return False
        except Exception as e:
            print(f"❌ Unexpected error connecting to ESP32: {e}")
            return False

    def serial_reader_thread(self):
        """Thread to read messages from ESP32 and queue them for WebSocket broadcast"""
        print("📡 Starting ESP32 serial reader thread...")
        
        while self.running:
            if not self.serial_connection or not self.serial_connection.is_open:
                if not self.connect_to_esp32():
                    time.sleep(5)  # Wait 5 seconds before retry
                    continue
            
            try:
                # Read line from ESP32
                if self.serial_connection:
                    line = self.serial_connection.readline().decode('utf-8').strip()
                else:
                    continue
                
                if line:
                    self.stats['esp32_messages_received'] += 1
                    print(f"📤 ESP32: {line}")
                    
                    # Try to parse as JSON
                    try:
                        message = json.loads(line)
                        
                        # Update heartbeat timestamp if it's a heartbeat message
                        if message.get('type') == 'heartbeat':
                            self.stats['last_esp32_heartbeat'] = datetime.now()
                        
                        # Queue message for WebSocket broadcast
                        asyncio.run_coroutine_threadsafe(
                            self.esp32_to_websocket_queue.put(message),
                            self.loop
                        )
                        
                    except json.JSONDecodeError:
                        # Not JSON, might be debug output - still forward it
                        debug_message = {
                            'type': 'esp32_debug',
                            'message': line,
                            'timestamp': int(time.time() * 1000)
                        }
                        
                        asyncio.run_coroutine_threadsafe(
                            self.esp32_to_websocket_queue.put(debug_message),
                            self.loop
                        )
                        
            except serial.SerialException as e:
                print(f"⚠️ Serial connection lost: {e}")
                self.serial_connection = None
                time.sleep(1)
                
            except Exception as e:
                print(f"❌ Error in serial reader: {e}")
                time.sleep(1)

    async def websocket_handler(self, websocket):
        """Handle new WebSocket client connections"""
        client_addr = websocket.remote_address
        print(f"🌐 WebSocket client connected: {client_addr}")
        
        self.websocket_clients.add(websocket)
        self.stats['websocket_connections'] += 1
        
        # Send connection confirmation and current bridge status
        await self.send_to_client(websocket, {
            'type': 'bridge_status',
            'esp32_connected': self.serial_connection and self.serial_connection.is_open,
            'stats': self.stats.copy(),
            'timestamp': int(time.time() * 1000)
        })
        
        try:
            async for message in websocket:
                await self.handle_websocket_message(websocket, message)
                
        except websockets.exceptions.ConnectionClosed:
            print(f"🔌 WebSocket client disconnected: {client_addr}")
        except Exception as e:
            print(f"❌ WebSocket error for {client_addr}: {e}")
        finally:
            self.websocket_clients.remove(websocket)

    async def handle_websocket_message(self, websocket, message_str: str):
        """Process incoming WebSocket messages and forward to ESP32"""
        try:
            self.stats['websocket_messages_received'] += 1
            print(f"📥 WebSocket: {message_str}")
            
            message = json.loads(message_str)
            message_type = message.get('type', '')
            
            # Handle bridge-specific commands
            if message_type == 'bridge_command':
                await self.handle_bridge_command(websocket, message)
                return
                
            # Handle ESP32 system commands
            elif message_type == 'system_command':
                await self.forward_to_esp32(message)
                
            # Handle LED update commands
            elif message_type == 'led_update':
                await self.forward_to_esp32(message)
                
            # Handle parameter updates (convert to ESP32 format)
            elif message_type == 'parameter_update':
                # Convert parameter update to LED update for ESP32
                led_message = {
                    'type': 'led_update',
                    'encoder_id': message.get('knob_id', 0),
                    'color': {'r': 255, 'g': 128, 'b': 0},  # Default orange
                    'pattern': 'ring_fill',
                    'value': message.get('value', 0.0)
                }
                await self.forward_to_esp32(led_message)
                
            # Handle parameter value sync (batch updates from Vue.js)
            elif message_type == 'parameter_value_sync':
                updates = message.get('updates', [])
                print(f"🔄 Processing {len(updates)} parameter sync updates")
                
                for update in updates:
                    # Convert each parameter to LED update for ESP32
                    param_id = update.get('id', '')
                    value = update.get('value', 0.0)
                    rgb_color = update.get('rgbColor', {'r': 255, 'g': 128, 'b': 0})
                    
                    # Map parameter ID to encoder ID (you may need to adjust this mapping)
                    encoder_id = self.map_parameter_to_encoder(param_id)
                    
                    led_message = {
                        'type': 'led_update',
                        'encoder_id': encoder_id,
                        'color': rgb_color,
                        'pattern': 'ring_fill',
                        'value': value
                    }
                    await self.forward_to_esp32(led_message)
                    print(f"📡 → ESP32: {param_id} ({encoder_id}) = {value} | RGB({rgb_color['r']},{rgb_color['g']},{rgb_color['b']})")
                
            # Handle parameter structure sync (initial setup from Vue.js)
            elif message_type == 'parameter_structure_sync':
                self.structure_hash = message.get('structure_hash', '')
                parameters = message.get('parameters', [])
                
                print(f"🏗️ Received parameter structure with {len(parameters)} parameters")
                
                # Store parameter structure for reference
                self.parameter_structure = {param['id']: param for param in parameters}
                
                # Process initial parameter values and send to ESP32
                for param in parameters:
                    param_id = param.get('id', '')
                    value = param.get('value', 0.0)
                    rgb_color = param.get('rgbColor', {'r': 255, 'g': 128, 'b': 0})
                    
                    encoder_id = self.map_parameter_to_encoder(param_id)
                    
                    led_message = {
                        'type': 'led_update',
                        'encoder_id': encoder_id,
                        'color': rgb_color,
                        'pattern': 'ring_fill',
                        'value': value
                    }
                    await self.forward_to_esp32(led_message)
                    print(f"🎛️ Init: {param_id} ({encoder_id}) = {value:.2f} | {param.get('name', 'Unknown')}")
                
                print(f"✅ Parameter structure initialized (hash: {self.structure_hash[:8]}...)")
                
            else:
                print(f"⚠️ Unknown message type: {message_type}")
                
        except json.JSONDecodeError:
            print(f"❌ Invalid JSON from WebSocket: {message_str}")
        except Exception as e:
            print(f"❌ Error handling WebSocket message: {e}")

    async def handle_bridge_command(self, websocket, message):
        """Handle bridge-specific commands"""
        command = message.get('command', '')
        
        if command == 'get_status':
            await self.send_to_client(websocket, {
                'type': 'bridge_status',
                'esp32_connected': self.serial_connection and self.serial_connection.is_open,
                'stats': self.stats.copy(),
                'parameter_count': len(self.parameter_structure),
                'structure_hash': self.structure_hash,
                'timestamp': int(time.time() * 1000)
            })
            
        elif command == 'restart_esp32_connection':
            print("🔄 Restarting ESP32 connection...")
            if self.serial_connection:
                self.serial_connection.close()
                self.serial_connection = None

    async def forward_to_esp32(self, message):
        """Send message to ESP32 via UART"""
        if not self.serial_connection or not self.serial_connection.is_open:
            print("⚠️ Cannot send to ESP32: Serial connection not available")
            return
            
        try:
            message_str = json.dumps(message)
            self.serial_connection.write((message_str + '\n').encode('utf-8'))
            self.serial_connection.flush()
            
            self.stats['esp32_messages_sent'] += 1
            print(f"📤 → ESP32: {message_str}")
            
        except Exception as e:
            print(f"❌ Error sending to ESP32: {e}")

    async def send_to_client(self, websocket, message):
        """Send message to specific WebSocket client"""
        try:
            message_str = json.dumps(message)
            await websocket.send(message_str)
            self.stats['websocket_messages_sent'] += 1
            
        except Exception as e:
            print(f"❌ Error sending to WebSocket client: {e}")

    async def broadcast_to_websockets(self, message):
        """Broadcast message to all connected WebSocket clients"""
        if not self.websocket_clients:
            return
            
        # Create a copy of the set to avoid modification during iteration
        clients_copy = self.websocket_clients.copy()
        
        for client in clients_copy:
            try:
                await self.send_to_client(client, message)
            except:
                # Remove disconnected clients
                self.websocket_clients.discard(client)

    async def message_forwarder(self):
        """Forward messages from ESP32 to WebSocket clients"""
        print("🔄 Starting message forwarder...")
        
        while self.running:
            try:
                # Get message from ESP32 queue
                message = await asyncio.wait_for(
                    self.esp32_to_websocket_queue.get(), 
                    timeout=1.0
                )
                
                # Broadcast to all WebSocket clients
                await self.broadcast_to_websockets(message)
                
            except asyncio.TimeoutError:
                # Normal timeout, continue loop
                continue
            except Exception as e:
                print(f"❌ Error in message forwarder: {e}")

    async def start_server(self):
        """Start the WebSocket server and message processing"""
        print(f"🚀 Starting ESP32-WebSocket Bridge...")
        print(f"📡 ESP32 Serial: {self.serial_port} @ {self.baud_rate} baud")
        print(f"🌐 WebSocket Server: ws://0.0.0.0:{self.websocket_port}")
        
        self.running = True
        self.loop = asyncio.get_event_loop()
        
        # Start serial reader thread
        self.serial_thread = threading.Thread(target=self.serial_reader_thread, daemon=True)
        self.serial_thread.start()
        
        # Start message forwarder
        forwarder_task = asyncio.create_task(self.message_forwarder())
        
        # Start WebSocket server
        server = await websockets.serve(
            self.websocket_handler,
            "0.0.0.0",
            self.websocket_port
        )
        
        print("✅ Bridge is running!")
        print("🔗 Connect your Vue.js app to: ws://192.168.1.195:8765")
        print("📊 ESP32 messages will be forwarded to WebSocket clients")
        print("🎛️ WebSocket commands will be sent to ESP32")
        print("\nPress Ctrl+C to stop...")
        
        try:
            await asyncio.gather(server.wait_closed(), forwarder_task)
        except KeyboardInterrupt:
            print("\n🛑 Shutting down bridge...")
            self.running = False
            if self.serial_connection:
                self.serial_connection.close()

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description='ESP32 to WebSocket Bridge')
    parser.add_argument('--serial-port', default=None, 
                       help='Serial port for ESP32 (default: auto-detect)')
    parser.add_argument('--baud-rate', type=int, default=115200,
                       help='Baud rate for serial communication (default: 115200)')
    parser.add_argument('--websocket-port', type=int, default=8765,
                       help='WebSocket server port (default: 8765)')
    
    args = parser.parse_args()
    
    bridge = ESP32WebSocketBridge(
        serial_port=args.serial_port,
        baud_rate=args.baud_rate,
        websocket_port=args.websocket_port
    )
    
    try:
        asyncio.run(bridge.start_server())
    except KeyboardInterrupt:
        print("\n👋 Bridge stopped by user")
    except Exception as e:
        print(f"💥 Bridge crashed: {e}")

if __name__ == '__main__':
    main() 