<template>
  <g
    ref="BackButton"
    id="BackButton"
    @click="handleBack"
    @mouseenter="handleMouseEnter"
    @mouseleave="handleMouseLeave"
    style="cursor:pointer; pointer-events: auto !important;"
  >
    <rect 
      id="TransparentBack" 
      y="55" 
      width="128" 
      height="370" 
      :fill="isSelected ? '#3ED72A' : '#792929'"
      :fill-opacity="isSelected ? 0.8 : 0.64"
    />
    <rect 
      ref="backHighlight"
      id="BackHighlight" 
      y="55" 
      width="128" 
      height="370" 
      fill='#3ED72A' 
      :fill-opacity="1"
    />
    <g id="arrow_design_elements" ref="arrowElements">
      <path 
        id="Vector7" 
        d="M54.3137 106L43 117.314L54.3137 128.627V106Z" 
        :fill="isSelected ? '#fff' : '#000'"
      />
      <path 
        id="Vector8" 
        d="M54.3137 339.686L43 351L54.3137 362.314V339.686Z" 
        :fill="isSelected ? '#fff' : '#000'"
      />
      <path 
        id="Vector9" 
        d="M54.3137 222.686L43 234L54.3137 245.314V222.686Z" 
        :fill="isSelected ? '#fff' : '#000'"
      />
    </g>
    <text 
      id="BACK" 
      transform="translate(65 60)" 
      :fill="isSelected ? '#000' : '#fff'"
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
      :fill="isSelected ? '#000' : '#000'"
    />
  </g>
</template>

<script>
import { gsap } from 'gsap'

export default {
  name: 'BackButton',
  props: {
    isSelected: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      arrowTween: null
    }
  },
  watch: {
    isSelected(newVal) {
      if (newVal) {
        this.startArrowAnimation()
        this.highlight()
      } else {
        this.stopArrowAnimation()
        this.unhighlight()
      }
    }
  },
  mounted() {
    // Set initial state for back highlight
    gsap.set(this.$refs.backHighlight, {
      transformOrigin: 'bottom left',
      scaleY: 0
    })
  },
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

    highlight() {
      gsap.to(this.$refs.backHighlight, {
        scaleY: 1,
        duration: 0.3,
        ease: 'power2.out'
      })
    },

    unhighlight() {
      gsap.to(this.$refs.backHighlight, {
        scaleY: 0,
        duration: 0.3,
        ease: 'power2.out'
      })
    },

    handleBack() {
      console.log('BackButton: handleBack called')
      console.log('BackButton: Element style:', this.$el.style.pointerEvents)
      this.$emit('back')
    },

    handleMouseEnter() {
      if (!this.isSelected) {
        this.startArrowAnimation()
      }
    },

    handleMouseLeave() {
      if (!this.isSelected) {
        this.stopArrowAnimation()
      }
    },

    startArrowAnimation() {
      if (this.arrowTween) return
      this.arrowTween = gsap.to(this.$refs.arrowElements, {
        x: 20,
        repeat: -1,
        yoyo: true,
        duration: 0.5,
        ease: 'power1.inOut'
      })
    },

    stopArrowAnimation() {
      if (this.arrowTween) {
        this.arrowTween.kill()
        this.arrowTween = null
        gsap.set(this.$refs.arrowElements, { x: 0 })
      }
    }
  },
  beforeUnmount() {
    this.stopArrowAnimation()
  }
}
</script>

<style scoped>
#BackButton {
  opacity: 0;
}
</style> 