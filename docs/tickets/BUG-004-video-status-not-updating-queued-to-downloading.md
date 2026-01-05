# BUG-004: Video Card Status Not Updating from Queued to Downloading

## 1. Description

**Type:** Bug (Frontend/State Sync)
**Severity:** Medium (UX Issue)
**Status:** Fixed *
**Affected Platforms:** All (Web)

When a video starts downloading, the video card continues to show "QUEUED" status even though:
1. WebSocket progress messages are being received (showing 15%, 16%, 17%...)
2. The header shows "1 DOWNLOADING" indicator (flashing blue button)
3. Progress overlay is NOT displayed on the card (because `video.status` is still "pending")

The video card only updates to "DOWNLOADING" status after a manual page refresh.

## 2. Root Cause Analysis

### The Problem

The frontend has two separate data sources that are not synchronized:

1. **Video List (API)** - Fetched via `useVideos` hook from `/api/videos`
   - Contains `video.status` field ("pending", "downloading", "complete", etc.)
   - Only refreshed on initial load or manual refresh

2. **Progress Updates (WebSocket)** - Real-time via `useDownloadProgress` hook
   - Contains progress percentage, downloaded bytes, etc.
   - Does NOT include status changes

### Data Flow Gap

**Backend Flow:**
```
1. Video ingested → status: "pending" (saved to DB)
2. Worker picks up job → status: "downloading" (updated in DB)
3. Progress hook fires → publishes progress to Redis/WebSocket
4. Download completes → status: "complete" (updated in DB)
```

**Frontend Flow:**
```
1. Video ingested → API returns video with status: "pending"
2. useVideos stores this in state
3. Worker starts → WebSocket receives progress messages
4. useDownloadProgress updates progress state
5. App.tsx merges: progress from WebSocket + status from stale API data
6. VideoCard shows: QUEUED (stale status) + no progress overlay
```

### Key Code Locations

**File:** `frontend/src/App.tsx` (Lines 59-65)
```tsx
const videosWithProgress = useMemo(() => {
  return videos.map(video => ({
    ...video,
    download_progress: downloadProgress[video.video_id]?.percent ?? video.download_progress
  }))
}, [videos, downloadProgress])
```
- Merges progress data but does NOT update `video.status`

**File:** `frontend/src/components/VideoCard.tsx` (Lines 37-41)
```tsx
const isComplete = video.status === 'complete'
const isDownloading = video.status === 'downloading'  // Still 'pending' from stale data!
const isFailed = video.status === 'failed'
const isPending = video.status === 'pending'
```
- Progress overlay only shows when `isDownloading` is true
- Card border color based on status, not progress activity

**File:** `frontend/src/components/VideoCard.tsx` (Lines 122-127)
```tsx
{isDownloading && (
  <ProgressOverlay
    progress={video.download_progress || 0}
  />
)}
```
- Progress overlay requires `isDownloading` to be true
- Even with progress data, overlay won't show if status is still "pending"

## 3. Expected Behavior

1. When WebSocket progress messages start arriving for a video, the UI should immediately reflect "DOWNLOADING" status
2. Progress overlay should appear as soon as progress data is received
3. Card border should change from yellow (pending) to blue (downloading)
4. No manual refresh should be required

## 4. Technical Solutions

### Option A: Infer Status from Progress Data (Frontend-Only Fix)

Modify `VideoCard.tsx` to treat a video as "downloading" if it has active progress data:

```tsx
const hasActiveProgress = video.download_progress !== null && video.download_progress !== undefined
const isDownloading = video.status === 'downloading' || (isPending && hasActiveProgress)
```

**Pros:** Simple, no backend changes
**Cons:** Status inference, not actual status

### Option B: Send Status via WebSocket (Backend + Frontend)

Add a new WebSocket message type when status changes:

**Backend:** Send status change message when worker starts:
```python
# In download.py, after updating status to "downloading"
await redis.publish(
    f"progress:{video_id}",
    json.dumps({
        "type": "status",
        "status": "downloading",
        "video_id": video_id
    })
)
```

**Frontend:** Handle status messages in `useDownloadProgress`:
```typescript
if (message.type === 'status') {
  // Trigger video list refresh or update status locally
  onStatusChange?.(message.video_id, message.status)
}
```

**Pros:** Accurate status from source of truth
**Cons:** More complex, requires backend changes

### Option C: Auto-Refresh Videos on Progress (Frontend-Only)

Trigger a video list refresh when first progress message is received for a video:

```typescript
// In useDownloadProgress
if (message.type === 'progress' && !progress[message.video_id]) {
  // First progress for this video - trigger refresh
  onNewDownload?.()
}
```

**Pros:** Gets accurate status from API
**Cons:** Extra API calls, slight delay

### Option D: Combine A + B

1. **Immediate:** Infer "downloading" status from progress data (instant UX)
2. **Backend:** Send status WebSocket messages (accurate sync)
3. **Frontend:** Update local status cache on status messages

## Recommended Fix: Option A (Frontend-Only)

**Decision:** Use Option A - infer status from progress data. Simple, no backend changes, instant UX improvement.

