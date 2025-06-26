import { ref } from 'vue'

export function useJuceIntegration(state = null) {
  // Default values for when no state is provided (used by Header component)
  const defaultPluginInfo = ref({
    vendor: 'WolfSound',
    pluginName: 'MastrCtrl',
    pluginVersion: '1.0.0'
  })

  const isDevelopment = ref(!window.__JUCE__ || import.meta.env.DEV)

  // If state is provided, use it; otherwise use defaults
  const pluginInfo = state?.pluginInfo || defaultPluginInfo

  // JUCE state objects
  let sliderState, bypassToggleState, distortionTypeComboBoxState, nativeFunction

  const initializeJuceStates = async () => {
    if (!window.__JUCE__) {
      console.warn('JUCE not available - running in development mode')
      return
    }

    try {
      // In development mode, JUCE library might not be available
      // Try to import it, but handle gracefully if it fails
      let Juce = null

      // Check if we're in a WebView context (has JUCE) vs browser context
      const isInWebView = window.__JUCE__ && window.__JUCE__.initialisationData

      if (isInWebView) {
        try {
          const juceModule = await import('../juce/index.js')
          Juce = juceModule.default || juceModule
        } catch (error) {
          console.log('JUCE library import failed:', error)
          return
        }
      } else {
        console.log('Running in browser development mode - JUCE integration disabled')
        return
      }

      // Only initialize if state is provided
      if (!state) return

      const {
        gainValue,
        gainStep,
        bypassValue,
        distortionValue,
        distortionChoices,
        emittedCount,
        addDebugMessage
      } = state

      // Gain slider
      sliderState = Juce.getSliderState("GAIN")
      if (sliderState) {
        gainStep.value = 1 / sliderState.properties.numSteps
        gainValue.value = sliderState.getNormalisedValue()

        sliderState.valueChangedEvent.addListener(() => {
          gainValue.value = sliderState.getNormalisedValue()
        })
      }

      // Bypass toggle
      bypassToggleState = Juce.getToggleState("BYPASS")
      if (bypassToggleState) {
        bypassValue.value = bypassToggleState.getValue()

        bypassToggleState.valueChangedEvent.addListener(() => {
          bypassValue.value = bypassToggleState.getValue()
        })
      }

      // Distortion type combo box
      distortionTypeComboBoxState = Juce.getComboBoxState("DISTORTION_TYPE")
      if (distortionTypeComboBoxState) {
        distortionTypeComboBoxState.propertiesChangedEvent.addListener(() => {
          distortionChoices.value = [...distortionTypeComboBoxState.properties.choices]
        })

        distortionTypeComboBoxState.valueChangedEvent.addListener(() => {
          distortionValue.value = distortionTypeComboBoxState.getChoiceIndex()
        })

        // Initial values
        distortionChoices.value = [...distortionTypeComboBoxState.properties.choices]
        distortionValue.value = distortionTypeComboBoxState.getChoiceIndex()
      }

      // Native function
      nativeFunction = Juce.getNativeFunction("nativeFunction")
    } catch (error) {
      console.error('Failed to initialize JUCE states:', error)
    }
  }

  const updateGain = () => {
    if (!state) return
    if (sliderState) {
      sliderState.setNormalisedValue(state.gainValue.value)
    } else {
      console.log('Development mode: Gain updated to', state.gainValue.value)
    }
  }

  const updateBypass = () => {
    if (!state) return
    if (bypassToggleState) {
      bypassToggleState.setValue(state.bypassValue.value)
    } else {
      console.log('Development mode: Bypass updated to', state.bypassValue.value)
    }
  }

  const updateDistortion = () => {
    if (!state) return
    if (distortionTypeComboBoxState) {
      distortionTypeComboBoxState.setChoiceIndex(state.distortionValue.value)
    } else {
      console.log('Development mode: Distortion updated to', state.distortionValue.value)
    }
  }

  const callNativeFunction = () => {
    if (state?.addDebugMessage) state.addDebugMessage('Vue: Calling native C++ function...')
    if (nativeFunction) {
      nativeFunction("Vue.js", "calling", "C++").then((result) => {
        if (state?.addDebugMessage) state.addDebugMessage(`Vue: Native function result: ${result}`)
      }).catch((error) => {
        if (state?.addDebugMessage) state.addDebugMessage(`Vue: Native function error: ${error}`)
      })
    } else {
      if (state?.addDebugMessage) state.addDebugMessage('Vue: Development mode - Native function called with Vue.js args')
    }
  }

  const emitEvent = () => {
    if (!state) return
    state.emittedCount.value++
    if (state.addDebugMessage) state.addDebugMessage(`Vue: Emitting event with count: ${state.emittedCount.value}`)
    if (window.__JUCE__) {
      window.__JUCE__.backend.emitEvent("exampleJavaScriptEvent", {
        emittedCount: state.emittedCount.value,
      })
      if (state.addDebugMessage) state.addDebugMessage('Vue: Event emitted to JUCE backend')
    } else {
      if (state.addDebugMessage) state.addDebugMessage('Vue: Development mode - Event emitted with count ' + state.emittedCount.value)
    }
  }

  return {
    pluginInfo,
    isDevelopment,
    initializeJuceStates,
    updateGain,
    updateBypass,
    updateDistortion,
    callNativeFunction,
    emitEvent
  }
}
