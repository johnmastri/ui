# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **MIDI Master Controller** project that combines multiple technologies to create a comprehensive audio plugin control system:

- **Vue.js frontend** (plugin UI) with Vite build system
- **JUCE C++ audio plugin** integration via WebView
- **ESP32 microcontroller** firmware for physical hardware control
- **Raspberry Pi bridge** for hardware-to-software communication
- **Python/Kivy native GUI** application for standalone use

## Development Commands

### Frontend Development
```bash
# Start development server (Vue.js UI)
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Windows Batch Scripts
```bash
# Start development server (Windows)
./start-dev-server.bat

# Build for production (Windows)
./build-for-production.bat
```

### Testing Commands
No formal test suite is currently configured. Testing is done through:
- Manual testing with `npm run dev` 
- Hardware integration testing with ESP32 and Raspberry Pi
- Python WebSocket server testing with `python mock_ws_server.py`

## Architecture Overview

### Frontend Architecture (Vue.js)
The UI uses a **data-driven reactive architecture** with centralized state management:

- **Parameter Store**: Central source of truth for all parameter values
- **Hardware Store**: Manages display timing and parameter change detection
- **Settings Store**: User preferences (display timeout, brightness, etc.)
- **WebSocket Store**: Real-time communication with hardware/external systems

### Key Design Patterns
1. **Data-Driven Display**: HardwareDisplay reacts to parameter store changes, not UI interactions
2. **Debounced Change Detection**: 150ms debounce detects when parameter changes stop
3. **Universal Parameter Sources**: Works with UI knobs, MIDI controllers, DAW automation, WebSocket updates
4. **Settings-Driven Behavior**: User-configurable display timeouts and preferences

### Multi-Platform Integration
- **JUCE Plugin Mode**: Runs as VST/AU plugin UI in DAW
- **Standalone Mode**: Runs as web application for development
- **Hardware Bridge**: ESP32 → Raspberry Pi → WebSocket → Vue.js
- **Python Native**: Kivy app mirrors Vue.js functionality

## File Structure

### Core Frontend Files
- `src/App.vue` - Main application component with development/production mode detection
- `src/views/MainView.vue` - Primary control interface
- `src/views/VirtualHardwareView.vue` - Virtual hardware simulation
- `src/components/HardwareDisplay.vue` - Large parameter display with GSAP animations
- `src/components/ParameterKnob.vue` - Rotary parameter controls
- `src/components/SettingsPanel.vue` - User settings modal

### State Management
- `src/stores/parameterStore.js` - Central parameter state
- `src/stores/hardwareStore.js` - Display timing and hardware integration
- `src/stores/settingsStore.js` - User preferences and configuration
- `src/stores/websocketStore.js` - WebSocket communication

### Integration
- `src/composables/useJuceIntegration.js` - JUCE plugin integration
- `src/composables/useWebSocket.js` - WebSocket communication
- `src/juce/` - JUCE library integration files

### Hardware Integration
- `esp32/MasterController/` - ESP32 firmware for physical controllers
- `esp32/WebSocketBridge/` - ESP32 WebSocket bridge implementation
- `python_scripts/` - Python/Kivy native GUI and WebSocket server

## Key Implementation Details

### Parameter Change Flow
```
Parameter Change (any source) → Parameter Store → Hardware Store Watcher → 
150ms Debounce → HardwareDisplay Update → User-Configurable Fade Timer → 
Return to VU Meter
```

### JUCE Integration
- Detects plugin vs standalone mode via `window.__JUCE__`
- Gracefully handles development mode without JUCE
- Provides parameter binding for gain, bypass, and distortion controls

### WebSocket Communication
- Real-time bidirectional communication with hardware
- Message types: parameter updates, LED control, system commands
- Automatic reconnection and connection status display

### Hardware Architecture
- **ESP32**: APA102 LED strips, I2C encoders, UART communication
- **Raspberry Pi**: Bridge between ESP32 and Vue.js via WebSocket
- **Protocol**: JSON messages for all hardware communication

## Development Workflow

### Starting Development
1. Run `npm run dev` to start Vue.js development server
2. Navigate to `http://localhost:3000` for standalone mode
3. Use Virtual Hardware View to test without physical hardware

### Adding New Parameters
1. Add parameter definition to `parameterStore.js`
2. Parameter changes automatically trigger HardwareDisplay updates
3. No manual hardware store integration needed (data-driven)

### Testing Hardware Integration
1. Use `python_scripts/mock_ws_server.py` to simulate hardware
2. Test WebSocket communication with browser dev tools
3. Verify parameter changes work from all sources

### Production Build
1. Run `npm run build` or `./build-for-production.bat`
2. Built files go to `dist/` directory
3. Production build integrates with JUCE plugin WebView

## Important Notes

### Display System
- **Data-driven**: Display reacts to parameter store changes, not UI events
- **Universal**: Works with any parameter change source (UI, MIDI, DAW, WebSocket)
- **Debounced**: 150ms debounce prevents flicker during rapid changes
- **Configurable**: User controls fade delay (1-10 seconds) via settings

### WebSocket Integration
- Development server runs on port 3000 with CORS enabled
- WebSocket server typically runs on port 8080
- Connection status shown in footer with auto-reconnect

### JUCE Plugin Integration
- Development mode shows navigation bar
- Production mode (in plugin) hides navigation
- Plugin info comes from `useJuceIntegration.js`

### Hardware Specifications
- **ESP32**: Seeed Studio XIAO ESP32-S3
- **LEDs**: APA102 LED strips (28 LEDs per encoder)
- **Communication**: UART to Pi, I2C to encoders
- **Power**: 5V supply for LED strips, 3.3V logic

## Troubleshooting

### Development Issues
- Check console for WebSocket connection errors
- Verify parameter store state in Vue DevTools
- Use `isDevelopment` flag for conditional debug output

### Hardware Issues
- Check ESP32 serial output for UART communication
- Verify WebSocket server is running on correct port
- Test with Python mock server before physical hardware

### Build Issues
- Clear `node_modules` and reinstall if build fails
- Check Vite configuration for JUCE integration paths
- Verify all dependencies are properly installed