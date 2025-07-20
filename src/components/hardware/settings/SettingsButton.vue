<template>
  <g 
    id="SettingsButton"
    @click="handleClick"
    @mouseenter="isHovered = true"
    @mouseleave="isHovered = false"
    style="cursor: pointer"
  >
    <rect 
      x="596" 
      y="158" 
      width="120" 
      height="24" 
      rx="12" 
      :stroke="isHovered ? '#B0B0B0' : '#DCDCDC'"
      :fill="isHovered ? '#3ED72A' : '#2A2A2A'"
      stroke-width="2"
    />
    <text 
      id="SettingsButtonText" 
      :fill="isHovered ? '#000000' : '#3ED72A'" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="Barlow" 
      font-size="14" 
      font-weight="bold" 
      letter-spacing="0.02em"
      text-anchor="middle"
    >
      <tspan x="656" y="174.6">{{ value }}</tspan>
    </text>
  </g>
</template>

<script>
export default {
  name: 'SettingsButton',
  props: {
    value: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      isHovered: false
    }
  },
  methods: {
    handleClick() {
      this.$emit('click', this.value)
    }
  }
}
</script> 