import { useState, useCallback, useRef, useEffect } from 'react'
import { useWebSocket, type WebSocketMessage } from './useWebSocket'

interface ProgressEntry {
  percent: number
  downloadedBytes?: number
  totalBytes?: number
  isComplete?: boolean  // Track completion status
}

interface ProgressState {
  [videoId: string]: ProgressEntry
}

interface UseDownloadProgressOptions {
  onVideoComplete?: () => void
  onDownloadStarted?: () => void  // Called when first progress arrives for any video
  onStatusChange?: (videoId: string, status: string) => void  // Called on status WebSocket messages
}

export function useDownloadProgress(options?: UseDownloadProgressOptions) {
  const [progress, setProgress] = useState<ProgressState>({})

  // Use refs to avoid stale closures in handleMessage
  const onVideoCompleteRef = useRef(options?.onVideoComplete)
  const onDownloadStartedRef = useRef(options?.onDownloadStarted)
  const onStatusChangeRef = useRef(options?.onStatusChange)
  useEffect(() => {
    onVideoCompleteRef.current = options?.onVideoComplete
    onDownloadStartedRef.current = options?.onDownloadStarted
    onStatusChangeRef.current = options?.onStatusChange
  }, [options?.onVideoComplete, options?.onDownloadStarted, options?.onStatusChange])

  // Track which videos we've already triggered refresh for (prevent duplicates)
  const refreshedVideosRef = useRef<Set<string>>(new Set())
  // Track which videos we've seen progress for (to trigger onDownloadStarted only once)
  const seenVideosRef = useRef<Set<string>>(new Set())

  const handleMessage = useCallback((message: WebSocketMessage) => {
    if (message.type === 'progress') {
      // Trigger onDownloadStarted when we see a new video's progress for the first time
      if (!seenVideosRef.current.has(message.video_id)) {
        seenVideosRef.current.add(message.video_id)
        onDownloadStartedRef.current?.()
      }

      setProgress(prev => ({
        ...prev,
        [message.video_id]: {
          percent: message.percent || 0,
          downloadedBytes: message.downloaded_bytes,
          totalBytes: message.total_bytes
        }
      }))
    }

    // Handle status change messages from backend (downloading, complete, failed, etc.)
    if (message.type === 'status' && message.video_id && message.status) {
      onStatusChangeRef.current?.(message.video_id, message.status)
      // Also trigger onDownloadStarted for status=downloading if we haven't seen this video
      if (message.status === 'downloading' && !seenVideosRef.current.has(message.video_id)) {
        seenVideosRef.current.add(message.video_id)
        onDownloadStartedRef.current?.()
      }
    }

    // Handle completion messages from backend (complete, cancelled, failed)
    if (message.type === 'completion' && message.video_id) {
      // Mark as complete with 100% progress (don't clear - let the overlay show "Complete")
      setProgress(prev => ({
        ...prev,
        [message.video_id]: {
          ...prev[message.video_id],
          percent: 100,
          isComplete: true
        }
      }))

      // Only trigger refresh once per video completion
      if (!refreshedVideosRef.current.has(message.video_id)) {
        refreshedVideosRef.current.add(message.video_id)
        // Small delay to ensure DB has committed
        setTimeout(() => {
          onVideoCompleteRef.current?.()
          // Clean up the tracking after refresh
          setTimeout(() => {
            refreshedVideosRef.current.delete(message.video_id)
          }, 5000)
        }, 300)
      }
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
