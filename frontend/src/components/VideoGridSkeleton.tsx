interface VideoGridSkeletonProps {
  count?: number
}

export default function VideoGridSkeleton({ count = 8 }: VideoGridSkeletonProps) {
  return (
    <div
      className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
      aria-label="Loading videos"
      aria-busy="true"
    >
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="bg-term-card border border-term-dim overflow-hidden"
        >
          {/* Thumbnail skeleton */}
          <div className="aspect-video skeleton" />

          {/* Content skeleton */}
          <div className="p-3 border-t border-term-dim space-y-2">
            <div className="h-5 skeleton w-3/4" />
            <div className="h-4 skeleton w-1/2" />
          </div>
        </div>
      ))}
    </div>
  )
}
