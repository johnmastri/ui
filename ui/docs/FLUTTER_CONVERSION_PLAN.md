# Flutter Conversion Plan: Kivy MIDI Controller → Flutter-Pi

## Project Overview

Converting the existing Kivy-based MIDI controller application to Flutter for Raspberry Pi deployment using flutter-pi for optimal performance and hot reload development workflow.

## Target Platform Decision

### Selected: flutter-pi + flutterpi_tool
- **Maintainer**: ardera.dev (official flutter-pi project)
- **Status**: Official tooling, actively maintained
- **Benefits**: Direct framebuffer rendering, optimal performance, hot reload support
- **Reliability**: Production-ready, long-term support

### Alternatives Considered
- **snapp_cli**: Third-party wrapper, less maintained (4+ months since update)
- **Flutter Linux Desktop**: Higher overhead, requires desktop environment

## Hardware Configuration

### Raspberry Pi 4 Specifications
- **Screen**: 800x480 resolution (4:3 aspect ratio)
- **Touch**: Capacitive multi-touch display
- **CPU**: Quad-core ARM Cortex-A72
- **Memory**: 2GB/4GB/8GB RAM (sufficient for Flutter)
- **Power**: AC powered (no battery optimization needed)
- **Audio**: No audio processing required

### Performance Considerations
- Direct framebuffer rendering eliminates desktop overhead
- Optimized for touch interaction with precise gestures
- Custom painting for smooth knob animations
- Efficient WebSocket message handling

## Development Workflow

### Setup Process
```bash
# Install flutterpi_tool
flutter pub global activate flutterpi_tool

# Add Pi device with specs
flutterpi_tool devices add pi@192.168.1.195 --display-size=800x480 --id=midi-pi

# Create project
flutter create hardware_gui --platforms=linux
cd hardware_gui
```

### Development Cycle
1. **Code on Windows**: VS Code with Flutter extension
2. **Hot reload**: `flutterpi_tool run -d midi-pi` with real-time updates
3. **Debug**: Remote debugging with Flutter DevTools
4. **Deploy**: `flutterpi_tool install -d midi-pi` for production

### Hot Reload Confirmation
- **Supported**: Yes, via flutterpi_tool integration
- **Speed**: Fast iteration cycle (2-3 seconds)
- **Limitations**: Some low-level changes require full restart

## Project Structure

```
hardware_gui/
├── lib/
│   ├── main.dart                    # Entry point optimized for 800x480
│   ├── models/
│   │   ├── parameter.dart           # Parameter data model
│   │   └── websocket_messages.dart  # WebSocket message types
│   ├── services/
│   │   ├── websocket_service.dart   # WebSocket client
│   │   └── parameter_service.dart   # Parameter management
│   ├── widgets/
│   │   ├── knob_widget.dart         # Custom knob with touch handling
│   │   ├── led_ring_widget.dart     # LED ring visualization
│   │   └── parameter_display.dart   # Parameter value display
│   ├── screens/
│   │   ├── main_screen.dart         # Primary knob interface
│   │   └── settings_screen.dart     # Configuration screen
│   └── utils/
│       ├── constants.dart           # Screen dimensions, colors
│       └── color_utils.dart         # Color conversion utilities
├── pubspec.yaml                     # Dependencies
└── README.md                        # Setup instructions
```

## WebSocket Protocol Analysis

### Message Types (Vue.js Compatible)
- `parameter_structure_sync` - Full parameter definitions with structure hash
- `parameter_value_sync` - Real-time value updates with text and RGB color
- `parameter_color_sync` - Color changes for LED rings
- `request_parameter_state` - State synchronization requests
- `led_update` - LED ring data for hardware display
- `system` - System commands and control

### Server Discovery
- **Primary**: `ws://localhost:8765` (development)
- **Secondary**: `ws://192.168.1.195:8765` (Pi bridge)
- **Auto-reconnect**: Exponential backoff with connection health monitoring

