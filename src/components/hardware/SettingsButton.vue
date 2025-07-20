<template>
  <g
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
    style="cursor: pointer;"
  >
    <!-- Original background color as overlay -->
    <rect 
      ref="backgroundRect"
      width="400" 
      height="240" 
      fill="#AC3636" 
      :fill-opacity="backgroundOpacity"
    />

    <!-- Animated diagonal lines background -->
    <DiagonalLines :should-animate="isSelected" :button-id="buttonId" />
    
    <!-- SVG lines omitted for brevity, copy from SettingsButton.svg -->
    <g><!-- ... lines ... --></g>
    
    <text
      fill="white"
      xml:space="preserve"
      style="white-space: pre"
      font-family="Barlow"
      font-size="36"
      font-style="italic"
      font-weight="bold"
      letter-spacing="0.04em"
      :x="labelX"
      :y="labelY"
      text-anchor="middle"
      dominant-baseline="middle"
    >
      {{ label }}
    </text>
  </g>
</template>

<script>
import DiagonalLines from './settings/DiagonalLines.vue'
import { gsap } from 'gsap'
import { useHardwareSettingsStore } from '../../stores/hardwareSettingsStore'

export default {
  name: 'SettingsButton',
  components: {
    DiagonalLines
  },
  props: {
    label: {
      type: String,
      required: true
    },
    buttonId: {
      type: String,
      required: true
    },
    isSelected: {
      type: Boolean,
      default: false
    }
  },
  
  data() {
    return {
      backgroundOpacity: 0.67 // Will be set to button's defaultOpacity in mounted
    }
  },
  
  computed: {
    labelX() {
      // Center of the 400px wide rectangle
      return 200;
    },
    labelY() {
      // Center of the 240px height rectangle
      return 120;
    },
    buttonData() {
      const hardwareSettingsStore = useHardwareSettingsStore()
      return hardwareSettingsStore.buttons.find(btn => btn.id === this.buttonId)
    },
    defaultOpacity() {
      return this.buttonData?.defaultOpacity || 0.67
    }
  },
  
  mounted() {
    // Set initial opacity to button's default
    this.backgroundOpacity = this.defaultOpacity
  },
  
  methods: {
    handleMouseEnter() {
      const hardwareSettingsStore = useHardwareSettingsStore()
      hardwareSettingsStore.setHoveredButton(this.buttonId)
    },
    
    handleMouseLeave() {
      const hardwareSettingsStore = useHardwareSettingsStore()
      hardwareSettingsStore.clearHoveredButton()
    }
  },
  
  watch: {
    isSelected(newValue) {
      // Animate background opacity with GSAP
      gsap.to(this, {
        backgroundOpacity: newValue ? 0.9 : this.defaultOpacity,
        duration: 0.2,
        ease: "power2.out"
      })
    }
  }
}
</script> 