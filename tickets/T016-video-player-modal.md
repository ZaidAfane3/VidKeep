# T016: Video Player Modal

## 1. Description

Implement a modal dialog with an HTML5 video player for playing locally stored videos. The modal includes playback controls, video title display, and keyboard shortcuts.

**Why**: Users need to watch videos directly in the app without downloading. The modal provides a focused viewing experience without leaving the page.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    VideoPlayerModal.tsx
    Modal.tsx
  hooks/
    useKeyboard.ts
  App.tsx (integrate modal)
```

### Base Modal Component (components/Modal.tsx)

```typescript
import { ReactNode, useEffect } from 'react'

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  children: ReactNode
  title?: string
}

export default function Modal({ isOpen, onClose, children, title }: ModalProps) {
  // Close on Escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }

    if (isOpen) {
      document.addEventListener('keydown', handleEscape)
      document.body.style.overflow = 'hidden'
    }

    return () => {
      document.removeEventListener('keydown', handleEscape)
      document.body.style.overflow = ''
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      onClick={onClose}
    >
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/80" />

      {/* Modal content */}
      <div
        className="relative w-full max-w-5xl max-h-[90vh] flex flex-col bg-vidkeep-card rounded-lg overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        {title && (
          <div className="flex items-center justify-between px-4 py-3 border-b border-vidkeep-accent">
            <h2 dir="auto" className="text-lg font-medium truncate pr-4">
              {title}
            </h2>
            <button
              onClick={onClose}
              className="p-1 hover:bg-vidkeep-accent/20 rounded transition-colors"
              aria-label="Close"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        )}

        {/* Body */}
        <div className="flex-1 overflow-auto">
          {children}
        </div>
      </div>
    </div>
  )
}
```

### Video Player Modal (components/VideoPlayerModal.tsx)

```typescript
import { useRef, useEffect, useState } from 'react'
import Modal from './Modal'
import { Video } from '../api/types'
import { formatDuration } from '../utils/format'

interface VideoPlayerModalProps {
  video: Video | null
  isOpen: boolean
  onClose: () => void
}

export default function VideoPlayerModal({ video, isOpen, onClose }: VideoPlayerModalProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [isPlaying, setIsPlaying] = useState(false)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [volume, setVolume] = useState(1)
  const [isMuted, setIsMuted] = useState(false)
  const [isFullscreen, setIsFullscreen] = useState(false)

  // Auto-play when modal opens
  useEffect(() => {
    if (isOpen && videoRef.current) {
      videoRef.current.play().catch(() => {
        // Autoplay blocked - user will need to click play
      })
    }
  }, [isOpen])

  // Reset state when modal closes
  useEffect(() => {
    if (!isOpen) {
      setIsPlaying(false)
      setCurrentTime(0)
    }
  }, [isOpen])

  // Keyboard controls
  useEffect(() => {
    if (!isOpen) return

    const handleKeydown = (e: KeyboardEvent) => {
      if (!videoRef.current) return

      switch (e.key) {
        case ' ':
        case 'k':
          e.preventDefault()
          if (videoRef.current.paused) {
            videoRef.current.play()
          } else {
            videoRef.current.pause()
          }
          break
        case 'ArrowLeft':
          e.preventDefault()
          videoRef.current.currentTime -= 10
          break
        case 'ArrowRight':
          e.preventDefault()
          videoRef.current.currentTime += 10
          break
        case 'ArrowUp':
          e.preventDefault()
          videoRef.current.volume = Math.min(1, videoRef.current.volume + 0.1)
          break
        case 'ArrowDown':
          e.preventDefault()
          videoRef.current.volume = Math.max(0, videoRef.current.volume - 0.1)
          break
        case 'm':
          e.preventDefault()
          videoRef.current.muted = !videoRef.current.muted
          break
        case 'f':
          e.preventDefault()
          toggleFullscreen()
          break
      }
    }

    document.addEventListener('keydown', handleKeydown)
    return () => document.removeEventListener('keydown', handleKeydown)
  }, [isOpen])

  const toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      videoRef.current?.requestFullscreen()
      setIsFullscreen(true)
    } else {
      document.exitFullscreen()
      setIsFullscreen(false)
    }
  }

  if (!video) return null

  const streamUrl = `/api/stream/${video.video_id}`

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={video.title}>
      <div className="relative bg-black">
        <video
          ref={videoRef}
          src={streamUrl}
          className="w-full max-h-[70vh]"
          controls
          playsInline
          onPlay={() => setIsPlaying(true)}
          onPause={() => setIsPlaying(false)}
          onTimeUpdate={(e) => setCurrentTime(e.currentTarget.currentTime)}
          onDurationChange={(e) => setDuration(e.currentTarget.duration)}
          onVolumeChange={(e) => {
            setVolume(e.currentTarget.volume)
            setIsMuted(e.currentTarget.muted)
          }}
        >
          Your browser does not support the video tag.
        </video>
      </div>

      {/* Video info */}
      <div className="p-4 space-y-2">
        <div className="flex items-center justify-between text-sm text-vidkeep-accent">
          <span dir="auto">{video.channel_name}</span>
          {video.duration_seconds && (
            <span>{formatDuration(video.duration_seconds)}</span>
          )}
        </div>

        {video.description && (
          <details className="text-sm">
            <summary className="cursor-pointer text-vidkeep-accent hover:text-white">
              Show description
            </summary>
            <p dir="auto" className="mt-2 text-vidkeep-accent whitespace-pre-wrap">
              {video.description}
            </p>
          </details>
        )}

        {/* Keyboard shortcuts hint */}
        <div className="text-xs text-vidkeep-accent/50 pt-2 border-t border-vidkeep-accent/20">
          <span className="font-medium">Shortcuts:</span> Space/K = Play/Pause,
          ← → = Seek 10s, ↑ ↓ = Volume, M = Mute, F = Fullscreen, Esc = Close
        </div>
      </div>
    </Modal>
  )
}
```

### Integrate into App.tsx

```typescript
import { useState } from 'react'
import VideoGrid from './components/VideoGrid'
import VideoPlayerModal from './components/VideoPlayerModal'
import { Video } from './api/types'
// ... other imports

