<template>
  <div class="mock-display-container" :style="containerStyle">
    <!-- VU Meter Display Mode -->
    <div 
      ref="vuMeterDisplayRef"
      class="vu-meter-container"
      :style="displayStyle"
    >
      <VUMeter :level="vuMeterLevel" />
    </div>
    
    <!-- Audio Control Modal (overlay) -->
    <AudioControlModal />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useHardwareStore } from '../stores/hardwareStore'
import { useSettingsStore } from '../stores/settingsStore'
import VUMeter from './VUMeter.vue'
import AudioControlModal from './AudioControlModal.vue'

// Stores and routing
const hardwareStore = useHardwareStore()
const settingsStore = useSettingsStore()
const route = useRoute()

// Template refs
const vuMeterDisplayRef = ref(null)

// Display state
const vuMeterValue = ref('-20.0 dB')
const vuMeterLevel = ref(-20)

// Scaling (disabled for hardware route)
const scale = ref(1)
const isHardwareRoute = computed(() => route.name === 'Hardware')

// Computed properties
const displayStyle = computed(() => {
  if (isHardwareRoute.value) {
    // Hardware route: no transform scaling
    return {
      transform: 'none',
      width: '100%',
      height: '100%'
    }
  }
  
  // Other routes: responsive scaling
  return {
    transform: `scale(${scale.value})`,
    transformOrigin: 'center center'
  }
})

const containerStyle = computed(() => {
  if (isHardwareRoute.value) {
    // Hardware route: fixed dimensions, no scaling
    return {
      height: '100%',
      width: '100%',
      padding: '0'
    }
  }
  
  // Other routes: responsive scaling
  return {
    height: `${480 * scale.value}px`,
    padding: '0'
  }
})

// Methods
const calculateScale = () => {
  // No scaling for hardware route - always use 1:1 scale
  if (isHardwareRoute.value) {
    scale.value = 1
    return
  }
  
  const viewportWidth = window.innerWidth
  const padding = viewportWidth <= 480 ? 10 : 20
  const availableWidth = viewportWidth - padding
  const newScale = Math.min(1, availableWidth / 800) // Never scale up beyond 1
  scale.value = newScale
}

  // Lifecycle
  onMounted(() => {
    console.log('HardwareDisplay mounted - VU meter only')
    
    // Initialize VU meter display (no animation needed)
    
    // Initialize scaling (only for non-hardware routes)
    calculateScale()
    if (!isHardwareRoute.value) {
      window.addEventListener('resize', calculateScale)
    }
  })

onUnmounted(() => {
  if (!isHardwareRoute.value) {
    window.removeEventListener('resize', calculateScale)
  }
})
</script>

<style scoped>
.mock-display-container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: fit-content;
  box-sizing: border-box;
  overflow: hidden;
}

.mock-display {
  width: 800px;
  height: 480px;
  min-width: 800px;
  min-height: 480px;
  max-width: 800px;
  max-height: 480px;
  background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
  border: 2px solid #333;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  position: relative;
  overflow: hidden;
  box-shadow: 
    inset 0 0 20px rgba(0, 0, 0, 0.5),
    0 4px 15px rgba(0, 0, 0, 0.3);
}

/* VU Meter Container */
.vu-meter-container {
  display: flex;
  justify-content: center;
  align-items: center;
  width: 100%;
  height: 100%;
}

/* Performance optimizations */
.parameter-display {
  will-change: opacity, transform;
}

/* Mobile responsive width calculation handled by JavaScript */
</style> 