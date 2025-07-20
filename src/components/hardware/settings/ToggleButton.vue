<template>
  <g 
    id="ToggleButton" 
    @click="toggle"
    @mouseenter="isHovered = true"
    @mouseleave="isHovered = false"
    style="cursor: pointer"
  >
    <rect 
      :x="x" 
      :y="y" 
      width="66" 
      height="24" 
      rx="12" 
      :stroke="isHovered ? '#B0B0B0' : '#DCDCDC'"
      :fill="modelValue ? '#3ED72A' : '#2A2A2A'"
      stroke-width="2"
    />
    <circle 
      :cx="modelValue ? (x + 56) : (x + 10)" 
      :cy="y + 12" 
      r="8" 
      :fill="isHovered ? '#FFFFFF' : '#EBEBEB'" 
      :stroke="isHovered ? '#A0A0A0' : '#D0D0D0'"
      stroke-width="1"
      style="transition: cx 0.2s ease"
    />
  </g>
</template>

<script>
export default {
  name: 'ToggleButton',
  props: {
    modelValue: {
      type: Boolean,
      default: false
    },
    x: {
      type: Number,
      default: 540.5
    },
    y: {
      type: Number,
      default: 158
    }
  },
  data() {
    return {
      isHovered: false
    }
  },
  methods: {
    toggle() {
      this.$emit('update:modelValue', !this.modelValue)
      this.$emit('change', !this.modelValue)
    }
  }
}
</script> 