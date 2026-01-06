# T028: Embedded Worker Process Pool Architecture

## 1. Overview

**Ticket Type**: Architecture Refactor  
**Priority**: Medium  
**Effort Estimate**: 3-4 days  
**Depends On**: T026 (Monolith Merge - if proceeding)

### Summary

Refactor the worker architecture from separate ARQ worker containers to an embedded process pool model where each pod manages its own download processes. This simplifies Kubernetes deployment by eliminating separate worker deployments while maintaining horizontal scaling capability.

---

## 2. Current vs Proposed Architecture

### Current Architecture (ARQ Workers)

```
┌──────────────────────────────────────────────────────────────────┐
│                    CURRENT (Separate Workers)                     │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   Pod: api                           Pod: worker-1                │
│   ┌─────────────┐                    ┌─────────────┐             │
│   │ FastAPI     │──── Redis ────────▶│ ARQ Worker  │             │
│   │ (enqueue)   │     Queue          │ (consume)   │             │
│   └─────────────┘                    └─────────────┘             │
│                                                                   │
│                                      Pod: worker-2                │
│                                      ┌─────────────┐             │
│                                      │ ARQ Worker  │             │
│                                      │ (consume)   │             │
│                                      └─────────────┘             │
│                                                                   │
│   Deployments needed: 2 (api + worker, scaled separately)        │
└──────────────────────────────────────────────────────────────────┘
```

### Proposed Architecture (Embedded Process Pool)

```
┌──────────────────────────────────────────────────────────────────┐
│                 PROPOSED (Embedded Workers)                       │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│   Pod 1 (MAX_WORKERS=2)              Pod 2 (MAX_WORKERS=2)       │
│   ┌─────────────────────┐            ┌─────────────────────┐     │
│   │  Main Process       │            │  Main Process       │     │
│   │  (FastAPI + FE)     │            │  (FastAPI + FE)     │     │
│   │    │                │            │    │                │     │
│   │    ├─▶ Worker P1    │◀──Redis──▶│    ├─▶ Worker P1    │     │
│   │    └─▶ Worker P2    │   Queue    │    └─▶ Worker P2    │     │
│   └─────────────────────┘            └─────────────────────┘     │
│                                                                   │
│   Total capacity: 4 concurrent downloads                          │
│   Deployments needed: 1 (scales pods = scales workers)           │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. Scaling Model

| Pods | `MAX_WORKERS` | Total Concurrent Downloads |
|------|---------------|---------------------------|
| 1    | 1             | 1                         |
| 1    | 2             | 2                         |
| 2    | 1             | 2                         |
| 2    | 2             | 4                         |
| 3    | 2             | 6                         |

> [!TIP]
> For home lab use, `MAX_WORKERS=1` or `2` is recommended. Higher values increase memory/CPU per pod.

---

## 4. Queue Strategy Decision: Redis vs Database

### Recommendation: Hybrid Approach

Use **Redis for job queuing** with **Database for state persistence**.

| Concern | Redis Queue | Database Queue |
|---------|-------------|----------------|
| **Atomicity** | `BRPOPLPUSH` for atomic claim | `SELECT FOR UPDATE` works |
| **Speed** | ~1ms latency | ~5-10ms latency |
| **Heartbeat** | Native `SETEX` with TTL | Requires polling |
| **Recovery** | Jobs lost if Redis restarts without persistence | Jobs survive DB restarts |
| **Visibility** | Redis CLI needed | SQL queries |

### Hybrid Design

```
┌─────────────────────────────────────────────────────────────────┐
│                     JOB LIFECYCLE FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   1. User submits URL                                            │
│      └─▶ Video created in DB (status: QUEUED)                   │
│      └─▶ Job pushed to Redis queue                              │
│                                                                  │
│   2. Worker claims job                                           │
│      └─▶ BRPOPLPUSH moves job to processing list               │
│      └─▶ DB updated (status: DOWNLOADING, claimed_by: pod-1:w1) │
│      └─▶ Worker starts heartbeat (Redis SETEX every 10s)        │
│                                                                  │
│   3. Download in progress                                        │
│      └─▶ Progress published via Redis pub/sub                   │
│      └─▶ Heartbeat renewed every 10s                            │
│                                                                  │
│   4. Download completes                                          │
│      └─▶ DB updated (status: COMPLETE)                          │
│      └─▶ Job removed from Redis processing list                 │
│      └─▶ Heartbeat key deleted                                  │
│                                                                  │
│   5. Worker crashes (no heartbeat)                               │
│      └─▶ Recovery task detects stale job (heartbeat expired)    │
│      └─▶ DB updated (status: QUEUED, retry_count++)             │
│      └─▶ Job re-pushed to Redis queue                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. Download Resume Capability