### Message Format Examples
```json
{
  "type": "parameter_value_sync",
  "data": {
    "id": "param_001",
    "value": 0.75,
    "text": "75%",
    "color": {"r": 255, "g": 100, "b": 50}
  }
}
```

## UI Design Requirements

### Layout Optimization (800x480)
- **Grid**: 4x2 knob layout (maximum 8 parameters visible)
- **Knob size**: 80x80 pixels with 20px spacing
- **Touch targets**: 100x100 pixels minimum
- **Typography**: 14px minimum for readability

### Touch Interaction
- **Knob rotation**: Circular drag gestures
- **Fine control**: Slow drag for precision
- **Visual feedback**: Immediate response to touch
- **Haptic feedback**: Via system vibration (if available)

### Color System
- **LED rings**: RGB color mapping from WebSocket
- **Parameter states**: Active/inactive visual indicators
- **System status**: Connection state indicators
- **Accessibility**: High contrast mode support

## Implementation Phases

### Phase 1: Core Structure (Days 1-2)
- Project setup with flutterpi_tool
- Basic app structure and navigation
- WebSocket service implementation
- Parameter data models

### Phase 2: UI Components (Days 3-4)
- Custom knob widget with touch handling
- LED ring visualization
- Parameter display components
- Layout responsive to 800x480

### Phase 3: Integration (Days 5-6)
- WebSocket message handling
- Parameter synchronization
- Real-time updates
- Error handling and reconnection

### Phase 4: Optimization (Days 7-8)
- Performance tuning for Pi 4
- Memory usage optimization
- Touch responsiveness refinement
- Production deployment setup

## Production Considerations

### Hardware Reliability
- **SD Card**: Industrial-grade recommended for 24/7 operation
- **Thermal**: Heatsink/fan for continuous operation
- **Power**: 5V 3A stable power supply
- **Filesystem**: Read-only for production stability

### Boot Optimization
- **Boot time**: Target 10-15 seconds
- **Auto-start**: Systemd service configuration
- **Recovery**: Automatic restart on failure
- **Updates**: OTA update mechanism

### System Integration
- **Watchdog**: Hardware watchdog for crash recovery
- **Logging**: Structured logging for debugging
- **Monitoring**: System health monitoring
- **Backup**: Configuration backup/restore

## Risk Mitigation

### Technical Risks
- **Flutter-pi compatibility**: Mitigated by official tooling
- **Performance**: Mitigated by direct framebuffer rendering
- **WebSocket stability**: Mitigated by auto-reconnect logic
- **Touch accuracy**: Mitigated by proper touch target sizing

### Operational Risks
- **SD card failure**: Mitigated by industrial-grade cards
- **Power issues**: Mitigated by stable power supply
- **System corruption**: Mitigated by read-only filesystem
- **Update failures**: Mitigated by rollback mechanism

## Success Criteria

### Functional Requirements
- ✅ Touch-responsive knob controls
- ✅ Real-time WebSocket synchronization
- ✅ LED ring visualization
- ✅ Parameter value display
- ✅ Auto-reconnection capability

### Performance Requirements
- ✅ <100ms touch response time
- ✅ 60fps smooth animations
- ✅ <2MB memory usage
- ✅ <15 second boot time
- ✅ 24/7 operational stability

### Development Requirements
- ✅ Hot reload development workflow
- ✅ Remote debugging capability
- ✅ Easy deployment process
- ✅ Maintainable code structure
- ✅ Comprehensive error handling

## Next Steps

1. **Environment Setup**: Install flutterpi_tool and configure Pi device
2. **Project Creation**: Create Flutter project with linux platform
3. **Core Implementation**: Start with Phase 1 development
4. **Testing**: Continuous testing on target hardware
5. **Optimization**: Performance tuning and production preparation

---

*This plan provides a comprehensive roadmap for converting the Kivy MIDI controller to Flutter-Pi while maintaining full compatibility with the existing WebSocket protocol and Vue.js system.* 