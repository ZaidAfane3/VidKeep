import type { VideoStatus } from '../api/types'

interface StatusBadgeProps {
  status: VideoStatus
}

const statusConfig: Record<VideoStatus, { label: string; className: string }> = {
  pending: {
    label: 'PENDING',
    className: 'badge-pending'
  },
  downloading: {
    label: 'DOWNLOADING',
    className: 'badge-downloading'
  },
  failed: {
    label: 'FAILED',
    className: 'badge-error'
  },
  complete: {
    label: 'COMPLETE',
    className: 'bg-term-primary text-black'
  }
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  const config = statusConfig[status]

  return (
    <span
      className={`px-2 py-0.5 text-mono font-bold tracking-wider ${config.className}`}
      role="status"
    >
      {config.label}
    </span>
  )
}
