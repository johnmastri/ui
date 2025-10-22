param(
    [Parameter(Mandatory=$true)]
    [string]$PiAddress,
    
    [Parameter(Mandatory=$false)]
    [string]$PiUser = "mastrctrl",
    
    [Parameter(Mandatory=$false)]
    [switch]$Deploy
)

$ErrorActionPreference = "Stop"

Write-Host "=" * 60
Write-Host "Master Controller - Raspberry Pi Deployment Script"
Write-Host "=" * 60
Write-Host ""

Write-Host "[1/8] Checking Pi connectivity..."
try {
    $ping = Test-Connection -ComputerName $PiAddress -Count 2 -Quiet
    if ($ping) {
        Write-Host "  OK Pi is reachable at $PiAddress" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Cannot reach Pi at $PiAddress" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERROR: Cannot ping Pi: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[2/8] Creating deployment package..."
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "mastrctrl-pi-$timestamp.zip"
$scriptDir = $PSScriptRoot
$sourcePath = Join-Path (Split-Path $scriptDir -Parent) "python\pi"
$tempZip = Join-Path $env:TEMP $packageName
$tempFlatDir = Join-Path $env:TEMP "mastrctrl-pi-flat"

Write-Host "  Source path: $sourcePath" -ForegroundColor Gray

if (-not (Test-Path $sourcePath)) {
    Write-Host "  ERROR: Source path does not exist: $sourcePath" -ForegroundColor Red
    exit 1
}

if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force
}

if (Test-Path $tempFlatDir) {
    Remove-Item $tempFlatDir -Recurse -Force
}

try {
    New-Item -ItemType Directory -Path $tempFlatDir -Force | Out-Null
    
    Get-ChildItem -Path $sourcePath -Recurse -File | ForEach-Object {
        Copy-Item $_.FullName -Destination $tempFlatDir -Force
    }
    
    Push-Location $tempFlatDir
    Compress-Archive -Path * -DestinationPath $tempZip -Force
    Pop-Location
    
    Remove-Item $tempFlatDir -Recurse -Force
    
    $zipSize = (Get-Item $tempZip).Length / 1KB
    Write-Host "  OK Package created: $packageName ($([math]::Round($zipSize, 1)) KB) [flattened structure]" -ForegroundColor Green
} catch {
    if ((Get-Location).Path -ne $PWD.Path) { 
        Pop-Location 
    }
    if (Test-Path $tempFlatDir) {
        Remove-Item $tempFlatDir -Recurse -Force
    }
    Write-Host "  ERROR: Failed to create package: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/8] Copying package to Pi..."
try {
    scp $tempZip "${PiUser}@${PiAddress}:~/"
    Write-Host "  OK Package copied to Pi" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to copy package: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/8] Extracting files on Pi..."
$extractCmd = "mkdir -p ~/mastrctrl/package/python/pi && cd ~/mastrctrl/package/python/pi && unzip -o ~/$packageName && rm ~/$packageName && find . -type f -name '*.sh' -exec chmod +x {} \; && find . -type f -name '*.py' -exec chmod +x {} \;"

try {
    ssh "${PiUser}@${PiAddress}" $extractCmd
    Write-Host "  OK Files extracted" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to extract files: $_" -ForegroundColor Red
    exit 1
}

if ($Deploy) {
    Write-Host ""
    Write-Host "[5/8] Installing dependencies..."
    try {
        ssh "${PiUser}@${PiAddress}" "cd ~/mastrctrl/package/python/pi && bash setup/install_dependencies.sh"
        Write-Host "  OK Dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Some dependencies may have failed" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "[6/8] Configuring USB gadget mode (plug-and-play with DHCP)..."
    $configureUSB = Read-Host "Configure USB gadget mode? This requires sudo and reboot (y/n)"
    if ($configureUSB -eq 'y') {
        try {
            Write-Host "  Installing modern USB gadget with automatic DHCP..." -ForegroundColor Cyan
            ssh "${PiUser}@${PiAddress}" "cd ~/mastrctrl/package/python/pi/setup && echo 'n' | sudo bash configure_usb_gadget_modern.sh"
            Write-Host "  OK USB gadget configured with DHCP (reboot required)" -ForegroundColor Green
            Write-Host "  After reboot, Windows will auto-configure via DHCP - no manual setup needed!" -ForegroundColor Green
        } catch {
            Write-Host "  WARNING: USB gadget setup may have failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  SKIPPED USB gadget configuration" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "[7/8] Installing systemd services..."
    $installService = Read-Host "Install systemd service for auto-start? (y/n)"
    if ($installService -eq 'y') {
        try {
            $serviceCmd = @"
cd ~/mastrctrl/package/python/pi && 
if [ -f setup/systemd/mastrctrl-pi.service ]; then 
    sudo cp setup/systemd/mastrctrl-pi.service /etc/systemd/system/ && 
    sudo systemctl daemon-reload && 
    sudo systemctl enable mastrctrl-pi.service; 
else 
    echo 'Service file not found'; 
    exit 1; 
fi
"@
            ssh "${PiUser}@${PiAddress}" $serviceCmd
            Write-Host "  OK Controller service installed and enabled" -ForegroundColor Green
            
            if ($configureUSB -eq 'y') {
                Write-Host "  USB gadget service also enabled (starts on boot)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  WARNING: Service installation may have failed" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  SKIPPED Service installation" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "[8/8] Starting controller..."
    $startNow = Read-Host "Start controller now? (y/n)"
    if ($startNow -eq 'y') {
        if ($installService -eq 'y') {
            ssh "${PiUser}@${PiAddress}" "sudo systemctl start mastrctrl-pi.service"
            Write-Host "  OK Service started" -ForegroundColor Green
        } else {
            Write-Host "  Starting manually (Ctrl+C to stop)..." -ForegroundColor Yellow
            ssh "${PiUser}@${PiAddress}" "cd ~/mastrctrl/package/python/pi && python3 main.py"
        }
    }
} else {
    Write-Host ""
    Write-Host "[5-8] Skipped (use -Deploy flag for automatic setup)"
}

Write-Host ""
Write-Host "=" * 60
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "=" * 60
Write-Host ""
Write-Host "Files installed to: ~/mastrctrl/package/python/pi"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Connect Pi USB-C to computer"
Write-Host "  2. Windows will auto-detect USB Ethernet device"
Write-Host "  3. Windows will auto-configure IP via DHCP (plug-and-play!)"
Write-Host "  4. Pi accessible at: 192.168.4.1"
Write-Host "  5. Connect to: ws://192.168.4.1:8765"
Write-Host ""
Write-Host "Manual commands:"
Write-Host "  ssh ${PiUser}@${PiAddress}"
Write-Host "  cd ~/mastrctrl/package/python/pi"
Write-Host "  python3 tests/test_leds.py     # Test LEDs"
Write-Host "  python3 main.py                # Run controller"
Write-Host "  sudo systemctl status mastrctrl-pi.service  # Check status"
Write-Host ""

if ($Deploy -and $configureUSB -eq 'y') {
    Write-Host "IMPORTANT: USB gadget mode requires a REBOOT!" -ForegroundColor Yellow
    $rebootNow = Read-Host "Reboot Pi now? (y/n)"
    if ($rebootNow -eq 'y') {
        ssh "${PiUser}@${PiAddress}" "sudo reboot"
        Write-Host "Pi is rebooting..." -ForegroundColor Green
    }
}

Remove-Item $tempZip -Force
