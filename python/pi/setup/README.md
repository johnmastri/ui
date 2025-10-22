# Master Controller - Raspberry Pi Setup Guide

## Hardware Requirements

### Components
- Raspberry Pi 4B (or newer)
- 72× APA102 LED strip (DotStar compatible)
- 5V power supply (3-5A for LEDs)
- Rotary encoder (for testing)
- Optional: 8× PCF8574 I2C encoder boards
- USB-C data cable (not power-only!)
- Jumper wires

### GPIO Pin Assignments

```
Raspberry Pi 40-Pin Header
════════════════════════════════════════════════════

Configuration 1: APA102 LEDs (SPI0 - Required)
  GPIO 10 (Pin 19) → APA102 DATA (DI)
  GPIO 11 (Pin 23) → APA102 CLOCK (CI)
  GND     (Pin 25) → APA102 GND
  5V*              → APA102 VCC (external supply!)

Configuration 2: Test Encoder (GPIO - Optional)
  GPIO 17 (Pin 11) → Encoder A (CLK)
  GPIO 27 (Pin 13) → Encoder B (DT)
  GPIO 22 (Pin 15) → Encoder Button (SW)
  GND     (Pin 9)  → Encoder GND
  3.3V    (Pin 1)  → Encoder VCC

Configuration 3: PCF I2C Encoders (I2C1 - Optional)
  GPIO 2  (Pin 3)  → PCF SDA (all chips daisy-chained)
  GPIO 3  (Pin 5)  → PCF SCL (all chips daisy-chained)
  GND     (Pin 6)  → PCF GND
  5V      (Pin 2)  → PCF VCC

* LEDs require external 5V power supply (not Pi's 5V pins)
  72 LEDs at brightness=8 draw ~1-1.5A
```

## Installation Methods

### Method 1: Automated Deployment (Recommended)

From your Windows/Linux/Mac computer:

```powershell
# Windows PowerShell
cd package/scripts
.\deploy-to-pi.ps1 -PiAddress 192.168.1.195 -Deploy

# Linux/Mac
cd package/scripts
chmod +x deploy-to-pi.sh
./deploy-to-pi.sh 192.168.1.195
```

The script will:
1. Copy files to Pi
2. Install dependencies
3. Configure USB gadget mode
4. Set up systemd service
5. Start the controller

### Method 2: Manual Installation

#### Step 1: Copy Files to Pi

```bash
# From your computer
scp -r package/python/pi/ pi@192.168.1.195:~/mastrctrl/
```

#### Step 2: Install Dependencies

```bash
# On the Pi
cd ~/mastrctrl/package/python/pi
bash setup/install_dependencies.sh
```

#### Step 3: Configure USB Gadget Mode

```bash
sudo bash setup/usb_gadget_setup.sh
# Reboot when prompted
```

#### Step 4: Install Systemd Service (Optional)

```bash
sudo cp setup/systemd/mastrctrl-pi.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mastrctrl-pi.service
sudo systemctl start mastrctrl-pi.service
```

## Testing

### Test LEDs Only

```bash
cd ~/mastrctrl/package/python/pi
python3 tests/test_leds.py

# Specific tests
python3 tests/test_leds.py --test 4  # Rainbow pattern
python3 tests/test_leds.py --brightness 16  # Brighter
```

### Test Encoder Only

```bash
python3 tests/test_encoder.py
# Rotate encoder and press button to test
```

### Test WebSocket Server

```bash
python3 tests/test_websocket.py
# Connect with Vue.js app to ws://192.168.1.195:8765
```

### Run Full Controller

```bash
# Manual start
python3 main.py

# With options
python3 main.py --no-usb  # Skip USB gadget check
python3 main.py --no-leds  # Disable LEDs
python3 main.py --debug  # Verbose output

# View service logs
sudo journalctl -u mastrctrl-pi.service -f
```

## USB Gadget Mode

After setup and reboot:

