import { useRef, useEffect, useState } from 'react'
import { ChevronDown, ChevronUp } from 'lucide-react'
import Modal from './Modal'
import type { Video } from '../api/types'
import { getStreamUrl } from '../api/client'
import { formatDuration } from '../utils/format'

interface VideoPlayerModalProps {
  video: Video | null
  isOpen: boolean
  onClose: () => void
}

export default function VideoPlayerModal({
  video,
  isOpen,
  onClose
}: VideoPlayerModalProps) {
  const videoRef = useRef<HTMLVideoElement>(null)
  const [showDescription, setShowDescription] = useState(false)

  // Auto-play when modal opens
  useEffect(() => {
    if (isOpen && videoRef.current) {
      videoRef.current.play().catch(() => {
        // Autoplay blocked - user will need to click play
      })
    }
  }, [isOpen, video])

  // Reset state when modal closes
  useEffect(() => {
    if (!isOpen) {
      setShowDescription(false)
      if (videoRef.current) {
        videoRef.current.pause()
        videoRef.current.currentTime = 0
      }
    }
  }, [isOpen])

  // Keyboard controls (separate from modal's Escape handler)
  useEffect(() => {
    if (!isOpen) return

    const handleKeydown = (e: KeyboardEvent) => {
      if (!videoRef.current) return

      // Don't handle if user is typing in an input
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
        return
      }

      switch (e.key.toLowerCase()) {
        case ' ':
        case 'k':
          e.preventDefault()
          if (videoRef.current.paused) {
            videoRef.current.play()
          } else {
            videoRef.current.pause()
          }
          break
        case 'arrowleft':
          e.preventDefault()
          videoRef.current.currentTime = Math.max(0, videoRef.current.currentTime - 10)
          break
        case 'arrowright':
          e.preventDefault()
          videoRef.current.currentTime = Math.min(
            videoRef.current.duration,
            videoRef.current.currentTime + 10
          )
          break
        case 'arrowup':
          e.preventDefault()
          videoRef.current.volume = Math.min(1, videoRef.current.volume + 0.1)
          break
        case 'arrowdown':
          e.preventDefault()
          videoRef.current.volume = Math.max(0, videoRef.current.volume - 0.1)
          break
        case 'm':
          e.preventDefault()
          videoRef.current.muted = !videoRef.current.muted
          break
        case 'f':
          e.preventDefault()
          toggleFullscreen()
          break
      }
    }

    document.addEventListener('keydown', handleKeydown)
    return () => document.removeEventListener('keydown', handleKeydown)
  }, [isOpen])

  const toggleFullscreen = async () => {
    if (!videoRef.current) return

    try {
      if (!document.fullscreenElement) {
        await videoRef.current.requestFullscreen()
      } else {
        await document.exitFullscreen()
      }
    } catch (err) {
      console.error('Fullscreen error:', err)
    }
  }

  if (!video) return null

  const streamUrl = getStreamUrl(video.video_id)

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={video.title}>
      {/* Video Player */}
      <div className="relative bg-black">
        <video
          ref={videoRef}
          src={streamUrl}
          className="w-full max-h-[70vh]"
          controls
          playsInline
          controlsList="nodownload"
        >
          Your browser does not support the video tag.
        </video>
      </div>

      {/* Video info - Phosphor Console styled */}
      <div className="p-4 space-y-3 border-t border-term-dim">
        {/* Channel and duration */}
        <div className="flex items-center justify-between text-mono">
          <span dir="auto" className="text-term-primary/60 uppercase">
            {video.channel_name}
          </span>
          {video.duration_seconds && (
            <span className="text-term-primary">
              {formatDuration(video.duration_seconds)}
            </span>
          )}
        </div>

        {/* Description toggle */}
        {video.description && (
          <div className="border border-term-dim">
            <button
              onClick={() => setShowDescription(!showDescription)}
              className="w-full flex items-center justify-between px-3 py-2 text-mono text-term-primary/60 hover:text-term-primary hover:bg-term-dark transition-colors"
            >
              <span className="uppercase tracking-wider">
                {showDescription ? 'Hide' : 'Show'} Description
              </span>
              {showDescription ? (
                <ChevronUp className="w-4 h-4" />
              ) : (
                <ChevronDown className="w-4 h-4" />
              )}
            </button>
            {showDescription && (
              <div className="px-3 py-2 border-t border-term-dim">
                <p
                  dir="auto"
                  className="text-mono text-term-primary/80 whitespace-pre-wrap text-sm"
                >
                  {video.description}
                </p>
              </div>
            )}
          </div>
        )}

        {/* Keyboard shortcuts hint */}
        <div className="text-mono text-xs text-term-dim pt-2 border-t border-term-dim">
          <span className="text-term-primary/60 uppercase tracking-wider">Shortcuts: </span>
          <span className="text-term-primary/40">
            SPACE/K = Play/Pause | LEFT/RIGHT = Seek 10s | UP/DOWN = Volume | M = Mute | F = Fullscreen | ESC = Close
          </span>
        </div>
      </div>
    </Modal>
  )
}
