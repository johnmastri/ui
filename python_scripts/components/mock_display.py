"""
Mock Display Component - Large parameter display and VU meter for the MIDI Controller.
Replicates the Vue.js MockDisplay functionality in Kivy.
"""

import math
import random
from kivy.uix.widget import Widget
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.graphics import Color, Rectangle, Line
from kivy.clock import Clock
from kivy.animation import Animation

class MockDisplay(Widget):
    def __init__(self, parameter_store, **kwargs):
        super().__init__(**kwargs)
        self.parameter_store = parameter_store
        self.size_hint = (1, 1)
        
        # Display state
        self.is_display_active = False
        self.display_text = ""
        self.display_value = ""
        self.fade_timer = None
        self.fade_delay = 3.0  # seconds
        
        # VU meter state
        self.vu_meter_value = -20.0
        self.vu_meter_db_text = "-20.0 dB"
        self.vu_meter_percentage = 0.67
        
        # Create display labels
        self.create_display_labels()
        
        # Bind drawing and positioning
        self.bind(pos=self.update_graphics, size=self.update_graphics)
        self.bind(pos=self.update_label_positions, size=self.update_label_positions)
        
        # Start VU meter animation
        self.start_vu_meter_animation()
        
    def create_display_labels(self):
        """Create labels for parameter and VU meter display"""
        # Parameter display labels
        self.param_name_label = Label(
            text="",
            font_size=36,
            color=(0, 1, 0.53, 1),  # Green
            size_hint=(None, None),
            opacity=0,
            halign='center',
            valign='top'
        )
        self.param_name_label.bind(size=self._update_param_name_text_size)
        self.add_widget(self.param_name_label)
        
        self.param_value_label = Label(
            text="",
            font_size=72,
            color=(1, 1, 1, 1),  # White
            size_hint=(None, None),
            opacity=0,
            halign='center',
            valign='center'
        )
        self.param_value_label.bind(size=self._update_param_value_text_size)
        self.add_widget(self.param_value_label)
        
        # VU meter labels
        self.vu_meter_label = Label(
            text="VU Meter",
            font_size=32,
            color=(0, 1, 1, 1),  # Cyan
            size_hint=(None, None),
            opacity=1,
            halign='center',
            valign='top'
        )
        self.vu_meter_label.bind(size=self._update_vu_meter_text_size)
        self.add_widget(self.vu_meter_label)
        
        self.vu_db_label = Label(
            text="-20.0 dB",
            font_size=36,
            color=(1, 1, 1, 1),  # White
            size_hint=(None, None),
            opacity=1,
            halign='center',
            valign='center'
        )
        self.vu_db_label.bind(size=self._update_vu_db_text_size)
        self.add_widget(self.vu_db_label)
        
        # Position labels initially
        self.update_label_positions()
        
    def _update_param_name_text_size(self, instance, size):
        """Update parameter name label text size for proper centering"""
        instance.text_size = size
        
    def _update_param_value_text_size(self, instance, size):
        """Update parameter value label text size for proper centering"""
        instance.text_size = size
        
    def _update_vu_meter_text_size(self, instance, size):
        """Update VU meter label text size for proper centering"""
        instance.text_size = size
        
    def _update_vu_db_text_size(self, instance, size):
        """Update VU dB label text size for proper centering"""
        instance.text_size = size
        
    def update_label_positions(self, *args):
        """Update label positions to center them in the widget"""
        # Set label sizes to match parent widget
        for label in [self.param_name_label, self.param_value_label, self.vu_meter_label, self.vu_db_label]:
            label.size = self.size
            label.pos = self.pos
            label.text_size = self.size
        
    def update_graphics(self, *args):
        """Update the display graphics"""
        self.canvas.before.clear()
        
        with self.canvas.before:
            # Background
            Color(0.1, 0.1, 0.1, 1)
            Rectangle(pos=self.pos, size=self.size)
            
            # Border
            Color(0.2, 0.2, 0.2, 1)
            Line(rectangle=(self.x, self.y, self.width, self.height), width=2)
            
            # Draw VU meter bar if in VU meter mode
            if not self.is_display_active and self.vu_meter_label.opacity > 0:
                self.draw_vu_meter_bar()
                
    def draw_vu_meter_bar(self):
        """Draw the VU meter bar"""
        # Calculate bar dimensions
        bar_width = min(300, self.width * 0.6)
        bar_height = 20
        bar_x = self.x + (self.width - bar_width) / 2
        bar_y = self.y + self.height / 2 - 50
        
        # Bar background
        Color(0.2, 0.2, 0.2, 1)
        Rectangle(pos=(bar_x, bar_y), size=(bar_width, bar_height))
        
        # Bar border
        Color(0.33, 0.33, 0.33, 1)
        Line(rectangle=(bar_x, bar_y, bar_width, bar_height), width=1)
        
        # Bar fill (gradient approximation)
        fill_width = bar_width * (self.vu_meter_percentage / 100)
        segments = 20
        segment_width = fill_width / segments if segments > 0 else 0
        
        for i in range(int(segments)):
            progress = i / segments
            # Green -> Yellow -> Orange -> Red gradient
            if progress < 0.25:
                r, g, b = progress * 4, 1, 0
            elif progress < 0.5:
                r, g, b = 1, 1 - (progress - 0.25) * 2, 0
            elif progress < 0.75:
                r, g, b = 1, 0.5 - (progress - 0.5) * 2, 0
            else:
                r, g, b = 1, 0, 0
                
            Color(r, g, b, 1)
            seg_x = bar_x + i * segment_width
            Rectangle(pos=(seg_x, bar_y), size=(segment_width, bar_height))
            
    def show_parameter(self, param_name, param_value, param_text):
        """Show parameter in large display mode"""
        self.display_text = param_name
        self.display_value = param_text
        
        # Update labels
        self.param_name_label.text = param_name.upper()
        self.param_value_label.text = param_text
        
        # Adjust font size for long text
        text_length = len(param_text)
        if text_length > 10:
            self.param_value_label.font_size = 48
        elif text_length > 8:
            self.param_value_label.font_size = 56
        elif text_length > 6:
            self.param_value_label.font_size = 64
        else:
            self.param_value_label.font_size = 72
        
        # Cancel existing timer
        if self.fade_timer:
            self.fade_timer.cancel()
            
        # Fade to parameter display
        self.fade_to_parameter_display()
        
        # Set timer to fade back to VU meter
        self.fade_timer = Clock.schedule_once(self.fade_to_vu_meter, self.fade_delay)
        
    def fade_to_parameter_display(self):
        """Animate fade to parameter display"""
        self.is_display_active = True
        
        # Fade out VU meter
        Animation(opacity=0, duration=0.3).start(self.vu_meter_label)
        Animation(opacity=0, duration=0.3).start(self.vu_db_label)
        
        # Fade in parameter display
        Animation(opacity=1, duration=0.3).start(self.param_name_label)
        Animation(opacity=1, duration=0.3).start(self.param_value_label)
        
        Clock.schedule_once(lambda dt: self.update_graphics(), 0.1)
        
    def fade_to_vu_meter(self, *args):
        """Animate fade back to VU meter"""
        self.is_display_active = False
        
        # Fade out parameter display
        Animation(opacity=0, duration=1.0).start(self.param_name_label)
        Animation(opacity=0, duration=1.0).start(self.param_value_label)
        
        # Fade in VU meter
        Animation(opacity=1, duration=1.0).start(self.vu_meter_label)
        Animation(opacity=1, duration=1.0).start(self.vu_db_label)
        
        Clock.schedule_once(lambda dt: self.update_graphics(), 1.1)
        
    def start_vu_meter_animation(self):
        """Start the VU meter animation"""
        Clock.schedule_interval(self.update_vu_meter, 0.1)
        
    def update_vu_meter(self, *args):
        """Update VU meter with simulated audio levels"""
        # Simulate realistic VU meter movement
        base_level = -45 + random.random() * 15  # -45 to -30 dB
        peak_level = base_level + random.random() * 10  # Add peaks
        
        self.vu_meter_value = max(-60, min(0, peak_level))
        self.vu_meter_db_text = f"{self.vu_meter_value:.1f} dB"
        
        # Convert dB to percentage
        self.vu_meter_percentage = max(0, min(100, ((self.vu_meter_value + 60) / 60) * 100))
        
        # Update label
        self.vu_db_label.text = self.vu_meter_db_text
        
        # Update graphics if in VU meter mode
        if not self.is_display_active and self.vu_meter_label.opacity > 0:
            self.update_graphics()

