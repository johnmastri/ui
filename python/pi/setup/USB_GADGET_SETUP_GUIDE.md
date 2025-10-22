# USB Gadget Mode Setup Guide

Complete guide for setting up plug-and-play USB gadget mode on Raspberry Pi 4B with modern kernels (6.x+).

## Overview

This setup creates a **true plug-and-play** USB Ethernet connection between Raspberry Pi and Windows computers:

- **Single cable**: USB-C provides both power and data
- **Automatic configuration**: Windows gets IP via DHCP (no manual setup)
- **Immediate connectivity**: Pi accessible at `192.168.4.1`
- **Modern kernel support**: Works with Raspberry Pi OS kernel 6.x+ using configfs

## Quick Setup

### Automated (Recommended)

From your computer:
```powershell
cd package/scripts
.\deploy-to-pi.ps1 -PiAddress 192.168.1.195 -Deploy
```

Answer `y` when prompted to configure USB gadget mode.

### Manual Setup

On the Pi:
```bash
cd ~/mastrctrl/package/python/pi/setup
sudo bash configure_usb_gadget_modern.sh
```

Then reboot:
```bash
sudo reboot
```

## How It Works

### Components

1. **USB Device Controller (UDC)**
   - Pi 4B has `fe980000.usb` controller
   - Configured via device tree overlay (`dtoverlay=dwc2`)
   - Must disable conflicting `dwc_otg` legacy driver

3. **Gadget Configuration (configfs)**
   - Modern method for kernel 6.x+
   - Creates RNDIS Ethernet gadget
   - Uses Microsoft OS Descriptors for automatic Windows driver installation
   - Binds to UDC at boot

3. **Network Configuration**
   - Pi gets static IP: `192.168.4.1/24`
   - Creates `usb0` network interface

4. **DHCP Server (dnsmasq)**
   - Automatically assigns IPs to Windows: `192.168.4.10-250`
   - No manual Windows configuration needed

### Boot Sequence

1. Bootloader reads `/boot/firmware/config.txt`
   - `otg_mode=0` disables XHCI host mode
   - `dtoverlay=dwc2` enables USB device controller
   
2. Kernel loads with `dwc_otg` blacklisted

3. systemd runs `usb-gadget.service`
   - Loads `libcomposite` module
   - Creates gadget via configfs
   - Configures RNDIS function
   - Binds to UDC
   
4. Network interface `usb0` appears

5. `dnsmasq` starts DHCP server on `usb0`

6. Windows detects device, **automatically installs RNDIS driver via OS descriptors**, gets IP via DHCP

## Files Created

### Scripts
- `/usr/local/bin/usb-gadget-setup.sh` - Main gadget configuration
- `setup/usb_gadget_configfs.sh` - Source template

### Services
- `/etc/systemd/system/usb-gadget.service` - Auto-start service
- `setup/systemd/usb-gadget.service` - Source template

### Configuration
- `/etc/modprobe.d/blacklist-dwc_otg.conf` - Blacklist legacy driver
- `/etc/dnsmasq.d/usb-gadget.conf` - DHCP configuration
- `/boot/firmware/config.txt` - Device tree modifications

## Troubleshooting

### No UDC (/sys/class/udc/ is empty)

**Symptoms:** `ls /sys/class/udc/` shows nothing

**Causes:**
1. `dwc_otg` loading instead of `dwc2`
2. `otg_mode=1` enabling XHCI host mode
3. Device tree overlay not applied

**Solutions:**
```bash
# Check what's loading
dmesg | grep -i "dwc_otg\|dwc2"

# If dwc_otg appears, blacklist it
echo "blacklist dwc_otg" | sudo tee /etc/modprobe.d/blacklist-dwc_otg.conf

# Check boot config
sudo grep -E "otg_mode|dtoverlay.*dwc" /boot/firmware/config.txt

# Should see:
# otg_mode=0
# dtoverlay=dwc2

# Reboot required
sudo reboot
```

### usb0 Interface Doesn't Exist

**Symptoms:** `ip addr show usb0` says device doesn't exist

**Causes:**
1. UDC not available (see above)
2. Gadget not created
3. Wrong kernel modules

**Solutions:**
```bash
# Check if UDC exists
ls /sys/class/udc/

# Check if gadget was created
ls /sys/kernel/config/usb_gadget/pi4/

# Manually run setup
sudo /usr/local/bin/usb-gadget-setup.sh

# Check service status
sudo systemctl status usb-gadget.service
sudo journalctl -u usb-gadget.service
```

### Windows Not Recognizing Device

**Symptoms:** "USB device not recognized" error

**Automatic Driver Installation:**
The gadget is configured with Microsoft OS Descriptors that tell Windows to automatically load the built-in RNDIS driver. In 95% of cases, this happens automatically within 3-10 seconds.

**If automatic installation fails:**

1. **Let Windows Update find it:**
   - Device Manager → Unknown device
   - Right-click → Update driver
   - Search automatically for drivers

2. **Manual driver selection:**
   - Device Manager → Unknown device  
   - Right-click → Update driver → Browse → Let me pick
   - Network adapters → Microsoft → "Remote NDIS based Internet Sharing Device"

