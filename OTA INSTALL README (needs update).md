# MastrCtrl OTA Update System Package

This package contains a complete Over-The-Air (OTA) update system for the MastrCtrl hardware controller.

## Overview

The update system enables automatic updates of three components:
- **UI**: Vue.js/Electron interface running on Raspberry Pi
- **Server**: Python WebSocket server (`ws_serial_bridge.py`)
- **Firmware**: ESP32 firmware flashed via UART

Updates are distributed via GitHub Releases and can be triggered from the hardware UI.

## Package Structure

```
package/
├── version.json              # Version tracking for all components
├── deploy-config.json        # Pi deployment configuration
├── README.md                 # This file
├── scripts/                  # Deployment and release scripts
│   ├── deploy-to-pi.ps1      # PowerShell deployment script
│   ├── update-install.sh     # Pi-side update installation
│   ├── create_release.ps1    # GitHub release creation
│   ├── generate_manifest.py  # Manifest generator
│   └── rollback.sh           # Manual rollback utility
├── python/                   # Python server with update support
│   ├── update_manager.py     # Update manager service
│   ├── ws_serial_bridge_with_updates.py  # Extended WebSocket bridge
│   └── requirements.txt      # Python dependencies
├── ui/                       # Complete Vue.js UI with update panel
│   ├── src/                  # Full copy of UI source
│   ├── electron/             # Electron kiosk scripts
│   ├── package.json          # UI dependencies
│   └── ...                   # All other UI files
├── esp32/                    # ESP32 firmware
│   ├── MasterController/     # Full firmware source
│   └── build_firmware.sh     # Firmware build script
└── systemd/                  # Systemd service files
    ├── mastrctrl-updater.service  # Update manager service
    ├── mastrctrl-ui.service       # UI service
    └── mastrctrl-server.service   # Server service
```

## Quick Start

### First Time Setup

1. **Authenticate with GitHub CLI:**
   ```powershell
   cd package\scripts
   .\setup-github-auth.ps1
   ```

2. **Create your first release:**
   ```powershell
   .\release-with-gh.ps1 -Version 1.0.0
   ```

3. **Deploy to Pi:**
   ```powershell
   .\deploy-to-pi.ps1
   ```

That's it! Your OTA update system is ready.

## Key Features

### Default Update Behavior
- **Server-only updates by default** for rapid debugging
- User can select which components to update (UI, Server, Firmware)
- Semi-automatic: auto-check, auto-download, manual install confirmation

### Update Flow
1. System periodically checks GitHub for new releases
2. Downloads update packages to staging area
3. User confirms installation from hardware UI
4. Applies selected component updates
5. Automatic backup before each update
6. Automatic rollback on failure

### ESP32 Firmware Flashing
- Flash ESP32 directly from Pi via UART using `esptool.py`
- No need to connect ESP32 to PC for updates
- Automatic version verification after flash

## Development Workflow

### Testing the UI
```bash
cd package/ui
npm install
npm run dev
```

### Deploying to Pi
```powershell
.\package\scripts\deploy-to-pi.ps1
```

### Creating a Release
```powershell
.\package\scripts\create_release.ps1 -Version 1.1.0
```

## Integration

This package is self-contained and can be developed independently. When ready to integrate:

1. Test all components in `package/`
2. Use deployment script to push to Pi
3. Optionally replace original files with enhanced versions

## Configuration

### Pi Connection (`deploy-config.json`)
```json
{
  "pi_host": "192.168.1.195",
  "pi_user": "pi",
  "server_path": "/home/pi/mastrctrl",
  "backup_enabled": true,
  "auto_restart": true
}
```

### GitHub Repository
Update `python/update_manager.py` with your GitHub repo:
```python
self.github_repo = "your-username/controller_v2"
```

## Safety Features

- **Automatic backups** before each update
- **Health checks** after updates
- **Automatic rollback** on failure
- **Manual rollback** command available
- **Checksum verification** for all downloads
- **Component selection** (update only what you need)

## Requirements

### Development Machine (Windows)
- PowerShell 5.1+
- Node.js 18+
- Python 3.8+
- Git

### Raspberry Pi
- Raspberry Pi 4 (2GB+ RAM)
- Python 3.8+
- Node.js 18+
- systemd
- esptool.py

## Documentation

See `docs/UPDATE_SYSTEM.md` (to be created) for detailed documentation.

## License

Same as parent project.

