from kivy.app import App
from kivy.uix.widget import Widget
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.boxlayout import BoxLayout
from kivy.graphics import Color, Ellipse, Line
from kivy.clock import Clock
from kivy.config import Config
from kivy.core.window import Window
import math
import asyncio
import websockets
import json
import threading
from datetime import datetime
import base64
import hashlib

# Configure Kivy for 800x480 windowed (not fullscreen by default)
# Clear any cached fullscreen settings
import os
kivy_config_dir = os.path.expanduser('~/.kivy')
config_file = os.path.join(kivy_config_dir, 'config.ini')
if os.path.exists(config_file):
    try:
        os.remove(config_file)
        print("🗑️ Cleared Kivy config cache")
    except:
        pass

Config.set('graphics', 'width', '800')
Config.set('graphics', 'height', '480')
Config.set('graphics', 'fullscreen', '0')
Config.set('graphics', 'borderless', '0')
Config.write()

class ParameterStore:
    """Parameter management system matching Vue.js parameterStore functionality"""
    
    def __init__(self):
        self.parameters = []
        self.current_structure_hash = None
        self.last_structure_update = None
        
        # Color presets matching Vue.js
        self.color_presets = {
            'Input Gain': '#4CAF50',    # Green
            'Drive': '#FF5722',         # Orange-Red
            'Tone': '#2196F3',          # Blue
            'Output Level': '#9C27B0',  # Purple
            'Mix': '#FF9800',           # Orange
            'Attack': '#00BCD4',        # Cyan
            'Release': '#3F51B5',       # Indigo
            'Threshold': '#E91E63',     # Pink
            'Ratio': '#795548',         # Brown
            'Knee': '#607D8B'           # Blue-Grey
        }
        
    def find_parameter(self, param_id):
        """Find parameter by ID"""
        return next((p for p in self.parameters if p['id'] == param_id), None)
        
    def add_parameter(self, parameter):
        """Add or update parameter (matching Vue.js logic)"""
        existing_index = next((i for i, p in enumerate(self.parameters) if p['id'] == parameter['id']), -1)
        
        if existing_index != -1:
            # Update existing parameter
            self.parameters[existing_index].update({
                **self.parameters[existing_index],
                **parameter,
                'text': parameter.get('text') or self.generate_parameter_text(parameter['name'], parameter['value']),
                'color': parameter.get('color') or self.color_presets.get(parameter['name'], '#4CAF50'),
                'rgbColor': parameter.get('rgbColor') or self.hex_to_rgb(parameter.get('color') or self.color_presets.get(parameter['name'], '#4CAF50')),
                'ledCount': parameter.get('ledCount', 28)
            })
        else:
            # Add new parameter
            new_parameter = {
                **parameter,
                'text': parameter.get('text') or self.generate_parameter_text(parameter['name'], parameter['value']),
                'color': parameter.get('color') or self.color_presets.get(parameter['name'], '#4CAF50'),
                'rgbColor': parameter.get('rgbColor') or self.hex_to_rgb(parameter.get('color') or self.color_presets.get(parameter['name'], '#4CAF50')),
                'ledCount': parameter.get('ledCount', 28)
            }
            self.parameters.append(new_parameter)
            
    def update_parameter(self, param_id, value, should_broadcast=True):
        """Update parameter value (matching Vue.js logic)"""
        param = self.find_parameter(param_id)
        if param:
            param['value'] = max(0, min(1, value))
            param['text'] = self.generate_parameter_text(param['name'], param['value'])
            return param
        return None
        
    def generate_parameter_text(self, name, value):
        """Generate parameter text matching Vue.js logic exactly"""
        if name in ["Input Gain", "Drive", "Tone", "Output Level", "Mix"]:
            return f"{round(value * 100)}%"
        elif name == "Attack":
            return f"{round(value * 100)}ms"
        elif name == "Release":
            return f"{round(value * 200)}ms"
        elif name == "Threshold":
            return f"{round((value - 0.5) * 48)}dB"
        elif name == "Ratio":
            ratios = ['1:1', '2:1', '4:1', '8:1', '16:1', '∞:1']
            ratio_index = math.floor(value * (len(ratios) - 1))
            return ratios[ratio_index]
        elif name == "Knee":
            knees = ['Hard', 'Soft', 'Medium']
            knee_index = math.floor(value * (len(knees) - 1))
            return knees[knee_index]
        else:
            return f"{round(value * 100)}%"
            
    def hex_to_rgb(self, hex_color):
        """Convert hex color to RGB (matching Vue.js logic)"""
        if not hex_color.startswith('#'):
            hex_color = '#' + hex_color
        try:
            return {
                'r': int(hex_color[1:3], 16),
                'g': int(hex_color[3:5], 16),
                'b': int(hex_color[5:7], 16)
            }
        except:
            return {'r': 0, 'g': 0, 'b': 0}
            
    def rgb_to_hex(self, rgb):
        """Convert RGB to hex color"""
        return f"#{rgb['r']:02x}{rgb['g']:02x}{rgb['b']:02x}"
        
    def generate_structure_hash(self):
        """Generate structure hash matching Vue.js logic"""
        structure = [{
            'id': p['id'],
            'name': p['name'],
            'min': p.get('min', 0),
            'max': p.get('max', 1),
            'step': p.get('step', 0.01),
            'format': p.get('format', 'percentage')
        } for p in self.parameters]
        
        structure_json = json.dumps(structure, sort_keys=True)
        return base64.b64encode(structure_json.encode()).decode()
        
    def load_mock_data(self):
        """Load mock data matching Vue.js mockData exactly"""
        mock_parameters = [
            {
                'id': 'input-gain',
                'index': 0,
                'name': "Input Gain",
                'value': 0.75,
                'defaultValue': 0.5,
                'label': "Input",
                'text': "75%"
            },
            {
                'id': 'drive',
                'index': 1,
                'name': "Drive",
                'value': 0.3,
                'defaultValue': 0.0,
                'label': "Drive",
                'text': "30%"
            },
            {
                'id': 'tone',
                'index': 2,
                'name': "Tone",
                'value': 0.6,
                'defaultValue': 0.5,
                'label': "Tone",
                'text': "60%"
            },
            {
                'id': 'output-level',
                'index': 3,
                'name': "Output Level",
                'value': 0.8,
                'defaultValue': 0.7,
                'label': "Output",
                'text': "80%"
            },
            {
                'id': 'mix',
                'index': 4,
                'name': "Mix",
                'value': 0.5,
                'defaultValue': 0.5,
                'label': "Mix",
                'text': "50%"
            },
            {
                'id': 'attack',
                'index': 5,
                'name': "Attack",
                'value': 0.2,
                'defaultValue': 0.1,
                'label': "Attack",
                'text': "20ms"
            },
            {
                'id': 'release',
                'index': 6,
                'name': "Release",
                'value': 0.4,
                'defaultValue': 0.3,
                'label': "Release",
                'text': "80ms"
            },
            {
                'id': 'threshold',
                'index': 7,
                'name': "Threshold",
                'value': 0.6,
                'defaultValue': 0.5,
                'label': "Threshold",
                'text': "5dB"
            }
        ]
        
        for param in mock_parameters:
            self.add_parameter(param)
            
        print(f"📊 Loaded {len(mock_parameters)} mock parameters")

