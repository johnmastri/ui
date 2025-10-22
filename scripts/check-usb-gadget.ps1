param(
    [string]$PiAddress = "192.168.1.195",
    [string]$PiUser = "mastrctrl"
)

Write-Host "=============================================="
Write-Host "USB Gadget Configuration Checker & Fixer"
Write-Host "=============================================="
Write-Host ""

Write-Host "Step 1: Checking Windows USB detection..." -ForegroundColor Cyan
Write-Host ""

$usbAdapter = Get-NetAdapter | Where-Object {
    $_.InterfaceDescription -like "*USB*" -or 
    $_.InterfaceDescription -like "*RNDIS*" -or 
    $_.InterfaceDescription -like "*Gadget*" -or
    $_.InterfaceDescription -like "*ECM*"
}

if ($usbAdapter) {
    Write-Host "  FOUND USB Network Adapter:" -ForegroundColor Green
    $usbAdapter | ForEach-Object {
        Write-Host "    Name: $($_.Name)"
        Write-Host "    Description: $($_.InterfaceDescription)"
        Write-Host "    Status: $($_.Status)"
    }
} else {
    Write-Host "  NOT FOUND: No USB network adapter detected" -ForegroundColor Red
}

Write-Host ""
$ip192 = Get-NetIPAddress -ErrorAction SilentlyContinue | Where-Object {$_.IPAddress -like "192.168.4.*"}
if ($ip192) {
    Write-Host "  FOUND 192.168.4.x IP: $($ip192.IPAddress)" -ForegroundColor Green
} else {
    Write-Host "  NOT FOUND: No 192.168.4.x IP configured" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 2: Testing Pi connection..." -ForegroundColor Cyan
$pingTest = Test-Connection -ComputerName 192.168.4.1 -Count 2 -Quiet -ErrorAction SilentlyContinue
if ($pingTest) {
    Write-Host "  SUCCESS: Pi is reachable at 192.168.4.1" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Cannot reach 192.168.4.1" -ForegroundColor Red
}

Write-Host ""
Write-Host "Step 3: Connecting to Pi via network to check config..." -ForegroundColor Cyan
Write-Host ""

try {
    Write-Host "Copying diagnostic script to Pi..." -ForegroundColor Yellow
    $scriptPath = Join-Path $PSScriptRoot "..\python\pi\setup\fix_usb_gadget.sh"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "  ERROR: Cannot find fix_usb_gadget.sh" -ForegroundColor Red
        Write-Host "  Expected at: $scriptPath" -ForegroundColor Yellow
        exit 1
    }
    
    scp $scriptPath "${PiUser}@${PiAddress}:~/"
    Write-Host "  Script copied" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Running diagnostic on Pi..." -ForegroundColor Yellow
    Write-Host "=============================================="
    
    ssh "${PiUser}@${PiAddress}" "chmod +x ~/fix_usb_gadget.sh && bash ~/fix_usb_gadget.sh"
    
    Write-Host "=============================================="
    Write-Host ""
    Write-Host "To apply fixes, run on Pi:" -ForegroundColor Yellow
    Write-Host "  ssh ${PiUser}@${PiAddress}" -ForegroundColor White
    Write-Host "  sudo bash ~/fix_usb_gadget.sh" -ForegroundColor White
    Write-Host ""
    
    $applyFix = Read-Host "Apply fixes now? (y/n)"
    if ($applyFix -eq 'y') {
        Write-Host ""
        Write-Host "Applying USB gadget configuration..." -ForegroundColor Yellow
        ssh "${PiUser}@${PiAddress}" "echo 'n' | sudo bash ~/fix_usb_gadget.sh"
        
        Write-Host ""
        $rebootNow = Read-Host "Reboot Pi now? (y/n)"
        if ($rebootNow -eq 'y') {
            Write-Host "Rebooting Pi..." -ForegroundColor Green
            ssh "${PiUser}@${PiAddress}" "sudo reboot"
            Write-Host ""
            Write-Host "Wait 30 seconds, then:" -ForegroundColor Cyan
            Write-Host "  1. Unplug and replug USB-C cable" -ForegroundColor White
            Write-Host "  2. Check Device Manager for USB Ethernet adapter" -ForegroundColor White
            Write-Host "  3. Run: ping 192.168.4.1" -ForegroundColor White
        }
    }
    
} catch {
    Write-Host "  ERROR: Cannot connect to Pi at $PiAddress" -ForegroundColor Red
    Write-Host "  Make sure Pi is connected to network" -ForegroundColor Yellow
    Write-Host "  Check IP address and SSH access" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=============================================="

