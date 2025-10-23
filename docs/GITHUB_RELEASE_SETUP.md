# GitHub Release Setup - Complete Guide

## ✅ What's Been Configured

Your repository **https://github.com/johnmastri/ui** is now fully configured for OTA updates!

### Configuration Updates Made

1. **Update Manager** (`package/python/update_manager.py`)
   - GitHub repo: `johnmastri/ui` ✓
   - Checks: `https://github.com/johnmastri/ui/releases/latest/download/manifest.json`

2. **Release Scripts** (`package/scripts/create_release.ps1`)
   - Default repo: `johnmastri/ui` ✓
   - Builds and packages all components

3. **Automated Release** (`package/scripts/release-with-gh.ps1`)
   - One-command release creation ✓
   - Automatic GitHub CLI integration ✓
   - Tag creation and push ✓

4. **GitHub CLI** 
   - Installed: `gh version 2.81.0` ✓
   - Not yet authenticated ⚠️

## 🚀 Creating Your First Release

### Step 1: Authenticate (One Time Only)

Run the authentication helper:

```powershell
cd package\scripts
.\setup-github-auth.ps1
```

This will:
- Check if gh CLI is installed
- Guide you through GitHub authentication
- Verify authentication works

**What to expect:**
1. Browser will open
2. You'll see a one-time code
3. Paste it in GitHub
4. Authorize GitHub CLI
5. Done!

### Step 2: Create Release v1.0.0

```powershell
.\release-with-gh.ps1 -Version 1.0.0
```

This single command will:
1. ✓ Update `version.json` to 1.0.0
2. ✓ Build Vue.js UI (`npm run build`)
3. ✓ Package components into zips
4. ✓ Generate `manifest.json` with SHA256 checksums
5. ✓ Create git tag `v1.0.0`
6. ✓ Push tag to GitHub
7. ✓ Create GitHub Release
8. ✓ Upload all files:
   - `ui-v1.0.0.zip`
   - `server-v1.0.0.zip`
   - `firmware-v1.0.0.bin` (if available)
   - `manifest.json` ⭐ **Critical!**

### Step 3: Deploy to Pi

```powershell
.\deploy-to-pi.ps1
```

This will:
- Copy all files to Pi
- Install dependencies
- Restart services
- Update manager will now check GitHub for updates!

## 📋 Complete Workflow

### Development → Release → Deploy

```powershell
# 1. Make changes to code
cd d:\Dropbox\projects\midi_cs\controller_v2

# 2. Test locally
cd VSTMastrCtrl\mastrctrl\plugin\ui
npm run dev

# 3. When ready, create release
cd ..\..\..\..\package\scripts
.\release-with-gh.ps1 -Version 1.0.1

# 4. Deploy to Pi (optional - or use OTA from hardware!)
.\deploy-to-pi.ps1
```

### OTA Update from Hardware

Once deployed:
1. **Settings** → **Device** → **System Update**
2. **Check for Updates** (finds v1.0.1 on GitHub)
3. **Download Update** (server only by default)
4. **Install Now**
5. Done! Server updated in ~30 seconds

## 🔍 How It Works

### Release Flow

```
Developer Machine (You)
         ↓
    Run: release-with-gh.ps1
         ↓
    Creates Tag: v1.0.0
         ↓
    Pushes to GitHub
         ↓
    GitHub Release Created
         ↓
Files Available At:
https://github.com/johnmastri/ui/releases/download/v1.0.0/
    - ui-v1.0.0.zip
    - server-v1.0.0.zip
    - firmware-v1.0.0.bin
    - manifest.json ⭐
         ↓
Raspberry Pi Checks:
https://github.com/johnmastri/ui/releases/latest/download/manifest.json
         ↓
    Downloads & Installs
```

### Manifest File

The `manifest.json` tells the Pi what's available:

```json
{
  "latest_version": "1.0.0",
  "components": {
    "ui": {
      "version": "1.0.0",
      "url": "https://github.com/johnmastri/ui/releases/download/v1.0.0/ui-v1.0.0.zip",
      "sha256": "abc123...",
      "size_bytes": 2048576
    }
  }
}
```

## 🎯 Testing Your Setup

### 1. Check Release Created

```powershell
gh release view v1.0.0 --repo johnmastri/ui
```

### 2. Verify Manifest URL

```powershell
# Check specific version
curl https://github.com/johnmastri/ui/releases/download/v1.0.0/manifest.json

# Check latest (what Pi checks)
curl https://github.com/johnmastri/ui/releases/latest/download/manifest.json
```

### 3. Test from Hardware UI

1. SSH to Pi (optional): `ssh pi@192.168.1.195`
2. Use touchscreen interface:
   - Settings → Device → System Update
   - Should show "v1.0.0 available"

## 📝 Release Options

### Draft Release (Review Before Publishing)

```powershell
.\release-with-gh.ps1 -Version 1.0.0 -Draft
```

Review and publish from: https://github.com/johnmastri/ui/releases

### Skip Build (Already Built)

```powershell
.\release-with-gh.ps1 -Version 1.0.0 -SkipBuild
```

### Delete a Release

```powershell
gh release delete v1.0.0 --repo johnmastri/ui --yes
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
```

## 🐛 Troubleshooting

### "Authentication failed"

Re-run setup:
```powershell
.\setup-github-auth.ps1
```

### "Tag already exists"

Delete and recreate:
```powershell
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0
.\release-with-gh.ps1 -Version 1.0.0
```

### "No updates detected" from Pi

1. Check manifest exists:
   ```
   https://github.com/johnmastri/ui/releases/download/v1.0.0/manifest.json
   ```

2. Check server logs on Pi:
   ```bash
   ssh pi@192.168.1.195 "journalctl -u mastrctrl-server -f"
   ```

3. Verify update manager config:
   ```bash
   ssh pi@192.168.1.195 "cat /home/pi/mastrctrl/current/python/update_manager.py | grep github_repo"
   ```
   Should show: `'github_repo': 'johnmastri/ui'`

### "Firmware build failed"

Firmware is optional! The script continues without it. To include firmware:
1. Install Arduino CLI: `winget install --id Arduino.ArduinoCLI`
2. Configure for ESP32-S3
3. Or build manually and place in `release/firmware-v1.0.0.bin`

## 📚 Additional Resources

- **Full Guide**: `package/RELEASE_GUIDE.md`
- **Quick Reference**: `package/QUICK_START.md`
- **Installation**: `package/INSTALL.md`
- **Implementation**: `package/IMPLEMENTATION_SUMMARY.md`

## ✨ You're All Set!

Your repository is configured and ready. Here's what to do next:

1. **Authenticate** (one time):
   ```powershell
   cd package\scripts
   .\setup-github-auth.ps1
   ```

2. **Create first release**:
   ```powershell
   .\release-with-gh.ps1 -Version 1.0.0
   ```

3. **View your release**:
   https://github.com/johnmastri/ui/releases

4. **Deploy and test OTA updates!**

---

**Repository**: https://github.com/johnmastri/ui  
**Status**: ✅ Configured and Ready  
**Next Step**: Authenticate and create v1.0.0

