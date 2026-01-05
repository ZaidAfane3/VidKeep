# BUG-003: Download Progress Resets at 100% and Delayed Status Color Update

## 1. Description

**Type:** Bug (Frontend/WebSocket)
**Severity:** Low (Cosmetic/UX)
**Status:** Done
**Affected Platforms:** All (Web)

Two related issues occur when a video download completes:

1. **Progress Reset Animation:** When download progress reaches 100%, the progress indicator briefly resets to 0% and quickly animates back to 100% before showing "Complete"
2. **Delayed Status Color:** The video card remains yellow (pending/downloading color) instead of immediately refreshing to green (complete) when the download finishes

## 2. Root Cause Analysis

### Issue 1: Progress Resetting from 100% to 0% and Animating Back

**Root Cause:** Race condition between WebSocket progress updates and video list state

**File:** `frontend/src/App.tsx` (Lines 59-65)

```tsx
const videosWithProgress = useMemo(() => {
  return videos.map(video => ({
    ...video,
    download_progress: downloadProgress[video.video_id]?.percent ?? video.download_progress
  }))
}, [videos, downloadProgress])
```

**Event Sequence:**

1. Backend sends WebSocket progress message with `percent: 100`
2. `useDownloadProgress` hook stores this in state
3. Progress displays at 100%
4. Video list is fetched (manual or scheduled refresh)
5. Fresh video list has `download_progress: 0` or `null` (reset by backend)
6. The merge logic falls back to `video.download_progress` when WebSocket data is stale
7. Progress briefly shows 0%, then animates back due to CSS transitions

**CSS Transition Trigger:** `frontend/src/components/ProgressOverlay.tsx` uses `transition-all duration-300` which creates the smooth animation effect when values change unexpectedly.

### Issue 2: Video Card Not Immediately Refreshing to Green

**Root Cause:** No automatic polling for video status updates after download completion

**Evidence:**

| Hook | Polling Interval | Purpose |
|------|------------------|---------|
| `useQueueStatus.ts` | 5 seconds | Queue status updates |
| `useWorkerCount.ts` | 30 seconds | Worker heartbeat count |
| `useVideos.ts` | **None** | Video list (manual only) |

The video card border color depends on `video.status` field:

**File:** `frontend/src/components/VideoCard.tsx` (Lines 37-41, 106)

```tsx
const isComplete = video.status === 'complete'
const isDownloading = video.status === 'downloading'
// ...

// Border color logic (Line 106):
// - Pending/Downloading: border-term-warning (yellow) or border-term-info (blue)
// - Complete: border-term-primary (green)
```

**The Gap:** Backend completes the download and updates DB status to `'complete'`, but the frontend still shows old status because:

1. WebSocket only sends `progress` type messages, not `status` type messages
2. `useDownloadProgress.ts` has code to handle `status` messages (Lines 27-34) but they're never sent:
   ```tsx
   // This would be sent by backend if we add status updates to WebSocket
   if (message.type === 'status' && message.status === 'complete') {
     clearProgress(message.video_id)
   }
   ```
3. No automatic video list refresh when downloads are active

### Data Flow Diagram

```
Backend (Download Complete)
    │
    ├─→ WebSocket: { type: 'progress', percent: 100 }
    │       ↓
    │   useDownloadProgress updates state
    │       ↓
    │   ProgressOverlay shows 100%
    │
    ├─→ Database: status = 'complete'
    │       ↓
    │   [NO NOTIFICATION TO FRONTEND]
    │       ↓
    │   Card still shows old status color
    │
    └─→ [MANUAL REFRESH REQUIRED]
            ↓
        useVideos fetches fresh list
            ↓
        Card updates to green
```

## 3. Expected Behavior

1. When download reaches 100%, progress should smoothly complete without resetting
2. Video card should immediately transition from yellow/blue to green when download completes
3. Progress overlay should hide and status should update without requiring manual refresh