### yt-dlp Resume Support

yt-dlp supports resuming interrupted downloads via the `--continue` flag (enabled by default). For this to work:

1. **Don't delete partial files** on worker crash
2. **Only delete partial files** on explicit cancellation or final failure

### Implementation Strategy

```python
# Current behavior (ytdlp.py)
def cleanup_partial_files(video_id):
    # Deletes .part, .ytdl, temp files
    ...

# New behavior
def cleanup_partial_files(video_id, reason: str):
    if reason == "cancelled":
        # User cancelled - delete everything
        ...
    elif reason == "max_retries_exceeded":
        # Failed after all retries - delete everything
        ...
    elif reason == "worker_crash_recovery":
        # Worker died - KEEP partial files for resume
        pass  # Do nothing, let next attempt resume
```

### Resume Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                   RESUME DOWNLOAD FLOW                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Attempt 1: Worker starts download                              │
│              Downloads 60% (video.mp4.part = 600MB)              │
│              Worker crashes                                      │
│              Partial file preserved                              │
│                                                                  │
│   Attempt 2: Recovery task re-queues job                         │
│              New worker claims job                               │
│              yt-dlp detects existing .part file                 │
│              Resumes from 60%, downloads remaining 40%           │
│              Video completes                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Storage Consideration

> [!IMPORTANT]
> For resume to work, all pods must share the same persistent volume (PVC). This is already the case with `vidkeep_data` volume.

---

## 6. Required Changes

### 6.1 New Configuration

```python
# backend/app/config.py
class Settings(BaseSettings):
    # Existing...
    
    # Embedded worker config
    max_workers: int = Field(default=1, env="MAX_WORKERS")
    worker_heartbeat_interval: int = Field(default=10, env="WORKER_HEARTBEAT_INTERVAL")
    worker_heartbeat_ttl: int = Field(default=30, env="WORKER_HEARTBEAT_TTL")
    stale_job_threshold_seconds: int = Field(default=60, env="STALE_JOB_THRESHOLD")
    max_download_retries: int = Field(default=3, env="MAX_DOWNLOAD_RETRIES")
```

### 6.2 Database Schema Updates

```python
# backend/app/models.py - Video model additions
class Video(Base):
    # Existing fields...
    
    # Job tracking fields
    claimed_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    claimed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    retry_count: Mapped[int] = mapped_column(Integer, default=0)
    last_heartbeat: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
```

### 6.3 New Worker Manager

```python
# backend/app/services/worker_manager.py

class WorkerProcess:
    """Represents a single download worker process."""
    def __init__(self, process_id: str, video_id: str):
        self.process_id = process_id
        self.video_id = video_id
        self.process: asyncio.subprocess.Process | None = None
        self.started_at = datetime.utcnow()

class WorkerManager:
    """Manages a pool of download worker processes."""
    
    def __init__(self, max_workers: int):
        self.max_workers = max_workers
        self.active_workers: dict[str, WorkerProcess] = {}
        self.redis: Redis | None = None
        self._shutdown = False
    
    async def start(self):
        """Start the worker manager and begin consuming jobs."""
        self.redis = await get_redis()
        asyncio.create_task(self._job_consumer_loop())
        asyncio.create_task(self._heartbeat_loop())
        asyncio.create_task(self._stale_job_recovery_loop())
    
    async def shutdown(self, grace_period: int = 300):
        """Gracefully shutdown all workers."""
        self._shutdown = True
        # Wait for in-progress downloads with timeout
        ...
    
    async def _job_consumer_loop(self):
        """Main loop that claims and processes jobs."""
        while not self._shutdown:
            if len(self.active_workers) < self.max_workers:
                job = await self._claim_next_job()
                if job:
                    await self._spawn_worker(job)
            await asyncio.sleep(1)
    
    async def _heartbeat_loop(self):
        """Send heartbeats for all active workers."""
        ...
    
    async def _stale_job_recovery_loop(self):
        """Detect and re-queue stale jobs from crashed workers."""
        ...
```

