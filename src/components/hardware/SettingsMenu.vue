<template>
  <g>
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
    <g
      @click="emitClose"
      style="cursor:pointer;"
      :transform="'translate(359,199)'"
    >
      <!-- CloseButton.svg -->
      <svg width="82" height="82" viewBox="0 0 82 82" fill="none" xmlns="http://www.w3.org/2000/svg">
        <g id="Close Button">
          <rect id="Rectangle 10" width="82" height="82" fill="#101010"/>
          <g id="X">
            <path id="Icon" d="M61.5 20.5L20.5 61.5M20.5 20.5L61.5 61.5" stroke="#EDEDED" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
          </g>
        </g>
      </svg>
    </g>
  </g>
</template>

<script>
import SettingsButton from './SettingsButton.vue'
import { useHardwareSettingsStore } from '../../stores/hardwareSettingsStore'

export default {
  name: 'SettingsMenu',
  components: {
    SettingsButton
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
    }
  }
}
</script> 