class ParameterKnob(Widget):
    def __init__(self, name, param_id, parameter_store, websocket_manager, value=0.5, **kwargs):
        super().__init__(**kwargs)
        self.name = name
        self.param_id = param_id
        self.value = value
        self.parameter_store = parameter_store
        self.websocket_manager = websocket_manager
        self.size_hint = (None, None)
        self.size = (100, 100)
        self.bind(pos=self.update_graphics, size=self.update_graphics)
        
    def update_graphics(self, *args):
        self.canvas.clear()
        
        # Get current parameter data
        param = self.parameter_store.find_parameter(self.param_id)
        if param:
            self.value = param['value']
            rgb_color = param.get('rgbColor', {'r': 0, 'g': 255, 'b': 0})
        else:
            rgb_color = {'r': 0, 'g': 255, 'b': 0}
        
        with self.canvas:
            # Knob background
            Color(0.2, 0.2, 0.2)
            Ellipse(pos=(self.x + 10, self.y + 20), size=(60, 60))
            
            # Knob border
            Color(0.5, 0.5, 0.5)
            Line(ellipse=(self.x + 10, self.y + 20, 60, 60), width=2)
            
            # Indicator line (using parameter color)
            Color(rgb_color['r']/255, rgb_color['g']/255, rgb_color['b']/255)
            angle = (self.value * 270) - 135  # -135° to +135°
            center_x = self.x + 40
            center_y = self.y + 50
            end_x = center_x + 25 * math.cos(math.radians(angle))
            end_y = center_y + 25 * math.sin(math.radians(angle))
            Line(points=[center_x, center_y, end_x, end_y], width=3)
    
    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos):
            return True
        return False
    
    def on_touch_move(self, touch):
        if self.collide_point(*touch.pos):
            # Update value based on vertical drag
            center_y = self.y + 50
            relative_y = touch.y - center_y
            old_value = self.value
            self.value = max(0, min(1, 0.5 + relative_y / 80))
            
            if abs(self.value - old_value) > 0.01:  # Threshold to prevent spam
                # Update parameter store
                param = self.parameter_store.update_parameter(self.param_id, self.value, should_broadcast=True)
                
                if param:
                    self.update_graphics()
                    
                    # Send WebSocket message (with feedback loop prevention)
                    self.websocket_manager.send_parameter_update(self.param_id, self.value, param['text'], param['rgbColor'])
                    
                    # Update label
                    self.parent.update_label(param['text'])
                    
            return True
        return False

