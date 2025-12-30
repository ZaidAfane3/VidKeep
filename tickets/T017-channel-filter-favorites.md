# T017: Channel Filter & Favorites Toggle

## 1. Description

Implement the channel filter dropdown and favorites toggle button in the header. These filters allow users to quickly find videos by channel or view only their favorite videos.

**Why**: As the library grows, users need efficient ways to filter and find specific content. Channel grouping and favorites are the primary organization methods.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    Header.tsx
    ChannelFilter.tsx
    FavoritesToggle.tsx
  hooks/
    useChannels.ts
  App.tsx (update to use Header)
```

### useChannels Hook (hooks/useChannels.ts)

```typescript
import { useState, useEffect } from 'react'
import { Channel } from '../api/types'
import { fetchChannels } from '../api/client'

export function useChannels() {
  const [channels, setChannels] = useState<Channel[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    async function load() {
      try {
        setLoading(true)
        const response = await fetchChannels()
        setChannels(response.channels)
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load channels')
      } finally {
        setLoading(false)
      }
    }
    load()
  }, [])

  return { channels, loading, error }
}
```

### Channel Filter Component (components/ChannelFilter.tsx)

```typescript
import { Channel } from '../api/types'

interface ChannelFilterProps {
  channels: Channel[]
  selectedChannel: string | undefined
  onSelect: (channel: string | undefined) => void
  loading?: boolean
}

export default function ChannelFilter({
  channels,
  selectedChannel,
  onSelect,
  loading = false
}: ChannelFilterProps) {
  return (
    <div className="relative">
      <select
        value={selectedChannel || ''}
        onChange={(e) => onSelect(e.target.value || undefined)}
        disabled={loading}
        className="
          appearance-none bg-vidkeep-bg border border-vidkeep-accent
          rounded-lg px-4 py-2 pr-10 text-sm
          focus:outline-none focus:ring-2 focus:ring-vidkeep-primary focus:border-transparent
          disabled:opacity-50 disabled:cursor-not-allowed
          cursor-pointer
        "
      >
        <option value="">All Channels</option>
        {channels.map((channel) => (
          <option key={channel.name} value={channel.name}>
            {channel.name} ({channel.video_count})
          </option>
        ))}
      </select>

      {/* Dropdown arrow */}
      <div className="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
        <svg className="w-4 h-4 text-vidkeep-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </div>
    </div>
  )
}
```

### Favorites Toggle Component (components/FavoritesToggle.tsx)

```typescript
interface FavoritesToggleProps {
  active: boolean
  onToggle: () => void
  count?: number
}

export default function FavoritesToggle({ active, onToggle, count }: FavoritesToggleProps) {
  return (
    <button
      onClick={onToggle}
      className={`
        flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium
        transition-colors
        ${active
          ? 'bg-red-500/20 text-red-400 border border-red-500/50'
          : 'bg-vidkeep-bg border border-vidkeep-accent text-vidkeep-accent hover:text-white hover:border-white'
        }
      `}
    >
      <svg
        className={`w-4 h-4 ${active ? 'fill-current' : ''}`}
        fill={active ? 'currentColor' : 'none'}
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
        />
      </svg>
      <span>Favorites</span>
      {count !== undefined && count > 0 && (
        <span className={`
          px-1.5 py-0.5 rounded text-xs
          ${active ? 'bg-red-500/30' : 'bg-vidkeep-accent/20'}
        `}>
          {count}
        </span>
      )}
    </button>
  )
}
```

### Header Component (components/Header.tsx)

```typescript
import ChannelFilter from './ChannelFilter'
import FavoritesToggle from './FavoritesToggle'
import { Channel } from '../api/types'

interface HeaderProps {
  channels: Channel[]
  channelsLoading: boolean
  selectedChannel: string | undefined
  onChannelSelect: (channel: string | undefined) => void
  favoritesOnly: boolean
  onFavoritesToggle: () => void
  favoritesCount?: number
}

export default function Header({
  channels,
  channelsLoading,
  selectedChannel,
  onChannelSelect,
  favoritesOnly,
  onFavoritesToggle,
  favoritesCount
}: HeaderProps) {
  return (
    <header className="bg-vidkeep-card border-b border-vidkeep-accent sticky top-0 z-40">
      <div className="container mx-auto px-4 py-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          {/* Logo */}
          <h1 className="text-2xl font-bold">
            <span className="text-vidkeep-primary">Vid</span>Keep
          </h1>

          {/* Filters */}
          <div className="flex items-center gap-3">
            <ChannelFilter
              channels={channels}
              selectedChannel={selectedChannel}
              onSelect={onChannelSelect}
              loading={channelsLoading}
            />

            <FavoritesToggle
              active={favoritesOnly}
              onToggle={onFavoritesToggle}
              count={favoritesCount}
            />

            {/* Clear filters */}
            {(selectedChannel || favoritesOnly) && (
              <button
                onClick={() => {
                  onChannelSelect(undefined)
                  if (favoritesOnly) onFavoritesToggle()
                }}
                className="text-xs text-vidkeep-accent hover:text-white underline"
              >
                Clear filters
              </button>
            )}
          </div>
        </div>
      </div>
    </header>
  )
}
```

### Updated App.tsx

```typescript
import { useState, useMemo } from 'react'
import Header from './components/Header'
import VideoGrid from './components/VideoGrid'
import { useVideos } from './hooks/useVideos'
import { useChannels } from './hooks/useChannels'
// ... other imports

