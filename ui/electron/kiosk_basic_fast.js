const { app, BrowserWindow } = require("electron")

app.whenReady().then(() => {
  const win = new BrowserWindow({
    width: 800,
    height: 480,
    kiosk: true,
    show: false,
    webPreferences: {
      nodeIntegration: false
    }
  })
  
  win.loadURL("http://192.168.1.5:3000")
  
  win.once("ready-to-show", () => {
    win.show()
    win.focus()
    
    // Inject performance optimizations at the web level
    win.webContents.executeJavaScript(`
      // Optimize requestAnimationFrame
      const originalRAF = window.requestAnimationFrame;
      window.requestAnimationFrame = function(callback) {
        return originalRAF.call(window, function(time) {
          callback(time);
        });
      };
      
      // Optimize touch events for better responsiveness
      const style = document.createElement('style');
      style.textContent = \`
        * { 
          touch-action: manipulation !important;
          user-select: none !important;
          -webkit-user-select: none !important;
        }
        body {
          overflow: hidden !important;
        }
      \`;
      document.head.appendChild(style);
      
      // Disable smooth scrolling which can cause lag
      document.documentElement.style.scrollBehavior = 'auto';
      
      console.log('Basic performance optimizations applied');
    `)
  })
})

app.on("window-all-closed", () => {
  app.quit()
}) 