import { useRef } from 'react'
import { Heart, Youtube, Play, Download, RefreshCw, Loader2, Trash2, StopCircle } from 'lucide-react'
import type { Video } from '../api/types'
import { getThumbnailUrl, getStreamUrl } from '../api/client'
import ProgressOverlay from './ProgressOverlay'
import ActionButton from './ActionButton'
import { formatDuration, formatFileSize } from '../utils/format'

interface VideoCardProps {
  video: Video
  onFavoriteToggle: (videoId: string, isFavorite: boolean) => void
  onDelete: (videoId: string) => void
  onPlay: (video: Video) => void
  onRetry?: (videoId: string) => void
  onCancel?: (videoId: string) => void
  isOverlayActive?: boolean
  onOverlayActivate?: () => void
}

// Threshold in pixels - if touch moves more than this, it's a swipe not a tap
const SWIPE_THRESHOLD = 10

export default function VideoCard({
  video,
  onFavoriteToggle,
  onDelete,
  onPlay,
  onRetry,
  onCancel,
  isOverlayActive = false,
  onOverlayActivate
}: VideoCardProps) {
  // Track touch start position to differentiate tap from swipe
  const touchStartRef = useRef<{ x: number; y: number } | null>(null)

  const thumbnailUrl = getThumbnailUrl(video.video_id)
  const isComplete = video.status === 'complete'
  const isDownloading = video.status === 'downloading'
  const isFailed = video.status === 'failed'
  const isPending = video.status === 'pending'
  const isCancelled = video.status === 'cancelled'

  const handleDownload = (e: React.MouseEvent) => {
    e.stopPropagation()
    const link = document.createElement('a')
    link.href = getStreamUrl(video.video_id)
    link.download = `${video.title}.mp4`
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const handleYouTube = (e: React.MouseEvent) => {
    e.stopPropagation()
    window.open(video.youtube_url, '_blank', 'noopener,noreferrer')
  }

  const handlePlay = (e: React.MouseEvent) => {
    e.stopPropagation()
    onPlay(video)
  }

  const handleRetry = (e: React.MouseEvent) => {
    e.stopPropagation()
    onRetry?.(video.video_id)
  }

  const handleDelete = (e: React.MouseEvent) => {
    e.stopPropagation()
    onDelete(video.video_id)
  }

  const handleCancel = (e: React.MouseEvent) => {
    e.stopPropagation()
    onCancel?.(video.video_id)
  }

  const handleTouchStart = (e: React.TouchEvent) => {
    const touch = e.touches[0]
    touchStartRef.current = { x: touch.clientX, y: touch.clientY }
  }

  const handleTouchEnd = (e: React.TouchEvent) => {
    if (!touchStartRef.current) return

    const touch = e.changedTouches[0]
    const deltaX = Math.abs(touch.clientX - touchStartRef.current.x)
    const deltaY = Math.abs(touch.clientY - touchStartRef.current.y)

    // Only activate overlay if it was a tap (not a swipe)
    if (deltaX < SWIPE_THRESHOLD && deltaY < SWIPE_THRESHOLD) {
      onOverlayActivate?.()
    }

    touchStartRef.current = null
  }

  return (
    <div
      data-video-card
      className={`card-terminal overflow-hidden group relative ${isPending ? 'border-term-warning' : ''} ${isDownloading ? 'border-term-info' : ''} ${isFailed || isCancelled ? 'border-term-error' : ''}`}
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      {/* Thumbnail container */}
      <div className="relative aspect-video bg-term-dark">
        <img
          src={thumbnailUrl}
          alt={video.title}
          className="w-full h-full object-cover thumbnail-terminal"
          loading="lazy"
          onError={(e) => {
            e.currentTarget.style.display = 'none'
          }}
        />

        {/* Progress overlay for downloading (always visible, no cancel - cancel is on hover) */}
        {isDownloading && (
          <ProgressOverlay
            progress={video.download_progress || 0}
          />
        )}

        {/* Status badges removed - status indicated by card border color */}

        {/* Duration badge (bottom-right) - Phosphor Console style */}
        {isComplete && video.duration_seconds && (
          <div className="absolute bottom-2 right-2 bg-term-bg/90 border border-term-dim px-2 py-0.5 text-mono text-term-primary z-10">
            {formatDuration(video.duration_seconds)}
          </div>
        )}

        {/* Favorite button (top-right) */}
        <button
          onClick={(e) => {
            e.stopPropagation()
            onFavoriteToggle(video.video_id, !video.is_favorite)
          }}
          className={`absolute top-2 right-2 p-1.5 border transition-all z-10
                     ${video.is_favorite
                       ? 'bg-term-error border-term-error text-black'
                       : 'bg-term-bg/80 border-term-dim text-term-primary opacity-0 group-hover:opacity-100 hover:border-term-primary'
                     }`}
          aria-label={video.is_favorite ? 'Remove from favorites' : 'Add to favorites'}
        >
          <Heart
            className="w-4 h-4"
            fill={video.is_favorite ? 'currentColor' : 'none'}
            strokeWidth={2}
          />
        </button>

        {/* Action overlay - shows on hover/tap for all states */}
        <div
          className={`
            absolute inset-0 bg-term-bg/90
            transition-opacity duration-200 flex items-center justify-center
            ${isOverlayActive
              ? 'opacity-100'
              : 'opacity-0 group-hover:opacity-100'
            }
          `}
        >
          {/* Complete: Show YouTube, Play, Download, Delete buttons */}
          {isComplete && (
            <div className="flex items-center gap-4">
              <ActionButton
                onClick={handleYouTube}
                icon={<Youtube className="w-5 h-5" />}
                label="YouTube"
              />
              <ActionButton
                onClick={handlePlay}
                icon={<Play className="w-5 h-5" fill="currentColor" />}
                label="Play"
              />
              <ActionButton
                onClick={handleDownload}
                icon={<Download className="w-5 h-5" />}
                label="Download"
              />
              <ActionButton
                onClick={handleDelete}
                icon={<Trash2 className="w-5 h-5" />}
                label="Delete"
                variant="danger"
              />
            </div>
          )}

          {/* Failed: Show Retry and Delete buttons */}
          {isFailed && (
            <div className="flex items-center gap-4">
              <ActionButton
                onClick={handleYouTube}
                icon={<Youtube className="w-5 h-5" />}
                label="YouTube"
              />
              <ActionButton
                onClick={handleRetry}
                icon={<RefreshCw className="w-5 h-5" />}
                label="Retry"
                variant="danger"
              />
              <ActionButton
                onClick={handleDelete}
                icon={<Trash2 className="w-5 h-5" />}
                label="Delete"
                variant="danger"
              />
            </div>
          )}

          {/* Pending: Show spinner and cancel button */}
          {isPending && (
            <div className="flex flex-col items-center gap-3 text-term-warning">
              <Loader2 className="w-8 h-8 animate-spin" />
              <span className="text-mono text-xs uppercase tracking-wider">
                QUEUED...
              </span>
              {onCancel && (
                <ActionButton
                  onClick={handleCancel}
                  icon={<StopCircle className="w-5 h-5" />}
                  label="Cancel"
                  variant="danger"
                />
              )}
            </div>
          )}

          {/* Downloading: Show cancel button on hover */}
          {isDownloading && onCancel && (
            <div className="flex flex-col items-center gap-3">
              <ActionButton
                onClick={handleCancel}
                icon={<StopCircle className="w-5 h-5" />}
                label="Cancel"
                variant="danger"
              />
            </div>
          )}

          {/* Cancelled: Show Retry and Delete buttons */}
          {isCancelled && (
            <div className="flex items-center gap-4">
              <ActionButton
                onClick={handleYouTube}
                icon={<Youtube className="w-5 h-5" />}
                label="YouTube"
              />
              <ActionButton
                onClick={handleRetry}
                icon={<RefreshCw className="w-5 h-5" />}
                label="Retry"
                variant="danger"
              />
              <ActionButton
                onClick={handleDelete}
                icon={<Trash2 className="w-5 h-5" />}
                label="Delete"
                variant="danger"
              />
            </div>
          )}
        </div>
      </div>

      {/* Card content - fixed height for consistency */}
      <div className="p-3 border-t border-term-dim h-[7.5rem] flex flex-col">
        {/* Title with RTL support - fixed 2-line height container */}
        <div className="h-[3rem] mb-1">
          <h3
            dir="auto"
            className="text-h3 text-term-primary line-clamp-2 text-glow"
            title={video.title}
          >
            {video.title}
          </h3>
        </div>

        {/* Channel name - always aligned */}
        <p
          dir="auto"
          className="text-mono text-term-primary/60 line-clamp-1 uppercase"
        >
          {video.channel_name}
        </p>

        {/* Meta info - pushed to bottom */}
        <div className="mt-auto pt-1">
          {/* File size (for complete videos) */}
          {isComplete && video.file_size_bytes && (
            <p className="text-mono text-term-dim">
              {formatFileSize(video.file_size_bytes)}
            </p>
          )}

          {/* Error message (for failed videos) */}
          {isFailed && (
            <p className="text-mono text-term-error line-clamp-1" title={video.error_message || 'Download failed'}>
              {video.error_message ? `ERROR: ${video.error_message}` : 'FAILED'}
            </p>
          )}

          {/* Cancelled status */}
          {isCancelled && (
            <p className="text-mono text-term-error">CANCELLED</p>
          )}

          {/* Status text for pending/downloading */}
          {isPending && (
            <p className="text-mono text-term-warning">QUEUED</p>
          )}
          {isDownloading && (
            <p className="text-mono text-term-info">DOWNLOADING...</p>
          )}
        </div>
      </div>
    </div>
  )
}
