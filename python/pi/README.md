# Master Controller - Raspberry Pi

Complete Python-based controller system for Raspberry Pi, replacing ESP32+Pi architecture.

## Quick Start

### From Your Computer (Automated Deployment)

**Windows:**
```powershell
cd package/scripts
.\deploy-to-pi.ps1 -PiAddress 192.168.1.195 -Deploy
```

**Linux/Mac:**
```bash
cd package/scripts
chmod +x deploy-to-pi.sh
./deploy-to-pi.sh 192.168.1.195
```

### On the Pi (Manual Setup)

```bash
# Install dependencies
bash setup/install_dependencies.sh

# Configure USB gadget mode (modern kernel 6.x+ with DHCP)
sudo bash setup/configure_usb_gadget_modern.sh

# Test LEDs
python3 tests/test_leds.py

# Run controller
python3 main.py
```

## Features

- **APA102 LED Control**: 72 LEDs, 6 patterns, 60 FPS
- **Rotary Encoder**: GPIO-based with interrupts
- **I2C Encoders**: PCF8574 support (8 encoders)
- **WebSocket Server**: ws://192.168.4.1:8765
- **USB Gadget Mode**: Single USB-C cable connection with automatic DHCP (plug-and-play!)
- **Auto-Start**: systemd service included

## Hardware Requirements

- Raspberry Pi 4B
- 72× APA102 LED strip
- Rotary encoder (optional)
- PCF8574 I2C encoders (optional)
- 5V power supply for LEDs
- USB-C data cable

## Pin Assignments

| Function | GPIO | Pin | Wire To |
|----------|------|-----|---------|
| LED DATA | 10 | 19 | APA102 DI |
| LED CLOCK | 11 | 23 | APA102 CI |
| Encoder A | 17 | 11 | CLK |
| Encoder B | 27 | 13 | DT |
| Encoder Button | 22 | 15 | SW |
| I2C SDA | 2 | 3 | PCF SDA |
| I2C SCL | 3 | 5 | PCF SCL |

## Configuration

Edit `config.py`:
```python
LED_COUNT = 72
LED_BRIGHTNESS = 8
ENABLE_TEST_ENCODER = True
ENABLE_PCF_ENCODERS = False
WEBSOCKET_IP = "192.168.4.1"
WEBSOCKET_PORT = 8765
```

## Documentation

- **setup/WINDOWS_USER_GUIDE.md**: End-user guide for Windows connection (share with users!)
- **setup/USB_GADGET_SETUP_GUIDE.md**: Technical setup and troubleshooting guide
- **setup/README.md**: Complete Pi setup guide with hardware details
- **IMPLEMENTATION_SUMMARY.md**: Full implementation details

## Testing

```bash
# Test each component independently
python3 tests/test_leds.py          # LED patterns
python3 tests/test_encoder.py       # Encoder reading
python3 tests/test_websocket.py     # WebSocket server

# Test specific LED pattern
python3 tests/test_leds.py --test 4 # Rainbow
```

## Usage

```bash
# Manual start
python3 main.py

# With options
python3 main.py --no-usb            # Skip USB check
python3 main.py --no-leds           # Disable LEDs
python3 main.py --debug             # Verbose output

# Systemd service
sudo systemctl start mastrctrl-pi.service
sudo systemctl status mastrctrl-pi.service
sudo journalctl -u mastrctrl-pi.service -f
```

## Connect to Vue.js App

1. Connect Pi USB-C to computer (single cable for power + data)
2. Windows automatically detects USB Ethernet device
3. Windows automatically configures network via DHCP (plug-and-play!)
4. Pi accessible at 192.168.4.1
5. Open Vue.js app
6. Select "Pi Server" or enter ws://192.168.4.1:8765
7. Control LEDs and receive encoder events

**No manual network configuration needed!** The Pi runs a DHCP server that automatically assigns IPs to connected computers.

## Troubleshooting

**LEDs not working?**
- Check wiring (GPIO 10→DATA, GPIO 11→CLOCK)
- Try swapping DATA/CLOCK wires
- Ensure external 5V power for LEDs
- Run: `python3 tests/test_leds.py`

**USB gadget not working?**
- Must use USB-C data cable (not power-only)
- Requires reboot after setup
- Check Pi: `ip addr show usb0` should show `192.168.4.1`
- Check Windows: `ipconfig` should show 192.168.4.x address
- Driver: Device Manager should show "Remote NDIS" adapter
- Kernel 6.x+: Uses configfs-based gadget (not legacy dwc2/g_ether)
- DHCP: Pi runs dnsmasq for automatic IP assignment

**Permission errors?**
```bash
sudo usermod -a -G gpio,spi,i2c $(whoami)
# Log out and log back in
```

See `setup/README.md` for complete troubleshooting guide.

## Architecture

```
┌─────────────────────────────────────┐
│  Raspberry Pi 4B                    │
├─────────────────────────────────────┤
│  USB-C Port (192.168.4.1)          │
│    ├─ USB Gadget Mode              │
│    └─ WebSocket Server :8765       │
│                                     │
│  GPIO Pins                          │
│    ├─ SPI0 → APA102 LEDs (72)     │
│    ├─ GPIO → Test Encoder          │
│    └─ I2C1 → PCF Encoders (8)     │
└─────────────────────────────────────┘
           │ USB-C Cable
           ↓
┌─────────────────────────────────────┐
│  Host Computer                      │
│    ├─ USB Ethernet: 192.168.4.2   │
│    └─ Vue.js App                   │
└─────────────────────────────────────┘
```

## Performance

- LED Update: 60 FPS
- Encoder Latency: < 1ms
- WebSocket Latency: < 5ms
- I2C Polling: 100 Hz

## License

Same as parent project.

