param(
    [Parameter(Mandatory=$true)]
    [string]$PiAddress,
    
    [Parameter(Mandatory=$false)]
    [string]$PiUser = "mastrctrl",
    
    [Parameter(Mandatory=$false)]
    [string]$PiPassword = "mastri"
)

$ErrorActionPreference = "Stop"

Write-Host "Setting up SSH key authentication..."
Write-Host "Target: ${PiUser}@${PiAddress}"
Write-Host ""

$publicKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub" -ErrorAction Stop

Write-Host "[1/3] Testing SSH connection..."
try {
    $testResult = ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" "echo 'Connection test successful'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK SSH connection works (key auth already set up)" -ForegroundColor Green
        exit 0
    }
} catch {
    Write-Host "  Connection test failed, proceeding with key setup..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/3] Copying public key to Pi..."
Write-Host "  You may be prompted for the password: $PiPassword"

$setupScript = @"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo '$publicKey' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo 'SSH key added successfully'
"@

try {
    $setupScript | ssh -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" "bash"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK Public key copied to Pi" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to copy key" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ERROR: Failed to copy key: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual setup instructions:" -ForegroundColor Yellow
    Write-Host "1. SSH to Pi: ssh ${PiUser}@${PiAddress}"
    Write-Host "2. Run these commands:"
    Write-Host "   mkdir -p ~/.ssh"
    Write-Host "   chmod 700 ~/.ssh"
    Write-Host "   echo '$publicKey' >> ~/.ssh/authorized_keys"
    Write-Host "   chmod 600 ~/.ssh/authorized_keys"
    exit 1
}

Write-Host ""
Write-Host "[3/3] Testing passwordless SSH..."
try {
    $testResult = ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" "echo 'Passwordless SSH works!'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK Passwordless SSH authentication working!" -ForegroundColor Green
        Write-Host ""
        Write-Host "SSH key authentication is now set up!" -ForegroundColor Green
        Write-Host "You can now run deploy scripts without entering passwords."
    } else {
        Write-Host "  WARNING: Passwordless SSH test failed" -ForegroundColor Yellow
        Write-Host "  You may still need to enter password for first connection"
    }
} catch {
    Write-Host "  WARNING: Could not verify passwordless SSH" -ForegroundColor Yellow
}

