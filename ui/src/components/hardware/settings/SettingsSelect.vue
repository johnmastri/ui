<template>
  <g 
    id="SettingsSelect"
    @wheel="handleWheel"
    @mouseenter="isHovered = true"
    @mouseleave="isHovered = false"
    style="cursor: pointer"
  >
    <!-- Focus mode border box -->
    <rect
      v-if="isFocused"
      x="650"
      y="160"
      width="80"
      height="30"
      fill="none"
      stroke="#FFFFFF"
      stroke-width="2"
      rx="4"
    />
    
    <text 
      id="SettingsSelectValue" 
      :fill="isFocused ? '#FFFFFF' : '#3ED72A'" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="Barlow" 
      font-size="24" 
      font-weight="bold" 
      letter-spacing="0.04em"
      text-anchor="end"
    >
      <tspan x="716" y="179.6">{{ displayValue }}</tspan>
    </text>
    <!-- Hover indicator -->
    <text 
      v-if="isHovered && !isFocused"
      fill="#666666" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="Barlow" 
      font-size="12" 
      font-style="italic"
      letter-spacing="0.02em"
      text-anchor="end"
    >
      <tspan x="716" y="195">scroll to change</tspan>
    </text>
    <!-- Focus mode indicator -->
    <text 
      v-if="isFocused"
      fill="#FFFFFF" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="Barlow" 
      font-size="12" 
      font-style="italic"
      letter-spacing="0.02em"
      text-anchor="end"
    >
      <tspan x="716" y="195">middle click to confirm</tspan>
    </text>
  </g>
</template>

<script>
import { useHardwareSettingsStore } from '../../../stores/hardwareSettingsStore.js'

export default {
  name: 'SettingsSelect',
  props: {
    modelValue: {
      type: String,
      required: true
    },
    options: {
      type: Array,
      required: true
    },
    parameterId: {
      type: String,
      required: true
    }
  },
  setup() {
    const hardwareSettingsStore = useHardwareSettingsStore()
    return { hardwareSettingsStore }
  },
  data() {
    return {
      isHovered: false
    }
  },
  computed: {
    isFocused() {
      return this.hardwareSettingsStore.isSelectFocused && 
             this.hardwareSettingsStore.focusedParameterId === this.parameterId
    },
    displayValue() {
      if (this.isFocused) {
        return this.options[this.hardwareSettingsStore.highlightedSelectIndex] || this.modelValue
      }
      return this.modelValue
    }
  },
  mounted() {
    // Find current value index
    this.currentIndex = this.options.indexOf(this.modelValue)
    if (this.currentIndex === -1) {
      this.currentIndex = 0
    }
  },
  methods: {
    handleWheel(event) {
      event.preventDefault()
      
      if (this.isFocused) {
        // In focus mode, scroll through options
        const dir = event.deltaY > 0 ? 1 : -1
        this.hardwareSettingsStore.updateHighlightedSelectIndex(dir)
      } else {
        // Normal mode - emit change to parent
        if (event.deltaY > 0) {
          // Scroll down - next option
          this.currentIndex = (this.currentIndex + 1) % this.options.length
        } else {
          // Scroll up - previous option
          this.currentIndex = this.currentIndex === 0 ? this.options.length - 1 : this.currentIndex - 1
        }
        
        const newValue = this.options[this.currentIndex]
        this.$emit('update:modelValue', newValue)
        this.$emit('change', newValue)
      }
    }
  },
  watch: {
    modelValue(newValue) {
      this.currentIndex = this.options.indexOf(newValue)
      if (this.currentIndex === -1) {
        this.currentIndex = 0
      }
    }
  }
}
</script> 