class MockDisplayContainer(BoxLayout):
    """Container for MockDisplay with header"""
    
    def __init__(self, parameter_store, **kwargs):
        super().__init__(**kwargs)
        self.orientation = 'vertical'
        self.parameter_store = parameter_store
        
        # Header
        self.create_header()
        
        # Mock display
        self.mock_display = MockDisplay(parameter_store)
        self.add_widget(self.mock_display)
        
    def create_header(self):
        """Create header with device info"""
        header = BoxLayout(orientation='horizontal', size_hint_y=None, height=40)
        
        # Settings icon placeholder
        settings_label = Label(
            text='⚙️',
            color=(0.53, 0.53, 0.53, 1),
            font_size=16,
            size_hint_x=None,
            width=40,
            halign='center'
        )
        settings_label.bind(size=settings_label.setter('text_size'))
        header.add_widget(settings_label)
        
        # Device name
        device_label = Label(
            text='MasterCtrl Device',
            color=(0.67, 0.67, 0.67, 1),
            font_size=12,
            size_hint_x=0.4,
            halign='left'
        )
        device_label.bind(size=device_label.setter('text_size'))
        header.add_widget(device_label)
        
        # Channel name  
        channel_label = Label(
            text='Channel 1',
            color=(0, 1, 0.53, 1),
            font_size=14,
            size_hint_x=0.4,
            halign='right'
        )
        channel_label.bind(size=channel_label.setter('text_size'))
        header.add_widget(channel_label)
        
        self.add_widget(header)
        
    def show_parameter(self, param_name, param_value, param_text):
        """Show parameter in the display"""
        self.mock_display.show_parameter(param_name, param_value, param_text) 