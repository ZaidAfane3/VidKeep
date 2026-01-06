# T026: Evaluate Frontend/Backend Monolith Merge


**Note:** This ticket is archived and not to be used. The monolith merge was not pursued.

## 1. Overview

**Ticket Type**: Architecture Evaluation / Discussion  
**Priority**: To be determined  
**Effort Estimate**: See analysis below  

### Summary

Evaluate the feasibility and effort required to merge the frontend (React/Vite) and backend (FastAPI/Python) into a single monolithic application. This ticket documents the current architecture, worker approach, required changes, and trade-offs to facilitate decision-making.

---

## 2. Current Architecture Analysis

### 2.1 Service Topology

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CURRENT ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────┐      ┌──────────────┐      ┌──────────────┐             │
│   │   Frontend   │      │   Backend    │      │   Worker(s)  │             │
│   │  (nginx:80)  │─────▶│  (uvicorn)   │◀════▶│    (arq)     │             │
│   │  React/Vite  │      │  FastAPI     │      │   x2 replicas│             │
│   │   Port 3001  │      │   Port 8000  │      │              │             │
│   └──────────────┘      └──────────────┘      └──────────────┘             │
│         │                      │                     │                      │
│         │                      ▼                     │                      │
│         │               ┌──────────────┐             │                      │
│         │               │   PostgreSQL │             │                      │
│         │               │   Port 5432  │◀────────────┤                      │
│         │               └──────────────┘             │                      │
│         │                      ▲                     │                      │
│         │                      │                     │                      │
│         └──────────────────────┼─────────────────────┘                      │
│                                │                                            │
│                         ┌──────────────┐                                    │
│                         │    Redis     │                                    │
│                         │   Port 6379  │                                    │
│                         │  (pub/sub +  │                                    │
│                         │   job queue) │                                    │
│                         └──────────────┘                                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Current Docker Containers

| Service   | Base Image      | Purpose                             | Replicas |
|-----------|-----------------|-------------------------------------|----------|
| frontend  | nginx:alpine    | Serve React SPA, proxy to backend   | 1        |
| api       | python:3.12-slim| FastAPI REST API + WebSocket        | 1        |
| worker    | python:3.12-slim| ARQ background job processing       | 2        |
| postgres  | postgres:16-alpine | Primary database                 | 1        |
| redis     | redis:7-alpine  | Job queue + pub/sub                 | 1        |

### 2.3 Frontend Details

- **Framework**: React 18 with Vite
- **Styling**: Tailwind CSS
- **Language**: TypeScript
- **Build Output**: Static files (`dist/`)
- **Serving**: Nginx serves static files and proxies `/api` and `/ws` to backend
- **API Integration**: Fetch-based client (`src/api/client.ts`)
- **Real-time**: WebSocket connection at `/ws/progress/{videoId}`

### 2.4 Backend Details

- **Framework**: FastAPI (Python 3.12)
- **Database**: PostgreSQL with SQLAlchemy (async) + Alembic migrations
- **Task Queue**: ARQ (Async Redis Queue)
- **Dependencies**: yt-dlp, FFmpeg, redis, aiofiles

### 2.5 Worker Architecture

**Key Files**:
- `backend/app/worker.py` - WorkerSettings, heartbeat loop, pool management
- `backend/app/tasks/download.py` - Download task with progress reporting

**Worker Features**:
1. **Heartbeat Mechanism**: Workers send heartbeats to Redis every 30 seconds
2. **Progress Reporting**: Sync Redis client publishes progress during downloads
3. **Cancellation Support**: Checks `cancel:{video_id}` flag in Redis
4. **Retry Logic**: Up to 3 retries with 60-second delay
5. **Job Timeout**: 1 hour maximum per download

**How ARQ Works**:
```python
# API enqueues job:
await pool.enqueue_job("download_video", video_id, url)

# Worker picks up job and executes:
async def download_video(ctx, video_id: str, url: str):
    # Download logic with progress reporting
```

---

## 3. Monolith Merge Options

### Option A: FastAPI Serves Static Files (Recommended)

