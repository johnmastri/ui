import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useHardwareSettingsStore = defineStore('hardwareSettings', () => {
  // Settings menu buttons with opacity variations (keep existing)
  const buttons = ref([
    { id: 'device', label: 'DEVICE', x: 0, y: 0, defaultOpacity: 0.45 },      // -33%
    { id: 'network', label: 'NETWORK', x: 400, y: 0, defaultOpacity: 0.85 },  // +27%
    { id: 'display', label: 'DISPLAY', x: 0, y: 240, defaultOpacity: 0.67 },  // base
    { id: 'midi', label: 'MIDI', x: 400, y: 240, defaultOpacity: 0.55 }       // -18%
  ])
  
  // Settings with parameters (new)
  const settings = ref([
    {
      id: 'device',
      parameters: [
        {
          id: 'deviceName',
          label: 'Device Name',
          type: 'button',
          value: 'MastrCtrl Unit 1'
        },
        {
          id: 'firmwareVersion',
          label: 'Firmware Version',
          type: 'display',
          value: 'v2.1.4'
        },
        {
          id: 'updateFirmware',
          label: 'Update Firmware',
          type: 'button',
          value: 'UPDATE'
        },
        {
          id: 'factoryReset',
          label: 'Factory Reset',
          type: 'button',
          value: 'RESET'
        }
      ]
    },
    {
      id: 'network',
      parameters: [
        {
          id: 'connectionMode',
          label: 'Connection Mode',
          type: 'display',
          value: 'Master'
        },
        {
          id: 'deviceAddress',
          label: 'Device Address',
          type: 'select',
          value: '1',
          options: ['1', '2', '3', '4', '5', '10', '50', '100', '255']
        },
        {
          id: 'rj45DaisyChain',
          label: 'RJ45 Daisy-Chain',
          type: 'select',
          value: 'Auto Detect',
          options: ['Auto Detect', 'Manual Setup']
        },
        {
          id: 'pingTest',
          label: 'Ping Test',
          type: 'button',
          value: 'TEST'
        }
      ]
    },
    {
      id: 'display',
      parameters: [
        {
          id: 'brightness',
          label: 'Brightness',
          type: 'select',
          value: '75%',
          options: ['25%', '50%', '75%', '100%']
        },
        {
          id: 'theme',
          label: 'Theme',
          type: 'select',
          value: 'Dark',
          options: ['Light', 'Dark', 'High Contrast']
        }
      ]
    },
    {
      id: 'midi',
      parameters: [
        {
          id: 'mode',
          label: 'Mode',
          type: 'select',
          value: 'MIDI',
          options: ['MIDI', 'Serial Protocol']
        },
        {
          id: 'channel',
          label: 'Channel',
          type: 'select',
          value: 'Global',
          options: ['Global', 'Per Encoder']
        },
        {
          id: 'thru',
          label: 'Thru',
          type: 'toggle',
          value: true
        }
      ]
    }
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
  
  // Helper function to get settings for a button
  const getSettingForButton = (buttonId) => {
    return settings.value.find(s => s.id === buttonId)
  }
  
  return {
    // State
    buttons,
    settings,
    currentSelectedButton,
    
    // Actions
    setHoveredButton,
    clearHoveredButton,
    getSettingForButton
  }
}) 