function App() {
  const [selectedChannel, setSelectedChannel] = useState<string>()
  const [favoritesOnly, setFavoritesOnly] = useState(false)

  const { channels, loading: channelsLoading } = useChannels()
  const {
    videos,
    loading: videosLoading,
    error,
    refresh,
    toggleFavorite,
    deleteVideo
  } = useVideos({
    channel: selectedChannel,
    favoritesOnly
  })

  // Count favorites (from all videos, not just filtered)
  const favoritesCount = useMemo(() => {
    // This would ideally come from the API
    // For now, we can track it client-side when not filtered
    return videos.filter(v => v.is_favorite).length
  }, [videos])

  // ... playingVideo state and handlers

  return (
    <div className="min-h-screen bg-vidkeep-bg">
      <Header
        channels={channels}
        channelsLoading={channelsLoading}
        selectedChannel={selectedChannel}
        onChannelSelect={setSelectedChannel}
        favoritesOnly={favoritesOnly}
        onFavoritesToggle={() => setFavoritesOnly(!favoritesOnly)}
        favoritesCount={favoritesCount}
      />

      <main className="container mx-auto px-4 py-8">
        {/* Active filters display */}
        {(selectedChannel || favoritesOnly) && (
          <div className="mb-4 text-sm text-vidkeep-accent">
            Showing: {favoritesOnly ? 'Favorites' : 'All videos'}
            {selectedChannel && ` from "${selectedChannel}"`}
          </div>
        )}

        {/* ... error and video grid */}
      </main>

      {/* ... modals */}
    </div>
  )
}
```

### Dependencies

- T012 (React setup)
- T013 (Video grid)
- T011 (Channels API, Videos API with filters)

## 3. Implementation Verification

- [x] Channel dropdown shows all unique channels with counts
- [x] Selecting a channel filters the video grid
- [x] "All Channels" option clears the filter
- [x] Favorites toggle highlights when active
- [x] Favorites toggle filters to favorite videos only
- [x] Favorites count badge shows current count
- [x] Clear filters button resets both filters
- [x] Active filter state is displayed to user
- [x] Filters work in combination (channel + favorites)
- [x] Header is sticky on scroll

### Tests to Write

```typescript
// src/__tests__/ChannelFilter.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import ChannelFilter from '../components/ChannelFilter'

const mockChannels = [
  { name: 'Channel A', video_count: 5 },
  { name: 'Channel B', video_count: 3 }
]

test('renders all channels option', () => {
  render(
    <ChannelFilter
      channels={mockChannels}
      selectedChannel={undefined}
      onSelect={() => {}}
    />
  )

  expect(screen.getByText('All Channels')).toBeInTheDocument()
})

test('shows channel with count', () => {
  render(
    <ChannelFilter
      channels={mockChannels}
      selectedChannel={undefined}
      onSelect={() => {}}
    />
  )

  expect(screen.getByText('Channel A (5)')).toBeInTheDocument()
})

test('calls onSelect when channel changes', () => {
  const onSelect = jest.fn()

  render(
    <ChannelFilter
      channels={mockChannels}
      selectedChannel={undefined}
      onSelect={onSelect}
    />
  )

  fireEvent.change(screen.getByRole('combobox'), { target: { value: 'Channel A' } })
  expect(onSelect).toHaveBeenCalledWith('Channel A')
})

// src/__tests__/FavoritesToggle.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import FavoritesToggle from '../components/FavoritesToggle'

test('shows count badge when count > 0', () => {
  render(
    <FavoritesToggle active={false} onToggle={() => {}} count={5} />
  )

  expect(screen.getByText('5')).toBeInTheDocument()
})

test('toggles active state on click', () => {
  const onToggle = jest.fn()

  render(
    <FavoritesToggle active={false} onToggle={onToggle} />
  )

  fireEvent.click(screen.getByText('Favorites'))
  expect(onToggle).toHaveBeenCalled()
})
```

### Commands to Verify

```bash
# Test filtering
npm run dev

# Add some videos from different channels
# Check:
# - Channel dropdown populates
# - Selecting channel filters grid
# - Favorites toggle works
# - Combining filters works
# - Clear filters resets both
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2024-12-29 | Created useChannels.ts hook | Success | Fetches channels with loading/error states |
| 2024-12-29 | Created ChannelFilter.tsx | Success | Fixed property name (channel_name vs name) |
| 2024-12-29 | Created FavoritesToggle.tsx | Success | Heart icon with count badge |
| 2024-12-29 | Created Header.tsx | Success | Responsive header with mobile filter row |
| 2024-12-29 | Updated App.tsx | Success | Integrated filters with useVideos hook |
| 2024-12-29 | Verified build | Success | dist: 167KB JS, 19KB CSS |

## 5. Comments

- Implemented with Phosphor Console terminal styling (uppercase, term-* colors)
- Header is sticky for easy access to filters while scrolling
- Channel dropdown shows channel_name with video_count in uppercase
- Favorites toggle uses Heart icon from lucide-react with fill on active
- Clear filters button only appears when filters are active
- Active filter indicator bar shows current filter state below header
- Mobile layout: compact Plus button, filters in separate row below header
- Desktop layout: full "ADD VIDEO" button with divider before filters
- useChannels hook includes refresh() for updating after new video ingest
- useVideos hook refetches when channel or favoritesOnly filters change
- T018 adds the ingest form modal triggered from Header's Add Video button

**TESTING LOG (2024-12-30):** ✅ Phase 4 Manual Testing Complete - 17/17 tests passed
- Channel filter dropdown: Lists all channels with video counts ✅
- Favorites toggle: Shows count badge, filters correctly ✅
- Combined filters: Channel + Favorites work together ✅
- Filter indicator bar: Displays active filters and Clear button ✅
- Header responsiveness: Inline on desktop, stacked on mobile ✅
