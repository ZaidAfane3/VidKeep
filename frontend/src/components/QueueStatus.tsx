import { Loader2, Clock, CheckCircle } from 'lucide-react'

interface QueueStatusProps {
  pending: number
  processing: number
  loading?: boolean
}

/**
 * Compact queue status indicator for header
 * Shows only when queue is active
 */
export function QueueStatusCompact({ pending, processing, loading }: QueueStatusProps) {
  const total = pending + processing
  const isActive = total > 0

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-mono text-term-dim uppercase">
        <Loader2 className="w-3 h-3 animate-spin" />
      </div>
    )
  }

  if (!isActive) return null

  return (
    <div className="flex items-center gap-2">
      {/* Animated indicator */}
      <div className="relative">
        <div className="w-2 h-2 bg-term-info rounded-full" />
        <div className="absolute inset-0 w-2 h-2 bg-term-info rounded-full animate-ping opacity-75" />
      </div>

      {/* Status text */}
      <span className="text-mono text-term-info uppercase">
        {processing > 0 ? `${processing} downloading` : `${pending} queued`}
      </span>
    </div>
  )
}

/**
 * Full queue status display with all counts
 */
export default function QueueStatus({ pending, processing, loading }: QueueStatusProps) {
  const total = pending + processing
  const isActive = total > 0

  if (loading) {
    return (
      <div className="flex items-center gap-2 text-mono text-term-dim uppercase">
        <Loader2 className="w-4 h-4 animate-spin" />
        <span>LOADING QUEUE...</span>
      </div>
    )
  }

  if (!isActive) {
    return (
      <div className="flex items-center gap-2 text-mono text-term-dim uppercase">
        <CheckCircle className="w-4 h-4" />
        <span>QUEUE EMPTY</span>
      </div>
    )
  }

  return (
    <div className="flex items-center gap-4 text-mono uppercase">
      {/* Processing indicator */}
      {processing > 0 && (
        <div className="flex items-center gap-2 text-term-info">
          <div className="relative">
            <Loader2 className="w-4 h-4 animate-spin" />
          </div>
          <span>{processing} DOWNLOADING</span>
        </div>
      )}

      {/* Pending indicator */}
      {pending > 0 && (
        <div className="flex items-center gap-2 text-term-warning">
          <Clock className="w-4 h-4" />
          <span>{pending} QUEUED</span>
        </div>
      )}

      {/* Total badge */}
      <span className="px-2 py-0.5 bg-term-primary/20 text-term-primary text-xs font-bold">
        {total} TOTAL
      </span>
    </div>
  )
}
