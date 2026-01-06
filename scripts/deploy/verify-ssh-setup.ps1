Write-Host "SSH Setup Verification" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan
Write-Host ""

$publicKey = Get-Content "$env:USERPROFILE\.ssh\id_ed25519.pub"
Write-Host "Your public key:" -ForegroundColor Yellow
Write-Host $publicKey
Write-Host ""

Write-Host "To verify SSH key is on the Pi, run this command:" -ForegroundColor Cyan
Write-Host "ssh mastrctrl@192.168.1.195 'cat ~/.ssh/authorized_keys'" -ForegroundColor Green
Write-Host ""
Write-Host "The output should include the key above."
Write-Host ""
Write-Host "If the key is NOT there, run this command (will prompt for password):" -ForegroundColor Yellow
Write-Host "ssh mastrctrl@192.168.1.195 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo \"$publicKey\" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'" -ForegroundColor Green
Write-Host ""
Write-Host "Common issues:" -ForegroundColor Cyan
Write-Host "1. Wrong permissions on ~/.ssh directory (should be 700)"
Write-Host "2. Wrong permissions on authorized_keys (should be 600)"
Write-Host "3. Key not properly added to authorized_keys"
Write-Host ""
Write-Host "To fix permissions on Pi, run:" -ForegroundColor Yellow
Write-Host "ssh mastrctrl@192.168.1.195 'chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys'" -ForegroundColor Green

