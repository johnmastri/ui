<template>
  <div class="led-ring" :style="ringStyle">
    <div
      v-for="(led, index) in leds"
      :key="index"
      class="led"
      :class="{ active: led.isActive }"
      :style="getLedStyle(led, index)"
    ></div>
  </div>
</template>

<script>
import { useParameterStore } from '../stores/parameterStore.js'

export default {
  name: 'LedRing',
  props: {
    paramId: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      store: useParameterStore()
    }
  },
  computed: {
    leds() {
      const param = this.store.getParameterById(this.paramId)
      if (!param) return []
      const ledCount = param.ledCount || 28
      const knobAngle = 180 + (param.value * 360) // 0 = 180° (down), 0.5 = 360° (up), 1 = 540° (down)
      const leds = []
      for (let i = 0; i < ledCount; i++) {
        const ledAngle = 180 + (360 / ledCount) * i
        // LEDs are lit if their angle is less than or equal to the knob angle
        const isLit = ledAngle <= knobAngle
        leds.push({
          index: i,
          isActive: isLit,
          color: param.rgbColor
        })
      }
      return leds
    },
    ringStyle() {
      return {
        width: '78px',  // 60px knob + 18px ring (39px radius - 30px knob radius)
        height: '78px',
        position: 'absolute',
        top: '-9px',    // Center the ring around the knob
        left: '-9px',
        pointerEvents: 'none' // Don't interfere with knob interaction
      }
    }
  },
  methods: {
    getLedStyle(led, index) {
      const ledCount = this.leds.length
      // Start from bottom (180°), fill clockwise
      const angle = 180 + (index / ledCount) * 360 // 0 = 180° (down)
      const radius = 39 // 39px radius (1.3x knob radius)
      
      // Convert polar to cartesian coordinates
      const x = radius * Math.cos((angle - 90) * Math.PI / 180)
      const y = radius * Math.sin((angle - 90) * Math.PI / 180)
      
      const backgroundColor = led.isActive 
        ? `rgb(${led.color.r}, ${led.color.g}, ${led.color.b})`
        : '#e0e0e0' // Light gray for inactive LEDs
      
      return {
        position: 'absolute',
        left: `${39 + x - 2}px`,
        top: `${39 + y - 2}px`,
        width: '4px',
        height: '4px',
        borderRadius: '50%',
        backgroundColor: backgroundColor,
        boxShadow: led.isActive 
          ? `0 0 4px rgb(${led.color.r}, ${led.color.g}, ${led.color.b})`
          : 'none',
        transition: 'all 0.1s ease'
      }
    }
  }
}
</script>

<style scoped>
.led-ring {
  z-index: 1;
}

.led {
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.led.active {
  border-color: rgba(255, 255, 255, 0.3);
}
</style> 