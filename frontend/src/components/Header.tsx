import { X, Plus, Wifi, WifiOff } from 'lucide-react'
import ChannelFilter from './ChannelFilter'
import FavoritesToggle from './FavoritesToggle'
import { QueueStatusCompact } from './QueueStatus'
import { useQueueStatus } from '../hooks/useQueueStatus'
import { useDataSaver } from '../contexts/DataSaverContext'
import type { Channel } from '../api/types'

interface HeaderProps {
  channels: Channel[]
  channelsLoading: boolean
  selectedChannel: string | undefined
  onChannelSelect: (channel: string | undefined) => void
  favoritesOnly: boolean
  onFavoritesToggle: () => void
  favoritesCount?: number
  totalVideos: number
  onAddVideoClick: () => void
}

export default function Header({
  channels,
  channelsLoading,
  selectedChannel,
  onChannelSelect,
  favoritesOnly,
  onFavoritesToggle,
  favoritesCount,
  totalVideos,
  onAddVideoClick
}: HeaderProps) {
  const { mode, isActive: dataSaverActive, setMode } = useDataSaver()

  // Adjust queue polling based on data saver
  const { pending, processing, loading: queueLoading } = useQueueStatus({
    pollInterval: dataSaverActive ? 60000 : 10000  // 60s vs 10s
  })

  const hasActiveFilters = selectedChannel || favoritesOnly

  // Cycle through data saver modes
  const toggleDataSaver = () => {
    if (mode === 'auto') setMode('on')
    else if (mode === 'on') setMode('off')
    else setMode('auto')
  }

  const clearFilters = () => {
    onChannelSelect(undefined)
    if (favoritesOnly) onFavoritesToggle()
  }

  return (
    <header className="sticky top-0 z-40 bg-term-bg/95 border-b border-term-primary/30">
      <div className="max-w-[1440px] mx-auto px-4">
        {/* Main Header Row */}
        <div className="h-16 flex items-center justify-between">
          {/* Logo: ">_ VIDKEEP" with blinking underscore + Queue Status */}
          <div className="flex items-center gap-4">
            <div className="flex items-center text-glow">
              <h1 className="text-heading text-term-primary font-bold uppercase tracking-wider">
                <span className="text-term-primary/60">&gt;</span>
                <span className="animate-blink">_</span>
                <span className="ml-1">VIDKEEP</span>
              </h1>
            </div>

            {/* Queue Status (Desktop) */}
            <div className="hidden md:block">
              <QueueStatusCompact
                pending={pending}
                processing={processing}
                loading={queueLoading}
              />
            </div>
          </div>

          {/* Desktop Controls */}
          <div className="hidden md:flex items-center gap-3">
            {/* Add Video Button */}
            <button
              onClick={onAddVideoClick}
              className="flex items-center gap-2 px-3 py-2 text-mono text-sm uppercase tracking-wider
                bg-term-primary/20 border border-term-primary text-term-primary
                hover:bg-term-primary/30 transition-colors"
              aria-label="Add new video"
            >
              <Plus className="w-4 h-4" />
              <span>ADD VIDEO</span>
            </button>

            {/* Divider */}
            <div className="h-6 w-px bg-term-dim" />

            {/* Filters */}
            <ChannelFilter
              channels={channels}
              selectedChannel={selectedChannel}
              onSelect={onChannelSelect}
              loading={channelsLoading}
            />

            <FavoritesToggle
              active={favoritesOnly}
              onToggle={onFavoritesToggle}
              count={favoritesCount}
            />

            {/* Clear filters button */}
            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="flex items-center gap-1 px-2 py-1 text-mono text-xs text-term-dim hover:text-term-primary transition-colors uppercase"
                aria-label="Clear all filters"
              >
                <X className="w-3 h-3" />
                CLEAR
              </button>
            )}

            {/* Video count */}
            <span className="text-mono text-term-primary/60 uppercase ml-2">
              [ {totalVideos} VIDEOS ]
            </span>

            {/* Data Saver Toggle */}
            <button
              onClick={toggleDataSaver}
              className={`flex items-center gap-1 px-2 py-1 border transition-colors text-mono text-xs uppercase ${
                dataSaverActive
                  ? 'text-term-warning border-term-warning'
                  : 'text-term-primary/40 border-term-dim hover:text-term-primary hover:border-term-primary'
              }`}
              title={`Click to change mode. Current: ${mode.toUpperCase()}${dataSaverActive ? ' (Active - slower polling)' : ''}`}
              aria-label={`Data saver ${mode}, click to change`}
            >
              {dataSaverActive ? (
                <WifiOff className="w-3 h-3" />
              ) : (
                <Wifi className="w-3 h-3" />
              )}
              <span>{mode}</span>
            </button>
          </div>

          {/* Mobile Controls */}
          <div className="flex md:hidden items-center gap-2">
            {/* Queue Status (Mobile) */}
            <QueueStatusCompact
              pending={pending}
              processing={processing}
              loading={queueLoading}
            />

            {/* Add Video Button (compact) */}
            <button
              onClick={onAddVideoClick}
              className="p-2 text-term-primary hover:bg-term-primary/20 transition-colors"
              aria-label="Add new video"
            >
              <Plus className="w-5 h-5" />
            </button>

            {/* Video count */}
            <span className="text-mono text-term-primary/60 uppercase text-sm">
              [ {totalVideos} ]
            </span>

            {/* Data Saver Toggle (Mobile) */}
            <button
              onClick={toggleDataSaver}
              className={`flex items-center gap-1 px-1.5 py-1 border transition-colors text-mono text-xs uppercase ${
                dataSaverActive
                  ? 'text-term-warning border-term-warning'
                  : 'text-term-primary/40 border-term-dim'
              }`}
              title={`Data Saver: ${mode.toUpperCase()}`}
              aria-label={`Data saver ${mode}`}
            >
              {dataSaverActive ? (
                <WifiOff className="w-3 h-3" />
              ) : (
                <Wifi className="w-3 h-3" />
              )}
              <span>{mode}</span>
            </button>
          </div>
        </div>

        {/* Mobile Filters Row */}
        <div className="flex md:hidden items-center gap-2 pb-3 overflow-x-auto">
          <ChannelFilter
            channels={channels}
            selectedChannel={selectedChannel}
            onSelect={onChannelSelect}
            loading={channelsLoading}
          />

          <FavoritesToggle
            active={favoritesOnly}
            onToggle={onFavoritesToggle}
            count={favoritesCount}
          />

          {hasActiveFilters && (
            <button
              onClick={clearFilters}
              className="flex items-center gap-1 px-2 py-2 text-mono text-xs text-term-dim hover:text-term-primary transition-colors uppercase whitespace-nowrap"
              aria-label="Clear all filters"
            >
              <X className="w-3 h-3" />
              CLEAR
            </button>
          )}
        </div>
      </div>

      {/* Active Filters Indicator */}
      {hasActiveFilters && (
        <div className="bg-term-dark border-t border-term-dim">
          <div className="max-w-[1440px] mx-auto px-4 py-2">
            <span className="text-mono text-xs text-term-primary/60 uppercase">
              FILTERED:{' '}
              <span className="text-term-primary">
                {favoritesOnly ? 'FAVORITES' : 'ALL'}
                {selectedChannel && ` FROM "${selectedChannel.toUpperCase()}"`}
              </span>
            </span>
          </div>
        </div>
      )}
    </header>
  )
}
