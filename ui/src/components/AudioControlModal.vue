<template>
  <div v-if="store && store.isModalVisible" class="modal-overlay" @click="closeModal">
    <div class="audio-control-panel" @click.stop>
      <!-- Header -->
      <div class="panel-header">
        <h3>🎵 AUDIO CONTROL PANEL</h3>
      </div>
      
      <!-- Track Selection -->
      <div class="control-section">
        <label>Track Selection:</label>
        <select 
          v-model="store.selectedTrackId" 
          @change="onTrackChange"
          class="track-dropdown"
          :disabled="store.isTrackLoading"
        >
          <option 
            v-for="track in store.availableTracks" 
            :key="track.id" 
            :value="track.id"
          >
            {{ track.name }} ({{ track.genre }}, {{ track.bpm }} BPM)
          </option>
        </select>
      </div>
      
      <!-- Volume Control -->
      <div class="control-section">
        <label>Output Gain:</label>
        <div class="volume-control">
          <input 
            type="range" 
            v-model="store.outputGain"
            min="-60" 
            max="6" 
            step="0.5"
            class="volume-slider"
            @input="onVolumeChange"
          />
          <div class="volume-labels">
            <span>-60dB</span>
            <span>0dB</span>
            <span>+6dB</span>
          </div>
          <div class="volume-display">
            {{ store.outputGain }}dB
          </div>
        </div>
      </div>
      
      <!-- Playback Controls -->
      <div class="control-section">
        <div class="playback-controls">
          <button 
            @click="togglePlayback" 
            :disabled="!store.canPlay"
            class="playback-button"
          >
            {{ store.isPlaying ? '⏸️ Pause' : '▶️ Play' }}
          </button>
          <button 
            @click="stopPlayback"
            class="playback-button"
          >
            ⏹️ Stop
          </button>
        </div>
      </div>
      
      <!-- Status Display -->
      <div class="control-section">
        <div class="status-display">
          <span class="status-label">Status:</span>
          <span 
            :class="['status-value', statusClass]"
          >
            {{ statusText }}
          </span>
        </div>
      </div>
      
      <!-- Help Text -->
      <div class="help-text">
        Press 'M' to close • 'N' to toggle playback
      </div>
    </div>
  </div>
</template>

<script>
import { useAudioControlStore } from '../stores/audioControlStore'

export default {
  name: 'AudioControlModal',
  
  data() {
    return {
      store: useAudioControlStore() // Initialize immediately
    }
  },
  
  computed: {
    statusText() {
      if (!this.store) return 'Loading...'
      if (this.store.isTrackLoading) return 'Loading...'
      if (!this.store.canPlay) return 'No track loaded'
      
      let status = this.store.isPlaying ? 'Playing' : 'Paused'
      if (this.store.isFallbackMode) {
        status += ' (Test Tone)'
      }
      return status
    },
    
    statusClass() {
      if (!this.store) return 'loading'
      if (this.store.isTrackLoading) return 'loading'
      if (!this.store.canPlay) return 'error'
      return this.store.isPlaying ? 'playing' : 'paused'
    }
  },
  
  methods: {
    closeModal() {
      if (this.store) {
        this.store.hideModal()
      }
    },
    
    onTrackChange() {
      console.log('🎵 Track changed to:', this.store?.selectedTrackId)
      // Explicitly call selectTrack to ensure proper state reset
      if (this.store && this.store.selectedTrackId) {
        this.store.selectTrack(this.store.selectedTrackId)
      }
    },
    
    onVolumeChange() {
      console.log('🔊 Volume changed to:', this.store?.outputGain, 'dB')
    },
    
    togglePlayback() {
      if (!this.store) return
      if (this.store.isPlaying) {
        this.store.pause()
      } else {
        this.store.play()
      }
    },
    
    stopPlayback() {
      if (this.store) {
        this.store.stop()
      }
    },
    
    handleKeyDown(event) {
      if (event.key === 'Escape') {
        this.closeModal()
      }
    }
  },
  
  mounted() {
    window.addEventListener('keydown', this.handleKeyDown)
    console.log('🎛️ AudioControlModal mounted')
  },
  
  beforeUnmount() {
    window.removeEventListener('keydown', this.handleKeyDown)
    console.log('🎛️ AudioControlModal unmounted')
  }
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 9999;
  backdrop-filter: blur(2px);
}

