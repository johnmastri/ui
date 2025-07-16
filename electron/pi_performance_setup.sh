#!/bin/bash

# Pi Performance Optimization Script
# Run this on your Pi in the mastrctrl/flutter/web directory

export DISPLAY=:0

echo "Optimizing Pi for Electron performance..."

# Kill existing processes
echo "Stopping existing browsers..."
pkill -f electron
pkill -f chromium
sleep 2

# Performance optimizations
echo "Setting CPU to performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

echo "Clearing memory caches..."
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Clean temp files
echo "Cleaning temporary files..."
rm -rf /tmp/.org.chromium.Chromium.*

# Network optimizations (one-time setup)
echo "Applying network optimizations..."
if ! grep -q "net.core.rmem_max = 16777216" /etc/sysctl.conf; then
    echo 'net.core.rmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
    echo 'net.core.wmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
fi

# Create GPU-disabled kiosk script to fix GBM errors
echo "Creating kiosk_no_gpu.js..."
cat > kiosk_no_gpu.js << 'EOF'
const { app, BrowserWindow } = require("electron")

// Disable hardware acceleration to fix GBM errors on Pi
app.disableHardwareAcceleration()

// Additional flags for Pi compatibility
app.commandLine.appendSwitch("--disable-gpu")
app.commandLine.appendSwitch("--disable-software-rasterizer")
app.commandLine.appendSwitch("--no-sandbox")

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: true,
    show: false,
    webPreferences: {
      nodeIntegration: false,
      offscreen: false
    }
  })
  
  win.loadURL("http://192.168.1.5:3000")
  
  win.once("ready-to-show", () => {
    win.show()
    win.focus()
  })
})

app.on("window-all-closed", () => {
  app.quit()
})
EOF

echo "Starting optimized Electron (no GPU)..."
nice -n -10 electron kiosk_no_gpu.js &
ELECTRON_PID=$!

echo "Electron started with PID: $ELECTRON_PID"
echo "Performance optimizations applied!" 