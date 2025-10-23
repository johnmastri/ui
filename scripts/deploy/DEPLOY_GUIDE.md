# Deploy Script - Quick Reference

## Command
```bash
./deploy.sh [FLAG] <pi-address> [pi-user]
```

## Pi IP Addresses
- **192.168.1.195** (or similar): Pi on your local network (WiFi/Ethernet)
- **192.168.4.1**: Pi via USB-C cable after USB gadget setup

Use the network IP during development. Use 192.168.4.1 when connected via USB-C.

## Flags

| Flag | Purpose |
|------|---------|
| `--verify` | Check Pi configuration status (read-only) |
| `--update` | Copy code files to Pi |
| `--install` | Full setup (idempotent, safe to re-run) |
| `--run` | Start controller with existing code |

## Common Workflows

### First-Time Setup
```bash
./deploy.sh --install 192.168.1.195 mastrctrl
```

### Development Iteration
```bash
# Update code (use your Pi's actual IP)
./deploy.sh --update 192.168.1.195 mastrctrl

# Test it
./deploy.sh --run 192.168.1.195 mastrctrl
```

### Quick Restart (no code changes)
```bash
./deploy.sh --run 192.168.1.195 mastrctrl
```

### Check Status
```bash
# Over network
./deploy.sh --verify 192.168.1.195 mastrctrl

# Or via USB gadget (after USB setup complete)
./deploy.sh --verify 192.168.4.1 mastrctrl
```

### Fix Broken System
```bash
# Re-run install (safe, checks what's missing)
./deploy.sh --install 192.168.1.195 mastrctrl
```

## What Each Flag Does

### `--verify`
- Checks boot configuration
- Verifies USB Device Controller
- Checks if modules are loaded
- Verifies usb0 interface exists
- Checks systemd services status
- **Does NOT modify anything**

### `--update`
- Creates zip package of code
- Copies to Pi via SCP
- Extracts to `~/mastrctrl/package/python/pi/`
- Sets executable permissions
- **Does NOT configure system**

### `--install`
- Copies code files
- Checks and installs dependencies (if missing)
- Checks and configures USB gadget (if missing)
- Checks and installs systemd services (if missing)
- **Idempotent - safe to run multiple times**
- Prompts for reboot if USB config changed

### `--run`
- SSH to Pi
- Runs `start_controller.sh`
- **Assumes code already on Pi**
- Keep terminal open (Ctrl+C to stop)

## Notes

- Default username: `mastrctrl`
- After USB gadget setup, Pi will be at `192.168.4.1`
- First-time setup requires reboot for USB gadget
- `--install` is smart: skips what's already configured

