# ESP32 Firmware Directory

Arduino firmware for ESP32-S3 hardware controller.

## What's Here

- **MasterController/** - Main firmware project
  - `MasterController.ino` - Main Arduino sketch
  - `config.h` - Pin definitions and configuration
  - `uart_comm.cpp/h` - Dual serial communication (USB + Pi UART)
  - `led_controller.cpp/h` - LED ring control
  - `rotary_encoder.cpp/h` - Encoder handling
  - `esp32_pi_bridge/` - WebSocket bridge profiles and configurations

## Connections

**USB Serial:** PC communication (115200 baud)  
**Pi UART:** D8(TX) → Pi GPIO15, D9(RX) ← Pi GPIO14 (115200 baud)

## Compilation

Use Arduino IDE or arduino-cli:

```bash
arduino-cli compile --fqbn esp32:esp32:esp32s3 MasterController/
```

## Deployment

Firmware is packaged by `../scripts/create_release.ps1` and can be:
- Flashed from Pi via Update Manager (esptool over UART)
- Manually flashed via USB using Arduino IDE or esptool

