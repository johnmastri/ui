# MastrCtrl Release Creation Script
# Creates GitHub release with all components

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [string]$GitHubRepo = "johnmastri/ui",
    [string]$ReleaseDir = "./release",
    [switch]$SkipBuild = $false,
    [switch]$DryRun = $false
)

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "MastrCtrl Release Creation Script" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

# Validate version format
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-Host "Error: Invalid version format. Use X.Y.Z (e.g., 1.2.3)" -ForegroundColor Red
    exit 1
}

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Version: $Version"
Write-Host "  GitHub Repo: $GitHubRepo"
Write-Host "  Release Directory: $ReleaseDir"
Write-Host "  Skip Build: $SkipBuild"
Write-Host "  Dry Run: $DryRun"
Write-Host ""

# Convert to absolute path if relative
if (-not [System.IO.Path]::IsPathRooted($ReleaseDir)) {
    $ReleaseDir = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $ReleaseDir))
}

# Create release directory
if (-not (Test-Path $ReleaseDir)) {
    New-Item -ItemType Directory -Path $ReleaseDir | Out-Null
}

Write-Host "Release directory: $ReleaseDir" -ForegroundColor Cyan
Write-Host ""

# Update version.json
function Update-Version {
    Write-Host "Updating version.json..." -ForegroundColor Yellow
    
    $versionFile = "../version.json"
    $versionData = @{
        ui = $Version
        server = $Version
        firmware = $Version
        build_date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    
    $versionData | ConvertTo-Json | Set-Content $versionFile
    Write-Host "  Version updated to $Version" -ForegroundColor Green
}

# Build UI
function Build-UI {
    if ($SkipBuild) {
        Write-Host "Skipping UI build..." -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Building UI..." -ForegroundColor Yellow
    Push-Location "$PSScriptRoot/../ui"
    
    Write-Host "  Installing dependencies..."
    npm install
    
    Write-Host "  Running build..."
    npm run build
    
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Host "Error: UI build failed" -ForegroundColor Red
        return $false
    }
    
    Pop-Location
    Write-Host "  UI build complete" -ForegroundColor Green
    return $true
}

# Build firmware
function Build-Firmware {
    if ($SkipBuild) {
        Write-Host "Skipping firmware build..." -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Building ESP32 firmware..." -ForegroundColor Yellow
    
    $arduinoCli = Get-Command arduino-cli -ErrorAction SilentlyContinue
    
    if (-not $arduinoCli) {
        Write-Host "  Warning: arduino-cli not found." -ForegroundColor Yellow
        Write-Host "  Install with: winget install ArduinoSA.CLI" -ForegroundColor Yellow
        Write-Host "  Then configure with:" -ForegroundColor Yellow
        Write-Host "    arduino-cli config init" -ForegroundColor Yellow
        Write-Host "    arduino-cli config add board_manager.additional_urls https://espressif.github.io/arduino-esp32/package_esp32_index.json" -ForegroundColor Yellow
        Write-Host "    arduino-cli core update-index" -ForegroundColor Yellow
        Write-Host "    arduino-cli core install esp32:esp32" -ForegroundColor Yellow
        Write-Host "  Place firmware-v${Version}.bin in $ReleaseDir manually" -ForegroundColor Yellow
        return $true
    }
    
    $esp32Core = arduino-cli core list 2>&1 | Select-String "esp32:esp32"
    if (-not $esp32Core) {
        Write-Host "  Warning: ESP32 core not installed." -ForegroundColor Yellow
        Write-Host "  Install with: arduino-cli core install esp32:esp32" -ForegroundColor Yellow
        Write-Host "  (Note: This is a large download ~1GB and may take several minutes)" -ForegroundColor Yellow
        Write-Host "  Place firmware-v${Version}.bin in $ReleaseDir manually" -ForegroundColor Yellow
        return $true
    }
    
    $sourcePath = "$PSScriptRoot/../esp32/MasterController"
    if (-not (Test-Path $sourcePath)) {
        Write-Host "  Error: Firmware source not found at $sourcePath" -ForegroundColor Red
        return $false
    }
    
    Push-Location $sourcePath
    
    Write-Host "  Compiling firmware for ESP32-S3..."
    $outputDir = Join-Path $ReleaseDir "build"
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    
    arduino-cli compile --fqbn esp32:esp32:esp32s3 MasterController.ino --output-dir $outputDir 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Host "  Error: Firmware compilation failed" -ForegroundColor Red
        Write-Host "  You may need to build manually in Arduino IDE or platformio" -ForegroundColor Yellow
        return $true
    }
    
    $binFile = Get-ChildItem $outputDir -Filter "*.bin" | Where-Object { $_.Name -like "*MasterController*" } | Select-Object -First 1
    if ($binFile) {
        Copy-Item $binFile.FullName "$ReleaseDir/firmware-v${Version}.bin" -Force
        Start-Sleep -Milliseconds 500
        Remove-Item $outputDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Firmware build complete: firmware-v${Version}.bin" -ForegroundColor Green
    } else {
        Write-Host "  Warning: Compiled .bin file not found" -ForegroundColor Yellow
    }
    
    Pop-Location
    return $true
}

# Package UI
function Package-UI {
    Write-Host "Packaging UI..." -ForegroundColor Yellow
    
    $uiZip = "$ReleaseDir/ui-v${Version}.zip"
    
    Push-Location "$PSScriptRoot/../ui"
    
    # Create zip with necessary files
    $files = @(
        "dist/*",
        "electron/*",
        "package.json",
        "vite.config.js",
        "index.html"
    )
    
    if (Test-Path $uiZip) {
        Remove-Item $uiZip -Force
    }
    
    Write-Host "  Creating archive..."
    
    # Longer delay to ensure file handles are released
    Start-Sleep -Seconds 2
    
    $maxRetries = 3
    $retryCount = 0
    $success = $false
    
    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            Compress-Archive -Path $files -DestinationPath $uiZip -Force -ErrorAction Stop
            $success = $true
        } catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Host "  Warning: Compression failed, retrying ($retryCount/$maxRetries)..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            } else {
                throw
            }
        }
    }
    
    Pop-Location
    
    if (Test-Path $uiZip) {
        $size = (Get-Item $uiZip).Length / 1MB
        Write-Host "  UI packaged: $uiZip ($([math]::Round($size, 2)) MB)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Error: Failed to create UI package" -ForegroundColor Red
        return $false
    }
}

