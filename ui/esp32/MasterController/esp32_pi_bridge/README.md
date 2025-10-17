# ESP32-S3 WebSocket-to-Pi Bridge

Communication bridge that connects a desktop WebSocket server to an ESP32-S3, which then forwards data to a Raspberry Pi via UART.

## Architecture

```
┌──────────────┐
│  Desktop PC  │
│  Web Browser │  ← test_client.html
└──────┬───────┘
       │ WebSocket (ws://localhost:8766)
       │
┌──────▼───────────────┐
│  Python Server       │
│  ws_serial_bridge.py │
└──────┬───────────────┘
       │ USB Serial (115200 baud)
       │
┌──────▼───────────────────────────┐
│     ESP32-S3 (mastr_r2a)         │
│  - Receives WebSocket JSON       │
│  - Parses and acts on data       │
│  - Forwards to Raspberry Pi      │
│  - Echoes everything to Serial   │
│    Monitor for debugging         │
└──────┬───────────────────────────┘
       │ UART (D8 TX, D9 RX @ 115200 baud)
       │
┌──────▼───────┐
│ Raspberry Pi │
│ (Future)     │
└──────────────┘
```

## Hardware Setup

### ESP32-S3 Pin Configuration

**Current Assignments:**
- `D0` - LED Data (APA102)
- `D1` - LED Clock (APA102)
- `D2` - Rotary Encoder A
- `D3` - Rotary Encoder B
- `D4` - Rotary Encoder Button
- `GPIO5` - I2C SDA
- `GPIO7` - I2C SCL
- **`D8` - Pi UART TX (ESP32 → Pi)**
- **`D9` - Pi UART RX (Pi → ESP32)**

### Wiring to Raspberry Pi (Future)

```
ESP32-S3          Raspberry Pi
--------          ------------
D8 (TX)    →      GPIO15 (RXD)
D9 (RX)    ←      GPIO14 (TXD)
GND        ←→     GND
```

## Software Setup

### Prerequisites

```bash
pip install pyserial
pip install websockets
```

### Running the Bridge Server

1. **Flash ESP32 Firmware**
   - Open `MasterController.ino` in Arduino IDE
   - Select board: "XIAO ESP32-S3"
   - Upload to ESP32

2. **Start Python Bridge**
   ```bash
   cd esp32_pi_bridge
   python ws_serial_bridge.py
   ```
   
   The server will:
   - Auto-detect ESP32 COM port
   - Connect at 115200 baud
   - Start WebSocket server on port 8766

3. **Open Test Client**
   - Open `test_client.html` in a web browser
   - Client auto-connects to `ws://localhost:8766`

## Usage

### Serial Monitor Output

The ESP32 provides verbose output showing all message flows:

```
========================================
ESP32-S3 WebSocket-to-Pi Bridge
========================================
Firmware: 1.1.0-bridge
Device ID: mastr_r2a
MAC Address: A4:CF:12:5A:3B:8C
----------------------------------------
USB Serial: ACTIVE (115200 baud)
  Purpose: Receive WebSocket data
Pi UART: ACTIVE (115200 baud)
  TX Pin: D8
  RX Pin: D9
========================================

┌─────────────────────────────────────
│ [USB->ESP32] Message #1
│ Timestamp: 12345 ms
│ Raw JSON:
│   {"type":"led_update","encoder_id":0,...}
│ Parsed Type: led_update
│ Action: Updating LEDs
│   Encoder: 0
│   Color: RGB(255,0,0)
│   Pattern: ring_fill
│   Value: 0.5
│ [ESP32->Pi] Forwarded to Raspberry Pi
└─────────────────────────────────────
```

### Test Client Features

**Connection Panel:**
- View connection status
- See ESP32 device ID and MAC address
- Monitor message counts

**LED Test Controls:**
- Select encoder (0-3)
- Adjust LED value (0-100%)
- Pick RGB color
- Test patterns: ring_fill, solid, pulse, rainbow, off

**System Commands:**
- Test pattern
- Clear LEDs
- Scan I2C
- Adjust brightness

