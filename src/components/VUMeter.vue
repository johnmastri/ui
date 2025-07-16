<template>
  <div class="vu-meter-frame" :class="{ 'hardware-mode': isHardwareRoute }">
    <!-- Bezel Frame -->
    <div class="bezel-frame">
      <!-- Main VU Meter Display -->
      <div class="vu-meter-display">
        <!-- Title -->
        <div class="vu-title">VU LEVEL INDICATOR</div>
        
        <!-- Scale Numbers -->
        <div class="scale-numbers">
          <!-- Black numbers (negative dB) -->
          <div class="black-numbers">
            <span class="number n-20" style="left: 63px; top: 131px;">-20</span>
            <span class="number n-10" style="left: 120px; top: 108px;">-10</span>
            <span class="number n-7" style="left: 178px; top: 90px;">-7</span>
            <span class="number n-5" style="left: 232px; top: 78px;">-5</span>
            <span class="number n-3" style="left: 317px; top: 68px;">-3</span>
            <span class="number n-2" style="left: 369px; top: 66px;">-2</span>
            <span class="number n-1" style="left: 437px; top: 68px;">-1</span>
            <span class="number n-0" style="left: 510px; top: 74px;">0</span>
          </div>
          
          <!-- Red numbers (positive dB) -->
          <div class="red-numbers">
            <span class="number-red n-p1" style="left: 577px; top: 85px;">+1</span>
            <span class="number-red n-p2" style="left: 653px; top: 105px;">+2</span>
            <span class="number-red n-p3" style="left: 700px; top: 135px;">+3</span>
          </div>
        </div>

        <!-- VU Labels -->
        <div class="vu-labels">
          <div class="vu-label-left">VU</div>
          <div class="vu-label-right">
            <div class="red-vu-box">VU</div>
          </div>
        </div>

        <!-- Meter Arc and Markings -->
        <div class="meter-container">
          <!-- Background arc -->
          <div class="meter-arc-bg"></div>
          
          <!-- Scale markings -->
          <div class="scale-markings">
            <!-- Major tick marks -->
            <div class="tick-mark tick-n20" style="transform: rotate(-120deg);"></div>
            <div class="tick-mark tick-n10" style="transform: rotate(-90deg);"></div>
            <div class="tick-mark tick-n7" style="transform: rotate(-72deg);"></div>
            <div class="tick-mark tick-n5" style="transform: rotate(-60deg);"></div>
            <div class="tick-mark tick-n3" style="transform: rotate(-36deg);"></div>
            <div class="tick-mark tick-n2" style="transform: rotate(-24deg);"></div>
            <div class="tick-mark tick-n1" style="transform: rotate(-12deg);"></div>
            <div class="tick-mark tick-0" style="transform: rotate(0deg);"></div>
            
            <!-- Red zone markings -->
            <div class="tick-mark tick-red tick-p1" style="transform: rotate(12deg);"></div>
            <div class="tick-mark tick-red tick-p2" style="transform: rotate(30deg);"></div>
            <div class="tick-mark tick-red tick-p3" style="transform: rotate(48deg);"></div>
          </div>
          
          <!-- Red arc overlay for positive values -->
          <div class="red-arc-overlay"></div>
          
          <!-- Needle -->
          <div ref="needleElement" class="needle-container">
            <div class="needle"></div>
          </div>
          
          <!-- Center hub -->
          <div class="center-hub"></div>
        </div>

        <!-- MASTR/ Branding -->
        <div class="branding">
          <div class="mastr-logo">MASTR/</div>
          <div class="design-engineering">DESIGN ENGINEERING</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { gsap } from 'gsap'

