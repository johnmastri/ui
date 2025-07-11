import { ref } from 'vue'

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
    // Set up VST host interface
    if (window.nativeInterface) {
      // Request initial plugin state from C++
      window.nativeInterface.requestState()
    } else if (!window.__JUCE__) {
      console.warn('JUCE not available - running in development mode')
      // Set up mock interface for development
      window.nativeInterface = {
        loadPlugin: () => console.log('DEV: Load plugin requested'),
        setParameter: (index, value) => console.log('DEV: Set parameter', index, value),
        requestState: () => {
          // Mock loaded plugin state for development
          if (window.vueApp) {
            window.vueApp.setPluginState(true, 'Mock Plugin (Development)')
            window.vueApp.setParameters([
              { index: 0, name: 'Gain', label: 'dB', currentValue: 0.5 },
              { index: 1, name: 'Bypass', label: '', currentValue: 0.0 },
              { index: 2, name: 'Filter', label: 'Hz', currentValue: 0.75 }
            ])
          }
        }
      }
    }
  }

  const loadVSTPlugin = () => {
    if (window.nativeInterface) {
      window.nativeInterface.loadPlugin()
    } else {
      console.log('Development mode: Load VST plugin requested')
    }
  }

  const setVSTParameter = (parameterIndex, value) => {
    if (window.nativeInterface) {
      window.nativeInterface.setParameter(parameterIndex, value)
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
