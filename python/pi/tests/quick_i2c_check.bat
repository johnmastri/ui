@echo off
echo Installing i2c-tools on Pi...
echo.

set PI_USER=mastrctrl
set PI_IP=192.168.1.195

echo Step 1: Installing i2c-tools...
ssh %PI_USER%@%PI_IP% "sudo apt-get update && sudo apt-get install -y i2c-tools"

echo.
echo Step 2: Running i2cdetect scan...
echo.
ssh %PI_USER%@%PI_IP% "i2cdetect -y 1"

echo.
echo ============================================================
echo WHAT TO LOOK FOR:
echo ============================================================
echo.
echo In the grid above, you should see:
echo   - A number (like 21 or 20) where your PCF8575 is
echo   - If you see all dashes (--) = NO DEVICE DETECTED
echo.
echo If you see a number: SUCCESS! The PCF8575 is connected.
echo If you see all dashes, check:
echo.
echo 1. SDA wire: Pi Pin 3 to PCF SDA pin
echo 2. SCL wire: Pi Pin 5 to PCF SCL pin  
echo 3. Try swapping SDA and SCL wires
echo 4. Try different jumper wires
echo 5. Is encoder disconnected from PCF? (test with just PCF)
echo.
echo ============================================================
pause






