param(
    [Parameter(Mandatory=$false)]
    [string]$PiAddress = "192.168.1.195",
    
    [Parameter(Mandatory=$false)]
    [string]$PiUser = "mastrctrl",
    
    [Parameter(Mandatory=$false)]
    [string]$PiPassword = "mastri"
)

Write-Host "Ensuring SSH key is on Pi..." -ForegroundColor Cyan
Write-Host "Target: ${PiUser}@${PiAddress}"
Write-Host ""

$publicKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub" -ErrorAction Stop

Write-Host "Your public key:" -ForegroundColor Yellow
Write-Host $publicKey
Write-Host ""

Write-Host "[1/3] Checking if key exists on Pi..."
$checkResult = ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" "test -f ~/.ssh/authorized_keys && grep -q '${publicKey}' ~/.ssh/authorized_keys && echo 'KEY_EXISTS' || echo 'KEY_NOT_FOUND'" 2>&1

if ($checkResult -match "KEY_EXISTS") {
    Write-Host "  OK SSH key already exists on Pi" -ForegroundColor Green
} else {
    Write-Host "  Key not found, setting it up..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "[2/3] Creating .ssh directory and adding key..."
    Write-Host "  You will be prompted for password: $PiPassword"
    
    $setupCmd = @"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
if ! grep -q '$publicKey' ~/.ssh/authorized_keys 2>/dev/null; then
    echo '$publicKey' >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo 'KEY_ADDED'
else
    echo 'KEY_ALREADY_EXISTS'
fi
"@
    
    $result = ssh -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" $setupCmd 2>&1
    
    if ($result -match "KEY_ADDED") {
        Write-Host "  OK SSH key added to Pi" -ForegroundColor Green
    } elseif ($result -match "KEY_ALREADY_EXISTS") {
        Write-Host "  OK SSH key was already on Pi" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to add key" -ForegroundColor Red
        Write-Host "  Output: $result" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "[3/3] Testing passwordless SSH..."
$testResult = ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" "echo 'Passwordless SSH works!'" 2>&1

if ($LASTEXITCODE -eq 0 -and $testResult -match "Passwordless SSH works") {
    Write-Host "  OK Passwordless SSH authentication working!" -ForegroundColor Green
    Write-Host ""
    Write-Host "SSH key setup complete!" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Passwordless SSH test failed" -ForegroundColor Yellow
    Write-Host "  Output: $testResult" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Cyan
    Write-Host "  1. Verify key on Pi: ssh ${PiUser}@${PiAddress} 'cat ~/.ssh/authorized_keys'"
    Write-Host "  2. Check permissions: ssh ${PiUser}@${PiAddress} 'ls -la ~/.ssh'"
    Write-Host "  3. Permissions should be: .ssh=700, authorized_keys=600"
}

