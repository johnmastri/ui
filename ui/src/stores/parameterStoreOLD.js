import { defineStore } from 'pinia'

export const useParameterStore = defineStore('parameters', {
  state: () => ({
    parameters: [],
    colorPresets: {
      'Input Gain': '#4CAF50',    // Green
      'Drive': '#FF5722',         // Orange-Red
      'Tone': '#2196F3',          // Blue
      'Output Level': '#9C27B0',  // Purple
      'Mix': '#FF9800',           // Orange
      'Attack': '#00BCD4',        // Cyan
      'Release': '#3F51B5',       // Indigo
      'Threshold': '#E91E63',     // Pink
      'Ratio': '#795548',         // Brown
      'Knee': '#607D8B'           // Blue-Grey
    }
  }),

  getters: {
    getParameterById: (state) => (id) => {
      return state.parameters.find(p => p.id === id)
    },

    getActiveLedIndex: () => (value, ledCount = 28) => {
      // Convert 0-1 value to 0-27 LED index
      // Knob range is -135° to +135° (270° total)
      // Map to 0-27 LED positions
      const normalizedValue = Math.max(0, Math.min(1, value))
      return Math.floor(normalizedValue * (ledCount - 1))
    },

    getLedArray: (state) => (paramId) => {
      const param = state.parameters.find(p => p.id === paramId)
      if (!param) return []

      const ledCount = param.ledCount || 28
      const activeIndex = state.getActiveLedIndex(param.value, ledCount)
      const leds = []

      for (let i = 0; i < ledCount; i++) {
        const isActive = i === activeIndex
        const color = isActive ? param.rgbColor : { r: 51, g: 51, b: 51 } // Dark gray
        leds.push({
          index: i,
          color: color,
          isActive: isActive
        })
      }

      return leds
    },

    // FASTLED compatibility
    getFastledArray: (state) => (paramId) => {
      const leds = state.getLedArray(paramId)
      return leds.map(led => `CRGB(${led.color.r}, ${led.color.g}, ${led.color.b})`)
    },

    getAllFastledData: (state) => {
      return state.parameters.map(param => ({
        paramId: param.id,
        leds: state.getFastledArray(param.id)
      }))
    }
  },

  actions: {
    addParameter(parameter) {
      // Check if parameter already exists
      const existingIndex = this.parameters.findIndex(p => p.id === parameter.id)
      if (existingIndex !== -1) {
        // Update existing parameter
        this.parameters[existingIndex] = {
          ...this.parameters[existingIndex],
          ...parameter,
          text: parameter.text || this.generateParameterText(parameter.name, parameter.value),
          color: parameter.color || this.colorPresets[parameter.name] || '#4CAF50',
          rgbColor: parameter.rgbColor || this.hexToRgb(parameter.color || this.colorPresets[parameter.name] || '#4CAF50'),
          ledCount: parameter.ledCount || 28
        }
      } else {
        // Add new parameter
        const newParameter = {
          ...parameter,
          text: parameter.text || this.generateParameterText(parameter.name, parameter.value),
          color: parameter.color || this.colorPresets[parameter.name] || '#4CAF50',
          rgbColor: parameter.rgbColor || this.hexToRgb(parameter.color || this.colorPresets[parameter.name] || '#4CAF50'),
          ledCount: parameter.ledCount || 28
        }
        this.parameters.push(newParameter)
      }
    },

    updateParameter(id, value) {
      const param = this.parameters.find(p => p.id === id)
      if (param) {
        param.value = Math.max(0, Math.min(1, value))
        param.text = this.generateParameterText(param.name, param.value)
      }
    },

    setParameterColor(id, color) {
      const param = this.parameters.find(p => p.id === id)
      if (param) {
        param.color = color
        param.rgbColor = this.hexToRgb(color)
      }
    },

    generateParameterText(name, value) {
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
    },

    hexToRgb(hex) {
      const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
      return result ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16)
      } : { r: 0, g: 0, b: 0 }
    },

    loadMockData() {
      const mockParameters = [
        {
          id: 'input-gain',
          index: 0,
          name: "Input Gain",
          value: 0.75,
          defaultValue: 0.5,
          label: "Input",
          text: "75%",
          color: this.colorPresets['Input Gain'],
          rgbColor: this.hexToRgb(this.colorPresets['Input Gain']),
          ledCount: 28
        },
        {
          id: 'drive',
          index: 1,
          name: "Drive",
          value: 0.3,
          defaultValue: 0.0,
          label: "Drive",
          text: "30%",
          color: this.colorPresets['Drive'],
          rgbColor: this.hexToRgb(this.colorPresets['Drive']),
          ledCount: 28
        },
        {
          id: 'tone',
          index: 2,
          name: "Tone",
          value: 0.6,
          defaultValue: 0.5,
          label: "Tone",
          text: "60%",
          color: this.colorPresets['Tone'],
          rgbColor: this.hexToRgb(this.colorPresets['Tone']),
          ledCount: 28
        },
        {
          id: 'output-level',
          index: 3,
          name: "Output Level",
          value: 0.8,
          defaultValue: 0.7,
          label: "Output",
          text: "80%",
          color: this.colorPresets['Output Level'],
          rgbColor: this.hexToRgb(this.colorPresets['Output Level']),
          ledCount: 28
        },
        {
          id: 'mix',
          index: 4,
          name: "Mix",
          value: 0.5,
          defaultValue: 0.5,
          label: "Mix",
          text: "50%",
          color: this.colorPresets['Mix'],
          rgbColor: this.hexToRgb(this.colorPresets['Mix']),
          ledCount: 28
        },
        {
          id: 'attack',
          index: 5,
          name: "Attack",
          value: 0.2,
          defaultValue: 0.1,
          label: "Attack",
          text: "20ms",
          color: this.colorPresets['Attack'],
          rgbColor: this.hexToRgb(this.colorPresets['Attack']),
          ledCount: 28
        },
        {
          id: 'release',
          index: 6,
          name: "Release",
          value: 0.4,
          defaultValue: 0.3,
          label: "Release",
          text: "100ms",
          color: this.colorPresets['Release'],
          rgbColor: this.hexToRgb(this.colorPresets['Release']),
          ledCount: 28
        },
        {
          id: 'threshold',
          index: 7,
          name: "Threshold",
          value: 0.6,
          defaultValue: 0.5,
          label: "Thresh",
          text: "-12dB",
          color: this.colorPresets['Threshold'],
          rgbColor: this.hexToRgb(this.colorPresets['Threshold']),
          ledCount: 28
        },
        {
          id: 'ratio',
          index: 8,
          name: "Ratio",
          value: 0.7,
          defaultValue: 0.5,
          label: "Ratio",
          text: "4:1",
          color: this.colorPresets['Ratio'],
          rgbColor: this.hexToRgb(this.colorPresets['Ratio']),
          ledCount: 28
        },
        {
          id: 'knee',
          index: 9,
          name: "Knee",
          value: 0.3,
          defaultValue: 0.0,
          label: "Knee",
          text: "Soft",
          color: this.colorPresets['Knee'],
          rgbColor: this.hexToRgb(this.colorPresets['Knee']),
          ledCount: 28
        }
      ]

      this.parameters = mockParameters
    },

    clearParameters() {
      this.parameters = []
    }
  }
}) 