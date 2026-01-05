# BUG-004: Video Card Status Not Updating from Queued to Downloading

## 1. Description

**Type:** Bug (Frontend/State Sync)
**Severity:** Medium (UX Issue)
**Status:** Open
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
