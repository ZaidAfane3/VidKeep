# T026: Evaluate Frontend/Backend Monolith Merge

> [!NOTE]
> **Status: COMPLETE** ✅ - Merged frontend and backend into single container. All QA tests passed (2026-01-07).

## 1. Overview

**Ticket Type**: Architecture Refactor  
**Priority**: Medium  
**Effort Estimate**: ~9 hours (see Section 6)  
**Depends On**: ~~T028~~ ✅ (Complete)  

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

### 2.2 Current Docker Containers (Post-T028)

| Service   | Base Image      | Purpose                             | Replicas |
|-----------|-----------------|-------------------------------------|----------|
| frontend  | nginx:alpine    | Serve React SPA, proxy to backend   | 1        |
| api       | python:3.12-slim| FastAPI REST API + WebSocket + **Embedded Workers** | 1 |
| ~~worker~~| ~~python:3.12-slim~~| ~~ARQ background job processing~~ | ~~2~~ **REMOVED in T028** |
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
- **Task Queue**: ~~ARQ~~ **Embedded WorkerManager** (T028) with Redis-based job queue
- **Dependencies**: yt-dlp, FFmpeg, redis, aiofiles, prometheus-client, psutil

### 2.5 Worker Architecture (Updated by T028)

> [!NOTE]
> **T028 completed** - Workers are now embedded in the API pod via `WorkerManager`. No separate worker containers needed.

**Key Files**:
- `backend/app/services/worker_manager.py` - WorkerManager process pool
- `backend/app/services/metrics.py` - Prometheus metrics
- `backend/app/tasks/download.py` - Download task with progress reporting

**Embedded Worker Features**:
1. **Embedded Process Pool**: Workers run within API pod, managed by `WorkerManager`
2. **Heartbeat Mechanism**: Workers send heartbeats to Redis every 30 seconds
3. **Progress Reporting**: Publishes progress via Redis pub/sub
4. **Cancellation Support**: Checks `cancel:{video_id}` flag in Redis
5. **Retry Logic**: Up to 3 retries with stale job recovery
6. **Prometheus Metrics**: `/metrics` endpoint for monitoring

**How It Works Now**:
```python
# API pushes job to Redis queue:
await redis.lpush("vidkeep:jobs:pending", video_id)

# WorkerManager claims and executes:
async def download_video_task(video_id: str, url: str):
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
from fastapi import HTTPException
from pathlib import Path

# Mount static files
STATIC_DIR = Path(__file__).parent.parent / "static"
if STATIC_DIR.exists():
    app.mount("/assets", StaticFiles(directory=STATIC_DIR / "assets"), name="assets")

# SPA catch-all route (MUST be last)
# IMPORTANT: Exclude API, WS, health, and metrics routes to preserve proper 404 handling
@app.get("/{path:path}")
async def spa_catch_all(path: str):
    # Don't catch API/WS/health/metrics routes - let them 404 properly with JSON response
    if path.startswith(("api/", "ws/", "health", "metrics")):
        raise HTTPException(status_code=404, detail="Not found")
    
    static_file = STATIC_DIR / path
    if static_file.exists() and static_file.is_file():
        return FileResponse(static_file)
    return FileResponse(STATIC_DIR / "index.html")
```

#### 4.1.2 Security Headers Middleware

> [!TIP]
> These security headers are typically handled by Ingress NGINX in Kubernetes. If using Ingress NGINX, this middleware is **optional** but provides defense-in-depth.

```python
# backend/app/main.py (optional security enhancement)
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    return response
```

> [!NOTE]
> **No code changes required for existing endpoints:**
> - Health endpoints (`/health`, `/health/ready`, `/health/db`, `/health/redis`) - already exist
> - Metrics endpoint (`/metrics`) - already added by T028

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

> [!NOTE]
> **T028 simplification**: The separate `worker` service was already removed by T028. Workers are now embedded in the API pod.

| Change | Description | Effort |
|--------|-------------|--------|
| Remove `frontend` service | No longer separate | Low |
| Update `api` service | New Dockerfile context, expose port 3001 or 80 | Low |
| ~~Keep `worker` service~~ | ~~Still needed for background jobs~~ | **Already removed by T028** |

```yaml
# docker-compose.yml (proposed after T026)
services:
  app:  # Single unified service (combines frontend + api)
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
      MAX_WORKERS: 2  # Embedded workers from T028
      POD_NAME: local-dev
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
  
  # NOTE: No separate worker service needed - embedded in app via T028
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

> [!TIP]
> **T028 Completed** - Worker architecture has already been simplified. This section now reflects the post-T028 state.

### What Stays the Same
- Redis pub/sub for WebSocket progress updates
- Heartbeat mechanism for worker health
- Job queue, retries, and cancellation

### What Was Already Changed by T028
- ~~ARQ worker process runs separately~~ → **Embedded in API pod**
- Workers managed by `WorkerManager` within the API process
- `MAX_WORKERS` env var controls concurrent downloads per pod
- Prometheus metrics at `/metrics` endpoint

> [!NOTE]
> With T028 complete, the monolith merge in T026 becomes simpler - there's no separate worker service to consider.

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

> [!TIP]
> **Kubernetes with Ingress NGINX**: If deploying to Kubernetes with Ingress NGINX, many "disadvantages" are mitigated:
> - **Gzip compression**: Handled by Ingress NGINX
> - **Static file caching**: Ingress NGINX adds `Cache-Control` headers
> - **Security headers**: Configurable via Ingress annotations
> - **API 404 handling**: Still handled at application level (Ingress proxies all traffic through)
>
> The merge simplifies the application layer while Ingress NGINX handles edge concerns.

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
