# MastrCtrl Deployment Script
# Deploys UI, Python server, and ESP32 firmware to Raspberry Pi

param(
    [string]$ConfigFile = "../deploy-config.json",
    [switch]$DryRun = $false,
    [switch]$ServerOnly = $false,
    [switch]$UIOnly = $false,
    [switch]$NoRestart = $false,
    [switch]$Build = $true
)

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "MastrCtrl Deployment Script" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan

if (-not (Test-Path $ConfigFile)) {
    Write-Host "Error: Config file not found: $ConfigFile" -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigFile | ConvertFrom-Json

$piHost = $config.pi_host
$piUser = $config.pi_user
$serverPath = $config.server_path
$backupEnabled = $config.backup_enabled
$autoRestart = $config.auto_restart -and (-not $NoRestart)

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Pi Host: $piHost"
Write-Host "  Pi User: $piUser"
Write-Host "  Server Path: $serverPath"
Write-Host "  Backup Enabled: $backupEnabled"
Write-Host "  Auto Restart: $autoRestart"
Write-Host "  Dry Run: $DryRun"
Write-Host ""

$piConnection = "${piUser}@${piHost}"

function Test-SSHConnection {
    Write-Host "Testing SSH connection to Pi..." -ForegroundColor Yellow
    $result = ssh $piConnection "echo 'SSH OK'"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Cannot connect to Pi via SSH" -ForegroundColor Red
        return $false
    }
    Write-Host "  SSH connection OK" -ForegroundColor Green
    return $true
}

function Build-UI {
    Write-Host "Building Vue.js UI..." -ForegroundColor Yellow
    Push-Location ../ui
    
    if (-not (Test-Path "node_modules")) {
        Write-Host "  Installing dependencies..."
        npm install
    }
    
    Write-Host "  Running build..."
    npm run build
    
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        Write-Host "Error: Build failed" -ForegroundColor Red
        return $false
    }
    
    Pop-Location
    Write-Host "  Build complete" -ForegroundColor Green
    return $true
}

function Deploy-Server {
    Write-Host "Deploying Python server..." -ForegroundColor Yellow
    
    $pythonFiles = "../python/*"
    $destination = "${piConnection}:${serverPath}/python/"
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would copy: $pythonFiles -> $destination"
        return $true
    }
    
    Write-Host "  Creating directory on Pi..."
    ssh $piConnection "mkdir -p ${serverPath}/python"
    
    Write-Host "  Copying Python files..."
    scp -r $pythonFiles $destination
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to copy Python files" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Installing Python dependencies..."
    ssh $piConnection "cd ${serverPath}/python && pip3 install -r requirements.txt"
    
    Write-Host "  Server deployed successfully" -ForegroundColor Green
    return $true
}

function Deploy-UI {
    Write-Host "Deploying UI..." -ForegroundColor Yellow
    
    $uiFiles = "../ui/*"
    $destination = "${piConnection}:${serverPath}/ui/"
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would copy: $uiFiles -> $destination"
        return $true
    }
    
    Write-Host "  Creating directory on Pi..."
    ssh $piConnection "mkdir -p ${serverPath}/ui"
    
    Write-Host "  Copying UI files (excluding node_modules)..."
    $excludeArgs = "--exclude=node_modules --exclude=dist --exclude=.vite"
    $command = "scp -r $excludeArgs $uiFiles $destination"
    Invoke-Expression $command
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to copy UI files" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Installing UI dependencies on Pi..."
    ssh $piConnection "cd ${serverPath}/ui && npm install"
    
    Write-Host "  UI deployed successfully" -ForegroundColor Green
    return $true
}

function Deploy-ESP32Firmware {
    Write-Host "Copying ESP32 firmware..." -ForegroundColor Yellow
    
    $esp32Files = "../esp32/*"
    $destination = "${piConnection}:${serverPath}/esp32/"
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would copy: $esp32Files -> $destination"
        return $true
    }
    
    Write-Host "  Creating directory on Pi..."
    ssh $piConnection "mkdir -p ${serverPath}/esp32"
    
    Write-Host "  Copying ESP32 files..."
    scp -r $esp32Files $destination
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to copy ESP32 files" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  ESP32 firmware copied" -ForegroundColor Green
    return $true
}

function Restart-Services {
    if (-not $autoRestart) {
        Write-Host "Skipping service restart (auto-restart disabled)" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "Restarting services on Pi..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "  [DRY RUN] Would restart services"
        return $true
    }
    
    if (-not $UIOnly) {
        Write-Host "  Restarting server..."
        ssh $piConnection "sudo systemctl restart mastrctrl-server"
    }
    
    if (-not $ServerOnly) {
        Write-Host "  Restarting UI..."
        ssh $piConnection "sudo systemctl restart mastrctrl-ui"
    }
    
    Start-Sleep -Seconds 3
    
    Write-Host "  Checking service status..."
    $serverStatus = ssh $piConnection "systemctl is-active mastrctrl-server"
    $uiStatus = ssh $piConnection "systemctl is-active mastrctrl-ui"
    
    Write-Host "  Server status: $serverStatus" -ForegroundColor $(if ($serverStatus -eq "active") { "Green" } else { "Red" })
    Write-Host "  UI status: $uiStatus" -ForegroundColor $(if ($uiStatus -eq "active") { "Green" } else { "Red" })
    
    return $true
}

# Main deployment flow
if (-not (Test-SSHConnection)) {
    exit 1
}

if ($Build -and (-not $ServerOnly)) {
    if (-not (Build-UI)) {
        exit 1
    }
}

$success = $true

if (-not $UIOnly) {
    if (-not (Deploy-Server)) {
        $success = $false
    }
    
    if (-not (Deploy-ESP32Firmware)) {
        $success = $false
    }
}

if (-not $ServerOnly) {
    if (-not (Deploy-UI)) {
        $success = $false
    }
}

if ($success) {
    Restart-Services
    
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Green
    Write-Host "Deployment Complete!" -ForegroundColor Green
    Write-Host "=" * 60 -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Check logs: ssh $piConnection 'journalctl -u mastrctrl-server -f'"
    Write-Host "  2. Access UI: http://${piHost}:3000"
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Red
    Write-Host "Deployment Failed" -ForegroundColor Red
    Write-Host "=" * 60 -ForegroundColor Red
    exit 1
}

