<template>
  <g>
    <!-- 2x2 Grid of Settings Buttons -->
    <g v-for="(btn, idx) in buttons" :key="btn.id" :transform="`translate(${btn.x}, ${btn.y})`">
      <SettingsButton 
        :label="btn.label"
        @click="handleButtonClick(btn.id)"
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

export default {
  name: 'SettingsMenu',
  components: {
    SettingsButton
  },
  emits: ['close'],
  data() {
    return {
      buttons: [
        { id: 'device', label: 'DEVICE', x: 0,   y: 0 },
        { id: 'network', label: 'NETWORK', x: 400, y: 0 },
        { id: 'display', label: 'DISPLAY', x: 0,   y: 240 },
        { id: 'midi', label: 'MIDI', x: 400, y: 240 }
      ]
    }
  },
  methods: {
    handleButtonClick(id) {
      // Placeholder for future submenu logic
      console.log('Settings button clicked:', id)
    },
    emitClose() {
      this.$emit('close')
    }
  }
}
</script> 