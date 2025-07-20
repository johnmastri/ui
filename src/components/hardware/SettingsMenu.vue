<template>
  <g @wheel="handleWheel">
        <!-- 2x2 Grid of Settings Buttons -->
    <g 
      v-for="(btn, idx) in hardwareSettingsStore.buttons" 
      :key="btn.id" 
      :ref="el => setButtonRef(el, btn.id)"
      :transform="`translate(${btn.x}, ${btn.y})`"
      @mouseenter="handleMouseEnter(btn.id)"
      @mouseleave="handleMouseLeave"
      style="opacity: 0; pointer-events: auto;"
    >
      <SettingsButton 
        :label="btn.label"
        :button-id="btn.id"
        :is-selected="isButtonSelected(btn.id)"
      />
    </g>
    
        <!-- Close Button -->
    <g :ref="el => closeButtonWrapper = el" style="opacity: 0; pointer-events: auto;">
      <CloseButton 
        :is-selected="isButtonSelected('close')"
        @close="emitClose"
        @mouseenter="handleMouseEnter('close')"
        @mouseleave="handleMouseLeave"
      />
    </g>
  </g>
</template>

<script>
import SettingsButton from './SettingsButton.vue'
import CloseButton from './CloseButton.vue'
import { useHardwareSettingsStore } from '../../stores/hardwareSettingsStore'
import { gsap } from 'gsap'

export default {
  name: 'SettingsMenu',
  components: {
    SettingsButton,
    CloseButton
  },
  emits: ['close'],
  setup() {
    const hardwareSettingsStore = useHardwareSettingsStore()
    
    const handleMouseEnter = (buttonId) => {
      hardwareSettingsStore.setHoveredButton(buttonId)
    }
    
    const handleMouseLeave = () => {
      hardwareSettingsStore.clearHoveredButton()
    }
    
    const emitClose = () => {
      hardwareSettingsStore.clearHoveredButton()
      // Note: We'll need to emit the close event, but we need to access the emit function
      // This will be handled in the methods section
    }
    
    return {
      hardwareSettingsStore,
      handleMouseEnter,
      handleMouseLeave,
      emitClose
    }
  },
  data() {
    return {
      buttonRefs: {},
      closeButtonWrapper: null
    }
  },
  methods: {
    isButtonSelected(buttonId) {
      return this.hardwareSettingsStore.currentSelectedButton === buttonId
    },
    
    setButtonRef(el, buttonId) {
      if (el) {
        this.buttonRefs[buttonId] = el
      }
    },
    
    animateButtonsIn() {
      // Define the order for sequential animation - close button last
      const buttonOrder = ['device', 'network', 'midi', 'display']
      const delayBetweenButtons = 0.10 // 150ms between each button
      
      // Animate the settings buttons
      buttonOrder.forEach((buttonId, index) => {
        const delay = index * delayBetweenButtons
        const element = this.buttonRefs[buttonId]
        
        if (element) {
          gsap.to(element, {
            opacity: 1,
            duration: 0.5,
            delay: delay,
            ease: "bounce.out"
          })
        }
      })
      
      // Animate the close button last
      const closeButtonDelay = buttonOrder.length * delayBetweenButtons
      
      if (this.closeButtonWrapper) {
        gsap.to(this.closeButtonWrapper, {
          opacity: 1,
          duration: 0.8,
          delay: closeButtonDelay,
          ease: "bounce.out"
        })
      }
    },
    
    emitClose() {
      this.hardwareSettingsStore.clearHoveredButton()
      this.$emit('close')
    },
    
    handleWheel(event) {
      event.preventDefault()
      
      // Define clockwise order: device → network → midi → display → close → device...
      const clockwiseOrder = ['device', 'network', 'midi', 'display', 'close']
      const currentButtonId = this.hardwareSettingsStore.currentSelectedButton
      const currentIndex = clockwiseOrder.indexOf(currentButtonId)
      
      let nextIndex
      if (event.deltaY > 0) {
        // Scroll down - move clockwise
        nextIndex = currentIndex === -1 ? 0 : (currentIndex + 1) % clockwiseOrder.length
      } else {
        // Scroll up - move counter-clockwise
        nextIndex = currentIndex === -1 ? clockwiseOrder.length - 1 : (currentIndex - 1 + clockwiseOrder.length) % clockwiseOrder.length
      }
      
      const nextButton = clockwiseOrder[nextIndex]
      
      // Set the new selected button
      this.hardwareSettingsStore.setHoveredButton(nextButton)
    }
  },
  
  mounted() {
    // Start the animation sequence when the component mounts
    this.$nextTick(() => {
      this.animateButtonsIn()
      // Ensure device is selected when menu opens
      this.hardwareSettingsStore.setHoveredButton('device')
    })
  }
}
</script> 