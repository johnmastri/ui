import { defineStore } from 'pinia'

export const useSettingsStore = defineStore('settings', {
  state: () => ({
    // Display settings
    showLargeDisplay: true,
    fadeOutDelay: 3, // seconds (1-10 range)
    
    // UI settings
    showSettingsPanel: false,
    
    // Future settings placeholders
    // theme: 'dark',
    // ledBrightness: 80,
    // websocketAutoReconnect: true,
  }),

  getters: {
    fadeOutDelayMs: (state) => state.fadeOutDelay * 1000,
    
    isLargeDisplayEnabled: (state) => state.showLargeDisplay,
    
    isSettingsPanelOpen: (state) => state.showSettingsPanel,
  },

  actions: {
    // Display settings
    toggleLargeDisplay() {
      this.showLargeDisplay = !this.showLargeDisplay
      console.log('Settings: Large display toggled to:', this.showLargeDisplay)
    },

    setLargeDisplay(enabled) {
      this.showLargeDisplay = enabled
      console.log('Settings: Large display set to:', enabled)
    },

    setFadeOutDelay(seconds) {
      // Clamp to valid range
      const clampedValue = Math.max(1, Math.min(10, seconds))
      this.fadeOutDelay = clampedValue
      console.log('Settings: Fade out delay set to:', clampedValue, 'seconds')
    },

    // UI settings
    openSettingsPanel() {
      this.showSettingsPanel = true
      console.log('Settings: Panel opened')
    },

    closeSettingsPanel() {
      this.showSettingsPanel = false
      console.log('Settings: Panel closed')
    },

    toggleSettingsPanel() {
      this.showSettingsPanel = !this.showSettingsPanel
      console.log('Settings: Panel toggled to:', this.showSettingsPanel)
    },

    // Bulk settings management
    resetToDefaults() {
      this.showLargeDisplay = true
      this.fadeOutDelay = 3
      this.showSettingsPanel = false
      console.log('Settings: Reset to defaults')
    },

    // Future: Load/save settings from localStorage or backend
    loadSettings() {
      // TODO: Load from localStorage or backend
      console.log('Settings: Loading settings (not implemented)')
    },

    saveSettings() {
      // TODO: Save to localStorage or backend
      console.log('Settings: Saving settings (not implemented)')
    }
  }
}) 