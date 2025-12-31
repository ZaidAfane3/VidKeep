# T023: Cancel Download with Cleanup

## 1. Description

Implement the ability to cancel an in-progress download and automatically clean up any partially downloaded files. Users should be able to stop a download at any point, with the system removing incomplete video/audio files and resetting the video status.

**Why**: Users may start downloading a video and then decide they no longer want it, or realize they selected the wrong video. Without cancellation, they must wait for the download to complete and then delete it, wasting bandwidth and storage. Clean cancellation improves user experience and resource management.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  api/
    videos.py          # Add cancel endpoint
  services/
    ytdlp.py           # Add cancellation support
  tasks/
    download.py        # Handle cancellation signal, cleanup logic
  models/
    video.py           # Add 'cancelled' status if needed

/frontend/src/
  api/
    client.ts          # Add cancelDownload function
  components/
    VideoCard.tsx      # Add cancel button for downloading videos
    ProgressOverlay.tsx # Add cancel button in progress UI
  hooks/
    useVideos.ts       # Add cancel mutation
```

### Backend: Cancel Endpoint (api/videos.py)

```python
from fastapi import APIRouter, HTTPException
from arq.connections import ArqRedis

router = APIRouter()

@router.post("/videos/{video_id}/cancel")
async def cancel_download(
    video_id: str,
    db: AsyncSession = Depends(get_db),
    redis: ArqRedis = Depends(get_redis)
):
    """
    Cancel an in-progress download and clean up partial files.
    """
    video = await db.get(Video, video_id)
    if not video:
        raise HTTPException(status_code=404, detail="Video not found")

    if video.status not in ['pending', 'downloading']:
        raise HTTPException(
            status_code=400,
            detail=f"Cannot cancel video with status '{video.status}'"
        )

    # Set cancellation flag in Redis for the worker to detect
    await redis.set(f"cancel:{video_id}", "1", ex=3600)

    # Update video status
    video.status = 'cancelled'
    video.error_message = 'Download cancelled by user'
    await db.commit()

    # Trigger cleanup task
    await redis.enqueue_job('cleanup_partial_download', video_id)

    return {"status": "cancelled", "video_id": video_id}
```

### Backend: Cleanup Task (tasks/download.py)

```python
import os
import glob
from pathlib import Path

async def cleanup_partial_download(ctx: dict, video_id: str):
    """
    Remove any partially downloaded files for a cancelled video.
    """
    db = ctx['db']
    video = await db.get(Video, video_id)

    if not video:
        return {"status": "error", "message": "Video not found"}

    media_dir = Path(settings.MEDIA_DIR) / video_id
    cleaned_files = []

    if media_dir.exists():
        # Remove partial video files (yt-dlp creates .part files)
        patterns = ['*.part', '*.ytdl', '*.temp', '*.mp4', '*.webm', '*.mkv', '*.m4a', '*.mp3']

        for pattern in patterns:
            for file_path in media_dir.glob(pattern):
                try:
                    file_path.unlink()
                    cleaned_files.append(str(file_path))
                except OSError as e:
                    logger.error(f"Failed to delete {file_path}: {e}")

        # Remove directory if empty
        try:
            if not any(media_dir.iterdir()):
                media_dir.rmdir()
        except OSError:
            pass  # Directory not empty or other error

    # Optionally reset video to allow re-download
    # video.status = 'failed'
    # video.error_message = 'Download was cancelled'
    # await db.commit()

    return {
        "status": "cleaned",
        "video_id": video_id,
        "files_removed": cleaned_files
    }


async def download_video(ctx: dict, video_id: str):
    """
    Modified download task with cancellation check.
    """
    redis = ctx['redis']
    db = ctx['db']

    # Check cancellation before starting
    if await redis.get(f"cancel:{video_id}"):
        await redis.delete(f"cancel:{video_id}")
        return {"status": "cancelled", "video_id": video_id}

    video = await db.get(Video, video_id)
    # ... existing download setup ...

    def progress_hook(d):
        # Check for cancellation during download
        # Note: This runs in sync context, need async bridge
        cancel_flag = sync_redis_check(f"cancel:{video_id}")
        if cancel_flag:
            raise DownloadCancelledException("Download cancelled by user")

        # ... existing progress reporting ...

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            ydl.download([video.url])
    except DownloadCancelledException:
        await cleanup_partial_download(ctx, video_id)
        return {"status": "cancelled", "video_id": video_id}
    except Exception as e:
        # ... existing error handling ...


