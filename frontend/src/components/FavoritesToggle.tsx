import { Heart } from 'lucide-react'

interface FavoritesToggleProps {
  active: boolean
  onToggle: () => void
  count?: number
}

export default function FavoritesToggle({
  active,
  onToggle,
  count
}: FavoritesToggleProps) {
  return (
    <button
      onClick={onToggle}
      className={`
        flex items-center gap-2 px-3 py-2 text-mono text-sm uppercase tracking-wider
        border transition-colors
        ${active
          ? 'bg-term-error/20 text-term-error border-term-error'
          : 'bg-term-dark text-term-primary/60 border-term-dim hover:text-term-primary hover:border-term-primary hover:bg-term-card'
        }
      `}
      aria-pressed={active}
      aria-label={`Show favorites only${count !== undefined ? ` (${count} favorites)` : ''}`}
    >
      <Heart
        className={`w-4 h-4 ${active ? 'fill-current' : ''}`}
        strokeWidth={2}
      />
      <span>FAVORITES</span>
      {count !== undefined && count > 0 && (
        <span
          className={`
            px-1.5 py-0.5 text-xs
            ${active ? 'bg-term-error/30' : 'bg-term-primary/20'}
          `}
        >
          {count}
        </span>
      )}
    </button>
  )
}
