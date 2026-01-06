Write-Host "Setting up SSH key on Pi..." -ForegroundColor Cyan
Write-Host ""

$publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICy47fbbb0IzTNB3bhZCXn6fgLWQetU1vSyEUEPqfT4h mastrctrl-deploy"

Write-Host "Your public key:" -ForegroundColor Yellow
Write-Host $publicKey
Write-Host ""
Write-Host "Run this command (will prompt for password: mastri):" -ForegroundColor Green
Write-Host ""
Write-Host "ssh mastrctrl@192.168.1.195 `"mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$publicKey' > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && echo 'SSH key setup complete!'`"" -ForegroundColor White
Write-Host ""
Write-Host "After running, test with:" -ForegroundColor Cyan
Write-Host "ssh mastrctrl@192.168.1.195 'echo Test'" -ForegroundColor Green

