# T008: Ingest API Endpoint

## 1. Description

Implement the POST `/api/videos/ingest` endpoint that accepts a YouTube URL, validates it, extracts initial metadata, creates a database record, and queues the download job. This is the primary entry point for adding videos to VidKeep.

**Why**: Users need a simple way to submit YouTube URLs. The ingest endpoint orchestrates the entire download workflow from URL submission to queuing.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  routers/
    videos.py
  services/
    url_validator.py
  main.py (add router)
```

### URL Validator Service (services/url_validator.py)

```python
import re
from typing import Optional

# YouTube URL patterns
YOUTUBE_PATTERNS = [
    # Standard watch URLs
    r'(?:https?://)?(?:www\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})',
    # Shortened URLs
    r'(?:https?://)?youtu\.be/([a-zA-Z0-9_-]{11})',
    # Embed URLs
    r'(?:https?://)?(?:www\.)?youtube\.com/embed/([a-zA-Z0-9_-]{11})',
    # Mobile URLs
    r'(?:https?://)?m\.youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})',
]

def extract_video_id(url: str) -> Optional[str]:
    """
    Extract YouTube video ID from various URL formats.

    Returns video ID (11 chars) or None if invalid.
    """
    for pattern in YOUTUBE_PATTERNS:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None

def validate_youtube_url(url: str) -> tuple[bool, str, Optional[str]]:
    """
    Validate a YouTube URL.

    Returns:
        (is_valid, message, video_id)
    """
    if not url:
        return False, "URL is required", None

    video_id = extract_video_id(url)
    if not video_id:
        return False, "Invalid YouTube URL format", None

    if len(video_id) != 11:
        return False, "Invalid video ID length", None

    return True, "Valid YouTube URL", video_id
```

### Videos Router (routers/videos.py)

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.dependencies import get_db
from app.schemas import VideoCreate, VideoResponse, IngestResponse
from app.models import Video
from app.services.url_validator import validate_youtube_url, extract_video_id
from app.services.ytdlp import YTDLPService
from app.worker import enqueue_download

router = APIRouter(prefix="/api/videos", tags=["Videos"])

@router.post("/ingest", response_model=IngestResponse, status_code=status.HTTP_202_ACCEPTED)
async def ingest_video(
    request: VideoCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    Submit a YouTube URL for download.

    1. Validates the URL format
    2. Checks for duplicate video IDs
    3. Fetches initial metadata from YouTube
    4. Creates database record with status=pending
    5. Queues download job
    """
    # Validate URL
    is_valid, message, video_id = validate_youtube_url(request.url)
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )

    # Check for existing video
    existing = await db.get(Video, video_id)
    if existing:
        if existing.status == "complete":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Video {video_id} already exists"
            )
        elif existing.status in ("pending", "downloading"):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Video {video_id} is already being processed"
            )
        else:  # failed - allow retry
            existing.status = "pending"
            existing.error_message = None
            await db.commit()
            await enqueue_download(video_id, request.url)
            return IngestResponse(
                video_id=video_id,
                message="Retry queued for previously failed download"
            )

    # Fetch initial metadata (quick, no download)
    ytdlp = YTDLPService()
    try:
        info = await ytdlp.extract_info(request.url)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Failed to fetch video info: {str(e)}"
        )

    # Create database record
    video = Video(
        video_id=video_id,
        title=info.get('title', 'Untitled'),
        channel_name=info.get('channel') or info.get('uploader') or 'Unknown',
        channel_id=info.get('channel_id'),
        duration_seconds=info.get('duration'),
        status="pending"
    )

    db.add(video)
    await db.commit()

    # Queue download job
    await enqueue_download(video_id, request.url)

    return IngestResponse(
        video_id=video_id,
        message="Video queued for download"
    )
```

### Update main.py

```python
from app.routers import health, videos

app.include_router(health.router)
app.include_router(videos.router)
```

### Dependencies

- T005 (ARQ worker/enqueue)
- T006 (yt-dlp service)
- T003 (Schemas, FastAPI app)

## 3. Implementation Verification

- [ ] Valid YouTube URLs are accepted (watch, youtu.be, embed, mobile)
- [ ] Invalid URLs return 400 Bad Request
- [ ] Duplicate complete videos return 409 Conflict
- [ ] Failed videos can be retried
- [ ] Metadata is fetched before queuing
- [ ] Database record is created with status=pending
- [ ] Download job is queued in ARQ
- [ ] Returns 202 Accepted with video_id

### Tests to Write

```python
# tests/test_url_validator.py
from app.services.url_validator import extract_video_id, validate_youtube_url

def test_extract_video_id_standard():
    assert extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ") == "dQw4w9WgXcQ"

def test_extract_video_id_short():
    assert extract_video_id("https://youtu.be/dQw4w9WgXcQ") == "dQw4w9WgXcQ"

def test_extract_video_id_embed():
    assert extract_video_id("https://www.youtube.com/embed/dQw4w9WgXcQ") == "dQw4w9WgXcQ"

def test_extract_video_id_mobile():
    assert extract_video_id("https://m.youtube.com/watch?v=dQw4w9WgXcQ") == "dQw4w9WgXcQ"

def test_extract_video_id_with_params():
    assert extract_video_id("https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42") == "dQw4w9WgXcQ"

def test_validate_youtube_url_invalid():
    is_valid, msg, vid = validate_youtube_url("https://vimeo.com/123")
    assert not is_valid

# tests/test_ingest.py
from fastapi.testclient import TestClient
from app.main import app
import pytest

client = TestClient(app)

def test_ingest_invalid_url():
    response = client.post("/api/videos/ingest", json={"url": "not-a-url"})
    assert response.status_code == 400

def test_ingest_non_youtube_url():
    response = client.post("/api/videos/ingest", json={"url": "https://vimeo.com/123"})
    assert response.status_code == 400
```

### Commands to Verify

```bash
# Test the ingest endpoint
curl -X POST http://localhost:8000/api/videos/ingest \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.youtube.com/watch?v=jNQXAC9IVRw"}'

# Check video was created in database
docker-compose exec postgres psql -U vidkeep -d vidkeep \
  -c "SELECT video_id, title, status FROM videos"

# Check job was queued
docker-compose exec redis redis-cli KEYS "arq:*"
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|

## 5. Comments

- Response is 202 Accepted (not 201 Created) because download happens asynchronously
- Failed videos can be retried by submitting the same URL again
- Metadata is fetched before queuing to catch invalid/unavailable videos early
- Video ID is extracted from URL, not from yt-dlp, for faster validation
- The endpoint handles various YouTube URL formats (standard, short, embed, mobile)
- Phase 2 (Ingestion Pipeline) is complete after this ticket
- Next ticket (T009) implements video streaming