Merge frontend build output into FastAPI, serve static files directly.

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONOLITH ARCHITECTURE (Option A)             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────────────────────────────┐       ┌──────────────┐   │
│   │      Monolith (FastAPI)         │       │   Worker(s)  │   │
│   │  ┌────────────┬───────────────┐ │       │    (arq)     │   │
│   │  │  Static    │    API        │ │◀═════▶│              │   │
│   │  │  Files     │  Routes       │ │       │              │   │
│   │  │  (React)   │  WebSocket    │ │       │              │   │
│   │  └────────────┴───────────────┘ │       └──────────────┘   │
│   │           Port 8000             │              │            │
│   └─────────────────────────────────┘              │            │
│                    │                               │            │
│            ┌───────┴───────┐                       │            │
│            ▼               ▼                       ▼            │
│   ┌──────────────┐  ┌──────────────┐       ┌──────────────┐    │
│   │  PostgreSQL  │  │    Redis     │◀──────│              │    │
│   └──────────────┘  └──────────────┘       └──────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Option B: In-Process Workers (Major Change)

Replace ARQ with in-process background tasks using `asyncio.create_task()`.

> [!CAUTION]
> This would fundamentally change the worker architecture and is **NOT recommended** due to:
> - Loss of job persistence across restarts
> - Loss of horizontal scaling
> - Long downloads would block the event loop
> - FFmpeg/yt-dlp blocking I/O issues

---

## 4. Required Changes for Option A (FastAPI + Static Files)

### 4.1 Backend Changes

| File | Change Type | Description | Effort |
|------|-------------|-------------|--------|
| `backend/app/main.py` | Modify | Mount static files, add catch-all route for SPA | Low |
| `backend/Dockerfile` | Modify | Multi-stage build to include frontend | Medium |
| `backend/requirements.txt` | Modify | Add `aiofiles` if not present | Low |

#### 4.1.1 Static File Serving Implementation

```python
# backend/app/main.py (additions)
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pathlib import Path

# Mount static files
STATIC_DIR = Path(__file__).parent.parent / "static"
if STATIC_DIR.exists():
    app.mount("/assets", StaticFiles(directory=STATIC_DIR / "assets"), name="assets")

# SPA catch-all route (MUST be last)
@app.get("/{path:path}")
async def spa_catch_all(path: str):
    static_file = STATIC_DIR / path
    if static_file.exists() and static_file.is_file():
        return FileResponse(static_file)
    return FileResponse(STATIC_DIR / "index.html")
```

#### 4.1.2 Unified Dockerfile

```dockerfile
# Build frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ .
RUN npm run build

# Build backend
FROM python:3.12-slim
WORKDIR /app

# Install FFmpeg
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code
COPY backend/ .

# Copy frontend build
COPY --from=frontend-builder /frontend/dist /app/static

# Expose port
EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 4.2 Frontend Changes

| File | Change Type | Description | Effort |
|------|-------------|-------------|--------|
| `frontend/src/api/client.ts` | Modify | Simplify API_BASE (same origin) | Low |
| `frontend/Dockerfile` | Delete | No longer needed | Low |
| `frontend/nginx.conf` | Delete | No longer needed | Low |

#### 4.2.1 API Client Update

```typescript
// frontend/src/api/client.ts
// Change from:
const API_BASE = '/api'
// To: (no change needed if already relative, but verify)
const API_BASE = '/api'  // Works with same origin
```

### 4.3 Docker Compose Changes

| Change | Description | Effort |
|--------|-------------|--------|
| Remove `frontend` service | No longer separate | Low |
| Update `api` service | New Dockerfile context, expose port 3001 or 80 | Low |
| Keep `worker` service | Still needed for background jobs | None |

```yaml
# docker-compose.yml (updated)
services:
  app:  # Renamed from 'api'
    build: .  # Root context for unified Dockerfile
    ports:
      - "3001:8000"  # or "80:8000"
    volumes:
      - vidkeep_data:/data
    environment:
      DATABASE_URL: postgresql+asyncpg://vidkeep:vidkeep@postgres:5432/vidkeep
      REDIS_URL: redis://redis:6379
      DATA_PATH: /data
      MAX_VIDEO_HEIGHT: 1080
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy

  worker:
    build: . 
    command: arq app.worker.WorkerSettings
    # ... (unchanged)
