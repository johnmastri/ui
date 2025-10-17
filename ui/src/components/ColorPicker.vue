<template>
  <div class="color-picker-container">
    <div 
      class="color-picker-circle"
      :style="{ backgroundColor: currentColor }"
      @click="openColorPicker"
      @mouseenter="showTooltip = true"
      @mouseleave="showTooltip = false"
    ></div>
    <input
      ref="colorInput"
      type="color"
      :value="currentColor"
      @input="updateColor"
      class="color-input"
    />
    <div v-if="showTooltip" class="tooltip">
      Click to change color
    </div>
  </div>
</template>

<script>
import { useParameterStore } from '../stores/parameterStore.js'

export default {
  name: 'ColorPicker',
  props: {
    paramId: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      store: useParameterStore(),
      showTooltip: false
    }
  },
  computed: {
    currentColor() {
      const param = this.store.getParameterById(this.paramId)
      return param ? param.color : '#ffffff'
    }
  },
  methods: {
    openColorPicker() {
      this.$refs.colorInput.click()
    },
    updateColor(event) {
      const newColor = event.target.value
      this.store.setParameterColor(this.paramId, newColor)
      this.$emit('color-changed', newColor)
    }
  }
}
</script>

<style scoped>
.color-picker-container {
  position: relative;
  display: inline-block;
}

.color-picker-circle {
  width: 25px;
  height: 25px;
  border-radius: 50%;
  border: 2px solid #ffffff;
  cursor: pointer;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
  transition: all 0.2s ease;
  position: absolute;
  top: -5px;
  left: -5px;
  z-index: 10;
}

.color-picker-circle:hover {
  transform: scale(1.1);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3);
}

.color-input {
  position: absolute;
  opacity: 0;
  pointer-events: none;
  width: 0;
  height: 0;
}

.tooltip {
  position: absolute;
  top: 30px;
  left: 0;
  background: #333;
  color: white;
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 11px;
  white-space: nowrap;
  z-index: 100;
  pointer-events: none;
}

.tooltip::before {
  content: '';
  position: absolute;
  top: -4px;
  left: 8px;
  width: 0;
  height: 0;
  border-left: 4px solid transparent;
  border-right: 4px solid transparent;
  border-bottom: 4px solid #333;
}
</style> 