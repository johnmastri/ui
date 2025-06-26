@echo off
echo Starting Vue.js development server...

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo Installing dependencies...
    npm install
)

REM Start the development server
echo Starting development server on http://localhost:3000
echo.
echo To use development mode:
echo 1. Keep this server running
echo 2. Build VST with: cmake -DJUCE_WEBVIEW_DEVELOPMENT_MODE=ON --preset vs
echo 3. Build: cmake --build vs-build --config Release
echo.
npm run dev