class DownloadCancelledException(Exception):
    """Raised when a download is cancelled by user."""
    pass
```

### Backend: Kill Active yt-dlp Process

For immediate cancellation, we need to track and kill the yt-dlp subprocess:

```python
import subprocess
import signal

# Store active processes (in production, use Redis for multi-worker)
active_downloads: dict[str, subprocess.Popen] = {}

async def download_video(ctx: dict, video_id: str):
    # ... setup ...

    # Use subprocess instead of yt_dlp library for killable process
    cmd = [
        'yt-dlp',
        '--progress',
        '--newline',
        '-o', str(output_path),
        video.url
    ]

    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    active_downloads[video_id] = process

    try:
        # Monitor process and check for cancellation
        while process.poll() is None:
            # Check cancellation flag
            if await redis.get(f"cancel:{video_id}"):
                process.send_signal(signal.SIGTERM)
                process.wait(timeout=5)
                await cleanup_partial_download(ctx, video_id)
                return {"status": "cancelled"}

            # Read and parse progress from stdout
            line = process.stdout.readline()
            if line:
                await parse_and_broadcast_progress(video_id, line)

            await asyncio.sleep(0.1)
    finally:
        active_downloads.pop(video_id, None)
```

### Frontend: API Client (api/client.ts)

```typescript
export async function cancelDownload(videoId: string): Promise<{ status: string; video_id: string }> {
  const response = await fetch(`${API_BASE}/videos/${videoId}/cancel`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.detail || 'Failed to cancel download')
  }

  return response.json()
}
```

### Frontend: Cancel Button in VideoCard (components/VideoCard.tsx)

```typescript
import { X, StopCircle } from 'lucide-react'

interface VideoCardProps {
  video: Video
  onCancel?: (videoId: string) => void
  // ... other props
}

export default function VideoCard({ video, onCancel, ...props }: VideoCardProps) {
  const isDownloading = video.status === 'downloading' || video.status === 'pending'

  const handleCancel = async (e: React.MouseEvent) => {
    e.stopPropagation()  // Prevent card click
    if (onCancel) {
      onCancel(video.id)
    }
  }

  return (
    <div className="relative ...">
      {/* Existing card content */}

      {/* Cancel button for downloading videos */}
      {isDownloading && (
        <button
          onClick={handleCancel}
          className="absolute top-2 right-2 p-2 bg-red-500/80 hover:bg-red-500
                     rounded-full transition-colors z-10"
          title="Cancel download"
          aria-label="Cancel download"
        >
          <StopCircle className="w-5 h-5 text-white" />
        </button>
      )}

      {/* Show cancelled status */}
      {video.status === 'cancelled' && (
        <div className="absolute inset-0 bg-black/60 flex items-center justify-center">
          <span className="text-white font-medium">Cancelled</span>
        </div>
      )}
    </div>
  )
}
```

### Frontend: Progress Overlay Cancel (components/ProgressOverlay.tsx)

```typescript
interface ProgressOverlayProps {
  videoId: string
  progress: number
  status: string
  onCancel?: () => void
}

