<template>
  <div class="la2a-controls">
    <h3 class="controls-title">LA-2A COMPRESSOR</h3>
    
    <div class="controls-container">
      <!-- Gain Knob (Left) -->
      <HardwareKnob
        v-model="gain"
        label="GAIN"
        :min="0"
        :max="100"
        :displayFormat="formatGain"
        @update:modelValue="updateGain"
      />
      
      <!-- Meter Mode Switch (Center) -->
      <div class="meter-mode-switch">
        <button 
          class="mode-button"
          :class="{ active: meterMode === 'GR' }"
          @click="setMeterMode('GR')"
        >
          GR
        </button>
        <button 
          class="mode-button"
          :class="{ active: meterMode === 'VU' }"
          @click="setMeterMode('VU')"
        >
          +4
        </button>
      </div>
      
      <!-- Peak Reduction Knob (Right) -->
      <HardwareKnob
        v-model="peakReduction"
        label="PEAK REDUCTION"
        :min="0"
        :max="100"
        :displayFormat="formatPeakReduction"
        @update:modelValue="updatePeakReduction"
      />
    </div>
    
    <!-- Status indicator -->
    <div class="compression-status" v-if="isCompressing">
      <div class="status-led"></div>
      <span>COMPRESSING</span>
    </div>
  </div>
</template>

<script>
import { useHardwareStore } from '@/stores/hardwareStore'
import HardwareKnob from './HardwareKnob.vue'

export default {
  name: 'LA2AControls',
  
  components: {
    HardwareKnob
  },
  
  data() {
    return {
      gain: 50,
      peakReduction: 0
    }
  },
  
  computed: {
    hardwareStore() {
      return useHardwareStore()
    },
    
    meterMode() {
      return this.hardwareStore.compression.meterMode
    },
    
    isCompressing() {
      return this.hardwareStore.compression.isCompressing
    }
  },
  
  mounted() {
    // Initialize from store
    this.gain = this.hardwareStore.compression.gain
    this.peakReduction = this.hardwareStore.compression.peakReduction
  },
  
  methods: {
    updateGain(value) {
      this.hardwareStore.updateCompressionGain(value)
    },
    
    updatePeakReduction(value) {
      this.hardwareStore.updatePeakReduction(value)
    },
    
    setMeterMode(mode) {
      if (this.meterMode !== mode) {
        this.hardwareStore.toggleMeterMode()
      }
    },
    
    formatGain(value) {
      // Convert to dB display
      const db = (value - 50) * 0.4
      return db >= 0 ? `+${db.toFixed(1)}` : db.toFixed(1)
    },
    
    formatPeakReduction(value) {
      return value.toString()
    }
  }
}
</script>

<style scoped>
.la2a-controls {
  background: linear-gradient(180deg, #2a2a2a 0%, #1a1a1a 100%);
  border: 2px solid #333;
  border-radius: 8px;
  padding: 20px;
  margin-top: 20px;
  box-shadow: 
    0 4px 12px rgba(0, 0, 0, 0.5),
    inset 0 1px 2px rgba(255, 255, 255, 0.1);
}

.controls-title {
  text-align: center;
  font-size: 16px;
  font-weight: 600;
  color: #ccc;
  letter-spacing: 2px;
  margin-bottom: 20px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
}

.controls-container {
  display: flex;
  justify-content: space-around;
  align-items: center;
  gap: 40px;
}

.meter-mode-switch {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.mode-button {
  background: #1a1a1a;
  border: 2px solid #444;
  color: #666;
  padding: 8px 16px;
  font-size: 12px;
  font-weight: 600;
  letter-spacing: 1px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 
    0 2px 4px rgba(0, 0, 0, 0.3),
    inset 0 1px 2px rgba(0, 0, 0, 0.2);
}

.mode-button:hover {
  border-color: #555;
  color: #888;
}

.mode-button.active {
  background: #ff4444;
  border-color: #ff6666;
  color: #fff;
  box-shadow: 
    0 2px 8px rgba(255, 68, 68, 0.4),
    inset 0 1px 2px rgba(255, 255, 255, 0.2);
}

.compression-status {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  margin-top: 16px;
  opacity: 0;
  animation: fadeIn 0.3s ease forwards;
}

@keyframes fadeIn {
  to {
    opacity: 1;
  }
}

.status-led {
  width: 8px;
  height: 8px;
  background: #ff4444;
  border-radius: 50%;
  box-shadow: 
    0 0 8px rgba(255, 68, 68, 0.8),
    inset 0 0 4px rgba(255, 255, 255, 0.3);
  animation: pulse 1s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% {
    opacity: 0.8;
  }
  50% {
    opacity: 1;
  }
}

.compression-status span {
  font-size: 11px;
  font-weight: 600;
  color: #ff6666;
  letter-spacing: 1px;
  text-transform: uppercase;
}

/* Responsive adjustments */
@media (max-width: 600px) {
  .controls-container {
    gap: 20px;
  }
  
  .la2a-controls {
    padding: 15px;
  }
}
</style> 