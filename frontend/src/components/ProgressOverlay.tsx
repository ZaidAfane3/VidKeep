interface ProgressOverlayProps {
  progress: number
}

export default function ProgressOverlay({ progress }: ProgressOverlayProps) {
  // Calculate stroke-dasharray for circular progress
  const circumference = 2 * Math.PI * 16
  const strokeDasharray = `${(progress / 100) * circumference} ${circumference}`

  return (
    <div className="absolute inset-0 bg-black/80 flex flex-col items-center justify-center">
      {/* Circular progress */}
      <div className="relative w-16 h-16">
        <svg className="w-full h-full -rotate-90" viewBox="0 0 36 36">
          {/* Background circle */}
          <circle
            cx="18"
            cy="18"
            r="16"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-term-dim"
          />
          {/* Progress circle */}
          <circle
            cx="18"
            cy="18"
            r="16"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeDasharray={strokeDasharray}
            strokeLinecap="square"
            className="text-term-primary transition-all duration-300"
          />
        </svg>
        {/* Percentage text */}
        <span className="absolute inset-0 flex items-center justify-center text-body font-bold text-term-primary text-glow">
          {progress}%
        </span>
      </div>
      <p className="text-mono text-term-primary/60 mt-2 uppercase tracking-wider">
        Downloading...
      </p>
    </div>
  )
}