## 4. Technical Solution

### Option A: Backend WebSocket Status Messages (Recommended)

Add status change notifications to the WebSocket broadcast:

**Backend Change:** When download completes, send:
```json
{ "type": "status", "video_id": "xxx", "status": "complete" }
```

**Frontend Change:** `useDownloadProgress.ts` already has handling code, just needs backend support.

### Option B: Frontend Auto-Polling When Downloads Active

**File:** `frontend/src/hooks/useVideos.ts`

```tsx
useEffect(() => {
  const hasActiveDownloads = videos.some(v => v.status === 'downloading')

  if (hasActiveDownloads) {
    const pollInterval = setInterval(() => {
      loadVideos()
    }, 3000) // Poll every 3 seconds while downloads are active

    return () => clearInterval(pollInterval)
  }
}, [videos])
```

### Option C: Clear Progress and Trigger Refresh at 100%

**File:** `frontend/src/hooks/useDownloadProgress.ts`

```tsx
if (message.type === 'progress') {
  setProgress(prev => ({
    ...prev,
    [message.video_id]: {
      percent: message.percent || 0,
      downloadedBytes: message.downloaded_bytes,
      totalBytes: message.total_bytes
    }
  }))

  // Auto-clear progress and trigger refresh when complete
  if (message.percent === 100) {
    setTimeout(() => {
      clearProgress(message.video_id)
      // Trigger video list refresh (would need callback prop)
    }, 1000)
  }
}
```

## 5. Verification Checklist

After fix:
- [ ] Progress smoothly reaches 100% without resetting
- [ ] Video card immediately turns green when download completes
- [ ] No manual refresh required to see completion status
- [ ] Multiple concurrent downloads still work correctly
- [ ] Progress overlay hides correctly after completion
- [ ] No memory leaks from polling/intervals

## 6. Related Files

- `frontend/src/hooks/useDownloadProgress.ts` - WebSocket progress handling
- `frontend/src/hooks/useWebSocket.ts` - WebSocket connection management
- `frontend/src/components/ProgressOverlay.tsx` - Visual progress display (CSS transitions)
- `frontend/src/components/VideoCard.tsx` - Status-based border color rendering
- `frontend/src/App.tsx` - Progress and video list merging logic (Lines 59-65)
- `frontend/src/hooks/useVideos.ts` - Video list fetching (no polling)
- `backend/app/services/download_service.py` - Backend download completion (WebSocket messages)

## 7. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-01-05 | Bug identified and documented | Ticket created | Root cause: Missing WebSocket status messages and no auto-polling |
| 2025-01-05 | Implemented Option A fix | Complete | Backend now sends `completion` messages; frontend clears progress and refreshes video list |
| 2025-01-05 | Fixed WebSocket router | Complete | Router was converting completion messages to progress messages with percent:0 |
| 2025-01-05 | Fixed header queue status | Complete | Lifted useQueueStatus to App.tsx so completion triggers queue refresh too |

## 8. Implementation Summary

**Approach:** Option A - Backend WebSocket Status Messages

### Backend Changes (`backend/app/tasks/download.py`)

Added completion message publishing at three locations:

1. **After successful download** (line ~144): Sends `{ "type": "completion", "status": "complete", "video_id": "..." }`
2. **After cancellation** (line ~168): Sends `{ "type": "completion", "status": "cancelled", "video_id": "..." }`
3. **After failure** (line ~188): Sends `{ "type": "completion", "status": "failed", "video_id": "..." }`

### Frontend Changes

**`frontend/src/hooks/useDownloadProgress.ts`:**
- Added `onVideoComplete` callback option
- Handles `type: "completion"` messages to clear progress state
- Triggers callback to refresh video list

**`frontend/src/App.tsx`:**
- Passes `refresh` function to `useDownloadProgress({ onVideoComplete: refresh })`
- Video list automatically refreshes when any download completes
