<template>
  <g>
    <!-- Pattern definition for diagonal lines -->
    <defs>
      <pattern :id="patternId" patternUnits="userSpaceOnUse" width="20" height="20" x="0" y="0" ref="pattern">
        <path d="M-1,1 l2,-2 M0,20 l20,-20 M19,21 l2,-2" 
              stroke="rgba(0,0,0,1)" 
              stroke-width="2"
              stroke-linecap="square"
              ref="diagonalLine"/>
      </pattern>
    </defs>
    
    <!-- Background rectangle with pattern -->
    <rect width="400px" height="240px" :fill="`url(#${patternId})`" ref="background"/>
  </g>
</template>

<script>
import { gsap } from 'gsap'


export default {
  name: 'DiagonalLines',
  props: {
    shouldAnimate: {
      type: Boolean,
      default: false
    },
    buttonId: {
      type: String,
      required: true
    }
  },
  
  data() {
    return {
      animations: {
        pattern: null,
        line: null
      }
    }
  },
  
  computed: {
    patternId() {
      return `diagonalLines-${this.buttonId}`
    }
  },
  
  watch: {
    shouldAnimate(newValue, oldValue) {
      // Only start/stop if the value actually changed
      if (newValue !== oldValue) {
        if (newValue) {
          this.startAnimations()
        } else {
          this.stopAnimations()
        }
      }
    }
  },
  
  mounted() {
    if (this.shouldAnimate) {
      this.startAnimations()
    }
  },
  
  beforeUnmount() {
    this.stopAnimations()
  },
  
  methods: {
    startAnimations() {
      // Stop any existing animations first
      this.stopAnimations()
      
      // Ensure refs are available
      if (!this.$refs.pattern || !this.$refs.diagonalLine) {
        return
      }
      
      // Reset pattern position to ensure clean start
      this.$refs.pattern.setAttribute('x', 0)
      this.$refs.pattern.setAttribute('y', 0)
      
      // Animate the pattern's x and y attributes for seamless movement
      this.animations.pattern = gsap.to(this.$refs.pattern, {
        attr: { x: -20, y: -20 },
        duration: 5,
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
      
      // Animate line width from 2 to 9 and stay at 9
      this.animations.line = gsap.to(this.$refs.diagonalLine, {
        attr: { "stroke-width": 9 },
        duration: 0.5,
        ease: "power2.out"
      })
    },
    
    stopAnimations() {
      if (this.animations.pattern) {
        this.animations.pattern.kill()
        this.animations.pattern = null
      }
      if (this.animations.line) {
        this.animations.line.kill()
        this.animations.line = null
      }
      
      // Reset pattern position to ensure clean state
      if (this.$refs.pattern) {
        this.$refs.pattern.setAttribute('x', 0)
        this.$refs.pattern.setAttribute('y', 0)
      }
      
      // Animate line width back to 2 when stopping
      if (this.$refs.diagonalLine) {
        gsap.to(this.$refs.diagonalLine, {
          attr: { "stroke-width": 2 },
          duration: 0.3,
          ease: "power2.out"
        })
      }
    }
  }
}
</script> 