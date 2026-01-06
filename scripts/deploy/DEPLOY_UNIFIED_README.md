# Unified Deployment Script

Simple script to deploy both Vue UI and Python servers to Raspberry Pi.

## Usage

### Windows (PowerShell)

```powershell
# Basic deployment (assumes UI already built)
.\deploy-unified.ps1 192.168.1.195

# Full installation (build UI + deploy + setup)
.\deploy-unified.ps1 --Install 192.168.1.195

# With custom username
.\deploy-unified.ps1 --Install 192.168.1.195 mastrctrl
```

### Linux/Mac (Bash)

```bash
# Basic deployment (assumes UI already built)
./deploy-unified.sh 192.168.1.195

# Full installation (build UI + deploy + setup)
./deploy-unified.sh --install 192.168.1.195

# With custom username
./deploy-unified.sh --install 192.168.1.195 mastrctrl
```

## What It Does

### Basic Deployment (no flags)
1. Validates source directories exist
2. Creates zip packages (UI and Python)
3. Copies packages to Pi via SCP
4. Extracts files on Pi to:
   - `~/mastrctrl/ui/` (Vue UI)
   - `~/mastrctrl/package/python/pi/` (Python servers)

### Full Installation (`--install` flag)
Everything above, plus:
1. Builds Vue UI (`npm run build`)
2. Installs Python dependencies on Pi
3. Installs and enables systemd service

## Requirements

- SSH access to Pi (key-based auth recommended)
- Pi must be reachable via network
- For `--install`: npm and node installed locally

## Files Deployed

**Vue UI:**
- All files from `package/ui/dist/` → `~/mastrctrl/ui/`

**Python Servers:**
- All files from `package/python/pi/` → `~/mastrctrl/package/python/pi/`
- Excludes: `*.zip`, `__pycache__`, `*.pyc`, `.pytest_cache`, `mastrctrl-updates/`

## After Deployment

**Start controller manually:**
```bash
ssh mastrctrl@192.168.1.195
cd ~/mastrctrl/package/python/pi
python3 main.py
```

**Or use systemd service (if --install was used):**
```bash
ssh mastrctrl@192.168.1.195 sudo systemctl start mastrctrl-pi.service
```

