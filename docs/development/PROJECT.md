# VidKeep: Personal Video Library & Streamer

A lightweight, self-hosted web application to manage, stream, and archive YouTube content within a home lab environment.

## 1. Project Overview

VidKeep allows users to manually ingest YouTube videos into a private storage system. It provides a clean, single-view interface to categorize videos by channel, mark favorites, and interact with media via three primary actions: streaming from the source (YouTube), streaming from the local server, or downloading for offline use.

## 2. Business Requirements

- **Centralized Library**: A single point of truth for all downloaded media.
- **Dual-Source Viewing**: Ability to watch content via the original YouTube URL or the local server copy.
- **Mobile-Friendly Downloads**: Videos stored in a universal format (MP4/H.264) allowing direct download to mobile devices for offline viewing.
- **Localized UI**: Support for RTL (Arabic) titles and metadata.
- **Dynamic Categorization**: Automatic grouping by channel name with a favorites filter.

## 3. Technical Specifications

### The Universal Format

| Component   | Specification |
| ----------- | ------------- |
| Video Codec | H.264 (AVC)   |
| Audio Codec | AAC           |
| Container   | MP4           |

**Reasoning**: Native playback support in all modern browsers (Chrome, Safari, Firefox) and mobile operating systems (iOS, Android) without requiring a transcoding engine.

### yt-dlp Format String

```bash
-f "bestvideo[vcodec^=avc1][height<=1080]+bestaudio[acodec^=mp4a]/best[ext=mp4]" --merge-output-format mp4
```

This ensures:

- H.264 video (avc1 prefix) at max 1080p
- AAC audio (mp4a prefix)
- FFmpeg muxing into MP4 container when streams are separate

### Tech Stack

| Layer      | Technology                   |
| ---------- | ---------------------------- |
| Frontend   | React (Vite) + Tailwind CSS  |
| Backend    | FastAPI (Python)             |
| Database   | PostgreSQL                   |
| Task Queue | ARQ (async Redis-based queue)|
| Storage    | Local filesystem (`/data`)   |
| Downloader | yt-dlp + FFmpeg              |

### Storage Layout

```
/data/
  videos/
    {video_id}.mp4
  thumbnails/
    {video_id}.jpg
```

Single volume mount. Flat structure per asset type for simpler maintenance and static file serving.

## 4. System Architecture

### Data Schema

The YouTube Video ID (e.g., `dQw4w9WgXcQ`) serves as the primary key to ensure data integrity and prevent duplicate downloads.

```sql
CREATE TABLE videos (
    video_id VARCHAR(11) PRIMARY KEY,
    title TEXT NOT NULL,
    channel_name VARCHAR(255) NOT NULL,
    channel_id VARCHAR(24),
    duration_seconds INTEGER,
    upload_date DATE,
    description TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'pending',  -- pending, downloading, complete, failed
    -- file_size_bytes is computed live for single-item detail views, but is persisted
    -- once status = 'complete' to support list views / sorting without filesystem access.
    file_size_bytes BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    error_message TEXT
);

CREATE INDEX idx_channel_name ON videos(channel_name);
CREATE INDEX idx_is_favorite ON videos(is_favorite);
CREATE INDEX idx_status ON videos(status);
```

### Component Architecture

1. **API Layer**: FastAPI endpoints for CRUD operations and ingestion triggers.
2. **Task Queue**: ARQ with Redis for background download jobs. Worker count configurable via `WORKER_COUNT` environment variable.
3. **Ingestion Worker**: Pulls jobs from queue, executes yt-dlp, streams progress events (e.g., via Redis/WebSocket), saves files to `/data`, and persists `file_size_bytes` when complete.
4. **Streaming Service**: Range-request enabled endpoint for seeking within video files.
5. **Frontend**: Responsive grid displaying thumbnails with real-time progress overlay for active downloads.

### Download Progress Flow

```
User submits URL
    → API validates and creates DB record (status: pending)
    → Job pushed to ARQ queue
    → Worker picks up job (status: downloading)
    → yt-dlp progress callback emits progress events (no DB write)
        → Redis pub/sub: PUBLISH progress:{video_id} {"percent": 42, "downloaded_bytes": 123, "total_bytes": 456}
    → API exposes a WebSocket endpoint that subscribes to progress:{video_id} and forwards updates to connected clients
    → API/UI exposes download_progress as a computed field (derived from Redis/in-memory live progress state)
    → Frontend subscribes (WebSocket) or polls the API for computed progress
    → Thumbnail shows percentage overlay
    → Complete: status → complete, file_size_bytes persisted
    → Failed: status → failed, error_message populated
```

