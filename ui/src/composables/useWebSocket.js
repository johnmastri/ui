import { ref, onMounted, onUnmounted } from 'vue'

export function useWebSocket() {
  // Reactive state
  const isWebSocketConnected = ref(false)
  const hasRecentSend = ref(false)
  const hasRecentReceive = ref(false)
  const websocketServer = ref('ws://localhost:8765')
  
  // Internal state
  let websocket = null
  let sendTimeout = null
  let receiveTimeout = null
  let reconnectAttempts = 0
  const maxReconnectAttempts = 5
  let reconnectInterval = null

  // Methods
  const connectWebSocket = () => {
    try {
      console.log(`WebSocket: Attempting to connect to ${websocketServer.value}`)
      websocket = new WebSocket(websocketServer.value)
      
      websocket.onopen = () => {
        isWebSocketConnected.value = true
        reconnectAttempts = 0 // Reset attempts on successful connection
        console.log(`WebSocket: Connected to ${websocketServer.value}`)
      }
      
      websocket.onmessage = (event) => {
        console.log(`WebSocket: Received: ${event.data}`)
        showReceiveLight()
      }
      
      websocket.onclose = (event) => {
        isWebSocketConnected.value = false
        console.log(`WebSocket: Disconnected - Code: ${event.code}, Reason: ${event.reason}`)
        
        // Auto-reconnect if not manually disconnected
        if (event.code !== 1000) { // 1000 = normal closure
          scheduleReconnect()
        }
      }
      
      websocket.onerror = (error) => {
        console.log(`WebSocket: Error - ${error}`)
      }
      
    } catch (error) {
      console.log(`WebSocket: Failed to connect - ${error.message}`)
      scheduleReconnect()
    }
  }

  const scheduleReconnect = () => {
    if (reconnectAttempts < maxReconnectAttempts) {
      reconnectAttempts++
      const delay = Math.min(1000 * Math.pow(2, reconnectAttempts), 30000) // Exponential backoff, max 30s
      
      console.log(`WebSocket: Scheduling reconnect attempt ${reconnectAttempts}/${maxReconnectAttempts} in ${delay}ms`)
      
      reconnectInterval = setTimeout(() => {
        connectWebSocket()
      }, delay)
    } else {
      console.log('WebSocket: Max reconnect attempts reached. Manual reconnect required.')
    }
  }

  const disconnectWebSocket = () => {
    if (websocket) {
      websocket.close(1000) // Normal closure
      websocket = null
    }
    isWebSocketConnected.value = false
    
    // Clear any pending reconnect attempts
    if (reconnectInterval) {
      clearTimeout(reconnectInterval)
      reconnectInterval = null
    }
    reconnectAttempts = 0
  }

  const sendWebSocketMessage = (message) => {
    if (websocket && websocket.readyState === WebSocket.OPEN) {
      const messageStr = JSON.stringify(message)
      websocket.send(messageStr)
      console.log(`WebSocket: Sent: ${messageStr}`)
      showSendLight()
    } else {
      console.log('WebSocket: Cannot send - not connected')
    }
  }

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

  const reconnectWebSocket = () => {
    console.log('WebSocket: Manual reconnect requested')
    disconnectWebSocket()
    reconnectAttempts = 0 // Reset retry counter for manual reconnect
    setTimeout(() => {
      connectWebSocket()
    }, 100)
  }

  const initWebSocket = () => {
    console.log('WebSocket: Initializing WebSocket connection...')
    connectWebSocket()
  }

  const closeWebSocket = () => {
    disconnectWebSocket()
  }

  // Lifecycle
  onMounted(() => {
    initWebSocket()
  })

  onUnmounted(() => {
    closeWebSocket()
  })

  return {
    // Reactive state
    isWebSocketConnected,
    hasRecentSend,
    hasRecentReceive,
    websocketServer,
    
    // Methods
    connectWebSocket,
    disconnectWebSocket,
    sendWebSocketMessage,
    reconnectWebSocket,
    initWebSocket,
    closeWebSocket
  }
} 