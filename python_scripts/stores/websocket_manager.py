"""
WebSocket Manager - Handles WebSocket communication for the MIDI Controller.
Manages connection, message handling, and parameter synchronization.
"""

import asyncio
import websockets
import json
import threading
import os
import socket
from datetime import datetime
from kivy.clock import Clock

class WebSocketManager:
    def __init__(self, parameter_store, urls=None):
        # Check environment variable first
        env_url = os.getenv('WEBSOCKET_URL')
        if env_url:
            self.urls = [env_url]
            print(f"🌍 Using WebSocket URL from environment: {env_url}")
        elif urls:
            self.urls = urls
        else:
            # Auto-discovery fallback
            self.urls = self._discover_urls()
            
        self.current_url = None
        self.websocket = None
        self.connected = False
        self.message_queue = []
        self.parameter_store = parameter_store
        self.knob_containers = {}  # Track knob containers for updates
        self.display_container = None  # Track display container for updates
        self.loop = None
        
    def _discover_urls(self):
        """Generate list of URLs to try based on network detection and common patterns"""
        urls = ["ws://localhost:8765", "ws://127.0.0.1:8765"]
        
        try:
            # Get local IP to guess network range
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            
            # Extract network prefix (e.g., 192.168.1.)
            network = '.'.join(local_ip.split('.')[:-1]) + '.'
            print(f"🔍 Detected network: {network}x")
            
            # Try common IPs in the same network
            for i in [1, 5, 100, 101, 102, 195, 200, 250]:
                ip = f"{network}{i}"
                if ip != local_ip:  # Don't try our own IP
                    urls.append(f"ws://{ip}:8765")
                    
        except Exception as e:
            print(f"⚠️ Network detection failed: {e}")
            # Fallback to common networks
            for network in ["192.168.1.", "192.168.0.", "10.0.0.", "172.16.0."]:
                for i in [1, 5, 100, 195]:
                    urls.append(f"ws://{network}{i}:8765")
                    
        # Add some specific known addresses
        known_addresses = [
            "ws://192.168.1.195:8765",  # Common Pi address
            "ws://192.168.1.5:8765",    # Common PC address
        ]
        
        for addr in known_addresses:
            if addr not in urls:
                urls.append(addr)
                
        print(f"🔍 Will try {len(urls)} possible WebSocket URLs")
        return urls
        
    def register_knob_container(self, param_id, container):
        """Register knob container for updates"""
        self.knob_containers[param_id] = container
        
    def register_display_container(self, container):
        """Register display container for updates"""
        self.display_container = container
        
    def start(self):
        """Start WebSocket connection in background thread"""
        self.thread = threading.Thread(target=self._run_websocket)
        self.thread.daemon = True
        self.thread.start()
        
    def _run_websocket(self):
        """Run WebSocket connection"""
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self._connect_with_fallback())
        
    async def _connect_with_fallback(self):
        """Try each URL until one works"""
        for url in self.urls:
            try:
                print(f"🔍 Trying {url}...")
                self.websocket = await asyncio.wait_for(
                    websockets.connect(url), 
                    timeout=3.0  # 3 second timeout per URL
                )
                self.current_url = url
                self.connected = True
                print(f"✅ Connected to {url}")
                
                # Send initial state request
                await self._send_state_request()
                
                # Send queued messages
                while self.message_queue:
                    message = self.message_queue.pop(0)
                    await self.websocket.send(json.dumps(message))
                    
                # Listen for incoming messages
                async for message in self.websocket:
                    await self._handle_incoming_message(message)
                    
                return  # Success - exit the function
                
            except asyncio.TimeoutError:
                print(f"⏰ Timeout connecting to {url}")
                continue
            except ConnectionRefusedError:
                print(f"🚫 Connection refused by {url}")
                continue
            except Exception as e:
                print(f"❌ Failed {url}: {e}")
                continue
                
        print("💥 Could not connect to any WebSocket server")
        print(f"💡 Tried {len(self.urls)} URLs. Check if server is running on port 8765")
        print("💡 Set WEBSOCKET_URL environment variable to specify exact URL")
        self.connected = False
        
    async def _handle_incoming_message(self, message_str):
        """Handle incoming WebSocket messages (matching Vue.js handlers)"""
        try:
            message = json.loads(message_str)
            message_type = message.get('type', 'unknown')
            
            print(f"📥 WebSocket: {message_type}")
            
            if message_type == 'parameter_structure_sync':
                await self._handle_structure_sync(message)
            elif message_type == 'parameter_value_sync':
                await self._handle_value_sync(message)
            elif message_type == 'parameter_color_sync':
                await self._handle_color_sync(message)
            elif message_type == 'request_parameter_state':
                await self._handle_parameter_state_request(message)
            else:
                print(f"⚠️ Unknown message type: {message_type}")
                
        except json.JSONDecodeError:
            print(f"❌ Invalid JSON: {message_str}")
        except Exception as e:
            print(f"❌ Error handling message: {e}")
            
    async def _handle_structure_sync(self, message):
        """Handle parameter structure sync (matching Vue.js logic)"""
        structure_hash = message.get('structure_hash')
        
        if structure_hash and structure_hash == self.parameter_store.current_structure_hash:
            return  # No changes needed
            
        parameters = message.get('parameters', [])
        if parameters:
            print(f"📡 Structure sync: {len(parameters)} parameters")
            
            # Clear and reload parameters
            self.parameter_store.parameters = []
            for param in parameters:
                self.parameter_store.add_parameter(param)
                
            self.parameter_store.current_structure_hash = structure_hash
            self.parameter_store.last_structure_update = datetime.now().timestamp() * 1000
            
            # Update UI on main thread
            Clock.schedule_once(lambda dt: self._update_all_knobs(), 0)
            
    async def _handle_value_sync(self, message):
        """Handle parameter value sync (matching Vue.js logic)"""
        updates = message.get('updates', [])
        
        for update in updates:
            param_id = update.get('id')
            value = update.get('value')
            
            if param_id and value is not None:
                # Update parameter store (no broadcasting to prevent feedback loop)
                param = self.parameter_store.update_parameter(param_id, value, should_broadcast=False)
                
                # Update RGB color if provided
                if update.get('rgbColor') and param:
                    param['rgbColor'] = update['rgbColor']
                    
                # Update UI on main thread
                if param:
                    Clock.schedule_once(lambda dt, pid=param_id, v=value, t=param['text']: self._update_knob_from_websocket(pid, v, t), 0)
                    # Trigger display update
                    Clock.schedule_once(lambda dt, p=param: self._trigger_display_update(p), 0)
                    
    async def _handle_color_sync(self, message):
        """Handle parameter color sync (matching Vue.js logic)"""
        updates = message.get('updates', [])
        
        for update in updates:
            param_id = update.get('id')
            param = self.parameter_store.find_parameter(param_id)
            
            if param:
                if update.get('color'):
                    param['color'] = update['color']
                    # Import here to avoid circular imports
                    from utils.color_utils import hex_to_rgb, rgb_to_hex
                    param['rgbColor'] = hex_to_rgb(update['color'])
                elif update.get('rgbColor'):
                    param['rgbColor'] = update['rgbColor']
                    from utils.color_utils import hex_to_rgb, rgb_to_hex
                    param['color'] = rgb_to_hex(update['rgbColor'])
                    
                # Update UI
                Clock.schedule_once(lambda dt, pid=param_id: self._update_knob_color(pid), 0)
                
    async def _handle_parameter_state_request(self, message):
        """Handle parameter state request (matching Vue.js logic)"""
        if self.parameter_store.parameters:
            await self._broadcast_structure()
            
    async def _send_state_request(self):
        """Send initial state request"""
        if not self.websocket:
            return
            
        request_payload = {
            "type": "request_parameter_state",
            "timestamp": int(datetime.now().timestamp() * 1000)
        }
        await self.websocket.send(json.dumps(request_payload))
        print("❓ Sent parameter state request")
        
    async def _broadcast_structure(self):
        """Broadcast current parameter structure"""
        if not self.parameter_store.parameters or not self.websocket:
            return
            
        structure_hash = self.parameter_store.generate_structure_hash()
        payload = {
            "type": "parameter_structure_sync",
            "structure_hash": structure_hash,
            "parameters": [{
                "id": p['id'],
                "name": p['name'],
                "value": p['value'],
                "min": p.get('min', 0),
                "max": p.get('max', 1),
                "step": p.get('step', 0.01),
                "format": p.get('format', 'percentage'),
                "defaultValue": p.get('defaultValue', 0.5),
                "color": p['color'],
                "rgbColor": p['rgbColor'],
                "ledCount": p.get('ledCount', 28)
            } for p in self.parameter_store.parameters],
            "timestamp": int(datetime.now().timestamp() * 1000)
        }
        
        await self.websocket.send(json.dumps(payload))
        print(f"📡 Broadcasted structure: {len(self.parameter_store.parameters)} parameters")
        
    def _update_all_knobs(self):
        """Update all knobs from parameter store"""
        for param in self.parameter_store.parameters:
            container = self.knob_containers.get(param['id'])
            if container:
                container.update_from_websocket(param['value'], param['text'])
                
    def _update_knob_from_websocket(self, param_id, value, text):
        """Update specific knob from WebSocket"""
        container = self.knob_containers.get(param_id)
        if container:
            container.update_from_websocket(value, text)
            
    def _update_knob_color(self, param_id):
        """Update knob color"""
        container = self.knob_containers.get(param_id)
        if container:
            container.knob.update_graphics()
            
    def _trigger_display_update(self, param):
        """Trigger display update for parameter changes from WebSocket"""
        if self.display_container:
            print(f"📺 WebSocket triggering display update: {param['name']} = {param['text']}")
            self.display_container.show_parameter(
                param['name'], 
                param['value'], 
                param['text']
            )
        else:
            print("⚠️ Display container not registered for WebSocket updates")
            
    def send_parameter_update(self, param_id, value, text, rgb_color):
        """Send parameter update via WebSocket (matching Vue.js format)"""
        message = {
            "type": "parameter_value_sync",
            "updates": [{
                "id": param_id,
                "value": value,
                "text": text,
                "rgbColor": rgb_color
            }],
            "timestamp": int(datetime.now().timestamp() * 1000)
        }
        
        if self.connected and self.websocket and self.loop:
            # Send immediately if connected
            future = asyncio.run_coroutine_threadsafe(
                self.websocket.send(json.dumps(message)), self.loop
            )
            try:
                future.result(timeout=0.1)
                print(f"📤 Sent parameter update: {param_id} = {value}")
            except:
                self.message_queue.append(message)
        else:
            # Queue message if not connected
            self.message_queue.append(message)
            print(f"📤 Queued parameter update: {param_id} = {value}")
        
    async def _connect(self):
        """Legacy connect method - kept for compatibility"""
        return await self._connect_with_fallback()
        
    def get_current_url(self):
        """Get the currently connected URL"""
        return self.current_url
        
    def get_connection_info(self):
        """Get connection information for debugging"""
        return {
            "connected": self.connected,
            "current_url": self.current_url,
            "tried_urls": len(self.urls),
            "urls": self.urls[:5] if len(self.urls) > 5 else self.urls  # Show first 5 for brevity
        } 