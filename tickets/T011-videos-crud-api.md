# T011: Videos CRUD API

## 1. Description

Complete the video management API with GET (list/detail), PATCH (update favorites), and DELETE endpoints. Also add the channels list endpoint for frontend filtering.

**Why**: The frontend needs full CRUD capabilities to display, filter, and manage videos. This completes the core API functionality.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  routers/
    videos.py (update from T008)
    channels.py
    queue.py
  main.py (add routers)
```

### Videos Router Updates (routers/videos.py)

```python
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, delete
from typing import Optional
from pathlib import Path
from app.dependencies import get_db
from app.schemas import VideoResponse, VideoUpdate, VideoListResponse
from app.models import Video
from app.config import settings

# Add to existing router from T008

@router.get("", response_model=VideoListResponse)
async def list_videos(
    channel: Optional[str] = Query(None, description="Filter by channel name"),
    favorites_only: bool = Query(False, description="Show only favorites"),
    status_filter: Optional[str] = Query(None, description="Filter by status"),
    db: AsyncSession = Depends(get_db)
):
    """
    List all videos with optional filters.

    Computed fields (youtube_url, download_progress) are added to response.
    """
    query = select(Video)

    if channel:
        query = query.where(Video.channel_name == channel)
    if favorites_only:
        query = query.where(Video.is_favorite == True)
    if status_filter:
        query = query.where(Video.status == status_filter)

    query = query.order_by(Video.created_at.desc())

    result = await db.execute(query)
    videos = result.scalars().all()

    # Add computed fields
    response_videos = []
    for video in videos:
        video_dict = video_to_response(video)
        response_videos.append(VideoResponse(**video_dict))

    return VideoListResponse(videos=response_videos, total=len(response_videos))


@router.get("/{video_id}", response_model=VideoResponse)
async def get_video(
    video_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Get single video by ID with computed fields."""
    video = await db.get(Video, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Video not found"
        )

    return VideoResponse(**video_to_response(video))


@router.patch("/{video_id}", response_model=VideoResponse)
async def update_video(
    video_id: str,
    update: VideoUpdate,
    db: AsyncSession = Depends(get_db)
):
    """Update video metadata (currently only favorites)."""
    video = await db.get(Video, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Video not found"
        )

    if update.is_favorite is not None:
        video.is_favorite = update.is_favorite

    await db.commit()
    await db.refresh(video)

    return VideoResponse(**video_to_response(video))


@router.delete("/{video_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_video(
    video_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Delete video record and associated files."""
    video = await db.get(Video, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Video not found"
        )

    # Delete files
    data_path = Path(settings.data_path)
    video_path = data_path / "videos" / f"{video_id}.mp4"
    thumb_path = data_path / "thumbnails" / f"{video_id}.jpg"

    if video_path.exists():
        video_path.unlink()
    if thumb_path.exists():
        thumb_path.unlink()

    # Delete database record
    await db.delete(video)
    await db.commit()

    return None


def video_to_response(video: Video) -> dict:
    """Convert Video model to response dict with computed fields."""
    return {
        "video_id": video.video_id,
        "title": video.title,
        "channel_name": video.channel_name,
        "channel_id": video.channel_id,
        "duration_seconds": video.duration_seconds,
        "upload_date": video.upload_date,
        "description": video.description,
        "is_favorite": video.is_favorite,
        "status": video.status,
        "file_size_bytes": video.file_size_bytes,
        "created_at": video.created_at,
        "error_message": video.error_message,
        # Computed fields
        "youtube_url": f"https://www.youtube.com/watch?v={video.video_id}",
        "download_progress": None,  # Will be enhanced in T019 (WebSocket)
    }
```

### Channels Router (routers/channels.py)

```python
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.dependencies import get_db
from app.models import Video

router = APIRouter(prefix="/api/channels", tags=["Channels"])

@router.get("")
async def list_channels(
    db: AsyncSession = Depends(get_db)
):
    """List unique channel names with video counts."""
    query = (
        select(
            Video.channel_name,
            func.count(Video.video_id).label("video_count")
        )
        .group_by(Video.channel_name)
        .order_by(Video.channel_name)
    )

    result = await db.execute(query)
    channels = result.all()

    return {
        "channels": [
            {"name": name, "video_count": count}
            for name, count in channels
        ]
    }
```

### Queue Status Router (routers/queue.py)

```python
from fastapi import APIRouter
from app.redis import get_redis

router = APIRouter(prefix="/api/queue", tags=["Queue"])

@router.get("/status")
async def queue_status():
    """Get current queue depth and active job count."""
    redis = await get_redis()

    # ARQ stores jobs in specific keys
    pending = await redis.llen("arq:queue")
    processing = await redis.scard("arq:in-progress")

    return {
        "pending": pending,
        "processing": processing,
        "total": pending + processing
    }
```

### Update main.py

```python
from app.routers import health, videos, stream, channels, queue

app.include_router(channels.router)
app.include_router(queue.router)
```

### Dependencies

- T003 (FastAPI, schemas)
- T002 (Database models)
- T004 (Redis)
- T008 (Ingest endpoint in same router)

## 3. Implementation Verification

- [ ] GET /api/videos returns list with computed fields
- [ ] GET /api/videos?channel=X filters by channel
- [ ] GET /api/videos?favorites_only=true filters favorites
- [ ] GET /api/videos/{id} returns single video
- [ ] PATCH /api/videos/{id} updates is_favorite
- [ ] DELETE /api/videos/{id} removes record and files
- [ ] GET /api/channels returns channel list with counts
- [ ] GET /api/queue/status returns queue depth

### Tests to Write

```python
# tests/test_videos_crud.py
from fastapi.testclient import TestClient
from app.main import app
import pytest

client = TestClient(app)

def test_list_videos_empty():
    response = client.get("/api/videos")
    assert response.status_code == 200
    assert response.json()["videos"] == []
    assert response.json()["total"] == 0

def test_get_video_not_found():
    response = client.get("/api/videos/nonexistent")
    assert response.status_code == 404

def test_delete_video_not_found():
    response = client.delete("/api/videos/nonexistent")
    assert response.status_code == 404

def test_patch_video_favorite():
    # Requires a video to exist - use fixture
    pass

# tests/test_channels.py
def test_list_channels_empty():
    response = client.get("/api/channels")
    assert response.status_code == 200
    assert response.json()["channels"] == []

# tests/test_queue.py
def test_queue_status():
    response = client.get("/api/queue/status")
    assert response.status_code == 200
    assert "pending" in response.json()
    assert "processing" in response.json()
```

### Commands to Verify

```bash
# List all videos
curl http://localhost:8000/api/videos

# Filter by channel
curl "http://localhost:8000/api/videos?channel=ChannelName"

# Filter favorites
curl "http://localhost:8000/api/videos?favorites_only=true"

# Get single video
curl http://localhost:8000/api/videos/VIDEO_ID

# Update favorite status
curl -X PATCH http://localhost:8000/api/videos/VIDEO_ID \
  -H "Content-Type: application/json" \
  -d '{"is_favorite": true}'

# Delete video
curl -X DELETE http://localhost:8000/api/videos/VIDEO_ID

# List channels
curl http://localhost:8000/api/channels

# Queue status
curl http://localhost:8000/api/queue/status
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|

## 5. Comments

- youtube_url is computed from video_id, not stored in database
- download_progress is currently null; T019 will implement real-time updates
- DELETE removes both database record and filesystem files
- Channels endpoint aggregates unique channel names with counts
- Queue status uses ARQ's Redis keys to count jobs
- Phase 3 (Streaming Service) is complete after this ticket
- Next ticket (T012) begins frontend implementation
