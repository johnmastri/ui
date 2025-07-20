<template>
  <g
    ref="closeButtonElement"
    @click="$emit('close')"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
    style="cursor:pointer;"
    :transform="'translate(359,199)'"
  >
    <g id="Close Button">
      <rect 
        id="Rectangle 10" 
        ref="closeButtonBg"
        width="82" 
        height="82" 
        fill="#101010"
        transform-origin="center"
      />
      <g 
        id="X"
        ref="xIcon"
        transform-origin="center"
      >
        <path 
          id="Icon" 
          ref="xIconPath"
          d="M61.5 20.5L20.5 61.5M20.5 20.5L61.5 61.5" 
          stroke="#EDEDED" 
          stroke-width="4" 
          stroke-linecap="round" 
          stroke-linejoin="round"
        />
      </g>
    </g>
  </g>
</template>

<script>
import { gsap } from 'gsap'

export default {
  name: 'CloseButton',
  emits: ['close', 'mouseenter', 'mouseleave'],
  props: {
    isSelected: {
      type: Boolean,
      default: false
    },
    isExpanded: {
      type: Boolean,
      default: false
    }
  },
  
  methods: {
    animateIn() {
      if (this.$refs.closeButtonElement) {
        gsap.to(this.$refs.closeButtonElement, {
          opacity: 1,
          duration: 0.8,
          ease: "bounce.out"
        })
      }
    },
    
    handleMouseEnter() {
      if (!this.isExpanded) {
        this.$emit('mouseenter')
      }
    },
    
    handleMouseLeave() {
      if (!this.isExpanded) {
        this.$emit('mouseleave')
      }
    }
  },
  
  watch: {
    isSelected(newValue) {
      // Don't change colors if the button is expanded
      if (this.isExpanded) {
        return
      }
      
      if (newValue) {
        // Scale up background square
        gsap.to(this.$refs.closeButtonBg, {
          scale: 1.1,
          duration: 0.15,
          ease: "power2.out",
          transformOrigin: "center"
        })
        
        // Scale up X icon
        gsap.to(this.$refs.xIcon, {
          scale: 1.2,
          duration: 0.15,
          ease: "power2.out",
          transformOrigin: "center center"
        })
        
        // Invert colors: background to white, X to black
        gsap.to(this.$refs.closeButtonBg, {
          fill: "#FFFFFF",
          duration: 0.15,
          ease: "power2.out"
        })
        
        gsap.to(this.$refs.xIconPath, {
          stroke: "#000000",
          duration: 0.15,
          ease: "power2.out"
        })
      } else {
        // Scale down background square
        gsap.to(this.$refs.closeButtonBg, {
          scale: 1,
          duration: 0.15,
          ease: "power2.out",
          transformOrigin: "center"
        })
        
        // Scale down X icon
        gsap.to(this.$refs.xIcon, {
          scale: 1,
          duration: 0.15,
          ease: "power2.out",
          transformOrigin: "center center"
        })
        
        // Restore original colors: background to black, X to white
        gsap.to(this.$refs.closeButtonBg, {
          fill: "#101010",
          duration: 0.15,
          ease: "power2.out"
        })
        
        gsap.to(this.$refs.xIconPath, {
          stroke: "#EDEDED",
          duration: 0.15,
          ease: "power2.out"
        })
      }
    }
  }
}
</script> 