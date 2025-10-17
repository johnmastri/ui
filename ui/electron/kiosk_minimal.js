const { app, BrowserWindow } = require('electron')

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: true,
    webPreferences: {
      nodeIntegration: false
    }
  })
  
  win.loadURL('http://192.168.1.5:3000')
})

app.on('window-all-closed', () => {
  app.quit()
}) 