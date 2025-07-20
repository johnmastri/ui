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
  
  // Currently hovered button - default to device
  const currentSelectedButton = ref('device')
  
  // Actions
  const setHoveredButton = (buttonId) => {
    currentSelectedButton.value = buttonId
  }
  
  const clearHoveredButton = () => {
    currentSelectedButton.value = 'device'
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