**Custom JSON:**
- Send arbitrary JSON messages
- Full protocol access

### Message Flow Examples

**1. LED Update from Browser**
```
Browser → WebSocket → Python → USB Serial → ESP32
                                              ↓
                                    Parse & Update LEDs
                                              ↓
                                    Forward → Pi UART (D8/D9)
```

**2. Encoder Update from Pi (Future)**
```
Pi → UART (D8/D9) → ESP32 → Parse → USB Serial → Python → WebSocket → Browser
```

## Message Protocol

### LED Update
```json
{
  "type": "led_update",
  "encoder_id": 0,
  "color": {"r": 255, "g": 128, "b": 0},
  "pattern": "ring_fill",
  "value": 0.75
}
```

### System Command
```json
{
  "type": "system_command",
  "command": "brightness",
  "parameter": "100"
}
```

### ESP32 Startup (Automatic)
```json
{
  "type": "startup",
  "device_id": "mastr_r2a",
  "mac_address": "A4:CF:12:5A:3B:8C",
  "firmware_version": "1.1.0-bridge",
  "status": "ready",
  "capabilities": "websocket_bridge,dual_uart,led_control,i2c_encoders",
  "usb_baud": 115200,
  "pi_baud": 115200,
  "timestamp": 1234
}
```

### Encoder Update (From Pi)
```json
{
  "type": "encoder",
  "device_id": "mastr_r2a",
  "mac_address": "A4:CF:12:5A:3B:8C",
  "encoder_id": 0,
  "value": 0.5,
  "direction": 1,
  "timestamp": 5678
}
```

## Troubleshooting

### ESP32 Not Detected
- Check USB cable connection
- Verify driver installation (CP210x or CH340)
- Try different USB port
- Manually select COM port: `python ws_serial_bridge.py --port COM3`

### WebSocket Connection Failed
- Ensure Python server is running
- Check firewall settings
- Verify port 8766 is not in use
- Try connecting to `ws://127.0.0.1:8766`

### No Data in Serial Monitor
- Set baud rate to 115200
- Ensure "Both NL & CR" line ending
- Check USB connection
- Reset ESP32

### LEDs Not Responding
- Verify LED strip connections (D0/D1)
- Check power supply
- Test with system commands first
- Review Serial Monitor for errors

## Command Line Options

### Python Server
```bash
python ws_serial_bridge.py --help

Options:
  --port PORT        Serial port (default: auto-detect)
  --baud BAUD        Baud rate (default: 115200)
  --ws-port PORT     WebSocket port (default: 8766)
```

### Examples
```bash
python ws_serial_bridge.py --port COM5
python ws_serial_bridge.py --baud 9600 --ws-port 8080
```

## Multi-Device Support (Future)

The system uses MAC addresses for unique device identification:
- Each ESP32 has a unique factory-assigned MAC address
- Python server can manage multiple ESP32 devices simultaneously
- Route messages by MAC address to specific devices

```json
{
  "target_mac": "A4:CF:12:5A:3B:8C",
  "type": "led_update",
  ...
}
```

## Development

### File Structure
```
esp32_pi_bridge/
├── ws_serial_bridge.py   - Python WebSocket-to-Serial server
├── test_client.html      - Browser test interface
└── README.md             - This file

../
├── config.h              - ESP32 configuration
├── uart_comm.h           - UART communication header
├── uart_comm.cpp         - Bridge implementation
└── MasterController.ino  - Main firmware
```

### Extending Functionality

Add custom message handlers in `uart_comm.cpp`:
```cpp
void UARTComm::processUSBMessage(const String& message) {
    // Add your custom message type handling here
    if (messageType == "my_custom_type") {
        // Handle it
    }
}
```

## License

Part of the MastrCtrl MIDI Controller project.

## Version History

**1.1.0-bridge** (Current)
- Dual serial port support (USB + Pi UART)
- Verbose Serial Monitor output
- MAC address identification
- WebSocket bridge server
- HTML test client

**1.0.0**
- Initial UART communication
- LED control
- I2C encoder support

