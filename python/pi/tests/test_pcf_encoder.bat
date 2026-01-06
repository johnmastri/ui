@echo off
echo Copying PCF encoder test script to Raspberry Pi...
echo.

set PI_USER=mastrctrl
set PI_IP=192.168.1.195
set PI_PATH=~/mastrctrl/tests/

cd /d "%~dp0"

echo Creating tests directory on Pi...
ssh %PI_USER%@%PI_IP% "mkdir -p mastrctrl/tests"

echo Copying test scripts to %PI_USER%@%PI_IP%:%PI_PATH%
scp test_pcf_encoder.py %PI_USER%@%PI_IP%:%PI_PATH%
scp test_i2c_scan.py %PI_USER%@%PI_IP%:%PI_PATH%

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to copy file. Check connection to Pi.
    pause
    exit /b 1
)

echo.
echo File copied successfully!
echo.
echo Running I2C diagnostic first...
echo.
ssh %PI_USER%@%PI_IP% "cd mastrctrl && python3 tests/test_i2c_scan.py"

echo.
echo.
echo Press any key to continue to encoder test, or Ctrl+C to stop...
pause > nul

echo.
echo Connecting to Pi and running encoder test...
echo Scanning for PCF device on addresses 0x20-0x27...
echo.

ssh %PI_USER%@%PI_IP% "cd mastrctrl && python3 tests/test_pcf_encoder.py"

echo.
echo Test completed.
pause

