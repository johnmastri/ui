<template>
  <g ref="SettingsHolder" id="SettingsHolder">
    <!-- Settings Parameter Templates -->
    <SettingsParameterTemplate 
      v-for="(parameter, index) in currentParameters" 
      :key="parameter.id"
      :parameter="parameter"
      :y-position="calculateYPosition(index)"
      :is-selected="selectedParameterIndex === index"
      @parameter-change="handleParameterChange"
      @button-click="handleButtonClick"
    />

    <!-- Green marker -->
     <g :transform="`translate(0, ${markerY})`">
    <rect 
      ref="marker"
      id="marker" 
      :x="128" 
      :y="0" 
      width="9" 
      height="50" 
      fill="#3ED72A"
    />
  </g>


    <!-- Settings Header -->
    <text 
      id="SettingsHeader" 
      fill="white" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="IBM Plex Sans Condensed" 
      font-size="48" 
      font-style="italic" 
      letter-spacing="0em"
    >
      <tspan x="149" y="112">{{ headerText }}</tspan>
    </text>
  </g>
</template>

<script>
import SettingsParameterTemplate from './SettingsParameterTemplate.vue'
import { useHardwareSettingsStore } from '../../../stores/hardwareSettingsStore'
import { gsap } from 'gsap'
import { ref, computed, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'

export default {
  name: 'SettingsHolder',
  components: {
    SettingsParameterTemplate
  },
  setup() {
    const hardwareSettingsStore = useHardwareSettingsStore()
    const SettingsHolder = ref(null)
    const marker = ref(null)
    const markerY = ref(147)
    let markerAnimation = null // Track marker position animation
    let markerScaleAnimation = null // Track marker scale animation

    const selectedParameterIndex = computed(() => hardwareSettingsStore.selectedParameterIndex)
    const currentParameters = computed(() => hardwareSettingsStore.currentParameters)
    const isBackButtonSelected = computed(() => hardwareSettingsStore.isBackButtonSelected)

    // Calculate parameter Y position (for the list items)
    const calculateYPosition = (index) => {
      const baseY = 0 // Base Y position for parameters
      const spacing = 67 // Spacing between parameters
      return baseY + (index * spacing) // Use index * spacing for positioning
    }

    // Calculate marker Y position based on selected index
    const calculateMarkerYPosition = (index) => {
      return 147 + (index * 67) // Simple absolute positioning
    }

    // Animate marker when selection changes
    watch(selectedParameterIndex, (newIdx) => {
      console.log('SettingsHolder: selectedParameterIndex changed to:', newIdx, 'isBackSelected:', isBackButtonSelected.value)
      // Only animate Y position if back button is not selected
      if (!isBackButtonSelected.value) {
        // Kill previous animation immediately
        if (markerAnimation) {
          markerAnimation.kill()
          markerAnimation = null
        }
        
        // Ensure index is within bounds (0 to parameters.length - 1)
        const validIndex = Math.max(0, Math.min(newIdx, currentParameters.value.length - 1))
        const newY = calculateMarkerYPosition(validIndex)
        console.log('SettingsHolder: setting markerY to:', newY, 'for index:', validIndex)
        
        // Animate to exact position
        markerAnimation = gsap.to(markerY, {
          value: newY,
          duration: 0.3,
          ease: 'power2.out'
        })
      } else {
        console.log('SettingsHolder: back button selected, not animating Y position')
      }
    })

    // Watch for back button selection changes
    watch(isBackButtonSelected, (isSelected) => {
      console.log('SettingsHolder: isBackButtonSelected changed to:', isSelected)
      // Handle marker scaling directly in setup
      if (marker.value) {
        // Kill previous scale animation
        if (markerScaleAnimation) {
          markerScaleAnimation.kill()
        }
        
        markerScaleAnimation = gsap.to(marker.value, {
          scaleY: isSelected ? 0 : 1,
          duration: 0.3,
          ease: 'power2.out',
          transformOrigin: 'bottom left'
        })
        
        // When returning from back button to parameters, ensure marker is positioned correctly
        if (!isSelected) {
          // Kill previous position animation immediately
          if (markerAnimation) {
            markerAnimation.kill()
            markerAnimation = null
          }
          
          const currentIdx = selectedParameterIndex.value
          const newY = calculateMarkerYPosition(currentIdx)
          console.log('SettingsHolder: returning from back button, setting marker at:', newY)
          
          // Animate to exact position
          markerAnimation = gsap.to(markerY, {
            value: newY,
            duration: 0.3,
            ease: 'power2.out'
          })
        }
      }
    })

    // Reset marker position to ensure it's in sync
    const resetMarkerPosition = () => {
      // Kill any ongoing animations
      if (markerAnimation) {
        markerAnimation.kill()
        markerAnimation = null
      }
      if (markerScaleAnimation) {
        markerScaleAnimation.kill()
        markerScaleAnimation = null
      }
      
      const validIndex = Math.max(0, Math.min(selectedParameterIndex.value, currentParameters.value.length - 1))
      const correctY = calculateMarkerYPosition(validIndex)
      markerY.value = correctY
      console.log('SettingsHolder: reset marker position to:', correctY, 'for index:', validIndex)
    }

    // Mouse wheel navigation
    const onWheel = (e) => {
      e.preventDefault()
      const dir = e.deltaY > 0 ? 1 : -1
      const newIndex = selectedParameterIndex.value + dir
      // Clamp to valid parameter range (0 to parameters.length - 1)
      if (newIndex >= 0 && newIndex < currentParameters.value.length) {
        hardwareSettingsStore.setSelectedParameterIndex(newIndex)
      }
    }

    onMounted(() => {
      nextTick(() => {
        if (SettingsHolder.value) {
          SettingsHolder.value.addEventListener('wheel', onWheel, { passive: false })
        }
        // Reset marker position on mount to ensure it's correct
        resetMarkerPosition()
      })
    })
    onBeforeUnmount(() => {
      if (SettingsHolder.value) {
        SettingsHolder.value.removeEventListener('wheel', onWheel)
      }
    })

    return {
      hardwareSettingsStore,
      SettingsHolder,
      marker,
      markerY,
      selectedParameterIndex,
      currentParameters,
      calculateYPosition,
      resetMarkerPosition,
      headerText: computed(() => {
        const currentButton = hardwareSettingsStore.buttons.find(
          btn => btn.id === hardwareSettingsStore.currentSelectedButton
        )
        return currentButton ? currentButton.label.toLowerCase() : 'settings'
      })
    }
  },
  methods: {
    fadeIn() {
      gsap.to(this.$refs.SettingsHolder, {
        opacity: 1,
        duration: 1,
        delay: 0.3,
        ease: "elastic.out(1, 1)"
      })
    },
    fadeOut() {
      gsap.to(this.$refs.SettingsHolder, {
        opacity: 0,
        duration: 0.2,
        ease: "power2.in"
      })
    },
    handleParameterChange({ id, value, type }) {
      const currentSetting = this.hardwareSettingsStore.getSettingForButton(
        this.hardwareSettingsStore.currentSelectedButton
      )
      if (currentSetting) {
        const parameter = currentSetting.parameters.find(p => p.id === id)
        if (parameter) {
          parameter.value = value
          this.$emit('settings-change', {
            category: this.hardwareSettingsStore.currentSelectedButton,
            parameterId: id,
            value: value,
            type: type
          })
        }
      }
    },
    handleButtonClick({ id, value, type }) {
      const currentSetting = this.hardwareSettingsStore.getSettingForButton(
        this.hardwareSettingsStore.currentSelectedButton
      )
      if (currentSetting) {
        const parameter = currentSetting.parameters.find(p => p.id === id)
        if (parameter) {
          this.$emit('button-click', {
            category: this.hardwareSettingsStore.currentSelectedButton,
            parameterId: id,
            value: value,
            type: type
          })
        }
      }
    }
  }
}
</script>

<style scoped>
#SettingsHolder {
  opacity: 0;
}
</style> 