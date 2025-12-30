import { useEffect } from 'react'
import { CheckCircle, XCircle, AlertTriangle, Info, X } from 'lucide-react'

export type ToastType = 'success' | 'error' | 'warning' | 'info'

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

const icons: Record<ToastType, React.ReactNode> = {
  success: <CheckCircle className="w-5 h-5 text-term-success" strokeWidth={2} />,
  error: <XCircle className="w-5 h-5 text-term-error" strokeWidth={2} />,
  warning: <AlertTriangle className="w-5 h-5 text-term-warning" strokeWidth={2} />,
  info: <Info className="w-5 h-5 text-term-info" strokeWidth={2} />
}

const backgrounds: Record<ToastType, string> = {
  success: 'bg-term-success/10 border-term-success/50',
  error: 'bg-term-error/10 border-term-error/50',
  warning: 'bg-term-warning/10 border-term-warning/50',
  info: 'bg-term-info/10 border-term-info/50'
}

export default function Toast({ toast, onDismiss }: ToastProps) {
  useEffect(() => {
    // duration of 0 means no auto-dismiss
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
        flex items-start gap-3 px-4 py-3 border
        ${backgrounds[toast.type]}
        animate-slide-in
        shadow-lg shadow-black/50
      `}
      role="alert"
    >
      {/* Icon */}
      <div className="flex-shrink-0 mt-0.5">
        {icons[toast.type]}
      </div>

      {/* Content */}
      <div className="flex-1 min-w-0">
        <p className="text-body font-bold uppercase tracking-wider text-term-primary">
          {toast.title}
        </p>
        {toast.message && (
          <p className="text-mono text-term-dim mt-1 uppercase">
            {toast.message}
          </p>
        )}
      </div>

      {/* Dismiss Button */}
      <button
        onClick={() => onDismiss(toast.id)}
        className="flex-shrink-0 p-1 hover:bg-white/10 transition-colors"
        aria-label="Dismiss notification"
      >
        <X className="w-4 h-4 text-term-dim" strokeWidth={2} />
      </button>
    </div>
  )
}
