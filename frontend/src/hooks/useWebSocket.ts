import { useEffect, useRef, useCallback, useState } from 'react'

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

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const { onMessage, reconnectInterval = 5000 } = options
  const wsRef = useRef<WebSocket | null>(null)
  const [isConnected, setIsConnected] = useState(false)
  const reconnectTimeoutRef = useRef<ReturnType<typeof setTimeout>>()
  const pingIntervalRef = useRef<ReturnType<typeof setInterval>>()

  const connect = useCallback(() => {
    // Determine WebSocket URL based on current location
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = window.location.host
    const wsUrl = `${protocol}//${host}/ws/progress`

    try {
      const ws = new WebSocket(wsUrl)

      ws.onopen = () => {
        setIsConnected(true)
        console.log('[WS] Connected to progress updates')

        // Start ping interval for keepalive
        pingIntervalRef.current = setInterval(() => {
          if (ws.readyState === WebSocket.OPEN) {
            ws.send('ping')
          }
        }, 30000)
      }

      ws.onmessage = (event) => {
        // Ignore pong responses
        if (event.data === 'pong') return

        try {
          const message = JSON.parse(event.data) as WebSocketMessage
          onMessage?.(message)
        } catch (e) {
          console.error('[WS] Failed to parse message:', e)
        }
      }

      ws.onclose = () => {
        setIsConnected(false)
        console.log('[WS] Disconnected, attempting reconnect...')

        // Clear ping interval
        if (pingIntervalRef.current) {
          clearInterval(pingIntervalRef.current)
        }

        // Attempt reconnect
        reconnectTimeoutRef.current = setTimeout(connect, reconnectInterval)
      }

      ws.onerror = (error) => {
        console.error('[WS] Error:', error)
        ws.close()
      }

      wsRef.current = ws
    } catch (error) {
      console.error('[WS] Failed to connect:', error)
      // Retry connection
      reconnectTimeoutRef.current = setTimeout(connect, reconnectInterval)
    }
  }, [onMessage, reconnectInterval])

  useEffect(() => {
    connect()

    return () => {
      // Cleanup on unmount
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current)
      }
      if (pingIntervalRef.current) {
        clearInterval(pingIntervalRef.current)
      }
      if (wsRef.current) {
        wsRef.current.close()
      }
    }
  }, [connect])

  return { isConnected }
}
