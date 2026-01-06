param(
    [Parameter(Mandatory=$true)]
    [string]$PiAddress,
    
    [Parameter(Mandatory=$false)]
    [string]$PiUser = "mastrctrl"
)

$ErrorActionPreference = "Continue"

Write-Host "Testing SSH connection to ${PiUser}@${PiAddress}..."
Write-Host ""

Write-Host "[1/2] Testing network connectivity..."
$pingResult = Test-Connection -ComputerName $PiAddress -Count 2 -Quiet
if ($pingResult) {
    Write-Host "  OK Pi is reachable at $PiAddress" -ForegroundColor Green
} else {
    Write-Host "  ERROR: Cannot reach Pi at $PiAddress" -ForegroundColor Red
    Write-Host "  Please check:" -ForegroundColor Yellow
    Write-Host "    - Pi is powered on"
    Write-Host "    - Pi is on the same network"
    Write-Host "    - IP address is correct"
    exit 1
}

Write-Host ""
Write-Host "[2/2] Testing SSH connection..."
Write-Host "  Attempting to connect (you may be prompted for password)..."

try {
    $sshTest = ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "${PiUser}@${PiAddress}" "echo 'SSH connection successful!'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK SSH connection works!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Connection details:" -ForegroundColor Cyan
        Write-Host "  User: $PiUser"
        Write-Host "  Address: $PiAddress"
        Write-Host ""
        Write-Host "Next step: Run setup-ssh-key.ps1 to enable passwordless login"
    } else {
        Write-Host "  ERROR: SSH connection failed" -ForegroundColor Red
        Write-Host "  Error output: $sshTest" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible issues:" -ForegroundColor Yellow
        Write-Host "  - SSH service not running on Pi"
        Write-Host "  - Wrong username (trying: $PiUser)"
        Write-Host "  - Wrong password"
        Write-Host "  - Firewall blocking connection"
    }
} catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

