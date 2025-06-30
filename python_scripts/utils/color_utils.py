"""
Color utility functions for the MIDI Controller application.
Handles hex to RGB conversions and color presets.
"""

def hex_to_rgb(hex_color):
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

def rgb_to_hex(rgb):
    """Convert RGB to hex color"""
    return f"#{rgb['r']:02x}{rgb['g']:02x}{rgb['b']:02x}"

def get_color_presets():
    """Get color presets matching Vue.js"""
    return {
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