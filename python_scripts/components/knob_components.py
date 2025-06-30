"""
Knob UI Components for the MIDI Controller application.
Contains ParameterKnob, KnobLabel, and KnobContainer classes.
"""

import math
from kivy.uix.widget import Widget
from kivy.uix.label import Label
from kivy.uix.boxlayout import BoxLayout
from kivy.graphics import Color, Ellipse, Line

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
                    
                    # Trigger display update
                    self.trigger_display_update(param)
                    
            return True
        return False
    
    def trigger_display_update(self, param):
        """Trigger display update for parameter changes"""
        # Find the main widget through parent hierarchy
        widget = self.parent
        while widget and not hasattr(widget, 'display_container'):
            widget = widget.parent
        
        if widget and hasattr(widget, 'display_container'):
            widget.display_container.show_parameter(
                param['name'], 
                param['value'], 
                param['text']
            )

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