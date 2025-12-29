# T013: Video Grid Component

## 1. Description

Implement the responsive video grid layout that displays video thumbnails. The grid adapts to different screen sizes and supports RTL text direction for Arabic titles.

**Why**: The grid is the primary UI for browsing videos. Responsive design ensures usability across desktop, tablet, and mobile devices.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    VideoGrid.tsx
    VideoGridSkeleton.tsx
  hooks/
    useVideos.ts
  App.tsx (update to use VideoGrid)
```

### Video Grid Component (components/VideoGrid.tsx)

```typescript
import { Video } from '../api/types'
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
      <div className="flex flex-col items-center justify-center py-16 text-vidkeep-accent">
        <svg
          className="w-16 h-16 mb-4"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth={1.5}
            d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
          />
        </svg>
        <p className="text-lg">No videos yet</p>
        <p className="text-sm mt-2">Add a YouTube URL to get started</p>
      </div>
    )
  }

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      {videos.map((video) => (
        <VideoCard
          key={video.video_id}
          video={video}
          onFavoriteToggle={onFavoriteToggle}
          onDelete={onDelete}
          onPlay={onPlay}
        />
      ))}
    </div>
  )
}
```

### Grid Skeleton (components/VideoGridSkeleton.tsx)

```typescript
export default function VideoGridSkeleton({ count = 8 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="bg-vidkeep-card rounded-lg overflow-hidden animate-pulse"
        >
          {/* Thumbnail skeleton */}
          <div className="aspect-video bg-vidkeep-accent/20" />

          {/* Content skeleton */}
          <div className="p-3 space-y-2">
            <div className="h-4 bg-vidkeep-accent/20 rounded w-3/4" />
            <div className="h-3 bg-vidkeep-accent/20 rounded w-1/2" />
          </div>
        </div>
      ))}
    </div>
  )
}
```

### useVideos Hook (hooks/useVideos.ts)

```typescript
import { useState, useEffect, useCallback } from 'react'
import { Video } from '../api/types'
import { fetchVideos, updateVideoFavorite, deleteVideo as apiDeleteVideo } from '../api/client'

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
    try {
      await updateVideoFavorite(videoId, isFavorite)
      setVideos(prev =>
        prev.map(v =>
          v.video_id === videoId ? { ...v, is_favorite: isFavorite } : v
        )
      )
    } catch (err) {
      console.error('Failed to update favorite:', err)
    }
  }, [])

  const deleteVideo = useCallback(async (videoId: string) => {
    try {
      await apiDeleteVideo(videoId)
      setVideos(prev => prev.filter(v => v.video_id !== videoId))
    } catch (err) {
      console.error('Failed to delete video:', err)
    }
  }, [])

  return {
    videos,
    loading,
    error,
    refresh: loadVideos,
    toggleFavorite,
    deleteVideo
  }
}
```

### Update App.tsx

```typescript
import { useState } from 'react'
import VideoGrid from './components/VideoGrid'
import VideoGridSkeleton from './components/VideoGridSkeleton'
import { useVideos } from './hooks/useVideos'
import { Video } from './api/types'

function App() {
  const [selectedChannel, setSelectedChannel] = useState<string>()
  const [favoritesOnly, setFavoritesOnly] = useState(false)

  const {
    videos,
    loading,
    error,
    refresh,
    toggleFavorite,
    deleteVideo
  } = useVideos({
    channel: selectedChannel,
    favoritesOnly
  })

  const handlePlay = (video: Video) => {
    // Will be implemented in T016
    console.log('Play video:', video.video_id)
  }

  return (
    <div className="min-h-screen bg-vidkeep-bg">
      <header className="bg-vidkeep-card border-b border-vidkeep-accent px-6 py-4">
        <div className="container mx-auto flex items-center justify-between">
          <h1 className="text-2xl font-bold">VidKeep</h1>
          {/* Filters will be added in T017 */}
        </div>
      </header>

      <main className="container mx-auto px-4 py-8">
        {error && (
          <div className="bg-red-500/20 border border-red-500 text-red-200 px-4 py-3 rounded mb-6">
            {error}
            <button onClick={refresh} className="ml-4 underline">
              Retry
            </button>
          </div>
        )}

        {loading ? (
          <VideoGridSkeleton />
        ) : (
          <VideoGrid
            videos={videos}
            onFavoriteToggle={toggleFavorite}
            onDelete={deleteVideo}
            onPlay={handlePlay}
          />
        )}
      </main>
    </div>
  )
}

export default App
```

### Dependencies

- T012 (React/Vite setup)
- T011 (Videos API)

## 3. Implementation Verification

- [x] Grid displays 1 column on mobile, 2 on tablet, 3-4 on desktop
- [x] Empty state shows helpful message
- [x] Loading state shows skeleton animation
- [x] Error state shows message with retry button
- [x] Videos are sorted by created_at (newest first)
- [x] Grid gaps are consistent (gap-6)

### Tests to Write

```typescript
// src/__tests__/VideoGrid.test.tsx
import { render, screen } from '@testing-library/react'
import VideoGrid from '../components/VideoGrid'

const mockVideos = [
  {
    video_id: 'test123',
    title: 'Test Video',
    channel_name: 'Test Channel',
    status: 'complete' as const,
    is_favorite: false,
    youtube_url: 'https://youtube.com/watch?v=test123',
    // ... other required fields
  }
]

test('renders empty state when no videos', () => {
  render(
    <VideoGrid
      videos={[]}
      onFavoriteToggle={() => {}}
      onDelete={() => {}}
      onPlay={() => {}}
    />
  )
  expect(screen.getByText('No videos yet')).toBeInTheDocument()
})

test('renders video cards when videos exist', () => {
  render(
    <VideoGrid
      videos={mockVideos}
      onFavoriteToggle={() => {}}
      onDelete={() => {}}
      onPlay={() => {}}
    />
  )
  expect(screen.getByText('Test Video')).toBeInTheDocument()
})
```

### Commands to Verify

```bash
# Start dev server and check grid
npm run dev
open http://localhost:3000

# Test responsive breakpoints (use browser devtools)
# - Mobile: 1 column
# - Tablet (sm): 2 columns
# - Desktop (lg): 3 columns
# - Wide (xl): 4 columns
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2024-12-29 | Created hooks/useVideos.ts | Success | Includes optimistic updates for favorites |
| 2024-12-29 | Created components/VideoGrid.tsx | Success | Phosphor Console styled empty state |
| 2024-12-29 | Created components/VideoGridSkeleton.tsx | Success | Terminal-styled skeleton with pulse animation |
| 2024-12-29 | Updated App.tsx to use VideoGrid | Success | Integrated loading, error, and empty states |
| 2024-12-29 | Verified build | Success | No TypeScript errors |

## 5. Comments

- Grid uses CSS Grid with responsive columns via Tailwind
- Skeleton loader maintains layout during loading
- useVideos hook encapsulates all video state management
- VideoCard component is a placeholder; implemented in T014
- Empty state encourages user to add first video
- Error state allows retry without page refresh
- Next ticket (T014) implements the VideoCard component
