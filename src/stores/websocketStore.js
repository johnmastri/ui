import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useWebSocketStore = defineStore('websocket', () => {
  // Connection state
  const isConnected = ref(false)
  const hasRecentSend = ref(false)
  const hasRecentReceive = ref(false)
  // Use the current host instead of hardcoded localhost
  const serverUrl = ref(`ws://${window.location.hostname}:8765`)
  
  // Message handling
  const messageHandlers = ref(new Map())
  const messageHistory = ref([])
  const maxHistorySize = 50
  
  // WebSocket instance and reconnection
  let websocket = null
  let reconnectAttempts = 0
  const maxReconnectAttempts = 5
  let reconnectInterval = null
  let sendTimeout = null
  let receiveTimeout = null

  // Computed
  const connectionStatus = computed(() => 
    isConnected.value ? 'Connected' : 'Disconnected'
  )

  // Message handler registration
  const registerHandler = (messageType, handler) => {
    messageHandlers.value.set(messageType, handler)
  }

  const unregisterHandler = (messageType) => {
    messageHandlers.value.delete(messageType)
  }

  // Core WebSocket methods
  const connect = () => {
    try {
      websocket = new WebSocket(serverUrl.value)
      
      websocket.onopen = () => {
        isConnected.value = true
        reconnectAttempts = 0
      }
      
      websocket.onmessage = (event) => {
        handleIncomingMessage(event.data)
        showReceiveLight()
      }
      
      websocket.onclose = (event) => {
        isConnected.value = false
        
        // Auto-reconnect if not manually disconnected
        if (event.code !== 1000) {
          scheduleReconnect()
        }
      }
      
      websocket.onerror = (error) => {
        console.error('WebSocket: Connection error')
      }
      
    } catch (error) {
      console.error('WebSocket: Failed to connect')
      scheduleReconnect()
    }
  }

  const disconnect = () => {
    if (websocket) {
      websocket.close(1000) // Normal closure
      websocket = null
    }
    isConnected.value = false
    
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
      
      reconnectInterval = setTimeout(() => {
        connect()
      }, delay)
    }
  }

  const reconnect = () => {
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
    serverUrl,
    messageHistory,
    
    // Computed
    connectionStatus,
    
    // Methods
    registerHandler,
    unregisterHandler,
    connect,
    disconnect,
    send,
    reconnect,
    clearHistory,
    getHistory
  }
}) 