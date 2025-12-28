# T015: Action Overlay (YouTube/Play/Download)

## 1. Description

Implement the hover/tap action overlay for video cards with three actions: open YouTube URL, play local video, and download file. The overlay provides quick access to primary video interactions.

**Why**: Users need easy access to view videos (YouTube or local) and download for offline use. The overlay presents these options without cluttering the card.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    VideoCard.tsx (update action overlay section)
    ActionButton.tsx
```

### Action Button Component (components/ActionButton.tsx)

```typescript
import { ReactNode } from 'react'

interface ActionButtonProps {
  onClick: (e: React.MouseEvent) => void
  icon: ReactNode
  label: string
  disabled?: boolean
}

export default function ActionButton({
  onClick,
  icon,
  label,
  disabled = false
}: ActionButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`
        flex flex-col items-center gap-1 p-3 rounded-lg
        transition-all duration-200
        ${disabled
          ? 'opacity-50 cursor-not-allowed'
          : 'hover:bg-white/20 active:scale-95'
        }
      `}
      title={label}
    >
      <div className="w-10 h-10 flex items-center justify-center rounded-full bg-white/20">
        {icon}
      </div>
      <span className="text-xs">{label}</span>
    </button>
  )
}
```

### Updated Video Card (components/VideoCard.tsx)

Replace the action overlay placeholder with:

```typescript
import ActionButton from './ActionButton'

// Inside VideoCard component, replace the action overlay div:

{/* Action overlay (on hover) */}
<div
  className={`
    absolute inset-0 bg-black/60
    opacity-0 group-hover:opacity-100
    transition-opacity flex items-center justify-center gap-2
    ${!isComplete && 'pointer-events-none'}
  `}
>
  {isComplete && (
    <>
      {/* YouTube button */}
      <ActionButton
        onClick={(e) => {
          e.stopPropagation()
          window.open(video.youtube_url, '_blank', 'noopener,noreferrer')
        }}
        icon={
          <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
            <path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/>
          </svg>
        }
        label="YouTube"
      />

      {/* Play button */}
      <ActionButton
        onClick={(e) => {
          e.stopPropagation()
          onPlay(video)
        }}
        icon={
          <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 24 24">
            <path d="M8 5v14l11-7z"/>
          </svg>
        }
        label="Play"
      />

      {/* Download button */}
      <ActionButton
        onClick={(e) => {
          e.stopPropagation()
          // Create download link
          const link = document.createElement('a')
          link.href = `/api/stream/${video.video_id}`
          link.download = `${video.title}.mp4`
          document.body.appendChild(link)
          link.click()
          document.body.removeChild(link)
        }}
        icon={
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                  d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"/>
          </svg>
        }
        label="Download"
      />
    </>
  )}

  {/* Show retry button for failed videos */}
  {isFailed && (
    <ActionButton
      onClick={(e) => {
        e.stopPropagation()
        // Re-ingest the video
        // This will be connected to the ingest function
        console.log('Retry download:', video.video_id)
      }}
      icon={
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
        </svg>
      }
      label="Retry"
    />
  )}

  {/* Show spinner for pending/downloading */}
  {(isPending || isDownloading) && (
    <div className="flex flex-col items-center gap-2">
      <div className="w-8 h-8 border-2 border-white/30 border-t-white rounded-full animate-spin" />
      <span className="text-xs">
        {isPending ? 'Queued...' : 'Downloading...'}
      </span>
    </div>
  )}
</div>
```

### Mobile Touch Support

Add touch-friendly interaction:

```typescript
// In VideoCard component
const [showOverlay, setShowOverlay] = useState(false)

// Update the card container
<div
  className="bg-vidkeep-card rounded-lg overflow-hidden group relative"
  onTouchStart={() => setShowOverlay(true)}
  onTouchEnd={() => setTimeout(() => setShowOverlay(false), 3000)}
>
  {/* ... */}

  {/* Update overlay classes */}
  <div
    className={`
      absolute inset-0 bg-black/60
      ${showOverlay ? 'opacity-100' : 'opacity-0 group-hover:opacity-100'}
      transition-opacity flex items-center justify-center gap-2
      ${!isComplete && 'pointer-events-none'}
    `}
  >
```

### Dependencies

- T014 (Thumbnail card)
- T009 (Streaming endpoint for download)

## 3. Implementation Verification

- [ ] Overlay appears on hover (desktop)
- [ ] Overlay appears on tap (mobile)
- [ ] YouTube button opens video in new tab
- [ ] Play button triggers onPlay callback
- [ ] Download button downloads MP4 file
- [ ] Buttons show tooltips on hover
- [ ] Overlay is hidden for pending/downloading (shows progress instead)
- [ ] Retry button appears for failed videos
- [ ] Click on overlay doesn't trigger card click

### Tests to Write

```typescript
// src/__tests__/ActionOverlay.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import VideoCard from '../components/VideoCard'

const mockVideo = {
  video_id: 'test123',
  title: 'Test Video',
  channel_name: 'Test Channel',
  status: 'complete' as const,
  is_favorite: false,
  duration_seconds: 125,
  youtube_url: 'https://youtube.com/watch?v=test123',
  // ... other fields
}

test('youtube button opens new tab', () => {
  const windowOpen = jest.spyOn(window, 'open').mockImplementation()

  render(
    <VideoCard
      video={mockVideo}
      onFavoriteToggle={() => {}}
      onDelete={() => {}}
      onPlay={() => {}}
    />
  )

  fireEvent.click(screen.getByTitle('YouTube'))
  expect(windowOpen).toHaveBeenCalledWith(
    mockVideo.youtube_url,
    '_blank',
    'noopener,noreferrer'
  )
})

test('play button triggers onPlay', () => {
  const onPlay = jest.fn()

  render(
    <VideoCard
      video={mockVideo}
      onFavoriteToggle={() => {}}
      onDelete={() => {}}
      onPlay={onPlay}
    />
  )

  fireEvent.click(screen.getByTitle('Play'))
  expect(onPlay).toHaveBeenCalledWith(mockVideo)
})

test('download button creates download link', () => {
  // Mock document methods
  const appendChildSpy = jest.spyOn(document.body, 'appendChild')
  const removeChildSpy = jest.spyOn(document.body, 'removeChild')

  render(
    <VideoCard
      video={mockVideo}
      onFavoriteToggle={() => {}}
      onDelete={() => {}}
      onPlay={() => {}}
    />
  )

  fireEvent.click(screen.getByTitle('Download'))
  expect(appendChildSpy).toHaveBeenCalled()
  expect(removeChildSpy).toHaveBeenCalled()
})
```

### Commands to Verify

```bash
# Visual testing
npm run dev

# Test on desktop:
# - Hover over card to see overlay
# - Click YouTube button (should open new tab)
# - Click Play button (check console log)
# - Click Download button (should download file)

# Test on mobile (devtools mobile view):
# - Tap card to show overlay
# - Overlay should hide after 3 seconds
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|

## 5. Comments

- `stopPropagation()` prevents clicks from bubbling to card
- `noopener,noreferrer` on YouTube link prevents security issues
- Download uses native `<a download>` attribute for best UX
- Mobile overlay auto-hides after 3 seconds for better touch UX
- Retry button for failed videos uses same ingest flow
- Pending/downloading videos show spinner instead of actions
- Action icons use inline SVGs for fast loading
- Next ticket (T016) implements the video player modal
