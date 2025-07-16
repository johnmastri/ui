# Raspberry Pi 4B Setup for Flutter MIDI Controller

## 1. Install Flutter-Pi on Your Pi

SSH into your Pi and run these commands:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git cmake ninja-build pkg-config \
    libsystemd-dev libinput-dev libudev-dev libdrm-dev \
    libgbm-dev libxkbcommon-dev libgles2-mesa-dev \
    libegl1-mesa-dev libgl1-mesa-dev build-essential

# Clone and build flutter-pi
cd ~
git clone https://github.com/ardera/flutter-pi.git
cd flutter-pi
mkdir build && cd build

# Configure for Pi 4B
cmake .. -G Ninja

# Build (this takes 5-10 minutes)
ninja

# Install
sudo ninja install

# Verify installation
flutter-pi --help
```

## 2. Configure Pi for Optimal Performance

```bash
# Edit boot config for GPU and display
sudo nano /boot/firmware/config.txt

# Add these lines for your 800x480 display:
gpu_mem=128
dtoverlay=vc4-kms-v3d
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=1

# Save and reboot
sudo reboot
```

## 3. Test 3D Acceleration

```bash
# Check if 3D acceleration is working
ls -la /dev/dri/
lsmod | grep vc4
vcgencmd get_mem gpu

# Expected output:
# /dev/dri/card0 and /dev/dri/renderD128 should exist
# vc4 driver should be loaded
# GPU should have 128MB memory
```

## 4. Setup User Permissions

```bash
# Add pi user to required groups
sudo usermod -a -G input,video,render pi

# Logout and login again for groups to take effect
exit
# Then SSH back in
```

## 5. Test Flutter-Pi

```bash
# Download a test Flutter app (optional)
cd ~
git clone https://github.com/ardera/flutter_gallery.git
cd flutter_gallery

# Run test (if available)
flutter-pi ./build/flutter_assets
```

## 6. Create Systemd Service (Optional - for auto-start)

```bash
# Create service file
sudo nano /etc/systemd/system/midi-controller.service

# Add this content:
[Unit]
Description=Flutter MIDI Controller
After=multi-user.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=5
User=pi
WorkingDirectory=/home/pi/midi_controller
ExecStart=/usr/local/bin/flutter-pi --resolution=800x480 /home/pi/midi_controller/flutter_assets
Environment=FLUTTER_PI_RESOLUTION=800x480

[Install]
WantedBy=multi-user.target

# Enable the service
sudo systemctl enable midi-controller.service

# Start the service
sudo systemctl start midi-controller.service

# Check status
sudo systemctl status midi-controller.service
```

## 7. Network Configuration

Make sure your Pi is accessible from your Windows machine:

```bash
# Check Pi IP address
hostname -I

# Test SSH from Windows:
# ssh pi@192.168.1.195

# If needed, set static IP in /etc/dhcpcd.conf:
interface wlan0
static ip_address=192.168.1.195/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

## 8. Troubleshooting

### Display Issues
```bash
# Check display detection
tvservice -s

# Check for errors
dmesg | grep -i hdmi
```

### Performance Issues
```bash
# Check temperature
vcgencmd measure_temp

# Check throttling
vcgencmd get_throttled

# Check memory usage
free -h
```

### Flutter-Pi Issues
```bash
# Check flutter-pi version
flutter-pi --help

# Run with verbose output
flutter-pi --verbose /path/to/flutter_assets

# Check for missing libraries
ldd /usr/local/bin/flutter-pi
```

---

## Ready for Deployment!

Once you've completed these steps, your Pi is ready to receive the Flutter MIDI controller app using the `deploy-to-pi.ps1` script from your Windows machine. 