import { useEffect, useState, useCallback } from 'react'

export interface WebSocketMessage {
  type: string
  video_id: string
  percent?: number
  downloaded_bytes?: number
  total_bytes?: number
}

interface UseWebSocketOptions {
  onMessage?: (message: WebSocketMessage) => void
  reconnectInterval?: number
}

// Module-level singleton state (lives outside React lifecycle)
let wsInstance: WebSocket | null = null
let wsListeners: Set<(msg: WebSocketMessage) => void> = new Set()
let connectionStateListeners: Set<(connected: boolean) => void> = new Set()
let reconnectTimeout: ReturnType<typeof setTimeout> | null = null
let pingInterval: ReturnType<typeof setInterval> | null = null
let isConnecting = false

function notifyConnectionState(connected: boolean) {
  connectionStateListeners.forEach(listener => listener(connected))
}

function getOrCreateConnection(reconnectInterval: number = 5000): WebSocket | null {
  // Already have an open connection
  if (wsInstance && wsInstance.readyState === WebSocket.OPEN) {
    return wsInstance
  }

  // Connection attempt in progress
  if (isConnecting && wsInstance) {
    return wsInstance
  }

  // Clear any pending reconnect
  if (reconnectTimeout) {
    clearTimeout(reconnectTimeout)
    reconnectTimeout = null
  }

  isConnecting = true
  const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
  const wsUrl = `${protocol}//${window.location.host}/ws/progress`

  try {
    wsInstance = new WebSocket(wsUrl)

    wsInstance.onopen = () => {
      isConnecting = false
      console.log('[WS] Connected to progress updates')
      notifyConnectionState(true)

      // Start ping interval for keepalive
      if (pingInterval) {
        clearInterval(pingInterval)
      }
      pingInterval = setInterval(() => {
        if (wsInstance && wsInstance.readyState === WebSocket.OPEN) {
          wsInstance.send('ping')
        }
      }, 30000)
    }

    wsInstance.onmessage = (event) => {
      // Ignore pong responses
      if (event.data === 'pong') return

      try {
        const message = JSON.parse(event.data) as WebSocketMessage
        // Broadcast to all listeners
        wsListeners.forEach(listener => {
          try {
            listener(message)
          } catch (e) {
            console.error('[WS] Listener error:', e)
          }
        })
      } catch (e) {
        console.error('[WS] Failed to parse message:', e)
      }
    }

    wsInstance.onclose = () => {
      isConnecting = false
      wsInstance = null
      console.log('[WS] Disconnected, attempting reconnect...')
      notifyConnectionState(false)

      // Clear ping interval
      if (pingInterval) {
        clearInterval(pingInterval)
        pingInterval = null
      }

      // Attempt reconnect if we still have listeners
      if (wsListeners.size > 0 || connectionStateListeners.size > 0) {
        reconnectTimeout = setTimeout(() => {
          getOrCreateConnection(reconnectInterval)
        }, reconnectInterval)
      }
    }

    wsInstance.onerror = (error) => {
      console.error('[WS] Error:', error)
      if (wsInstance) {
        wsInstance.close()
      }
    }

    return wsInstance
  } catch (error) {
    console.error('[WS] Failed to connect:', error)
    isConnecting = false

    // Retry connection if we have listeners
    if (wsListeners.size > 0 || connectionStateListeners.size > 0) {
      reconnectTimeout = setTimeout(() => {
        getOrCreateConnection(reconnectInterval)
      }, reconnectInterval)
    }
    return null
  }
}

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const { onMessage, reconnectInterval = 5000 } = options
  const [isConnected, setIsConnected] = useState(
    wsInstance?.readyState === WebSocket.OPEN
  )

  // Stable callback ref for connection state
  const handleConnectionChange = useCallback((connected: boolean) => {
    setIsConnected(connected)
  }, [])

  useEffect(() => {
    // Subscribe to connection state changes
    connectionStateListeners.add(handleConnectionChange)

    // Subscribe message listener if provided
    if (onMessage) {
      wsListeners.add(onMessage)
    }

    // Get or create shared connection
    getOrCreateConnection(reconnectInterval)

    // Update initial state
    setIsConnected(wsInstance?.readyState === WebSocket.OPEN)

    return () => {
      // Unsubscribe listeners but DON'T close the connection
      connectionStateListeners.delete(handleConnectionChange)
      if (onMessage) {
        wsListeners.delete(onMessage)
      }

      // Only cleanup connection if no more listeners remain
      // This prevents closing during StrictMode remounts
      if (wsListeners.size === 0 && connectionStateListeners.size === 0) {
        if (reconnectTimeout) {
          clearTimeout(reconnectTimeout)
          reconnectTimeout = null
        }
        if (pingInterval) {
          clearInterval(pingInterval)
          pingInterval = null
        }
        if (wsInstance) {
          wsInstance.close()
          wsInstance = null
        }
      }
    }
  }, [onMessage, reconnectInterval, handleConnectionChange])

  return { isConnected }
}
