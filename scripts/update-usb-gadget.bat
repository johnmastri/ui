@echo off
REM Update USB Gadget Script on Pi and Restart

setlocal

set PI_USER=mastrctrl
set PI_ADDRESS=192.168.1.195

if not "%1"=="" set PI_ADDRESS=%1

echo ============================================
echo Updating USB Gadget Script on Pi
echo ============================================
echo.

cd /d "%~dp0..\python\pi\setup"

echo [1/4] Copying updated script to Pi...
scp usb_gadget_configfs.sh %PI_USER%@%PI_ADDRESS%:/tmp/

echo.
echo [2/4] Stopping current gadget...
ssh %PI_USER%@%PI_ADDRESS% "cd /sys/kernel/config/usb_gadget/pi4 2>/dev/null && sudo sh -c 'echo > UDC' 2>/dev/null; cd .. && sudo rm -rf pi4 2>/dev/null; true"

echo.
echo [3/4] Installing updated script...
ssh %PI_USER%@%PI_ADDRESS% "sudo cp /tmp/usb_gadget_configfs.sh /usr/local/bin/usb-gadget-setup.sh && sudo chmod +x /usr/local/bin/usb-gadget-setup.sh"

echo.
echo [4/4] Starting gadget with new script...
ssh %PI_USER%@%PI_ADDRESS% "sudo /usr/local/bin/usb-gadget-setup.sh"

echo.
echo ============================================
echo Done!
echo ============================================
echo.
echo Now unplug and replug the USB-C cable on Windows
echo Windows should auto-install the driver
echo.
pause

