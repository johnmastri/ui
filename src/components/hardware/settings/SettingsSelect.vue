<template>
  <g 
    id="SettingsSelect"
    @wheel="handleWheel"
    @mouseenter="isHovered = true"
    @mouseleave="isHovered = false"
    style="cursor: pointer"
  >
    <text 
      id="SettingsSelectValue" 
      fill="#3ED72A" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="Barlow" 
      font-size="24" 
      font-weight="bold" 
      letter-spacing="0.04em"
      text-anchor="end"
    >
      <tspan x="716" y="179.6">{{ currentValue }}</tspan>
    </text>
    <!-- Hover indicator -->
    <text 
      v-if="isHovered"
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
  </g>
</template>

<script>
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
    }
  },
  data() {
    return {
      isHovered: false,
      currentIndex: 0
    }
  },
  computed: {
    currentValue() {
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