# Scripts Directory

Build, package, and release automation scripts.

## Release Creation & Upload

### 1. Build and Create Release

```powershell
# From project root
.\package\scripts\release-with-gh.ps1 -Version 0.1.0
```

This script:
- ✓ Builds UI (npm run build)
- ✓ Packages UI and server into versioned zip files
- ✓ Compiles ESP32 firmware (if arduino-cli available)
- ✓ Generates manifest.json with SHA256 checksums
- ✓ Creates git tag
- ✓ Pushes tag to GitHub
- ✓ Creates GitHub Release
- ✓ Uploads all packages and manifest

### 2. Options

```powershell
# Skip building (use existing build)
.\release-with-gh.ps1 -Version 0.1.0 -SkipBuild

# Create draft release (not public)
.\release-with-gh.ps1 -Version 0.1.0 -Draft
```

## Other Scripts

- **deploy-to-pi.ps1** - Deploy to Pi for testing (not for production releases)
- **generate_manifest.py** - Generate update manifest (called by release-with-gh.ps1)
- **create_release.ps1** - Build & package (called by release-with-gh.ps1)
- **setup-github-auth.ps1** - Install GitHub CLI and authenticate
- **update-install.sh** - Pi-side update installation (runs on Pi)
- **rollback.sh** - Pi-side rollback script (runs on Pi)

## Requirements

- GitHub CLI (`gh`) - installed via `setup-github-auth.ps1`
- Node.js & npm - for UI builds
- Python 3 - for manifest generation
- arduino-cli - for firmware compilation (see FIRMWARE_BUILD_SETUP.md)

### Firmware Build Setup

To enable automatic firmware building during releases:

1. Install Arduino CLI:
   ```powershell
   winget install ArduinoSA.CLI
   ```

2. Configure for ESP32:
   ```powershell
   arduino-cli config init
   arduino-cli config add board_manager.additional_urls https://espressif.github.io/arduino-esp32/package_esp32_index.json
   arduino-cli core update-index
   arduino-cli core install esp32:esp32
   ```

For detailed setup instructions, see [FIRMWARE_BUILD_SETUP.md](FIRMWARE_BUILD_SETUP.md).

## Release Flow

```
1. Make changes in package/ui, package/python, or package/esp32
2. Commit changes to git
3. Run release-with-gh.ps1 with new version
4. GitHub Release is created automatically
5. Pi devices auto-check for updates (or manual check from UI)
```