### 6.4 File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `backend/app/config.py` | Modify | Add worker config settings |
| `backend/app/models.py` | Modify | Add job tracking fields |
| `backend/app/services/worker_manager.py` | **New** | Process pool manager |
| `backend/app/worker.py` | Delete/Repurpose | No longer needed as ARQ worker |
| `backend/app/tasks/download.py` | Modify | Adjust for new architecture |
| `backend/app/services/ytdlp.py` | Modify | Resume-aware cleanup |
| `backend/app/main.py` | Modify | Start WorkerManager on startup |
| `backend/app/routers/videos.py` | Modify | Adjust enqueue logic |
| `alembic/versions/xxx_add_job_tracking.py` | **New** | Migration for new columns |
| `docker-compose.yml` | Modify | Remove worker service |
| `Dockerfile` | Modify | Single unified image |

---

## 7. Redis Key Schema

```
vidkeep:jobs:pending          # List - jobs waiting to be processed
vidkeep:jobs:processing       # List - jobs currently being processed

vidkeep:heartbeat:{video_id}  # String with TTL - worker heartbeat
  Value: "{pod_name}:{process_id}"
  TTL: 30 seconds

vidkeep:worker:{pod_name}     # Hash - pod's worker info
  field: process_count
  field: active_jobs (JSON array)

cancel:{video_id}             # Existing - cancellation flag
progress:{video_id}           # Existing - pub/sub channel
```

---

## 8. Failover Mechanisms

### 8.1 Graceful Shutdown (SIGTERM)

```python
@app.on_event("shutdown")
async def shutdown():
    """Handle pod termination gracefully."""
    logger.info("Shutdown signal received")
    
    # Stop accepting new jobs
    worker_manager.stop_accepting()
    
    # Wait for in-progress downloads (up to 5 minutes)
    await worker_manager.shutdown(grace_period=300)
    
    # Any incomplete jobs will have stale heartbeats
    # and be recovered by other pods
```

### 8.2 Worker Process Crash

```python
async def _monitor_worker(self, worker: WorkerProcess):
    """Monitor a worker process and handle crashes."""
    try:
        await worker.process.wait()
        exit_code = worker.process.returncode
        
        if exit_code != 0:
            # Process crashed - job will be recovered via stale heartbeat
            logger.error(f"Worker {worker.process_id} crashed: exit {exit_code}")
    finally:
        del self.active_workers[worker.video_id]
```

### 8.3 Stale Job Recovery

```python
async def _stale_job_recovery_loop(self):
    """Periodic task to recover jobs from crashed workers."""
    while not self._shutdown:
        async with async_session() as db:
            stale_threshold = datetime.utcnow() - timedelta(
                seconds=settings.stale_job_threshold_seconds
            )
            
            stale_videos = await db.execute(
                select(Video).where(
                    Video.status == "downloading",
                    Video.claimed_at < stale_threshold,
                )
            )
            
            for video in stale_videos.scalars():
                # Check if heartbeat exists in Redis
                heartbeat = await self.redis.get(f"vidkeep:heartbeat:{video.id}")
                if not heartbeat:
                    # Worker is dead, re-queue
                    if video.retry_count < settings.max_download_retries:
                        video.status = "queued"
                        video.claimed_by = None
                        video.claimed_at = None
                        video.retry_count += 1
                        logger.warning(f"Re-queued stale job: {video.id}")
                        
                        # Push back to Redis queue
                        await self.redis.lpush("vidkeep:jobs:pending", video.id)
                    else:
                        video.status = "failed"
                        video.error_message = "Max retries exceeded"
                        # Clean up partial files
                        ytdlp.cleanup_partial_files(video.id, "max_retries_exceeded")
                
            await db.commit()
        
        await asyncio.sleep(30)  # Check every 30 seconds
```

---

### 8.4 Zombie Process Prevention

> [!WARNING]
> **Zombie Processes Risk**: When managing raw subprocesses in containers, if the parent process (FastAPI) crashes hard or is OOM-killed, subprocesses can become "zombies" if PID 1 doesn't reap them appropriately.

**Mitigation**:
Ensure the Docker image uses an init system (like `tini` or `dumb-init`) as the entrypoint.

```dockerfile
# Dockerfile example
ENTRYPOINT ["/usr/bin/tini", "--", "/start.sh"]
```

---

## 9. Kubernetes Deployment

