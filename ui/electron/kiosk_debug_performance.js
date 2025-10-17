const { app, BrowserWindow } = require("electron")

app.disableHardwareAcceleration()

app.commandLine.appendSwitch("--disable-gpu")
app.commandLine.appendSwitch("--no-sandbox")
app.commandLine.appendSwitch("--disable-dev-shm-usage")
app.commandLine.appendSwitch("--disable-web-security")

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: false, // Disable kiosk for debugging
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false,
      devTools: true // Enable dev tools
    }
  })
  
  win.loadURL("http://192.168.1.5:3000")
  
  win.once("ready-to-show", () => {
    win.show()
    win.focus()
    
    // Open dev tools automatically
    win.webContents.openDevTools()
    
    // Inject performance monitoring
    win.webContents.executeJavaScript(`
      // Monitor frame rate
      let frames = 0;
      let lastTime = performance.now();
      
      function countFPS() {
        frames++;
        const now = performance.now();
        if (now - lastTime >= 1000) {
          console.log('FPS:', frames);
          frames = 0;
          lastTime = now;
        }
        requestAnimationFrame(countFPS);
      }
      countFPS();
      
      // Monitor DOM updates
      const observer = new MutationObserver((mutations) => {
        console.log('DOM mutations:', mutations.length);
      });
      observer.observe(document.body, { childList: true, subtree: true, attributes: true });
      
      console.log('Performance monitoring started');
    `)
  })
})

app.on("window-all-closed", () => {
  app.quit()
}) 