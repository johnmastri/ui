# Systemd Service Files

Service configurations for running MastrCtrl components as system services on Raspberry Pi.

## What's Here

- **mastrctrl-ui.service** - Electron UI in kiosk mode
- **mastrctrl-server.service** - Python WebSocket server
- **mastrctrl-updater.service** - Update manager service

## Installation on Pi

```bash
# Copy service files
sudo cp *.service /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable services to start on boot
sudo systemctl enable mastrctrl-ui mastrctrl-server mastrctrl-updater

# Start services
sudo systemctl start mastrctrl-ui mastrctrl-server mastrctrl-updater
```

## Management

```bash
# Check status
sudo systemctl status mastrctrl-server

# View logs
sudo journalctl -u mastrctrl-server -f

# Restart service
sudo systemctl restart mastrctrl-server

# Stop service
sudo systemctl stop mastrctrl-server
```

## Service Details

**mastrctrl-ui.service**
- Runs Electron in kiosk mode
- Auto-restarts on crash
- Depends on X11 server

**mastrctrl-server.service**
- WebSocket bridge (ESP32 ↔ UI)
- Auto-restarts on crash
- Starts after network is ready

**mastrctrl-updater.service**
- Checks for updates periodically
- Applies updates via update_manager.py
- Auto-restarts on crash

