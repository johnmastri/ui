# Hardware Setup Guide: Raspberry Pi + Flutter-Pi

## Hardware Specifications

### Raspberry Pi 4 Configuration
- **Model**: Raspberry Pi 4 (2GB/4GB/8GB RAM)
- **Display**: 800x480 resolution (4:3 aspect ratio)
- **Touch**: Capacitive multi-touch display
- **Power**: AC powered (5V 3A power supply)
- **Storage**: 32GB+ microSD card (industrial grade recommended)
- **Network**: Wi-Fi or Ethernet connection

### Display Requirements
- **Resolution**: 800x480 pixels
- **Touch Type**: Capacitive (multi-touch support)
- **Interface**: DSI, HDMI, or GPIO connection
- **Brightness**: Adjustable via software
- **Orientation**: Landscape (800x480) or Portrait (480x800)

## Raspberry Pi OS Setup

### 1. OS Installation
```bash
# Download Raspberry Pi OS Lite (64-bit)
# Flash to microSD card using Raspberry Pi Imager
# Enable SSH and Wi-Fi during imaging process
```

### 2. Initial Configuration
```bash
# SSH into Pi
ssh pi@192.168.1.195

# Update system
sudo apt update && sudo apt upgrade -y

# Configure system
sudo raspi-config
# - Enable SSH
# - Set timezone
# - Configure display settings
# - Enable I2C/SPI if needed
```

### 3. Display Configuration
```bash
# Edit boot config for display
sudo nano /boot/config.txt

# Add display configuration (example for DSI display)
dtoverlay=vc4-kms-v3d
dtparam=audio=on
display_auto_detect=1
```

## Flutter-Pi Installation

### 1. Dependencies Installation
```bash
# Install required packages
sudo apt install -y \
    git \
    cmake \
    ninja-build \
    pkg-config \
    libsystemd-dev \
    libinput-dev \
    libudev-dev \
    libdrm-dev \
    libgbm-dev \
    libxkbcommon-dev \
    libgles2-mesa-dev \
    libegl1-mesa-dev \
    libgl1-mesa-dev \
    build-essential
```

### 2. Flutter-Pi Installation
```bash
# Clone flutter-pi repository
git clone https://github.com/ardera/flutter-pi.git
cd flutter-pi

# Build flutter-pi
mkdir build && cd build
cmake ..
make -j$(nproc)

# Install flutter-pi
sudo make install
```

### 3. System Configuration
```bash
# Add user to input group
sudo usermod -a -G input pi

# Configure GPU memory split
echo "gpu_mem=128" | sudo tee -a /boot/config.txt

# Disable unused services
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable cups-browsed
```

## Development Environment Setup

### 1. Development Machine (Windows)
```bash
# Install Flutter SDK (already completed)
flutter --version

# Install flutterpi_tool
flutter pub global activate flutterpi_tool

# Verify installation
flutterpi_tool --version
```

### 2. Add Pi as Flutter Device
```bash
# Add Pi device with display specifications
flutterpi_tool devices add pi@192.168.1.195 \
    --display-size=800x480 \
    --id=midi-pi \
    --description="MIDI Controller Pi"

# Verify device is detected
flutterpi_tool devices
```

### 3. SSH Key Setup (for seamless deployment)
```bash
# Generate SSH key (if not exists)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy public key to Pi
ssh-copy-id pi@192.168.1.195

# Test passwordless SSH
ssh pi@192.168.1.195 "echo 'SSH key setup successful'"
```

## Performance Optimization

### 1. System Optimization
```bash
# Disable unnecessary services
sudo systemctl disable avahi-daemon
sudo systemctl disable triggerhappy
sudo systemctl disable hciuart

# Configure GPU memory
echo "gpu_mem=128" | sudo tee -a /boot/config.txt

# Disable swapping (for SD card longevity)
sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo systemctl disable dphys-swapfile
```

### 2. Display Optimization
```bash
# Configure display for optimal performance
sudo nano /boot/config.txt

# Add these settings
dtoverlay=vc4-kms-v3d
gpu_mem=128
disable_overscan=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1
```

### 3. Touch Calibration
```bash
# Install touch calibration tools
sudo apt install -y xinput-calibrator

# Calibrate touch screen
xinput_calibrator

# Save calibration results to system
sudo nano /etc/X11/xorg.conf.d/99-calibration.conf
```

## Production Deployment

