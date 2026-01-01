# T014: Thumbnail Card Component

## 1. Description

Implement the VideoCard component that displays video thumbnails with status overlays, duration badges, and interactive elements. Cards show download progress for active downloads and error indicators for failed ones.

**Why**: The card is the main interaction point for each video. It must convey status, metadata, and available actions at a glance.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    VideoCard.tsx
    StatusBadge.tsx
    ProgressOverlay.tsx
  utils/
    format.ts
```

### Video Card Component (components/VideoCard.tsx)

```typescript
import { Video } from '../api/types'
import StatusBadge from './StatusBadge'
import ProgressOverlay from './ProgressOverlay'
import { formatDuration, formatFileSize } from '../utils/format'

interface VideoCardProps {
  video: Video
  onFavoriteToggle: (videoId: string, isFavorite: boolean) => void
  onDelete: (videoId: string) => void
  onPlay: (video: Video) => void
}

export default function VideoCard({
  video,
  onFavoriteToggle,
  onDelete,
  onPlay
}: VideoCardProps) {
  const thumbnailUrl = `/api/thumbnail/${video.video_id}`
  const isComplete = video.status === 'complete'
  const isDownloading = video.status === 'downloading'
  const isFailed = video.status === 'failed'
  const isPending = video.status === 'pending'

  return (
    <div className="bg-vidkeep-card rounded-lg overflow-hidden group relative">
      {/* Thumbnail container */}
      <div className="relative aspect-video bg-vidkeep-accent/20">
        <img
          src={thumbnailUrl}
          alt={video.title}
          className="w-full h-full object-cover"
          loading="lazy"
          onError={(e) => {
            // Fallback to placeholder
            e.currentTarget.src = '/placeholder-thumbnail.svg'
          }}
        />

        {/* Progress overlay for downloading */}
        {isDownloading && (
          <ProgressOverlay progress={video.download_progress || 0} />
        )}

        {/* Status badge (top-left) */}
        {!isComplete && (
          <div className="absolute top-2 left-2">
            <StatusBadge status={video.status} />
          </div>
        )}

        {/* Duration badge (bottom-right) */}
        {isComplete && video.duration_seconds && (
          <div className="absolute bottom-2 right-2 bg-black/80 px-1.5 py-0.5 rounded text-xs">
            {formatDuration(video.duration_seconds)}
          </div>
        )}

        {/* Favorite button (top-right) */}
        <button
          onClick={(e) => {
            e.stopPropagation()
            onFavoriteToggle(video.video_id, !video.is_favorite)
          }}
          className="absolute top-2 right-2 p-1.5 rounded-full bg-black/50
                     hover:bg-black/70 transition-colors opacity-0 group-hover:opacity-100"
          aria-label={video.is_favorite ? 'Remove from favorites' : 'Add to favorites'}
        >
          <svg
            className={`w-5 h-5 ${video.is_favorite ? 'text-red-500 fill-current' : 'text-white'}`}
            fill={video.is_favorite ? 'currentColor' : 'none'}
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
            />
          </svg>
        </button>

        {/* Action overlay (on hover) - handled in T015 */}
        <div
          className="absolute inset-0 bg-black/60 opacity-0 group-hover:opacity-100
                     transition-opacity flex items-center justify-center gap-4"
          onClick={() => isComplete && onPlay(video)}
        >
          {/* Placeholder for action buttons from T015 */}
        </div>
      </div>

      {/* Card content */}
      <div className="p-3">
        {/* Title with RTL support */}
        <h3
          dir="auto"
          className="font-medium text-sm line-clamp-2 mb-1"
          title={video.title}
        >
          {video.title}
        </h3>

        {/* Channel name */}
        <p
          dir="auto"
          className="text-xs text-vidkeep-accent line-clamp-1"
        >
          {video.channel_name}
        </p>

        {/* File size (for complete videos) */}
        {isComplete && video.file_size_bytes && (
          <p className="text-xs text-vidkeep-accent mt-1">
            {formatFileSize(video.file_size_bytes)}
          </p>
        )}

        {/* Error message (for failed videos) */}
        {isFailed && video.error_message && (
          <p className="text-xs text-red-400 mt-1 line-clamp-1" title={video.error_message}>
            {video.error_message}
          </p>
        )}
      </div>
    </div>
  )
}
```

### Status Badge (components/StatusBadge.tsx)

```typescript
import { VideoStatus } from '../api/types'

interface StatusBadgeProps {
  status: VideoStatus
}

const statusConfig = {
  pending: {
    label: 'Pending',
    className: 'bg-yellow-500/80 text-yellow-100'
  },
  downloading: {
    label: 'Downloading',
    className: 'bg-blue-500/80 text-blue-100'
  },
  failed: {
    label: 'Failed',
    className: 'bg-red-500/80 text-red-100'
  },
  complete: {
    label: 'Complete',
    className: 'bg-green-500/80 text-green-100'
  }
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  const config = statusConfig[status]

  return (
    <span className={`px-2 py-0.5 rounded text-xs font-medium ${config.className}`}>
      {config.label}
    </span>
  )
}
```

### Progress Overlay (components/ProgressOverlay.tsx)

```typescript
interface ProgressOverlayProps {
  progress: number
}

