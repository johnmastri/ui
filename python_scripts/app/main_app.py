"""
Main Application - Handles the Kivy app lifecycle and keyboard shortcuts.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from kivy.app import App
from kivy.core.window import Window
from utils.config import setup_kivy_config
from .main_widget import MIDIControllerWidget

class MIDIControllerApp(App):
    def build(self):
        # Setup Kivy configuration
        setup_kivy_config()
        
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