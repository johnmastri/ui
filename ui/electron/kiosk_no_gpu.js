const { app, BrowserWindow } = require("electron")

// Disable hardware acceleration to fix GBM errors on Pi
app.disableHardwareAcceleration()

// Additional flags for Pi compatibility
app.commandLine.appendSwitch("--disable-gpu")
app.commandLine.appendSwitch("--disable-software-rasterizer")
app.commandLine.appendSwitch("--no-sandbox")

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: true,
    show: false,
    webPreferences: {
      nodeIntegration: false,
      offscreen: false
    }
  })
  
  win.loadURL("http://192.168.1.5:3000")
  
  win.once("ready-to-show", () => {
    win.show()
    win.focus()
  })
})

app.on("window-all-closed", () => {
  app.quit()
}) 