class KnobLabel(Label):
    def __init__(self, knob_name, **kwargs):
        super().__init__(**kwargs)
        self.knob_name = knob_name
        self.text = f"{knob_name}\n50%"
        self.color = (1, 1, 1, 1)
        self.size_hint = (None, None)
        self.size = (100, 30)
        self.font_size = 12
        
    def update_text(self, text):
        """Update label text"""
        self.text = f"{self.knob_name}\n{text}"

class KnobContainer(BoxLayout):
    def __init__(self, name, param_id, parameter_store, websocket_manager, **kwargs):
        super().__init__(**kwargs)
        self.orientation = 'vertical'
        self.size_hint_x = None
        self.width = 100
        
        # Create knob
        self.knob = ParameterKnob(
            name=name, 
            param_id=param_id,
            parameter_store=parameter_store,
            websocket_manager=websocket_manager
        )
        self.add_widget(self.knob)
        
        # Create label
        self.label = KnobLabel(knob_name=name)
        self.add_widget(self.label)
        
    def update_label(self, text):
        """Update the knob label"""
        self.label.update_text(text)
        
    def update_from_websocket(self, value, text):
        """Update knob from WebSocket message (no broadcasting)"""
        self.knob.value = value
        self.knob.update_graphics()
        self.update_label(text)

class WebSocketManager:
    def __init__(self, parameter_store, url="ws://192.168.1.195:8765"):
        self.url = url
        self.websocket = None
        self.connected = False
        self.message_queue = []
        self.parameter_store = parameter_store
        self.knob_containers = {}  # Track knob containers for updates
        self.loop = None
        
    def register_knob_container(self, param_id, container):
        """Register knob container for updates"""
        self.knob_containers[param_id] = container
        
    def start(self):
        """Start WebSocket connection in background thread"""
        self.thread = threading.Thread(target=self._run_websocket)
        self.thread.daemon = True
        self.thread.start()
        
    def _run_websocket(self):
        """Run WebSocket connection"""
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self._connect())
        
    async def _connect(self):
        """Connect to WebSocket server with message handling"""
        try:
            print(f"🔗 Connecting to {self.url}...")
            self.websocket = await websockets.connect(self.url)
            self.connected = True
            print("✅ WebSocket connected!")
            
            # Send initial state request
            await self._send_state_request()
            
            # Send queued messages
            while self.message_queue:
                message = self.message_queue.pop(0)
                await self.websocket.send(json.dumps(message))
                
            # Listen for incoming messages
            async for message in self.websocket:
                await self._handle_incoming_message(message)
                
        except Exception as e:
            print(f"❌ WebSocket error: {e}")
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
                    
    async def _handle_color_sync(self, message):
        """Handle parameter color sync (matching Vue.js logic)"""
        updates = message.get('updates', [])
        
        for update in updates:
            param_id = update.get('id')
            param = self.parameter_store.find_parameter(param_id)
            
            if param:
                if update.get('color'):
                    param['color'] = update['color']
                    param['rgbColor'] = self.parameter_store.hex_to_rgb(update['color'])
                elif update.get('rgbColor'):
                    param['rgbColor'] = update['rgbColor']
                    param['color'] = self.parameter_store.rgb_to_hex(update['rgbColor'])
                    
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

