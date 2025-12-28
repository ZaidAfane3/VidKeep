# T022: Error Toasts & Mobile Polish

## 1. Description

Implement a toast notification system for success/error feedback and apply final mobile-responsive polish to ensure the app works well on all screen sizes.

**Why**: Users need clear feedback for actions, and mobile users need touch-friendly interfaces. This ticket completes the UI polish phase.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/src/
  components/
    Toast.tsx
    ToastContainer.tsx
  contexts/
    ToastContext.tsx
  hooks/
    useToast.ts
  index.css (mobile polish)
  App.tsx (integrate toasts)
```

### Toast Component (components/Toast.tsx)

```typescript
import { useEffect } from 'react'

export type ToastType = 'success' | 'error' | 'info' | 'warning'

export interface ToastData {
  id: string
  type: ToastType
  title: string
  message?: string
  duration?: number
}

interface ToastProps {
  toast: ToastData
  onDismiss: (id: string) => void
}

const icons: Record<ToastType, JSX.Element> = {
  success: (
    <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
    </svg>
  ),
  error: (
    <svg className="w-5 h-5 text-red-500" fill="currentColor" viewBox="0 0 20 20">
      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
    </svg>
  ),
  warning: (
    <svg className="w-5 h-5 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
      <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
    </svg>
  ),
  info: (
    <svg className="w-5 h-5 text-blue-500" fill="currentColor" viewBox="0 0 20 20">
      <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
    </svg>
  )
}

const backgrounds: Record<ToastType, string> = {
  success: 'bg-green-500/10 border-green-500/50',
  error: 'bg-red-500/10 border-red-500/50',
  warning: 'bg-yellow-500/10 border-yellow-500/50',
  info: 'bg-blue-500/10 border-blue-500/50'
}

export default function Toast({ toast, onDismiss }: ToastProps) {
  useEffect(() => {
    if (toast.duration !== 0) {
      const timer = setTimeout(() => {
        onDismiss(toast.id)
      }, toast.duration || 5000)

      return () => clearTimeout(timer)
    }
  }, [toast, onDismiss])

  return (
    <div
      className={`
        flex items-start gap-3 px-4 py-3 rounded-lg border shadow-lg
        ${backgrounds[toast.type]}
        animate-slide-in
      `}
      role="alert"
    >
      <div className="flex-shrink-0 mt-0.5">
        {icons[toast.type]}
      </div>

      <div className="flex-1 min-w-0">
        <p className="font-medium text-sm">{toast.title}</p>
        {toast.message && (
          <p className="text-sm text-vidkeep-accent mt-1">{toast.message}</p>
        )}
      </div>

      <button
        onClick={() => onDismiss(toast.id)}
        className="flex-shrink-0 p-1 hover:bg-white/10 rounded transition-colors"
        aria-label="Dismiss"
      >
        <svg className="w-4 h-4 text-vidkeep-accent" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>
  )
}
```

### Toast Container (components/ToastContainer.tsx)

```typescript
import Toast, { ToastData } from './Toast'

interface ToastContainerProps {
  toasts: ToastData[]
  onDismiss: (id: string) => void
}

export default function ToastContainer({ toasts, onDismiss }: ToastContainerProps) {
  return (
    <div
      className="fixed bottom-4 right-4 z-50 flex flex-col gap-2 w-full max-w-sm px-4 sm:px-0"
      aria-live="polite"
    >
      {toasts.map(toast => (
        <Toast key={toast.id} toast={toast} onDismiss={onDismiss} />
      ))}
    </div>
  )
}
```

### Toast Context (contexts/ToastContext.tsx)

```typescript
import { createContext, useContext, useState, useCallback, ReactNode } from 'react'
import { ToastData, ToastType } from '../components/Toast'

interface ToastContextValue {
  toasts: ToastData[]
  addToast: (type: ToastType, title: string, message?: string, duration?: number) => void
  removeToast: (id: string) => void
  success: (title: string, message?: string) => void
  error: (title: string, message?: string) => void
  info: (title: string, message?: string) => void
  warning: (title: string, message?: string) => void
}

const ToastContext = createContext<ToastContextValue | null>(null)

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<ToastData[]>([])

  const addToast = useCallback((
    type: ToastType,
    title: string,
    message?: string,
    duration?: number
  ) => {
    const id = Date.now().toString()
    setToasts(prev => [...prev, { id, type, title, message, duration }])
  }, [])

  const removeToast = useCallback((id: string) => {
    setToasts(prev => prev.filter(t => t.id !== id))
  }, [])

  const success = useCallback((title: string, message?: string) => {
    addToast('success', title, message)
  }, [addToast])

  const error = useCallback((title: string, message?: string) => {
    addToast('error', title, message, 8000) // Longer duration for errors
  }, [addToast])

  const info = useCallback((title: string, message?: string) => {
    addToast('info', title, message)
  }, [addToast])

  const warning = useCallback((title: string, message?: string) => {
    addToast('warning', title, message)
  }, [addToast])

  return (
    <ToastContext.Provider value={{
      toasts,
      addToast,
      removeToast,
      success,
      error,
      info,
      warning
    }}>
      {children}
    </ToastContext.Provider>
  )
}

export function useToast() {
  const context = useContext(ToastContext)
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider')
  }
  return context
}
```

### Integrate Toasts into App.tsx

```typescript
import { ToastProvider, useToast } from './contexts/ToastContext'
import ToastContainer from './components/ToastContainer'

