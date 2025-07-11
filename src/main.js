import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import MainView from './views/MainView.vue'
import VirtualHardwareView from './views/VirtualHardwareView.vue'
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

// Global functions that C++ calls via evaluateJavascript
window.updatePluginState = function(pluginState) {
  console.log('Received plugin state from C++:', pluginState)
  
  // Update JUCE composable
  juceIntegration.updateVSTPluginState(true, 'Loaded VST Plugin', pluginState.parameters)
  
  // Convert C++ parameter format to Vue store format
  const storeParams = pluginState.parameters.map(param => {
    const value = param.currentValue || param.value || 0
    const name = param.name
    const color = getDefaultColor(name)
    
    return {
      id: param.index,
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
  
  // Populate parameter store
  parameterStore.parameters = storeParams
  console.log(`Updated parameter store with ${storeParams.length} parameters`)
}

window.updateParameterValue = function(parameterIndex, value) {
  console.log(`Received parameter update from C++: ${parameterIndex} = ${value}`)
  
  // Update JUCE composable
  juceIntegration.updateVSTParameter(parameterIndex, value)
  
  // Update parameter store (find parameter by index, update by id)
  const param = parameterStore.parameters.find(p => p.index === parameterIndex || p.id === parameterIndex)
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
