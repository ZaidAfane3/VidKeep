"""
Prometheus metrics definitions (T028).

Defines application metrics for worker pool monitoring:
- Download duration and speed histograms
- Active worker gauges
- Download totals counter
"""

from prometheus_client import Histogram, Gauge, Counter

# Histograms for distributions
DOWNLOAD_DURATION = Histogram(
    'vidkeep_download_duration_seconds',
    'Time spent downloading',
    ['quality', 'source'],
    buckets=[10, 30, 60, 120, 300, 600, 1800]
)

MUXING_DURATION = Histogram(
    'vidkeep_muxing_duration_seconds',
    'Time spent in FFmpeg muxing',
    buckets=[5, 15, 30, 60, 120, 300]
)

DOWNLOAD_SPEED = Histogram(
    'vidkeep_download_speed_mbps',
    'Download speed distribution',
    buckets=[1, 5, 10, 25, 50, 100, 200]
)

# Gauges for current state
ACTIVE_WORKERS = Gauge(
    'vidkeep_active_workers',
    'Currently active download workers'
)

WORKER_MEMORY = Gauge(
    'vidkeep_worker_memory_mb',
    'Worker memory usage',
    ['worker_id']
)

WORKER_CPU = Gauge(
    'vidkeep_worker_cpu_percent',
    'Worker CPU usage',
    ['worker_id']
)

# Counters for totals
DOWNLOADS_TOTAL = Counter(
    'vidkeep_downloads_total',
    'Total downloads by status',
    ['status']  # completed, failed, cancelled
)


class WorkerMetrics:
    """Collects and emits worker metrics to Prometheus."""

    def record_download_complete(self, quality: str, duration: float, speed_mbps: float):
        """Record a completed download."""
        DOWNLOAD_DURATION.labels(quality=quality, source='youtube').observe(duration)
        DOWNLOAD_SPEED.observe(speed_mbps)
        DOWNLOADS_TOTAL.labels(status='completed').inc()

    def record_muxing(self, duration: float):
        """Record muxing duration."""
        MUXING_DURATION.observe(duration)

    def record_failure(self):
        """Record a failed download."""
        DOWNLOADS_TOTAL.labels(status='failed').inc()

    def record_cancelled(self):
        """Record a cancelled download."""
        DOWNLOADS_TOTAL.labels(status='cancelled').inc()

    def update_worker_resources(self, worker_id: str, pid: int):
        """Update resource usage for a worker process."""
        try:
            import psutil
            proc = psutil.Process(pid)
            WORKER_MEMORY.labels(worker_id=worker_id).set(
                proc.memory_info().rss / 1024 / 1024
            )
            WORKER_CPU.labels(worker_id=worker_id).set(proc.cpu_percent())
        except Exception:
            pass  # Ignore errors (process may have exited)

    def set_active_workers(self, count: int):
        """Set the current active worker count."""
        ACTIVE_WORKERS.set(count)

    def clear_worker(self, worker_id: str):
        """Remove worker from gauges when done."""
        try:
            WORKER_MEMORY.remove(worker_id)
            WORKER_CPU.remove(worker_id)
        except KeyError:
            pass  # Label not found, ignore


# Global instance
worker_metrics = WorkerMetrics()
