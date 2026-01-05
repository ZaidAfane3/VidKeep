interface ProgressOverlayProps {
  progress: number
}

export default function ProgressOverlay({ progress }: ProgressOverlayProps) {
  // Calculate stroke-dasharray for circular progress
  const circumference = 2 * Math.PI * 16
  const strokeDasharray = `${(progress / 100) * circumference} ${circumference}`

  const isComplete = progress >= 100

  return (
    <div className="absolute inset-0 bg-black/80 flex flex-col items-center justify-center pointer-events-none">
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
          {/* Progress circle - no transition to prevent glitchy animation */}
          <circle
            cx="18"
            cy="18"
            r="16"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeDasharray={strokeDasharray}
            strokeLinecap="square"
            className={isComplete ? "text-term-success" : "text-term-info"}
          />
        </svg>
        {/* Percentage text or checkmark */}
        <span className={`absolute inset-0 flex items-center justify-center text-body font-bold ${isComplete ? 'text-term-success' : 'text-term-info'}`}>
          {isComplete ? '✓' : `${progress}%`}
        </span>
      </div>
      <p className={`text-mono mt-2 uppercase tracking-wider ${isComplete ? 'text-term-success/80' : 'text-term-info/80'}`}>
        {isComplete ? 'Complete!' : 'Downloading...'}
      </p>
    </div>
  )
}