3. **Use included INF (backup):**
   - See `setup/windows_drivers/rpi_rndis.inf`
   - Device Manager → Update driver → Browse to that folder

**Root Causes:**
- Wrong USB cable (power-only) - try different cable
- Wrong USB port on Pi (must use USB-C power port)
- Outdated Windows (needs KB updates for RNDIS support)

### Windows Has Wrong IP

**Symptoms:** Windows has 169.254.x.x address

**Causes:**
1. dnsmasq not running
2. dnsmasq not listening on usb0

**Solutions:**
```bash
# Check dnsmasq status
sudo systemctl status dnsmasq

# Check dnsmasq is listening
sudo netstat -ulnp | grep 67

# Check configuration
cat /etc/dnsmasq.d/usb-gadget.conf

# Restart dnsmasq
sudo systemctl restart dnsmasq

# On Windows - renew DHCP
ipconfig /release
ipconfig /renew
```

### Can't Ping Pi from Windows

**Symptoms:** `ping 192.168.4.1` times out

**Causes:**
1. usb0 not configured with IP
2. usb0 interface down
3. Firewall blocking

**Solutions:**
```bash
# Check usb0 status
ip addr show usb0
# Should show: inet 192.168.4.1/24

# If missing, add IP
sudo ip addr add 192.168.4.1/24 dev usb0
sudo ip link set usb0 up

# Check firewall (if enabled)
sudo iptables -L -n
```

## Testing

### Verify UDC
```bash
ls /sys/class/udc/
# Should show: fe980000.usb
```

### Verify Gadget
```bash
ls /sys/kernel/config/usb_gadget/pi4/
# Should show: configs/ functions/ strings/ UDC bcd* id*
```

### Verify Network
```bash
ip addr show usb0
# Should show: inet 192.168.4.1/24 ... state UP
```

### Verify DHCP
```bash
sudo systemctl status dnsmasq
sudo tail -f /var/log/syslog | grep dnsmasq
# Plug in Windows, should see DHCP request/reply
```

### Test from Windows
```powershell
# Check adapter
Get-NetAdapter | Where-Object {$_.InterfaceDescription -like "*RNDIS*"}

# Check IP
ipconfig | findstr 192.168.4

# Test connectivity
ping 192.168.4.1
```

## Architecture Comparison

### Legacy (Kernel 5.x)
```
config.txt → dtoverlay=dwc2 → /etc/modules (g_ether) → usb0
```
- Uses `g_ether` module
- Limited configuration
- No Windows DHCP

### Modern (Kernel 6.x+)
```
config.txt → dtoverlay=dwc2 → configfs → RNDIS function → usb0 → dnsmasq
```
- Uses configfs-based gadget
- Flexible configuration
- Windows DHCP included
- True plug-and-play

## Advanced Configuration

### Automatic Windows Driver Installation

The gadget uses **Microsoft OS Descriptors** to trigger automatic driver installation:

```bash
# In usb-gadget-setup.sh
echo 1 > functions/rndis.usb0/os_desc/use
echo 0xcd > functions/rndis.usb0/os_desc/b_vendor_code  
echo MSFT100 > functions/rndis.usb0/os_desc/qw_sign
ln -s configs/c.1 os_desc
```

This tells Windows:
- **os_desc/use=1**: "I have Microsoft-specific descriptors"
- **b_vendor_code=0xcd**: "Query me with vendor code 0xcd"
- **qw_sign=MSFT100**: "I'm compatible with Microsoft OS 1.00+"

When Windows sees these descriptors, it automatically:
1. Identifies the device as RNDIS-compatible
2. Loads the built-in `usb8023.sys` driver
3. Creates network adapter
4. No user intervention needed!

**VID/PID Used:**
- Vendor: `0x0525` (Netchip Technology)
- Product: `0xa4a2` (Ethernet/RNDIS Gadget)

These IDs are recognized by Windows' built-in RNDIS driver database.

### Change IP Range

Edit `/etc/dnsmasq.d/usb-gadget.conf`:
```
dhcp-range=192.168.4.10,192.168.4.250,255.255.255.0,12h
```

### Add Multiple Gadget Functions

Modify `/usr/local/bin/usb-gadget-setup.sh` to add serial or mass storage:
```bash
# Add serial console
mkdir -p functions/acm.usb0
ln -s functions/acm.usb0 configs/c.1/

# Add mass storage
mkdir -p functions/mass_storage.usb0
echo /path/to/disk.img > functions/mass_storage.usb0/lun.0/file
ln -s functions/mass_storage.usb0 configs/c.1/
```

### Use ECM Instead of RNDIS

RNDIS is Windows-compatible. For Linux hosts, ECM might work better:
```bash
# In usb-gadget-setup.sh, replace:
mkdir -p functions/rndis.usb0
# With:
mkdir -p functions/ecm.usb0
```

## References

- [Linux USB Gadget configfs](https://www.kernel.org/doc/html/latest/usb/gadget_configfs.html)
- [Raspberry Pi USB Gadget](https://www.kernel.org/doc/html/latest/usb/gadget-testing.html)
- [dnsmasq Documentation](https://thekelleys.org.uk/dnsmasq/doc.html)

