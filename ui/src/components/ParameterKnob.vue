<template>
  <div class="parameter-knob-container" :class="{ 'theme-dark': theme === 'dark' }">
    <!-- Color Picker in upper left -->
    <ColorPicker 
      :paramId="paramId" 
      @color-changed="handleColorChanged"
      class="color-picker-absolute"
    />
    <div class="parameter-knob-label">{{ parameter.name }}</div>
    
    <div class="parameter-knob-wrapper">
      <!-- LED Ring -->
      <LedRing :paramId="paramId" />
      
      <!-- Knob -->
      <div
        class="parameter-knob"
        @mousedown="startKnobDrag"
        @touchstart="startKnobDrag"
      >
        <div
          class="knob-indicator"
          :style="{ transform: `rotate(${knobRotation}deg)` }"
        ></div>
      </div>
    </div>
    
    <div class="parameter-knob-value">{{ parameter.text }}</div>
  </div>
</template>

<script>
import { useParameterStore } from '../stores/parameterStore.js'
import { useJuceIntegration } from '../composables/useJuceIntegration.js'
import LedRing from './LedRing.vue'
import ColorPicker from './ColorPicker.vue'

export default {
  name: 'ParameterKnob',
  components: {
    LedRing,
    ColorPicker
  },
  props: {
    paramId: {
      type: String,
      required: true
    },
    theme: {
      type: String,
      default: 'light',
      validator: value => ['light', 'dark'].includes(value)
    }
  },
  data() {
    return {
      store: useParameterStore(),
      juceIntegration: useJuceIntegration(),
      isDragging: false,
      dragStartY: 0,
      dragStartValue: 0
    }
  },
  computed: {
    parameter() {
      return this.store.getParameterById(this.paramId)
    },
    knobRotation() {
      if (!this.parameter) return 0
      // 0.0 = 180° (down), 0.5 = 360° (up), 1.0 = 540° (down again)
      return 180 + (this.parameter.value * 360)
    }
  },
  methods: {
    startKnobDrag(event) {
      event.preventDefault()
      this.isDragging = true
      this.dragStartY = event.clientY || event.touches[0].clientY
      this.dragStartValue = this.parameter.value
      
      // Add global mouse/touch move and up listeners
      document.addEventListener('mousemove', this.handleKnobDrag)
      document.addEventListener('mouseup', this.endKnobDrag)
      document.addEventListener('touchmove', this.handleKnobDrag)
      document.addEventListener('touchend', this.endKnobDrag)
    },

    handleKnobDrag(event) {
      if (!this.isDragging) return
      event.preventDefault()
      const currentY = event.clientY || event.touches[0].clientY
      const deltaY = this.dragStartY - currentY // Inverted for natural feel
      const sensitivity = 0.01 // Adjust sensitivity as needed
      let newValue = this.dragStartValue + (deltaY * sensitivity)
      // Clamp to [0, 1] (endless, but no wrapping)
      newValue = Math.max(0, Math.min(1, newValue))
      
      // Update parameter store (this updates the UI)
      this.store.updateParameter(this.paramId, newValue)
      
      // Send parameter change to C++ via JUCE (if parameter has an index)
      if (this.parameter && this.parameter.index !== undefined) {
        this.juceIntegration.setVSTParameter(this.parameter.index, newValue)
      }
      
      this.$emit('value-changed', {
        value: newValue,
        paramId: this.paramId,
        id: this.paramId,
        name: this.parameter?.name,
        text: this.parameter?.text
      })
    },

    endKnobDrag() {
      if (!this.isDragging) return
      
      this.isDragging = false
      
      // Remove global listeners
      document.removeEventListener('mousemove', this.handleKnobDrag)
      document.removeEventListener('mouseup', this.endKnobDrag)
      document.removeEventListener('touchmove', this.handleKnobDrag)
      document.removeEventListener('touchend', this.endKnobDrag)
      
      // Note: Hardware display timing is now handled by data watchers in hardwareStore
    },

    handleColorChanged(color) {
      this.$emit('color-changed', color)
    }
  }
}
</script>

<style scoped>
.parameter-knob-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 16px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  position: relative;
}

/* Dark theme styles */
.parameter-knob-container.theme-dark {
  background: #1a1a1a;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  border: none; /* Remove the white border */
}

.color-picker-absolute {
  position: absolute;
  top: 8px;
  left: 8px;
  z-index: 20;
}

/* .parameter-knob-container:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
} */

.parameter-knob-label {
  font-size: 11px;
  font-weight: 600;
  color: #333;
  text-align: center;
  max-width: 100px;
  word-wrap: break-word;
  line-height: 1.2;
}

.theme-dark .parameter-knob-label {
  color: #ffffff;
}

.parameter-knob-wrapper {
  position: relative;
  width: 60px;
  height: 60px;
}

.parameter-knob {
  width: 60px;
  height: 60px;
  border-radius: 50%;
  background: linear-gradient(145deg, #e6e6e6, #ffffff);
  border: 3px solid #d0d0d0;
  cursor: pointer;
  position: relative;
  transition: all 0.2s ease;
  box-shadow:
    inset 0 2px 4px rgba(0,0,0,0.1),
    0 2px 8px rgba(0,0,0,0.1);
  z-index: 2;
}

.theme-dark .parameter-knob {
  background: linear-gradient(145deg, #2a2a2a, #1a1a1a);
  border: 3px solid #444;
  box-shadow:
    inset 0 2px 4px rgba(0,0,0,0.3),
    0 2px 8px rgba(0,0,0,0.3);
}

.parameter-knob:hover {
  border-color: #2196F3;
  box-shadow:
    inset 0 2px 4px rgba(0,0,0,0.1),
    0 2px 12px rgba(33, 150, 243, 0.3);
}

.theme-dark .parameter-knob:hover {
  border-color: #00ffff;
  box-shadow:
    inset 0 2px 4px rgba(0,0,0,0.3),
    0 2px 12px rgba(0, 255, 255, 0.3);
}

.parameter-knob:active {
  transform: scale(0.98);
}

.knob-indicator {
  position: absolute;
  top: 6px;
  left: 50%;
  width: 3px;
  height: 20px;
  background: #2196F3;
  border-radius: 2px;
  transform-origin: 50% 21px;
  transition: transform 0.1s ease;
  box-shadow: 0 1px 3px rgba(0,0,0,0.3);
}

.theme-dark .knob-indicator {
  background: #00ffff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.5), 0 0 5px rgba(0, 255, 255, 0.5);
}

.parameter-knob-value {
  font-size: 10px;
  color: #666;
  text-align: center;
  background: #f0f0f0;
  padding: 4px 8px;
  border-radius: 12px;
  min-width: 40px;
  font-weight: 500;
  border: 1px solid #e0e0e0;
}

.theme-dark .parameter-knob-value {
  color: #cccccc;
  background: #2a2a2a;
  border: 1px solid #444;
}
</style> 