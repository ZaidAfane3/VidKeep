import { useState, useCallback } from 'react'
import { useWebSocket, type WebSocketMessage } from './useWebSocket'

interface ProgressState {
  [videoId: string]: {
    percent: number
    downloadedBytes?: number
    totalBytes?: number
  }
}

export function useDownloadProgress() {
  const [progress, setProgress] = useState<ProgressState>({})

  const handleMessage = useCallback((message: WebSocketMessage) => {
    if (message.type === 'progress') {
      setProgress(prev => ({
        ...prev,
        [message.video_id]: {
          percent: message.percent || 0,
          downloadedBytes: message.downloaded_bytes,
          totalBytes: message.total_bytes
        }
      }))
    }

    // Clear progress when download completes or fails
    // (This would be sent by backend if we add status updates to WebSocket)
    if (message.type === 'status' && ['complete', 'failed'].includes(message.video_id)) {
      setProgress(prev => {
        const next = { ...prev }
        delete next[message.video_id]
        return next
      })
    }
  }, [])

  const { isConnected } = useWebSocket({ onMessage: handleMessage })

  const getProgress = useCallback((videoId: string): number | null => {
    return progress[videoId]?.percent ?? null
  }, [progress])

  const clearProgress = useCallback((videoId: string) => {
    setProgress(prev => {
      const next = { ...prev }
      delete next[videoId]
      return next
    })
  }, [])

  return { progress, getProgress, clearProgress, isConnected }
}
