# WebSocket Port Cleanup Guide

## Overview

The WebSocket server runs on port 8765 by default. If the server crashes or is stopped improperly, the port may remain bound and cause "Address already in use" errors when restarting.

## Automatic Port Cleanup (Recommended)

### Method 1: Use Startup Script

The `start_controller.sh` script automatically cleans up the port before starting:

```bash
cd ~/mastrctrl/package/python/pi
bash start_controller.sh
```

This script:
- Reads the port from `config.py`
- Kills any processes using that port
- Waits briefly for cleanup
- Starts the controller

### Method 2: Systemd Service

The systemd service automatically cleans ports on restart:

```bash
sudo systemctl restart mastrctrl-pi.service
```

The service file includes:
```ini
ExecStartPre=/bin/bash -c 'fuser -k 8765/tcp 2>/dev/null || true'
ExecStartPre=/bin/sleep 0.5
```

### Method 3: Socket Options in Code

The WebSocket server now uses `SO_REUSEADDR` and `SO_REUSEPORT` socket options, which allow immediate port reuse even during TCP TIME_WAIT state.

## Manual Port Cleanup

If you need to manually clean up the port:

### Using fuser (preferred):
```bash
sudo fuser -k 8765/tcp
```

### Using lsof:
```bash
sudo kill -9 $(lsof -t -i:8765)
```

### Using netstat:
```bash
# Find the process
sudo netstat -tulpn | grep 8765

# Kill it by PID
sudo kill -9 <PID>
```

## Deployment Script

When deploying with `deploy-to-pi.ps1`, the script automatically:
1. Stops any running systemd services
2. Cleans up port 8765
3. Extracts new files
4. Restarts services (if enabled)

```powershell
cd package\scripts
.\deploy-to-pi.ps1 -PiAddress 192.168.1.195 -Deploy
```

## Troubleshooting

### Port still in use after cleanup?

Wait 1-2 seconds after killing the process:
```bash
sudo fuser -k 8765/tcp
sleep 2
python3 main.py
```

### Permission denied?

Port cleanup requires sudo:
```bash
sudo bash start_controller.sh
```

Or add your user to sudoers for fuser without password:
```bash
echo "$USER ALL=(ALL) NOPASSWD: /bin/fuser" | sudo tee /etc/sudoers.d/fuser
```

### Different port number?

The cleanup script reads from `config.py`. If you change `WEBSOCKET_PORT`, the script will automatically use the new port.

## Technical Details

### Socket Options

The WebSocket server uses:
- `SO_REUSEADDR`: Allows binding to a port in TIME_WAIT state
- `SO_REUSEPORT`: Allows multiple sockets to bind to same port (Linux 3.9+)

These options are set in `network/websocket_server.py`:

```python
server.sockets[0].setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.sockets[0].setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
```

### TCP TIME_WAIT

When a TCP connection closes, the socket enters TIME_WAIT state for ~60 seconds. The socket options allow rebinding immediately, but forcefully killing processes with `fuser` is still the most reliable method for cleanup.

