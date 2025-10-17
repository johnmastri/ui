@echo off
echo Rebuilding MastrCtrl VST Plugin...

cd /d "%~dp0vs-build"

echo Building with MSBuild...
msbuild "Juce8WebViewTutorial.sln" /p:Configuration=Release /p:Platform=x64

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Build completed successfully!
    echo.
    echo Plugin location:
    echo %cd%\plugin\JuceWebViewPlugin_artefacts\Release\VST3\MastrCtrl.vst3
    echo.
    echo Standalone app location:
    echo %cd%\plugin\JuceWebViewPlugin_artefacts\Release\Standalone\MastrCtrl.exe
) else (
    echo.
    echo ❌ Build failed with error code %ERRORLEVEL%
    echo Check the output above for build errors.
)

pause