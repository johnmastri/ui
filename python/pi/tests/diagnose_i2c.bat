@echo off
echo Installing i2c-tools and running hardware diagnostic...
echo.

cd /d "%~dp0"

set PI_USER=mastrctrl
set PI_IP=192.168.1.195

echo Copying diagnostic script...
scp install_i2c_tools.sh %PI_USER%@%PI_IP%:~/mastrctrl/tests/

echo.
echo Running on Pi...
ssh %PI_USER%@%PI_IP% "cd mastrctrl/tests && chmod +x install_i2c_tools.sh && ./install_i2c_tools.sh"

echo.
echo ============================================================
echo TROUBLESHOOTING GUIDE
echo ============================================================
echo.
echo If i2cdetect shows nothing (all dashes):
echo.
echo 1. POWER CHECK:
echo    - Measure voltage on PCF8575 VCC pin (should be 5V)
echo    - Check power LED on PCF board (if present)
echo    - Try different 5V pin or power source
echo.
echo 2. WIRING CHECK (use multimeter continuity mode):
echo    - Verify Pin 3 connects to PCF SDA
echo    - Verify Pin 5 connects to PCF SCL
echo    - Verify Pin 6 connects to PCF GND
echo    - Check for loose connections
echo.
echo 3. SIMPLIFY:
echo    - Remove encoder wires (just power + I2C)
echo    - Try PCF8575 alone with no encoder attached
echo.
echo 4. ADDRESS:
echo    - Try removing A0 jumper (use base address 0x20)
echo    - Or try setting different jumpers
echo.
echo 5. REPLACE:
echo    - Try different jumper wires
echo    - Test with different PCF8575 board if available
echo.
echo ============================================================
pause






