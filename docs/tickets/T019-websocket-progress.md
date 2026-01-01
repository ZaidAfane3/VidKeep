# T019: WebSocket Progress Updates

## 1. Description

Implement real-time download progress updates via WebSocket connection. This replaces polling and provides instant progress feedback to users while videos download.

**Why**: Real-time progress creates a responsive UX. Users can see exactly how their downloads are progressing without manual refreshing.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  routers/
    websocket.py
  main.py (add WebSocket route)

/frontend/src/
  hooks/
    useWebSocket.ts
    useDownloadProgress.ts
  App.tsx (integrate progress updates)
```

### Backend WebSocket Endpoint (routers/websocket.py)

```python
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.redis import get_redis
import asyncio
import json

router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: dict):
        for connection in self.active_connections:
            try:
                await connection.send_json(message)
            except:
                pass

manager = ConnectionManager()

@router.websocket("/ws/progress")
async def websocket_progress(websocket: WebSocket):
    """
    WebSocket endpoint for real-time download progress.

    Subscribes to Redis pub/sub for progress updates and forwards to client.
    Also sends video status changes.
    """
    await manager.connect(websocket)
    redis = await get_redis()
    pubsub = redis.pubsub()

    try:
        # Subscribe to all progress channels
        await pubsub.psubscribe("progress:*")

        # Listen for messages
        while True:
            message = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)

            if message and message["type"] == "pmessage":
                # Extract video_id from channel name
                channel = message["channel"].decode()
                video_id = channel.split(":")[1]

                # Parse progress data
                data = json.loads(message["data"])

                # Send to WebSocket client
                await websocket.send_json({
                    "type": "progress",
                    "video_id": video_id,
                    "percent": data.get("percent", 0),
                    "downloaded_bytes": data.get("downloaded_bytes"),
                    "total_bytes": data.get("total_bytes")
                })

            # Check for WebSocket close
            try:
                data = await asyncio.wait_for(
                    websocket.receive_text(),
                    timeout=0.1
                )
                if data == "ping":
                    await websocket.send_text("pong")
            except asyncio.TimeoutError:
                pass

    except WebSocketDisconnect:
        manager.disconnect(websocket)
    finally:
        await pubsub.punsubscribe("progress:*")
```

### Update main.py

```python
from app.routers import websocket

app.include_router(websocket.router)
```

### Frontend WebSocket Hook (hooks/useWebSocket.ts)

```typescript
import { useEffect, useRef, useCallback, useState } from 'react'

interface WebSocketMessage {
  type: string
  video_id: string
  percent?: number
  downloaded_bytes?: number
  total_bytes?: number
}

interface UseWebSocketOptions {
  onMessage?: (message: WebSocketMessage) => void
  reconnectInterval?: number
}

export function useWebSocket(options: UseWebSocketOptions = {}) {
  const { onMessage, reconnectInterval = 5000 } = options
  const wsRef = useRef<WebSocket | null>(null)
  const [isConnected, setIsConnected] = useState(false)
  const reconnectTimeoutRef = useRef<NodeJS.Timeout>()

  const connect = useCallback(() => {
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const wsUrl = `${protocol}//${window.location.host}/ws/progress`

    const ws = new WebSocket(wsUrl)

    ws.onopen = () => {
      setIsConnected(true)
      // Start ping interval
      const pingInterval = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send('ping')
        }
      }, 30000)

      ws.onclose = () => clearInterval(pingInterval)
    }

    ws.onmessage = (event) => {
      if (event.data === 'pong') return

      try {
        const message = JSON.parse(event.data) as WebSocketMessage
        onMessage?.(message)
      } catch (e) {
        console.error('Failed to parse WebSocket message:', e)
      }
    }

    ws.onclose = () => {
      setIsConnected(false)
      // Attempt reconnect
      reconnectTimeoutRef.current = setTimeout(connect, reconnectInterval)
    }

    ws.onerror = (error) => {
      console.error('WebSocket error:', error)
      ws.close()
    }

    wsRef.current = ws
  }, [onMessage, reconnectInterval])

  useEffect(() => {
    connect()

    return () => {
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current)
      }
      wsRef.current?.close()
    }
  }, [connect])

  return { isConnected }
}
```

### Download Progress Hook (hooks/useDownloadProgress.ts)

```typescript
import { useState, useCallback } from 'react'
import { useWebSocket } from './useWebSocket'

interface ProgressState {
  [videoId: string]: {
    percent: number
    downloadedBytes?: number
    totalBytes?: number
  }
}

