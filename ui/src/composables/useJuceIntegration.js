import { ref } from 'vue'
import { getNativeFunction } from '../juce/index.js'

export function useJuceIntegration(state = null) {
  // Default values for when no state is provided (used by Header component)
  const defaultPluginInfo = ref({
    vendor: 'Mastri Design Engineering',
    pluginName: 'MastrCtrl',
    pluginVersion: '1.0.0'
  })

  const isDevelopment = ref(!window.__JUCE__ || import.meta.env.DEV)

  // If state is provided, use it; otherwise use defaults
  const pluginInfo = state?.pluginInfo || defaultPluginInfo

  // VST Host plugin state
  const vstPluginState = ref({
    isLoaded: false,
    pluginName: '',
    parameters: []
  })

  const initializeJuceStates = async () => {
    if (window.__JUCE__) {
      console.log('JUCE detected - using real native functions')
      // C++ will automatically call window.updatePluginState when ready
    } else {
      console.warn('JUCE not available - running in development mode')
      // Mock some parameters for development
      setTimeout(() => {
        if (window.updatePluginState) {
          window.updatePluginState({
            parameters: [
              { index: 0, name: 'Gain', currentValue: 0.5, defaultValue: 0.5, isAutomatable: true },
              { index: 1, name: 'Bypass', currentValue: 0.0, defaultValue: 0.0, isAutomatable: true },
              { index: 2, name: 'Filter', currentValue: 0.75, defaultValue: 0.5, isAutomatable: true }
            ]
          })
        }
      }, 100)
    }
  }

  const loadVSTPlugin = () => {
    if (window.__JUCE__) {
      // Use real JUCE native function
      const loadVST = getNativeFunction('loadVST')
      loadVST()
        .then(result => {
          console.log('VST load result:', result)
        })
        .catch(error => {
          console.error('Failed to request VST load:', error)
        })
    } else {
      console.log('Development mode: Load VST plugin requested')
    }
  }

  const setVSTParameter = (parameterIndex, value) => {
    if (window.__JUCE__) {
      // Use real JUCE native function
      const setParameter = getNativeFunction('setParameter')
      setParameter(parameterIndex, value)
        .then(result => {
          console.log('Parameter sent to C++:', result)
        })
        .catch(error => {
          console.error('Failed to send parameter to C++:', error)
        })
    } else {
      console.log('Development mode: Set parameter', parameterIndex, value)
    }
  }

  const getVSTPluginState = () => {
    return vstPluginState.value
  }

  const updateVSTPluginState = (isLoaded, pluginName, parameters = []) => {
    vstPluginState.value = {
      isLoaded,
      pluginName,
      parameters
    }
  }

  const updateVSTParameter = (parameterIndex, value) => {
    const param = vstPluginState.value.parameters.find(p => p.index === parameterIndex)
    if (param) {
      param.currentValue = value
    }
  }

  return {
    pluginInfo,
    isDevelopment,
    vstPluginState,
    initializeJuceStates,
    loadVSTPlugin,
    setVSTParameter,
    getVSTPluginState,
    updateVSTPluginState,
    updateVSTParameter
  }
}
