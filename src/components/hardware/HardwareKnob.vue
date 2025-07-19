<template>
  <div class="hardware-knob" @mousedown="startDrag" @touchstart="startDrag">
    <div class="knob-container">
      <div class="knob-body" :style="{ transform: `rotate(${rotation}deg)` }">
        <div class="knob-pointer"></div>
        <div class="knob-center"></div>
      </div>
      <div class="knob-label">{{ label }}</div>
      <div class="knob-value">{{ displayValue }}</div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HardwareKnob',
  
  props: {
    // v-model support
    modelValue: {
      type: Number,
      default: 0
    },
    
    // Knob properties
    label: {
      type: String,
      required: true
    },
    
    min: {
      type: Number,
      default: 0
    },
    
    max: {
      type: Number,
      default: 100
    },
    
    step: {
      type: Number,
      default: 1
    },
    
    // Display formatting
    displayFormat: {
      type: Function,
      default: (value) => Math.round(value).toString()
    },
    
    // Visual properties
    rotationRange: {
      type: Number,
      default: 270 // Total degrees of rotation
    }
  },
  
  data() {
    return {
      isDragging: false,
      dragStartY: 0,
      dragStartValue: 0,
      currentValue: this.modelValue
    }
  },
  
  computed: {
    rotation() {
      // Map value to rotation angle
      const normalized = (this.currentValue - this.min) / (this.max - this.min)
      const startAngle = -this.rotationRange / 2
      return startAngle + (normalized * this.rotationRange)
    },
    
    displayValue() {
      return this.displayFormat(this.currentValue)
    }
  },
  
  watch: {
    modelValue(newValue) {
      this.currentValue = newValue
    },
    
    currentValue(newValue) {
      this.$emit('update:modelValue', newValue)
    }
  },
  
  methods: {
    startDrag(event) {
      this.isDragging = true
      this.dragStartY = event.type.includes('mouse') ? event.clientY : event.touches[0].clientY
      this.dragStartValue = this.currentValue
      
      // Add global listeners
      document.addEventListener('mousemove', this.handleDrag)
      document.addEventListener('mouseup', this.stopDrag)
      document.addEventListener('touchmove', this.handleDrag)
      document.addEventListener('touchend', this.stopDrag)
      
      event.preventDefault()
    },
    
    handleDrag(event) {
      if (!this.isDragging) return
      
      const currentY = event.type.includes('mouse') ? event.clientY : event.touches[0].clientY
      const deltaY = this.dragStartY - currentY
      
      // Sensitivity factor
      const sensitivity = 0.5
      const range = this.max - this.min
      const valueDelta = (deltaY * sensitivity * range) / 100
      
      // Update value with constraints
      const newValue = this.dragStartValue + valueDelta
      this.currentValue = Math.max(this.min, Math.min(this.max, newValue))
      
      // Round to step
      this.currentValue = Math.round(this.currentValue / this.step) * this.step
    },
    
    stopDrag() {
      this.isDragging = false
      
      // Remove global listeners
      document.removeEventListener('mousemove', this.handleDrag)
      document.removeEventListener('mouseup', this.stopDrag)
      document.removeEventListener('touchmove', this.handleDrag)
      document.removeEventListener('touchend', this.stopDrag)
    }
  }
}
</script>

<style scoped>
.hardware-knob {
  display: inline-block;
  user-select: none;
  -webkit-user-select: none;
}

.knob-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}

.knob-body {
  width: 60px;
  height: 60px;
  background: linear-gradient(145deg, #2a2a2a, #1a1a1a);
  border-radius: 50%;
  box-shadow: 
    0 4px 8px rgba(0, 0, 0, 0.5),
    inset 0 -2px 4px rgba(0, 0, 0, 0.3),
    inset 0 2px 4px rgba(255, 255, 255, 0.1);
  position: relative;
  cursor: grab;
  transition: transform 0.1s ease-out;
}

.hardware-knob:active .knob-body {
  cursor: grabbing;
  transform: scale(0.98);
}

.knob-pointer {
  position: absolute;
  width: 4px;
  height: 20px;
  background: linear-gradient(to bottom, #ff6b6b, #ff4444);
  top: 5px;
  left: 50%;
  transform: translateX(-50%);
  border-radius: 2px;
  box-shadow: 0 0 4px rgba(255, 68, 68, 0.5);
}

.knob-center {
  position: absolute;
  width: 20px;
  height: 20px;
  background: radial-gradient(circle, #3a3a3a, #1a1a1a);
  border-radius: 50%;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  box-shadow: 
    inset 0 1px 2px rgba(0, 0, 0, 0.5),
    0 1px 1px rgba(255, 255, 255, 0.1);
}

.knob-label {
  font-size: 12px;
  font-weight: 500;
  text-transform: uppercase;
  color: #aaa;
  letter-spacing: 1px;
}

.knob-value {
  font-size: 14px;
  font-weight: 600;
  color: #fff;
  font-family: 'Courier New', monospace;
  min-width: 40px;
  text-align: center;
}

/* Touch device optimizations */
@media (hover: none) {
  .knob-body {
    width: 70px;
    height: 70px;
  }
  
  .knob-pointer {
    width: 5px;
    height: 25px;
  }
}
</style> 