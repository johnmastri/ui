# Deploy Flutter Web MIDI Controller to Raspberry Pi
# Run this script from the hardware_gui directory

param(
    [string]$PiIP = "192.168.1.195",
    [string]$PiUser = "pi",
    [string]$AppPort = "8080"
)

Write-Host "🌐 Deploying Flutter Web MIDI Controller to Pi..." -ForegroundColor Green

# Check if web build exists
if (-not (Test-Path "build\web")) {
    Write-Host "❌ Web build not found. Run 'flutter build web --release' first." -ForegroundColor Red
    exit 1
}

# Create web directory on Pi
Write-Host "📁 Creating web directory on Pi..." -ForegroundColor Yellow
& ssh "${PiUser}@${PiIP}" "mkdir -p /home/pi/midi_web"

# Transfer web files
Write-Host "📦 Transferring web files..." -ForegroundColor Yellow
& scp -r "build/web/*" "${PiUser}@${PiIP}:/home/pi/midi_web/"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Web files transferred successfully!" -ForegroundColor Green
    
    # Create startup script on Pi
    Write-Host "📝 Creating startup script on Pi..." -ForegroundColor Yellow
    $startupScript = @"
#!/bin/bash
# Flutter Web MIDI Controller Startup Script

echo "🎹 Starting Flutter Web MIDI Controller..."
echo "Port: ${AppPort}"
echo "Display: 800x480 (Chromium Kiosk)"

# Kill any existing instances
pkill -f "python3 -m http.server"
pkill -f "chromium"

# Start HTTP server in background
cd /home/pi/midi_web
echo "Starting web server on port ${AppPort}..."
python3 -m http.server ${AppPort} &
SERVER_PID=`$!

# Wait a moment for server to start
sleep 3

# Check if server started
if ps -p `$SERVER_PID > /dev/null; then
    echo "✅ Web server started successfully (PID: `$SERVER_PID)"
else
    echo "❌ Failed to start web server"
    exit 1
fi

# Start Chromium in kiosk mode
echo "Starting Chromium in kiosk mode..."
DISPLAY=:0 chromium-browser \
    --kiosk \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-features=TranslateUI \
    --disable-ipc-flooding-protection \
    --window-size=800,480 \
    --window-position=0,0 \
    --autoplay-policy=no-user-gesture-required \
    http://localhost:${AppPort} &

CHROMIUM_PID=`$!

echo "✅ Chromium started (PID: `$CHROMIUM_PID)"
echo "🎯 MIDI Controller should be visible on display"
echo ""
echo "To stop: pkill -f 'python3 -m http.server' && pkill -f 'chromium'"

# Save PIDs for later management
echo `$SERVER_PID > /tmp/midi_server.pid
echo `$CHROMIUM_PID > /tmp/midi_chromium.pid

echo "PIDs saved to /tmp/midi_*.pid"
"@

    # Create stop script
    $stopScript = @"
#!/bin/bash
# Stop Flutter Web MIDI Controller

echo "🛑 Stopping MIDI Controller..."

# Kill server and chromium
pkill -f "python3 -m http.server"
pkill -f "chromium"

# Clean up PID files
rm -f /tmp/midi_*.pid

echo "✅ MIDI Controller stopped"
"@

    # Transfer scripts
    $startupScript | & ssh "${PiUser}@${PiIP}" "cat > /home/pi/start_midi_web.sh && chmod +x /home/pi/start_midi_web.sh"
    $stopScript | & ssh "${PiUser}@${PiIP}" "cat > /home/pi/stop_midi_web.sh && chmod +x /home/pi/stop_midi_web.sh"
    
    Write-Host "🎯 Deployment complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To start on Pi:" -ForegroundColor Cyan
    Write-Host "  ssh ${PiUser}@${PiIP}" -ForegroundColor White
    Write-Host "  ./start_midi_web.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "To stop on Pi:" -ForegroundColor Cyan
    Write-Host "  ./stop_midi_web.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "Or run directly:" -ForegroundColor Cyan
    Write-Host "  ssh ${PiUser}@${PiIP} './start_midi_web.sh'" -ForegroundColor White
    Write-Host ""
    Write-Host "Access via browser: http://${PiIP}:${AppPort}" -ForegroundColor Yellow
    
} else {
    Write-Host "❌ Transfer failed! Check SSH connectivity to ${PiIP}" -ForegroundColor Red
    Write-Host "💡 Tip: Make sure you can run: ssh ${PiUser}@${PiIP}" -ForegroundColor Yellow
} 