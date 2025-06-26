<template>
  <div class="plugin-container">
    <!-- Header -->
    <Header />
    
    <!-- WebSocket Status Bar -->
    <WebSocketStatusBar />

    <!-- Tab Navigation -->
    <div class="tab-navigation">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        @click="activeTab = tab.id"
        :class="['tab-button', { active: activeTab === tab.id }]"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- Tab Content -->
    <div class="tab-content">
      <!-- Main Controls Tab -->
      <div v-if="activeTab === 'main'" class="tab-panel">
        <!-- Gain Control -->
        <div class="control-group">
          <div class="control-label">Gain</div>
          <input
            type="range"
            min="0"
            max="1"
            :step="gainStep"
            v-model="gainValue"
            @input="updateGain"
          >
          <div class="value-display">
            {{ Math.round(gainValue * 100) }}%
          </div>
        </div>

        <!-- Bypass Control -->
        <div class="control-group">
          <label class="checkbox-label">
            <input
              type="checkbox"
              v-model="bypassValue"
              @change="updateBypass"
            >
            <span class="control-label">Bypass</span>
          </label>
        </div>

        <!-- Distortion Type -->
    <!--     <div class="control-group">
          <div class="control-label">Distortion Type</div>
          <select v-model="distortionValue" @change="updateDistortion">
            <option v-for="(choice, index) in distortionChoices" :key="index" :value="index">
              {{ choice }}
            </option>
          </select>
        </div>
 -->
        <!-- Controls -->
        <div class="control-group">
          <div class="control-label">Controls</div>
          <button @click="callNativeFunction">Call C++ Function</button>
          <button @click="emitEvent">Emit Event ({{ emittedCount }})</button>
          <button @click="testLevelAnimation">Test Level Animation</button>
          <button @click="testWebSocketConnection">Test WebSocket</button>
        </div>

        <!-- VST Host -->
        <div class="control-group">
          <div class="control-label">VST Host</div>
          <div class="vst-host-controls">
            <button @click="browseForVST" :disabled="isLoadingVST">
              {{ isLoadingVST ? 'Loading...' : 'Browse for VST' }}
            </button>
            <div v-if="loadedVSTName" class="loaded-vst">
              <span class="vst-name">{{ loadedVSTName }}</span>
              <button @click="confirmUnloadVST" class="unload-btn">✕</button>
            </div>
            <div v-if="!loadedVSTName" class="no-vst">No VST loaded</div>
          </div>
        </div>

        <!-- Debug Console -->
        <div class="control-group">
          <div class="control-label">
            Debug Console
            <button @click="toggleDebugConsole" class="collapse-toggle">
              {{ isDebugConsoleCollapsed ? '▶' : '▼' }}
            </button>
          </div>
          <div ref="debugConsoleContent" class="collapsible-content">
            <div class="debug-console" ref="debugConsole">
              <div v-for="(message, index) in debugMessages" :key="index" class="debug-message">
                {{ message }}
              </div>
            </div>
            <button @click="clearDebug" class="debug-clear">Clear</button>
          </div>
        </div>
      </div>

      <!-- Parameters Tab -->
      <div v-if="activeTab === 'parameters'" class="tab-panel">
        <ParameterGrid 
          @mock-data-loaded="handleMockDataLoaded"
          @value-changed="handleParameterValueChanged"
          @color-changed="handleParameterColorChanged"
        />
      </div>
    </div>
  </div>
</template>

<script>
import { gsap } from 'gsap'
import ParameterGrid from '../components/ParameterGrid.vue'
import Header from '../components/Header.vue'
import WebSocketStatusBar from '../components/WebSocketStatusBar.vue'
import { useJuceIntegration } from '../composables/useJuceIntegration'
import { useWebSocket } from '../composables/useWebSocket'

