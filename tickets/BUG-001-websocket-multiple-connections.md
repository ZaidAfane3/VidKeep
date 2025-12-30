# BUG-001: WebSocket Multiple Connections in Development

## 1. Description

**Type:** Bug (Development Environment)
**Severity:** Low
**Status:** Open

In development mode, multiple WebSocket connections are created when the app loads, causing:
1. One WebSocket shows "finished: WebSocket is closed before the connection is established"
2. Multiple WebSocket connections visible in Network tab (2-3 instead of 1)
3. All active connections receive the same progress updates

**Root Cause:** React StrictMode intentionally double-mounts components in development to detect side effects. This causes `useWebSocket` hook to create multiple connections.

## 2. Current Behavior

### Symptoms
- 3 WebSocket connections visible in browser Network > WS tab
- First connection fails with "WebSocket is closed before the connection is established"
- Subsequent connections succeed and work correctly
- Progress updates work but are duplicated across connections

### Why This Happens
1. React StrictMode (`main.tsx` line 7) double-mounts components in development
2. First mount: `useWebSocket()` creates WebSocket #1
3. StrictMode cleanup: WebSocket #1 is closed (before fully establishing)
4. Second mount: `useWebSocket()` creates WebSocket #2 (succeeds)
5. Vite HMR may create additional connections on hot reload

### Impact
- **Development:** Console noise, multiple WS connections in Network tab
- **Production:** No impact (StrictMode doesn't double-mount in production)

## 3. Expected Behavior

Only 1 WebSocket connection should be created, even with React StrictMode enabled.

## 4. Technical Solution

Implement a **Singleton WebSocket Manager** that reuses connections across React re-renders.

### Files to Modify
- `frontend/src/hooks/useWebSocket.ts`

### Implementation Approach
```typescript
// Module-level singleton (lives outside React lifecycle)
let wsInstance: WebSocket | null = null
let wsListeners: Set<(msg: WebSocketMessage) => void> = new Set()

function getOrCreateConnection(): WebSocket {
  if (wsInstance && wsInstance.readyState === WebSocket.OPEN) {
    return wsInstance
  }
  // Create new connection only if none exists
  wsInstance = new WebSocket(wsUrl)
  // ... setup handlers
  return wsInstance
}

export function useWebSocket(options) {
  useEffect(() => {
    // Subscribe listener to shared connection
    wsListeners.add(options.onMessage)
    getOrCreateConnection()

    return () => {
      // Unsubscribe but DON'T close connection
      wsListeners.delete(options.onMessage)
    }
  }, [])
}
```

### Key Changes
1. WebSocket instance lives outside React lifecycle (module-level)
2. Components subscribe/unsubscribe listeners without creating new connections
3. Connection persists across StrictMode remounts
4. Reconnection logic shared across all subscribers

## 5. Verification Checklist

After fix:
- [ ] Only 1 WebSocket visible in Network tab (dev and prod)
- [ ] No "closed before connection established" errors in console
- [ ] Progress updates work for multiple concurrent downloads
- [ ] Footer shows "LIVE" status correctly
- [ ] Reconnection works after backend restart
- [ ] Works correctly in production build

## 6. Notes

- This is a **development-only issue** - production is not affected
- The current implementation works correctly despite the extra connections
- Fix is optional but improves developer experience
- Do NOT remove React StrictMode as a workaround (it catches other bugs)

## 7. Related Files

- `frontend/src/hooks/useWebSocket.ts` - WebSocket hook
- `frontend/src/hooks/useDownloadProgress.ts` - Uses useWebSocket
- `frontend/src/App.tsx` - Uses useDownloadProgress
- `frontend/src/main.tsx` - React StrictMode wrapper

## 8. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-30 | Bug identified during Phase 5 testing | Multiple WS connections observed | Root cause: React StrictMode double-mounting |
