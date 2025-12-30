# T021: Queue Status Indicator

## 1. Description

Implement a header indicator showing the current download queue status including pending jobs and active downloads. This gives users visibility into background processing activity.

**Why**: Users need to know when downloads are queued and processing. The indicator provides at-a-glance status without requiring clicks.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    QueueStatus.tsx
  hooks/
    useQueueStatus.ts
  api/
    client.ts (add queue status fetch)
  components/
    Header.tsx (integrate QueueStatus)
```

### API Client Update (api/client.ts)

```typescript
export interface QueueStatusResponse {
  pending: number
  processing: number
  total: number
}

export async function fetchQueueStatus(): Promise<QueueStatusResponse> {
  const response = await fetch('/api/queue/status')
  if (!response.ok) throw new Error('Failed to fetch queue status')
  return response.json()
}
```

### useQueueStatus Hook (hooks/useQueueStatus.ts)

```typescript
import { useState, useEffect, useCallback } from 'react'
import { fetchQueueStatus, QueueStatusResponse } from '../api/client'

interface UseQueueStatusOptions {
  pollInterval?: number // ms
  enabled?: boolean
}

export function useQueueStatus(options: UseQueueStatusOptions = {}) {
  const { pollInterval = 5000, enabled = true } = options

  const [status, setStatus] = useState<QueueStatusResponse | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchStatus = useCallback(async () => {
    try {
      const data = await fetchQueueStatus()
      setStatus(data)
      setError(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch queue status')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    if (!enabled) return

    // Initial fetch
    fetchStatus()

    // Poll for updates
    const interval = setInterval(fetchStatus, pollInterval)

    return () => clearInterval(interval)
  }, [enabled, pollInterval, fetchStatus])

  return {
    pending: status?.pending ?? 0,
    processing: status?.processing ?? 0,
    total: status?.total ?? 0,
    loading,
    error,
    refresh: fetchStatus
  }
}
```

### Queue Status Component (components/QueueStatus.tsx)

```typescript
interface QueueStatusProps {
  pending: number
  processing: number
  loading?: boolean
}

export default function QueueStatus({ pending, processing, loading }: QueueStatusProps) {
  const total = pending + processing
  const isActive = total > 0

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-sm text-vidkeep-accent">
        <div className="w-4 h-4 border-2 border-vidkeep-accent/30 border-t-vidkeep-accent rounded-full animate-spin" />
      </div>
    )
  }

  if (!isActive) {
    return (
      <div className="flex items-center gap-2 text-sm text-vidkeep-accent">
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M5 13l4 4L19 7" />
        </svg>
        <span>Queue empty</span>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-3 text-sm">
      {/* Processing indicator */}
      {processing > 0 && (
        <div className="flex items-center gap-2 text-blue-400">
          <div className="relative">
            <div className="w-4 h-4 border-2 border-blue-400/30 border-t-blue-400 rounded-full animate-spin" />
          </div>
          <span>
            {processing} downloading
          </span>
        </div>
      )}

      {/* Pending indicator */}
      {pending > 0 && (
        <div className="flex items-center gap-2 text-yellow-400">
          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>
            {pending} queued
          </span>
        </div>
      )}

      {/* Total badge */}
      <span className="px-2 py-0.5 rounded-full bg-vidkeep-primary/20 text-vidkeep-primary text-xs font-medium">
        {total} total
      </span>
    </div>
  )
}
```

### Compact Version for Header

```typescript
export function QueueStatusCompact({ pending, processing, loading }: QueueStatusProps) {
  const total = pending + processing
  const isActive = total > 0

  if (loading || !isActive) return null

  return (
    <div className="flex items-center gap-2">
      {/* Animated indicator */}
      <div className="relative">
        <div className="w-2 h-2 bg-blue-500 rounded-full" />
        <div className="absolute inset-0 w-2 h-2 bg-blue-500 rounded-full animate-ping" />
      </div>

      {/* Count */}
      <span className="text-sm text-vidkeep-accent">
        {processing > 0 ? `${processing} downloading` : `${pending} queued`}
      </span>
    </div>
  )
}
```

### Integrate into Header

```typescript
import { QueueStatusCompact } from './QueueStatus'
import { useQueueStatus } from '../hooks/useQueueStatus'

export default function Header({ ... }) {
  const { pending, processing, loading } = useQueueStatus()

  return (
    <header>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <h1>VidKeep</h1>

          {/* Queue status */}
          <QueueStatusCompact
            pending={pending}
            processing={processing}
            loading={loading}
          />
        </div>

        {/* ... filters and ingest form */}
      </div>
    </header>
  )
}
```

### Optional: Expanded Queue View

Add a dropdown or modal showing detailed queue information:

```typescript
function QueueDetailsDropdown() {
  const { pending, processing, total, refresh } = useQueueStatus()
  const [isOpen, setIsOpen] = useState(false)

  return (
    <div className="relative">
      <button onClick={() => setIsOpen(!isOpen)}>
        <QueueStatusCompact pending={pending} processing={processing} />
      </button>

      {isOpen && (
        <div className="absolute top-full right-0 mt-2 w-64 bg-vidkeep-card rounded-lg shadow-lg p-4">
          <h3 className="font-medium mb-3">Download Queue</h3>

          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-vidkeep-accent">Downloading:</span>
              <span>{processing}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-vidkeep-accent">Queued:</span>
              <span>{pending}</span>
            </div>
            <div className="flex justify-between font-medium">
              <span>Total:</span>
              <span>{total}</span>
            </div>
          </div>

          <button
            onClick={refresh}
            className="mt-3 text-xs text-vidkeep-primary hover:underline"
          >
            Refresh
          </button>
        </div>
      )}
    </div>
  )
}
```

### Dependencies

- T011 (Queue status API endpoint)
- T017 (Header component)

## 3. Implementation Verification

- [ ] Queue status shows in header
- [ ] Displays current pending count
- [ ] Displays current processing count
- [ ] Updates automatically (polls every 5s)
- [ ] Shows "Queue empty" when no jobs
- [ ] Animated indicator when active
- [ ] Loading state during initial fetch

### Tests to Write

```typescript
// src/__tests__/QueueStatus.test.tsx
import { render, screen } from '@testing-library/react'
import QueueStatus from '../components/QueueStatus'

test('shows queue empty when no jobs', () => {
  render(<QueueStatus pending={0} processing={0} />)
  expect(screen.getByText('Queue empty')).toBeInTheDocument()
})

test('shows processing count', () => {
  render(<QueueStatus pending={0} processing={2} />)
  expect(screen.getByText('2 downloading')).toBeInTheDocument()
})

test('shows pending count', () => {
  render(<QueueStatus pending={5} processing={0} />)
  expect(screen.getByText('5 queued')).toBeInTheDocument()
})

test('shows both counts', () => {
  render(<QueueStatus pending={3} processing={2} />)
  expect(screen.getByText('2 downloading')).toBeInTheDocument()
  expect(screen.getByText('3 queued')).toBeInTheDocument()
  expect(screen.getByText('5 total')).toBeInTheDocument()
})

// src/__tests__/useQueueStatus.test.tsx
import { renderHook, waitFor } from '@testing-library/react'
import { useQueueStatus } from '../hooks/useQueueStatus'

jest.mock('../api/client', () => ({
  fetchQueueStatus: jest.fn().mockResolvedValue({
    pending: 2,
    processing: 1,
    total: 3
  })
}))

test('fetches queue status on mount', async () => {
  const { result } = renderHook(() => useQueueStatus())

  await waitFor(() => {
    expect(result.current.loading).toBe(false)
  })

  expect(result.current.pending).toBe(2)
  expect(result.current.processing).toBe(1)
  expect(result.current.total).toBe(3)
})
```

### Commands to Verify

```bash
npm run dev

# Queue some videos for download
# Check header shows:
# - Active download count
# - Pending queue count
# - Updates as jobs complete
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-30 | Created useQueueStatus.ts hook | Polling every 5s, returns pending/processing/total/loading/error/refresh | None |
| 2025-12-30 | Created QueueStatus.tsx | Both QueueStatusCompact (header) and QueueStatus (full) variants | None |
| 2025-12-30 | Integrated into Header.tsx | Added QueueStatusCompact next to logo, shows pulsing blue dot when active | None |
| 2025-12-30 | Mobile support | Added queue status to mobile header row | None |
| 2025-12-30 | Styled with Phosphor Console theme | term-* colors, lucide-react icons (Loader2, Clock, CheckCircle), uppercase text | None |
| 2025-12-30 | Build verification | Build passed | None |

## 5. Comments

- 5-second polling interval balances responsiveness with server load
- Compact version saves header space while still being informative
- Animation draws attention to active downloads
- Empty state reassures users no jobs are pending
- Could integrate with WebSocket (T019) for real-time updates instead of polling
- Detailed dropdown is optional enhancement for power users
- Next ticket (T022) implements error toasts and mobile polish
