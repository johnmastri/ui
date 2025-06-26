<template>
  <div class="virtual-hardware-view">
    <!-- Header -->
    <Header />
    
    <!-- WebSocket Status Bar -->
    <WebSocketStatusBar />
    
    <!-- Mock Display -->
    <MockDisplay />
    
    <!-- Parameter Controls -->
    <div class="parameter-section">
      <h3 class="section-title">Master Unit Controls</h3>
      <div class="parameter-grid">
        <ParameterKnob 
          v-for="parameter in masterParameters" 
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
import { ref, onMounted } from 'vue'
import Header from '../components/Header.vue'
import WebSocketStatusBar from '../components/WebSocketStatusBar.vue'
import MockDisplay from '../components/MockDisplay.vue'
import ParameterKnob from '../components/ParameterKnob.vue'
import { useHardwareStore } from '../stores/hardwareStore'
import { usePayloadStore } from '../stores/payloadStore'
import { useParameterStore } from '../stores/parameterStore'

const hardwareStore = useHardwareStore()
const payloadStore = usePayloadStore()
const parameterStore = useParameterStore()

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

// Initialize parameters in the store immediately
const masterParameters = ref([
  {
    id: 'gain',
    name: 'Gain',
    value: 1.0,
    min: 0,
    max: 1,
    step: 0.01,
    format: 'percentage'
  },
  {
    id: 'bass',
    name: 'Bass',
    value: 0.5,
    min: 0,
    max: 1,
    step: 0.01,
    format: 'percentage'
  },
  {
    id: 'mid',
    name: 'Mid',
    value: 0.5,
    min: 0,
    max: 1,
    step: 0.01,
    format: 'percentage'
  },
  {
    id: 'treble',
    name: 'Treble',
    value: 0.5,
    min: 0,
    max: 1,
    step: 0.01,
    format: 'percentage'
  },
  {
    id: 'drive',
    name: 'Drive',
    value: 0.0,
    min: 0,
    max: 1,
    step: 0.01,
    format: 'percentage'
  },
  {
    id: 'volume',
    name: 'Volume',
    value: 0.7,
    min: 0,
    max: 1,
    step: 0.01,
    format: 'percentage'
  }
])

// Initialize parameters in the store immediately
masterParameters.value.forEach(param => {
  parameterStore.addParameter({
    id: param.id,
    name: param.name,
    value: param.value,
    text: formatValue(param.value, param.format),
    min: param.min,
    max: param.max,
    step: param.step
  })
})

// Methods
const handleParameterValueChanged = (value, paramId) => {
  // The ParameterKnob component handles the store update internally
  // We just need to handle the display and WebSocket communication
  const parameter = parameterStore.getParameterById(paramId)
  if (parameter) {
    const displayValue = formatValue(value, 'percentage') // Default to percentage format
    hardwareStore.updateDisplay(parameter.name, displayValue)
    
    // Send payload to hardware
    const payload = payloadStore.createParameterPayload(paramId, value)
    hardwareStore.sendHardwareCommand(payload)
    
    // Create LED payload for visual feedback
    const ledIndex = masterParameters.value.findIndex(p => p.id === paramId)
    if (ledIndex !== -1) {
      const color = getParameterColor(value)
      const ledPayload = payloadStore.createLEDPayload(ledIndex, color)
      hardwareStore.sendHardwareCommand(ledPayload)
    }
  }
}

const handleParameterColorChanged = (color) => {
  // Handle color changes if needed
  console.log('Parameter color changed:', color)
}

// Lifecycle
onMounted(() => {
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
  }
  
  .parameter-grid {
    grid-template-columns: repeat(auto-fit, minmax(100px, 1fr));
    gap: 15px;
  }
  
  .section-title {
    font-size: 1.3em;
  }
}
</style> 