@echo off
REM Install MastrCtrl USB Driver
REM Run as Administrator

echo ============================================
echo MastrCtrl USB Driver Installation
echo ============================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: This script must be run as Administrator
    echo Right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Installing driver...
echo.

pnputil.exe /add-driver "%~dp0MastrCtrl_USB.inf" /install

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo Driver installed successfully!
    echo ============================================
    echo.
    echo Now plug in your MastrCtrl hardware via USB-C
    echo Windows will automatically recognize it as:
    echo   "MastrCtrl USB MIDI Controller"
    echo.
    echo No further configuration needed!
    echo.
) else (
    echo.
    echo ============================================
    echo Driver installation failed!
    echo ============================================
    echo.
    echo Please check:
    echo   1. You are running as Administrator
    echo   2. Windows is up to date
    echo   3. MastrCtrl_USB.inf is in the same folder
    echo.
)

pause

