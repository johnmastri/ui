# GitHub CLI Authentication Setup Helper

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "GitHub CLI Authentication Setup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Refresh PATH to pick up newly installed gh
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Check if gh is installed
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghInstalled) {
    Write-Host "GitHub CLI is not installed" -ForegroundColor Red
    Write-Host ""
    Write-Host "Installing GitHub CLI..." -ForegroundColor Yellow
    winget install --id GitHub.cli
    
    Write-Host ""
    Write-Host "GitHub CLI installed!" -ForegroundColor Green
    Write-Host "Please close and reopen PowerShell, then run this script again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 0
}

Write-Host "GitHub CLI: Installed" -ForegroundColor Green
$version = gh --version 2>&1 | Select-Object -First 1
Write-Host "Version: $version" -ForegroundColor Gray
Write-Host ""

# Check authentication status
Write-Host "Checking authentication status..." -ForegroundColor Yellow
$authResult = gh auth status 2>&1
$authStatus = $authResult | Out-String

if ($authStatus -match "Logged in to") {
    Write-Host "Already authenticated!" -ForegroundColor Green
    Write-Host ""
    gh auth status
    Write-Host ""
    Write-Host "You are ready to create releases!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step:" -ForegroundColor Yellow
    Write-Host "  .\release-with-gh.ps1 -Version 1.0.0" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# Not authenticated - guide user through login
Write-Host "Not authenticated yet" -ForegroundColor Yellow
Write-Host ""
Write-Host "I will guide you through the authentication process..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Steps:" -ForegroundColor Yellow
Write-Host "  1. Choose GitHub.com (press Enter)" -ForegroundColor Gray
Write-Host "  2. Choose HTTPS (press Enter)" -ForegroundColor Gray
Write-Host "  3. Authenticate Git: Yes (press Enter)" -ForegroundColor Gray
Write-Host "  4. Choose Login with a web browser (press Enter)" -ForegroundColor Gray
Write-Host "  5. Copy the one-time code" -ForegroundColor Gray
Write-Host "  6. Press Enter to open browser" -ForegroundColor Gray
Write-Host "  7. Paste code and authorize" -ForegroundColor Gray
Write-Host ""

$response = Read-Host "Ready to authenticate? (y/n)"
if ($response -ne 'y') {
    Write-Host "Authentication cancelled" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "Starting authentication..." -ForegroundColor Cyan
Write-Host ""

gh auth login

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "Authentication Successful!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    
    gh auth status
    
    Write-Host ""
    Write-Host "You are now ready to create releases!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Create your first release:" -ForegroundColor Gray
    Write-Host "     .\release-with-gh.ps1 -Version 0.0.1" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  2. View the full guide:" -ForegroundColor Gray
    Write-Host "     See ..\RELEASE_GUIDE.md" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Authentication failed" -ForegroundColor Red
    Write-Host "Please try again or check your internet connection" -ForegroundColor Yellow
    exit 1
}
