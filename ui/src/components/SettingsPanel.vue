<template>
  <div v-if="settingsStore.isSettingsPanelOpen" class="settings-overlay" @click="handleOverlayClick">
    <div class="settings-panel" @click.stop>
      <!-- Header with close button -->
      <div class="settings-header">
        <h2>Settings</h2>
        <button class="close-button" @click="closeSettings">×</button>
      </div>

      <!-- Settings content -->
      <div class="settings-content">
        
        <!-- Large Display Toggle -->
        <div class="setting-item">
          <label class="setting-label">
            <span class="setting-name">Large Parameter Display</span>
            <span class="setting-description">Show large numeric values when adjusting parameters</span>
          </label>
          <div class="setting-control">
            <button 
              class="toggle-button"
              :class="{ 'active': settingsStore.showLargeDisplay }"
              @click="toggleLargeDisplay"
            >
              <span class="toggle-slider"></span>
            </button>
          </div>
        </div>

        <!-- Fade Out Delay -->
        <div class="setting-item">
          <label class="setting-label">
            <span class="setting-name">Display Timeout</span>
            <span class="setting-description">Time before returning to VU meter ({{ settingsStore.fadeOutDelay }}s)</span>
          </label>
          <div class="setting-control">
            <input 
              type="range" 
              class="delay-slider"
              :value="settingsStore.fadeOutDelay"
              min="1" 
              max="10" 
              step="1"
              @input="updateFadeDelay"
            >
            <div class="delay-markers">
              <span>1s</span>
              <span>5s</span>
              <span>10s</span>
            </div>
          </div>
        </div>

        <!-- Future settings placeholder -->
        <div class="setting-item disabled">
          <label class="setting-label">
            <span class="setting-name">Theme</span>
            <span class="setting-description">Coming soon...</span>
          </label>
          <div class="setting-control">
            <select class="theme-select" disabled>
              <option>Dark</option>
              <option>Light</option>
            </select>
          </div>
        </div>

      </div>

      <!-- Footer with reset button -->
      <div class="settings-footer">
        <button class="reset-button" @click="resetSettings">
          Reset to Defaults
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useSettingsStore } from '../stores/settingsStore'

const settingsStore = useSettingsStore()

// Methods
const closeSettings = () => {
  settingsStore.closeSettingsPanel()
}

const handleOverlayClick = () => {
  closeSettings()
}

const toggleLargeDisplay = () => {
  settingsStore.toggleLargeDisplay()
}

const updateFadeDelay = (event) => {
  const value = parseInt(event.target.value)
  settingsStore.setFadeOutDelay(value)
}

const resetSettings = () => {
  settingsStore.resetToDefaults()
}
</script>

<style scoped>
.settings-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  backdrop-filter: blur(4px);
}

.settings-panel {
  background: linear-gradient(135deg, #2a2a2a 0%, #1a1a1a 100%);
  border: 2px solid #444;
  border-radius: 12px;
  width: 90%;
  max-width: 500px;
  max-height: 80vh;
  overflow: hidden;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
}

/* Header */
.settings-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid #333;
  background: rgba(0, 0, 0, 0.2);
}

.settings-header h2 {
  margin: 0;
  color: #fff;
  font-size: 1.5em;
  font-weight: 600;
  font-family: 'Courier New', monospace;
}

.close-button {
  background: none;
  border: none;
  color: #888;
  font-size: 2em;
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 6px;
  transition: all 0.2s;
}

.close-button:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #fff;
}

/* Content */
.settings-content {
  padding: 24px;
  max-height: 400px;
  overflow-y: auto;
}

.setting-item {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 24px;
  gap: 20px;
}

.setting-item.disabled {
  opacity: 0.5;
  pointer-events: none;
}

.setting-label {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.setting-name {
  color: #fff;
  font-weight: 600;
  font-size: 1em;
  font-family: 'Courier New', monospace;
}

.setting-description {
  color: #aaa;
  font-size: 0.85em;
  line-height: 1.4;
}

.setting-control {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

/* Toggle Button */
.toggle-button {
  width: 50px;
  height: 24px;
  background: #333;
  border: 2px solid #555;
  border-radius: 12px;
  position: relative;
  cursor: pointer;
  transition: all 0.3s;
  outline: none;
}

.toggle-button.active {
  background: #00ff88;
  border-color: #00ff88;
}

.toggle-slider {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 16px;
  height: 16px;
  background: #fff;
  border-radius: 50%;
  transition: all 0.3s;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.toggle-button.active .toggle-slider {
  transform: translateX(26px);
}

/* Delay Slider */
.delay-slider {
  width: 120px;
  height: 6px;
  background: #333;
  border-radius: 3px;
  outline: none;
  cursor: pointer;
  -webkit-appearance: none;
}

.delay-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  width: 18px;
  height: 18px;
  background: #00ff88;
  border-radius: 50%;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.delay-slider::-moz-range-thumb {
  width: 18px;
  height: 18px;
  background: #00ff88;
  border-radius: 50%;
  cursor: pointer;
  border: none;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.delay-markers {
  display: flex;
  justify-content: space-between;
  width: 120px;
  font-size: 0.7em;
  color: #666;
}

/* Select */
.theme-select {
  background: #333;
  border: 1px solid #555;
  border-radius: 6px;
  color: #fff;
  padding: 6px 12px;
  font-family: 'Courier New', monospace;
  outline: none;
}

/* Footer */
.settings-footer {
  padding: 20px 24px;
  border-top: 1px solid #333;
  background: rgba(0, 0, 0, 0.2);
  display: flex;
  justify-content: flex-end;
}

.reset-button {
  background: #444;
  border: 1px solid #666;
  border-radius: 6px;
  color: #fff;
  padding: 8px 16px;
  cursor: pointer;
  font-family: 'Courier New', monospace;
  transition: all 0.2s;
}

.reset-button:hover {
  background: #555;
  border-color: #777;
}

/* Scrollbar */
.settings-content::-webkit-scrollbar {
  width: 8px;
}

.settings-content::-webkit-scrollbar-track {
  background: #1a1a1a;
}

.settings-content::-webkit-scrollbar-thumb {
  background: #555;
  border-radius: 4px;
}

.settings-content::-webkit-scrollbar-thumb:hover {
  background: #666;
}

/* Responsive */
@media (max-width: 600px) {
  .settings-panel {
    width: 95%;
    margin: 20px;
  }
  
  .setting-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
  
  .setting-control {
    align-items: flex-start;
    width: 100%;
  }
  
  .delay-slider {
    width: 100%;
  }
  
  .delay-markers {
    width: 100%;
  }
}
</style> 