```

### 4.4 Project Structure Changes

```
BEFORE:                          AFTER:
VidKeep/                         VidKeep/
├── backend/                     ├── src/
│   ├── app/                     │   ├── api/          # (was backend/app/)
│   └── Dockerfile               │   └── frontend/     # (was frontend/src/)
├── frontend/                    ├── Dockerfile        # Unified
│   ├── src/                     ├── package.json      # (was frontend/)
│   └── Dockerfile               ├── requirements.txt  # (was backend/)
└── docker-compose.yml           └── docker-compose.yml
```

> [!IMPORTANT]
> The project structure change above is optional. An alternative is to keep the current folder structure and use a root-level Dockerfile that builds both.

---

## 5. Worker Architecture - What Changes

### What Stays the Same
- ARQ worker process runs separately (required for long-running downloads)
- Redis pub/sub for WebSocket progress updates
- Heartbeat mechanism for worker health
- Job queue, retries, and cancellation

### What Changes
- Worker container uses the same unified image (already does today)
- No architectural changes to worker logic

> [!NOTE]
> The ARQ worker **must remain a separate process**. Video downloads with yt-dlp and FFmpeg can take 30+ minutes and would block the FastAPI event loop if run in-process.

---

## 6. Effort Estimation

### Summary Table

| Category | Task | Effort | Complexity |
|----------|------|--------|------------|
| **Backend** | Mount static files in FastAPI | 1h | Low |
| **Backend** | Update route catch-all for SPA | 1h | Low |
| **Backend** | Unified Dockerfile | 2h | Medium |
| **Frontend** | Verify/update API client | 30m | Low |
| **Frontend** | Remove Dockerfile & nginx.conf | 15m | Low |
| **Docker** | Update docker-compose.yml | 1h | Low |
| **Testing** | Verify all functionality | 2h | Medium |
| **Docs** | Update README, deployment docs | 1h | Low |
| **Total** | | **~9 hours** | Low-Medium |

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Static file caching | Medium | Low | Add proper cache headers in FastAPI |
| Build time increase | High | Low | Use Docker layer caching |
| Single point of failure | Low | Medium | Workers still separate, can scale API |
| WebSocket routing | Low | Low | FastAPI handles WebSocket natively |

---

## 7. Trade-offs

### Advantages of Monolith

| Benefit | Description |
|---------|-------------|
| **Simpler Deployment** | One container to build/deploy (plus workers) |
| **No Nginx Layer** | Eliminate reverse proxy complexity |
| **Unified Port** | Single port serves both UI and API |
| **Smaller Image Count** | 4 images → 3 images (postgres, redis, app+worker) |
| **Development Simplicity** | Easier local development |

### Disadvantages of Monolith

| Drawback | Description |
|----------|-------------|
| **Longer Build Times** | Must rebuild frontend when backend changes (and vice versa) |
| **No Nginx Features** | Lose nginx's static file performance, gzip, caching |
| **Coupled Versioning** | Frontend and backend versions tied together |
| **Larger Container** | Node.js build deps in multi-stage, but final Python image stays slim |

---

## 8. Alternative Considerations

### Keep Current Architecture If:
- You want independent frontend/backend deployments
- You plan to add more frontend clients (mobile apps, CLI)
- You need nginx-level caching or load balancing
- Team has separate frontend/backend developers

### Merge to Monolith If:
- Simplicity is the priority (home lab use case)
- Single developer/maintainer
- No plans for additional clients
- Want fewer moving parts in docker-compose

---

## 9. Testing Plan (Post-Implementation)

If this merge is approved, verify:

- [ ] Static files served at root path `/`
- [ ] React SPA routing works (client-side routes)
- [ ] API endpoints still work at `/api/*`
- [ ] WebSocket connections work at `/ws/*`
- [ ] Video streaming works (`/api/stream/{id}`)
- [ ] Thumbnail serving works (`/api/thumbnail/{id}`)
- [ ] Workers pick up jobs as before
- [ ] Progress updates via WebSocket work
- [ ] Download cancellation works
- [ ] Mobile responsiveness preserved

---

## 10. Decision Required

Please review this evaluation and decide:

1. **Proceed with Option A** (FastAPI serves static files)?
2. **Keep current microservices architecture**?
3. **Need more information** on specific aspects?

---

## 11. References

- [FastAPI Static Files Docs](https://fastapi.tiangolo.com/tutorial/static-files/)
- Existing tickets: T005-arq-worker.md, T019-websocket-progress.md
- Current docker-compose.yml configuration
