#!/bin/bash

echo "Optimizing Pi system for Electron performance..."

# Kill existing processes
pkill -f electron
pkill -f chromium
sleep 1

# CPU Performance
echo "Setting CPU to performance mode..."
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Force max CPU frequency
echo 1500000 | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq

# Memory optimizations
echo "Optimizing memory..."
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Reduce swappiness for better responsiveness
echo 10 | sudo tee /proc/sys/vm/swappiness

# Network optimizations for faster Vue.js loading
echo "Optimizing network..."
echo 'net.core.rmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 16777216' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# GPU memory (increase if low)
GPU_MEM=$(vcgencmd get_mem gpu | cut -d= -f2 | cut -dM -f1)
echo "Current GPU memory: ${GPU_MEM}M"
if [ "$GPU_MEM" -lt "128" ]; then
    echo "Consider increasing GPU memory in /boot/firmware/config.txt"
    echo "Add: gpu_mem=128"
fi

# Disable unnecessary services that can cause lag
echo "Disabling lag-causing services..."
sudo systemctl stop bluetooth
sudo systemctl stop avahi-daemon

# Start Electron with optimized environment
echo "Starting optimized Electron..."
export DISPLAY=:0

# Start Electron without nice (avoid permission issues)
electron kiosk_basic_fast.js &
ELECTRON_PID=$!

echo "Electron started with PID: $ELECTRON_PID"
echo "System optimized for performance!"

# Monitor performance
echo "Performance stats:"
echo "CPU Freq: $(vcgencmd measure_clock arm)"
echo "Temperature: $(vcgencmd measure_temp)"
echo "GPU Memory: $(vcgencmd get_mem gpu)" 