### API Response Shape (Computed Fields)

The database schema stores durable metadata only. The API response includes computed/derived fields for frontend convenience:

```json
{
  "video_id": "dQw4w9WgXcQ",
  "title": "…",
  "channel_name": "…",
  "status": "downloading",
  "download_progress": 42,
  "youtube_url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "file_size_bytes": null
}
```

- `download_progress` is **computed** from the latest live progress (Redis pub/sub and/or in-memory state) and is **not** stored in Postgres.
- `youtube_url` is **reconstructed** from `video_id` (no `yt_url` column required), enabling the Phase 4 “External link” action.
- `file_size_bytes` may be computed live for single-item views; it is persisted once `status = 'complete'` to support list views / sorting.

## 5. API Endpoints

```
POST   /api/videos/ingest        - Submit YouTube URL for download
GET    /api/videos               - List all videos (filterable by channel, favorites)
GET    /api/videos/{video_id}    - Get single video metadata
PATCH  /api/videos/{video_id}    - Update favorite status
DELETE /api/videos/{video_id}    - Remove video and files

GET    /api/stream/{video_id}    - Stream video with range request support
GET    /api/thumbnail/{video_id} - Serve thumbnail image

GET    /api/channels             - List unique channels
GET    /api/queue/status         - Current queue depth and active jobs
```

## 6. Implementation Plan

### Phase 1: Foundation

- Docker Compose with PostgreSQL and Redis containers
- FastAPI skeleton with SQLAlchemy async ORM
- Database migrations (Alembic)
- `/data` volume mount configuration
- Basic health check endpoints

### Phase 2: Ingestion Pipeline

- ARQ worker setup with configurable `WORKER_COUNT`
- yt-dlp integration with progress callbacks
- Thumbnail extraction and storage
- Metadata parsing (title, channel, duration, upload date)
- Error handling for geo-blocked, age-restricted, and unavailable videos

### Phase 3: Streaming Service

- `StreamingResponse` implementation with `Range` header support
- Proper `Content-Type`, `Content-Length`, `Accept-Ranges` headers
- Static file serving for thumbnails

### Phase 4: Frontend

- Video grid with responsive CSS Grid layout
- RTL support via `dir="auto"` on text elements
- Thumbnail cards showing:
  - Download progress overlay (percentage) for active downloads
  - Error indicator for failed downloads
  - Duration badge for complete videos
- Action overlay on hover/tap:
  - External link icon → opens YouTube URL
  - Play icon → opens modal with `<video>` player pointing to local stream
  - Download icon → direct file download with `download` attribute
- Channel filter dropdown
- Favorites toggle filter
- Ingest form (URL input)

### Phase 5: Polish

- Delete confirmation modal with file cleanup
- Queue status indicator in header
- Basic error toasts
- Mobile-responsive touch targets

## 7. Environment Configuration

```env
# Database
DATABASE_URL=postgresql+asyncpg://user:pass@postgres:5432/vidkeep

# Redis (for ARQ)
REDIS_URL=redis://redis:6379

# Workers
WORKER_COUNT=2

# Storage
DATA_PATH=/data

# yt-dlp
MAX_VIDEO_HEIGHT=1080
```

## 8. Docker Compose Services

```yaml
services:
  api:
    build: ./backend
    volumes:
      - vidkeep_data:/data
    depends_on:
      - postgres
      - redis

  worker:
    build: ./backend
    command: arq app.worker.WorkerSettings
    volumes:
      - vidkeep_data:/data
    deploy:
      replicas: ${WORKER_COUNT:-2}
    depends_on:
      - postgres
      - redis

  frontend:
    build: ./frontend
    ports:
      - "3000:80"

  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  vidkeep_data:
  postgres_data:
```

## 9. Prerequisites

- Docker and Docker Compose on host machine
- FFmpeg available in backend/worker container (required by yt-dlp for stream muxing)
- Sufficient disk space for video storage (estimate ~500MB per 1080p video)
- Network access to YouTube from host

## 10. Out of Scope

- User authentication (assumes internal network / Tailscale access)
- Metadata refresh from YouTube
- Multiple video resolutions
- Subtitle extraction
- Scheduled/automatic downloads