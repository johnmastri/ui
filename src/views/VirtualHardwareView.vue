<template>
  <div class="virtual-hardware-view">
    <!-- Header -->
    <Header />
    
    <!-- WebSocket Status Bar -->
    <WebSocketStatusBar />
    
    <!-- Mock Display -->
    <HardwareDisplay />
    
    <!-- Parameter Controls -->
    <div class="parameter-section">
      <h3 class="section-title">Master Unit Controls</h3>
      <div class="parameter-grid">
        <ParameterKnob 
          v-for="parameter in parameters" 
          :key="parameter.id"
          :paramId="parameter.id"
          theme="dark"
          @value-changed="handleParameterValueChanged"
          @color-changed="handleParameterColorChanged"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, watch } from 'vue'
import Header from '../components/Header.vue'
import WebSocketStatusBar from '../components/WebSocketStatusBar.vue'
import HardwareDisplay from '../components/HardwareDisplay.vue'
import ParameterKnob from '../components/ParameterKnob.vue'
import { useHardwareStore } from '../stores/hardwareStore'
import { usePayloadStore } from '../stores/payloadStore'
import { useParameterStore } from '../stores/parameterStore'
import { useWebSocketStore } from '../stores/websocketStore'

const hardwareStore = useHardwareStore()
const payloadStore = usePayloadStore()
const parameterStore = useParameterStore()
const websocketStore = useWebSocketStore()

// Helper functions (defined before use)
const formatValue = (value, format) => {
  switch (format) {
    case 'percentage':
      return `${Math.round(value * 100)}%`
    case 'decibel':
      return `${value.toFixed(1)} dB`
    default:
      return value.toFixed(2)
  }
}

const getParameterColor = (value) => {
  // Color gradient based on parameter value
  const intensity = Math.round(value * 255)
  return {
    r: intensity,
    g: Math.round(intensity * 0.7),
    b: Math.round(intensity * 0.3)
  }
}

// Use parameters from store (populated via WebSocket)
const parameters = computed(() => {
  return parameterStore.parameters
})

// Watch for parameter changes
watch(parameters, (newParams, oldParams) => {

}, { deep: true })

// Methods
const handleParameterValueChanged = (parameterData) => {
  // Handle both old format (value, paramId) and new format (object)
  let value, paramId
  if (typeof parameterData === 'object' && parameterData.value !== undefined) {
    value = parameterData.value
    paramId = parameterData.paramId || parameterData.id
  } else {
    // Legacy format support
    value = arguments[0]
    paramId = arguments[1]
  }
  
 
  // Note: Parameter store update will trigger hardware display via data watcher
  // This just handles WebSocket broadcast and LED updates
  
  // Send hardware command payload
  const payload = payloadStore.createParameterPayload(paramId, value)
  hardwareStore.sendHardwareCommand(payload)
  
  // Create LED payload for visual feedback
  const ledIndex = parameters.value.findIndex(p => p.id === paramId)
  if (ledIndex !== -1) {
    const color = getParameterColor(value)
    const ledPayload = payloadStore.createLEDPayload(ledIndex, color)
    hardwareStore.sendHardwareCommand(ledPayload)
  }
}

const handleParameterColorChanged = (color) => {
  // Handle color changes if needed

}

// Lifecycle
onMounted(() => {
 
  // Initialize WebSocket handlers for parameter synchronization
  parameterStore.initWebSocketHandlers()
  
  // Initialize hardware store parameter watcher
  hardwareStore.initParameterWatcher()
  
  // Force WebSocket connection if not connected
  if (!websocketStore.isConnected) {
   
    websocketStore.connect()
  }
  
  // Request current parameter state from other clients
  setTimeout(() => {
  
    const requestPayload = {
      type: 'request_parameter_state',
      timestamp: Date.now()
    }
    websocketStore.send(requestPayload)
  }, 1000) // Wait 1 second for connection to stabilize
  
  // Initialize display with VU meter
  hardwareStore.fadeToUVMeter()
  
 
})
</script>

<style scoped>
.virtual-hardware-view {
  min-height: 100vh;
  background: #0a0a0a;
  color: #ffffff;
  padding: 20px;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  overflow-y: auto; /* Enable vertical scrolling */
  overflow-x: hidden; /* Prevent horizontal scrolling */
  -webkit-overflow-scrolling: touch; /* Smooth scrolling on iOS */
}

.parameter-section {
  margin-top: 20px;
}

.section-title {
  font-size: 1.5em;
  font-weight: bold;
  color: #00ffff;
  text-shadow: 0 0 10px rgba(0, 255, 255, 0.5);
  margin-bottom: 20px;
  text-align: center;
}

.parameter-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 20px;
  max-width: 800px;
  margin: 0 auto;
}

/* Dark theme overrides for child components */
.virtual-hardware-view :deep(.control-group) {
  background: #1a1a1a;
  border-color: #333;
}

.virtual-hardware-view :deep(.plugin-title) {
  color: #00ff00;
}

.virtual-hardware-view :deep(.plugin-meta) {
  color: #cccccc;
}

.virtual-hardware-view :deep(.websocket-status-bar) {
  background: #1a1a1a;
  border-color: #333;
}

.virtual-hardware-view :deep(.status-label) {
  color: #cccccc;
}

/* Responsive design */
@media (max-width: 768px) {
  .virtual-hardware-view {
    padding: 10px;
    height: 100vh; /* Ensure full height on mobile */
    width: 100vw; /* Ensure full width on mobile */
    box-sizing: border-box; /* Include padding in dimensions */
  }
  
  .parameter-grid {
    grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
    gap: 15px;
    padding-bottom: 20px; /* Add bottom padding for scroll space */
  }
  
  .section-title {
    font-size: 1.3em;
    margin-bottom: 15px; /* Reduce margin on mobile */
  }
  
  .parameter-section {
    margin-top: 15px; /* Reduce top margin on mobile */
  }
}
</style> 