# Flutter MIDI Controller Documentation

## Project Overview

This documentation covers the conversion of the existing Kivy-based MIDI controller application to Flutter for Raspberry Pi deployment. The project maintains full compatibility with the existing WebSocket protocol while optimizing for touch-based hardware interaction.

## Documentation Structure

### 📋 [Flutter Conversion Plan](./FLUTTER_CONVERSION_PLAN.md)
**Complete project roadmap and implementation strategy**
- Target platform selection (flutter-pi + flutterpi_tool)
- Development workflow with hot reload
- Project structure and architecture
- Implementation phases and timeline
- Production considerations and risk mitigation

### 🔌 [WebSocket Protocol](./WEBSOCKET_PROTOCOL.md)
**Detailed protocol specification for system integration**
- Message types and formats
- Parameter synchronization
- LED ring data handling
- Error handling and recovery
- Vue.js compatibility layer

### 🔧 [Hardware Setup Guide](./HARDWARE_SETUP.md)
**Comprehensive Raspberry Pi deployment instructions**
- Hardware specifications and requirements
- Flutter-pi installation and configuration
- Performance optimization
- Production deployment setup
- Monitoring and maintenance procedures

## Key Decisions

### Platform Selection
- **Selected**: flutter-pi + flutterpi_tool
- **Reason**: Official tooling, active maintenance, hot reload support
- **Alternative**: snapp_cli (rejected due to third-party maintenance concerns)

### Hardware Target
- **Device**: Raspberry Pi 4 (2GB/4GB/8GB RAM)
- **Display**: 800x480 capacitive touch screen
- **Performance**: Direct framebuffer rendering via flutter-pi

### Development Workflow
- **Hot Reload**: ✅ Confirmed via flutterpi_tool
- **Remote Debug**: ✅ Flutter DevTools integration
- **Deployment**: Seamless via SSH automation

## Quick Start

### 1. Prerequisites
- Flutter SDK installed and configured
- Raspberry Pi 4 with 800x480 display
- SSH access to Pi (IP: 192.168.1.195)

### 2. Environment Setup
```bash
# Install flutterpi_tool
flutter pub global activate flutterpi_tool

# Add Pi as Flutter device
flutterpi_tool devices add pi@192.168.1.195 --display-size=800x480 --id=midi-pi
```

### 3. Project Creation
```bash
# Create Flutter project
cd VSTMastrCtrl/mastrctrl/plugin/ui/
flutter create hardware_gui --platforms=linux
cd hardware_gui
```

### 4. Development Cycle
```bash
# Start development with hot reload
flutterpi_tool run -d midi-pi

# Build for production
flutterpi_tool build -d midi-pi
```

## Project Architecture

### Core Components
- **WebSocket Service**: Real-time communication with VST plugin/ESP32
- **Parameter Store**: State management for MIDI parameters
- **Knob Widget**: Custom touch-responsive circular controls
- **LED Ring**: Visual feedback for parameter values
- **Color System**: RGB mapping for hardware LED synchronization

### State Management
- **Framework**: Provider/Riverpod for reactive state
- **Persistence**: SharedPreferences for settings
- **Real-time**: WebSocket message handling
- **Optimistic Updates**: Immediate UI response with rollback

## WebSocket Integration

### Message Types
- `parameter_structure_sync` - Parameter definitions
- `parameter_value_sync` - Real-time value updates
- `parameter_color_sync` - LED color updates
- `led_update` - Hardware LED ring data
- `system` - Control and status messages

### Server Discovery
- Primary: `ws://localhost:8765` (development)
- Secondary: `ws://192.168.1.195:8765` (Pi bridge)
- Auto-reconnect with exponential backoff

## Performance Targets

### Hardware Requirements
- **Response Time**: <100ms touch response
- **Frame Rate**: 60fps smooth animations
- **Memory Usage**: <2MB application footprint
- **Boot Time**: <15 seconds from power on
- **Reliability**: 24/7 operational stability

### Optimization Strategies
- Direct framebuffer rendering (no X11 overhead)
- Efficient custom painting for knobs
- Throttled WebSocket updates (60Hz max)
- Minimal system services

## Production Considerations

### Hardware Reliability
- Industrial-grade SD cards for 24/7 operation
- Temperature monitoring and thermal management
- Hardware watchdog for crash recovery
- Read-only filesystem for stability

### System Integration
- Systemd service for auto-start
- Structured logging for debugging
- OTA update mechanism
- Configuration backup/restore

## Development Status

### Current Phase
- **Status**: Planning Complete ✅
- **Next Step**: Awaiting confirmation to begin implementation
- **Target**: ui/hardware_gui directory

### Implementation Readiness
- ✅ Flutter SDK installed and configured
- ✅ Platform decision finalized (flutter-pi)
- ✅ WebSocket protocol documented
- ✅ Hardware specifications confirmed
- ✅ Development workflow established

## Support and Maintenance

### Documentation Updates
- Update docs as implementation progresses
- Add troubleshooting guides based on issues encountered
- Include performance benchmarks and optimization results
- Document deployment procedures for production

### Version Control
- All documentation versioned with code
- Implementation decisions tracked in git history
- Changes linked to specific requirements or issues

---

## Next Steps

1. **Confirm Implementation Start**: Await user confirmation to begin
2. **Environment Setup**: Install flutterpi_tool and configure Pi device
3. **Project Creation**: Create Flutter project structure in ui/hardware_gui
4. **Phase 1 Development**: Implement core WebSocket and parameter management
5. **UI Development**: Create custom knob widgets and LED visualization
6. **Integration Testing**: Test with existing VST plugin and ESP32 bridge
7. **Performance Optimization**: Tune for Raspberry Pi 4 hardware
8. **Production Deployment**: Configure systemd services and monitoring

*Ready to begin implementation upon confirmation.* 