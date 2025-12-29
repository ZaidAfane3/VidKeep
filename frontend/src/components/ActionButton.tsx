import type { ReactNode, MouseEvent } from 'react'

interface ActionButtonProps {
  onClick: (e: MouseEvent) => void
  icon: ReactNode
  label: string
  disabled?: boolean
  variant?: 'default' | 'danger'
}

export default function ActionButton({
  onClick,
  icon,
  label,
  disabled = false,
  variant = 'default'
}: ActionButtonProps) {
  const variantClasses = {
    default: 'border-term-primary text-term-primary hover:bg-term-primary hover:text-black',
    danger: 'border-term-error text-term-error hover:bg-term-error hover:text-black'
  }

  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`
        flex flex-col items-center gap-1 p-2
        transition-all duration-150
        focus:outline-none focus-visible:ring-2 focus-visible:ring-term-primary
        ${disabled
          ? 'opacity-50 cursor-not-allowed'
          : 'active:scale-95'
        }
      `}
      title={label}
      aria-label={label}
    >
      <div
        className={`
          w-10 h-10 flex items-center justify-center
          border-2 bg-term-bg/80
          transition-all duration-150
          ${disabled ? 'border-term-dim text-term-dim' : variantClasses[variant]}
        `}
      >
        {icon}
      </div>
      <span className="text-mono text-xs uppercase tracking-wider">
        {label}
      </span>
    </button>
  )
}
