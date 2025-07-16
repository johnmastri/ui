const { app, BrowserWindow } = require("electron")

// Completely disable all hardware acceleration before app starts
app.disableHardwareAcceleration()

// Aggressive flags to force software rendering
app.commandLine.appendSwitch("--disable-gpu")
app.commandLine.appendSwitch("--disable-gpu-compositing")
app.commandLine.appendSwitch("--disable-gpu-rasterization")
app.commandLine.appendSwitch("--disable-gpu-sandbox")
app.commandLine.appendSwitch("--disable-software-rasterizer")
app.commandLine.appendSwitch("--no-sandbox")
app.commandLine.appendSwitch("--disable-dev-shm-usage")
app.commandLine.appendSwitch("--disable-accelerated-2d-canvas")
app.commandLine.appendSwitch("--disable-accelerated-video-decode")
app.commandLine.appendSwitch("--disable-web-security")
app.commandLine.appendSwitch("--use-gl", "swiftshader")
app.commandLine.appendSwitch("--ignore-gpu-blacklist")
app.commandLine.appendSwitch("--disable-features", "VizDisplayCompositor,UseSurfaceLayerForVideo")

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: true,
    show: false,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false,
      offscreen: false,
      enableRemoteModule: false
    }
  })
  
  win.loadURL("http://192.168.1.5:3000")
  
  win.once("ready-to-show", () => {
    win.show()
    win.focus()
  })
  
  win.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
    console.log('Failed to load:', errorCode, errorDescription)
  })
})

app.on("window-all-closed", () => {
  app.quit()
}) 