# ESP32 WebSocket Bridge

ESP32-based USB-to-GPIO WebSocket proxy for MIDI Controller communication with isolated Raspberry Pi systems.

## Overview

This project creates a WebSocket bridge that enables communication between a VST plugin running on a PC and a Raspberry Pi that has no network connectivity. The ESP32 presents itself as a USB network device to the PC and forwards WebSocket messages to the Pi via GPIO/UART communication.

```
VST/Vue.js (PC) ←→ ESP32 (USB Network Device) ←→ Pi (runs mock_ws_server.py)
                      ↑                           ↑
               ws://192.168.4.1:8765        GPIO/UART Bridge
```

## Architecture

### Phase 1: USB Bridge (Current Implementation)
- **USB Network Interface**: ESP32 presents as USB CDC-ECM network device
- **WebSocket Server**: Runs on ESP32 at `192.168.4.1:8765`
- **GPIO Communication**: UART bridge to Pi on GPIO pins 16/17
- **Message Proxy**: Bidirectional message forwarding between WebSocket and UART
- **Status LED**: Visual feedback for connection states

### Phase 2: Hardware I/O (Future)
- **Encoder Support**: 16 I2C rotary encoders
- **Button Matrix**: 4x4 button matrix
- **LED Control**: 448 LEDs (16 rings × 28 LEDs) via FastLED
- **Direct Hardware**: Bypass Pi for real-time hardware control

## File Structure

```
WebSocketBridge/
├── WebSocketBridge.ino          # Main Arduino sketch
├── config.h                     # Configuration constants
├── libraries.txt                # Required Arduino libraries
├── README.md                    # This file
├── utils/                       # Utility classes
│   ├── debug_utils.h/cpp        # Debug logging and utilities
│   └── status_led.h/cpp         # LED status indication
├── network/                     # Network layer
│   ├── usb_network.h/cpp        # USB network device interface
│   └── wifi_fallback.h/cpp      # WiFi fallback (future)
├── websocket/                   # WebSocket server
│   └── ws_server.h/cpp          # WebSocket server implementation
├── communication/               # Pi communication
│   ├── gpio_comm.h/cpp          # High-level Pi communication
│   ├── uart_handler.h/cpp       # Low-level UART handling
│   └── message_queue.h/cpp      # Message buffering
├── bridge/                      # Bridge logic
│   ├── message_proxy.h/cpp      # Message forwarding logic
│   └── connection_manager.h/cpp # Connection state management
└── hardware/                    # Hardware I/O (Phase 2)
    ├── encoder_manager.h/cpp    # Rotary encoder handling
    ├── button_matrix.h/cpp      # Button matrix scanning
    └── led_controller.h/cpp     # LED ring control
```

## Hardware Requirements

### Minimum Setup (Phase 1)
- **ESP32-S3** or similar with USB OTG support
- **Status LED** on GPIO 2 (built-in LED)
- **UART Connection to Pi**:
  - TX: GPIO 17 → Pi RX
  - RX: GPIO 16 → Pi TX
  - GND: Common ground

### Pin Assignments

| Function | GPIO Pin | Notes |
|----------|----------|--------|
| Status LED | 2 | Built-in LED |
| Pi UART TX | 17 | To Pi RX |
| Pi UART RX | 16 | From Pi TX |
| USB D+ | 20 | USB OTG (built-in) |
| USB D- | 19 | USB OTG (built-in) |

### Future Hardware (Phase 2)
| Function | GPIO Pins | Notes |
|----------|-----------|--------|
| I2C SDA | 21 | For encoders |
| I2C SCL | 22 | For encoders |
| LED Data | 5 | FastLED output |
| Button Matrix | 8 pins | 4 rows + 4 cols |

## Setup Instructions

### 1. Install Required Libraries

See `libraries.txt` for complete list. Key libraries:
```bash
# Arduino IDE Library Manager
- ArduinoJson
- WebSockets by Markus Sattler
- TinyUSB (for USB device support)
```

### 2. Hardware Connections

Connect ESP32 to Pi:
```
ESP32 GPIO 17 (TX) → Pi GPIO 15 (RX)
ESP32 GPIO 16 (RX) → Pi GPIO 14 (TX)
ESP32 GND         → Pi GND
```

### 3. Upload Firmware

1. Open `WebSocketBridge.ino` in Arduino IDE
2. Select ESP32-S3 board
3. Configure USB settings:
   - USB Mode: "USB-OTG (TinyUSB)"
   - USB CDC On Boot: "Enabled"
4. Upload firmware

### 4. Configure PC Network

When ESP32 is connected via USB, it should appear as a network interface:
```
Network: 192.168.4.0/24
ESP32 IP: 192.168.4.1
PC IP: 192.168.4.2 (auto-assigned)
```