### 9.1 Single Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vidkeep
spec:
  replicas: 2  # Scale this for more capacity
  template:
    spec:
      terminationGracePeriodSeconds: 330  # 5.5 min for graceful shutdown
      containers:
        - name: vidkeep
          image: vidkeep:v1.0.0
          env:
            - name: MAX_WORKERS
              value: "2"  # 2 concurrent downloads per pod
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "2Gi"  # yt-dlp + FFmpeg can be memory hungry
              cpu: "1000m"
          volumeMounts:
            - name: data
              mountPath: /data
      volumes:
        - name: data
          persistentVolumeClaim:
            claimName: vidkeep-data  # Shared PVC for resume
```

### 9.2 HPA (Optional)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: vidkeep-hpa
spec:
  scaleTargetRef:
    kind: Deployment
    name: vidkeep
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: External
      external:
        metric:
          name: redis_list_length
          selector:
            matchLabels:
              key: vidkeep:jobs:pending
        target:
          type: AverageValue
          averageValue: "3"  # Scale up if >3 queued jobs per pod
```

---

## 10. Resource Monitoring & Metrics

Track worker resource utilization using Prometheus-native metrics.

### 10.1 Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   VidKeep API   │────▶│   Prometheus    │────▶│    Grafana      │
│   /metrics      │     │   (scrape)      │     │   (dashboards)  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  Alertmanager   │
                                                │  (optional)     │
                                                └─────────────────┘
```

> [!TIP]
> Let Prometheus handle retention and Grafana handle aggregation/recommendations. No custom JSON APIs needed.

### 10.2 Metrics Reference

| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| `vidkeep_download_duration_seconds` | Histogram | `quality`, `source` | Total time from download start to completion. Buckets: 10s, 30s, 60s, 2m, 5m, 10m, 30m |
| `vidkeep_muxing_duration_seconds` | Histogram | - | Time spent in FFmpeg merging video+audio. This is the CPU-intensive phase. Buckets: 5s, 15s, 30s, 1m, 2m, 5m |
| `vidkeep_download_speed_mbps` | Histogram | - | Download speed distribution. Buckets: 1, 5, 10, 25, 50, 100, 200 Mbps |
| `vidkeep_active_workers` | Gauge | - | Number of currently active download worker processes |
| `vidkeep_worker_memory_mb` | Gauge | `worker_id` | Memory usage per worker process in MB |
| `vidkeep_worker_cpu_percent` | Gauge | `worker_id` | CPU usage per worker process (0-100+) |
| `vidkeep_downloads_total` | Counter | `status` | Cumulative count of downloads. Status: `completed`, `failed`, `cancelled` |

> [!NOTE]
> **Counter for Failures**: We use a **Counter** for `vidkeep_downloads_total` with `status="failed"` to track the *rate* of failures over time. Since failure is a terminal state, a Gauge (for "currently failing") is not required.

**Metric Types:**
- **Histogram**: Tracks distribution of values across buckets. Use `histogram_quantile()` for percentiles.
- **Gauge**: Current value that can go up or down. Sampled at each Prometheus scrape.
- **Counter**: Cumulative total that only increases. Use `rate()` for per-second rates.

### 10.3 Prometheus Metrics Definition

```python
# backend/app/services/metrics.py
from prometheus_client import Histogram, Gauge, Counter
import psutil

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
        DOWNLOAD_DURATION.labels(quality=quality, source='youtube').observe(duration)
        DOWNLOAD_SPEED.observe(speed_mbps)
        DOWNLOADS_TOTAL.labels(status='completed').inc()
    
    def record_muxing(self, duration: float):
        MUXING_DURATION.observe(duration)
    
    def record_failure(self):
        DOWNLOADS_TOTAL.labels(status='failed').inc()
    
    def record_cancelled(self):
        DOWNLOADS_TOTAL.labels(status='cancelled').inc()
    
    def update_worker_resources(self, worker_id: str, pid: int):
        try:
            proc = psutil.Process(pid)
            WORKER_MEMORY.labels(worker_id=worker_id).set(
                proc.memory_info().rss / 1024 / 1024
            )
            WORKER_CPU.labels(worker_id=worker_id).set(proc.cpu_percent())
        except psutil.NoSuchProcess:
            pass
    
    def set_active_workers(self, count: int):
        ACTIVE_WORKERS.set(count)
    
    def clear_worker(self, worker_id: str):
        """Remove worker from gauges when done."""
        WORKER_MEMORY.remove(worker_id)
        WORKER_CPU.remove(worker_id)


# Global instance
worker_metrics = WorkerMetrics()
```

### 10.4 Metrics Endpoint

```python
# backend/app/routers/metrics.py
from fastapi import APIRouter
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

router = APIRouter()

