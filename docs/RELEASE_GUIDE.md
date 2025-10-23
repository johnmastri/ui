# Complete Release Guide

This guide walks you through creating and publishing a release for the MastrCtrl OTA Update System.

## Prerequisites

1. **GitHub CLI Installed** ✓
   ```powershell
   gh --version  # Should show version 2.81.0 or higher
   ```

2. **Authenticated with GitHub**
   ```powershell
   gh auth login
   ```
   Follow the prompts:
   - Choose: GitHub.com
   - Protocol: HTTPS
   - Authentication: Login with a web browser
   - Follow browser flow

3. **Repository Configured**
   - GitHub repo: `johnmastri/ui`
   - Already configured in:
     - `package/python/update_manager.py`
     - `package/scripts/create_release.ps1`
     - `package/scripts/release-with-gh.ps1`

## Quick Release (Recommended)

Use the automated release script:

```powershell
cd package/scripts

# Create and publish release v1.0.0
.\release-with-gh.ps1 -Version 1.0.0
```

This single command will:
1. ✓ Update version.json
2. ✓ Build Vue.js UI
3. ✓ Package all components
4. ✓ Generate manifest with checksums
5. ✓ Create git tag
6. ✓ Push to GitHub
7. ✓ Create GitHub Release
8. ✓ Upload all files

## Manual Release (Step by Step)

### Step 1: Authenticate with GitHub

```powershell
gh auth login
```

### Step 2: Build Release Packages

```powershell
cd package/scripts
.\create_release.ps1 -Version 1.0.0
```

This creates in `release/`:
- `ui-v1.0.0.zip`
- `server-v1.0.0.zip`
- `firmware-v1.0.0.bin` (if Arduino CLI available)
- `manifest.json`

### Step 3: Create Git Tag

```powershell
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### Step 4: Create GitHub Release

```powershell
gh release create v1.0.0 release/* `
  --repo johnmastri/ui `
  --title "v1.0.0" `
  --notes "Initial release with OTA update system"
```

## Release Options

### Create Draft Release

```powershell
.\release-with-gh.ps1 -Version 1.0.0 -Draft
```

You can then edit and publish it later from GitHub web interface.

### Skip Build (Use Existing Files)

```powershell
.\release-with-gh.ps1 -Version 1.0.0 -SkipBuild
```

Useful if you've already built the packages.

## What Gets Published

### Required Files
- **ui-v1.0.0.zip** - Vue.js UI with Electron
- **server-v1.0.0.zip** - Python WebSocket server
- **manifest.json** - ⭐ **CRITICAL** - Update system needs this!

### Optional Files
- **firmware-v1.0.0.bin** - ESP32 firmware (if built)

## Manifest Structure

The `manifest.json` file contains:

```json
{
  "latest_version": "1.0.0",
  "release_date": "2025-10-17T...",
  "components": {
    "ui": {
      "version": "1.0.0",
      "url": "https://github.com/johnmastri/ui/releases/download/v1.0.0/ui-v1.0.0.zip",
      "sha256": "abc123...",
      "size_bytes": 2048576
    },
    "server": { ... },
    "firmware": { ... }
  }
}
```

## Testing Your Release

### From Development Machine

```powershell
# View release
gh release view v1.0.0 --repo johnmastri/ui

# Verify manifest URL
curl https://github.com/johnmastri/ui/releases/download/v1.0.0/manifest.json

# Check latest release
curl https://github.com/johnmastri/ui/releases/latest/download/manifest.json
```

### From Raspberry Pi

```bash
# Deploy updated server with OTA system
cd package/scripts
./deploy-to-pi.ps1

# SSH to Pi and test
ssh pi@192.168.1.195

# Check update manager config
cat /home/pi/mastrctrl/current/python/update_manager.py | grep github_repo
# Should show: 'github_repo': 'johnmastri/ui'
```

### From Hardware UI

1. **Settings** → **Device** → **System Update**
2. Click **"Check for Updates"**
3. Should detect v1.0.0 available
4. Select components (Server is default)
5. **Download Update**
6. **Install Now**

## Common Issues

### "Tag already exists"

Delete and recreate:
```powershell
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

Then run release script again.

### "Authentication failed"

Re-authenticate:
```powershell
gh auth login
gh auth status
```

### "No updates detected" from hardware UI

1. Check manifest exists:
   ```
   https://github.com/johnmastri/ui/releases/download/v1.0.0/manifest.json
   ```

2. Check update manager config:
   ```bash
   ssh pi@192.168.1.195 "cat /home/pi/mastrctrl/update_config.json"
   ```

3. View server logs:
   ```bash
   ssh pi@192.168.1.195 "journalctl -u mastrctrl-server -f"
   ```

### "Firmware build failed"

Firmware is optional. If you don't have Arduino CLI:
1. Build firmware manually in Arduino IDE
2. Export compiled binary
3. Place in `release/firmware-v1.0.0.bin`
4. Or skip firmware and only update UI/Server

## Release Checklist

- [ ] Update CHANGELOG.md with release notes
- [ ] Commit any pending changes
- [ ] Run release script: `.\release-with-gh.ps1 -Version X.Y.Z`
- [ ] Verify release on GitHub
- [ ] Test manifest URL
- [ ] Deploy to Pi
- [ ] Test update from hardware UI
- [ ] Document any issues

## Release Workflow Diagram

```
Developer Machine
    ↓
1. Run: release-with-gh.ps1 -Version 1.0.0
    ↓
2. Builds: UI, Server, Firmware (optional)
    ↓
3. Creates: manifest.json with SHA256 checksums
    ↓
4. Tags: v1.0.0
    ↓
5. Pushes: Tag to GitHub
    ↓
6. Creates: GitHub Release
    ↓
7. Uploads: All files to release
    ↓
GitHub: https://github.com/johnmastri/ui/releases/tag/v1.0.0
    ↓
Raspberry Pi checks:
https://github.com/johnmastri/ui/releases/latest/download/manifest.json
    ↓
Downloads & Installs Updates
```

## Future Releases

For subsequent releases (v1.0.1, v1.1.0, etc.):

```powershell
# Update CHANGELOG.md first

# Create new release
cd package/scripts
.\release-with-gh.ps1 -Version 1.0.1

# That's it! Automatic deployment to Pi via OTA
```

## Advanced: GitHub Actions (Optional)

To automate releases on git tag push, see `.github/workflows/release.yml` (not yet created).

This would allow:
```bash
git tag v1.0.0
git push origin v1.0.0
# GitHub Actions automatically builds and publishes release
```

## Support

- View releases: https://github.com/johnmastri/ui/releases
- GitHub CLI docs: https://cli.github.com/manual/
- Project docs: See `package/` directory

---

**Ready to create your first release!**

```powershell
cd d:\Dropbox\projects\midi_cs\controller_v2\package\scripts
.\release-with-gh.ps1 -Version 1.0.0
```

