param(
    [Parameter(Mandatory=$true)]
    [string]$PiAddress,
    
    [Parameter(Mandatory=$false)]
    [string]$PiUser = "mastrctrl",
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallDeps
)

$ErrorActionPreference = "Stop"

Write-Host "=" * 60
Write-Host "Master Controller - UI Deployment to Pi"
Write-Host "=" * 60
Write-Host ""

Write-Host "[1/5] Checking Pi connectivity..."
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
Write-Host "[2/5] Creating UI deployment package..."
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "mastrctrl-ui-$timestamp.zip"
$scriptDir = $PSScriptRoot
$sourcePath = Join-Path (Split-Path $scriptDir -Parent) "ui"
$tempZip = Join-Path $env:TEMP $packageName

Write-Host "  Source path: $sourcePath" -ForegroundColor Gray

if (-not (Test-Path $sourcePath)) {
    Write-Host "  ERROR: Source path does not exist: $sourcePath" -ForegroundColor Red
    exit 1
}

if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force
}

try {
    $filesToInclude = @(
        "src",
        "public", 
        "electron",
        "package.json",
        "vite.config.js",
        "index.html"
    )
    
    $tempDir = Join-Path $env:TEMP "mastrctrl-ui-temp"
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    foreach ($item in $filesToInclude) {
        $itemPath = Join-Path $sourcePath $item
        if (Test-Path $itemPath) {
            Copy-Item $itemPath -Destination $tempDir -Recurse -Force
            Write-Host "    Included: $item" -ForegroundColor Gray
        } else {
            Write-Host "    WARNING: Not found: $item" -ForegroundColor Yellow
        }
    }
    
    Push-Location $tempDir
    Compress-Archive -Path * -DestinationPath $tempZip -Force
    Pop-Location
    
    Remove-Item $tempDir -Recurse -Force
    
    $zipSize = (Get-Item $tempZip).Length / 1KB
    Write-Host "  OK Package created: $packageName ($([math]::Round($zipSize, 1)) KB)" -ForegroundColor Green
} catch {
    if ((Get-Location).Path -ne $PWD.Path) { 
        Pop-Location 
    }
    Write-Host "  ERROR: Failed to create package: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/5] Copying package to Pi..."
try {
    scp $tempZip "${PiUser}@${PiAddress}:~/"
    Write-Host "  OK Package copied to Pi" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to copy package: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[4/5] Extracting files on Pi..."
$extractCmd = "mkdir -p ~/mastrctrl/ui && cd ~/mastrctrl/ui && unzip -o ~/$packageName && rm ~/$packageName"

try {
    ssh "${PiUser}@${PiAddress}" $extractCmd
    Write-Host "  OK Files extracted to ~/mastrctrl/ui" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Failed to extract files: $_" -ForegroundColor Red
    exit 1
}

if ($InstallDeps) {
    Write-Host ""
    Write-Host "[5/5] Installing Node dependencies and Electron..."
    try {
        Write-Host "  Installing npm packages..." -ForegroundColor Cyan
        ssh "${PiUser}@${PiAddress}" "cd ~/mastrctrl/ui && npm install"
        
        Write-Host "  Installing Electron globally..." -ForegroundColor Cyan
        ssh "${PiUser}@${PiAddress}" "sudo npm install -g electron"
        
        Write-Host "  OK Dependencies installed" -ForegroundColor Green
    } catch {
        Write-Host "  WARNING: Some dependencies may have failed" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[5/5] Skipped dependency installation (use -InstallDeps flag)"
}

Write-Host ""
Write-Host "=" * 60
Write-Host "UI Deployment Complete!" -ForegroundColor Green
Write-Host "=" * 60
Write-Host ""
Write-Host "Files installed to: ~/mastrctrl/ui"
Write-Host ""
Write-Host "To run the UI on the Pi (copy and paste):"
Write-Host ""
Write-Host "ssh ${PiUser}@${PiAddress}" -ForegroundColor Cyan
Write-Host ""
Write-Host "Then run this command:"
Write-Host ""
Write-Host "sudo X :0 -nolisten tcp & sleep 5 && cd ~/mastrctrl/ui && npm run dev & sleep 3 && DISPLAY=:0 electron ~/mastrctrl/ui/electron/kiosk_basic_fast.cjs" -ForegroundColor Green
Write-Host ""
Write-Host "Or use systemd service:"
Write-Host "  sudo systemctl start mastrctrl-ui.service"
Write-Host ""

Remove-Item $tempZip -Force

