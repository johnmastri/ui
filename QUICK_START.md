# Quick Start Guide

## For Development

### Deploy to Pi
```powershell
cd package/scripts
.\deploy-to-pi.ps1
```

### Deploy Server Only (Fast Debugging)
```powershell
.\deploy-to-pi.ps1 -ServerOnly -NoRestart
```

### Check Pi Services
```bash
ssh pi@192.168.1.195 "systemctl status mastrctrl-*"
```

## For Release

### Create Release
```powershell
cd package/scripts
.\create_release.ps1 -Version 1.1.0 -GitHubRepo "your-username/controller_v2"
```

### Manual GitHub Release
```bash
gh release create v1.1.0 release/* --title "v1.1.0" --notes "Release notes here"
```

## For Updates (From Hardware UI)

1. **Settings** → **Device** → **System Update**
2. Click **"Check for Updates"**
3. Select components (Server is default)
4. Click **"Download Update"**
5. Click **"Install Now"** when ready

## Common Commands

### View Logs
```bash
# Server logs
ssh pi@192.168.1.195 "journalctl -u mastrctrl-server -f"

# UI logs
ssh pi@192.168.1.195 "journalctl -u mastrctrl-ui -f"
```

### Restart Services
```bash
ssh pi@192.168.1.195 "sudo systemctl restart mastrctrl-server"
ssh pi@192.168.1.195 "sudo systemctl restart mastrctrl-ui"
```

### Manual Rollback
```bash
ssh pi@192.168.1.195
cd /home/pi/mastrctrl
./scripts/rollback.sh server
```

### Check Current Versions
```bash
ssh pi@192.168.1.195 "cat /home/pi/mastrctrl/current/version.json"
```

## Troubleshooting

### "No updates available"
- Check GitHub repo URL in `python/update_manager.py`
- Verify latest release exists with manifest.json
- Check Pi network connection

### Update fails
- Check logs: `journalctl -u mastrctrl-server -f`
- System automatically rolls back on failure
- Manual rollback: `./scripts/rollback.sh <component>`

### ESP32 won't flash
- Verify UART connection (Pi GPIO14/15 ↔ ESP32 D8/D9)
- Check esptool installed: `esptool.py version`
- Try manual flash test

## File Locations

- **Config**: `/home/pi/mastrctrl/update_config.json`
- **Current**: `/home/pi/mastrctrl/current/`
- **Backups**: `/home/pi/mastrctrl/backups/`
- **Staging**: `/home/pi/mastrctrl/staging/`
- **Logs**: `journalctl -u mastrctrl-*`

## Default Behavior

- **Server-only updates** by default (for fast debugging)
- **Auto-check** every 6 hours (configurable)
- **Manual install** confirmation required
- **Automatic backup** before each update
- **Automatic rollback** on failure
- **Keep last 2 backups** per component