export function useDownloadProgress() {
  const [progress, setProgress] = useState<ProgressState>({})

  const handleMessage = useCallback((message: any) => {
    if (message.type === 'progress') {
      setProgress(prev => ({
        ...prev,
        [message.video_id]: {
          percent: message.percent,
          downloadedBytes: message.downloaded_bytes,
          totalBytes: message.total_bytes
        }
      }))
    }

    // Clear progress when download completes or fails
    if (message.type === 'status' && ['complete', 'failed'].includes(message.status)) {
      setProgress(prev => {
        const next = { ...prev }
        delete next[message.video_id]
        return next
      })
    }
  }, [])

  const { isConnected } = useWebSocket({ onMessage: handleMessage })

  const getProgress = useCallback((videoId: string): number | null => {
    return progress[videoId]?.percent ?? null
  }, [progress])

  return { progress, getProgress, isConnected }
}
```

### Integrate into App.tsx

```typescript
import { useDownloadProgress } from './hooks/useDownloadProgress'

function App() {
  const { progress, isConnected } = useDownloadProgress()

  // Merge progress into videos
  const videosWithProgress = useMemo(() => {
    return videos.map(video => ({
      ...video,
      download_progress: progress[video.video_id]?.percent ?? video.download_progress
    }))
  }, [videos, progress])

  return (
    <div>
      {/* Connection indicator (optional) */}
      {!isConnected && (
        <div className="fixed bottom-4 right-4 px-3 py-2 bg-yellow-500/20 text-yellow-200 rounded-lg text-sm">
          Reconnecting...
        </div>
      )}

      <VideoGrid videos={videosWithProgress} ... />
    </div>
  )
}
```

### Dependencies

- T006 (Redis pub/sub for progress)
- T014 (Progress overlay in VideoCard)
- T004 (Redis connection)

## 3. Implementation Verification

- [ ] WebSocket connects on page load
- [ ] Progress updates appear in real-time
- [ ] Multiple videos can show progress simultaneously
- [ ] Connection auto-reconnects on disconnect
- [ ] Ping/pong keeps connection alive
- [ ] Progress clears when download completes
- [ ] No memory leaks from progress state
- [ ] Works with multiple browser tabs

### Tests to Write

```typescript
// src/__tests__/useDownloadProgress.test.tsx
import { renderHook, act } from '@testing-library/react-hooks'
import { useDownloadProgress } from '../hooks/useDownloadProgress'

// Mock WebSocket
class MockWebSocket {
  onmessage: ((event: any) => void) | null = null
  onopen: (() => void) | null = null
  onclose: (() => void) | null = null
  close = jest.fn()
  send = jest.fn()
}

beforeAll(() => {
  (global as any).WebSocket = MockWebSocket
})

test('updates progress from WebSocket message', () => {
  const { result } = renderHook(() => useDownloadProgress())

  // Simulate WebSocket message
  act(() => {
    const ws = new MockWebSocket()
    ws.onopen?.()
    ws.onmessage?.({
      data: JSON.stringify({
        type: 'progress',
        video_id: 'test123',
        percent: 42
      })
    })
  })

  expect(result.current.getProgress('test123')).toBe(42)
})
```

### Commands to Verify

```bash
# Backend: Start with WebSocket support
docker-compose up api

# Test WebSocket connection
# Open browser devtools > Network > WS
# Should see /ws/progress connection

# Ingest a video and watch progress in real-time
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-30 | Created backend/app/routers/websocket.py | WebSocket endpoint with ConnectionManager, Redis pub/sub pattern subscription | None |
| 2025-12-30 | Registered WebSocket router in main.py | Added import and include_router | None |
| 2025-12-30 | Created useWebSocket.ts hook | Auto-connect, reconnect, ping/pong keepalive implemented | None |
| 2025-12-30 | Created useDownloadProgress.ts hook | Progress state management with clearProgress utility | None |
| 2025-12-30 | Integrated into App.tsx | Added videosWithProgress merge with useMemo, WS connection indicator in footer | TypeScript error TS6133 for unused wsConnected - fixed by adding footer indicator |
| 2025-12-30 | Build verification | Build passed (182.75 kB JS gzipped to 56.56 kB) | None |

## 5. Comments

- WebSocket is more efficient than polling for real-time updates
- Redis pub/sub distributes progress from workers to API
- Pattern subscription (`progress:*`) handles all video IDs
- Ping/pong keeps connection alive through proxies
- Reconnection logic handles network interruptions
- Progress state is local to component, not persisted
- Connection indicator is optional but helpful for debugging
- Next ticket (T020) implements the delete confirmation modal
