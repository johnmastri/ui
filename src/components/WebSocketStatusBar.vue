<template>
  <div class="websocket-status-bar">
    <div class="status-item">
      <span class="status-label">WebSocket:</span>
      <span class="status-value" :class="{ connected: isWebSocketConnected, connecting: isConnecting }">
        {{ connectionStatus }}
      </span>
    </div>
    
    <!-- Server Selection Radio Buttons -->
    <div class="status-item server-selection">
      <span class="status-label">Server:</span>
      <div class="radio-group">
        <label 
          v-for="server in availableServers" 
          :key="server.id"
          class="radio-option"
          :class="{ active: selectedServerId === server.id }"
        >
          <input 
            type="radio" 
            :value="server.id" 
            v-model="selectedServerId"
            @change="selectServer(server.id)"
            :disabled="isConnecting"
          />
          <span class="radio-label">{{ server.name }}</span>
        </label>
      </div>
    </div>
    
    <div class="status-item">
      <span class="status-label">URL:</span>
      <span class="status-value server-url">{{ websocketServer }}</span>
    </div>
    
    <div class="status-item">
      <span class="status-label">Send:</span>
      <div class="status-light" :class="{ active: hasRecentSend }"></div>
    </div>
    
    <div class="status-item">
      <span class="status-label">Receive:</span>
      <div class="status-light" :class="{ active: hasRecentReceive }"></div>
    </div>
    
    <div class="status-item">
      <button 
        @click="reconnectWebSocket" 
        class="reconnect-btn" 
        :disabled="isWebSocketConnected || isConnecting"
      >
        {{ isConnecting ? 'Connecting...' : (isWebSocketConnected ? 'Connected' : 'Reconnect') }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useWebSocketStore } from '../stores/websocketStore'

const websocketStore = useWebSocketStore()

// Create reactive computed properties
const isWebSocketConnected = computed(() => websocketStore.isConnected)
const isConnecting = computed(() => websocketStore.isConnecting)
const hasRecentSend = computed(() => websocketStore.hasRecentSend)
const hasRecentReceive = computed(() => websocketStore.hasRecentReceive)
const websocketServer = computed(() => websocketStore.serverUrl)
const connectionStatus = computed(() => websocketStore.connectionStatus)
const availableServers = computed(() => websocketStore.availableServers)
const selectedServerId = computed({
  get: () => websocketStore.selectedServerId,
  set: (value) => websocketStore.selectedServerId = value
})

const selectServer = (serverId) => websocketStore.selectServer(serverId)
const reconnectWebSocket = () => websocketStore.reconnect()
</script>

<style scoped>
.websocket-status-bar {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 10px;
  background: #f8f9fa;
  border-radius: 6px;
  border: 1px solid #e9ecef;
  margin-top: 10px;
  flex-wrap: wrap;
}

.status-item {
  display: flex;
  align-items: center;
  gap: 5px;
}

.status-label {
  font-weight: 500;
  color: #495057;
  font-size: 0.9em;
}

.status-value {
  font-family: monospace;
  color: #dc3545;
  font-size: 0.9em;
}

.status-value.connected {
  color: #28a745;
}

.status-value.connecting {
  color: #ffc107;
}

.server-url {
  color: #6c757d;
  font-size: 0.8em;
}

.server-selection {
  gap: 8px;
}

.radio-group {
  display: flex;
  gap: 12px;
}

.radio-option {
  display: flex;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  transition: background-color 0.2s ease;
  font-size: 0.85em;
}

.radio-option:hover {
  background: #e9ecef;
}

.radio-option.active {
  background: #007bff;
  color: white;
}

.radio-option.active .radio-label {
  color: white;
}

.radio-option input[type="radio"] {
  margin: 0;
  width: 12px;
  height: 12px;
}

.radio-option input[type="radio"]:disabled {
  opacity: 0.5;
}

.radio-label {
  color: #495057;
  font-weight: 500;
}

.status-light {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #6c757d;
  transition: background-color 0.2s ease;
}

.status-light.active {
  background: #28a745;
  box-shadow: 0 0 8px rgba(40, 167, 69, 0.5);
}

.reconnect-btn {
  padding: 4px 12px;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.8em;
  transition: background-color 0.2s ease;
  min-width: 90px;
}

.reconnect-btn:hover:not(:disabled) {
  background: #0056b3;
}

.reconnect-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}
</style> 