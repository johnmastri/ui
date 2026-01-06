param(
    [Parameter(Mandatory=$true)]
    [string]$PiAddress,
    
    [Parameter(Mandatory=$false)]
    [string]$PiUser = "mastrctrl",
    
    [Parameter(Mandatory=$false)]
    [switch]$Install
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Master Controller - Unified Deployment" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$packageDir = Split-Path -Parent (Split-Path -Parent $scriptDir)
$uiDir = Join-Path $packageDir "ui"
$pythonPiDir = Join-Path $packageDir "python\pi"

Write-Host "[1/6] Checking Pi connectivity..." -ForegroundColor Yellow
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

try {
    $sshTest = ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" "echo 'SSH OK'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK SSH connection verified" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: SSH test failed. You may need to enter password during transfer." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  WARNING: SSH test failed: $_" -ForegroundColor Yellow
}

if ($Install) {
    Write-Host ""
    Write-Host "[2/6] Building Vue UI..." -ForegroundColor Yellow
    Push-Location $uiDir
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Host "  Installing npm dependencies..." -ForegroundColor Cyan
            npm install
            if ($LASTEXITCODE -ne 0) {
                throw "npm install failed"
            }
        }
        
        Write-Host "  Building Vue app..." -ForegroundColor Cyan
        npm run build
        if ($LASTEXITCODE -ne 0) {
            throw "npm run build failed"
        }
        
        if (-not (Test-Path "dist")) {
            throw "Build failed - dist folder not created"
        }
        
        Write-Host "  Copying JUCE files to dist..." -ForegroundColor Cyan
        if (Test-Path "public\js\juce") {
            if (-not (Test-Path "dist\js\juce")) {
                New-Item -ItemType Directory -Path "dist\js\juce" -Force | Out-Null
            }
            Copy-Item "public\js\juce\*" "dist\js\juce\" -Recurse -Force
        }
        
        Write-Host "  OK Vue UI built successfully" -ForegroundColor Green
    } catch {
        Write-Host "  ERROR: Build failed: $_" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    Pop-Location
} else {
    Write-Host ""
    Write-Host "[2/6] Skipping UI build (use --Install to build before deploy)" -ForegroundColor Yellow
    if (-not (Test-Path (Join-Path $uiDir "dist"))) {
        Write-Host "  WARNING: dist folder not found. Run with --Install flag." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[3/6] Validating source directories..." -ForegroundColor Yellow
if (-not (Test-Path $pythonPiDir)) {
    Write-Host "  ERROR: Python server directory not found: $pythonPiDir" -ForegroundColor Red
    exit 1
}
Write-Host "  OK Python server directory found" -ForegroundColor Green

$uiDistPath = Join-Path $uiDir "dist"
if (Test-Path $uiDistPath) {
    Write-Host "  OK UI dist directory found" -ForegroundColor Green
} else {
    Write-Host "  WARNING: UI dist directory not found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[4/6] Creating deployment packages..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempDir = Join-Path $env:TEMP "mastrctrl-deploy-$timestamp"

if (Test-Path $tempDir) {
    Remove-Item $tempDir -Recurse -Force
}
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $uiPackageName = $null
    if (Test-Path $uiDistPath) {
        $uiPackageName = "mastrctrl-ui-$timestamp.zip"
        $uiZipPath = Join-Path $tempDir $uiPackageName
        Write-Host "  Packaging Vue UI..." -ForegroundColor Cyan
        
        Push-Location $uiDistPath
        try {
            if (Get-Command zip -ErrorAction SilentlyContinue) {
                zip -r $uiZipPath . -q
            } else {
                $tempUiDir = Join-Path $tempDir "ui-temp"
                if (Test-Path $tempUiDir) {
                    Remove-Item $tempUiDir -Recurse -Force
                }
                New-Item -ItemType Directory -Path $tempUiDir -Force | Out-Null
                Get-ChildItem -Path . | Copy-Item -Destination $tempUiDir -Recurse -Force
                Compress-Archive -Path "$tempUiDir\*" -DestinationPath $uiZipPath -Force
                Remove-Item $tempUiDir -Recurse -Force
            }
        } finally {
            Pop-Location
        }
        
        $uiSize = [math]::Round((Get-Item $uiZipPath).Length / 1KB, 1)
        Write-Host "    OK UI package: $uiPackageName ($uiSize KB)" -ForegroundColor Green
    } else {
        Write-Host "  Skipping UI package (dist folder not found)" -ForegroundColor Yellow
    }
    
    $pythonPackageName = "mastrctrl-python-$timestamp.zip"
    $pythonZipPath = Join-Path $tempDir $pythonPackageName
    Write-Host "  Packaging Python server..." -ForegroundColor Cyan
    
    Push-Location $pythonPiDir
    
    $excludeItems = @("*.zip", "__pycache__", "*.pyc", ".pytest_cache", "mastrctrl-updates")
    $itemsToZip = Get-ChildItem -Path . | Where-Object {
        $shouldExclude = $false
        foreach ($exclude in $excludeItems) {
            if ($_.Name -like $exclude -or $_.Name -eq $exclude) {
                $shouldExclude = $true
                break
            }
        }
        -not $shouldExclude
    }
    
    $tempPythonDir = Join-Path $tempDir "python-pi"
    New-Item -ItemType Directory -Path $tempPythonDir -Force | Out-Null
    
    foreach ($item in $itemsToZip) {
        Copy-Item $item.FullName -Destination (Join-Path $tempPythonDir $item.Name) -Recurse -Force
    }
    
    Compress-Archive -Path "$tempPythonDir\*" -DestinationPath $pythonZipPath -Force
    Remove-Item $tempPythonDir -Recurse -Force
    Pop-Location
    
    $pythonSize = [math]::Round((Get-Item $pythonZipPath).Length / 1KB, 1)
    Write-Host "    OK Python package: $pythonPackageName ($pythonSize KB)" -ForegroundColor Green
    
} catch {
    if ((Get-Location).Path -ne $PWD.Path) { 
        Pop-Location 
    }
    Write-Host "  ERROR: Failed to create packages: $_" -ForegroundColor Red
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
Write-Host "[5/6] Transferring packages to Pi..." -ForegroundColor Yellow
try {
    if ($uiPackageName) {
        $uiZipPath = Join-Path $tempDir $uiPackageName
        Write-Host "  Copying UI package..." -ForegroundColor Cyan
        scp -o StrictHostKeyChecking=no "$uiZipPath" "${PiUser}@${PiAddress}:~/" 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to copy UI package"
        }
        Write-Host "    OK UI package transferred" -ForegroundColor Green
    }
    
    Write-Host "  Copying Python package..." -ForegroundColor Cyan
    scp -o StrictHostKeyChecking=no "$pythonZipPath" "${PiUser}@${PiAddress}:~/" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to copy Python package"
    }
    Write-Host "    OK Python package transferred" -ForegroundColor Green
    
} catch {
    Write-Host "  ERROR: Transfer failed: $_" -ForegroundColor Red
    Write-Host "  Make sure SSH key authentication is set up or you can enter password." -ForegroundColor Yellow
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
Write-Host "[6/6] Extracting files on Pi..." -ForegroundColor Yellow
$extractScript = "mkdir -p ~/mastrctrl/ui`n"
$extractScript += "mkdir -p ~/mastrctrl/package/python/pi`n`n"

if ($uiPackageName) {
    $extractScript += "if [ -f ~/$uiPackageName ]; then`n"
    $extractScript += "    echo '  Extracting UI package...'`n"
    $extractScript += "    cd ~/mastrctrl/ui`n"
    $extractScript += "    unzip -o ~/$uiPackageName 2>&1 | grep -v 'backslashes' || true`n"
    $extractScript += "    EXIT_CODE=`$?`n"
    $extractScript += "    rm ~/$uiPackageName`n"
    $extractScript += "    if [ `$EXIT_CODE -eq 0 ] || [ `$EXIT_CODE -eq 1 ]; then`n"
    $extractScript += "        echo '    OK UI files extracted'`n"
    $extractScript += "    else`n"
    $extractScript += "        echo '    ERROR: Extraction failed'`n"
    $extractScript += "        exit 1`n"
    $extractScript += "    fi`n"
    $extractScript += "fi`n`n"
}

$extractScript += "if [ -f ~/$pythonPackageName ]; then`n"
$extractScript += "    echo '  Extracting Python package...'`n"
$extractScript += "    cd ~/mastrctrl/package/python/pi`n"
$extractScript += "    unzip -o ~/$pythonPackageName 2>&1 | grep -v 'backslashes' || true`n"
$extractScript += "    EXIT_CODE=`$?`n"
$extractScript += "    rm ~/$pythonPackageName`n"
$extractScript += "    if [ `$EXIT_CODE -eq 0 ] || [ `$EXIT_CODE -eq 1 ]; then`n"
$extractScript += "        echo '  Fixing permissions...'`n"
$extractScript += "        find . -type f -name '*.sh' -exec chmod +x {} \;`n"
$extractScript += "        find . -type f -name '*.py' -exec chmod +x {} \;`n"
$extractScript += "        `n"
$extractScript += "        echo '  Fixing line endings...'`n"
$extractScript += "        find . -type f -name '*.sh' -exec sed -i 's/\r$//' {} \;`n"
$extractScript += "        `n"
$extractScript += "        echo '    OK Python files extracted'`n"
$extractScript += "    else`n"
$extractScript += "        echo '    ERROR: Extraction failed'`n"
$extractScript += "        exit 1`n"
$extractScript += "    fi`n"
$extractScript += "fi`n"

try {
    ssh -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" $extractScript 2>&1 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Extraction failed"
    }
    
    Write-Host "  OK Files extracted successfully" -ForegroundColor Green
    
} catch {
    Write-Host "  ERROR: Extraction failed: $_" -ForegroundColor Red
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

if ($Install) {
    Write-Host ""
    Write-Host "[7/7] Running setup on Pi..." -ForegroundColor Yellow
    
    $setupScript = "cd ~/mastrctrl/package/python/pi`n`n"
    $setupScript += "echo '  Installing dependencies...'`n"
    $setupScript += "if [ -f setup/install_dependencies.sh ]; then`n"
    $setupScript += "    bash setup/install_dependencies.sh`n"
    $setupScript += "else`n"
    $setupScript += "    echo '    WARNING: install_dependencies.sh not found'`n"
    $setupScript += "fi`n`n"
    $setupScript += "echo '  Checking USB gadget configuration...'`n"
    $setupScript += "if ip addr show usb0 2>/dev/null | grep -q '192.168.4.1'; then`n"
    $setupScript += "    echo '    OK USB gadget already configured'`n"
    $setupScript += "elif [ -f setup/configure_usb_gadget_modern.sh ]; then`n"
    $setupScript += "    echo '    Configuring USB gadget (requires reboot)...'`n"
    $setupScript += "    echo 'n' | sudo bash setup/configure_usb_gadget_modern.sh`n"
    $setupScript += "    echo '    WARNING: Reboot required for USB gadget to work'`n"
    $setupScript += "else`n"
    $setupScript += "    echo '    WARNING: USB gadget setup script not found'`n"
    $setupScript += "fi`n`n"
    $setupScript += "echo '  Installing systemd service...'`n"
    $setupScript += "if [ -f setup/systemd/mastrctrl-pi.service ]; then`n"
    $setupScript += "    sudo cp setup/systemd/mastrctrl-pi.service /etc/systemd/system/`n"
    $setupScript += "    sudo systemctl daemon-reload`n"
    $setupScript += "    sudo systemctl enable mastrctrl-pi.service`n"
    $setupScript += "    echo '    OK Service installed and enabled'`n"
    $setupScript += "else`n"
    $setupScript += "    echo '    WARNING: mastrctrl-pi.service not found'`n"
    $setupScript += "fi`n`n"
    $setupScript += "if [ -f setup/systemd/usb-gadget.service ]; then`n"
    $setupScript += "    sudo cp setup/systemd/usb-gadget.service /etc/systemd/system/`n"
    $setupScript += "    sudo systemctl daemon-reload`n"
    $setupScript += "    sudo systemctl enable usb-gadget.service`n"
    $setupScript += "    echo '    OK USB gadget service installed and enabled'`n"
    $setupScript += "fi`n`n"
    $setupScript += "echo '  OK Setup complete'`n"
    
    try {
        ssh -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" $setupScript 2>&1 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  WARNING: Some setup steps may have failed" -ForegroundColor Yellow
        } else {
            Write-Host "  OK Setup completed successfully" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "  WARNING: Setup encountered errors: $_" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files deployed to:" -ForegroundColor Yellow
if ($uiPackageName) {
    Write-Host "  UI: ~/mastrctrl/ui/" -ForegroundColor White
}
Write-Host "  Python: ~/mastrctrl/package/python/pi/" -ForegroundColor White
Write-Host ""

if ($Install) {
    Write-Host "To start the controller:" -ForegroundColor Yellow
    Write-Host "  ssh ${PiUser}@${PiAddress}" -ForegroundColor Cyan
    Write-Host "  cd ~/mastrctrl/package/python/pi" -ForegroundColor Cyan
    Write-Host "  python3 main.py" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Or use systemd service:" -ForegroundColor Yellow
    Write-Host "  ssh ${PiUser}@${PiAddress} sudo systemctl start mastrctrl-pi.service" -ForegroundColor Cyan
} else {
    Write-Host "Run with --Install flag to install dependencies and configure services." -ForegroundColor Yellow
}

Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue

