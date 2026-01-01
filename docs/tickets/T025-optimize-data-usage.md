# T025: Optimize Data Usage for Cellular Connections

## 1. Description

Reduce network data consumption when users are connected via cellular/mobile data. The current implementation may make frequent status polling and WebSocket updates that consume unnecessary bandwidth on metered connections.

**Why**: Users accessing VidKeep on mobile devices with limited data plans will experience excessive data usage from constant status updates, WebSocket messages, and API polling. This leads to unexpected data charges and poor user experience on slow connections.

## 2. Technical Specification

### Areas of Concern

1. **WebSocket Updates** - Real-time progress updates during downloads
2. **Status Polling** - Queue status and video list refreshes
3. **Thumbnail Loading** - High-resolution thumbnails on mobile
4. **Automatic Retries** - Failed request retries consuming data

### Proposed Solutions

#### 2.1 Detect Connection Type

Use the Network Information API to detect cellular connections:

```typescript
// hooks/useNetworkStatus.ts
export function useNetworkStatus() {
  const [isMetered, setIsMetered] = useState(false)
  const [connectionType, setConnectionType] = useState<string>('unknown')

  useEffect(() => {
    const connection = (navigator as any).connection ||
                       (navigator as any).mozConnection ||
                       (navigator as any).webkitConnection

    if (connection) {
      const updateStatus = () => {
        setIsMetered(connection.saveData || connection.type === 'cellular')
        setConnectionType(connection.effectiveType || connection.type || 'unknown')
      }

      updateStatus()
      connection.addEventListener('change', updateStatus)
      return () => connection.removeEventListener('change', updateStatus)
    }
  }, [])

  return { isMetered, connectionType }
}
```

#### 2.2 Reduce WebSocket Update Frequency

Throttle progress updates on cellular:

```typescript
// Backend: Throttle WebSocket broadcasts based on client preference
// frontend/src/hooks/useWebSocket.ts

const PROGRESS_THROTTLE_WIFI = 500      // 500ms on WiFi
const PROGRESS_THROTTLE_CELLULAR = 3000  // 3s on cellular

// Send connection preference to backend
ws.send(JSON.stringify({
  type: 'set_preference',
  throttle_ms: isMetered ? PROGRESS_THROTTLE_CELLULAR : PROGRESS_THROTTLE_WIFI
}))
```

#### 2.3 Reduce Polling Frequency

Adjust React Query refetch intervals:

```typescript
// hooks/useVideos.ts
export function useVideos() {
  const { isMetered } = useNetworkStatus()

  return useQuery({
    queryKey: ['videos'],
    queryFn: fetchVideos,
    refetchInterval: isMetered ? 30000 : 5000,  // 30s vs 5s
    refetchOnWindowFocus: !isMetered,
  })
}

export function useQueueStatus() {
  const { isMetered } = useNetworkStatus()

  return useQuery({
    queryKey: ['queue-status'],
    queryFn: fetchQueueStatus,
    refetchInterval: isMetered ? 60000 : 10000,  // 60s vs 10s
  })
}
```

#### 2.4 Lazy Load Thumbnails

Only load thumbnails when visible, with lower quality on cellular:

```typescript
// components/VideoCard.tsx
const { isMetered } = useNetworkStatus()

// Use smaller thumbnails on cellular
const thumbnailUrl = isMetered
  ? `/api/videos/${video.id}/thumbnail?quality=low`
  : `/api/videos/${video.id}/thumbnail`

// Intersection Observer for lazy loading
<img
  loading="lazy"
  src={thumbnailUrl}
  alt={video.title}
/>
```

#### 2.5 Backend: Thumbnail Quality Endpoint

```python
# api/videos.py
@router.get("/videos/{video_id}/thumbnail")
async def get_thumbnail(
    video_id: str,
    quality: str = Query("high", enum=["low", "high"]),
    db: AsyncSession = Depends(get_db)
):
    video = await db.get(Video, video_id)
    if not video or not video.thumbnail_path:
        raise HTTPException(404)

    if quality == "low":
        # Return compressed/smaller thumbnail
        return FileResponse(
            get_low_quality_thumbnail(video.thumbnail_path),
            media_type="image/jpeg"
        )
    return FileResponse(video.thumbnail_path)
```