export default {
  name: 'MainView',
  components: {
    ParameterGrid,
    Header,
    WebSocketStatusBar
  },
  data() {
    console.log('MainView.vue data() function called!')
    return {
      // Tab system
      activeTab: 'main',
      tabs: [
        { id: 'main', label: 'Main' },
        { id: 'parameters', label: 'Parameters' }
      ],

      // Reactive state
      gainValue: 1.0,  // Match JUCE default of 1.0 (100%)
      gainStep: 0.01,
      bypassValue: false,
      distortionValue: 0,
      distortionChoices: ['Soft Clip', 'Hard Clip', 'Saturation'],
      emittedCount: 0,
      debugMessages: [],
      debugConsole: null,

      // Level meter data
      leftLevelDb: -60,
      rightLevelDb: -60,

      // Refs for SVG level bar elements
      leftLevelBar: null,
      rightLevelBar: null,

      // VST hosting data
      loadedVSTName: '',
      isLoadingVST: false,
      vstParameters: [],

      // Collapsible sections data (collapsed by default)
      isDebugConsoleCollapsed: true,
      debugConsoleContent: null
    }
  },
  beforeMount() {
    console.log('MainView.vue beforeMount() hook called!')
  },
  mounted() {
    console.log('MainView.vue mounted() hook called!')
    console.log('Component data:', this.$data)
    
    // Initialize JUCE integration
    this.initJuceIntegration()
  },
  methods: {
    // JUCE Integration methods
    initJuceIntegration() {
      const { pluginInfo, isDevelopment } = useJuceIntegration()
      this.pluginInfo = pluginInfo
      this.isDevelopment = isDevelopment
    },

    // WebSocket methods (using the composable)
    testWebSocketConnection() {
      const { connectWebSocket } = useWebSocket()
      this.addDebugMessage('WebSocket: Manual test connection requested')
      connectWebSocket()
    },

    // GSAP animation function for smooth 60fps level updates
    animateLevelBar(barElement, dbLevel) {
      if (!barElement) {
        return
      }

      // Convert dB to height (0 dB = 180px height, -60 dB = 0px height)
      const normalizedLevel = Math.max(0, Math.min(60, 60 + dbLevel)) // 0 to 60
      const targetHeight = (normalizedLevel / 60) * 180 // 0 to 180px

      gsap.to(barElement, {
        height: targetHeight,
        duration: 0.1,
        ease: "power2.out"
      })
    },

    // Level meter update function
    updateLevelMeters(leftDb, rightDb) {
      this.leftLevelDb = leftDb
      this.rightLevelDb = rightDb

      // Animate the level bars
      this.$nextTick(() => {
        if (this.leftLevelBar) {
          this.animateLevelBar(this.leftLevelBar, leftDb)
        }
        if (this.rightLevelBar) {
          this.animateLevelBar(this.rightLevelBar, rightDb)
        }
      })
    },

    // Control update methods
    updateGain() {
      this.addDebugMessage(`Gain updated to ${Math.round(this.gainValue * 100)}%`)
      if (window.__JUCE__) {
        window.__JUCE__.backend.setParameter("gain", this.gainValue)
      }
    },

    updateBypass() {
      this.addDebugMessage(`Bypass ${this.bypassValue ? 'enabled' : 'disabled'}`)
      if (window.__JUCE__) {
        window.__JUCE__.backend.setParameter("bypass", this.bypassValue)
      }
    },

    updateDistortion() {
      this.addDebugMessage(`Distortion type changed to ${this.distortionChoices[this.distortionValue]}`)
      if (window.__JUCE__) {
        window.__JUCE__.backend.setParameter("distortionType", this.distortionValue)
      }
    },

    // Native function calls
    callNativeFunction() {
      this.addDebugMessage('Calling native C++ function...')
      if (window.__JUCE__) {
        const result = window.__JUCE__.backend.callNativeFunction("testFunction", { message: "Hello from Vue!" })
        this.addDebugMessage(`Native function result: ${result}`)
      } else {
        this.addDebugMessage('JUCE backend not available')
      }
    },

    emitEvent() {
      this.emittedCount++
      this.addDebugMessage(`Vue: Emitting event (${this.emittedCount})`)
      if (window.__JUCE__) {
        window.__JUCE__.backend.emitEvent("testEvent", { count: this.emittedCount })
      }
    },

    testLevelAnimation() {
      this.addDebugMessage('Testing level animation...')
      // Simulate some level changes
      const testLevels = [-60, -40, -20, -10, -5, -2, 0, -2, -5, -10, -20, -40, -60]
      let index = 0
      
      const interval = setInterval(() => {
        if (index < testLevels.length) {
          const level = testLevels[index]
          this.updateLevelMeters(level, level - 2)
          index++
        } else {
          clearInterval(interval)
        }
      }, 200)
    },

    // VST Hosting methods
    browseForVST() {
      this.addDebugMessage('Browsing for VST...')
      this.isLoadingVST = true
      
      if (window.__JUCE__) {
        window.__JUCE__.backend.browseForVST()
          .then((result) => {
            this.addDebugMessage(`VST loaded: ${result.name}`)
            this.loadedVSTName = result.name
            this.vstParameters = result.parameters || []
          })
          .catch((error) => {
            this.addDebugMessage(`Failed to load VST: ${error}`)
          })
          .finally(() => {
            this.isLoadingVST = false
          })
      } else {
        this.addDebugMessage('JUCE backend not available')
        this.isLoadingVST = false
      }
    },

    confirmUnloadVST() {
      if (confirm('Are you sure you want to unload the VST?')) {
        this.unloadVST()
      }
    },

    unloadVST() {
      this.addDebugMessage('Unloading VST...')
      if (window.__JUCE__) {
        window.__JUCE__.backend.unloadVST()
        this.loadedVSTName = ''
        this.vstParameters = []
      }
    },

    // Parameter Grid event handlers
    handleMockDataLoaded(data) {
      this.addDebugMessage(`Mock data loaded: ${data.length} parameters`)
    },

    handleParameterValueChanged(parameter) {
      this.addDebugMessage(`Parameter changed: ${parameter.name} = ${parameter.value}`)
    },

    handleParameterColorChanged(parameter) {
      this.addDebugMessage(`Parameter color changed: ${parameter.name} = RGB(${parameter.color.r}, ${parameter.color.g}, ${parameter.color.b})`)
    },

    // Debug console methods
    addDebugMessage(message) {
      const timestamp = new Date().toLocaleTimeString()
      this.debugMessages.push(`[${timestamp}] ${message}`)
      
      // Keep only last 100 messages
      if (this.debugMessages.length > 100) {
        this.debugMessages = this.debugMessages.slice(-100)
      }
      
      // Auto-scroll to bottom
      this.$nextTick(() => {
        if (this.debugConsole) {
          this.debugConsole.scrollTop = this.debugConsole.scrollHeight
        }
      })
    },

    clearDebug() {
      this.debugMessages = []
    },

    toggleDebugConsole() {
      this.isDebugConsoleCollapsed = !this.isDebugConsoleCollapsed
      this.$nextTick(() => {
        if (this.debugConsoleContent) {
          if (this.isDebugConsoleCollapsed) {
            gsap.to(this.debugConsoleContent, {
              height: 0,
              duration: 0.3,
              ease: "power2.out"
            })
          } else {
            gsap.to(this.debugConsoleContent, {
              height: "auto",
              duration: 0.3,
              ease: "power2.out"
            })
          }
        }
      })
    }
  }
}
</script>

