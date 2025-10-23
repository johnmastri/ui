# Scripts Directory

Organized scripts for deployment, releases, and system management.

## Directory Structure

```
scripts/
├── deploy/              # Deployment scripts (use these!)
├── release/             # Release management
├── update-system/       # Pi-side update system
└── obsolete/            # Old scripts (replaced by deploy.sh)
```

## Quick Start

### Deploy to Pi
```bash
# From package/scripts directory:
./deploy/deploy.sh --install 192.168.1.195 mastrctrl

# Or navigate into deploy folder:
cd deploy
bash deploy.sh --install 192.168.1.195 mastrctrl
```

See `deploy/DEPLOY_GUIDE.md` for full documentation.

## Folders

### `deploy/` - Main Deployment Scripts

**Primary scripts:**
- `deploy.sh` - **Main deployment script** with flags:
  - `--verify` - Check Pi configuration
  - `--update` - Copy code files
  - `--install` - Full setup (idempotent)
  - `--run` - Start controller
- `DEPLOY_GUIDE.md` - Quick reference guide
- `deploy-ui-to-pi.ps1` - Deploy UI (Vue/Electron) separately

**Use deploy.sh for all Pi server/controller deployment.**

### `release/` - Release Management

- `create_release.ps1` - Build release packages
- `release-with-gh.ps1` - Publish to GitHub releases
- `generate_manifest.py` - Generate update manifest
- `setup-github-auth.ps1` - Configure GitHub authentication
- `build/` - Compiled firmware binaries
- `*.zip`, `*.bin` - Release artifacts

### `update-system/` - Pi-Side Update Scripts

Scripts that run **on the Pi** for OTA updates:
- `update-install.sh` - Install updates on Pi
- `rollback.sh` - Rollback to previous version

These are deployed to the Pi and used by the update system.

### `obsolete/` - Deprecated Scripts

Old scripts replaced by `deploy/deploy.sh`:
- `check-usb-gadget.ps1` - Now: `deploy.sh --verify`
- `configure-pi-usb-gadget.bat` - Now: `deploy.sh --install`
- `diagnose-usb.bat` - Now: `deploy.sh --verify`
- `update-usb-gadget.bat` - Now: `deploy.sh --install`
- `find-pi.bat` - No longer needed

**These scripts are kept for reference but should not be used.**

## Common Tasks

### First-Time Pi Setup
```bash
# From package/scripts directory:
./deploy/deploy.sh --install 192.168.1.195 mastrctrl
```

### Update Code During Development
```bash
./deploy/deploy.sh --update 192.168.1.195 mastrctrl
./deploy/deploy.sh --run 192.168.1.195 mastrctrl
```

### Check Pi Status
```bash
./deploy/deploy.sh --verify 192.168.1.195 mastrctrl
```

### Create a New Release
```powershell
# From PowerShell:
.\release\create_release.ps1 -Version "1.2.3"
```

### Deploy UI to Pi
```powershell
# From PowerShell:
.\deploy\deploy-ui-to-pi.ps1 -PiAddress 192.168.1.195
```

## Migration from Old Scripts

If you were using the old scripts:

| Old Script | New Command |
|------------|-------------|
| `deploy-to-pi.ps1 -Deploy` | `deploy.sh --install` |
| `deploy-to-pi.ps1 -Run` | `deploy.sh --run` |
| `check-usb-gadget.ps1` | `deploy.sh --verify` |
| `configure-pi-usb-gadget.bat` | `deploy.sh --install` |
| `diagnose-usb.bat` | `deploy.sh --verify` |

## Notes

- Use `deploy.sh` from Git Bash, WSL, or native Linux/Mac terminal
- PowerShell scripts (`.ps1`) run from PowerShell on Windows
- Bash scripts (`.sh`) need chmod +x on Unix systems
- Default Pi username is `mastrctrl`
- Network IP is typically `192.168.1.195`
- USB gadget IP is `192.168.4.1` (after USB setup)

