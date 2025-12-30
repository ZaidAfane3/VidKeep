import { useState, useEffect, useCallback } from 'react'
import type { Video } from '../api/types'
import { fetchVideos, updateVideoFavorite, deleteVideo as apiDeleteVideo, ingestVideo } from '../api/client'

interface UseVideosOptions {
  channel?: string
  favoritesOnly?: boolean
}

export function useVideos(options: UseVideosOptions = {}) {
  const [videos, setVideos] = useState<Video[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const loadVideos = useCallback(async () => {
    try {
      setLoading(true)
      setError(null)
      const response = await fetchVideos({
        channel: options.channel,
        favorites_only: options.favoritesOnly
      })
      setVideos(response.videos)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load videos')
    } finally {
      setLoading(false)
    }
  }, [options.channel, options.favoritesOnly])

  useEffect(() => {
    loadVideos()
  }, [loadVideos])

  const toggleFavorite = useCallback(async (videoId: string, isFavorite: boolean) => {
    // Optimistic update
    setVideos(prev =>
      prev.map(v =>
        v.video_id === videoId ? { ...v, is_favorite: isFavorite } : v
      )
    )

    try {
      await updateVideoFavorite(videoId, isFavorite)
    } catch (err) {
      // Revert on error
      setVideos(prev =>
        prev.map(v =>
          v.video_id === videoId ? { ...v, is_favorite: !isFavorite } : v
        )
      )
      console.error('Failed to update favorite:', err)
    }
  }, [])

  const deleteVideo = useCallback(async (videoId: string) => {
    try {
      await apiDeleteVideo(videoId)
      setVideos(prev => prev.filter(v => v.video_id !== videoId))
    } catch (err) {
      console.error('Failed to delete video:', err)
      throw err
    }
  }, [])

  const addVideo = useCallback((video: Video) => {
    setVideos(prev => [video, ...prev])
  }, [])

  const updateVideo = useCallback((videoId: string, updates: Partial<Video>) => {
    setVideos(prev =>
      prev.map(v =>
        v.video_id === videoId ? { ...v, ...updates } : v
      )
    )
  }, [])

  const retryVideo = useCallback(async (videoId: string) => {
    // Find the video to get its youtube_url
    const video = videos.find(v => v.video_id === videoId)
    if (!video?.youtube_url) {
      console.error('Cannot retry: video or youtube_url not found')
      return
    }

    // Optimistic update - set status to pending
    setVideos(prev =>
      prev.map(v =>
        v.video_id === videoId ? { ...v, status: 'pending' as const, error_message: null } : v
      )
    )

    try {
      // Re-ingest the video (backend handles retry for failed videos)
      await ingestVideo(video.youtube_url)
    } catch (err) {
      // Revert on error
      setVideos(prev =>
        prev.map(v =>
          v.video_id === videoId ? { ...v, status: 'failed' as const } : v
        )
      )
      console.error('Failed to retry video:', err)
    }
  }, [videos])

  return {
    videos,
    loading,
    error,
    refresh: loadVideos,
    toggleFavorite,
    deleteVideo,
    addVideo,
    updateVideo,
    retryVideo
  }
}