.audio-control-panel {
  background: linear-gradient(135deg, #2a2a2a 0%, #1a1a1a 100%);
  border: 2px solid #444;
  border-radius: 12px;
  padding: 24px;
  width: 400px;
  max-width: 90vw;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
  color: #ffffff;
  font-family: 'Courier New', monospace;
}

.panel-header {
  text-align: center;
  margin-bottom: 20px;
  border-bottom: 1px solid #444;
  padding-bottom: 12px;
}

.panel-header h3 {
  margin: 0;
  font-size: 18px;
  color: #fef888;
  letter-spacing: 1px;
}

.control-section {
  margin-bottom: 20px;
}

.control-section label {
  display: block;
  margin-bottom: 8px;
  font-weight: bold;
  color: #fef888;
  font-size: 14px;
}

.track-dropdown {
  width: 100%;
  padding: 8px 12px;
  background: #333;
  border: 1px solid #555;
  border-radius: 6px;
  color: #fff;
  font-family: 'Courier New', monospace;
  font-size: 13px;
}

.track-dropdown:focus {
  outline: none;
  border-color: #fef888;
  box-shadow: 0 0 5px rgba(254, 248, 136, 0.3);
}

.track-dropdown:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.volume-control {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.volume-slider {
  width: 100%;
  height: 6px;
  background: #333;
  border-radius: 3px;
  outline: none;
  cursor: pointer;
}

.volume-slider::-webkit-slider-thumb {
  appearance: none;
  width: 20px;
  height: 20px;
  background: #fef888;
  border-radius: 50%;
  cursor: pointer;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
}

.volume-slider::-moz-range-thumb {
  width: 20px;
  height: 20px;
  background: #fef888;
  border-radius: 50%;
  cursor: pointer;
  border: none;
}

.volume-labels {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: #aaa;
  margin-top: 4px;
}

.volume-display {
  text-align: center;
  font-weight: bold;
  color: #fef888;
  font-size: 16px;
  margin-top: 4px;
}

.playback-controls {
  display: flex;
  gap: 12px;
  justify-content: center;
}

.playback-button {
  padding: 10px 20px;
  background: linear-gradient(135deg, #4a4a4a 0%, #2a2a2a 100%);
  border: 1px solid #666;
  border-radius: 6px;
  color: #fff;
  font-family: 'Courier New', monospace;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.playback-button:hover:not(:disabled) {
  background: linear-gradient(135deg, #5a5a5a 0%, #3a3a3a 100%);
  border-color: #fef888;
  box-shadow: 0 2px 8px rgba(254, 248, 136, 0.2);
}

.playback-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.status-display {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: #333;
  border-radius: 6px;
  border: 1px solid #555;
}

.status-label {
  font-weight: bold;
  color: #fef888;
}

.status-value {
  font-weight: bold;
}

.status-value.playing {
  color: #4ade80;
}

.status-value.paused {
  color: #fbbf24;
}

.status-value.loading {
  color: #60a5fa;
}

.status-value.error {
  color: #ef4444;
}

.help-text {
  text-align: center;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #444;
  font-size: 12px;
  color: #aaa;
  font-style: italic;
}

/* Responsive adjustments */
@media (max-width: 480px) {
  .audio-control-panel {
    width: 320px;
    padding: 16px;
  }
  
  .panel-header h3 {
    font-size: 16px;
  }
  
  .playback-controls {
    flex-direction: column;
    gap: 8px;
  }
  
  .playback-button {
    width: 100%;
  }
}
</style>