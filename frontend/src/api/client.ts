import type {
  Video,
  VideoListResponse,
  IngestRequest,
  IngestResponse,
  ChannelsResponse,
  QueueStatus,
  ApiError,
} from './types'

const API_BASE = '/api'

/**
 * Custom error class for API errors
 */
export class ApiClientError extends Error {
  constructor(
    message: string,
    public status: number,
    public detail?: string
  ) {
    super(message)
    this.name = 'ApiClientError'
  }
}

/**
 * Generic response handler
 */
async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    let detail: string | undefined
    try {
      const error: ApiError = await response.json()
      detail = error.detail
    } catch {
      detail = response.statusText
    }
    throw new ApiClientError(
      detail || 'Request failed',
      response.status,
      detail
    )
  }
  return response.json()
}

/**
 * Fetch all videos with optional filters
 * @endpoint GET /api/videos
 */
export async function fetchVideos(params?: {
  channel?: string
  favorites_only?: boolean
  status?: string
}): Promise<VideoListResponse> {
  const searchParams = new URLSearchParams()
  if (params?.channel) searchParams.set('channel', params.channel)
  if (params?.favorites_only) searchParams.set('favorites_only', 'true')
  if (params?.status) searchParams.set('status_filter', params.status)

  const url = `${API_BASE}/videos?${searchParams}`
  const response = await fetch(url)
  return handleResponse<VideoListResponse>(response)
}

/**
 * Fetch single video by ID
 * @endpoint GET /api/videos/{video_id}
 */
export async function fetchVideo(videoId: string): Promise<Video> {
  const response = await fetch(`${API_BASE}/videos/${videoId}`)
  return handleResponse<Video>(response)
}

/**
 * Fetch all channels with video counts
 * @endpoint GET /api/channels
 */
export async function fetchChannels(): Promise<ChannelsResponse> {
  const response = await fetch(`${API_BASE}/channels`)
  return handleResponse<ChannelsResponse>(response)
}

/**
 * Ingest (queue) a new video for download
 * @endpoint POST /api/videos/ingest
 */
export async function ingestVideo(url: string): Promise<IngestResponse> {
  const response = await fetch(`${API_BASE}/videos/ingest`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ url } as IngestRequest),
  })
  return handleResponse<IngestResponse>(response)
}

/**
 * Update video favorite status
 * @endpoint PATCH /api/videos/{video_id}
 */
export async function updateVideoFavorite(
  videoId: string,
  isFavorite: boolean
): Promise<Video> {
  const response = await fetch(`${API_BASE}/videos/${videoId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ is_favorite: isFavorite }),
  })
  return handleResponse<Video>(response)
}

/**
 * Delete a video and its files
 * @endpoint DELETE /api/videos/{video_id}
 */
export async function deleteVideo(videoId: string): Promise<void> {
  const response = await fetch(`${API_BASE}/videos/${videoId}`, {
    method: 'DELETE',
  })
  if (!response.ok) {
    throw new ApiClientError('Failed to delete video', response.status)
  }
}

/**
 * Cancel an in-progress or pending download
 * @endpoint POST /api/videos/{video_id}/cancel
 */
export async function cancelDownload(videoId: string): Promise<{ video_id: string; status: string; message: string }> {
  const response = await fetch(`${API_BASE}/videos/${videoId}/cancel`, {
    method: 'POST',
  })
  return handleResponse<{ video_id: string; status: string; message: string }>(response)
}

/**
 * Get queue status
 * @endpoint GET /api/queue/status
 */
export async function fetchQueueStatus(): Promise<QueueStatus> {
  const response = await fetch(`${API_BASE}/queue/status`)
  return handleResponse<QueueStatus>(response)
}


/**
 * Get stream URL for a video
 * @note Not a fetch, just URL construction for <video> src
 */
export function getStreamUrl(videoId: string): string {
  return `${API_BASE}/stream/${videoId}`
}

/**
 * Get thumbnail URL for a video
 * @note Not a fetch, just URL construction for <img> src
 */
export function getThumbnailUrl(videoId: string): string {
  return `${API_BASE}/thumbnail/${videoId}`
}
