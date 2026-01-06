@echo off
set PI_USER=mastrctrl
set PI_IP=192.168.1.195

echo ============================================================
echo I2C Device Scan
echo ============================================================
echo.
ssh %PI_USER%@%PI_IP% "/usr/sbin/i2cdetect -y 1"

echo.
echo ============================================================
echo RESULTS:
echo ============================================================
echo If you see a number in the grid (like 20 or 21):
echo   SUCCESS - PCF8575 is detected!
echo.
echo If you see all dashes (--):
echo   NO DEVICE - Check SDA/SCL wiring
echo   Try: swap Pin 3 and Pin 5 connections
echo ============================================================
pause






