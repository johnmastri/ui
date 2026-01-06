@echo off
echo Installing i2c-tools on Raspberry Pi...
echo This may take a minute...
echo.

set PI_USER=mastrctrl
set PI_IP=192.168.1.195

echo Updating package list...
ssh %PI_USER%@%PI_IP% "sudo apt-get update"

echo.
echo Installing i2c-tools...
ssh %PI_USER%@%PI_IP% "sudo apt-get install -y i2c-tools"

echo.
echo Verifying installation...
ssh %PI_USER%@%PI_IP% "which i2cdetect"

echo.
echo Installation complete!
echo.
pause






