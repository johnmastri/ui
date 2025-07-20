<template>
  <g @wheel="handleWheel">
    <!-- 2x2 Grid of Settings Buttons -->
    <g 
      v-for="(btn, idx) in hardwareSettingsStore.buttons" 
      :key="btn.id" 
      :transform="`translate(${btn.x}, ${btn.y})`"
      @mouseenter="handleMouseEnter(btn.id)"
      @mouseleave="handleMouseLeave"
    >
      <SettingsButton 
        :label="btn.label"
        :button-id="btn.id"
        :is-selected="isButtonSelected(btn.id)"
      />
    </g>
    
    <!-- Close Button -->
    <CloseButton 
      :is-selected="isButtonSelected('close')"
      @close="emitClose"
      @mouseenter="handleMouseEnter('close')"
      @mouseleave="handleMouseLeave"
    />
  </g>
</template>

<script>
import SettingsButton from './SettingsButton.vue'
import CloseButton from './CloseButton.vue'
import { useHardwareSettingsStore } from '../../stores/hardwareSettingsStore'

export default {
  name: 'SettingsMenu',
  components: {
    SettingsButton,
    CloseButton
  },
  emits: ['close'],
  setup() {
    const hardwareSettingsStore = useHardwareSettingsStore()
    
    const isButtonSelected = (buttonId) => {
      return hardwareSettingsStore.currentSelectedButton === buttonId
    }
    
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
      isButtonSelected,
      handleMouseEnter,
      handleMouseLeave,
      emitClose
    }
  },
  methods: {
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
      
      // Set the new selected button
      this.hardwareSettingsStore.setHoveredButton(clockwiseOrder[nextIndex])
    }
  }
}
</script> 