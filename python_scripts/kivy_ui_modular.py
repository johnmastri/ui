"""
MIDI Controller - Modular Version Entry Point

This is the modular version of the MIDI Controller Kivy application.
The original monolithic version is preserved in kivy_ui.py.

This modular version splits the application into logical components:
- utils/: Configuration and utility functions
- stores/: Data management (ParameterStore, WebSocketManager)
- components/: UI components (knobs, labels, containers)
- app/: Main application classes (widget, app)

Usage:
    python kivy_ui_modular.py

Features:
- Vue.js compatible parameter management
- WebSocket communication for real-time updates
- Touch-based knob controls with drag interaction
- Fullscreen/windowed mode toggle (F11 or ESC)
- Parameter color coding and text formatting
- Automatic state synchronization
"""

if __name__ == '__main__':
    print("🚀 Starting MIDI Controller - Modular Version")
    print("=" * 50)
    
    try:
        from app.main_app import MIDIControllerApp
        
        print("✅ All modules loaded successfully")
        print("🎛️ Starting Kivy application...")
        
        # Run the application
        MIDIControllerApp().run()
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        print("💡 Make sure all required packages are installed:")
        print("   pip install kivy websockets")
    except Exception as e:
        print(f"❌ Application error: {e}")
        print("💡 Check the console output for more details")
    
    print("👋 Application closed") 