function AppContent() {
  const { toasts, removeToast, success, error } = useToast()

  // Use toast for feedback
  const handleIngestSuccess = (videoId: string) => {
    success('Video queued', 'Download will start shortly')
  }

  const handleDeleteSuccess = () => {
    success('Video deleted', 'Video and files removed')
  }

  const handleError = (message: string) => {
    error('Error', message)
  }

  return (
    <>
      {/* ... existing app content */}
      <ToastContainer toasts={toasts} onDismiss={removeToast} />
    </>
  )
}

export default function App() {
  return (
    <ToastProvider>
      <AppContent />
    </ToastProvider>
  )
}
```

### Mobile Polish CSS (add to index.css)

```css
/* Mobile-specific styles */
@layer utilities {
  /* Toast animation */
  @keyframes slide-in {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  .animate-slide-in {
    animation: slide-in 0.3s ease-out;
  }
}

/* Touch-friendly targets */
@media (max-width: 640px) {
  /* Larger touch targets */
  button, a {
    @apply min-h-[44px] min-w-[44px];
  }

  /* Full-width buttons on mobile */
  .btn-mobile-full {
    @apply w-full;
  }

  /* Bottom navigation safe area */
  .pb-safe {
    padding-bottom: env(safe-area-inset-bottom, 20px);
  }
}

/* Prevent content shift with fixed header */
main {
  padding-top: 0;
}

/* Smooth scrolling */
html {
  scroll-behavior: smooth;
}

/* Hide scrollbar but allow scrolling */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

/* Better tap highlight on mobile */
button, a {
  -webkit-tap-highlight-color: transparent;
}

/* Prevent text selection on interactive elements */
button, [role="button"] {
  user-select: none;
}

/* Full-height on mobile browsers */
.min-h-screen-mobile {
  min-height: 100vh;
  min-height: 100dvh;
}
```

### Mobile Navigation Improvements

Update Header for better mobile layout:

```typescript
// In Header.tsx, improve mobile responsiveness:

<header className="bg-vidkeep-card border-b border-vidkeep-accent sticky top-0 z-40">
  <div className="container mx-auto px-4 py-3">
    {/* First row: Logo and queue status */}
    <div className="flex items-center justify-between mb-3 sm:mb-0">
      <h1 className="text-xl sm:text-2xl font-bold">
        <span className="text-vidkeep-primary">Vid</span>Keep
      </h1>
      <QueueStatusCompact {...} />
    </div>

    {/* Second row on mobile: Filters */}
    <div className="flex flex-col sm:flex-row sm:items-center gap-3 sm:gap-4">
      {/* Ingest form - full width on mobile */}
      <div className="order-1 sm:order-none">
        <IngestForm onSuccess={...} />
      </div>

      {/* Filters - horizontal scroll on mobile */}
      <div className="flex items-center gap-2 overflow-x-auto scrollbar-hide pb-2 sm:pb-0">
        <ChannelFilter {...} />
        <FavoritesToggle {...} />
      </div>
    </div>
  </div>
</header>
```

### Dependencies

- T012 (React setup)
- All previous frontend tickets

## 3. Implementation Verification

- [ ] Toast notifications appear for success/error actions
- [ ] Toasts auto-dismiss after timeout
- [ ] Toasts can be manually dismissed
- [ ] Multiple toasts stack properly
- [ ] Touch targets are 44px minimum
- [ ] Filters scroll horizontally on mobile
- [ ] Header stacks properly on mobile
- [ ] Safe areas respected on iOS
- [ ] No horizontal overflow on mobile
- [ ] Smooth animations on all interactions

### Tests to Write

```typescript
// src/__tests__/Toast.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { ToastProvider, useToast } from '../contexts/ToastContext'

function TestComponent() {
  const { success, error, toasts } = useToast()

  return (
    <div>
      <button onClick={() => success('Success!', 'It worked')}>
        Show Success
      </button>
      <button onClick={() => error('Error!', 'Something went wrong')}>
        Show Error
      </button>
      <div data-testid="toast-count">{toasts.length}</div>
    </div>
  )
}

test('shows success toast', () => {
  render(
    <ToastProvider>
      <TestComponent />
    </ToastProvider>
  )

  fireEvent.click(screen.getByText('Show Success'))
  expect(screen.getByText('Success!')).toBeInTheDocument()
  expect(screen.getByText('It worked')).toBeInTheDocument()
})

test('toast auto-dismisses', async () => {
  jest.useFakeTimers()

  render(
    <ToastProvider>
      <TestComponent />
    </ToastProvider>
  )

  fireEvent.click(screen.getByText('Show Success'))
  expect(screen.getByTestId('toast-count')).toHaveTextContent('1')

  jest.advanceTimersByTime(5000)

  await waitFor(() => {
    expect(screen.getByTestId('toast-count')).toHaveTextContent('0')
  })

  jest.useRealTimers()
})
```

### Commands to Verify

```bash
npm run dev

# Test on desktop:
# - Add a video (success toast)
# - Try invalid URL (error toast)
# - Delete a video (success toast)

# Test on mobile (devtools):
# - Verify touch targets are large enough
# - Verify no horizontal scroll
# - Verify filters scroll smoothly
# - Test on iPhone X (notch/safe area)
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|

## 5. Comments

- Toast container is fixed at bottom-right (bottom for mobile-friendliness)
- Errors have longer duration (8s) as they're more important
- Touch targets follow Apple HIG (44px minimum)
- Horizontal scroll for filters prevents wrapping issues
- Safe area padding prevents content hiding behind iOS home indicator
- Animation uses CSS for performance
- Context pattern allows toasts from anywhere in the app
- Phase 5 (Polish) is complete after this ticket
- VidKeep MVP is ready for deployment!