class MIDIControllerWidget(BoxLayout):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.orientation = 'vertical'
        self.padding = 10
        self.spacing = 5
        
        # Initialize parameter store
        self.parameter_store = ParameterStore()
        
        # Initialize WebSocket
        self.websocket_manager = WebSocketManager(self.parameter_store)
        self.websocket_manager.start()
        
        # Create UI
        self._create_ui()
        
        # Load initial data and request state
        Clock.schedule_once(self._initialize_data, 1.0)
        
        # Update status periodically
        Clock.schedule_interval(self.update_status, 1.0)
        
        # Track fullscreen state
        self.is_fullscreen = False
        
    def _create_ui(self):
        """Create the user interface"""
        # Top bar with title and controls
        top_bar = BoxLayout(orientation='horizontal', size_hint_y=None, height=40)
        
        # Title
        title = Label(
            text='MIDI Controller - Python Native (Vue.js Compatible)',
            color=(0, 1, 1, 1),
            font_size=14,
            size_hint_x=0.5
        )
        top_bar.add_widget(title)
        
        # Fullscreen button
        self.fullscreen_btn = Button(
            text='Fullscreen',
            size_hint_x=None,
            width=100,
            height=35
        )
        self.fullscreen_btn.bind(on_press=self.toggle_fullscreen)
        top_bar.add_widget(self.fullscreen_btn)
        
        # Status
        self.status = Label(
            text='WebSocket: Connecting...',
            color=(1, 1, 0, 1),
            font_size=12,
            size_hint_x=0.3
        )
        top_bar.add_widget(self.status)
        
        self.add_widget(top_bar)
        
        # Knob area
        self.knob_area = BoxLayout(orientation='vertical', spacing=5)
        self.add_widget(self.knob_area)
        
    def _initialize_data(self, dt):
        """Initialize data and create knobs"""
        # Load mock data
        self.parameter_store.load_mock_data()
        
        # Create knobs from parameter store
        self._create_knobs_from_store()
        
        print("🎛️ UI initialized with mock data")
        
    def _create_knobs_from_store(self):
        """Create knobs from parameter store"""
        # Clear existing knobs
        self.knob_area.clear_widgets()
        
        # Create knobs in rows of 4
        params = self.parameter_store.parameters
        for i in range(0, len(params), 4):
            row_params = params[i:i+4]
            row = self._create_knob_row(row_params)
            self.knob_area.add_widget(row)
            
    def _create_knob_row(self, parameters):
        """Create a row of knobs"""
        row = BoxLayout(orientation='horizontal', spacing=10)
        
        for param in parameters:
            container = KnobContainer(
                name=param['name'],
                param_id=param['id'],
                parameter_store=self.parameter_store,
                websocket_manager=self.websocket_manager
            )
            
            # Register container for updates
            self.websocket_manager.register_knob_container(param['id'], container)
            
            # Set initial label
            container.update_label(param['text'])
            
            row.add_widget(container)
            
        return row
        
    def toggle_fullscreen(self, button):
        """Toggle fullscreen mode"""
        self.is_fullscreen = not self.is_fullscreen
        
        if self.is_fullscreen:
            # Enter fullscreen
            Window.fullscreen = 'auto'
            self.fullscreen_btn.text = 'Windowed'
            print("🖥️ Entered fullscreen mode")
        else:
            # Exit fullscreen
            Window.fullscreen = False
            Window.size = (800, 480)
            self.fullscreen_btn.text = 'Fullscreen'
            print("🪟 Entered windowed mode")
        
    def update_status(self, dt):
        """Update connection status"""
        if self.websocket_manager.connected:
            param_count = len(self.parameter_store.parameters)
            self.status.text = f'WebSocket: Connected ✅ ({param_count} params)'
            self.status.color = (0, 1, 0, 1)
        else:
            self.status.text = 'WebSocket: Disconnected ❌'
            self.status.color = (1, 0, 0, 1)

class MIDIControllerApp(App):
    def build(self):
        # Force windowed mode
        Window.fullscreen = False
        Window.size = (800, 480)
        Window.bind(on_keyboard=self.on_keyboard)
        return MIDIControllerWidget()
        
    def on_keyboard(self, window, key, *args):
        """Handle keyboard shortcuts"""
        if key == 27:  # ESC key
            if self.root.is_fullscreen:
                self.root.toggle_fullscreen(None)
            return True
        elif key == 282:  # F11 key
            self.root.toggle_fullscreen(None)
            return True
        return False
        
    def on_stop(self):
        """Clean up WebSocket connection"""
        if hasattr(self.root, 'websocket_manager'):
            self.root.websocket_manager.connected = False

if __name__ == '__main__':
    MIDIControllerApp().run()