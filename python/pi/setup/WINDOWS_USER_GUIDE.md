# Raspberry Pi USB Connection - User Guide

## What to Expect

Your Raspberry Pi MIDI controller uses a single USB-C cable for both power and communication. **Everything happens automatically!**

### First Time Setup (One-Time)

1. Connect Raspberry Pi to your computer via USB-C cable
2. Wait 10-15 seconds
3. Windows will show notifications:
   - "Installing device driver software..."
   - "Device is ready to use"
4. Done! Pi is now at `192.168.4.1`

**No configuration needed!** Windows automatically:
- Detects the USB device
- Installs the built-in RNDIS Ethernet driver
- Gets an IP address from the Pi (via DHCP)

### Every Time After

1. Plug in USB-C cable
2. Wait 5-10 seconds
3. Pi is ready at `192.168.4.1`

## Troubleshooting

### "USB device not recognized"

**Most common cause:** Bad or power-only USB cable

**Try:**
1. Use a different USB-C cable (must support data, not just charging)
2. Try a different USB port on your computer
3. Make sure you're using the USB-C port on the Pi (not the blue USB-A ports)

### Driver doesn't install automatically

If Windows shows an unknown device but doesn't install the driver:

**Option 1: Let Windows Update find it**
1. Open Device Manager (Win+X → Device Manager)
2. Find the unknown device (probably under "Other devices")
3. Right-click → Update driver
4. Choose "Search automatically for drivers"
5. Windows will find and install the driver

**Option 2: Manual selection**
1. Open Device Manager
2. Right-click unknown device → Update driver
3. Choose "Browse my computer for drivers"
4. Choose "Let me pick from a list of available drivers"
5. Select "Network adapters"
6. Manufacturer: "Microsoft" or "Microsoft Corporation"
7. Model: "Remote NDIS based Internet Sharing Device"
8. Click Next

### Can't connect to Pi

**Check Windows got an IP address:**
1. Open Command Prompt
2. Type: `ipconfig`
3. Look for "Ethernet adapter" with an IP like `192.168.4.x`

**If you see 169.254.x.x:**
This means DHCP didn't work. Try:
1. Unplug and replug the USB cable
2. Wait 15 seconds
3. Check `ipconfig` again

**Test connectivity:**
```cmd
ping 192.168.4.1
```

Should reply with `Reply from 192.168.4.1: bytes=32 time<1ms`

### Device shows but no network

1. Check Device Manager for yellow warning symbols
2. If you see a warning on the network adapter:
   - Right-click → Disable
   - Right-click → Enable
   - Wait 10 seconds

## Technical Details (for curious users)

### What's happening under the hood?

The Raspberry Pi presents itself as a **USB Ethernet adapter** using the RNDIS protocol (Remote Network Driver Interface Specification). This is a standard developed by Microsoft that Windows has built-in support for.

**The Pi acts as:**
- USB network adapter (from Windows' perspective)
- DHCP server (assigns IP addresses automatically)  
- WebSocket server (for MIDI controller communication)

**Network configuration:**
- Pi: `192.168.4.1`
- Windows: `192.168.4.10-250` (assigned automatically)
- Subnet: `255.255.255.0`

### Why this method?

**Alternatives:**
- WiFi: Requires network configuration, router, etc.
- Bluetooth: Limited range, pairing hassles
- Separate Ethernet cable: Two cables (power + data)

**USB Gadget advantages:**
- Single cable (power + data)
- No network configuration needed
- Direct connection (no router/WiFi needed)
- Low latency
- Plug and play!

## Advanced: Connection Status

To see detailed connection status:

**Windows PowerShell:**
```powershell
# See all network adapters
Get-NetAdapter

# See the USB adapter specifically
Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*RNDIS*"}

# See IP configuration
ipconfig /all

# Test connection
Test-Connection 192.168.4.1
```

**Check what the Pi sees:**
If you have SSH access over another network:
```bash
ssh mastrctrl@192.168.1.195  # Your Pi's WiFi IP
ip addr show usb0
```

Should show:
```
usb0: <BROADCAST,MULTICAST,UP,LOWER_UP>
    inet 192.168.4.1/24
```

## FAQ

**Q: Can I use any USB-C cable?**  
A: No, must be a data cable. Many cheap cables are power-only.

**Q: Can I connect multiple Pis to one computer?**  
A: Yes, but you'd need to configure different IP ranges for each.

**Q: Does this work on Mac/Linux?**  
A: Yes! Mac and Linux have better CDC-ECM support, so it often works even faster.

**Q: Will this interfere with my WiFi/Ethernet?**  
A: No, it's a separate network interface. Your existing connections work normally.

**Q: Do I need admin rights to use this?**  
A: First-time driver installation may require admin. After that, no.

**Q: Can I access the internet through the Pi?**  
A: Not by default. The Pi can access the internet through its WiFi/Ethernet, but Windows doesn't route through it.

**Q: What if I see "Limited" or "No Internet" on the connection?**  
A: That's normal! This is a direct Pi-to-PC connection, not an internet connection. It will show as limited, but works fine.

## Support

If you're still having issues after trying the above:

1. Check cable (try 2-3 different cables)
2. Try different USB port on Windows computer
3. Check Windows Device Manager for errors
4. Check Windows version (needs Windows 7 SP1 or newer)
5. Try a different computer to isolate the issue

The setup has been tested on:
- Windows 10 (all versions)
- Windows 11
- Various USB-C cables
- Different Pi 4B models

Should work 95%+ of the time with no manual steps!



