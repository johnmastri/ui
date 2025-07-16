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
import AudioAnalysisService from '../services/AudioAnalysisService'
import { useAudioControlStore } from '../stores/audioControlStore'

export default {
  name: 'VUMeter',
  
  props: {
    animated: {
      type: Boolean,
      default: true
    }
  },
  
  data() {
    return {
      needleElement: null,
      audioService: null,
      store: null,
      isInitialized: false
    }
  },
  
  computed: {
    // Route detection for hardware view
    isHardwareRoute() {
      return this.$route.name === 'Hardware'
    },
    
    // Get current volume from audio service
    currentVolume() {
      return this.audioService ? this.audioService.getCurrentVolume() : 0
    },
    
    // Get current dB level from audio service  
    currentDbLevel() {
      return this.audioService ? this.audioService.getCurrentDbLevel() : -60
    }
  },
  
  methods: {
    // Convert volume (0-100) to needle rotation angle
    volumeToAngle(volume) {
      const restPosition = 70 // Above 2 o'clock (rest position)
      const maxDeflection = 130 // Total range (70° to -60°)
      
      // volume 0 = rest position, volume 100 = full deflection counterclockwise
      const deflection = (volume / 100) * maxDeflection
      return restPosition - deflection // Counterclockwise movement
    },
    
    // Simple needle update - volume -> angle -> animate
    updateNeedle() {
      if (!this.needleElement || !this.audioService) return
      
      // 1. Get current volume level (0-100)
      const volume = this.audioService.getCurrentVolume()
      
      // 2. Convert to angle
      const targetAngle = this.volumeToAngle(volume)
      
      // 3. Animate to angle
      gsap.to(this.needleElement, {
        rotation: targetAngle,
        duration: 0.1, // Fast response
        ease: "power2.out",
        force3D: true
      })
    },
    
    // Start needle update loop
    startNeedleUpdates() {
      const updateLoop = () => {
        this.updateNeedle()
        requestAnimationFrame(updateLoop)
      }
      updateLoop()
      console.log('🎚️ Needle updates started')
    },
    
    // Initialize audio service and store integration
    async initAudio() {
      try {
        // Create audio service
        this.audioService = new AudioAnalysisService()
        await this.audioService.init()
        
        // Get store reference
        this.store = useAudioControlStore()
        
        // Connect audio service to store for modal control
        this.store.setAudioService(this.audioService)
        
        // Watch for store changes
        this.$watch(() => this.store.selectedTrackId, this.onTrackChange, { immediate: true })
        this.$watch(() => this.store.outputGain, this.onVolumeChange, { immediate: true })
        this.$watch(() => this.store.isPlaying, this.onPlayStateChange)
        
        this.isInitialized = true
        console.log('✅ VU Meter audio initialized')
        
      } catch (error) {
        console.error('❌ Failed to initialize VU Meter audio:', error)
      }
    },
    
    // Handle track changes from store
    async onTrackChange(trackId) {
      if (!this.audioService || !this.store) {
        console.log('⚠️ onTrackChange: Missing audioService or store')
        return
      }
      
      const track = this.store.currentTrack
      if (!track) {
        console.log('⚠️ onTrackChange: No current track found for ID:', trackId)
        return
      }
      
      console.log('🔄 Loading track:', track.name, 'URL:', track.url)
      
      try {
        this.store.setLoading(true)
        const loadSuccess = await this.audioService.loadTrack(track.url)
        
        if (loadSuccess) {
          this.store.markTrackLoaded(trackId, false)
          this.store.setFallbackMode(false)
          console.log('✅ Track loaded successfully:', track.name)
        } else {
          console.log('⚠️ Track load failed, using fallback audio for:', track.name)
          // Still mark as loaded since we have fallback
          this.store.markTrackLoaded(trackId, true)
          this.store.setFallbackMode(true)
        }
        
        this.store.setLoading(false)
      } catch (error) {
        console.error('❌ Failed to load track:', track.name, error)
        this.store.setFallbackMode(true)
        this.store.setLoading(false)
      }
    },
    
    // Handle volume changes from store
    onVolumeChange(dbLevel) {
      if (this.audioService) {
        this.audioService.setVolume(dbLevel)
      }
    },
    
    // Handle play state changes from store
    onPlayStateChange(isPlaying) {
      if (!this.audioService) return
      
      if (isPlaying) {
        this.audioService.play()
      } else {
        this.audioService.pause()
      }
    },
    
    // Keyboard event handler
    handleKeyDown(event) {
      // 'N' key now toggles audio playback instead of fake animation
      if (event.key.toLowerCase() === 'n') {
        event.preventDefault()
        if (this.store) {
          if (this.store.isPlaying) {
            this.store.pause()
          } else {
            this.store.play()
          }
        }
      }
      
      // 'M' key toggles audio control modal
      if (event.key.toLowerCase() === 'm') {
        event.preventDefault()
        if (this.store) {
          this.store.toggleModal()
        }
      }
    }
  },
  
  async mounted() {
    console.log('🎚️ VU Meter mounted')
    
    // Get needle element reference
    this.needleElement = this.$refs.needleElement
    
    // Set initial needle position (rest position)
    if (this.needleElement) {
      gsap.set(this.needleElement, {
        rotation: 70, // Above 2 o'clock
        transformOrigin: "50% 50%",
        force3D: true
      })
    }
    
    // Add keyboard event listener
    window.addEventListener('keydown', this.handleKeyDown)
    
    // Initialize audio if animated
    if (this.animated) {
      await this.initAudio()
      this.startNeedleUpdates()
    }
  },
  
  beforeUnmount() {
    // Remove keyboard event listener
    window.removeEventListener('keydown', this.handleKeyDown)
    
    // Cleanup audio service
    if (this.audioService) {
      this.audioService.destroy()
    }
    
    console.log('🎚️ VU Meter unmounted')
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
