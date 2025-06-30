"""
Kivy configuration setup for the MIDI Controller application.
Handles window configuration and cleanup of cached settings.
"""

import os
from kivy.config import Config

def setup_kivy_config():
    """
    Configure Kivy for 800x480 windowed (not fullscreen by default)
    Clear any cached fullscreen settings
    """
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
    
    print("⚙️ Kivy configuration set to 800x480 windowed mode") 