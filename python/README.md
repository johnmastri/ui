# Python Server Directory

Python WebSocket server and update manager for Raspberry Pi.

## What's Here

- **ws_serial_bridge_with_updates.py** - Main WebSocket server bridging ESP32 ↔ UI
- **update_manager.py** - OTA update system (checks GitHub, downloads, applies updates)
- **requirements.txt** - Python dependencies
- **bridge.py** - Serial bridge utilities
- **test_*.py** - WebSocket and sync test scripts

## Installation on Pi

```bash
# Install dependencies
pip3 install -r requirements.txt

# Run server
python3 ws_serial_bridge_with_updates.py
```

## Systemd Service

Managed by `/etc/systemd/system/mastrctrl-server.service` (see ../systemd/)

## Update Manager

`update_manager.py` handles:
- Checking GitHub releases for updates
- Downloading UI, server, and firmware packages
- Verifying checksums
- Applying updates with automatic backups
- Flashing ESP32 firmware via esptool
- Automatic rollback on failure

