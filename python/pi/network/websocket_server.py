import asyncio
import websockets
import json
from datetime import datetime

from utils.message_handler import (
    parse_message, build_startup, build_heartbeat, 
    build_encoder_update, build_button_press, build_bridge_status
)

class WebSocketServer:
    def __init__(self, ip, port, device_id, version):
        self.ip = ip
        self.port = port
        self.device_id = device_id
        self.version = version
        
        self.clients = set()
        self.led_controller = None
        self.encoder_callbacks = {}
        
        self.stats = {
            'messages_sent': 0,
            'messages_received': 0,
            'client_count': 0,
            'start_time': datetime.now()
        }
    
    def set_led_controller(self, controller):
        self.led_controller = controller
    
    def register_encoder_callback(self, encoder_id, callback):
        self.encoder_callbacks[encoder_id] = callback
    
    async def handler(self, websocket):
        client_addr = websocket.remote_address
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        print(f"[{timestamp}] [WS] Client connected: {client_addr}")
        
        self.clients.add(websocket)
        self.stats['client_count'] = len(self.clients)
        
        startup_msg = build_startup(self.device_id, self.version, self.ip)
        await self.send_to_client(websocket, startup_msg)
        
        try:
            async for message in websocket:
                await self.handle_message(websocket, message)
        except websockets.exceptions.ConnectionClosed:
            pass
        except Exception as e:
            print(f"[WS] Error for {client_addr}: {e}")
        finally:
            self.clients.discard(websocket)
            self.stats['client_count'] = len(self.clients)
            print(f"[WS] Client disconnected: {client_addr}")
    
    async def handle_message(self, websocket, message_str):
        self.stats['messages_received'] += 1
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        print(f"[{timestamp}] [WS] Received: {message_str[:100]}...")
        
        message = parse_message(message_str)
        if not message:
            print("[WS] Invalid JSON")
            return
        
        message_type = message.get('type', '')
        
        if message_type == 'led_update':
            await self.handle_led_update(message)
        
        elif message_type == 'system_command':
            await self.handle_system_command(message)
        
        elif message_type == 'parameter_structure_sync':
            print(f"[WS] Broadcasting parameter structure to {len(self.clients)} clients")
            await self.broadcast(message_str, exclude=websocket)
        
        elif message_type == 'parameter_value_sync':
            print(f"[WS] Broadcasting parameter values to {len(self.clients)} clients")
            await self.broadcast(message_str, exclude=websocket)
        
        elif message_type == 'parameter_color_sync':
            print(f"[WS] Broadcasting color changes to {len(self.clients)} clients")
            await self.broadcast(message_str, exclude=websocket)
        
        elif message_type == 'bridge_command':
            await self.handle_bridge_command(websocket, message)
    
    async def handle_led_update(self, message):
        if not self.led_controller:
            return
        
        try:
            color = message.get('color', {})
            r = color.get('r', 0)
            g = color.get('g', 0)
            b = color.get('b', 0)
            
            if 'led_start' in message and 'led_count' in message:
                led_start = message.get('led_start')
                led_count = message.get('led_count')
                self.led_controller.set_led_range(led_start, led_count, r, g, b)
            else:
                encoder_id = message.get('encoder_id', 0)
                pattern = message.get('pattern', 'solid')
                value = message.get('value', 0.0)
                self.led_controller.update_encoder_ring(encoder_id, r, g, b, pattern, value)
        except Exception as e:
            print(f"[WS] Error handling LED update: {e}")
    
    async def handle_system_command(self, message):
        if not self.led_controller:
            return
        
        command = message.get('command', '')
        parameter = message.get('parameter', '')
        
        print(f"[WS] System command: {command} = {parameter}")
        
        if command == 'brightness':
            brightness = int(parameter) if parameter else 8
            self.led_controller.set_brightness(brightness)
        elif command == 'clear_leds':
            self.led_controller.clear_all()
        elif command == 'test_mode':
            print(f"[WS] Test mode: {parameter}")
    
    async def handle_bridge_command(self, websocket, message):
        command = message.get('command', '')
        
        if command == 'get_status':
            status_msg = build_bridge_status(
                self.device_id,
                True,
                self.stats.copy()
            )
            await self.send_to_client(websocket, status_msg)
    
    async def send_to_client(self, websocket, message):
        try:
            message_str = json.dumps(message)
            await websocket.send(message_str)
            self.stats['messages_sent'] += 1
        except Exception as e:
            print(f"[WS] Error sending to client: {e}")
    
    async def broadcast(self, message_str, exclude=None):
        clients_copy = self.clients.copy()
        
        for client in clients_copy:
            if client == exclude:
                continue
            try:
                await client.send(message_str)
                self.stats['messages_sent'] += 1
            except:
                self.clients.discard(client)
    
    async def broadcast_message(self, message):
        message_str = json.dumps(message)
        await self.broadcast(message_str)
    
    async def start(self):
        import socket
        
        server = await websockets.serve(
            self.handler,
            self.ip,
            self.port,
            ping_interval=20,
            ping_timeout=10
        )
        
        try:
            server.sockets[0].setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            try:
                server.sockets[0].setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
            except (AttributeError, OSError):
                pass
            print("[WS] Socket reuse options enabled")
        except Exception as e:
            print(f"[WS] Note: Could not set socket options: {e}")
        
        if self.ip == "0.0.0.0":
            import subprocess
            try:
                result = subprocess.run(['hostname', '-I'], capture_output=True, text=True, timeout=2)
                if result.returncode == 0:
                    ips = result.stdout.strip().split()
                    print(f"[WS] WebSocket server running on all interfaces (port {self.port})")
                    for ip in ips:
                        print(f"[WS]   Available at: ws://{ip}:{self.port}")
                else:
                    print(f"[WS] WebSocket server running on ws://{self.ip}:{self.port}")
            except Exception:
                print(f"[WS] WebSocket server running on ws://{self.ip}:{self.port}")
        else:
            print(f"[WS] WebSocket server running on ws://{self.ip}:{self.port}")
        
        return server