@router.get("/metrics")
async def metrics():
    """Prometheus-compatible metrics endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
```

### 10.5 File Changes for Metrics

| File | Action | Description |
|------|--------|-------------|
| `backend/app/services/metrics.py` | **New** | Prometheus metrics + collection |
| `backend/app/routers/metrics.py` | **New** | `/metrics` endpoint |
| `backend/app/main.py` | Modify | Register metrics router |
| `backend/requirements.txt` | Modify | Add `psutil`, `prometheus-client` |

---

## 11. Frontend UI Synchronization

Update the frontend to reflect the new worker architecture with proper status sync.

### 11.1 Status Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     VIDEO STATUS LIFECYCLE                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   QUEUED ─────▶ DOWNLOADING ─────▶ COMPLETE                         │
│     │               │                  │                             │
│     │               ├─────▶ FAILED     │                             │
│     │               │                  │                             │
│     │               └─────▶ CANCELLED  │                             │
│     │                                  │                             │
│     └──────────────────────────────────┘                            │
│              (re-queue on recovery)                                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 11.2 WebSocket Message Types

Current implementation supports these message types (no changes required):

| Message Type | When Sent | Payload |
|--------------|-----------|---------|
| `status` | Status transition (queued→downloading) | `{ type: "status", status: "downloading", video_id }` |
| `progress` | During download | `{ percent, downloaded_bytes, total_bytes, video_id }` |
| `completion` | Download finished | `{ type: "completion", status: "complete" \| "failed" \| "cancelled", video_id }` |

### 11.3 New Status: "Resuming"

When a download resumes from partial file, show visual feedback:

```typescript
// frontend/src/types/video.ts
export type VideoStatus = 
  | 'queued' 
  | 'downloading' 
  | 'resuming'    // NEW: Resuming from partial file
  | 'complete' 
  | 'failed' 
  | 'cancelled'
```

```python
# backend/app/tasks/download.py - Add resume detection
async def download_video(ctx, video_id: str, url: str):
    # Check if resuming from partial file
    partial_file = ytdlp.get_partial_path(video_id)
    is_resuming = partial_file.exists()
    
    if is_resuming:
        await redis.publish(
            f"progress:{video_id}",
            json.dumps({
                "type": "status",
                "status": "resuming",
                "video_id": video_id,
                "resumed_bytes": partial_file.stat().st_size
            })
        )
```

### 11.4 VideoCard UI Updates

Update the video card to show worker status:

```typescript
// frontend/src/components/VideoCard.tsx

// Existing flashing indicator logic (no changes needed)
const isDownloading = video.status === 'downloading' || video.status === 'resuming'

// Add retry badge if video was re-queued
{video.retry_count > 0 && video.status === 'queued' && (
  <span className="retry-badge">Retry #{video.retry_count}</span>
)}

// Show "Resuming" instead of "Downloading" when applicable
{video.status === 'resuming' && (
  <span className="status-text">Resuming from {formatBytes(video.resumed_bytes)}...</span>
)}
```

### 11.5 Queue Position Indicator

Show users their position in queue when multiple downloads are queued:

```typescript
// frontend/src/components/QueueStatus.tsx
interface QueueInfo {
  position: number
  total_queued: number
  active_downloads: number
  max_workers: number
}

// API endpoint to add
// GET /api/queue/status
// Returns: { queued_count, active_count, max_workers }
```

```python
# backend/app/routers/queue.py
@router.get("/api/queue/status")
async def get_queue_status():
    return {
        "queued_count": await redis.llen("vidkeep:jobs:pending"),
        "active_count": len(worker_manager.active_workers),
        "max_workers": settings.max_workers,
    }
```

### 11.6 File Changes for UI

| File | Action | Description |
|------|--------|-------------|
| `frontend/src/types/video.ts` | Modify | Add `resuming` status type |
| `frontend/src/components/VideoCard.tsx` | Modify | Handle resume and retry display |
| `frontend/src/components/QueueStatus.tsx` | Modify | Show active workers / capacity |
| `backend/app/routers/queue.py` | Modify | Add queue status endpoint |
| `backend/app/models.py` | Modify | Expose `retry_count` in API response |

---

## 12. Testing Plan

### 12.1 Unit Tests

- [ ] `WorkerManager` initialization and configuration
- [ ] Job claiming with atomic Redis operations
- [ ] Heartbeat generation and expiry
- [ ] Stale job detection logic
- [ ] Resume-aware cleanup logic
- [ ] Prometheus metrics recording

### 12.2 Integration Tests

- [ ] End-to-end download with embedded worker
- [ ] Graceful shutdown preserves job state
- [ ] Stale job recovery after simulated crash
- [ ] Resume download after worker restart (verify partial files used)
- [ ] Concurrent downloads respects `MAX_WORKERS` limit
- [ ] WebSocket status updates for queued→downloading→complete
- [ ] WebSocket resume status when resuming partial download

### 12.3 Manual Testing

1. **Basic Flow**: Submit URL → verify download completes
2. **Concurrency**: Submit 3 URLs with `MAX_WORKERS=2` → verify 2 concurrent, 1 queued
3. **Crash Recovery**: Kill pod during download → verify job re-queued
4. **Resume**: Kill pod at 50% → verify new pod resumes from 50%
5. **Cancellation**: Cancel mid-download → verify cleanup works
6. **Max Retries**: Force 3 failures → verify job marked failed
7. **UI Sync**: Verify flashing indicator → progress bar → complete transition

---

## 13. Migration Path

### Phase 1: Implement alongside ARQ (feature flag)
- Add embedded worker code under feature flag
- Test in development environment

### Phase 2: Switch to embedded workers
- Remove ARQ dependency
- Update docker-compose.yml
- Remove worker service

### Phase 3: Cleanup
- Remove ARQ-related code
- Update documentation

---

## 14. Architecture Decisions

1. **Progress tracking during resume**:
    - **Decision**: Track accurate progress.
    - **Rationale**: `yt-dlp` output allows calculating percentage relative to the *full* file size. Showing "60%" immediately upon resume instills confidence that the resume worked, whereas starting visual progress from "0%" feels broken.

2. **Multi-pod job visibility**:
    - **Decision**: No.
    - **Rationale**: The client/user shouldn't care which pod is downloading the file. That is an implementation detail. The API should remain abstract.

3. **Resource limits per worker**:
    - **Decision**: Manage limits **Per Pod**.
    - **Rationale**: Managing CGroup limits per subprocess in Python is complex and brittle. We will rely on K8s Pod limits. If a worker goes rogue, it hits the Pod limit, K8s OOM kills the pod, and the existing recovery logic moves the job to another pod.

---

## 15. References

- [yt-dlp Resume Documentation](https://github.com/yt-dlp/yt-dlp#filesystem-options)
- Existing tickets: T005-arq-worker.md, T019-websocket-progress.md, T026-monolith-merge
- Current implementation: `backend/app/worker.py`, `backend/app/tasks/download.py`

---

# Appendix A: Infrastructure Configuration (Out of Scope)

> [!IMPORTANT]
> The following configurations are **external infrastructure** that must be set up separately from the application. They are documented here for reference but are **NOT part of this ticket's implementation scope**.

## A.1 Prometheus Setup

Prometheus must be deployed separately (via Helm chart, operator, or manual deployment) and configured to scrape the VidKeep `/metrics` endpoint.

## A.2 Kubernetes ServiceMonitor

If using Prometheus Operator in Kubernetes, create this ServiceMonitor resource:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: vidkeep
  labels:
    app: vidkeep
spec:
  selector:
    matchLabels:
      app: vidkeep
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
```

## A.3 Grafana Dashboard Queries

Example PromQL queries for building Grafana dashboards:

```promql
# P95 download duration over last hour
histogram_quantile(0.95, rate(vidkeep_download_duration_seconds_bucket[1h]))

# P95 muxing duration (identifies CPU bottleneck)
histogram_quantile(0.95, rate(vidkeep_muxing_duration_seconds_bucket[1h]))

# Average memory per worker
avg(vidkeep_worker_memory_mb) by (worker_id)

# Suggested CPU allocation based on P99
ceil(histogram_quantile(0.99, rate(vidkeep_worker_cpu_percent[24h])) / 100)

# Download throughput
rate(vidkeep_downloads_total[5m])

# Average download speed
histogram_quantile(0.5, rate(vidkeep_download_speed_mbps_bucket[1h]))
```

## A.4 Alertmanager Rules (Optional)

Example alert rules for worker health:

```yaml
groups:
  - name: vidkeep
    rules:
      - alert: VidKeepNoActiveWorkers
        expr: vidkeep_active_workers == 0
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "No active VidKeep workers"
          
      - alert: VidKeepHighFailureRate
        expr: rate(vidkeep_downloads_total{status="failed"}[5m]) > 0.1
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "High download failure rate"
```

