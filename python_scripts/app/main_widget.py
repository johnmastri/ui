"""
Main Widget - Contains the primary UI logic and knob management for the MIDI Controller.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.clock import Clock
from kivy.core.window import Window

from stores.parameter_store import ParameterStore
from stores.websocket_manager import WebSocketManager
from components.knob_components import KnobContainer
from components.mock_display import MockDisplayContainer

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
        
        # View state
        self.current_view = 'knobs'  # 'knobs' or 'display'
        
    def _create_ui(self):
        """Create the user interface"""
        # Top bar with title and controls
        top_bar = BoxLayout(orientation='horizontal', size_hint_y=None, height=40)
        
        # Title
        title = Label(
            text='MIDI Controller - Python Native (Vue.js Compatible)',
            color=(0, 1, 1, 1),
            font_size=14,
            size_hint_x=0.3
        )
        top_bar.add_widget(title)
        
        # View toggle button
        self.view_toggle_btn = Button(
            text='Display View',
            size_hint_x=None,
            width=120,
            height=35
        )
        self.view_toggle_btn.bind(on_press=self.toggle_view)
        top_bar.add_widget(self.view_toggle_btn)
        
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
        
        # Content area
        self.content_area = BoxLayout(orientation='vertical')
        self.add_widget(self.content_area)
        
        # Create both views
        self.create_knob_view()
        self.create_display_view()
        
        # Show knobs view initially
        self.show_knobs_view()
        
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
        row = BoxLayout(orientation='horizontal', spacing=10, size_hint_y=None, height=140)
        
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
        
    def create_knob_view(self):
        """Create the knob view"""
        self.knob_area = BoxLayout(orientation='vertical', spacing=2)
        
    def create_display_view(self):
        """Create the display view"""
        self.display_container = MockDisplayContainer(self.parameter_store)
        # Register display container with WebSocket manager for updates
        self.websocket_manager.register_display_container(self.display_container)
        
    def show_knobs_view(self):
        """Show the knobs view"""
        self.content_area.clear_widgets()
        self.content_area.add_widget(self.knob_area)
        self.current_view = 'knobs'
        self.view_toggle_btn.text = 'Display View'
        
    def show_display_view(self):
        """Show the display view"""
        self.content_area.clear_widgets()
        self.content_area.add_widget(self.display_container)
        self.current_view = 'display'
        self.view_toggle_btn.text = 'Knobs View'
        
    def toggle_view(self, button):
        """Toggle between knobs and display view"""
        if self.current_view == 'knobs':
            self.show_display_view()
            print("📺 Switched to Display View")
        else:
            self.show_knobs_view()
            print("🎛️ Switched to Knobs View")
        
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
        """Update connection status with detailed information"""
        if self.websocket_manager.connected:
            param_count = len(self.parameter_store.parameters)
            current_url = self.websocket_manager.get_current_url()
            if current_url:
                # Extract just the IP and port for display
                url_display = current_url.replace('ws://', '').replace(':8765', '')
                self.status.text = f'WebSocket: Connected ✅ {url_display} ({param_count} params)'
            else:
                self.status.text = f'WebSocket: Connected ✅ ({param_count} params)'
            self.status.color = (0, 1, 0, 1)
        else:
            self.status.text = 'WebSocket: Disconnected ❌ (Auto-discovering...)'
            self.status.color = (1, 0, 0, 1)
            
    def print_connection_debug(self):
        """Print detailed connection information for debugging"""
        info = self.websocket_manager.get_connection_info()
        print("🔍 WebSocket Connection Debug Info:")
        print(f"  Connected: {info['connected']}")
        print(f"  Current URL: {info['current_url']}")
        print(f"  URLs tried: {info['tried_urls']}")
        print(f"  Available URLs: {info['urls']}")
        
        # Add keyboard shortcut to print debug info
        # Can be triggered by calling this method manually
        return info 