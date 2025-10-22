@echo off
echo ============================================
echo Finding Your Raspberry Pi
echo ============================================
echo.

echo Checking common hostnames...
echo.

echo [1] Trying mastrctrl.local...
ping -n 1 mastrctrl.local >nul 2>&1
if %errorlevel%==0 (
    echo    FOUND at mastrctrl.local
    for /f "tokens=3" %%a in ('ping -n 1 mastrctrl.local ^| find "Reply"') do (
        echo    IP Address: %%a
        set PI_IP=%%a
    )
) else (
    echo    Not found
)

echo.
echo [2] Trying raspberrypi.local...
ping -n 1 raspberrypi.local >nul 2>&1
if %errorlevel%==0 (
    echo    FOUND at raspberrypi.local
    for /f "tokens=3" %%a in ('ping -n 1 raspberrypi.local ^| find "Reply"') do (
        echo    IP Address: %%a
        set PI_IP=%%a
    )
) else (
    echo    Not found
)

echo.
echo [3] Scanning local network for Raspberry Pi devices...
echo    This may take a moment...
echo.

arp -a | findstr /C:"b8-27-eb" /C:"dc-a6-32" /C:"e4-5f-01" /C:"d8-3a-dd" /C:"b8-27-eb" /C:"2c-cf-67"

echo.
echo ============================================
echo.
echo What is your Pi's IP address?
echo (Check your router admin page if needed)
echo.
set /p MANUAL_IP="Enter Pi IP address: "

if not "%MANUAL_IP%"=="" (
    echo.
    echo Testing %MANUAL_IP%...
    ping -n 1 %MANUAL_IP% >nul 2>&1
    if %errorlevel%==0 (
        echo    SUCCESS! Pi is reachable at %MANUAL_IP%
        echo.
        echo Now run: diagnose-usb.bat
        echo Then edit the file and change line 4 to:
        echo set PI_ADDRESS=%MANUAL_IP%
    ) else (
        echo    ERROR: Cannot reach Pi at %MANUAL_IP%
    )
)

echo.
pause

