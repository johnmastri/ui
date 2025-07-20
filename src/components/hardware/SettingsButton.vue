<template>
  <g>
 
    
    <!-- Original background color as overlay -->
    <rect width="400" height="240" fill="#AC3636" fill-opacity="0.67"/>

       <!-- Animated diagonal lines background -->
       <DiagonalLines />
    
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
    >
      {{ label }}
    </text>
  </g>
</template>

<script>
import DiagonalLines from './settings/DiagonalLines.vue'

export default {
  name: 'SettingsButton',
  components: {
    DiagonalLines
  },
  props: {
    label: {
      type: String,
      required: true
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
    }
  }
}
</script> 