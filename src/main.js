import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import MainView from './views/MainView.vue'
import VirtualHardwareView from './views/VirtualHardwareView.vue'
import HardwareView from './views/HardwareView.vue'
import './style.css'

// Mock JUCE for development
if (!window.__JUCE__) {
  console.log('JUCE not detected - creating development mock')
  window.__JUCE__ = {
    initialisationData: {
      vendor: 'WolfSound',
      pluginName: 'JuceWebViewPlugin (Dev)',
      pluginVersion: '1.0.0-dev',
      devicePixelRatio: window.devicePixelRatio || 1
    },
    backend: {
      addEventListener: (event, callback) => {
        console.log(`Mock: addEventListener for ${event}`)
      },
      emitEvent: (event, data) => {
        console.log(`Mock: emitEvent ${event}`, data)
      }
    }
  }
}

// Router configuration
const routes = [
  {
    path: '/',
    name: 'Main',
    component: MainView
  },
  {
    path: '/virtual',
    name: 'VirtualHardware',
    component: VirtualHardwareView
  },
  {
    path: '/hardware',
    name: 'Hardware',
    component: HardwareView
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Initialize Vue app
console.log('Initializing Vue app...')
const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(router)
app.mount('#app')
console.log('Vue app mounted!')

// Set up JUCE bridge after Vue is mounted
import { useJuceIntegration } from './composables/useJuceIntegration.js'
import { useParameterStore } from './stores/parameterStore.js'

const juceIntegration = useJuceIntegration()
const parameterStore = useParameterStore(pinia)

// Initialize WebSocket handlers for parameter synchronization
parameterStore.initWebSocketHandlers()

// Request parameter state from other clients when page loads
import { useWebSocketStore } from './stores/websocketStore.js'
const websocketStore = useWebSocketStore()

// Function to request parameter state from other clients
const requestParameterState = () => {
  console.log('📡 Requesting current parameter state from other clients...')
  const requestPayload = {
    type: 'request_parameter_state',
    timestamp: Date.now()
  }
  websocketStore.send(requestPayload)
  
  // Set a timeout to log if no response is received
  setTimeout(() => {
    if (parameterStore.parameters.length === 0) {
      console.log('📡 No parameter state received from other clients after 5 seconds')
      console.log('📡 This is normal if no other clients have parameters loaded')
    }
  }, 5000)
}

// Add connection listener to request parameters when WebSocket connects
websocketStore.addConnectionListener(() => {
  // Wait a short delay to ensure connection is fully established
  setTimeout(requestParameterState, 500)
})

// If already connected, request parameters immediately
if (websocketStore.isConnected) {
  setTimeout(requestParameterState, 1000)
}

// Global functions that C++ calls via evaluateJavascript
window.updatePluginState = function(pluginState) {
  console.log('Received plugin state from C++:', pluginState)
  
  // ALWAYS CLEAR PREVIOUS PARAMETERS FIRST - broadcasts clear to all clients
  console.log('📡 Clearing previous parameters and broadcasting to all connected clients...')
  parameterStore.clearParameters()
  
  // If no parameters provided (VST unloaded), just clear and exit
  if (!pluginState.parameters || pluginState.parameters.length === 0) {
    console.log('No parameters provided - VST unloaded or no parameters')
    juceIntegration.updateVSTPluginState(false, 'No VST Loaded', [])
    console.log('📡 All connected clients now show empty parameter list')
    return
  }
  
  console.log(`Processing ${pluginState.parameters.length} new parameters...`)
  
  // Update JUCE composable
  juceIntegration.updateVSTPluginState(true, 'Loaded VST Plugin', pluginState.parameters)
  
  // Convert C++ parameter format to Vue store format
  const storeParams = pluginState.parameters
    .filter(param => {
      // Filter out MIDI CC parameters
      if (param.name && param.name.includes('MIDI CC')) {
        console.log(`Filtering out MIDI CC parameter from C++: ${param.name}`)
        return false
      }
      return true
    })
    .map(param => {
      const value = param.currentValue || param.value || 0
      const name = param.name
      const color = getDefaultColor(name)
      
      return {
        id: `param-${param.index}`, // Use string-based ID for consistency
        index: param.index, // Keep the original index for lookup
        name: name,
        value: value,
        min: 0,
        max: 1,
        step: 0.01,
        format: 'percentage',
        defaultValue: param.defaultValue || 0.5,
        color: color,
        rgbColor: hexToRgb(color),
        text: generateParameterText(name, value),
        ledCount: 28,
        isAutomatable: param.isAutomatable !== false
      }
    })
  
  // Set parameters and broadcast to all WebSocket clients
  parameterStore.setParameters(storeParams)
  console.log(`📡 All connected clients now have ${storeParams.length} fresh parameters (filtered from ${pluginState.parameters.length})`)
}

window.updateParameterValue = function(parameterIndex, value) {
  console.log(`Received parameter update from C++: ${parameterIndex} = ${value}`)
  
  // Update JUCE composable
  juceIntegration.updateVSTParameter(parameterIndex, value)
  
  // Update parameter store (find parameter by index, update by string ID)
  const param = parameterStore.parameters.find(p => p.index === parameterIndex)
  if (param) {
    parameterStore.updateParameterFromJuce(param.id, value) // Use new method that doesn't send back to C++
  } else {
    console.warn(`Parameter with index ${parameterIndex} not found in store`)
  }
}

// Helper function to get default colors
function getDefaultColor(paramName) {
  const colorPresets = {
    'Input Gain': '#4CAF50',
    'Drive': '#FF5722',
    'Tone': '#2196F3',
    'Output Level': '#9C27B0',
    'Mix': '#FF9800',
    'Attack': '#00BCD4',
    'Release': '#3F51B5',
    'Threshold': '#E91E63',
    'Ratio': '#795548',
    'Knee': '#607D8B'
  }
  
  if (!paramName) return '#808080'
  
  const name = paramName.toLowerCase()
  for (const [key, color] of Object.entries(colorPresets)) {
    if (name.includes(key.toLowerCase())) {
      return color
    }
  }
  return '#808080' // Default gray
}

// Helper function to convert hex to RGB
function hexToRgb(hex) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  return result ? {
    r: parseInt(result[1], 16),
    g: parseInt(result[2], 16),
    b: parseInt(result[3], 16)
  } : { r: 128, g: 128, b: 128 }
}

// Helper function to generate parameter text
function generateParameterText(name, value) {
  switch (name) {
    case "Input Gain":
    case "Drive":
    case "Tone":
    case "Output Level":
    case "Mix":
      return Math.round(value * 100) + '%'
    case "Attack":
      return Math.round(value * 100) + 'ms'
    case "Release":
      return Math.round(value * 200) + 'ms'
    case "Threshold":
      return Math.round((value - 0.5) * 48) + 'dB'
    case "Ratio":
      const ratios = ['1:1', '2:1', '4:1', '8:1', '16:1', '∞:1']
      const ratioIndex = Math.floor(value * (ratios.length - 1))
      return ratios[ratioIndex]
    case "Knee":
      const knees = ['Hard', 'Soft', 'Medium']
      const kneeIndex = Math.floor(value * (knees.length - 1))
      return knees[kneeIndex]
    default:
      return Math.round(value * 100) + '%'
  }
}

console.log('JUCE bridge functions registered')

// Initialize JUCE states
juceIntegration.initializeJuceStates()