# Package server
function Package-Server {
    Write-Host "Packaging server..." -ForegroundColor Yellow
    
    $serverZip = "$ReleaseDir/server-v${Version}.zip"
    
    Push-Location "$PSScriptRoot/../python"
    
    # Create zip with Python files
    $files = Get-ChildItem -File | Where-Object { $_.Extension -in @('.py', '.txt') }
    
    if ($files.Count -eq 0) {
        Write-Host "  Warning: No Python files found to package" -ForegroundColor Yellow
        Pop-Location
        return $false
    }
    
    if (Test-Path $serverZip) {
        Remove-Item $serverZip -Force
    }
    
    Write-Host "  Creating archive..."
    Compress-Archive -Path $files.FullName -DestinationPath $serverZip -Force
    
    Pop-Location
    
    if (Test-Path $serverZip) {
        $size = (Get-Item $serverZip).Length / 1KB
        Write-Host "  Server packaged: $serverZip ($([math]::Round($size, 2)) KB)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Error: Failed to create server package" -ForegroundColor Red
        return $false
    }
}

# Generate manifest
function Generate-Manifest {
    Write-Host "Generating manifest..." -ForegroundColor Yellow
    
    python "$PSScriptRoot/generate_manifest.py" $GitHubRepo $ReleaseDir
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Manifest generation failed" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Manifest generated" -ForegroundColor Green
    return $true
}

# Create git tag
function Create-GitTag {
    if ($DryRun) {
        Write-Host "[DRY RUN] Would create git tag: v$Version" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Creating git tag..." -ForegroundColor Yellow
    
    git tag -a "v$Version" -m "Release v$Version"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to create git tag" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Tag created: v$Version" -ForegroundColor Green
    return $true
}

# Push to GitHub
function Push-ToGitHub {
    if ($DryRun) {
        Write-Host "[DRY RUN] Would push to GitHub" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Pushing to GitHub..." -ForegroundColor Yellow
    
    git push origin "v$Version"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to push tag to GitHub" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Pushed to GitHub" -ForegroundColor Green
    return $true
}

# Main release flow
Update-Version

if (-not (Build-UI)) { exit 1 }
if (-not (Build-Firmware)) { exit 1 }
if (-not (Package-UI)) { exit 1 }
if (-not (Package-Server)) { exit 1 }
if (-not (Generate-Manifest)) { exit 1 }

# List release files
Write-Host ""
Write-Host "Release files:" -ForegroundColor Yellow
Get-ChildItem $ReleaseDir | ForEach-Object {
    $size = if ($_.Length -gt 1MB) {
        "$([math]::Round($_.Length / 1MB, 2)) MB"
    } else {
        "$([math]::Round($_.Length / 1KB, 2)) KB"
    }
    Write-Host "  $($_.Name) - $size"
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "Release Build Complete!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Review the release files in $ReleaseDir"
Write-Host "  2. Create GitHub release manually or using GitHub CLI:"
Write-Host "     gh release create v$Version $ReleaseDir/* --title 'v$Version' --notes 'Release notes here'"
Write-Host "  3. Or push tag to trigger GitHub Actions (if configured):"
Write-Host "     git push origin v$Version"
Write-Host ""

if (-not $DryRun) {
    $response = Read-Host "Create git tag and push to GitHub? (y/n)"
    if ($response -eq 'y') {
        Create-GitTag
        Push-ToGitHub
    }
}

