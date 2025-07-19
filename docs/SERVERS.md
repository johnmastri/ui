run python mock_ws_server
run npm run dev
flutter build
ssh mastrctrl@192.168.1.195


~/mastrctrl/flutter/web electron kiosk.js (from within flutter web directory)


   scp -r "VSTMastrCtrl\mastrctrl\plugin\ui\src" "VSTMastrCtrl\mastrctrl\plugin\ui\public" "VSTMastrCtrl\mastrctrl\plugin\ui\package.json" "VSTMastrCtrl\mastrctrl\plugin\ui\vite.config.js" "VSTMastrCtrl\mastrctrl\plugin\ui\index.html" pi@192.168.1.195:/home/pi/vue_dev/


const { app, BrowserWindow } = require('electron')

// Performance flags before app ready
app.commandLine.appendSwitch('--enable-features', 'VaapiVideoDecoder')
app.commandLine.appendSwitch('--disable-features', 'VizDisplayCompositor')
app.commandLine.appendSwitch('--enable-gpu-rasterization')
app.commandLine.appendSwitch('--enable-zero-copy')
app.commandLine.appendSwitch('--disable-software-rasterizer')
app.commandLine.appendSwitch('--disable-background-timer-throttling')
app.commandLine.appendSwitch('--disable-backgrounding-occluded-windows')
app.commandLine.appendSwitch('--disable-renderer-backgrounding')
app.commandLine.appendSwitch('--disable-background-networking')
app.commandLine.appendSwitch('--disable-extensions')
app.commandLine.appendSwitch('--disable-plugins')
app.commandLine.appendSwitch('--disable-web-security')
app.commandLine.appendSwitch('--disable-features', 'TranslateUI,BlinkGenPropertyTrees')
app.commandLine.appendSwitch('--no-sandbox')
app.commandLine.appendSwitch('--disable-dev-shm-usage')

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: true,
    show: false, // Don't show until ready
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      enableRemoteModule: false,
      webSecurity: false,
      allowRunningInsecureContent: true,
      experimentalFeatures: true,
      // Memory optimizations
      preload: null,
      partition: null,
      // Performance
      backgroundThrottling: false,
      offscreen: false
    }
  })
  
  // Load URL and show when ready for faster perceived startup
  win.loadURL('http://192.168.1.5:3000')
  
  win.once('ready-to-show', () => {
    win.show()
    // Force focus for touch input
    win.focus()
  })
  
  // Optional: Preload for faster subsequent loads
  win.webContents.once('dom-ready', () => {
    // Any additional optimizations after DOM loads
    win.webContents.setFrameRate(60)
  })
})

// App optimizations
app.on('window-all-closed', () => {
  app.quit()
})

// Disable hardware acceleration if causing issues (test both ways)
// app.disableHardwareAcceleration()



WORKING VERSION:::

const { app, BrowserWindow } = require('electron')

app.whenReady().then(() => {
  console.log('Electron app ready')
  
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: true,
    webPreferences: {
      nodeIntegration: false
    }
  })
  
  console.log('Loading URL: http://192.168.1.5:3000')
  win.loadURL('http://192.168.1.5:3000')
  
  win.webContents.on('did-finish-load', () => {
    console.log('Page loaded successfully')
  })
  
  win.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    console.log('Failed to load:', errorCode, errorDescription)
  })
})




///


scp "VSTMastrCtrl\mastrctrl\plugin\ui\electron\pi_performance_setup.sh" pi@192.168.1.195:/home/pi/mastrctrl/flutter/web/


scp "VSTMastrCtrl\mastrctrl\plugin\ui\electron\kiosk_no_shm.js" mastrctrl@192.168.1.195:~/mastrctrl/flutter/web/

DISPLAY=:0 electron kiosk_chromium_optimized.js




# ########### THIS WORKS ###################

# Start bare X server on display :0
sudo X :0 -nolisten tcp &
sleep 5

# Now run electron
DISPLAY=:0 electron kiosk.js