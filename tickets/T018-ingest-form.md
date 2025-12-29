# T018: Ingest Form

## 1. Description

Implement the URL input form for submitting YouTube videos to the download queue. The form includes URL validation, loading states, and success/error feedback.

**Why**: This is the primary way users add videos to VidKeep. A good UX with clear feedback is essential.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    IngestForm.tsx
  App.tsx (add form to header)
```

### Ingest Form Component (components/IngestForm.tsx)

```typescript
import { useState, FormEvent } from 'react'
import { ingestVideo } from '../api/client'

interface IngestFormProps {
  onSuccess?: (videoId: string) => void
  onError?: (error: string) => void
}

export default function IngestForm({ onSuccess, onError }: IngestFormProps) {
  const [url, setUrl] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  const isValidYouTubeUrl = (url: string): boolean => {
    const patterns = [
      /youtube\.com\/watch\?v=/,
      /youtu\.be\//,
      /youtube\.com\/embed\//,
      /m\.youtube\.com\/watch\?v=/
    ]
    return patterns.some(pattern => pattern.test(url))
  }

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()

    if (!url.trim()) {
      setError('Please enter a YouTube URL')
      return
    }

    if (!isValidYouTubeUrl(url)) {
      setError('Please enter a valid YouTube URL')
      return
    }

    setLoading(true)
    setError(null)
    setSuccess(false)

    try {
      const result = await ingestVideo(url)
      setSuccess(true)
      setUrl('')
      onSuccess?.(result.video_id)

      // Clear success state after 3 seconds
      setTimeout(() => setSuccess(false), 3000)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to queue video'
      setError(message)
      onError?.(message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col sm:flex-row gap-2">
      <div className="relative flex-1">
        <input
          type="text"
          value={url}
          onChange={(e) => {
            setUrl(e.target.value)
            setError(null)
          }}
          placeholder="Paste YouTube URL..."
          disabled={loading}
          className={`
            w-full px-4 py-2 rounded-lg
            bg-vidkeep-bg border text-sm
            focus:outline-none focus:ring-2 focus:ring-vidkeep-primary
            disabled:opacity-50 disabled:cursor-not-allowed
            transition-colors
            ${error ? 'border-red-500' : success ? 'border-green-500' : 'border-vidkeep-accent'}
          `}
        />

        {/* Validation icons */}
        {(error || success) && (
          <div className="absolute inset-y-0 right-3 flex items-center pointer-events-none">
            {error ? (
              <svg className="w-5 h-5 text-red-500" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
            ) : (
              <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
              </svg>
            )}
          </div>
        )}
      </div>

      <button
        type="submit"
        disabled={loading || !url.trim()}
        className={`
          px-6 py-2 rounded-lg font-medium text-sm
          transition-all duration-200
          ${loading || !url.trim()
            ? 'bg-vidkeep-accent/50 text-vidkeep-accent cursor-not-allowed'
            : 'bg-vidkeep-primary hover:bg-vidkeep-primary/80 text-white'
          }
        `}
      >
        {loading ? (
          <span className="flex items-center gap-2">
            <svg className="w-4 h-4 animate-spin" fill="none" viewBox="0 0 24 24">
              <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
              <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
            </svg>
            Adding...
          </span>
        ) : (
          <span className="flex items-center gap-2">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
            </svg>
            Add Video
          </span>
        )}
      </button>

      {/* Error message */}
      {error && (
        <p className="text-red-400 text-xs sm:hidden mt-1">{error}</p>
      )}
    </form>
  )
}
```

### Compact Ingest Form (for header)

```typescript
// Alternative compact version for header integration
interface CompactIngestFormProps {
  onSuccess?: (videoId: string) => void
}

export function CompactIngestForm({ onSuccess }: CompactIngestFormProps) {
  const [isOpen, setIsOpen] = useState(false)
  // ... same logic as above, but with a button to toggle visibility

  if (!isOpen) {
    return (
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-2 px-4 py-2 rounded-lg
                   bg-vidkeep-primary hover:bg-vidkeep-primary/80
                   text-white text-sm font-medium transition-colors"
      >
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
        </svg>
        Add Video
      </button>
    )
  }

  return (
    <div className="flex items-center gap-2">
      {/* Full form */}
      <IngestForm onSuccess={(id) => { onSuccess?.(id); setIsOpen(false) }} />
      <button
        onClick={() => setIsOpen(false)}
        className="p-2 text-vidkeep-accent hover:text-white"
        aria-label="Cancel"
      >
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  )
}
```

### Integrate into Header

Update Header.tsx to include the form:

```typescript
import { CompactIngestForm } from './IngestForm'

// In the Header component, add to the filters section:
<div className="flex items-center gap-3">
  <CompactIngestForm onSuccess={(videoId) => {
    // Optionally refresh the video list
    console.log('Video added:', videoId)
  }} />

  <div className="h-6 w-px bg-vidkeep-accent/30" /> {/* Divider */}

  <ChannelFilter ... />
  <FavoritesToggle ... />
</div>
```

### Alternative: Full-width form below header

```typescript
// In App.tsx, add a dedicated section:
<header>
  {/* ... existing header content */}
</header>

{/* Ingest form section */}
<div className="bg-vidkeep-card/50 border-b border-vidkeep-accent/30 px-4 py-3">
  <div className="container mx-auto">
    <IngestForm onSuccess={() => refresh()} />
  </div>
</div>

<main>
  {/* ... video grid */}
</main>
```

### Dependencies

- T008 (Ingest API endpoint)
- T017 (Header component)

## 3. Implementation Verification

- [x] Form accepts YouTube URLs
- [x] Client-side validation for URL format
- [x] Loading state shown during submission
- [x] Success state with checkmark icon
- [x] Error state with message
- [x] Video list refreshes after successful add
- [x] Form clears after successful submission
- [x] Button disabled when input is empty
- [x] Form is responsive (stacks on mobile)

### Tests to Write

```typescript
// src/__tests__/IngestForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import IngestForm from '../components/IngestForm'
import { ingestVideo } from '../api/client'

jest.mock('../api/client')

test('validates YouTube URL format', async () => {
  render(<IngestForm />)

  const input = screen.getByPlaceholderText('Paste YouTube URL...')
  const button = screen.getByText('Add Video')

  fireEvent.change(input, { target: { value: 'not-a-url' } })
  fireEvent.click(button)

  expect(screen.getByText('Please enter a valid YouTube URL')).toBeInTheDocument()
})

test('submits valid URL and shows success', async () => {
  (ingestVideo as jest.Mock).mockResolvedValue({ video_id: 'abc123' })

  render(<IngestForm />)

  const input = screen.getByPlaceholderText('Paste YouTube URL...')
  const button = screen.getByText('Add Video')

  fireEvent.change(input, { target: { value: 'https://youtube.com/watch?v=abc123' } })
  fireEvent.click(button)

  await waitFor(() => {
    expect(input).toHaveValue('')
  })
})

test('shows error from API', async () => {
  (ingestVideo as jest.Mock).mockRejectedValue(new Error('Video already exists'))

  render(<IngestForm />)

  fireEvent.change(screen.getByPlaceholderText('Paste YouTube URL...'), {
    target: { value: 'https://youtube.com/watch?v=abc123' }
  })
  fireEvent.click(screen.getByText('Add Video'))

  await waitFor(() => {
    expect(screen.getByText('Video already exists')).toBeInTheDocument()
  })
})

test('shows loading state during submission', async () => {
  (ingestVideo as jest.Mock).mockImplementation(() => new Promise(() => {})) // Never resolves

  render(<IngestForm />)

  fireEvent.change(screen.getByPlaceholderText('Paste YouTube URL...'), {
    target: { value: 'https://youtube.com/watch?v=abc123' }
  })
  fireEvent.click(screen.getByText('Add Video'))

  expect(screen.getByText('Adding...')).toBeInTheDocument()
})
```

### Commands to Verify

```bash
# Test form functionality
npm run dev

# Try submitting:
# - Empty URL (should show error)
# - Invalid URL (should show error)
# - Valid YouTube URL (should submit and show success)
# - Duplicate video (should show API error)

# Check that new video appears in grid
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2024-12-29 | Created IngestForm.tsx | Success | Phosphor Console styled with validation |
| 2024-12-29 | Updated Header.tsx with Add Video button | Success | Desktop + compact mobile versions |
| 2024-12-29 | Updated App.tsx with ingest modal | Success | Modal reuse from T016, auto-refresh on success |
| 2024-12-29 | Verified build | Success | dist: 172KB JS, 20KB CSS |

## 5. Comments

- Implemented as modal (triggered from Header) instead of inline compact form
- Uses Phosphor Console terminal styling (uppercase, term-* colors, mono font)
- Client-side validation for YouTube URL patterns (youtube.com, youtu.be, shorts)
- Server errors displayed in uppercase with "ERROR:" prefix
- Success message: "VIDEO QUEUED FOR DOWNLOAD" with auto-close after 2s
- Form clears on success to prepare for next entry
- Loading state shows Loader2 spinner with "ADDING..." text
- Uses lucide-react icons: Plus, Loader2, AlertCircle, CheckCircle, X
- onSuccess callback refreshes both videos and channels lists
- Help text shows supported URL formats
- Modal reuses Modal.tsx component from T016
- Phase 4 (Frontend) is complete after this ticket
- Next ticket (T019) implements real-time WebSocket progress for downloads
