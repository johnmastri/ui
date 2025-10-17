# UI Directory

Vue.js + Electron frontend for the MastrCtrl hardware controller.

## What's Here

- **src/** - Vue components, stores, and application logic
- **electron/** - Electron kiosk configurations for Raspberry Pi
- **public/** - Static assets (SVG, audio, JUCE bridge)
- **dist/** - Built production files (generated)

## Development

```bash
# Install dependencies
npm install

# Run dev server
npm run dev

# Build for production
npm run build
```

## Key Components

- `src/components/hardware/settings/UpdatePanel.vue` - OTA update UI
- `src/stores/updateStore.js` - Update state management
- `src/stores/websocketStore.js` - WebSocket communication with Pi server
- `src/stores/hardwareSettingsStore.js` - Hardware settings configuration

## Deployment

Built files are packaged by `../scripts/create_release.ps1` and deployed via `../scripts/deploy-to-pi.ps1`.

