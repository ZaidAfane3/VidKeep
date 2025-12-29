import { Video as VideoIcon } from 'lucide-react'
import type { Video } from '../api/types'
import VideoCard from './VideoCard'

interface VideoGridProps {
  videos: Video[]
  onFavoriteToggle: (videoId: string, isFavorite: boolean) => void
  onDelete: (videoId: string) => void
  onPlay: (video: Video) => void
}

export default function VideoGrid({
  videos,
  onFavoriteToggle,
  onDelete,
  onPlay
}: VideoGridProps) {
  if (videos.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <VideoIcon
          className="w-16 h-16 mb-4 text-term-primary/40"
          strokeWidth={1}
        />
        <p className="text-heading text-term-primary uppercase tracking-wider mb-2 text-glow">
          NO VIDEOS FOUND
        </p>
        <p className="text-body text-term-primary/60">
          Add a YouTube URL to begin archiving
        </p>
      </div>
    )
  }

  return (
    <div
      className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
      role="list"
      aria-label="Video library"
    >
      {videos.map((video) => (
        <div key={video.video_id} role="listitem">
          <VideoCard
            video={video}
            onFavoriteToggle={onFavoriteToggle}
            onDelete={onDelete}
            onPlay={onPlay}
          />
        </div>
      ))}
    </div>
  )
}
