@echo off
setlocal enabledelayedexpansion

set PI_ADDRESS=192.168.1.195
set PI_USER=mastrctrl

echo ============================================
echo USB Gadget Diagnostic and Fix Tool
echo ============================================
echo.

echo [1] Copying diagnostic script to Pi...
scp package\python\pi\setup\full_diagnostic.sh %PI_USER%@%PI_ADDRESS%:~/ 2>nul
if errorlevel 1 (
    echo ERROR: Could not copy script to Pi
    echo Make sure:
    echo   1. Pi is connected to network
    echo   2. IP address is correct: %PI_ADDRESS%
    echo   3. SSH is working
    pause
    exit /b 1
)
echo    Done!
echo.

echo [2] Running full diagnostic on Pi...
echo ============================================
ssh %PI_USER%@%PI_ADDRESS% "chmod +x ~/full_diagnostic.sh && bash ~/full_diagnostic.sh"
echo ============================================
echo.

echo [3] Do you want to apply USB gadget configuration fix? (y/n)
set /p APPLY_FIX="> "

if /i "%APPLY_FIX%"=="y" (
    echo.
    echo Applying USB gadget configuration...
    scp package\python\pi\setup\fix_usb_gadget.sh %PI_USER%@%PI_ADDRESS%:~/
    ssh %PI_USER%@%PI_ADDRESS% "chmod +x ~/fix_usb_gadget.sh && echo n | sudo bash ~/fix_usb_gadget.sh"
    
    echo.
    echo Configuration applied!
    echo.
    echo [4] Reboot Pi now? (y/n)
    set /p DO_REBOOT="> "
    
    if /i "!DO_REBOOT!"=="y" (
        echo Rebooting Pi...
        ssh %PI_USER%@%PI_ADDRESS% "sudo reboot"
        echo.
        echo ============================================
        echo Pi is rebooting...
        echo ============================================
        echo.
        echo Wait 30 seconds, then:
        echo   1. Unplug USB-C cable from computer
        echo   2. Plug it back in
        echo   3. Open Device Manager
        echo   4. Look for "USB Ethernet/RNDIS Gadget" under Network adapters
        echo   5. Run: ping 192.168.4.1
        echo.
        pause
    )
)

echo.
echo ============================================
echo Diagnostic Complete
echo ============================================
pause