<style scoped>
.plugin-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.value-display {
  text-align: center;
  font-size: 12px;
  color: #666;
  margin-top: 4px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.checkbox-label .control-label {
  margin: 0;
}

.debug-console {
  width: 100%;
  height: 150px;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: #000;
  color: #0f0;
  font-family: 'Courier New', monospace;
  font-size: 12px;
  padding: 8px;
  overflow-y: auto;
  white-space: pre-wrap;
}

.debug-message {
  margin-bottom: 2px;
}

.debug-clear {
  margin-top: 5px;
  padding: 4px 8px;
  background: #ff4444;
  color: white;
  border: none;
  border-radius: 3px;
  cursor: pointer;
}

.vst-host-controls {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.loaded-vst {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 8px;
  background: #e8f5e8;
  border: 1px solid #4caf50;
  border-radius: 4px;
}

.vst-name {
  font-weight: bold;
  color: #2e7d32;
}

.unload-btn {
  background: #f44336;
  color: white;
  border: none;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  cursor: pointer;
  font-size: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.unload-btn:hover {
  background: #d32f2f;
}

.no-vst {
  color: white;
  font-style: italic;
  padding: 8px;
  background: #333;
  border-radius: 4px;
}

.control-label {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.collapse-toggle {
  background: none;
  border: none;
  font-size: 14px;
  cursor: pointer;
  padding: 2px 6px;
  border-radius: 3px;
  color: #666;
}

.collapse-toggle:hover {
  background: #f0f0f0;
}

.collapsible-content {
  overflow: hidden;
  transition: height 0.3s ease;
}

/* Tab Navigation */
.tab-navigation {
  display: flex;
  border-bottom: 1px solid #ddd;
  margin-bottom: 20px;
}

.tab-button {
  padding: 10px 20px;
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
  color: #666;
  border-bottom: 2px solid transparent;
  transition: all 0.2s ease;
}

.tab-button:hover {
  color: #333;
  background: #f5f5f5;
}

.tab-button.active {
  color: #007bff;
  border-bottom-color: #007bff;
  font-weight: bold;
}

.tab-content {
  flex: 1;
}

.tab-panel {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.control-group {
  margin-bottom: 20px;
  padding: 15px;
  background: #f5f5f5;
  border-radius: 8px;
  border: 1px solid #ddd;
}

.control-group input[type="range"] {
  width: 100%;
  margin: 10px 0;
}

.control-group select {
  width: 100%;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: white;
}

.control-group button {
  margin: 5px;
  padding: 8px 16px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 14px;
}

.control-group button:hover {
  background: #0056b3;
}

.control-group button:disabled {
  background: #6c757d;
  cursor: not-allowed;
}
</style> 