# T009: Video Streaming with Range Support

## 1. Description

Implement the GET `/api/stream/{video_id}` endpoint with proper HTTP Range request support. This enables video seeking in browsers and ensures smooth playback of locally stored videos.

**Why**: Range requests are essential for video streaming. Without them, users would have to download the entire file before playing, and seeking wouldn't work.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  routers/
    stream.py
  services/
    streaming.py
  main.py (add router)
```

### Streaming Service (services/streaming.py)

```python
from pathlib import Path
from fastapi import HTTPException, status
from fastapi.responses import StreamingResponse
from typing import Generator
import os
from app.config import settings

CHUNK_SIZE = 1024 * 1024  # 1MB chunks

class StreamingService:
    def __init__(self, data_path: str = None):
        self.data_path = Path(data_path or settings.data_path)
        self.videos_path = self.data_path / "videos"

    def get_video_path(self, video_id: str) -> Path:
        """Get path to video file, raise 404 if not found"""
        path = self.videos_path / f"{video_id}.mp4"
        if not path.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Video file not found: {video_id}"
            )
        return path

    def get_file_size(self, path: Path) -> int:
        """Get file size in bytes"""
        return path.stat().st_size

    def stream_file(
        self,
        path: Path,
        start: int = 0,
        end: int = None,
        chunk_size: int = CHUNK_SIZE
    ) -> Generator[bytes, None, None]:
        """
        Stream file contents as a generator.

        Args:
            path: Path to file
            start: Start byte position
            end: End byte position (inclusive)
            chunk_size: Size of each chunk
        """
        file_size = self.get_file_size(path)
        end = end or file_size - 1

        with open(path, 'rb') as f:
            f.seek(start)
            remaining = end - start + 1

            while remaining > 0:
                read_size = min(chunk_size, remaining)
                data = f.read(read_size)
                if not data:
                    break
                remaining -= len(data)
                yield data
```

### Stream Router (routers/stream.py)

```python
from fastapi import APIRouter, Depends, Request, HTTPException, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.dependencies import get_db
from app.models import Video
from app.services.streaming import StreamingService

router = APIRouter(prefix="/api", tags=["Streaming"])

def parse_range_header(range_header: str, file_size: int) -> tuple[int, int]:
    """
    Parse HTTP Range header.

    Returns (start, end) byte positions.
    """
    if not range_header or not range_header.startswith('bytes='):
        return 0, file_size - 1

    range_spec = range_header[6:]  # Remove 'bytes='

    if range_spec.startswith('-'):
        # bytes=-500 means last 500 bytes
        suffix_length = int(range_spec[1:])
        start = max(0, file_size - suffix_length)
        end = file_size - 1
    elif range_spec.endswith('-'):
        # bytes=500- means from 500 to end
        start = int(range_spec[:-1])
        end = file_size - 1
    else:
        # bytes=500-999
        parts = range_spec.split('-')
        start = int(parts[0])
        end = int(parts[1]) if parts[1] else file_size - 1

    # Clamp to valid range
    start = max(0, min(start, file_size - 1))
    end = max(start, min(end, file_size - 1))

    return start, end

@router.get("/stream/{video_id}")
async def stream_video(
    video_id: str,
    request: Request,
    db: AsyncSession = Depends(get_db)
):
    """
    Stream video with Range request support.

    Supports:
    - Full file download (no Range header)
    - Partial content (Range header for seeking)
    """
    # Verify video exists in database
    video = await db.get(Video, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Video not found"
        )

    if video.status != "complete":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Video download not complete"
        )

    streaming = StreamingService()
    path = streaming.get_video_path(video_id)
    file_size = streaming.get_file_size(path)

    # Parse Range header
    range_header = request.headers.get('range')
    start, end = parse_range_header(range_header, file_size)
    content_length = end - start + 1

    # Common headers
    headers = {
        'Content-Type': 'video/mp4',
        'Accept-Ranges': 'bytes',
        'Content-Length': str(content_length),
    }

    if range_header:
        # Partial content response
        headers['Content-Range'] = f'bytes {start}-{end}/{file_size}'
        return StreamingResponse(
            streaming.stream_file(path, start, end),
            status_code=status.HTTP_206_PARTIAL_CONTENT,
            headers=headers,
            media_type='video/mp4'
        )
    else:
        # Full content response
        return StreamingResponse(
            streaming.stream_file(path),
            status_code=status.HTTP_200_OK,
            headers=headers,
            media_type='video/mp4'
        )
```

### Update main.py

```python
from app.routers import health, videos, stream

app.include_router(stream.router)
```

### Dependencies

- T001 (Data volume)
- T003 (FastAPI app)
- T006 (Videos stored in /data/videos)

## 3. Implementation Verification

- [ ] Streaming endpoint returns video content
- [ ] `Accept-Ranges: bytes` header is present
- [ ] Range requests return 206 Partial Content
- [ ] `Content-Range` header is correct for partial responses
- [ ] Video seeking works in browser
- [ ] Full download works without Range header
- [ ] 404 returned for missing videos
- [ ] 404 returned for incomplete downloads

### Tests to Write

```python
# tests/test_streaming.py
import pytest
from app.services.streaming import StreamingService
from app.routers.stream import parse_range_header

def test_parse_range_header_full():
    start, end = parse_range_header("bytes=0-999", 5000)
    assert start == 0
    assert end == 999

def test_parse_range_header_open_end():
    start, end = parse_range_header("bytes=1000-", 5000)
    assert start == 1000
    assert end == 4999

def test_parse_range_header_suffix():
    start, end = parse_range_header("bytes=-500", 5000)
    assert start == 4500
    assert end == 4999

def test_parse_range_header_none():
    start, end = parse_range_header(None, 5000)
    assert start == 0
    assert end == 4999

# Integration test
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_stream_missing_video():
    response = client.get("/api/stream/nonexistent")
    assert response.status_code == 404
```

### Commands to Verify

```bash
# Test streaming endpoint (full download)
curl -I http://localhost:8000/api/stream/VIDEO_ID

# Test Range request (first 1MB)
curl -I -H "Range: bytes=0-1048575" http://localhost:8000/api/stream/VIDEO_ID

# Verify Accept-Ranges header
curl -I http://localhost:8000/api/stream/VIDEO_ID | grep -i accept-ranges

# Test in browser (open and try seeking)
open http://localhost:8000/api/stream/VIDEO_ID
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|

## 5. Comments

- 1MB chunks balance memory usage and network efficiency
- Range header parsing handles all standard formats (start-end, start-, -suffix)
- 206 Partial Content is returned for Range requests, 200 OK otherwise
- Content-Type is always video/mp4 (our standard format)
- Video must have status=complete to be streamable
- StreamingResponse uses a generator to avoid loading entire file in memory
- Next ticket (T010) implements thumbnail serving
