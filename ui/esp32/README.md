# ESP32 Master Controller

MIDI Controller ESP32 firmware for the Seeed Studio XIAO ESP32-S3.

## Hardware Requirements

- **Seeed Studio XIAO ESP32-S3**
- **APA102 LED strips** (28 LEDs per encoder, up to 8 encoders = 224 LEDs total)
- **Level shifter** (74HCT245 or similar) for 3.3V → 5V conversion
- **I2C encoder boards** (Phase 2) - addresses 0x20-0x27
- **5V power supply** for LED strips (2-3A recommended)

## Pin Configuration (LOCKED)

```
D0 (GPIO44) → LED Data Pin (via level shifter)
D1 (GPIO43) → LED Clock Pin (via level shifter)
SDA (GPIO6) → I2C Data (encoder boards)
SCL (GPIO7) → I2C Clock (encoder boards)
TX/RX       → UART to Raspberry Pi
```

## Software Requirements

### Arduino IDE Setup

1. **Install ESP32 Board Package:**
   - Add `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_dev_index.json` to Board Manager URLs
   - Install "esp32" package by Espressif Systems

2. **Select Board:**
   - Board: "XIAO_ESP32S3"
   - USB CDC On Boot: "Enabled"
   - Port: Select appropriate COM port

3. **Install Required Libraries:**
   ```
   FastLED by Daniel Garcia (v3.6.0+)
   ArduinoJson by Benoit Blanchon (v6.21.0+)
   ```

## Project Structure

```
MasterController/
├── MasterController.ino    # Main application file
├── config.h               # Pin definitions & constants
├── uart_comm.h/.cpp       # UART/JSON communication
├── led_controller.h/.cpp  # FastLED APA102 management
├── i2c_encoder.h/.cpp     # I2C encoder handling
└── README.md             # This file
```

## Phase 1: Basic Testing

**Goal:** Verify UART communication and LED control without physical encoders.

### What Works in Phase 1:
- ✅ UART JSON messaging (startup, heartbeat, status)
- ✅ LED strip control (all patterns)
- ✅ I2C bus scanning (preparation for Phase 2)
- ✅ Built-in test mode with automatic LED patterns

### Testing Steps:

1. **Upload firmware** to ESP32 XIAO
2. **Open Serial Monitor** (115200 baud)
3. **Verify startup sequence:**
   ```
   MIDI Master Controller - ESP32
   Hardware: XIAO ESP32-S3
   Firmware: v1.0.0
   [UART] UART Communication initialized
   [LED] FastLED initialized - APA102 strips ready
   [I2C] I2C Encoder Manager initialized
   ```

4. **Watch LED test patterns** cycle automatically every 2 seconds
5. **Check JSON messages** in serial monitor

### Test Commands via Serial:

Send these JSON commands to test functionality:

```json
{"type":"system_command","command":"test_mode","parameter":"false"}
{"type":"system_command","command":"brightness","parameter":"128"}
{"type":"system_command","command":"test_pattern","parameter":""}
{"type":"led_update","encoder_id":0,"color":{"r":255,"g":0,"b":0},"pattern":"ring_fill","value":0.75}
```

## Phase 2: I2C Encoders

**Goal:** Add physical I2C encoder boards and integrate with Pi communication.

### Hardware Setup:
- Connect I2C encoder boards to SDA/SCL
- Use addresses 0x20, 0x21, 0x22... up to 0x27
- Add 4.7kΩ pull-up resistors on I2C lines

### Expected Behavior:
- Automatic encoder scanning every 5 seconds
- Real-time encoder position reporting via UART
- Immediate LED feedback when encoders move

## Communication Protocol

### ESP32 → Pi Messages:

**Startup:**
```json
{
  "type": "startup",
  "device_id": "esp32_master",
  "firmware_version": "1.0.0",
  "status": "ready",
  "capabilities": "led_control,i2c_encoders,uart_comm"
}
```

**Encoder Change:**
```json
{
  "type": "encoder",
  "device_id": "esp32_master",
  "encoder_id": 0,
  "value": 0.75,
  "direction": 1,
  "timestamp": 12345
}
```

**Heartbeat (every 5 seconds):**
```json
{
  "type": "heartbeat",
  "device_id": "esp32_master",
  "status": "alive",
  "uptime": 12345
}
```

### Pi → ESP32 Messages:

**LED Update:**
```json
{
  "type": "led_update",
  "encoder_id": 0,
  "color": {"r": 255, "g": 128, "b": 0},
  "pattern": "ring_fill",
  "value": 0.5
}
```

**System Command:**
```json
{
  "type": "system_command",
  "command": "brightness",
  "parameter": "128"
}
```

## LED Patterns

- **`off`** - All LEDs off
- **`solid`** - Solid color fill
- **`ring_fill`** - Value-based ring fill with dim background
- **`pulse`** - Breathing/pulsing effect
- **`rainbow`** - Animated rainbow colors

## Troubleshooting

### No LED Output:
1. Check power supply (5V, adequate current)
2. Verify level shifter connections
3. Test with lower brightness: `ledController.setBrightness(32);`
4. Check DATA/CLOCK pin connections

### UART Communication Issues:
1. Verify baud rate (115200)
2. Check JSON message format
3. Monitor for buffer overflows in serial output
4. Test with simple messages first

### I2C Encoder Issues:
1. Check pull-up resistors (4.7kΩ)
2. Verify encoder board addresses (0x20-0x27)
3. Test I2C scanner: `{"type":"system_command","command":"scan_i2c"}`
4. Check power to encoder boards

### Memory Issues:
- Current memory usage shown in startup messages
- Reduce `JSON_BUFFER_SIZE` if needed
- Monitor for memory leaks in serial output

## Development Tips

1. **Use Serial Monitor** extensively - all modules provide debug output
2. **Test incrementally** - verify each component before adding the next
3. **Start with low LED brightness** to avoid power issues
4. **Test JSON messages** with a terminal program before connecting Pi
5. **Use test mode** to verify LED patterns without physical encoders

## Next Steps

1. **Phase 1 Complete:** UART + LEDs working
2. **Add level shifter** and test LED strips
3. **Connect to Pi** via UART and test bidirectional communication
4. **Add I2C encoders** one at a time
5. **Integrate with Vue.js frontend** via Pi bridge

## Support

Check serial monitor output for detailed debugging information. All modules prefix their messages with tags like `[UART]`, `[LED]`, `[I2C]`, etc. 