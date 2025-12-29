import { useState, FormEvent } from 'react'
import { Plus, Loader2, AlertCircle, CheckCircle, X } from 'lucide-react'
import { ingestVideo } from '../api/client'

interface IngestFormProps {
  onSuccess?: (videoId: string) => void
  onError?: (error: string) => void
  onClose?: () => void
}

/**
 * YouTube URL validation patterns
 */
const YOUTUBE_URL_PATTERNS = [
  /youtube\.com\/watch\?v=/,
  /youtu\.be\//,
  /youtube\.com\/embed\//,
  /m\.youtube\.com\/watch\?v=/,
  /youtube\.com\/shorts\//
]

function isValidYouTubeUrl(url: string): boolean {
  return YOUTUBE_URL_PATTERNS.some(pattern => pattern.test(url))
}

export default function IngestForm({ onSuccess, onError, onClose }: IngestFormProps) {
  const [url, setUrl] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()

    const trimmedUrl = url.trim()

    if (!trimmedUrl) {
      setError('ENTER A YOUTUBE URL')
      return
    }

    if (!isValidYouTubeUrl(trimmedUrl)) {
      setError('INVALID YOUTUBE URL FORMAT')
      return
    }

    setLoading(true)
    setError(null)
    setSuccess(false)

    try {
      const result = await ingestVideo(trimmedUrl)
      setSuccess(true)
      setUrl('')
      onSuccess?.(result.video_id)

      // Clear success state after 3 seconds
      setTimeout(() => {
        setSuccess(false)
        onClose?.()
      }, 2000)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'FAILED TO QUEUE VIDEO'
      setError(message.toUpperCase())
      onError?.(message)
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (value: string) => {
    setUrl(value)
    if (error) setError(null)
    if (success) setSuccess(false)
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      {/* Input row */}
      <div className="flex flex-col sm:flex-row gap-2">
        <div className="relative flex-1">
          <input
            type="text"
            value={url}
            onChange={(e) => handleInputChange(e.target.value)}
            placeholder="PASTE YOUTUBE URL..."
            disabled={loading}
            autoFocus
            className={`
              w-full px-3 py-2 text-mono text-sm uppercase
              bg-term-dark border
              focus:outline-none focus:ring-1
              disabled:opacity-50 disabled:cursor-not-allowed
              transition-colors placeholder:text-term-dim
              ${error
                ? 'border-term-error text-term-error focus:ring-term-error'
                : success
                  ? 'border-green-500 text-green-500 focus:ring-green-500'
                  : 'border-term-dim text-term-primary focus:border-term-primary focus:ring-term-primary'
              }
            `}
          />

          {/* Status icons */}
          {(error || success) && (
            <div className="absolute inset-y-0 right-3 flex items-center pointer-events-none">
              {error ? (
                <AlertCircle className="w-4 h-4 text-term-error" />
              ) : (
                <CheckCircle className="w-4 h-4 text-green-500" />
              )}
            </div>
          )}
        </div>

        {/* Submit button */}
        <button
          type="submit"
          disabled={loading || !url.trim()}
          className={`
            flex items-center justify-center gap-2 px-4 py-2
            text-mono text-sm uppercase tracking-wider
            border transition-colors whitespace-nowrap
            ${loading || !url.trim()
              ? 'bg-term-dark border-term-dim text-term-dim cursor-not-allowed'
              : 'bg-term-primary/20 border-term-primary text-term-primary hover:bg-term-primary/30'
            }
          `}
        >
          {loading ? (
            <>
              <Loader2 className="w-4 h-4 animate-spin" />
              <span>ADDING...</span>
            </>
          ) : (
            <>
              <Plus className="w-4 h-4" />
              <span>ADD VIDEO</span>
            </>
          )}
        </button>

        {/* Close button (if onClose provided) */}
        {onClose && (
          <button
            type="button"
            onClick={onClose}
            className="p-2 text-term-dim hover:text-term-primary transition-colors"
            aria-label="Cancel"
          >
            <X className="w-5 h-5" />
          </button>
        )}
      </div>

      {/* Error/Success message */}
      {error && (
        <p className="text-mono text-xs text-term-error uppercase">
          ERROR: {error}
        </p>
      )}
      {success && (
        <p className="text-mono text-xs text-green-500 uppercase">
          VIDEO QUEUED FOR DOWNLOAD
        </p>
      )}

      {/* Help text */}
      <p className="text-mono text-xs text-term-dim uppercase">
        SUPPORTED: YOUTUBE.COM/WATCH, YOUTU.BE, YOUTUBE SHORTS
      </p>
    </form>
  )
}
