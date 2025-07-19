<template>
  <div class="mock-display-container" :style="containerStyle">
    <!-- Parameter Display Mode -->
    <div 
      v-show="shouldShowLargeDisplay"
      class="mock-display" 
      :style="displayStyle"
    >
      <!-- Header Row -->
      <div class="header-row">
        <div class="left-header">
          <div class="settings-icon" @click="openSettings">⚙️</div>
          <div class="device-name">{{ deviceName }}</div>
        </div>
        <div class="right-header">
          <div class="channel-name">{{ channelName }}</div>
        </div>
      </div>

      <!-- Parameter Display -->
      <div class="display-container">
        <div 
          ref="parameterDisplayRef"
          class="parameter-display"
        >
          <div 
            class="parameter-value"
            :class="{ 'text-value': isTextValue, 'numeric-value': !isTextValue }"
            :style="textValueStyle"
          >
            {{ hardwareStore.displayValue }}
          </div>
          <div class="parameter-name">{{ hardwareStore.displayText }}</div>
        </div>
      </div>

      <!-- Settings Panel -->
      <SettingsPanel />
    </div>
    
    <!-- VU Meter Display Mode -->
    <div 
      ref="vuMeterDisplayRef"
      v-show="!shouldShowLargeDisplay"
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
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { useRoute } from 'vue-router'
import { gsap } from 'gsap'
import { useHardwareStore } from '../stores/hardwareStore'
import { useSettingsStore } from '../stores/settingsStore'
import SettingsPanel from './SettingsPanel.vue'
import VUMeter from './VUMeter.vue'
import AudioControlModal from './AudioControlModal.vue'

// Stores and routing
const hardwareStore = useHardwareStore()
const settingsStore = useSettingsStore()
const route = useRoute()

// Template refs
const parameterDisplayRef = ref(null)
const vuMeterDisplayRef = ref(null)

// Display state
const deviceName = ref('MasterCtrl Device') // TODO: Make this dynamic
const channelName = ref('Channel 1') // TODO: Get from DAW
const vuMeterValue = ref('-20.0 dB')
const vuMeterLevel = ref(-20)

// Scaling (disabled for hardware route)
const scale = ref(1)
const isHardwareRoute = computed(() => route.name === 'Hardware')

// Computed properties
const shouldShowLargeDisplay = computed(() => {
  return settingsStore.isLargeDisplayEnabled && hardwareStore.isDisplayActive
})

const isTextValue = computed(() => {
  const value = hardwareStore.displayValue
  return isNaN(parseFloat(value)) || value.includes('%') || value.includes('dB') || value.includes('Hz')
})

const textValueStyle = computed(() => {
  if (!isTextValue.value) return {}
  
  // Scale down text values to fit
  const length = hardwareStore.displayValue.length
  let fontSize = '4em'
  
  if (length > 10) fontSize = '2em'
  else if (length > 8) fontSize = '2.5em'
  else if (length > 6) fontSize = '3em'
  else if (length > 4) fontSize = '3.5em'
  
  return { fontSize }
})



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

// Animation methods
const fadeInParameterDisplay = () => {
  if (parameterDisplayRef.value) {
    gsap.set(parameterDisplayRef.value, {
      opacity: 0,
      scale: 0.8,
      y: 20
    })
    
    gsap.to(parameterDisplayRef.value, {
      opacity: 1,
      scale: 1,
      y: 0,
      duration: 0.3,
      ease: "power2.out"
    })
  }
}

const fadeOutParameterDisplay = () => {
  if (parameterDisplayRef.value) {
    gsap.to(parameterDisplayRef.value, {
      opacity: 0,
      scale: 0.9,
      y: -10,
      duration: 1,
      ease: "power2.inOut"
    })
  }
}

const fadeInVuMeter = () => {
  if (vuMeterDisplayRef.value) {
    gsap.set(vuMeterDisplayRef.value, {
      opacity: 0,
      scale: 0.9
    })
    
    gsap.to(vuMeterDisplayRef.value, {
      opacity: 1,
      scale: 1,
      duration: 1,
      ease: "power2.inOut"
    })
  }
}

// Methods
const openSettings = () => {
  settingsStore.openSettingsPanel()
}

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

// Watchers for animations
watch(shouldShowLargeDisplay, async (newValue, oldValue) => {
  if (newValue === oldValue) return
  
  await nextTick()
  
  if (newValue) {
    // Show parameter display
    fadeInParameterDisplay()
  } else {
    // Show VU meter
    fadeInVuMeter()
  }
})

// Watch for parameter display becoming active
watch(() => hardwareStore.isDisplayActive, async (newValue) => {
  if (newValue && settingsStore.isLargeDisplayEnabled) {
    await nextTick()
    fadeInParameterDisplay()
  }
})

// Watch for fade out trigger
watch(() => hardwareStore.isDisplayActive, async (newValue, oldValue) => {
  if (oldValue && !newValue && settingsStore.isLargeDisplayEnabled) {
    // Fade out parameter display
    fadeOutParameterDisplay()
    
    // After fade out completes, fade in VU meter
    setTimeout(() => {
      fadeInVuMeter()
    }, 1000)
  }
})

// Lifecycle
onMounted(() => {
  console.log('HardwareDisplay mounted with GSAP')
  
  // Initialize display state
  if (shouldShowLargeDisplay.value) {
    gsap.set(parameterDisplayRef.value, { opacity: 1, scale: 1, y: 0 })
  } else {
    gsap.set(vuMeterDisplayRef.value, { opacity: 1, scale: 1 })
  }
  
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

/* Header Row */
.header-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: 12px 16px 0;
  min-height: 50px;
}

.left-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.settings-icon {
  font-size: 1.2em;
  color: #888;
  cursor: pointer;
  transition: all 0.2s;
  padding: 4px;
  border-radius: 4px;
}

.settings-icon:hover {
  color: #fff;
  background: rgba(255, 255, 255, 0.1);
}

.device-name {
  font-size: 0.8em;
  color: #aaa;
  font-family: 'Courier New', monospace;
  font-weight: 500;
}

.right-header {
  text-align: right;
}

.channel-name {
  font-size: 1.1em;
  font-weight: bold;
  color: #00ff88;
  text-shadow: 0 0 8px rgba(0, 255, 136, 0.4);
  font-family: 'Courier New', monospace;
}

/* Main Display Area */
.display-container {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  padding: 20px;
}

/* Parameter Display */
.parameter-display {
  text-align: center;
  width: 100%;
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.parameter-value {
  font-weight: bold;
  color: #ffffff;
  text-shadow: 0 0 20px rgba(255, 255, 255, 0.8);
  font-family: 'Courier New', monospace;
  margin-bottom: 12px;
  line-height: 1;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.numeric-value {
  font-size: 4em;
}

.text-value {
  /* fontSize set dynamically via textValueStyle */
}

.parameter-name {
  font-size: 1.4em;
  font-weight: 500;
  color: #00ff88;
  text-shadow: 0 0 10px rgba(0, 255, 136, 0.5);
  font-family: 'Courier New', monospace;
  text-transform: uppercase;
  letter-spacing: 1px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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