export default function ProgressOverlay({ progress }: ProgressOverlayProps) {
  return (
    <div className="absolute inset-0 bg-black/70 flex flex-col items-center justify-center">
      {/* Circular progress */}
      <div className="relative w-16 h-16">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
          {/* Background circle */}
          <circle
            cx="18"
            cy="18"
            r="16"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-vidkeep-accent/30"
          />
          {/* Progress circle */}
          <circle
            cx="18"
            cy="18"
            r="16"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeDasharray={`${progress} 100`}
            className="text-vidkeep-primary"
          />
        </svg>
        {/* Percentage text */}
        <span className="absolute inset-0 flex items-center justify-center text-sm font-medium">
          {progress}%
        </span>
      </div>
      <p className="text-xs text-vidkeep-accent mt-2">Downloading...</p>
    </div>
  )
}
```

### Formatting Utilities (utils/format.ts)

```typescript
export function formatDuration(seconds: number): string {
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const secs = seconds % 60

  if (hours > 0) {
    return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
  }
  return `${minutes}:${secs.toString().padStart(2, '0')}`
}

export function formatFileSize(bytes: number): string {
  const units = ['B', 'KB', 'MB', 'GB']
  let size = bytes
  let unitIndex = 0

  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024
    unitIndex++
  }

  return `${size.toFixed(1)} ${units[unitIndex]}`
}

export function formatDate(dateString: string): string {
  return new Date(dateString).toLocaleDateString()
}
```

### Dependencies

- T013 (Video grid)
- T010 (Thumbnail endpoint)

## 3. Implementation Verification

- [x] Thumbnail loads from /api/thumbnail/{id}
- [x] Fallback shown if thumbnail fails
- [x] Duration badge displays for complete videos
- [x] Progress overlay shows percentage during download
- [x] Status badge shows for non-complete videos
- [x] Favorite button toggles heart icon/color
- [x] RTL text (Arabic) displays correctly (dir="auto")
- [x] Hover reveals action overlay
- [x] Error message shows for failed videos

### Tests to Write

```typescript
// src/__tests__/VideoCard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import VideoCard from '../components/VideoCard'

const mockVideo = {
  video_id: 'test123',
  title: 'Test Video',
  channel_name: 'Test Channel',
  status: 'complete' as const,
  is_favorite: false,
  duration_seconds: 125,
  file_size_bytes: 104857600, // 100MB
  youtube_url: 'https://youtube.com/watch?v=test123',
  download_progress: null,
  channel_id: null,
  upload_date: null,
  description: null,
  created_at: '2024-01-01T00:00:00Z',
  error_message: null,
}

test('displays duration badge for complete video', () => {
  render(
    <VideoCard
      video={mockVideo}
      onFavoriteToggle={() => {}}
      onDelete={() => {}}
      onPlay={() => {}}
    />
  )
  expect(screen.getByText('2:05')).toBeInTheDocument()
})

test('shows progress overlay when downloading', () => {
  const downloadingVideo = {
    ...mockVideo,
    status: 'downloading' as const,
    download_progress: 42
  }
  render(
    <VideoCard
      video={downloadingVideo}
      onFavoriteToggle={() => {}}
      onDelete={() => {}}
      onPlay={() => {}}
    />
  )
  expect(screen.getByText('42%')).toBeInTheDocument()
})

// utils/format.test.ts
import { formatDuration, formatFileSize } from '../utils/format'

test('formatDuration handles minutes and seconds', () => {
  expect(formatDuration(65)).toBe('1:05')
  expect(formatDuration(3661)).toBe('1:01:01')
})

test('formatFileSize handles various sizes', () => {
  expect(formatFileSize(1024)).toBe('1.0 KB')
  expect(formatFileSize(1048576)).toBe('1.0 MB')
})
```

### Commands to Verify

```bash
# Visual verification in browser
npm run dev
# Check:
# - Thumbnail loading
# - Hover states
# - RTL text (add a video with Arabic title)
# - Progress overlay (mock a downloading video)
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2024-12-29 | Created utils/format.ts | Success | formatDuration, formatFileSize, formatDate helpers |
| 2024-12-29 | Created components/StatusBadge.tsx | Success | Phosphor Console styled (amber/green/red) |
| 2024-12-29 | Created components/ProgressOverlay.tsx | Success | Circular SVG progress with percentage |
| 2024-12-29 | Created components/VideoCard.tsx | Success | Full terminal aesthetic, CRT thumbnail effect |
| 2024-12-29 | Verified build | Success | dist: 154KB JS, 14KB CSS |

## 5. Comments

- `dir="auto"` enables automatic RTL detection for Arabic titles
- `line-clamp-2` truncates long titles with ellipsis
- Lazy loading (`loading="lazy"`) improves page performance
- Thumbnail error fallback prevents broken images
- Favorite button is always visible on hover
- Action overlay click area is the entire thumbnail
- Status badge uses semantic colors (yellow=pending, blue=downloading, red=failed)
- Next ticket (T015) adds the full action overlay with buttons

**TESTING LOG (2024-12-30):** ✅ Phase 4 Manual Testing Complete - 12/12 tests passed
- Thumbnail display with duration badge ✅
- Status indicators (pending/downloading/failed) via colored borders ✅
- Favorite button with toggle functionality ✅
- File size and error messages display ✅
- RTL text alignment support ✅
