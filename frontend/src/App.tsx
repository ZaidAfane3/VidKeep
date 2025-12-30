import { useState, useMemo } from 'react'
import { RefreshCw } from 'lucide-react'
import Header from './components/Header'
import VideoGrid from './components/VideoGrid'
import VideoGridSkeleton from './components/VideoGridSkeleton'
import VideoPlayerModal from './components/VideoPlayerModal'
import Modal from './components/Modal'
import IngestForm from './components/IngestForm'
import DeleteConfirmModal from './components/DeleteConfirmModal'
import ToastContainer from './components/ToastContainer'
import { ToastProvider, useToast } from './contexts/ToastContext'
import { useVideos } from './hooks/useVideos'
import { useChannels } from './hooks/useChannels'
import { useDownloadProgress } from './hooks/useDownloadProgress'
import type { Video } from './api/types'

function AppContent() {
  const { toasts, removeToast, success, error: showError } = useToast()

  // Filter state
  const [selectedChannel, setSelectedChannel] = useState<string>()
  const [favoritesOnly, setFavoritesOnly] = useState(false)

  // Video player modal state
  const [playingVideo, setPlayingVideo] = useState<Video | null>(null)

  // Ingest modal state
  const [showIngestModal, setShowIngestModal] = useState(false)

  // Delete confirmation modal state
  const [deletingVideo, setDeletingVideo] = useState<Video | null>(null)

  // Fetch channels for filter dropdown
  const { channels, loading: channelsLoading, refresh: refreshChannels } = useChannels()

  // WebSocket download progress
  const { progress: downloadProgress, isConnected: wsConnected } = useDownloadProgress()

  // Fetch videos with filter options
  const {
    videos,
    loading,
    error,
    refresh,
    toggleFavorite,
    deleteVideo,
    retryVideo
  } = useVideos({
    channel: selectedChannel,
    favoritesOnly
  })

  // Merge WebSocket progress into videos
  const videosWithProgress = useMemo(() => {
    return videos.map(video => ({
      ...video,
      download_progress: downloadProgress[video.video_id]?.percent ?? video.download_progress
    }))
  }, [videos, downloadProgress])

  // Count favorites from current video list
  const favoritesCount = useMemo(() => {
    return videos.filter(v => v.is_favorite).length
  }, [videos])

  const handlePlay = (video: Video) => {
    setPlayingVideo(video)
  }

  const handleClosePlayer = () => {
    setPlayingVideo(null)
  }

  const handleFavoritesToggle = () => {
    setFavoritesOnly(!favoritesOnly)
  }

  const handleAddVideoClick = () => {
    setShowIngestModal(true)
  }

  const handleIngestSuccess = (_videoId: string) => {
    // Refresh both videos and channels after successful ingest
    refresh()
    refreshChannels()

    // Show success toast
    success('Video queued', 'Download will start shortly')

    // Close modal after 2 seconds to show success message
    setTimeout(() => {
      setShowIngestModal(false)
    }, 2000)
  }

  const handleCloseIngestModal = () => {
    setShowIngestModal(false)
  }

  // Delete confirmation handlers
  const handleDeleteClick = (videoId: string) => {
    const video = videos.find(v => v.video_id === videoId)
    if (video) {
      setDeletingVideo(video)
    }
  }

  const handleDeleteConfirm = async (videoId: string) => {
    try {
      await deleteVideo(videoId)
      success('Video deleted', 'Video and files removed')
    } catch (err) {
      showError('Delete failed', err instanceof Error ? err.message : 'Failed to delete video')
      throw err // Re-throw to let modal handle it
    }
  }

  const handleCloseDeleteModal = () => {
    setDeletingVideo(null)
  }

  // Retry handler with toast
  const handleRetry = async (videoId: string) => {
    try {
      await retryVideo(videoId)
      success('Retry queued', 'Download will restart shortly')
    } catch (err) {
      showError('Retry failed', err instanceof Error ? err.message : 'Failed to retry download')
    }
  }

  return (
    <div className="min-h-screen bg-term-bg font-terminal pb-12">
      {/* Scanlines Overlay (Design.md Section 3.1) */}
      <div className="scanlines" aria-hidden="true" />

      {/* Header with Filters */}
      <Header
        channels={channels}
        channelsLoading={channelsLoading}
        selectedChannel={selectedChannel}
        onChannelSelect={setSelectedChannel}
        favoritesOnly={favoritesOnly}
        onFavoritesToggle={handleFavoritesToggle}
        favoritesCount={favoritesCount}
        totalVideos={videosWithProgress.length}
        onAddVideoClick={handleAddVideoClick}
      />

      {/* Main Content Area */}
      <main className="max-w-[1440px] mx-auto px-4 py-8">
        {/* Error State */}
        {error && (
          <div
            className="bg-term-error/10 border border-term-error text-term-error px-4 py-3 mb-6 flex items-center justify-between"
            role="alert"
          >
            <span className="text-body uppercase">ERROR: {error}</span>
            <button
              onClick={refresh}
              className="btn-secondary flex items-center gap-2"
            >
              <RefreshCw className="w-4 h-4" />
              RETRY
            </button>
          </div>
        )}

        {/* Loading State */}
        {loading ? (
          <VideoGridSkeleton />
        ) : (
          <VideoGrid
            videos={videosWithProgress}
            onFavoriteToggle={toggleFavorite}
            onDelete={handleDeleteClick}
            onPlay={handlePlay}
            onRetry={handleRetry}
          />
        )}
      </main>

      {/* Footer Status Bar */}
      <footer className="fixed bottom-0 left-0 right-0 h-8 bg-term-bg border-t border-term-dim z-30">
        <div className="max-w-[1440px] mx-auto px-4 h-full flex items-center justify-between">
          <span className="text-mono text-term-primary/40 uppercase">
            VidKeep v1.0.0
          </span>
          <div className="flex items-center gap-4">
            {/* WebSocket connection status */}
            <span className={`text-mono uppercase flex items-center gap-1 ${wsConnected ? 'text-term-success/60' : 'text-term-warning/60'}`}>
              <span className={`w-1.5 h-1.5 rounded-full ${wsConnected ? 'bg-term-success' : 'bg-term-warning animate-pulse'}`} />
              {wsConnected ? 'LIVE' : 'RECONNECTING'}
            </span>
            <span className="text-mono text-term-primary/40 uppercase">
              &lt;/TERMINAL&gt;
            </span>
          </div>
        </div>
      </footer>

      {/* Video Player Modal */}
      <VideoPlayerModal
        video={playingVideo}
        isOpen={playingVideo !== null}
        onClose={handleClosePlayer}
      />

      {/* Ingest Form Modal */}
      <Modal
        isOpen={showIngestModal}
        onClose={handleCloseIngestModal}
        title="ADD VIDEO"
      >
        <div className="p-4">
          <IngestForm
            onSuccess={handleIngestSuccess}
          />
        </div>
      </Modal>

      {/* Delete Confirmation Modal */}
      <DeleteConfirmModal
        video={deletingVideo}
        isOpen={deletingVideo !== null}
        onClose={handleCloseDeleteModal}
        onConfirm={handleDeleteConfirm}
      />

      {/* Toast Notifications */}
      <ToastContainer toasts={toasts} onDismiss={removeToast} />
    </div>
  )
}

function App() {
  return (
    <ToastProvider>
      <AppContent />
    </ToastProvider>
  )
}

export default App
