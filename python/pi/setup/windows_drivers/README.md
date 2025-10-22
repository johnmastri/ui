# Windows Driver Auto-Installation

This directory contains optional Windows driver files for the Raspberry Pi RNDIS USB gadget.

## Automatic Installation (No Driver File Needed)

The USB gadget is configured with:
- **Vendor ID**: `0x0525` (Netchip Technology)
- **Product ID**: `0xa4a2` (RNDIS Gadget)
- **Device Class**: `0xEF` (Miscellaneous)
- **Microsoft OS Descriptors**: Enabled

These settings tell Windows to automatically use its built-in RNDIS driver. **In most cases, no manual driver installation is needed.**

## What Happens When You Plug In

1. Windows detects new USB device
2. Windows reads device descriptors
3. Windows sees Microsoft OS descriptor signature (`MSFT100`)
4. Windows automatically loads `usb8023.sys` (RNDIS driver)
5. Network adapter appears in Device Manager
6. DHCP assigns IP automatically
7. Pi is accessible at `192.168.4.1`

**Total time: 3-10 seconds**

## If Automatic Installation Fails

### Method 1: Windows Update

1. Right-click unknown device in Device Manager
2. Update driver → Search automatically
3. Windows Update will find and install driver

### Method 2: Manual INF Installation

If Windows still doesn't recognize the device:

1. Right-click the unknown device
2. Update driver → Browse my computer
3. Point to this directory (`windows_drivers/`)
4. Windows will use `rpi_rndis.inf` to load the built-in driver

### Method 3: Device Manager Manual Selection

1. Right-click unknown device → Update driver
2. Browse → Let me pick from a list
3. Network adapters
4. Manufacturer: **Microsoft** or **Microsoft Corporation**
5. Model: **Remote NDIS based Internet Sharing Device** or **USB RNDIS Adapter**

## Supported Windows Versions

- Windows 7 SP1 and later (with updates)
- Windows 8/8.1
- Windows 10 (all versions)
- Windows 11

## Technical Details

### Microsoft OS Descriptors

The gadget configuration includes:
```
os_desc/use = 1
os_desc/b_vendor_code = 0xcd
os_desc/qw_sign = MSFT100
```

These tell Windows:
- "I have Microsoft-specific configuration"
- "Use vendor code 0xcd to query me"
- "I'm compatible with Microsoft OS 1.00+"

This triggers automatic driver installation without needing an INF file.

### Device Identifiers

Windows looks for:
```
USB\VID_0525&PID_A4A2
```

This matches the built-in RNDIS driver in Windows.

### Alternative: Use Microsoft's Own VID/PID

For even better compatibility, you could use Microsoft's vendor ID:
```
VID: 0x045E (Microsoft)
PID: 0x07AB (USB Ethernet/RNDIS Adapter)
```

But this is technically unofficial use of Microsoft's ID.

## Troubleshooting

### "USB Device Not Recognized"

**Cause**: Cable is power-only or bad
**Solution**: Try different USB-C cable with data support

### Device Shows as "CDC ECM" Instead of "RNDIS"

**Cause**: Windows detected ECM before RNDIS
**Solution**: Uninstall device, unplug, replug. Should now detect as RNDIS.

### Driver Installs but No Network

**Cause**: DHCP server (dnsmasq) not running on Pi
**Solution**: 
```bash
# On Pi
sudo systemctl status dnsmasq
sudo systemctl restart dnsmasq
```

### "Code 10" Error in Device Manager

**Cause**: Driver loaded but can't communicate with device
**Solutions**:
1. Disable/re-enable device in Device Manager
2. Try different USB port
3. Check Pi logs: `dmesg | tail -20`

## For Distribution

If you're distributing this to end users:

1. **Best**: Current setup with OS descriptors (no driver files needed)
2. **Good**: Include `rpi_rndis.inf` as backup
3. **Overkill**: Create signed driver package (requires code signing certificate ~$200/year)

The current configuration should work on 95%+ of Windows systems without any manual steps.

## Testing

To verify automatic installation:

1. Fresh Windows 10/11 machine
2. Plug in Pi via USB-C
3. Watch Device Manager
4. Device should appear as "Remote NDIS based Internet Sharing Device" or similar
5. Network adapter gets IP via DHCP automatically
6. `ping 192.168.4.1` succeeds

**No manual steps required!**

