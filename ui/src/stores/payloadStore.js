import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const usePayloadStore = defineStore('payload', () => {
  // Payload configuration
  const ledCount = ref(16) // Number of LEDs in the ring
  const maxBrightness = ref(255)
  const defaultColor = ref({ r: 0, g: 0, b: 0 })
  
  // Payload state
  const lastPayload = ref(null)
  const payloadHistory = ref([])
  const maxHistorySize = 50

  // Computed
  const isPayloadValid = computed(() => {
    return lastPayload.value !== null && lastPayload.value.type
  })

  // Methods
  const createLEDPayload = (ledIndex, color, brightness = null) => {
    const payload = {
      type: 'led_set',
      led: ledIndex,
      color: {
        r: Math.min(255, Math.max(0, color.r || 0)),
        g: Math.min(255, Math.max(0, color.g || 0)),
        b: Math.min(255, Math.max(0, color.b || 0))
      },
      brightness: brightness !== null ? Math.min(255, Math.max(0, brightness)) : maxBrightness.value,
      timestamp: Date.now()
    }
    
    addToHistory(payload)
    return payload
  }

  const createRingPayload = (colors, brightness = null) => {
    if (!Array.isArray(colors) || colors.length !== ledCount.value) {
      throw new Error(`Ring payload requires exactly ${ledCount.value} colors`)
    }

    const payload = {
      type: 'ring_set',
      leds: colors.map((color, index) => ({
        led: index,
        color: {
          r: Math.min(255, Math.max(0, color.r || 0)),
          g: Math.min(255, Math.max(0, color.g || 0)),
          b: Math.min(255, Math.max(0, color.b || 0))
        }
      })),
      brightness: brightness !== null ? Math.min(255, Math.max(0, brightness)) : maxBrightness.value,
      timestamp: Date.now()
    }
    
    addToHistory(payload)
    return payload
  }

  const createParameterPayload = (parameterName, value, ledIndex = null) => {
    const payload = {
      type: 'parameter_update',
      parameter: parameterName,
      value: value,
      led: ledIndex,
      timestamp: Date.now()
    }
    
    addToHistory(payload)
    return payload
  }

  const createSystemPayload = (command, data = {}) => {
    const payload = {
      type: 'system',
      command: command,
      data: data,
      timestamp: Date.now()
    }
    
    addToHistory(payload)
    return payload
  }

  const createClearPayload = (ledIndex = null) => {
    const payload = {
      type: 'led_clear',
      led: ledIndex, // null for all LEDs
      timestamp: Date.now()
    }
    
    addToHistory(payload)
    return payload
  }

  const createBrightnessPayload = (brightness, ledIndex = null) => {
    const payload = {
      type: 'brightness_set',
      brightness: Math.min(255, Math.max(0, brightness)),
      led: ledIndex, // null for all LEDs
      timestamp: Date.now()
    }
    
    addToHistory(payload)
    return payload
  }

  const addToHistory = (payload) => {
    lastPayload.value = payload
    payloadHistory.value.unshift(payload)
    
    // Keep history size manageable
    if (payloadHistory.value.length > maxHistorySize) {
      payloadHistory.value = payloadHistory.value.slice(0, maxHistorySize)
    }
  }

  const clearHistory = () => {
    payloadHistory.value = []
    lastPayload.value = null
  }

  const getPayloadHistory = (limit = 10) => {
    return payloadHistory.value.slice(0, limit)
  }

  const validatePayload = (payload) => {
    if (!payload || typeof payload !== 'object') {
      return { valid: false, error: 'Payload must be an object' }
    }

    if (!payload.type) {
      return { valid: false, error: 'Payload must have a type' }
    }

    switch (payload.type) {
      case 'led_set':
        if (typeof payload.led !== 'number' || payload.led < 0 || payload.led >= ledCount.value) {
          return { valid: false, error: `LED index must be 0-${ledCount.value - 1}` }
        }
        if (!payload.color || typeof payload.color !== 'object') {
          return { valid: false, error: 'LED payload must have color object' }
        }
        break
        
      case 'ring_set':
        if (!Array.isArray(payload.leds) || payload.leds.length !== ledCount.value) {
          return { valid: false, error: `Ring payload must have exactly ${ledCount.value} LEDs` }
        }
        break
        
      case 'parameter_update':
        if (!payload.parameter || typeof payload.parameter !== 'string') {
          return { valid: false, error: 'Parameter payload must have parameter name' }
        }
        break
        
      case 'system':
        if (!payload.command || typeof payload.command !== 'string') {
          return { valid: false, error: 'System payload must have command' }
        }
        break
    }

    return { valid: true }
  }

  const parseIncomingPayload = (data) => {
    try {
      const payload = typeof data === 'string' ? JSON.parse(data) : data
      const validation = validatePayload(payload)
      
      if (!validation.valid) {
        console.error('Invalid payload received:', validation.error)
        return null
      }
      
      return payload
    } catch (error) {
      console.error('Failed to parse payload:', error)
      return null
    }
  }

  return {
    // State
    ledCount,
    maxBrightness,
    defaultColor,
    lastPayload,
    payloadHistory,
    
    // Computed
    isPayloadValid,
    
    // Methods
    createLEDPayload,
    createRingPayload,
    createParameterPayload,
    createSystemPayload,
    createClearPayload,
    createBrightnessPayload,
    addToHistory,
    clearHistory,
    getPayloadHistory,
    validatePayload,
    parseIncomingPayload
  }
}) 