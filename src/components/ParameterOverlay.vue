<template>
  <g id="ParameterOverlay" ref="parameterOverlayRef">
    <!-- Debug info (temporary) -->
    <text 
      x="10" 
      y="20" 
      fill="red" 
      font-family="Arial" 
      font-size="12"
    >
      Debug: Active={{ hardwareStore.isDisplayActive }}, Text={{ hardwareStore.displayText }}, Value={{ hardwareStore.displayValue }}
    </text>
    
    <!-- PARAMETER NAME -->
    <text 
      id="PARAMETER-NAME" 
      x="400" 
      y="391.8" 
      fill="#504523" 
      font-family="Barlow" 
      font-size="32" 
      font-weight="bold" 
      letter-spacing="0.04em"
      xml:space="preserve"
      style="white-space: pre"
      text-anchor="middle"
    >
      {{ hardwareStore.displayText }}
    </text>
    
    <!-- TRACK NAME -->
    <text 
      id="TRACK-NAME" 
      x="563.962" 
      y="113.9" 
      fill="#504523" 
      fill-opacity="0.78"
      font-family="Barlow" 
      font-size="26" 
      font-style="italic"
      font-weight="bold" 
      letter-spacing="0.04em"
      xml:space="preserve"
      style="white-space: pre"
    >
      {{ hardwareStore.trackName }}
    </text>
    
    <!-- PARAMETER VALUE (the big number) -->
    <text 
      id="PARAMETER-VALUE" 
      x="400" 
      y="325.106" 
      fill="#504523" 
      font-family="Barlow" 
      font-size="250" 
      font-style="italic"
      font-weight="800" 
      letter-spacing="0em"
      text-anchor="middle"
      xml:space="preserve"
      style="white-space: pre"
    >
      {{ hardwareStore.displayValue }}
    </text>
    
    <!-- PLUGIN NAME -->
    <text 
      id="PLUGIN-NAME" 
      x="77" 
      y="115.9" 
      fill="#888249" 
      font-family="Barlow" 
      font-size="26" 
      font-style="italic"
      font-weight="bold" 
      letter-spacing="0.04em"
      xml:space="preserve"
      style="white-space: pre"
    >
      {{ hardwareStore.pluginName }}
    </text>
  </g>
</template>

<script setup>
import { ref, watch, onMounted, onUnmounted, nextTick } from 'vue'
import { gsap } from 'gsap'
import { useHardwareStore } from '../stores/hardwareStore'
import { useSettingsStore } from '../stores/settingsStore'

// Get stores
const hardwareStore = useHardwareStore()
const settingsStore = useSettingsStore()

// Template refs
const parameterOverlayRef = ref(null)

// Animation methods
const fadeInOverlay = () => {
  console.log('🎬 ParameterOverlay: Fading in...')
  if (parameterOverlayRef.value) {
    gsap.set(parameterOverlayRef.value, {
      opacity: 0,
      y: 20
    })
    
    gsap.to(parameterOverlayRef.value, {
      opacity: 1,
      y: 0,
      duration: 0.3,
      ease: "power2.out"
    })
  }
}

const fadeOutOverlay = () => {
  console.log('🎬 ParameterOverlay: Fading out...')
  if (parameterOverlayRef.value) {
    gsap.to(parameterOverlayRef.value, {
      opacity: 0,
      y: -10,
      duration: 1,
      ease: "power2.inOut"
    })
  }
}

// Manual test function
const testOverlay = () => {
  console.log('🧪 Testing ParameterOverlay manually...')
  const testParameter = {
    id: 'test-param',
    name: 'Test Parameter',
    value: 0.75,
    text: '75%'
  }
  hardwareStore.updateDisplayFromParameter(testParameter)
}

// Expose test function globally
if (typeof window !== 'undefined') {
  window.testParameterOverlay = testOverlay
}

// Watchers for animations
watch(() => hardwareStore.isDisplayActive, async (newValue, oldValue) => {
  console.log('👀 ParameterOverlay: isDisplayActive changed from', oldValue, 'to', newValue)
  if (newValue === oldValue) return
  
  await nextTick()
  
  if (newValue) {
    // Show parameter overlay
    fadeInOverlay()
  } else {
    // Hide parameter overlay
    fadeOutOverlay()
  }
})

// Watch for display text changes
watch(() => hardwareStore.displayText, (newValue) => {
  console.log('👀 ParameterOverlay: displayText changed to', newValue)
})

// Watch for display value changes
watch(() => hardwareStore.displayValue, (newValue) => {
  console.log('👀 ParameterOverlay: displayValue changed to', newValue)
})

// Lifecycle
onMounted(() => {
  console.log('🎬 ParameterOverlay mounted with GSAP animations')
  console.log('📊 Initial state:', {
    isDisplayActive: hardwareStore.isDisplayActive,
    displayText: hardwareStore.displayText,
    displayValue: hardwareStore.displayValue,
    isLargeDisplayEnabled: settingsStore.isLargeDisplayEnabled
  })
  
  // Initialize overlay state
  if (hardwareStore.isDisplayActive) {
    gsap.set(parameterOverlayRef.value, { opacity: 1, y: 0 })
  } else {
    gsap.set(parameterOverlayRef.value, { opacity: 0, y: 20 })
  }
})

onUnmounted(() => {
  // Cleanup any running animations
  if (parameterOverlayRef.value) {
    gsap.killTweensOf(parameterOverlayRef.value)
  }
})
</script> 