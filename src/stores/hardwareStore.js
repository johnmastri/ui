import { defineStore } from 'pinia'
import { ref, computed, watch } from 'vue'
import { useWebSocketStore } from './websocketStore'
import { useSettingsStore } from './settingsStore'
import { useParameterStore } from './parameterStore'

export const useHardwareStore = defineStore('hardware', () => {
  // Store integrations
  const websocketStore = useWebSocketStore()
  const settingsStore = useSettingsStore()
  const parameterStore = useParameterStore()

  // Display state for virtual hardware
  const displayText = ref('')
  const displayValue = ref('')
  const isDisplayActive = ref(false)
  const displayTimeout = ref(null)
  const lastParameterChange = ref(null)
  const parameterChangeDebounceTimeout = ref(null)

  // Hardware state
  const currentParameter = ref(null)
  const hardwareConnected = ref(false)

  // Parameter change tracking
  const lastChangedParameterId = ref(null)
  const lastChangeTimestamp = ref(0)

  // Computed
  const isConnected = computed(() => websocketStore.isConnected)
  const connectionStatus = computed(() => websocketStore.connectionStatus)

  // Initialize parameter store watcher
  const initParameterWatcher = () => {
    // Watch for parameter value changes by mapping each parameter's value
    // This avoids the issue where deep watching gives us the same array reference
    watch(
      () => parameterStore.parameters.map(p => ({ id: p.id, value: p.value, name: p.name, text: p.text })),
      (newValues, oldValues) => {
        if (!oldValues || !newValues) return
        
        // Find which parameter value changed
        for (let i = 0; i < newValues.length; i++) {
          const newValue = newValues[i]
          const oldValue = oldValues[i]
          
          if (oldValue && newValue.value !== oldValue.value) {
            // Find the full parameter object to pass to the handler
            const fullParameter = parameterStore.parameters.find(p => p.id === newValue.id)
            if (fullParameter) {
              handleParameterDataChange(fullParameter)
            }
            break
          }
        }
      },
      { deep: true }
    )
  }

  // Handle parameter data changes (the core logic)
  const handleParameterDataChange = (parameter) => {
    const now = Date.now()
    
    // Update display immediately
    updateDisplayFromParameter(parameter)
    
    // Track this change
    lastChangedParameterId.value = parameter.id
    lastChangeTimestamp.value = now
    
    // Clear any existing debounce timer
    if (parameterChangeDebounceTimeout.value) {
      clearTimeout(parameterChangeDebounceTimeout.value)
    }
    
    // Set debounce timer to detect when changes stop
    parameterChangeDebounceTimeout.value = setTimeout(() => {
      handleParameterChangesEnded()
    }, 150) // 150ms debounce - adjust as needed
    
    console.log('Hardware: Parameter data changed -', parameter.name, ':', parameter.value)
  }

  const updateDisplayFromParameter = (parameter) => {
    if (!settingsStore.isLargeDisplayEnabled) return
    
    // Clear any existing fade timer
    clearDisplayTimer()
    
    // Update display
    displayText.value = parameter.name
    displayValue.value = parameter.text || `${Math.round(parameter.value * 100)}%`
    isDisplayActive.value = true
    currentParameter.value = parameter.name
  }

  const handleParameterChangesEnded = () => {
    // Parameter changes have stopped, start fade timer
    if (settingsStore.isLargeDisplayEnabled) {
      startFadeTimer()
    }
    
    console.log('Hardware: Parameter changes ended, fade timer started')
  }

  const startFadeTimer = () => {
    // Clear any existing timeout
    clearDisplayTimer()

    // Set timeout using settings store delay
    displayTimeout.value = setTimeout(() => {
      fadeToUVMeter()
    }, settingsStore.fadeOutDelayMs)
  }

  const clearDisplayTimer = () => {
    if (displayTimeout.value) {
      clearTimeout(displayTimeout.value)
      displayTimeout.value = null
    }
    if (parameterChangeDebounceTimeout.value) {
      clearTimeout(parameterChangeDebounceTimeout.value)
      parameterChangeDebounceTimeout.value = null
    }
  }

  const fadeToUVMeter = () => {
    isDisplayActive.value = false
    displayText.value = 'VU Meter'
    displayValue.value = '0.0 dB'
    currentParameter.value = null
    console.log('Hardware: Faded to VU meter')
  }

  // Legacy method for backward compatibility (now just logs)
  const updateDisplay = (parameterName, value) => {
    console.log('Hardware: Legacy updateDisplay called -', parameterName, ':', value, '(now handled by data watcher)')
  }

  const stopInteraction = () => {
    console.log('Hardware: Legacy stopInteraction called (now handled by data watcher)')
  }

  const sendHardwareCommand = (command) => {
    websocketStore.send(command)
  }

  const sendParameterUpdate = (parameterName, value) => {
    const payload = {
      type: 'parameter_update',
      parameter: parameterName,
      value: value,
      timestamp: Date.now()
    }
    websocketStore.send(payload)
  }

  const sendLEDUpdate = (ledData) => {
    const payload = {
      type: 'led_update',
      data: ledData,
      timestamp: Date.now()
    }
    websocketStore.send(payload)
  }

  const reconnect = () => {
    websocketStore.reconnect()
  }

  const resetDisplay = () => {
    clearDisplayTimer()
    isDisplayActive.value = false
    displayText.value = ''
    displayValue.value = ''
    currentParameter.value = null
    lastChangedParameterId.value = null
    lastChangeTimestamp.value = 0
  }

  return {
    // WebSocket state (delegated to websocketStore)
    isWebSocketConnected: computed(() => websocketStore.isConnected),
    hasRecentSend: computed(() => websocketStore.hasRecentSend),
    hasRecentReceive: computed(() => websocketStore.hasRecentReceive),
    websocketServer: computed(() => websocketStore.serverUrl),
    isConnected,
    connectionStatus,
    
    // Display state
    displayText,
    displayValue,
    isDisplayActive,
    currentParameter,
    lastChangedParameterId,
    
    // Hardware state
    hardwareConnected,
    
    // Methods
    initParameterWatcher,
    handleParameterDataChange,
    updateDisplayFromParameter,
    handleParameterChangesEnded,
    startFadeTimer,
    clearDisplayTimer,
    fadeToUVMeter,
    sendHardwareCommand,
    sendParameterUpdate,
    sendLEDUpdate,
    reconnectWebSocket: reconnect,
    resetDisplay,
    
    // Legacy methods (for backward compatibility)
    updateDisplay,
    stopInteraction
  }
}) 