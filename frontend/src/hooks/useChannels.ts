import { useState, useEffect, useCallback } from 'react'
import type { Channel } from '../api/types'
import { fetchChannels } from '../api/client'

export function useChannels() {
  const [channels, setChannels] = useState<Channel[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadChannels = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await fetchChannels()
      setChannels(response.channels)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load channels')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    loadChannels()
  }, [loadChannels])

  return {
    channels,
    loading,
    error,
    refresh: loadChannels
  }
}
