@echo off
REM Configure USB Gadget Mode on Raspberry Pi
REM Run this from Windows to remotely set up the Pi

setlocal

set PI_USER=mastrctrl
set PI_ADDRESS=192.168.1.195

if not "%1"=="" set PI_ADDRESS=%1

echo ============================================
echo USB Gadget Configuration for Raspberry Pi
echo ============================================
echo.
echo Pi Address: %PI_ADDRESS%
echo Pi User: %PI_USER%
echo.

echo [1/3] Testing Pi connectivity...
ping -n 1 %PI_ADDRESS% >nul 2>&1
if errorlevel 1 (
    echo   ERROR: Cannot reach Pi at %PI_ADDRESS%
    echo   Make sure Pi is on the network
    pause
    exit /b 1
)
echo   OK: Pi is reachable
echo.

echo [2/3] Checking if setup files exist on Pi...
ssh %PI_USER%@%PI_ADDRESS% "test -f ~/mastrctrl/package/python/pi/setup/configure_usb_gadget_modern.sh" 2>nul
if errorlevel 1 (
    echo   Files not found. Deploying first...
    echo.
    call "%~dp0deploy-to-pi.ps1" -PiAddress %PI_ADDRESS%
    if errorlevel 1 (
        echo   ERROR: Deployment failed
        pause
        exit /b 1
    )
    echo.
)

echo [3/4] Running USB gadget configuration on Pi...
echo   This will install DHCP and configure automatic driver installation
echo   Pi will need to reboot after configuration
echo.
ssh %PI_USER%@%PI_ADDRESS% "cd ~/mastrctrl/package/python/pi/setup && echo 'n' | sudo bash configure_usb_gadget_modern.sh"

if errorlevel 1 (
    echo.
    echo   WARNING: Configuration may have failed
    echo   Check the output above for errors
    pause
    exit /b 1
)

echo.
echo   OK: Configuration complete
echo.

echo [4/4] Reboot Pi?
set /p REBOOT="Reboot now to apply changes? (y/n): "

if /i "%REBOOT%"=="y" (
    echo.
    echo Rebooting Pi...
    ssh %PI_USER%@%PI_ADDRESS% "sudo reboot"
    echo.
    echo ============================================
    echo Pi is rebooting...
    echo ============================================
    echo.
    echo Wait 30-60 seconds, then:
    echo   1. Unplug USB-C cable from Pi
    echo   2. Plug USB-C cable from Pi to Windows computer
    echo   3. Windows should auto-install driver
    echo   4. Check: ping 192.168.4.1
    echo.
) else (
    echo.
    echo Reboot skipped. Run this command to reboot later:
    echo   ssh %PI_USER%@%PI_ADDRESS% "sudo reboot"
    echo.
)

echo Configuration complete!
echo.
pause

