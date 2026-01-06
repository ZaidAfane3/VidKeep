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

## 10. Testing Plan

### 10.1 Unit Tests

- [ ] `WorkerManager` initialization and configuration
- [ ] Job claiming with atomic Redis operations
- [ ] Heartbeat generation and expiry
- [ ] Stale job detection logic
- [ ] Resume-aware cleanup logic

### 10.2 Integration Tests

- [ ] End-to-end download with embedded worker
- [ ] Graceful shutdown preserves job state
- [ ] Stale job recovery after simulated crash
- [ ] Resume download after worker restart (verify partial files used)
- [ ] Concurrent downloads respects `MAX_WORKERS` limit

### 10.3 Manual Testing

1. **Basic Flow**: Submit URL → verify download completes
2. **Concurrency**: Submit 3 URLs with `MAX_WORKERS=2` → verify 2 concurrent, 1 queued
3. **Crash Recovery**: Kill pod during download → verify job re-queued
4. **Resume**: Kill pod at 50% → verify new pod resumes from 50%
5. **Cancellation**: Cancel mid-download → verify cleanup works
6. **Max Retries**: Force 3 failures → verify job marked failed

---

## 11. Migration Path

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

## 12. Open Questions

1. **Progress tracking during resume**: Should we track bytes already downloaded and show accurate resume progress, or start from 0% visually?

2. **Multi-pod job visibility**: Should the API show which pod is processing a download?

3. **Resource limits per worker**: Should we add CPU/memory limits per worker process, or just per pod?

---

## 13. References

- [yt-dlp Resume Documentation](https://github.com/yt-dlp/yt-dlp#filesystem-options)
- Existing tickets: T005-arq-worker.md, T019-websocket-progress.md, T026-monolith-merge
- Current implementation: `backend/app/worker.py`, `backend/app/tasks/download.py`
