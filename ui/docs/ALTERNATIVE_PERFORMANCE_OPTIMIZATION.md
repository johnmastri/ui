# Alternative Performance Optimization for Flutter-Pi
## When GPU Memory Configuration Is Not Available

### System Memory Optimization
```bash
# Disable unnecessary kernel modules
echo 'blacklist bluetooth' | sudo tee -a /etc/modprobe.d/blacklist-bluetooth.conf
echo 'blacklist wifi' | sudo tee -a /etc/modprobe.d/blacklist-wifi.conf  # If using ethernet

# Reduce kernel memory usage
echo 'vm.swappiness=1' | sudo tee -a /etc/sysctl.conf
echo 'vm.min_free_kbytes=8192' | sudo tee -a /etc/sysctl.conf

# Disable unused services
sudo systemctl disable bluetooth
sudo systemctl disable avahi-daemon
sudo systemctl disable cups
sudo systemctl disable triggerhappy
sudo systemctl disable hciuart
sudo systemctl disable dphys-swapfile
```

### Application-Level Optimization
```bash
# Flutter-Pi performance flags
export FLUTTER_ENGINE_SWITCHES="--disable-software-rasterizer,--enable-vulkan-validation,--disable-vsync"

# Memory-conscious flutter-pi execution
flutter-pi \
  --release \
  --no-vsync-waits \
  --disable-cursor \
  --flutter-assets-dir=build/flutter_assets
```

### Display Configuration Without GPU Memory
```bash
# Optimize display without GPU memory changes
sudo nano /boot/firmware/config.txt

# Add these instead of gpu_mem
dtoverlay=vc4-kms-v3d
disable_overscan=1
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=800 480 60 6 0 0 0
hdmi_drive=2
# Remove or comment out gpu_mem lines
```

### Flutter App Optimization
```dart
// In your Flutter app, optimize for low memory
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Disable animations if performance is poor
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Use simple visual effects
        useMaterial3: false,
        visualDensity: VisualDensity.compact,
      ),
      home: MainScreen(),
    );
  }
}

// Optimize custom painting for knobs
class KnobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Use simple drawing operations
    // Avoid complex gradients and shadows
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### Check Your Hardware Model
```bash
# Check if you're on Pi 5 (where gpu_mem is ignored)
cat /proc/device-tree/model

# Check current memory allocation
vcgencmd get_mem arm && vcgencmd get_mem gpu

# Monitor actual memory usage
sudo dmesg | grep Memory
free -h
```

### Alternative Deployment Strategies

#### Option 1: Use Docker with Memory Limits
```dockerfile
FROM ubuntu:22.04

# Install flutter-pi dependencies
RUN apt-get update && apt-get install -y \
    libdrm2 libgbm1 libegl1 libgles2 \
    && rm -rf /var/lib/apt/lists/*

# Set memory constraints
ENV FLUTTER_ENGINE_SWITCHES="--disable-software-rasterizer"
EXPOSE 8080

CMD ["flutter-pi", "--release", "/app/build/flutter_assets"]
```

#### Option 2: Use Lightweight Linux Distribution
Consider switching to:
- **DietPi**: Minimal Raspberry Pi OS with better memory management
- **Alpine Linux**: Ultra-lightweight for embedded applications
- **Ubuntu Core**: Snap-based with controlled memory usage

### Debug Performance Issues
```bash
# Monitor performance in real-time
htop
iotop -o
vmstat 1

# Check GPU usage (if available)
sudo /opt/vc/bin/vcgencmd measure_temp
sudo /opt/vc/bin/vcgencmd get_throttled

# Monitor flutter-pi specifically
journalctl -f -u your-flutter-service
```

### If All Else Fails: Hardware Alternatives
1. **Use Raspberry Pi 4 8GB**: More total memory available
2. **Add USB3 storage**: Reduce SD card bottlenecks
3. **Use external GPU**: Via USB3 if supported
4. **Switch to desktop mode**: Run Flutter for Linux instead of flutter-pi 