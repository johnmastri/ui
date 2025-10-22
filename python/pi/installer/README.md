# MastrCtrl Windows Installer Package

This directory contains everything needed to create a professional Windows installer for MastrCtrl that includes automatic USB driver installation.

## Files

### Driver Files
- **`MastrCtrl_USB.inf`** - Windows driver information file that registers the USB device
- **`install-driver.bat`** - Standalone driver installer for testing

### Installer Script
- **`MastrCtrl_Installer.iss`** - Inno Setup script to build the complete installer

## How It Works

When a user installs MastrCtrl, the installer:

1. ✅ Installs the VST3 plugin to the standard VST3 folder
2. ✅ Installs UI files to Program Files
3. ✅ **Pre-registers the USB driver** using `pnputil.exe`
4. ✅ Creates shortcuts and documentation

**After installation**, when the user plugs in the hardware:
- Windows automatically recognizes the device
- Shows as **"MastrCtrl USB MIDI Controller"** in Device Manager
- Auto-loads the RNDIS network driver
- Gets IP via DHCP automatically
- **Completely plug-and-play!**

## Building the Installer

### Prerequisites

1. **Install Inno Setup**
   - Download from: https://jrsoftware.org/isinfo.php
   - Free and open source
   - Version 6.x recommended

2. **Prepare your files**
   - Build your VST3 plugin
   - Build the UI (run `npm run build` in ui folder)
   - Have a LICENSE.txt file ready

### Steps

1. **Edit the installer script:**
   ```
   Open MastrCtrl_Installer.iss in Inno Setup
   ```

2. **Update these paths** (lines 27-32):
   ```
   ; Point these to your actual build outputs
   Source: "..\..\VSTMastrCtrl\build\Release\MastrCtrl.vst3\*"
   Source: "..\..\ui\dist\*"
   ```

3. **Generate a new GUID:**
   - In Inno Setup: Tools → Generate GUID
   - Replace `{YOUR-GUID-HERE}` on line 17

4. **Update company info** (lines 8-11):
   ```
   #define MyAppPublisher "Your Company Name"
   #define MyAppURL "https://yourwebsite.com"
   ```

5. **Compile:**
   - Build → Compile (or press F9)
   - Output will be in `output/MastrCtrl_Setup_1.0.0.exe`

## Testing the Driver Installation

Before building the full installer, test just the driver:

1. **Right-click `install-driver.bat`**
2. **Run as Administrator**
3. Should see: "Driver installed successfully!"
4. Plug in the Pi hardware
5. Check Device Manager - should show "MastrCtrl USB MIDI Controller" under Network adapters

If this works, the full installer will work too!

## What Gets Installed

```
C:\Program Files\MastrCtrl\
├── driver\
│   └── MastrCtrl_USB.inf
├── docs\
│   ├── WINDOWS_USER_GUIDE.md
│   └── USB_GADGET_SETUP_GUIDE.md
└── ui\
    └── (all UI files)

C:\Program Files\Common Files\VST3\
└── MastrCtrl.vst3\
    └── (VST3 plugin)

Start Menu\
└── MastrCtrl\
    ├── MastrCtrl (opens UI)
    ├── User Guide
    └── Uninstall
```

## User Experience

**Installation (one time):**
1. Download `MastrCtrl_Setup_1.0.0.exe`
2. Run installer (accepts admin prompt)
3. Click through wizard
4. Done in 30 seconds

**First use:**
1. Plug in hardware via USB-C
2. Windows: "Installing device..." (3-5 seconds)
3. Windows: "Device ready to use!"
4. Opens VST in DAW
5. Hardware automatically connects
6. **No manual configuration needed!**

## Customization

### Change device name
Edit `MastrCtrl_USB.inf` line 51:
```inf
MastrCtrlDevice     = "Your Custom Name Here"
```

### Add license agreement
Add to installer script:
```ini
LicenseFile=LICENSE.txt
```

### Add custom wizard images
```ini
WizardImageFile=wizard.bmp
WizardSmallImageFile=wizard-small.bmp
```

### Add post-install actions
In the `[Run]` section:
```ini
Filename: "{app}\ui\index.html"; Description: "Launch MastrCtrl"; Flags: postinstall shellexec skipifsilent nowait
```

## Distribution

Once built, distribute `MastrCtrl_Setup_1.0.0.exe`:
- Upload to your website
- Share via download link
- Put on GitHub releases
- Distribute with hardware

**File size:** Typically 5-15 MB depending on VST size.

## Troubleshooting

### "Driver installation failed"
- User must run installer as Administrator
- Check Windows version (needs Win7 SP1 or newer)
- Antivirus might block driver installation

### "VST not showing in DAW"
- Check VST3 path is correct in script
- Some DAWs need restart or rescan
- Verify 64-bit vs 32-bit match

### "Device not recognized after install"
- Reboot computer after installation
- Check Device Manager for driver status
- Verify Pi is using VID/PID: 045E:07AB

## Advanced: Code Signing (Optional)

For professional distribution, consider code signing:

1. Purchase code signing certificate ($100-400/year)
2. Sign the installer:
   ```
   signtool sign /f cert.pfx /p password /t http://timestamp.digicert.com MastrCtrl_Setup.exe
   ```
3. Benefits:
   - No "Unknown Publisher" warning
   - Builds trust with users
   - Required for some enterprise environments

## Support

If users have issues:
1. Check they ran installer as Administrator
2. Verify Windows is up to date
3. Try manual driver install with `install-driver.bat`
4. Check Device Manager for errors
5. See `WINDOWS_USER_GUIDE.md` for troubleshooting

## License

Include appropriate license files and update the installer script accordingly.



