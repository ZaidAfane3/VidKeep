import { ChevronDown } from 'lucide-react'
import type { Channel } from '../api/types'

interface ChannelFilterProps {
  channels: Channel[]
  selectedChannel: string | undefined
  onSelect: (channel: string | undefined) => void
  loading?: boolean
}

export default function ChannelFilter({
  channels,
  selectedChannel,
  onSelect,
  loading = false
}: ChannelFilterProps) {
  return (
    <div className="relative">
      <select
        value={selectedChannel || ''}
        onChange={(e) => onSelect(e.target.value || undefined)}
        disabled={loading}
        className="
          appearance-none bg-term-dark border border-term-dim
          px-3 py-2 pr-8 text-mono text-sm text-term-primary uppercase tracking-wider
          focus:outline-none focus:border-term-primary focus:ring-1 focus:ring-term-primary
          disabled:opacity-50 disabled:cursor-not-allowed
          cursor-pointer hover:border-term-primary hover:bg-term-card
          transition-colors
        "
        aria-label="Filter by channel"
      >
        <option value="">ALL CHANNELS</option>
        {channels.map((channel) => (
          <option key={channel.channel_name} value={channel.channel_name}>
            {channel.channel_name.toUpperCase()} ({channel.video_count})
          </option>
        ))}
      </select>

      {/* Dropdown arrow */}
      <div className="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none">
        <ChevronDown className="w-4 h-4 text-term-primary/60" />
      </div>

      {/* Loading indicator */}
      {loading && (
        <div className="absolute inset-y-0 right-6 flex items-center">
          <div className="w-3 h-3 border border-term-primary/40 border-t-term-primary rounded-full animate-spin" />
        </div>
      )}
    </div>
  )
}
