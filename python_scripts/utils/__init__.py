"""
Utility functions for the MIDI Controller application.
"""

from .config import setup_kivy_config
from .color_utils import hex_to_rgb, rgb_to_hex, get_color_presets

__all__ = ['setup_kivy_config', 'hex_to_rgb', 'rgb_to_hex', 'get_color_presets'] 