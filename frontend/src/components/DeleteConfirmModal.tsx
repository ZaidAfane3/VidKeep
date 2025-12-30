import { useState } from 'react'
import { AlertTriangle, Trash2, Loader2 } from 'lucide-react'
import Modal from './Modal'
import type { Video } from '../api/types'
import { formatFileSize } from '../utils/format'

interface DeleteConfirmModalProps {
  video: Video | null
  isOpen: boolean
  onClose: () => void
  onConfirm: (videoId: string) => Promise<void>
}

export default function DeleteConfirmModal({
  video,
  isOpen,
  onClose,
  onConfirm
}: DeleteConfirmModalProps) {
  const [deleting, setDeleting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleConfirm = async () => {
    if (!video) return

    setDeleting(true)
    setError(null)

    try {
      await onConfirm(video.video_id)
      onClose()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'FAILED TO DELETE VIDEO')
    } finally {
      setDeleting(false)
    }
  }

  const handleClose = () => {
    if (!deleting) {
      setError(null)
      onClose()
    }
  }

  if (!video) return null

  return (
    <Modal isOpen={isOpen} onClose={handleClose} maxWidth="md">
      <div className="p-6">
        {/* Warning Icon */}
        <div className="flex justify-center mb-4">
          <div className="w-16 h-16 rounded-full bg-term-error/20 border border-term-error/50 flex items-center justify-center">
            <AlertTriangle className="w-8 h-8 text-term-error" strokeWidth={2} />
          </div>
        </div>

        {/* Title */}
        <h2 className="text-heading text-center mb-2 uppercase tracking-wider">
          DELETE VIDEO?
        </h2>

        {/* Warning Text */}
        <p className="text-body text-term-dim text-center mb-4 uppercase">
          This action cannot be undone. The video and its thumbnail will be permanently deleted.
        </p>

        {/* Video Details Card */}
        <div className="bg-black/30 border border-term-dim p-3 mb-6">
          <div className="flex gap-3">
            {/* Thumbnail */}
            <div className="flex-shrink-0 w-24 h-16 bg-term-dim/20 overflow-hidden">
              <img
                src={`/api/thumbnail/${video.video_id}`}
                alt=""
                className="w-full h-full object-cover"
                onError={(e) => {
                  // Hide broken image
                  e.currentTarget.style.display = 'none'
                }}
              />
            </div>

            {/* Info */}
            <div className="flex-1 min-w-0">
              <p
                dir="auto"
                className="text-body text-term-primary font-bold truncate uppercase"
              >
                {video.title}
              </p>
              <p className="text-mono text-term-dim truncate uppercase">
                {video.channel_name}
              </p>
              {video.file_size_bytes && (
                <p className="text-mono text-term-warning mt-1 uppercase">
                  {formatFileSize(video.file_size_bytes)} will be freed
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-term-error/10 border border-term-error text-term-error px-3 py-2 mb-4">
            <p className="text-body uppercase">ERROR: {error}</p>
          </div>
        )}

        {/* Action Buttons */}
        <div className="flex gap-3">
          <button
            onClick={handleClose}
            disabled={deleting}
            className="flex-1 btn-secondary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            CANCEL
          </button>

          <button
            onClick={handleConfirm}
            disabled={deleting}
            className="
              flex-1 px-4 py-2 uppercase tracking-wider
              bg-term-error hover:bg-term-error/80
              text-white font-bold
              border border-term-error
              transition-colors
              disabled:opacity-50 disabled:cursor-not-allowed
              flex items-center justify-center gap-2
            "
          >
            {deleting ? (
              <>
                <Loader2 className="w-4 h-4 animate-spin" />
                DELETING...
              </>
            ) : (
              <>
                <Trash2 className="w-4 h-4" />
                DELETE
              </>
            )}
          </button>
        </div>
      </div>
    </Modal>
  )
}
