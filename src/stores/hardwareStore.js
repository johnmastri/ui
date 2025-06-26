import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { useWebSocket } from '../composables/useWebSocket'

export const useHardwareStore = defineStore('hardware', () => {
  // WebSocket integration
  const {
    isWebSocketConnected,
    hasRecentSend,
    hasRecentReceive,
    websocketServer,
    sendWebSocketMessage,
    reconnectWebSocket
  } = useWebSocket()

  // Display state for virtual hardware
  const displayText = ref('')
  const displayValue = ref('')
  const isDisplayActive = ref(false)
  const displayTimeout = ref(null)

  // Hardware state
  const currentParameter = ref(null)
  const hardwareConnected = ref(false)

  // Computed
  const isConnected = computed(() => isWebSocketConnected.value)
  const connectionStatus = computed(() => 
    isWebSocketConnected.value ? 'Connected' : 'Disconnected'
  )

  // Methods
  const updateDisplay = (parameterName, value) => {
    // Clear any existing timeout
    if (displayTimeout.value) {
      clearTimeout(displayTimeout.value)
    }

    // Update display
    displayText.value = parameterName
    displayValue.value = value
    isDisplayActive.value = true
    currentParameter.value = parameterName

    // Set timeout to fade to UV meter after 3 seconds
    displayTimeout.value = setTimeout(() => {
      fadeToUVMeter()
    }, 3000)
  }

  const fadeToUVMeter = () => {
    isDisplayActive.value = false
    displayText.value = 'UV Meter'
    displayValue.value = '0.0 dB'
  }

  const sendHardwareCommand = (command) => {
    sendWebSocketMessage(command)
  }

  const sendParameterUpdate = (parameterName, value) => {
    const payload = {
      type: 'parameter_update',
      parameter: parameterName,
      value: value,
      timestamp: Date.now()
    }
    sendWebSocketMessage(payload)
  }

  const sendLEDUpdate = (ledData) => {
    const payload = {
      type: 'led_update',
      data: ledData,
      timestamp: Date.now()
    }
    sendWebSocketMessage(payload)
  }

  const resetDisplay = () => {
    if (displayTimeout.value) {
      clearTimeout(displayTimeout.value)
    }
    isDisplayActive.value = false
    displayText.value = ''
    displayValue.value = ''
    currentParameter.value = null
  }

  return {
    // WebSocket state
    isWebSocketConnected,
    hasRecentSend,
    hasRecentReceive,
    websocketServer,
    isConnected,
    connectionStatus,
    
    // Display state
    displayText,
    displayValue,
    isDisplayActive,
    currentParameter,
    
    // Hardware state
    hardwareConnected,
    
    // Methods
    updateDisplay,
    fadeToUVMeter,
    sendHardwareCommand,
    sendParameterUpdate,
    sendLEDUpdate,
    reconnectWebSocket,
    resetDisplay
  }
}) 