### 5. Test Connection

1. **Verify USB Network**: Ping `192.168.4.1` from PC
2. **Test WebSocket**: Connect to `ws://192.168.4.1:8765`
3. **Check Pi Communication**: Monitor serial output for Pi messages

## Configuration

### Main Settings (`config.h`)

```cpp
// Network Configuration
#define USB_NETWORK_IP          "192.168.4.1"
#define WEBSOCKET_PORT          8765
#define MAX_WEBSOCKET_CLIENTS   4

// Pi Communication
#define PI_UART_BAUD            115200
#define PI_UART_TX_PIN          17
#define PI_UART_RX_PIN          16

// Debug Settings
#define DEBUG_SERIAL            true
#define DEBUG_WEBSOCKET         true
#define DEBUG_PI_COMM           true
```

### Status LED Patterns

| Pattern | Meaning |
|---------|---------|
| Fast blink | Startup/Error |
| Slow pulse | Ready, waiting for connections |
| Single blink | USB connected |
| Double blink | WebSocket client connected |
| Triple blink | Pi communication active |
| Mostly on | Fully connected and operational |

## Protocol

### WebSocket Messages
All messages are JSON formatted and compatible with existing Vue.js WebSocket protocol:

```json
{
  "type": "parameter_value_sync",
  "parameter_name": "param1",
  "parameter_value": 0.5,
  "parameter_text": "50%"
}
```

### UART Protocol
Messages between ESP32 and Pi are newline-delimited JSON:
```
{"type":"heartbeat","timestamp":12345}\n
{"type":"parameter_value_sync","parameter_name":"param1","parameter_value":0.5}\n
```

## Debug Information

### Serial Debug Output
Connect to ESP32 serial port at 115200 baud for debug information:

```
[00:00:01.234] 🚀 WebSocket Bridge Starting...
[00:00:01.456] ✅ Status LED initialized
[00:00:01.678] 🔗 Initializing Pi communication...
[00:00:01.890] ✅ Pi communication initialized
[00:00:02.123] 🌐 Initializing USB network...
[00:00:02.345] ✅ USB network initialized
[00:00:02.567] 📡 Initializing WebSocket server...
[00:00:02.789] ✅ WebSocket server initialized
[00:00:03.012] 🎉 WebSocket Bridge Ready!
[00:00:03.234] 📍 USB IP: 192.168.4.1:8765
[00:00:03.456] 🔗 Connect VST to: ws://192.168.4.1:8765
```

### Memory Usage Monitoring
```
[00:01:00.000] 💾 Memory Usage:
  Free: 234.5 KB
  Used: 89.3 KB  
  Total: 323.8 KB
  Usage: 27%
```

## Troubleshooting

### USB Network Not Appearing
1. Check ESP32 board selection includes USB OTG support
2. Verify USB cable supports data transfer
3. Try different USB port on PC
4. Check Windows Device Manager for CDC-ECM device

### WebSocket Connection Failed
1. Verify ESP32 IP address: `ping 192.168.4.1`
2. Check firewall settings on PC
3. Monitor ESP32 serial output for errors
4. Verify WebSocket port (8765) is not blocked

### Pi Communication Issues
1. Check UART wiring (TX/RX crossed)
2. Verify baud rate matches (115200)
3. Check Pi serial port configuration
4. Monitor ESP32 debug output for Pi messages

### Status LED Indicates Error
- **Fast blink**: Check serial output for specific error
- **No activity**: Power/upload issue
- **Wrong pattern**: Partial initialization failure

## Development

### Adding Custom Messages
1. Update message proxy in `bridge/message_proxy.cpp`
2. Add JSON parsing for new message types
3. Implement bidirectional forwarding logic

### Modifying Network Configuration
1. Update `config.h` network settings
2. Modify `network/usb_network.cpp` implementation
3. Test with new IP addresses

### Future Hardware Integration
Phase 2 hardware components are prepared in the `hardware/` folder for:
- Rotary encoder matrix
- Button scanning
- LED control
- Real-time hardware feedback

## Performance

### Specifications
- **WebSocket Throughput**: ~100 messages/second
- **UART Bandwidth**: 115200 baud (theoretical ~14KB/s)
- **Memory Usage**: ~90KB RAM (ESP32-S3 has 512KB)
- **Latency**: <10ms WebSocket to UART forwarding

### Optimization Notes
- Messages are queued for smooth data flow
- UART uses efficient line-buffered parsing
- WebSocket server handles multiple clients
- Status updates are throttled to reduce overhead

## Contributing

This is part of a larger MIDI controller project. Key integration points:
- Compatible with existing Vue.js WebSocket protocol
- Maintains message format consistency
- Preserves Pi isolation requirements
- Supports future hardware expansion

## License

[Add appropriate license information] 