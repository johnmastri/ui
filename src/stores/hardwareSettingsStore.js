import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useHardwareSettingsStore = defineStore('hardwareSettings', () => {
  // Settings menu buttons with opacity variations
  const buttons = ref([
    { id: 'device', label: 'DEVICE', x: 0, y: 0, defaultOpacity: 0.45 },      // -33%
    { id: 'network', label: 'NETWORK', x: 400, y: 0, defaultOpacity: 0.85 },  // +27%
    { id: 'display', label: 'DISPLAY', x: 0, y: 240, defaultOpacity: 0.67 },  // base
    { id: 'midi', label: 'MIDI', x: 400, y: 240, defaultOpacity: 0.55 }       // -18%
  ])
  
  // Currently hovered button
  const currentSelectedButton = ref(null)
  
  // Actions
  const setHoveredButton = (buttonId) => {
    currentSelectedButton.value = buttonId
    console.log('Hardware Settings: Hovered button:', buttonId)
  }
  
  const clearHoveredButton = () => {
    currentSelectedButton.value = null
    console.log('Hardware Settings: Cleared hover state')
  }
  
  return {
    // State
    buttons,
    currentSelectedButton,
    
    // Actions
    setHoveredButton,
    clearHoveredButton
  }
}) 