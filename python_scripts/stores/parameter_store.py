"""
Parameter Store - Parameter management system matching Vue.js parameterStore functionality.
Handles parameter data, text generation, and mock data loading.
"""

import json
import base64
import math
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

from utils.color_utils import hex_to_rgb, rgb_to_hex, get_color_presets

class ParameterStore:
    """Parameter management system matching Vue.js parameterStore functionality"""
    
    def __init__(self):
        self.parameters = []
        self.current_structure_hash = None
        self.last_structure_update = None
        self.color_presets = get_color_presets()
        
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
                'rgbColor': parameter.get('rgbColor') or hex_to_rgb(parameter.get('color') or self.color_presets.get(parameter['name'], '#4CAF50')),
                'ledCount': parameter.get('ledCount', 28)
            })
        else:
            # Add new parameter
            new_parameter = {
                **parameter,
                'text': parameter.get('text') or self.generate_parameter_text(parameter['name'], parameter['value']),
                'color': parameter.get('color') or self.color_presets.get(parameter['name'], '#4CAF50'),
                'rgbColor': parameter.get('rgbColor') or hex_to_rgb(parameter.get('color') or self.color_presets.get(parameter['name'], '#4CAF50')),
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