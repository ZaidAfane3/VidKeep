import { useEffect, useRef, type ReactNode } from 'react'
import { X } from 'lucide-react'

interface ModalProps {
  isOpen: boolean
  onClose: () => void
  children: ReactNode
  title?: string
  maxWidth?: 'md' | 'lg' | 'xl' | '5xl'
}

export default function Modal({
  isOpen,
  onClose,
  children,
  title,
  maxWidth = '5xl'
}: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null)

  // Close on Escape key
  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }

    if (isOpen) {
      document.addEventListener('keydown', handleEscape)
      document.body.style.overflow = 'hidden'
      // Focus trap - focus the modal when it opens
      modalRef.current?.focus()
    }

    return () => {
      document.removeEventListener('keydown', handleEscape)
      document.body.style.overflow = ''
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  const maxWidthClasses = {
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
    '5xl': 'max-w-5xl'
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby={title ? 'modal-title' : undefined}
    >
      {/* Backdrop - Phosphor Console style */}
      <div className="modal-overlay" aria-hidden="true" />

      {/* Modal content */}
      <div
        ref={modalRef}
        className={`
          relative w-full ${maxWidthClasses[maxWidth]} max-h-[90vh] flex flex-col
          modal-panel overflow-hidden
        `}
        onClick={(e) => e.stopPropagation()}
        tabIndex={-1}
      >
        {/* Header - Terminal style with green bar */}
        {title && (
          <div className="modal-header">
            <h2
              id="modal-title"
              dir="auto"
              className="text-body font-bold truncate pr-4 tracking-wider"
            >
              {title}
            </h2>
            <button
              onClick={onClose}
              className="p-1 hover:bg-black/20 transition-colors"
              aria-label="Close modal"
            >
              <X className="w-5 h-5" strokeWidth={2} />
            </button>
          </div>
        )}

        {/* Body */}
        <div className="flex-1 overflow-auto bg-term-bg">
          {children}
        </div>
      </div>
    </div>
  )
}
