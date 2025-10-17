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
    
    # Check if arduino-cli is available
    $arduinoCli = Get-Command arduino-cli -ErrorAction SilentlyContinue
    
    if (-not $arduinoCli) {
        Write-Host "  Warning: arduino-cli not found. Firmware must be built manually." -ForegroundColor Yellow
        Write-Host "  Place firmware-v${Version}.bin in $ReleaseDir manually" -ForegroundColor Yellow
        return $true
    }
    
    Push-Location "$PSScriptRoot/../esp32/MasterController"
    
    Write-Host "  Compiling firmware..."
    arduino-cli compile --fqbn esp32:esp32:esp32s3 MasterController.ino --output-dir ../../$ReleaseDir
    
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Host "Error: Firmware build failed" -ForegroundColor Red
        return $false
    }
    
    # Rename firmware file
    Move-Item "$ReleaseDir/MasterController.ino.bin" "$ReleaseDir/firmware-v${Version}.bin" -Force
    
    Pop-Location
    Write-Host "  Firmware build complete" -ForegroundColor Green
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
    
    # Small delay to ensure file handles are released
    Start-Sleep -Milliseconds 500
    
    try {
        Compress-Archive -Path $files -DestinationPath $uiZip -Force -ErrorAction Stop
    } catch {
        Write-Host "  Warning: Compression error, retrying..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        Compress-Archive -Path $files -DestinationPath $uiZip -Force
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

