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

  // New SVG parameter overlay properties
  const trackName = ref('')
  const pluginName = ref('MastrCtrl')
  
  // VU meter control
  const vuMeterValue = ref(0)        // Current VU meter reading (-40 to +3 dB)
  const needleAngle = ref(0)         // Calculated needle rotation angle
  
  // LA-2A Compression state
  const compression = ref({
    // Knob values
    gain: 50,              // 0-100 (50 = unity gain)
    peakReduction: 0,      // 0-100 (amount of compression)
    smoothingFactor: 15,   // 0-100 (response speed, 15 = default VU)
    
    // Calculated values
    needlePosition: 0,     // Current needle position in degrees
    gainDB: 0,             // Gain in dB (-20 to +20)
    smoothingMultiplier: 0.15, // Actual smoothing value (0-1)
    
    // Meter mode
    meterMode: 'GR',       // 'GR' (Gain Reduction) or 'VU' (Output Level)
    
    // State
    isCompressing: false   // Whether compression is active
  })
  
  // Visual state controls
  const dimmerOpacity = ref(0)       // Dimmer overlay opacity (0-1)
  const backgroundBrightness = ref(1) // Background brightness multiplier
  
  // Parameter animation states
  const parameterAnimation = ref({
    isAnimating: false,
    animationType: 'none' // 'slide', 'fade', 'bounce'
  })

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
  }

  // Legacy method for backward compatibility (now just logs)
  const updateDisplay = (parameterName, value) => {
   // console.log('Hardware: Legacy updateDisplay called -', parameterName, ':', value, '(now handled by data watcher)')
  }

  const stopInteraction = () => {
 //   console.log('Hardware: Legacy stopInteraction called (now handled by data watcher)')
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

  // Compression methods
  const updateCompressionGain = (value) => {
    compression.value.gain = Math.max(0, Math.min(100, value))
    // Convert to dB: 50 = 0dB, 0 = -20dB, 100 = +20dB
    compression.value.gainDB = (compression.value.gain - 50) * 0.4
  }

  const updatePeakReduction = (value) => {
    compression.value.peakReduction = Math.max(0, Math.min(100, value))
  }

  const updateNeedlePosition = (position) => {
    compression.value.needlePosition = position
    compression.value.isCompressing = position < -1 // Compressing if needle moved more than 1 degree
  }

  const toggleMeterMode = () => {
    compression.value.meterMode = compression.value.meterMode === 'GR' ? 'VU' : 'GR'
  }

  const updateSmoothingFactor = (value) => {
    compression.value.smoothingFactor = Math.max(0, Math.min(100, value))
    // Convert to 0-1 range for actual use
    compression.value.smoothingMultiplier = compression.value.smoothingFactor / 100
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
    
    // SVG parameter overlay state
    trackName,
    pluginName,
    vuMeterValue,
    needleAngle,
    dimmerOpacity,
    backgroundBrightness,
    parameterAnimation,
    
    // Hardware state
    hardwareConnected,
    
    // Compression state
    compression,
    
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
    
    // Compression methods
    updateCompressionGain,
    updatePeakReduction,
    updateNeedlePosition,
    toggleMeterMode,
    updateSmoothingFactor,
    
    // Legacy methods (for backward compatibility)
    updateDisplay,
    stopInteraction
  }
}) 