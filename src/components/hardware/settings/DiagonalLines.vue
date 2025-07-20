<template>
  <g>
    <!-- Pattern definition for diagonal lines -->
    <defs>
      <pattern id="diagonalLines" patternUnits="userSpaceOnUse" width="20" height="20" x="0" y="0" ref="pattern">
        <path d="M-1,1 l2,-2 M0,20 l20,-20 M19,21 l2,-2" 
              stroke="rgba(0,0,0,1)" 
              stroke-width="2"
              stroke-linecap="square"
              ref="diagonalLine"/>
      </pattern>
    </defs>
    
    <!-- Background rectangle with pattern -->
    <rect width="100%" height="100%" fill="url(#diagonalLines)" ref="background"/>
  </g>
</template>

<script>
import { gsap } from 'gsap'

export default {
  name: 'DiagonalLines',
  
  mounted() {
    this.initAnimations()
  },
  
  methods: {
    initAnimations() {
      // Animate the pattern's x and y attributes for seamless movement
      gsap.to(this.$refs.pattern, {
        attr: { x:- 20, y: -20 },
        duration: 3,
        repeat: -1,
        ease: "none",
        onRepeat: () => {
          // Reset position for seamless loop
          if (this.$refs.pattern) {
            this.$refs.pattern.setAttribute('x', 0)
            this.$refs.pattern.setAttribute('y', 0)
          }
        }
      })
      
      // Animate line width
      gsap.to(this.$refs.diagonalLine, {
        attr: { "stroke-width": 6 },
        duration: 2,
        repeat: -1,
        yoyo: true,
        ease: "power2.inOut"
      })
    }
  }
}
</script> 