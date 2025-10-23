# ########### CURRENT METHOD (2025) ###################
# Step 1: Deploy UI to Pi first (run on Windows in PowerShell):
cd package\scripts
.\deploy-ui-to-pi.ps1 -PiAddress 192.168.1.195 -InstallDeps

# Step 2: SSH to Pi (run on Windows):
ssh mastrctrl@192.168.1.195

# Step 3: Start WebSocket server (run ON THE PI after SSH):
# This cleans up ports and starts the server
cd ~/mastrctrl/package/python/pi && bash start_controller.sh

# Step 4: Open NEW terminal, SSH again, start Vite dev server (run ON THE PI):
cd ~/mastrctrl/ui && npm run dev

# Step 5: Open NEW terminal, SSH again, then run ON THE PI:
# (This starts X server and Electron - bash syntax, NOT PowerShell!)

# First, kill any existing X server:
sudo pkill X

# Then start X and Electron:
sudo X :0 -nolisten tcp & sleep 5 && DISPLAY=:0 electron ~/mastrctrl/ui/electron/kiosk_basic_fast.cjs