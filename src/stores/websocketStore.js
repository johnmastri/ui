import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useWebSocketStore = defineStore('websocket', () => {
  // Server configuration
  const availableServers = ref([
    { id: 'local', name: 'Local Server', url: 'ws://localhost:8765' },
    { id: 'pi', name: 'Pi Server', url: 'ws://192.168.1.195:8765' }
  ])
  const selectedServerId = ref('local') // Default to local
  
  // Connection state
  const isConnected = ref(false)
  const hasRecentSend = ref(false)
  const hasRecentReceive = ref(false)
  const isConnecting = ref(false)
  
  // Message handling
  const messageHandlers = ref(new Map())
  const messageHistory = ref([])
  const maxHistorySize = 50
  
  // Connection event listeners
  const connectionListeners = ref([])
  
  // WebSocket instance and reconnection
  let websocket = null
  let reconnectAttempts = 0
  const maxReconnectAttempts = 5
  let reconnectInterval = null
  let sendTimeout = null
  let receiveTimeout = null

  // Computed
  const serverUrl = computed(() => {
    const server = availableServers.value.find(s => s.id === selectedServerId.value)
    return server ? server.url : availableServers.value[0].url
  })
  
  const currentServer = computed(() => {
    return availableServers.value.find(s => s.id === selectedServerId.value)
  })
  
  const connectionStatus = computed(() => 
    isConnecting.value ? 'Connecting...' : (isConnected.value ? 'Connected' : 'Disconnected')
  )

  // Server selection
  const selectServer = (serverId) => {
    if (selectedServerId.value !== serverId) {
      console.log(`WebSocket: Switching to server: ${serverId}`)
      selectedServerId.value = serverId
      
      // Reconnect to new server
      if (isConnected.value || isConnecting.value) {
        disconnect()
        setTimeout(() => {
          connect()
        }, 100)
      } else {
        connect()
      }
    }
  }

  // Message handler registration
  const registerHandler = (messageType, handler) => {
    messageHandlers.value.set(messageType, handler)
  }

  const unregisterHandler = (messageType) => {
    messageHandlers.value.delete(messageType)
  }

  // Connection event handling
  const addConnectionListener = (listener) => {
    connectionListeners.value.push(listener)
  }

  const removeConnectionListener = (listener) => {
    const index = connectionListeners.value.indexOf(listener)
    if (index > -1) {
      connectionListeners.value.splice(index, 1)
    }
  }

  const triggerConnectionEvent = () => {
    connectionListeners.value.forEach(listener => {
      try {
        listener()
      } catch (error) {
        console.error('Error in connection listener:', error)
      }
    })
  }

  // Core WebSocket methods
  const connect = () => {
    if (isConnecting.value || isConnected.value) {
      return // Already connecting/connected
    }
    
    try {
      isConnecting.value = true
      console.log(`WebSocket: Connecting to ${serverUrl.value}`)
      websocket = new WebSocket(serverUrl.value)
      
      websocket.onopen = () => {
        isConnected.value = true
        isConnecting.value = false
        reconnectAttempts = 0
        console.log(`WebSocket: Connected to ${serverUrl.value}`)
        
        // Trigger connection event for listeners
        triggerConnectionEvent()
      }
      
      websocket.onmessage = (event) => {
        handleIncomingMessage(event.data)
        showReceiveLight()
      }
      
      websocket.onclose = (event) => {
        isConnected.value = false
        isConnecting.value = false
        console.log(`WebSocket: Disconnected from ${serverUrl.value}`)
        
        // Auto-reconnect if not manually disconnected
        if (event.code !== 1000) {
          scheduleReconnect()
        }
      }
      
      websocket.onerror = (error) => {
        console.error(`WebSocket: Connection error to ${serverUrl.value}`)
        isConnecting.value = false
      }
      
    } catch (error) {
      console.error(`WebSocket: Failed to connect to ${serverUrl.value}`)
      isConnecting.value = false
      scheduleReconnect()
    }
  }

  const disconnect = () => {
    if (websocket) {
      websocket.close(1000) // Normal closure
      websocket = null
    }
    isConnected.value = false
    isConnecting.value = false
    
    // Clear any pending reconnect attempts
    if (reconnectInterval) {
      clearTimeout(reconnectInterval)
      reconnectInterval = null
    }
    reconnectAttempts = 0
  }

  const send = (message) => {
    if (websocket && websocket.readyState === WebSocket.OPEN) {
      const messageStr = JSON.stringify(message)
      websocket.send(messageStr)
      addToHistory(message, 'sent')
      showSendLight()
      return true
    } else {
      console.log('WebSocket: Cannot send - not connected')
      return false
    }
  }

  // Message routing
  const handleIncomingMessage = (data) => {
    try {
      const message = JSON.parse(data)
      addToHistory(message, 'received')
      
      if (message.type && messageHandlers.value.has(message.type)) {
        const handler = messageHandlers.value.get(message.type)
        handler(message)
      }
    } catch (error) {
      console.error('WebSocket: Failed to parse incoming message:', error)
    }
  }

  // Reconnection logic
  const scheduleReconnect = () => {
    if (reconnectAttempts < maxReconnectAttempts) {
      reconnectAttempts++
      const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 30000)
      
      console.log(`WebSocket: Scheduling reconnect attempt ${reconnectAttempts}/${maxReconnectAttempts} in ${delay}ms`)
      
      reconnectInterval = setTimeout(() => {
        connect()
      }, delay)
    } else {
      console.log('WebSocket: Max reconnect attempts reached')
    }
  }

  const reconnect = () => {
    console.log('WebSocket: Manual reconnect requested')
    disconnect()
    reconnectAttempts = 0
    setTimeout(() => {
      connect()
    }, 100)
  }

  // Helper methods
  const showSendLight = () => {
    hasRecentSend.value = true
    if (sendTimeout) clearTimeout(sendTimeout)
    sendTimeout = setTimeout(() => {
      hasRecentSend.value = false
    }, 500)
  }

  const showReceiveLight = () => {
    hasRecentReceive.value = true
    if (receiveTimeout) clearTimeout(receiveTimeout)
    receiveTimeout = setTimeout(() => {
      hasRecentReceive.value = false
    }, 500)
  }

  const addToHistory = (message, direction) => {
    messageHistory.value.unshift({
      message,
      direction,
      timestamp: Date.now()
    })
    
    if (messageHistory.value.length > maxHistorySize) {
      messageHistory.value = messageHistory.value.slice(0, maxHistorySize)
    }
  }

  const clearHistory = () => {
    messageHistory.value = []
  }

  const getHistory = (limit = 10) => {
    return messageHistory.value.slice(0, limit)
  }

  // Auto-connect on store creation
  connect()

  return {
    // State
    isConnected,
    hasRecentSend,
    hasRecentReceive,
    isConnecting,
    availableServers,
    selectedServerId,
    messageHistory,
    
    // Computed
    serverUrl,
    currentServer,
    connectionStatus,
    
    // Methods
    selectServer,
    registerHandler,
    unregisterHandler,
    addConnectionListener,
    removeConnectionListener,
    connect,
    disconnect,
    send,
    reconnect,
    clearHistory,
    getHistory
  }
}) 