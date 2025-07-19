<template>
  <div class="hardware-view" @keydown="handleKeyDown" tabindex="0">
    <!-- WebSocket Status Bar (hidden by default, shown with Shift+W) -->
    <div 
      v-show="showWebSocketHeader" 
      class="websocket-header-container"
    >
      <WebSocketStatusBar />
      <div class="header-hint">Press Shift+W to hide</div>
    </div>
    
    <!-- Mock Display - Full 800x480 -->
    <div class="display-container" :class="displayContainerClass" :style="displayContainerStyle">
      <HardwareDisplay />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import HardwareDisplay from '../components/HardwareDisplay.vue'
import WebSocketStatusBar from '../components/WebSocketStatusBar.vue'
import { useWebSocketStore } from '../stores/websocketStore'

const websocketStore = useWebSocketStore()

// WebSocket header visibility
const showWebSocketHeader = ref(false)

// Computed properties
const displayContainerStyle = computed(() => {
  // WebSocketStatusBar is roughly 60px tall including padding
  const headerHeight = showWebSocketHeader.value ? 60 : 0
  return {
    height: `${480 - headerHeight}px`
  }
})

const displayContainerClass = computed(() => {
  const headerHeight = showWebSocketHeader.value ? 60 : 0
  const availableHeight = 480 - headerHeight
  
  return {
    'container-height-420': availableHeight === 420,
    'container-height-480': availableHeight === 480
  }
})

// Keyboard event handler
const handleKeyDown = (event) => {
  // Check for Shift+W
  if (event.shiftKey && event.key.toLowerCase() === 'w') {
    event.preventDefault()
    showWebSocketHeader.value = !showWebSocketHeader.value
  }
}

// Lifecycle
onMounted(() => {
  // Focus the view to receive keyboard events
  document.querySelector('.hardware-view')?.focus()
})

onUnmounted(() => {
  // Cleanup if needed
})
</script>

<style scoped>
.hardware-view {
  width: 800px;
  height: 480px;
  max-width: 800px;
  max-height: 480px;
  min-width: 800px;
  min-height: 480px;
  margin: 0;
  padding: 0;
  overflow: hidden;
  background: #000;
  outline: none;
  position: relative;
}

.websocket-header-container {
  width: 100%;
  background: rgba(0, 0, 0, 0.95);
  border-bottom: 1px solid #333;
  z-index: 1000;
  padding: 5px 10px;
  position: relative;
}

.header-hint {
  position: absolute;
  top: 5px;
  right: 10px;
  opacity: 0.5;
  font-size: 10px;
  color: white;
  font-family: 'Courier New', monospace;
  z-index: 1001;
}

/* Override WebSocketStatusBar styles for hardware view */
.websocket-header-container :deep(.websocket-status-bar) {
  background: transparent;
  border: none;
  margin: 0;
  padding: 5px 0;
}

.display-container {
  width: 100%;
  margin: 0;
  padding: 0;
  position: relative;
}

/* Ensure HardwareDisplay fills the container exactly */
.display-container :deep(.mock-display-container) {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
}

/* Pass container height info to VUMeter */
.display-container.container-height-420 :deep(.vu-meter-frame.hardware-mode) {
  transform: scale(0.875); /* 420/480 = 0.875 */
  transform-origin: center center;
}

.display-container.container-height-480 :deep(.vu-meter-frame.hardware-mode) {
  transform: none;
}
</style> 