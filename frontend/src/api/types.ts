/**
 * Video status enum matching backend VideoStatus
 * @see backend/app/schemas.py
 */
export type VideoStatus = 'pending' | 'downloading' | 'complete' | 'failed'

/**
 * Video entity matching VideoResponse schema
 * @see backend/app/schemas.py - VideoResponse
 */
export interface Video {
  video_id: string
  title: string
  channel_name: string
  channel_id: string | null
  duration_seconds: number | null
  upload_date: string | null
  description: string | null
  is_favorite: boolean
  status: VideoStatus
  file_size_bytes: number | null
  created_at: string
  error_message: string | null
  youtube_url: string
  download_progress: number | null
}

/**
 * Video list response
 * @see backend/app/schemas.py - VideoListResponse
 */
export interface VideoListResponse {
  videos: Video[]
  total: number
}

/**
 * Ingest request payload
 * @see backend/app/schemas.py - VideoCreate
 */
export interface IngestRequest {
  url: string
}

/**
 * Ingest response
 * @see backend/app/schemas.py - IngestResponse
 */
export interface IngestResponse {
  video_id: string
  message: string
}

/**
 * Channel entity
 * @see backend/app/schemas.py - ChannelResponse
 */
export interface Channel {
  channel_name: string
  video_count: number
}

/**
 * Channel list response
 * @see backend/app/schemas.py - ChannelListResponse
 */
export interface ChannelsResponse {
  channels: Channel[]
}

/**
 * Queue status response
 * @see backend/app/routers/queue.py
 */
export interface QueueStatus {
  pending: number
  processing: number
  total: number
}

/**
 * API Error response
 */
export interface ApiError {
  detail: string
}