1. **Connect**: Plug USB-C cable from Pi to computer
2. **Device Appears**: Computer sees "USB Ethernet/RNDIS Gadget"
3. **Network**: Pi is at 192.168.4.1, computer gets 192.168.4.x
4. **WebSocket**: Connect to `ws://192.168.4.1:8765`

### Verify USB Gadget

```bash
# Check interface exists
ip addr show usb0

# Check modules loaded
lsmod | grep -E "dwc2|g_ether"

# Test from computer
ping 192.168.4.1
```

## Configuration

Edit `config.py` to customize:

```python
# LED settings
LED_COUNT = 72
LED_BRIGHTNESS = 8  # 0-31

# Enable/disable features
ENABLE_TEST_ENCODER = True  # GPIO encoder
ENABLE_PCF_ENCODERS = False  # I2C encoders

# WebSocket
WEBSOCKET_IP = "192.168.4.1"
WEBSOCKET_PORT = 8765
```

## Troubleshooting

### LEDs Not Working

1. **Check wiring**: MOSI→DATA, SCLK→CLOCK
2. **Swap wires**: Try reversing DATA/CLOCK
3. **Power**: LEDs need external 5V supply
4. **Test**: `python3 tests/test_leds.py --test 1`

### USB Gadget Not Working

1. **Cable**: Must be USB-C data cable (not power-only)
2. **Reboot**: USB gadget requires reboot after setup
3. **Check**: `ip addr show usb0` should show interface
4. **Modules**: `lsmod | grep dwc2` should show loaded

### Encoder Not Responding

1. **Permissions**: User must be in `gpio` group
2. **Pull-ups**: Encoder needs pull-up resistors or use internal
3. **Test**: `python3 tests/test_encoder.py`

### WebSocket Connection Failed

1. **Firewall**: Check if port 8765 is blocked
2. **Service**: `sudo systemctl status mastrctrl-pi.service`
3. **Logs**: `sudo journalctl -u mastrctrl-pi.service -f`

### Permission Denied Errors

```bash
# Add user to hardware groups
sudo usermod -a -G gpio,spi,i2c $(whoami)
# Log out and log back in
```

## Systemd Service Management

```bash
# Start service
sudo systemctl start mastrctrl-pi.service

# Stop service
sudo systemctl stop mastrctrl-pi.service

# Restart service
sudo systemctl restart mastrctrl-pi.service

# Enable auto-start on boot
sudo systemctl enable mastrctrl-pi.service

# Disable auto-start
sudo systemctl disable mastrctrl-pi.service

# View logs
sudo journalctl -u mastrctrl-pi.service -f

# View last 50 lines
sudo journalctl -u mastrctrl-pi.service -n 50
```

## Usage with Vue.js App

1. Connect Pi USB-C to computer
2. Wait for USB network to initialize (~10 seconds)
3. Open Vue.js app in browser
4. Select "Pi Server" (ws://192.168.4.1:8765) or manual IP
5. LEDs should respond to parameter changes
6. Encoder rotation sends events to app

## Performance Notes

- LED update rate: 60 FPS (16ms)
- I2C polling rate: 100 Hz (10ms)
- WebSocket latency: < 5ms
- Encoder latency: < 1ms (interrupt-based)

## Development Tips

```bash
# Run in debug mode
python3 main.py --debug

# Skip USB check during development
python3 main.py --no-usb

# Test LEDs only
python3 main.py --no-encoders

# Watch logs live
sudo journalctl -u mastrctrl-pi.service -f
```

## Pin Reference Quick Chart

```
Pin   GPIO   Function
─────────────────────────────
 1    3.3V   Test Encoder VCC
 2    5V     PCF/LED Power
 3    2      I2C SDA
 5    3      I2C SCL
 9    GND    Test Encoder GND
11    17     Test Encoder A
13    27     Test Encoder B
15    22     Test Encoder Button
19    10     APA102 DATA (MOSI) ★
23    11     APA102 CLOCK (SCLK) ★
25    GND    APA102 GND

★ = Hardware SPI, cannot be changed
```

