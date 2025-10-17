# Installation Guide

This guide explains how to install and configure the MastrCtrl OTA Update System.

## Prerequisites

### Development Machine (Windows)
- PowerShell 5.1 or higher
- Node.js 18+ and npm
- Python 3.8+
- Git
- SSH client

### Raspberry Pi
- Raspberry Pi 4 (2GB+ RAM recommended)
- Raspberry Pi OS (64-bit)
- Python 3.8+
- pip3
- Network connection
- Touchscreen display (800x480)

### ESP32
- ESP32-S3 development board
- USB cable for programming
- UART connection to Raspberry Pi (GPIO14/15)

## Installation Steps

### 1. Clone Repository

```bash
git clone https://github.com/your-username/controller_v2.git
cd controller_v2/package
```

### 2. Configure Deployment

Edit `deploy-config.json`:

```json
{
  "pi_host": "192.168.1.195",
  "pi_user": "pi",
  "server_path": "/home/pi/mastrctrl",
  "backup_enabled": true,
  "auto_restart": true
}
```

### 3. Set Up Raspberry Pi

SSH into your Pi:

```bash
ssh pi@192.168.1.195
```

Install system dependencies:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Python dependencies
sudo apt install python3-pip python3-venv -y

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Install Electron
sudo npm install -g electron

# Install esptool for ESP32 flashing
sudo pip3 install esptool

# Create directory structure
mkdir -p /home/pi/mastrctrl/{current,staging,backups,python,ui,esp32}
```

### 4. Deploy Initial Installation

From your development machine (in `package/scripts/`):

```powershell
.\deploy-to-pi.ps1
```

This will:
- Build the UI
- Copy all files to the Pi
- Install dependencies
- Set up the environment

### 5. Install Systemd Services

On the Pi:

```bash
# Copy service files
sudo cp /home/pi/mastrctrl/systemd/*.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable services
sudo systemctl enable mastrctrl-server
sudo systemctl enable mastrctrl-ui

# Start services
sudo systemctl start mastrctrl-server
sudo systemctl start mastrctrl-ui

# Check status
sudo systemctl status mastrctrl-server
sudo systemctl status mastrctrl-ui
```

### 6. Configure Auto-Start (Optional)

To start the UI on boot without X server:

Edit `/etc/systemd/system/mastrctrl-ui.service` and ensure it has:

```ini
Environment=DISPLAY=:0
ExecStartPre=/bin/bash -c 'sudo X :0 -nolisten tcp &'
ExecStartPre=/bin/sleep 5
```

### 7. Test the System

From the hardware UI:
1. Navigate to Settings → Device
2. Select "System Update"
3. Click "Check for Updates"

## Updating the Update System

To update the update system itself:

```powershell
# Deploy new version
.\deploy-to-pi.ps1 -ServerOnly

# Restart services on Pi
ssh pi@192.168.1.195 "sudo systemctl restart mastrctrl-server"
```

## Troubleshooting

### Services Won't Start

Check logs:
```bash
sudo journalctl -u mastrctrl-server -f
sudo journalctl -u mastrctrl-ui -f
```

### No Updates Detected

1. Check GitHub repo URL in `python/update_manager.py`
2. Verify manifest.json exists in latest release
3. Check network connectivity from Pi
4. View server logs for errors

### ESP32 Flashing Fails

1. Verify UART connection (GPIO14/15)
2. Check if esptool is installed: `esptool.py version`
3. Stop server service before flashing: `sudo systemctl stop mastrctrl-server`
4. Test manual flash: `esptool.py --port /dev/serial0 --baud 115200 chip_id`

### Permission Errors

Ensure pi user has proper permissions:
```bash
sudo usermod -a -G dialout,gpio pi
```

## Configuration

### Update Manager Config

Edit `/home/pi/mastrctrl/update_config.json`:

```json
{
  "github_repo": "your-username/controller_v2",
  "auto_check": true,
  "check_interval_hours": 6,
  "auto_download": false,
  "max_backups": 2
}
```

### Component Selection Defaults

Edit `package/ui/src/stores/updateStore.js`:

```javascript
const selectedComponents = ref({
  ui: false,
  server: true,    // Default: server only
  firmware: false
})
```

## Next Steps

- Create your first release: See `RELEASE.md`
- Configure GitHub repo in update_manager.py
- Test update flow with a test release
- Set up automatic update checks

## Support

For issues and questions, see the main project README or create an issue on GitHub.

