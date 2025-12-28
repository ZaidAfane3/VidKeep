# T020: Delete Confirmation Modal

## 1. Description

Implement a confirmation modal for video deletion that warns users before removing videos and their associated files. The modal includes video details and a clear warning about permanent deletion.

**Why**: Deletion is irreversible and removes downloaded files. Users need explicit confirmation to prevent accidental data loss.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    DeleteConfirmModal.tsx
    VideoCard.tsx (add delete button)
  App.tsx (integrate delete modal)
```

### Delete Confirm Modal (components/DeleteConfirmModal.tsx)

```typescript
import Modal from './Modal'
import { Video } from '../api/types'
import { formatFileSize } from '../utils/format'
import { useState } from 'react'

interface DeleteConfirmModalProps {
  video: Video | null
  isOpen: boolean
  onClose: () => void
  onConfirm: (videoId: string) => Promise<void>
}

export default function DeleteConfirmModal({
  video,
  isOpen,
  onClose,
  onConfirm
}: DeleteConfirmModalProps) {
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleConfirm = async () => {
    if (!video) return

    setDeleting(true)
    setError(null)

    try {
      await onConfirm(video.video_id)
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete video')
    } finally {
      setDeleting(false)
    }
  }

  if (!video) return null

  return (
    <Modal isOpen={isOpen} onClose={onClose}>
      <div className="p-6 max-w-md mx-auto">
        {/* Warning icon */}
        <div className="flex justify-center mb-4">
          <div className="w-16 h-16 rounded-full bg-red-500/20 flex items-center justify-center">
            <svg className="w-8 h-8 text-red-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
        </div>

        {/* Title */}
        <h2 className="text-xl font-semibold text-center mb-2">
          Delete Video?
        </h2>

        {/* Description */}
        <p className="text-vidkeep-accent text-center mb-4">
          This action cannot be undone. The video and its thumbnail will be permanently deleted.
        </p>

        {/* Video details */}
        <div className="bg-vidkeep-bg rounded-lg p-3 mb-6">
          <div className="flex gap-3">
            {/* Thumbnail */}
            <img
              src={`/api/thumbnail/${video.video_id}`}
              alt=""
              className="w-20 h-14 object-cover rounded"
            />

            {/* Info */}
            <div className="flex-1 min-w-0">
              <p dir="auto" className="font-medium text-sm truncate">
                {video.title}
              </p>
              <p className="text-xs text-vidkeep-accent truncate">
                {video.channel_name}
              </p>
              {video.file_size_bytes && (
                <p className="text-xs text-vidkeep-accent mt-1">
                  {formatFileSize(video.file_size_bytes)}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Error message */}
        {error && (
          <div className="bg-red-500/20 border border-red-500 text-red-200 px-3 py-2 rounded text-sm mb-4">
            {error}
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-3">
          <button
            onClick={onClose}
            disabled={deleting}
            className="flex-1 px-4 py-2 rounded-lg border border-vidkeep-accent
                       text-vidkeep-accent hover:text-white hover:border-white
                       transition-colors disabled:opacity-50"
          >
            Cancel
          </button>

          <button
            onClick={handleConfirm}
            disabled={deleting}
            className="flex-1 px-4 py-2 rounded-lg bg-red-500 hover:bg-red-600
                       text-white transition-colors disabled:opacity-50
                       flex items-center justify-center gap-2"
          >
            {deleting ? (
              <>
                <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                </svg>
                Deleting...
              </>
            ) : (
              <>
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                        d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                Delete
              </>
            )}
          </button>
        </div>
      </div>
    </Modal>
  )
}
```

### Update VideoCard.tsx

Add a delete button to the action overlay or card menu:

```typescript
// In VideoCard component, add to the action overlay section:

{/* Delete button (top-right corner, only on hover) */}
<button
  onClick={(e) => {
    e.stopPropagation()
    onDelete(video.video_id)
  }}
  className="absolute top-2 left-2 p-1.5 rounded-full bg-black/50
             hover:bg-red-500/80 transition-colors opacity-0 group-hover:opacity-100"
  aria-label="Delete video"
>
  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
  </svg>
</button>
```

### Integrate into App.tsx

```typescript
import DeleteConfirmModal from './components/DeleteConfirmModal'
import { Video } from './api/types'

function App() {
  const [deletingVideo, setDeletingVideo] = useState<Video | null>(null)

  const handleDeleteClick = (videoId: string) => {
    const video = videos.find(v => v.video_id === videoId)
    if (video) {
      setDeletingVideo(video)
    }
  }

  const handleDeleteConfirm = async (videoId: string) => {
    await deleteVideo(videoId)
    setDeletingVideo(null)
  }

  return (
    <div>
      {/* ... existing content */}

      <VideoGrid
        videos={videos}
        onDelete={handleDeleteClick}
        // ... other props
      />

      {/* Delete confirmation modal */}
      <DeleteConfirmModal
        video={deletingVideo}
        isOpen={deletingVideo !== null}
        onClose={() => setDeletingVideo(null)}
        onConfirm={handleDeleteConfirm}
      />
    </div>
  )
}
```

### Dependencies

- T016 (Modal component)
- T011 (Delete API endpoint)
- T014 (VideoCard component)

## 3. Implementation Verification

- [ ] Delete button appears on card hover
- [ ] Clicking delete opens confirmation modal
- [ ] Modal shows video thumbnail and title
- [ ] Modal shows file size to be freed
- [ ] Cancel closes modal without action
- [ ] Confirm deletes video and closes modal
- [ ] Error state shows if delete fails
- [ ] Loading state during deletion
- [ ] Video is removed from grid after delete

### Tests to Write

```typescript
// src/__tests__/DeleteConfirmModal.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import DeleteConfirmModal from '../components/DeleteConfirmModal'

const mockVideo = {
  video_id: 'test123',
  title: 'Test Video',
  channel_name: 'Test Channel',
  file_size_bytes: 104857600, // 100MB
  // ... other fields
}

test('shows video details', () => {
  render(
    <DeleteConfirmModal
      video={mockVideo}
      isOpen={true}
      onClose={() => {}}
      onConfirm={async () => {}}
    />
  )

  expect(screen.getByText('Test Video')).toBeInTheDocument()
  expect(screen.getByText('Test Channel')).toBeInTheDocument()
  expect(screen.getByText('100.0 MB')).toBeInTheDocument()
})

test('calls onClose when Cancel clicked', () => {
  const onClose = jest.fn()

  render(
    <DeleteConfirmModal
      video={mockVideo}
      isOpen={true}
      onClose={onClose}
      onConfirm={async () => {}}
    />
  )

  fireEvent.click(screen.getByText('Cancel'))
  expect(onClose).toHaveBeenCalled()
})

test('calls onConfirm and closes on Delete', async () => {
  const onConfirm = jest.fn().mockResolvedValue(undefined)
  const onClose = jest.fn()

  render(
    <DeleteConfirmModal
      video={mockVideo}
      isOpen={true}
      onClose={onClose}
      onConfirm={onConfirm}
    />
  )

  fireEvent.click(screen.getByText('Delete'))

  await waitFor(() => {
    expect(onConfirm).toHaveBeenCalledWith('test123')
    expect(onClose).toHaveBeenCalled()
  })
})

test('shows error on delete failure', async () => {
  const onConfirm = jest.fn().mockRejectedValue(new Error('Server error'))

  render(
    <DeleteConfirmModal
      video={mockVideo}
      isOpen={true}
      onClose={() => {}}
      onConfirm={onConfirm}
    />
  )

  fireEvent.click(screen.getByText('Delete'))

  await waitFor(() => {
    expect(screen.getByText('Server error')).toBeInTheDocument()
  })
})
```

### Commands to Verify

```bash
npm run dev

# Test:
# - Hover over a video card
# - Click delete icon
# - Verify modal shows correct video info
# - Click Cancel (modal closes, video remains)
# - Click Delete (video is removed)
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|

## 5. Comments

- Warning icon and red color reinforce the destructive action
- Thumbnail helps user confirm they're deleting the right video
- File size shows how much space will be freed
- Two-step confirmation prevents accidental deletions
- Loading state prevents double-click issues
- Error handling allows retry without closing modal
- Delete removes both database record and files (handled by API)
- Next ticket (T021) implements queue status indicator