export default function ProgressOverlay({
  videoId,
  progress,
  status,
  onCancel
}: ProgressOverlayProps) {
  return (
    <div className="absolute inset-0 bg-black/70 flex flex-col items-center justify-center p-4">
      {/* Progress indicator */}
      <div className="w-full max-w-[80%] mb-4">
        <div className="h-2 bg-gray-700 rounded-full overflow-hidden">
          <div
            className="h-full bg-vidkeep-primary transition-all duration-300"
            style={{ width: `${progress}%` }}
          />
        </div>
        <p className="text-white text-sm mt-2 text-center">
          {status === 'pending' ? 'Queued...' : `${Math.round(progress)}%`}
        </p>
      </div>

      {/* Cancel button */}
      {onCancel && (
        <button
          onClick={onCancel}
          className="flex items-center gap-2 px-4 py-2 bg-red-500/80 hover:bg-red-500
                     text-white rounded-lg transition-colors"
        >
          <StopCircle className="w-4 h-4" />
          <span>Cancel</span>
        </button>
      )}
    </div>
  )
}
```

### Frontend: Hook Integration (hooks/useVideos.ts)

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { cancelDownload } from '../api/client'

export function useCancelDownload() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: cancelDownload,
    onSuccess: (data) => {
      // Invalidate video queries to refresh status
      queryClient.invalidateQueries({ queryKey: ['videos'] })

      // Optimistically update the specific video
      queryClient.setQueryData(['videos'], (old: Video[] | undefined) => {
        if (!old) return old
        return old.map(v =>
          v.id === data.video_id
            ? { ...v, status: 'cancelled' }
            : v
        )
      })
    },
    onError: (error) => {
      console.error('Failed to cancel download:', error)
    }
  })
}
```

### Video Status Enum Update (models/video.py)

```python
class VideoStatus(str, Enum):
    PENDING = "pending"
    DOWNLOADING = "downloading"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"  # New status
```

### Database Migration

```python
# alembic/versions/xxxx_add_cancelled_status.py

def upgrade():
    # If using PostgreSQL enum, need to add the value
    op.execute("ALTER TYPE videostatus ADD VALUE IF NOT EXISTS 'cancelled'")

def downgrade():
    # Note: Cannot easily remove enum values in PostgreSQL
    pass
```

## 3. Implementation Verification

- [ ] Cancel button appears on downloading/pending videos
- [ ] Clicking cancel immediately updates UI to show cancelled state
- [ ] Backend receives cancel request and sets Redis flag
- [ ] Active yt-dlp process is terminated
- [ ] Partial files (.part, .temp, incomplete video) are deleted
- [ ] Video status updates to 'cancelled' in database
- [ ] Cancelled videos can be re-queued for download
- [ ] Cancel works for queued (pending) videos before download starts
- [ ] Progress overlay shows cancel button
- [ ] Toast notification confirms cancellation
- [ ] No orphaned files remain after cancellation

### Edge Cases to Test

- Cancel immediately after clicking download
- Cancel at 50% progress
- Cancel at 99% progress
- Cancel multiple videos simultaneously
- Cancel when worker is processing other tasks
- Network disconnect during cancellation
- Rapid cancel/re-download cycles

### Commands to Verify

```bash
# Backend tests
pytest tests/test_cancel_download.py -v

# Manual testing
curl -X POST http://localhost:8000/api/videos/{video_id}/cancel

# Check for orphaned files
ls -la /app/media/{video_id}/

# Check Redis for cancel flags
redis-cli KEYS "cancel:*"
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-31 | Added 'cancelled' status to VideoStatus enum | Complete | - |
| 2025-12-31 | Created POST /api/videos/{id}/cancel endpoint | Complete | Sets Redis flag, updates status |
| 2025-12-31 | Updated download task with cancellation checks | Complete | Polling-based approach every 1 second |
| 2025-12-31 | Added cancelDownload to frontend API client | Complete | - |
| 2025-12-31 | Added cancel mutation to useVideos hook | Complete | Optimistic update with rollback |
| 2025-12-31 | Added cancel button to VideoCard and ProgressOverlay | Complete | StopCircle icon with red styling |
| 2025-12-31 | Wired cancel through VideoGrid → App with toast | Complete | Shows success/error toast |

## 5. Comments

- Two approaches for cancellation:
  1. **Polling-based**: Worker checks Redis flag periodically - simpler but slight delay
  2. **Process-based**: Kill yt-dlp subprocess directly - immediate but more complex
- Recommended: Start with subprocess approach for immediate cancellation
- Consider adding confirmation dialog before cancelling large downloads
- Cancelled videos should be deletable or re-downloadable
- Cleanup task runs async to not block the cancel response
- Rate limit cancel endpoint to prevent abuse
- The 'cancelled' status is distinct from 'failed' for analytics/UX purposes
- WebSocket should broadcast cancellation to update all connected clients
