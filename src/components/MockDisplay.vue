<template>
  <div class="mock-display">
    <div class="display-container">
      <!-- Active Parameter Display -->
      <div 
        v-if="isDisplayActive" 
        class="parameter-display"
        :class="{ 'fade-in': isDisplayActive }"
      >
        <div class="parameter-name">{{ displayText }}</div>
        <div class="parameter-value">{{ displayValue }}</div>
      </div>
      
      <!-- VU Meter Display (default/fallback) -->
      <div 
        v-else 
        class="vu-meter-display"
        :class="{ 'fade-in': !isDisplayActive }"
      >
        <div class="meter-label">VU Meter</div>
        <div class="meter-value">{{ vuMeterValue }}</div>
        <div class="meter-bar">
          <div 
            class="meter-fill" 
            :style="{ width: `${vuMeterPercentage}%` }"
          ></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useHardwareStore } from '../stores/hardwareStore'

const hardwareStore = useHardwareStore()

// Reactive state
const vuMeterValue = ref('-20.0 dB')
const vuMeterLevel = ref(-20)

// Computed
const isDisplayActive = computed(() => hardwareStore.isDisplayActive)
const displayText = computed(() => hardwareStore.displayText)
const displayValue = computed(() => hardwareStore.displayValue)
const vuMeterPercentage = computed(() => {
  // Convert dB to percentage (0 dB = 100%, -60 dB = 0%)
  const db = parseFloat(vuMeterValue.value)
  return Math.max(0, Math.min(100, ((db + 60) / 60) * 100))
})

// Lifecycle
onMounted(() => {
  // Static VU meter - no animation needed
})
</script>

<style scoped>
.mock-display {
  width: 100%;
  height: 300px;
  background: #1a1a1a;
  border: 2px solid #333;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
  position: relative;
  overflow: hidden;
}

.display-container {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

/* Parameter Display */
.parameter-display {
  text-align: center;
  opacity: 0;
  transform: scale(0.9);
  transition: all 0.3s ease-in-out;
}

.parameter-display.fade-in {
  opacity: 1;
  transform: scale(1);
}

.parameter-name {
  font-size: 2.5em;
  font-weight: bold;
  color: #00ff00;
  text-shadow: 0 0 10px rgba(0, 255, 0, 0.5);
  margin-bottom: 10px;
  font-family: 'Courier New', monospace;
}

.parameter-value {
  font-size: 3em;
  font-weight: bold;
  color: #ffffff;
  text-shadow: 0 0 15px rgba(255, 255, 255, 0.7);
  font-family: 'Courier New', monospace;
}

/* VU Meter Display */
.vu-meter-display {
  text-align: center;
  opacity: 0;
  transform: scale(0.9);
  transition: all 0.3s ease-in-out;
}

.vu-meter-display.fade-in {
  opacity: 1;
  transform: scale(1);
}

.meter-label {
  font-size: 1.8em;
  font-weight: bold;
  color: #00ffff;
  text-shadow: 0 0 8px rgba(0, 255, 255, 0.5);
  margin-bottom: 15px;
  font-family: 'Courier New', monospace;
}

.meter-value {
  font-size: 2.2em;
  font-weight: bold;
  color: #ffffff;
  text-shadow: 0 0 10px rgba(255, 255, 255, 0.5);
  margin-bottom: 20px;
  font-family: 'Courier New', monospace;
}

.meter-bar {
  width: 300px;
  height: 20px;
  background: #333;
  border: 2px solid #555;
  border-radius: 10px;
  overflow: hidden;
  position: relative;
}

.meter-fill {
  height: 100%;
  background: linear-gradient(90deg, #00ff00, #ffff00, #ff8800, #ff0000);
  transition: width 0.1s ease-out;
  border-radius: 8px;
}

/* Dark theme adjustments */
.mock-display {
  box-shadow: inset 0 0 20px rgba(0, 0, 0, 0.5);
}

/* Responsive design */
@media (max-width: 768px) {
  .parameter-name {
    font-size: 2em;
  }
  
  .parameter-value {
    font-size: 2.5em;
  }
  
  .meter-label {
    font-size: 1.5em;
  }
  
  .meter-value {
    font-size: 1.8em;
  }
  
  .meter-bar {
    width: 250px;
  }
}
</style> 