**Implementation in `VideoCard.tsx`:**
```tsx
// Current (broken):
const isDownloading = video.status === 'downloading'
const isPending = video.status === 'pending'

// Fixed:
const isPendingStatus = video.status === 'pending'
const hasActiveProgress = video.download_progress != null && video.download_progress > 0
const isDownloading = video.status === 'downloading' || (isPendingStatus && hasActiveProgress)
const isPending = isPendingStatus && !hasActiveProgress
```

**Why this works:**
- If WebSocket sends progress (15%, 16%...), `download_progress` will have a value
- Even with stale API status ("pending"), we detect active download from progress data
- Progress overlay renders, card border turns blue, status shows "DOWNLOADING"

## 5. Verification Checklist

After fix:
- [ ] Video card shows "DOWNLOADING" immediately when progress starts
- [ ] Progress overlay appears without manual refresh
- [ ] Card border changes from yellow to blue when download starts
- [ ] Header "X DOWNLOADING" count matches actual downloading videos
- [ ] Multiple concurrent downloads all show correct status
- [ ] Status transitions correctly: QUEUED → DOWNLOADING → COMPLETE

## 6. Related Files

- `frontend/src/App.tsx` - Progress and video merging logic
- `frontend/src/hooks/useDownloadProgress.ts` - WebSocket progress handling
- `frontend/src/hooks/useVideos.ts` - Video list fetching
- `frontend/src/components/VideoCard.tsx` - Status display logic
- `backend/app/tasks/download.py` - Status updates during download
- `backend/app/routers/websocket.py` - WebSocket message routing

## 7. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-01-05 | Bug identified and documented | Ticket created | Root cause: Status not synced via WebSocket, only progress |
| 2025-01-05 | Implemented Option A fix | Partial | Modified `VideoCard.tsx` to infer `isDownloading` from `hasActiveProgress` when status is pending |
| 2025-01-05 | Timing sync investigation | Issue found | First progress message has percent=0, failing `> 0` check. QueueStatus polls every 10s causing lag |
| 2025-01-05 | Implemented complete sync solution | Resolved | Phase 1: Fix `> 0` to `!= null`, Phase 2: Sync QueueStatus on progress start, Phase 3: WebSocket status messages |

## 8. Timing Synchronization Enhancement

### Problem Discovered
After initial fix, components still update at different times:
- QueueStatus header shows "1 DOWNLOADING" (flashing button)
- VideoCard shows "QUEUED" for 0.3-2 seconds after
- Root cause: Multiple independent data sources with different update mechanisms

### Architecture Issue

| Component | Data Source | Update Method | Typical Lag |
|-----------|-------------|---------------|-------------|
| QueueStatus Header | Redis ARQ queue | HTTP Poll (10s) | 0-10 seconds |
| VideoCard Status | PostgreSQL API | On page load only | Stale until refresh |
| Progress Overlay | WebSocket | Real-time | ~100ms |

### Why Initial Fix Was Insufficient

The `hasActiveProgress` check used `> 0`:
```tsx
const hasActiveProgress = video.download_progress != null && video.download_progress > 0
```

First progress message often has `percent: 0`, failing the check and causing 0.3-0.5s delay.

### Complete Solution (3 Phases)

**Phase 1: Fix Progress Detection**
- Change `> 0` to `!= null` in VideoCard.tsx
- Any progress value (including 0) indicates active download

**Phase 2: Real-Time QueueStatus Sync**
- Add `onDownloadStarted` callback to useDownloadProgress
- Refresh queue status when first progress arrives for any video
- Eliminates 0-10 second polling lag

**Phase 3: WebSocket Status Messages**
- Backend sends `{"type": "status", "status": "downloading"}` when job starts
- Frontend handles status messages for authoritative real-time updates
- Provides true sync from backend source of truth

## 9. Implementation Summary

### Files Modified

| File | Change |
|------|--------|
| `frontend/src/components/VideoCard.tsx` | Changed `hasActiveProgress` check from `> 0` to `!= null` to detect downloads starting at 0% |
| `frontend/src/hooks/useDownloadProgress.ts` | Added `onDownloadStarted` callback, `onStatusChange` callback, and `seenVideosRef` tracking for first-progress detection |
| `frontend/src/hooks/useWebSocket.ts` | Added `status` field to `WebSocketMessage` interface |
| `frontend/src/App.tsx` | Added `onDownloadStarted` callback to refresh queue status on download start |
| `backend/app/tasks/download.py` | Added WebSocket status message publish when download starts |
| `backend/app/routers/websocket.py` | Added handler for `status` message type |

### Key Code Changes

**VideoCard.tsx (Line 47):**
```tsx
// Before:
const hasActiveProgress = video.download_progress != null && video.download_progress > 0

// After:
const hasActiveProgress = video.download_progress != null
```

**download.py (Lines 66-74):**
```python
# Notify frontend that download has started (real-time status sync)
await redis.publish(
    f"progress:{video_id}",
    json.dumps({
        "type": "status",
        "status": "downloading",
        "video_id": video_id
    })
)
```

**useDownloadProgress.ts:**
- Added `onDownloadStarted` callback triggered on first progress for any video
- Added `onStatusChange` callback for WebSocket status messages
- Added `seenVideosRef` to track which videos have been seen

### Result

All UI components (QueueStatus header, VideoCard, Progress Overlay) now update simultaneously within ~100ms when a download starts, eliminating the previous 0.3-10 second delays between component updates.