### 1. Auto-Start Configuration
```bash
# Create systemd service
sudo nano /etc/systemd/system/midi-controller.service

[Unit]
Description=MIDI Controller Flutter App
After=multi-user.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/midi_controller
ExecStart=/usr/local/bin/flutter-pi /home/pi/midi_controller/build/flutter_assets
Restart=always
RestartSec=5
Environment=FLUTTER_PI_RESOLUTION=800x480

[Install]
WantedBy=multi-user.target
```

### 2. Enable Auto-Start
```bash
# Enable service
sudo systemctl enable midi-controller.service

# Start service
sudo systemctl start midi-controller.service

# Check status
sudo systemctl status midi-controller.service
```

### 3. Read-Only Filesystem (Production)
```bash
# Install read-only filesystem tools
sudo apt install -y overlayroot

# Configure read-only mode
sudo nano /etc/overlayroot.conf
# Set: overlayroot="tmpfs"

# Create persistent data directory
sudo mkdir -p /var/lib/midi-controller
sudo chown pi:pi /var/lib/midi-controller
```

## Hardware Reliability

### 1. Watchdog Configuration
```bash
# Enable hardware watchdog
echo "dtparam=watchdog=on" | sudo tee -a /boot/config.txt

# Install watchdog service
sudo apt install -y watchdog

# Configure watchdog
sudo nano /etc/watchdog.conf
# Uncomment: watchdog-device = /dev/watchdog
# Set: max-load-1 = 24
```

### 2. Temperature Monitoring
```bash
# Create temperature monitoring script
sudo nano /usr/local/bin/temp_monitor.sh

#!/bin/bash
TEMP=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
if (( $(echo "$TEMP > 80" | bc -l) )); then
    logger "High temperature detected: $TEMP°C"
    # Add throttling logic if needed
fi
```

### 3. Power Management
```bash
# Disable unnecessary hardware
echo "dtoverlay=disable-bt" | sudo tee -a /boot/config.txt
echo "dtoverlay=disable-wifi" | sudo tee -a /boot/config.txt  # If using ethernet

# Configure power LED
echo "dtparam=pwr_led_trigger=heartbeat" | sudo tee -a /boot/config.txt
```

## Network Configuration

### 1. Wi-Fi Setup
```bash
# Configure Wi-Fi
sudo nano /etc/wpa_supplicant/wpa_supplicant.conf

network={
    ssid="YourWiFiNetwork"
    psk="YourWiFiPassword"
    key_mgmt=WPA-PSK
}
```

### 2. Static IP Configuration
```bash
# Configure static IP
sudo nano /etc/dhcpcd.conf

interface wlan0
static ip_address=192.168.1.195/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

### 3. Firewall Configuration
```bash
# Install UFW
sudo apt install -y ufw

# Configure firewall
sudo ufw allow ssh
sudo ufw allow 8765/tcp  # WebSocket port
sudo ufw enable
```

## Monitoring and Maintenance

### 1. System Monitoring
```bash
# Install monitoring tools
sudo apt install -y htop iotop

# Create monitoring script
sudo nano /usr/local/bin/system_monitor.sh

#!/bin/bash
# Log system stats
echo "$(date): CPU: $(cat /proc/loadavg) Temp: $(vcgencmd measure_temp) Mem: $(free -h | grep Mem)" >> /var/log/system-monitor.log
```

### 2. Log Management
```bash
# Configure log rotation
sudo nano /etc/logrotate.d/midi-controller

/var/log/midi-controller.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 pi pi
}
```

### 3. Backup Strategy
```bash
# Create backup script
sudo nano /usr/local/bin/backup.sh

#!/bin/bash
# Backup configuration and application
rsync -av --exclude '*.log' /home/pi/midi_controller/ /backup/
```

## Troubleshooting

### Common Issues
1. **Touch not working**: Check /dev/input/event* permissions
2. **Display not detected**: Verify display driver and config.txt
3. **Performance issues**: Check CPU temperature and memory usage
4. **WebSocket connection fails**: Verify network connectivity and firewall

### Debug Commands
```bash
# Check flutter-pi logs
journalctl -u midi-controller.service -f

# Monitor system resources
htop

# Check display status
tvservice -s

# Test touch input
evtest /dev/input/event0
```

## Security Considerations

### 1. System Hardening
```bash
# Change default password
passwd

# Disable unused services
sudo systemctl disable bluetooth
sudo systemctl disable cups

# Update system regularly
sudo apt update && sudo apt upgrade -y
```

### 2. Network Security
```bash
# Configure SSH keys only
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
# Set: PubkeyAuthentication yes
```

---

*This guide provides comprehensive setup instructions for deploying the Flutter MIDI controller application on Raspberry Pi hardware with flutter-pi for optimal performance and reliability.* 