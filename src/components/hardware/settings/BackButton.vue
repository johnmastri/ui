<template>
  <g
    ref="BackButton"
    id="BackButton"
    @click="handleBack"
    style="cursor:pointer; pointer-events: auto !important;"
  >
    <rect 
      id="TransparentBack" 
      y="55" 
      width="128" 
      height="370" 
      fill="#792929" 
      fill-opacity="0.64"
    />
    <g id="arrow_design_elements">
      <path 
        id="Vector 7" 
        d="M54.3137 106L43 117.314L54.3137 128.627V106Z" 
        fill="black"
      />
      <path 
        id="Vector 8" 
        d="M54.3137 339.686L43 351L54.3137 362.314V339.686Z" 
        fill="black"
      />
      <path 
        id="Vector 9" 
        d="M54.3137 222.686L43 234L54.3137 245.314V222.686Z" 
        fill="black"
      />
    </g>
    <text 
      id="BACK" 
      transform="translate(65 60)" 
      fill="white" 
      xml:space="preserve" 
      style="white-space: pre" 
      font-family="Barlow" 
      font-size="20" 
      font-weight="600" 
      letter-spacing="0.04em"
    >
      <tspan x="0.317577" y="20">BACK</tspan>
    </text>
    <path 
      id="corner_triangle" 
      d="M28 40H0V68L28 40Z" 
      fill="black"
    />
  </g>
</template>

<script>
import { gsap } from 'gsap'

export default {
  name: 'BackButton',
  
  methods: {
    fadeIn() {
      gsap.to(this.$refs.BackButton, {
        opacity: 1,
        duration: 0.5,
        ease: "power2.out"
      })
    },

    fadeOut() {
      gsap.to(this.$refs.BackButton, {
        opacity: 0,
        duration: 0.3,
        ease: "power2.in"
      })
    },

    handleBack() {
      console.log('BackButton: handleBack called')
      console.log('BackButton: Element style:', this.$el.style.pointerEvents)
      this.$emit('back')
    }
  }
}
</script>

<style scoped>
#BackButton {
  opacity: 0;
}
</style> 