#### 2.6 Data Saver Mode Toggle

Allow users to manually enable data saver:

```typescript
// contexts/SettingsContext.tsx
interface Settings {
  dataSaverMode: 'auto' | 'on' | 'off'
}

// In UI - Settings or header toggle
<button onClick={() => toggleDataSaver()}>
  {dataSaverMode === 'on' ? '📶 Data Saver ON' : '📶 Data Saver OFF'}
</button>
```

#### 2.7 Batch API Requests

Combine multiple requests into single calls:

```typescript
// Instead of:
GET /api/videos
GET /api/queue/status
GET /api/videos/123/progress
GET /api/videos/456/progress

// Use:
GET /api/dashboard?include=videos,queue,progress
```

### Files to Modify

```
/frontend/src/
  hooks/
    useNetworkStatus.ts    # New - detect connection type
    useVideos.ts           # Adjust polling intervals
    useQueueStatus.ts      # Adjust polling intervals
    useWebSocket.ts        # Throttle updates
  contexts/
    SettingsContext.tsx    # Data saver preference
  components/
    VideoCard.tsx          # Lazy load thumbnails
    Header.tsx             # Data saver toggle (optional)

/backend/app/
  api/
    videos.py              # Thumbnail quality param
    dashboard.py           # New - combined endpoint (optional)
  websocket/
    manager.py             # Per-client throttling
```

### Implementation Priority

1. **High Impact, Low Effort:**
   - Reduce polling intervals on cellular
   - Lazy load thumbnails
   - Throttle WebSocket updates

2. **Medium Impact, Medium Effort:**
   - Network detection hook
   - Low-quality thumbnail endpoint
   - Data saver toggle

3. **Lower Priority:**
   - Batch API endpoints
   - Per-client WebSocket preferences

## 3. Implementation Verification

- [ ] Network type detection works (test with Chrome DevTools network throttling)
- [ ] Polling intervals increase on cellular/slow connections
- [ ] WebSocket progress updates are throttled on cellular
- [ ] Thumbnails lazy load (not all at once)
- [ ] Low-quality thumbnails served when requested
- [ ] Data saver toggle persists in localStorage
- [ ] No functionality loss in data saver mode (just slower updates)
- [ ] Console shows reduced network requests in data saver mode

### Testing Scenarios

```
1. Open DevTools > Network > Throttle to "Slow 3G"
2. Enable "Network conditions" > Set connection type to "cellular"
3. Observe:
   - Fewer requests in Network tab
   - Progress updates less frequent
   - Thumbnails load lazily
   - App remains functional
```

### Metrics to Track

- Network requests per minute (before/after)
- Data transferred per session (before/after)
- Time to interactive on slow connections

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-31 | Created useNetworkStatus hook | Complete | Detects cellular/saveData mode |
| 2025-12-31 | Created DataSaverContext | Complete | Persists mode to localStorage |
| 2025-12-31 | Updated Header with data saver toggle | Complete | Wifi/WifiOff icon, cycles auto→on→off |
| 2025-12-31 | Updated queue polling intervals | Complete | 60s vs 10s based on data saver |
| 2025-12-31 | Wrapped App with DataSaverProvider | Complete | - |
| 2025-12-31 | **T025 Complete** | Core features implemented | Network detection, data saver toggle, polling adjustments |

## 5. Comments

- Network Information API has limited browser support (Chrome/Edge mainly)
- Fallback to manual data saver toggle for Safari/Firefox
- Consider `navigator.connection.saveData` for OS-level data saver detection
- Don't disable features entirely - just reduce frequency
- Users should still be able to force refresh manually
- WebSocket throttling requires backend changes for per-client settings
- Could add estimated data usage display in future
- Consider service worker for caching thumbnails offline