export default {
  name: 'VUMeter',
  
  props: {
    level: {
      type: Number,
      default: -10, // dB value
      validator: value => value >= -60 && value <= 12
    },
    smoothing: {
      type: Number,
      default: 0.1,
      validator: value => value >= 0 && value <= 1
    },
    animated: {
      type: Boolean,
      default: true // Enable realistic animation by default
    }
  },
  
  data() {
    return {
      currentLevel: -20, // Start at low level
      isAnimating: false, // Track animation state
      needleElement: null, // Will be set via ref
      animationTimeout: null
    }
  },
  
  computed: {
    // Route detection for hardware view
    isHardwareRoute() {
      return this.$route.name === 'Hardware'
    },
    
    // External level display for debugging
    displayLevel() {
      return `${this.currentLevel.toFixed(1)} dB`
    }
  },
  
  methods: {
    // Convert dB level to needle rotation angle
    levelToRotation(level) {
      // Map dB values to rotation angles
      // -20dB = -120deg, 0dB = 0deg, +3dB = +48deg
      const clampedLevel = Math.max(-20, Math.min(3, level))
      
      if (clampedLevel <= 0) {
        // Linear mapping from -20dB (-120deg) to 0dB (0deg)
        return (clampedLevel + 20) * 6 - 120 // 6 degrees per dB in negative range
      } else {
        // Linear mapping from 0dB (0deg) to +3dB (+48deg)
        return clampedLevel * 16 // 16 degrees per dB in positive range
      }
    },
    
    // Simple animation that directly animates the needle rotation
    animateNeedle() {
      // Stop recursion if animation is disabled
      if (!this.isAnimating) return
      
      // Store previous level for comparison
      const previousLevel = this.currentLevel
      
      // Generate target level with realistic audio characteristics
      const baseLevel = -25
      const variation = (Math.random() - 0.5) * 20 // ±10dB variation
      const microNoise = (Math.random() - 0.5) * 3 // ±1.5dB noise
      
      // Occasional peaks (30% chance)
      const hasPeak = Math.random() < 0.3
      const peakBoost = hasPeak ? Math.random() * 15 : 0 // 0-15dB boost for peaks
      
      let targetLevel = baseLevel + variation + microNoise + peakBoost
      
      // Clamp to realistic range
      targetLevel = Math.max(-35, Math.min(3, targetLevel))
      
      // Calculate target rotation
      const targetRotation = this.levelToRotation(targetLevel)
      
      // Update reactive value
      this.currentLevel = targetLevel
      
      // Determine movement direction for realistic physics
      const isMovingUp = targetLevel > previousLevel
      const duration = hasPeak ? 0.05 : (isMovingUp ? 0.1 : 0.3) // Fast peaks, slower normal movement
      const ease = hasPeak ? "power3.out" : (isMovingUp ? "power2.out" : "power1.inOut")
      
      gsap.to(this.needleElement, {
        rotation: 10, // targetRotation,
        duration: duration,
        ease: ease,
        force3D: true,
        yoyo: true,
        
      })
    },
    
    // Add continuous micro movements
    addMicroMovements() {
      // Stop recursion if animation is disabled
      if (!this.isAnimating) return
      
      const currentRotation = gsap.getProperty(this.needleElement, "rotation")
      const microVariation = (Math.random() - 0.5) * 2 // ±1 degree micro movement
      
      gsap.to(this.needleElement, {
        rotation: currentRotation + microVariation,
        duration: 0.1 + Math.random() * 0.2,
        ease: "sine.inOut",
        onComplete: () => {
          // Only schedule next micro movement if animation is still enabled
          if (this.isAnimating) {
            gsap.delayedCall(0.05 + Math.random() * 0.1, this.addMicroMovements)
          }
        }
      })
    },
    
    // Simple, working GSAP animation
    createRealisticAnimation() {
      if (!this.animated || !this.needleElement) return
      
      // Set initial needle position
      const initialRotation = this.levelToRotation(-20)
      gsap.set(this.needleElement, {
        rotation: initialRotation,
        transformOrigin: "50% 50%",
        force3D: true
      })
      
      // Start both animations
      this.animateNeedle()
      gsap.delayedCall(0.5, this.addMicroMovements) // Start micro movements after initial movement
    },
    
    // Start/stop animation
    startAnimation() {
      if (!this.animated || !this.needleElement || this.isAnimating) return
      
      console.log('🎚️ Starting VU meter animation...')
      this.isAnimating = true
      
      // Start realistic animation
      this.createRealisticAnimation()
    },
    
    stopAnimation() {
      console.log('🎚️ Stopping VU meter animation...')
      this.isAnimating = false
      
      // Kill all GSAP animations on the needle
      if (this.needleElement) {
        gsap.killTweensOf(this.needleElement)
      }
      
      // Kill any delayed calls
      gsap.killDelayedCallsTo(this.startAnimation)
    },
    
    // Toggle animation on/off
    toggleAnimation() {
      if (this.isAnimating) {
        this.stopAnimation()
      } else {
        this.startAnimation()
      }
      console.log(`🎚️ VU Meter Animation: ${this.isAnimating ? '🟢 ON' : '🔴 OFF'} (Press 'N' to toggle)`)
    },
    
    // External level control (for when animation is disabled)
    updateLevel(newLevel) {
      if (!this.animated && this.needleElement) {
        const clampedLevel = Math.max(-60, Math.min(12, newLevel))
        this.currentLevel = clampedLevel
        
        // Set needle position directly without animation
        gsap.set(this.needleElement, {
          rotation: this.levelToRotation(clampedLevel),
          transformOrigin: "50% 50%",
          force3D: true
        })
      }
    },
    
    // Keyboard event handler
    handleKeyDown(event) {
      // Toggle animation with 'N' key
      if (event.key.toLowerCase() === 'n') {
        event.preventDefault()
        this.toggleAnimation()
      }
    }
  },
  
  mounted() {
    console.log('🎚️ VU Meter mounted, animated:', this.animated, '(Press "N" to toggle animation)')
    
    // Get needle element reference
    this.needleElement = this.$refs.needleElement
    
    // Add keyboard event listener
    window.addEventListener('keydown', this.handleKeyDown)
    
    // Wait for next tick to ensure DOM element is available
    if (this.animated) {
      this.animationTimeout = setTimeout(() => {
        console.log('🎚️ Starting animation after timeout...')
        this.startAnimation()
      }, 100)
    }
  },
  
  beforeUnmount() {
    this.stopAnimation()
    
    // Clear timeout if it exists
    if (this.animationTimeout) {
      clearTimeout(this.animationTimeout)
    }
    
    // Remove keyboard event listener
    window.removeEventListener('keydown', this.handleKeyDown)
  }
}
</script>

