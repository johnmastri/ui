# Deploy Flutter MIDI Controller to Raspberry Pi 4B
# Run this script from the hardware_gui directory

param(
    [string]$PiIP = "192.168.1.195",
    [string]$PiUser = "pi",
    [string]$AppName = "midi_controller"
)

Write-Host "🚀 Deploying Flutter MIDI Controller to Pi..." -ForegroundColor Green

# Check if flutter_assets exists
if (-not (Test-Path "build\flutter_assets")) {
    Write-Host "❌ Flutter assets not found. Run 'flutter build bundle --release' first." -ForegroundColor Red
    exit 1
}

# Create app directory on Pi
Write-Host "📁 Creating app directory on Pi..." -ForegroundColor Yellow
& ssh "${PiUser}@${PiIP}" "mkdir -p /home/pi/${AppName}"

# Transfer flutter assets
Write-Host "📦 Transferring Flutter assets..." -ForegroundColor Yellow
& scp -r "build/flutter_assets" "${PiUser}@${PiIP}:/home/pi/${AppName}/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Assets transferred successfully!" -ForegroundColor Green
    
    # Create run script on Pi
    Write-Host "📝 Creating run script on Pi..." -ForegroundColor Yellow
    $runScript = @"
#!/bin/bash
# MIDI Controller Flutter-Pi Runner
export FLUTTER_PI_RESOLUTION=800x480
export FLUTTER_PI_ORIENTATION=0

echo "🎹 Starting MIDI Controller..."
echo "Display: 800x480"
echo "3D Acceleration: \$(lsmod | grep vc4 && echo 'Enabled' || echo 'Disabled')"

# Run flutter-pi with optimizations for Pi 4B
flutter-pi \
  --release \
  --resolution=800x480 \
  --rotation=0 \
  /home/pi/${AppName}/flutter_assets
"@

    # Transfer run script
    $runScript | & ssh "${PiUser}@${PiIP}" "cat > /home/pi/${AppName}/run_midi_controller.sh && chmod +x /home/pi/${AppName}/run_midi_controller.sh"
    
    Write-Host "🎯 Deployment complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run on Pi:" -ForegroundColor Cyan
    Write-Host "  ssh ${PiUser}@${PiIP}" -ForegroundColor White
    Write-Host "  cd ${AppName}" -ForegroundColor White
    Write-Host "  ./run_midi_controller.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run directly:" -ForegroundColor Cyan
    Write-Host "  ssh ${PiUser}@${PiIP} 'cd ${AppName} && ./run_midi_controller.sh'" -ForegroundColor White
    
} else {
    Write-Host "❌ Transfer failed! Check SSH connectivity to ${PiIP}" -ForegroundColor Red
    Write-Host "💡 Tip: Make sure you can run: ssh ${PiUser}@${PiIP}" -ForegroundColor Yellow
} 