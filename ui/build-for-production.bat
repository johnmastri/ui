@echo off
echo Building Vue.js app for production...

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo Installing dependencies...
    npm install
)

REM Build the Vue.js app
echo Building Vue.js app...
npm run build

REM Copy JUCE files to dist
echo Copying JUCE integration files...
if not exist "dist\js\juce" mkdir "dist\js\juce"
xcopy /Y /E "public\js\juce\*" "dist\js\juce\"

echo Production build complete! Files are in dist/ folder.
echo You can now build the VST with: cmake --build vs-build --config Release
pause
