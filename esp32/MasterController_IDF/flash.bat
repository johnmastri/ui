@echo off
echo Installing/Updating ESP-IDF Python environment...
cd C:\Espressif\frameworks\esp-idf-v5.5.1-2
call install.bat

echo.
echo Setting up ESP-IDF environment...
call export.bat

echo.
echo Navigating to project directory...
cd /d D:\Dropbox\projects\midi_cs\controller_v2\package\esp32\MasterController_IDF

echo.
echo Flashing firmware to ESP32-S3...
echo.
echo NOTE: If this is your first flash, you may need to:
echo   1. Hold the BOOT button while plugging in USB
echo   2. Check your COM port in Device Manager
echo.

idf.py -p COM4 flash monitor

echo.
echo If COM3 is not correct, edit this file or run:
echo   idf.py -p COMX flash monitor
echo.
pause