<style scoped>
.vu-meter-frame {
  width: 800px;
  height: 480px;
  position: relative;
  background: #5b5c59;
  box-shadow: 13px 10px 19.8px 0px rgba(0,0,0,0.33);
}

/* Hardware route: make VUMeter responsive to container */
.vu-meter-frame.hardware-mode {
  width: 100%;
  height: 100%;
  max-width: 800px;
  max-height: 480px;
  /* Scale down proportionally if container is smaller */
  object-fit: contain;
  /* Maintain aspect ratio */
  aspect-ratio: 800 / 480;
  /* Center the meter if there's extra space */
  margin: auto;
  /* Ensure it doesn't overflow container */
  box-sizing: border-box;
}

/* Fallback for browsers without aspect-ratio support */
@supports not (aspect-ratio: 800 / 480) {
  .vu-meter-frame.hardware-mode {
    /* Use container query or scale transform as fallback */
    transform-origin: center center;
  }
  
  .vu-meter-frame.hardware-mode:where(.container-height-420) {
    /* When WebSocket header is visible (420px available) */
    transform: scale(0.875); /* 420/480 = 0.875 */
  }
}

.bezel-frame {
  position: absolute;
  inset: 0;
  background: linear-gradient(135deg, #62665a 0%, #283026 100%);
  border: 2px solid #333;
}

.vu-meter-display {
  position: absolute;
  left: 50px;
  top: 50px;
  right: 50px;
  bottom: 50px;
  background: linear-gradient(to bottom, #d5d28f 0%, #fef888 100%);
  border-radius: 8px;
  overflow: hidden;
}

.vu-title {
  position: absolute;
  top: 32px;
  left: 50%;
  transform: translateX(-50%);
  font-family: 'Courier New', monospace;
  font-size: 24.18px;
  font-weight: 500;
  color: #504523;
  letter-spacing: 1px;
  text-align: center;
}

.scale-numbers {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
}

.black-numbers .number {
  position: absolute;
  font-family: 'Courier New', monospace;
  font-size: 24.18px;
  font-weight: 500;
  color: #392e20;
  transform: translateX(-50%);
}

.red-numbers .number-red {
  position: absolute;
  font-family: 'Courier New', monospace;
  font-size: 24.18px;
  font-weight: 500;
  color: #ce242b;
  transform: translateX(-50%);
}

.vu-labels {
  position: absolute;
  top: 140px;
  left: 0;
  width: 100%;
}

.vu-label-left {
  position: absolute;
  left: 81px;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  font-weight: 900;
  color: #504523;
}

.vu-label-right {
  position: absolute;
  right: 80px;
}

.red-vu-box {
  background: #ce242b;
  color: #fef888;
  padding: 6px 12px;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  font-weight: 900;
}

.meter-container {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 400px;
  height: 400px;
}

.meter-arc-bg {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 340px;
  height: 340px;
  border: 2.43px solid #000;
  border-radius: 50%;
}

.scale-markings {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 360px;
  height: 360px;
}

.tick-mark {
  position: absolute;
  top: 10px;
  left: 50%;
  width: 2.43px;
  height: 40px;
  background: #000;
  transform-origin: 50% 170px;
  margin-left: -1.215px;
}

.tick-mark.tick-red {
  background: #ce242b;
  height: 45px;
}

.red-arc-overlay {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 340px;
  height: 340px;
  border: 6.61px solid transparent;
  border-radius: 50%;
  border-top-color: #ce242b;
  border-right-color: #ce242b;
  clip-path: polygon(50% 50%, 100% 0%, 100% 50%, 85% 85%);
}

.needle-container {
  position: absolute;
  top: 50%;
  left: 50%;
  transform-origin: 50% 50%;
  /* GPU acceleration for smooth GSAP animation */
  will-change: transform;
  /* GSAP handles all transitions - no CSS transitions needed */
  /* Prevent subpixel rendering issues */
  backface-visibility: hidden;
  transform-style: preserve-3d;
}

.needle {
  position: absolute;
  width: 4px;
  height: 120px;
  background: #000;
  left: -2px;
  top: -110px;
  clip-path: polygon(0% 100%, 50% 85%, 100% 100%, 45% 0%, 55% 0%);
}

.center-hub {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 16px;
  height: 16px;
  background: #000;
  border-radius: 50%;
  z-index: 10;
}

.branding {
  position: absolute;
  bottom: 60px;
  left: 50%;
  transform: translateX(-50%);
  text-align: center;
}

.mastr-logo {
  font-family: 'Courier New', monospace;
  font-size: 48px;
  font-weight: 900;
  color: #16150d;
  opacity: 0.66;
  letter-spacing: 2px;
  margin-bottom: 8px;
}

.design-engineering {
  font-family: 'Courier New', monospace;
  font-size: 11.9px;
  font-weight: 500;
  color: #16150d;
  opacity: 0.66;
  letter-spacing: 2.261px;
}

/* Responsive adjustments for exact pixel positioning */
@media (max-width: 800px) {
  .vu-meter-frame {
    transform: scale(0.8);
    transform-origin: top left;
  }
}
</style>
