# T005: ARQ Worker Setup

## 1. Description

Set up ARQ (Async Redis Queue) for background task processing. This ticket configures the worker infrastructure that will handle video downloads asynchronously, preventing long-running downloads from blocking the API.

**Why**: Video downloads can take minutes to complete. ARQ enables queuing download jobs and processing them in the background while immediately returning a response to the user.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  worker.py
  tasks/
    __init__.py
    download.py
```

### Worker Configuration (worker.py)

```python
from arq import create_pool
from arq.connections import RedisSettings
from app.config import settings
from app.tasks.download import download_video

async def startup(ctx):
    """Called when worker starts"""
    ctx["db"] = ...  # Initialize database session if needed
    print("Worker started")

async def shutdown(ctx):
    """Called when worker shuts down"""
    print("Worker shutdown")

class WorkerSettings:
    redis_settings = RedisSettings.from_dsn(settings.redis_url)

    functions = [download_video]

    on_startup = startup
    on_shutdown = shutdown

    # Job settings
    max_jobs = 10
    job_timeout = 3600  # 1 hour max per download
    keep_result = 3600  # Keep results for 1 hour

    # Retry settings
    max_tries = 3
    retry_delay = 60  # Retry after 1 minute
```

### Download Task Placeholder (tasks/download.py)

```python
from arq import Retry
import asyncio

async def download_video(ctx, video_id: str, url: str):
    """
    Download a video from YouTube using yt-dlp.

    Args:
        ctx: ARQ context
        video_id: YouTube video ID
        url: Full YouTube URL

    This is a placeholder that will be fully implemented in T006.
    """
    print(f"Download task received: {video_id}")

    # Placeholder - actual implementation in T006
    await asyncio.sleep(1)

    return {"video_id": video_id, "status": "queued"}
```

### ARQ Client Helper (worker.py addition)

```python
from arq import ArqRedis

_arq_pool: ArqRedis | None = None

async def get_arq_pool() -> ArqRedis:
    global _arq_pool
    if _arq_pool is None:
        _arq_pool = await create_pool(
            RedisSettings.from_dsn(settings.redis_url)
        )
    return _arq_pool

async def enqueue_download(video_id: str, url: str) -> str:
    """Queue a download job and return the job ID"""
    pool = await get_arq_pool()
    job = await pool.enqueue_job("download_video", video_id, url)
    return job.job_id
```

### Requirements Update

```
arq>=0.25
```

### Docker Compose Worker Command

Verify worker service in docker-compose.yml:
```yaml
worker:
  build: ./backend
  command: arq app.worker.WorkerSettings
  volumes:
    - vidkeep_data:/data
  env_file:
    - .env
  depends_on:
    postgres:
      condition: service_healthy
    redis:
      condition: service_healthy
```

### Dependencies

- T004 (Redis connection)

## 3. Implementation Verification

- [ ] Worker starts without errors: `arq app.worker.WorkerSettings`
- [ ] Worker connects to Redis successfully
- [ ] Jobs can be enqueued from API
- [ ] Jobs are picked up by worker
- [ ] Job results are stored in Redis

### Tests to Write

```python
# tests/test_worker.py
import pytest
from arq import ArqRedis
from app.worker import get_arq_pool, enqueue_download

@pytest.mark.asyncio
async def test_arq_pool_connection():
    pool = await get_arq_pool()
    assert isinstance(pool, ArqRedis)

@pytest.mark.asyncio
async def test_enqueue_job():
    job_id = await enqueue_download("test123", "https://youtube.com/watch?v=test123")
    assert job_id is not None
    assert isinstance(job_id, str)
```

### Commands to Verify

```bash
# Start worker
docker-compose up worker

# Check worker logs
docker-compose logs -f worker

# Verify worker is connected to Redis
docker-compose exec redis redis-cli KEYS "*arq*"
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Created app/tasks/__init__.py | Success | Tasks package initialized |
| 2025-12-28 | Created app/tasks/download.py | Success | Placeholder download_video task |
| 2025-12-28 | Created app/worker.py | Success | WorkerSettings, get_arq_pool, enqueue_download |

## 5. Comments

- Worker uses same Docker image as API, just different command
- `job_timeout` is 1 hour to accommodate large video downloads
- `max_tries=3` provides automatic retry on transient failures
- The download_video function is a placeholder; T006 implements the actual yt-dlp logic
- ARQ pool is global to avoid creating multiple connections
- WorkerSettings class name must match docker-compose command path
- Next ticket (T006) will implement the actual yt-dlp download logic
