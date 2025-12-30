import { useState, useEffect, useCallback } from 'react'
import { fetchQueueStatus } from '../api/client'
import type { QueueStatus } from '../api/types'

interface UseQueueStatusOptions {
  pollInterval?: number
  enabled?: boolean
}

export function useQueueStatus(options: UseQueueStatusOptions = {}) {
  const { pollInterval = 5000, enabled = true } = options

  const [status, setStatus] = useState<QueueStatus | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchStatus = useCallback(async () => {
    try {
      const data = await fetchQueueStatus()
      setStatus(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch queue status')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (!enabled) return

    // Initial fetch
    fetchStatus()

    // Poll for updates
    const interval = setInterval(fetchStatus, pollInterval)

    return () => clearInterval(interval)
  }, [enabled, pollInterval, fetchStatus])

  return {
    pending: status?.pending ?? 0,
    processing: status?.processing ?? 0,
    total: status?.total ?? 0,
    loading,
    error,
    refresh: fetchStatus
  }
}
