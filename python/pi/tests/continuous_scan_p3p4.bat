@echo off
echo Starting continuous I2C scanner with custom encoder pins...
echo.

set PI_USER=mastrctrl
set PI_IP=192.168.1.195

cd /d "%~dp0"

echo Copying script to Pi...
scp continuous_i2c_scan.py %PI_USER%@%PI_IP%:~/mastrctrl/tests/

echo.
echo ============================================================
echo Continuous I2C Scan with Encoder on P03/P04
echo ============================================================
echo.
echo Encoder A on P03, Encoder B on P04, Button on P05
echo.
echo Scanning every 100ms...
echo Press Ctrl+C to stop
echo.
echo ============================================================
echo.

ssh %PI_USER%@%PI_IP% "cd mastrctrl/tests && python3 continuous_i2c_scan.py --pin-a 3 --pin-b 4 --pin-btn 5"

echo.
echo Scan stopped.
pause






