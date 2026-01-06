Write-Host "SSH Key Setup for Raspberry Pi" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This script will help you copy your SSH key to the Pi."
Write-Host "You will be prompted for the password: mastri"
Write-Host ""
Write-Host "Your public key:"
$publicKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
Write-Host $publicKey -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to continue (or Ctrl+C to cancel)..."
Read-Host

Write-Host ""
Write-Host "Connecting to Pi and setting up SSH key..."
Write-Host "When prompted, enter password: mastri"
Write-Host ""

$setupCommands = @"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
grep -q '$publicKey' ~/.ssh/authorized_keys 2>/dev/null || echo '$publicKey' >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo 'SSH key setup complete!'
"@

ssh -o StrictHostKeyChecking=no mastrctrl@192.168.1.195 $setupCommands

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Testing passwordless SSH..." -ForegroundColor Cyan
    $test = ssh -o ConnectTimeout=5 mastrctrl@192.168.1.195 "echo 'Passwordless SSH works!'" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS! SSH key authentication is now set up." -ForegroundColor Green
        Write-Host "You can now use deploy scripts without entering passwords." -ForegroundColor Green
    } else {
        Write-Host "Key was copied, but passwordless test failed." -ForegroundColor Yellow
        Write-Host "You may need to try connecting once more manually." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Setup failed. Please try manual setup:" -ForegroundColor Red
    Write-Host "1. SSH to Pi: ssh mastrctrl@192.168.1.195"
    Write-Host "2. Run: mkdir -p ~/.ssh && chmod 700 ~/.ssh"
    Write-Host "3. Add this key to ~/.ssh/authorized_keys:"
    Write-Host $publicKey -ForegroundColor Yellow
    Write-Host "4. Run: chmod 600 ~/.ssh/authorized_keys"
}

