import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useHardwareSettingsStore = defineStore('hardwareSettings', () => {
  // Settings menu buttons with opacity variations (keep existing)
  const buttons = ref([
    { id: 'device', label: 'DEVICE', x: 0, y: 0, defaultOpacity: 0.45 },      // -33%
    { id: 'network', label: 'NETWORK', x: 400, y: 0, defaultOpacity: 0.85 },  // +27%
    { id: 'display', label: 'DISPLAY', x: 0, y: 240, defaultOpacity: 0.67 },  // base
    { id: 'midi', label: 'MIDI', x: 400, y: 240, defaultOpacity: 0.55 }       // -18%
  ])
  
  // Settings with parameters (new)
  const settings = ref([
    {
      id: 'device',
      parameters: [
        {
          id: 'deviceName',
          label: 'Device Name',
          type: 'button',
          value: 'MastrCtrl Unit 1'
        },
        {
          id: 'firmwareVersion',
          label: 'Firmware Version',
          type: 'display',
          value: 'v1.0.0'
        },
        {
          id: 'updateFirmware',
          label: 'Update Firmware',
          type: 'button',
          value: 'UPDATE'
        },
        {
          id: 'factoryReset',
          label: 'Factory Reset',
          type: 'button',
          value: 'RESET'
        }
      ]
    },
    {
      id: 'network',
      parameters: [
        {
          id: 'connectionMode',
          label: 'Connection Mode',
          type: 'display',
          value: 'Master'
        },
        {
          id: 'deviceAddress',
          label: 'Device Address',
          type: 'select',
          value: '1',
          options: ['1', '2', '3', '4', '5', '10', '50', '100', '255']
        },
      ]
    },
    {
      id: 'display',
      parameters: [
        {
          id: 'brightness',
          label: 'Brightness',
          type: 'select',
          value: '75%',
          options: ['25%', '50%', '75%', '100%']
        },
        {
          id: 'theme',
          label: 'Theme',
          type: 'select',
          value: 'Dark',
          options: ['Light', 'Dark', 'High Contrast']
        }
      ]
    },
    {
      id: 'midi',
      parameters: [
        {
          id: 'mode',
          label: 'Mode',
          type: 'select',
          value: 'MIDI',
          options: ['MIDI', 'Serial Protocol']
        },
        {
          id: 'channel',
          label: 'Channel',
          type: 'select',
          value: 'Global',
          options: ['Global', 'Per Encoder']
        },
        {
          id: 'thru',
          label: 'Thru',
          type: 'toggle',
          value: true
        }
      ]
    }
  ])
  
  // Currently hovered button - default to device
  const currentSelectedButton = ref('device')
  
  // Currently active menu (which menu we're in when in parameters mode)
  const currentMenu = ref('device')
  
  // Currently selected parameter index for mouse wheel navigation (includes back button)
  const selectedParameterIndex = ref(0)
  
  // Navigation mode: 'menu' | 'parameters' | 'modal'
  const navigationMode = ref('menu')
  
  // Track if back button is selected during parameter navigation
  const isBackButtonSelected = ref(false)
  
  // Focus mode state for SettingsSelect
  const isSelectFocused = ref(false)
  const highlightedSelectIndex = ref(0)
  const focusedParameterId = ref(null)
  
  const setNavigationMode = (mode) => {
    navigationMode.value = mode
    // Reset back button selection when switching modes
    if (mode === 'menu') {
      isBackButtonSelected.value = false
      selectedParameterIndex.value = 0
    }
  }
  
  const setBackButtonSelected = (selected) => {
    isBackButtonSelected.value = selected
  }

  // Helper: get current parameters for selected button
  const currentParameters = computed(() => {
    const setting = getSettingForButton(currentMenu.value)
    return setting ? setting.parameters : []
  })

  // Helper: total selectable items (parameters + 1 for back button when in parameters mode)
  const totalSelectableItems = computed(() => {
    if (navigationMode.value === 'parameters') {
      return currentParameters.value.length + 1 // +1 for back button
    }
    return currentParameters.value.length
  })

  // Actions
  const setHoveredButton = (buttonId) => {
    currentSelectedButton.value = buttonId
    selectedParameterIndex.value = 0 // Reset to first parameter when changing settings
  }
  
  const setCurrentMenu = (menuId) => {
    currentMenu.value = menuId
  }
  
  const clearHoveredButton = () => {
    currentSelectedButton.value = 'device'
    selectedParameterIndex.value = 0
  }

  const setSelectedParameterIndex = (index) => {
    // Clamp index between 0 and totalSelectableItems-1
    if (index < 0) index = totalSelectableItems.value - 1
    if (index >= totalSelectableItems.value) index = 0
    selectedParameterIndex.value = index
  }
  
  // Helper function to get settings for a button
  const getSettingForButton = (buttonId) => {
    return settings.value.find(s => s.id === buttonId)
  }
  
  // Focus mode actions
  const setSelectFocusMode = (focused, parameterId = null) => {
    console.log('Store: setSelectFocusMode called', focused, parameterId)
    isSelectFocused.value = focused
    focusedParameterId.value = parameterId
    if (focused && parameterId) {
      // Find the parameter and set initial highlighted index
      const setting = getSettingForButton(currentMenu.value)
      if (setting) {
        const parameter = setting.parameters.find(p => p.id === parameterId)
        if (parameter && parameter.options) {
          highlightedSelectIndex.value = parameter.options.indexOf(parameter.value)
          if (highlightedSelectIndex.value === -1) highlightedSelectIndex.value = 0
          console.log('Store: Set highlighted index to', highlightedSelectIndex.value)
        }
      }
    } else {
      highlightedSelectIndex.value = 0
    }
    console.log('Store: Focus mode state updated', isSelectFocused.value, focusedParameterId.value)
  }
  
  const updateHighlightedSelectIndex = (delta) => {
    console.log('Store: updateHighlightedSelectIndex called with delta:', delta)
    console.log('Store: isSelectFocused:', isSelectFocused.value, 'focusedParameterId:', focusedParameterId.value)
    
    if (!isSelectFocused.value || !focusedParameterId.value) {
      console.log('Store: Not in focus mode or no focused parameter, returning')
      return
    }
    
    const setting = getSettingForButton(currentMenu.value)
    if (setting) {
      const parameter = setting.parameters.find(p => p.id === focusedParameterId.value)
      if (parameter && parameter.options) {
        const newIndex = highlightedSelectIndex.value + delta
        console.log('Store: Current index:', highlightedSelectIndex.value, 'New index:', newIndex, 'Options length:', parameter.options.length)
        
        if (newIndex >= 0 && newIndex < parameter.options.length) {
          highlightedSelectIndex.value = newIndex
          console.log('Store: Set highlighted index to:', newIndex)
        } else if (newIndex < 0) {
          highlightedSelectIndex.value = parameter.options.length - 1
          console.log('Store: Wrapped to end, set highlighted index to:', parameter.options.length - 1)
        } else {
          highlightedSelectIndex.value = 0
          console.log('Store: Wrapped to beginning, set highlighted index to: 0')
        }
      }
    }
  }
  
  const confirmSelectSelection = () => {
    console.log('Store: confirmSelectSelection called')
    if (!isSelectFocused.value || !focusedParameterId.value) {
      console.log('Store: Not in focus mode, returning')
      return
    }
    
    const setting = getSettingForButton(currentMenu.value)
    if (setting) {
      const parameter = setting.parameters.find(p => p.id === focusedParameterId.value)
      if (parameter && parameter.options) {
        const newValue = parameter.options[highlightedSelectIndex.value]
        console.log('Store: Setting parameter value to', newValue)
        parameter.value = newValue
      }
    }
    console.log('Store: Exiting focus mode')
    setSelectFocusMode(false)
  }
  
  return {
    // State
    buttons,
    settings,
    currentSelectedButton,
    currentMenu,
    selectedParameterIndex,
    navigationMode,
    isBackButtonSelected,
    // Focus mode state
    isSelectFocused,
    highlightedSelectIndex,
    focusedParameterId,
    // Computed
    currentParameters,
    totalSelectableItems,
    // Actions
    setHoveredButton,
    setCurrentMenu,
    clearHoveredButton,
    setSelectedParameterIndex,
    setNavigationMode,
    setBackButtonSelected,
    getSettingForButton,
    // Focus mode actions
    setSelectFocusMode,
    updateHighlightedSelectIndex,
    confirmSelectSelection
  }
}) 