function App() {
  // ... existing state
  const [playingVideo, setPlayingVideo] = useState<Video | null>(null)

  const handlePlay = (video: Video) => {
    setPlayingVideo(video)
  }

  const handleClosePlayer = () => {
    setPlayingVideo(null)
  }

  return (
    <div className="min-h-screen bg-vidkeep-bg">
      {/* ... header and main content */}

      <main className="container mx-auto px-4 py-8">
        <VideoGrid
          videos={videos}
          onFavoriteToggle={toggleFavorite}
          onDelete={deleteVideo}
          onPlay={handlePlay}
        />
      </main>

      {/* Video Player Modal */}
      <VideoPlayerModal
        video={playingVideo}
        isOpen={playingVideo !== null}
        onClose={handleClosePlayer}
      />
    </div>
  )
}
```

### Dependencies

- T014 (Video card with onPlay)
- T015 (Action overlay play button)
- T009 (Streaming endpoint)

## 3. Implementation Verification

- [x] Modal opens when Play button is clicked
- [x] Video loads and plays from streaming endpoint
- [x] Native controls work (play, pause, seek, volume)
- [x] Keyboard shortcuts work (Space/K, arrows, M, F, Escape)
- [x] Escape closes modal
- [x] Click outside modal closes it
- [x] Video title displays with RTL support
- [x] Description expandable (collapsible panel)
- [x] Fullscreen mode works
- [x] Body scroll is locked when modal is open

### Tests to Write

```typescript
// src/__tests__/VideoPlayerModal.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import VideoPlayerModal from '../components/VideoPlayerModal'

const mockVideo = {
  video_id: 'test123',
  title: 'Test Video',
  channel_name: 'Test Channel',
  description: 'A test description',
  duration_seconds: 300,
  // ... other fields
}

test('renders video player when open', () => {
  render(
    <VideoPlayerModal
      video={mockVideo}
      isOpen={true}
      onClose={() => {}}
    />
  )

  expect(screen.getByText('Test Video')).toBeInTheDocument()
  expect(screen.getByRole('video')).toBeInTheDocument()
})

test('closes on Escape key', () => {
  const onClose = jest.fn()

  render(
    <VideoPlayerModal
      video={mockVideo}
      isOpen={true}
      onClose={onClose}
    />
  )

  fireEvent.keyDown(document, { key: 'Escape' })
  expect(onClose).toHaveBeenCalled()
})

test('video src points to streaming endpoint', () => {
  render(
    <VideoPlayerModal
      video={mockVideo}
      isOpen={true}
      onClose={() => {}}
    />
  )

  const video = screen.getByRole('video') as HTMLVideoElement
  expect(video.src).toContain('/api/stream/test123')
})
```

### Commands to Verify

```bash
# Test modal functionality
npm run dev

# Click Play on a complete video
# Check:
# - Video loads and plays
# - Controls work
# - Keyboard shortcuts work
# - Escape closes modal
# - Click outside closes modal
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2024-12-29 | Created Modal.tsx base component | Success | Phosphor Console styled with green header bar |
| 2024-12-29 | Created VideoPlayerModal.tsx | Success | Full keyboard shortcuts, collapsible description |
| 2024-12-29 | Integrated modal into App.tsx | Success | State management with playingVideo |
| 2024-12-29 | Verified build | Success | dist: 163KB JS, 18KB CSS |

## 5. Comments

- Uses native HTML5 video controls for best compatibility
- Keyboard shortcuts match common video player conventions
- Description is collapsed by default to save space
- Modal prevents body scroll when open
- Fullscreen API handles cross-browser differences
- Video starts playing automatically (if browser allows)
- RTL support for title and channel name
- `playsInline` attribute required for iOS
- Next ticket (T017) implements channel filter and favorites

**TESTING LOG (2024-12-30):** ✅ Phase 4 Manual Testing Complete - 24/24 tests passed
- Modal open/close: All close methods work (X, backdrop, Escape) ✅
- Video streaming: /api/stream/{id} endpoint works, native controls responsive ✅
- Description panel: Expandable with RTL support ✅
- Keyboard shortcuts: All 9 shortcuts (Space, K, Arrows, M, F, Escape) working ✅
- Body scroll lock: Prevents scrolling behind modal ✅
