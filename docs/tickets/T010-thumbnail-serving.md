# T010: Thumbnail Static Serving

## 1. Description

Implement the GET `/api/thumbnail/{video_id}` endpoint to serve thumbnail images. This provides a simple, cacheable endpoint for displaying video thumbnails in the frontend.

**Why**: Thumbnails are displayed prominently in the video grid. Efficient serving with proper caching headers improves page load performance.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  routers/
    stream.py (add thumbnail endpoint)
```

### Thumbnail Endpoint (routers/stream.py addition)

```python
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse
from sqlalchemy.ext.asyncio import AsyncSession
from pathlib import Path
from app.dependencies import get_db
from app.models import Video
from app.config import settings

@router.get("/thumbnail/{video_id}")
async def get_thumbnail(
    video_id: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Serve thumbnail image for a video.

    Returns JPG image with caching headers.
    Thumbnails are available even for pending/downloading videos
    (extracted during metadata fetch).
    """
    # Verify video exists in database
    video = await db.get(Video, video_id)
    if not video:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Video not found"
        )

    # Get thumbnail path
    thumbnails_path = Path(settings.data_path) / "thumbnails"
    thumbnail_path = thumbnails_path / f"{video_id}.jpg"

    if not thumbnail_path.exists():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Thumbnail not found"
        )

    return FileResponse(
        path=thumbnail_path,
        media_type="image/jpeg",
        headers={
            "Cache-Control": "public, max-age=86400",  # Cache for 24 hours
            "Content-Disposition": f'inline; filename="{video_id}.jpg"'
        }
    )
```

### Placeholder Thumbnail (Optional Enhancement)

For videos without thumbnails, serve a placeholder:

```python
from fastapi.responses import Response

PLACEHOLDER_SVG = '''
<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360">
  <rect fill="#1a1a2e" width="640" height="360"/>
  <text x="50%" y="50%" fill="#4a4a6a" font-family="sans-serif" font-size="24"
        text-anchor="middle" dominant-baseline="middle">No Thumbnail</text>
</svg>
'''

@router.get("/thumbnail/{video_id}/placeholder")
async def get_thumbnail_placeholder():
    """Return a placeholder thumbnail SVG"""
    return Response(
        content=PLACEHOLDER_SVG,
        media_type="image/svg+xml",
        headers={"Cache-Control": "public, max-age=604800"}  # 1 week
    )
```

### Alternative: Fallback in Main Endpoint

```python
@router.get("/thumbnail/{video_id}")
async def get_thumbnail(
    video_id: str,
    fallback: bool = True,  # Query param to control fallback
    db: AsyncSession = Depends(get_db)
):
    # ... existing code ...

    if not thumbnail_path.exists():
        if fallback:
            return Response(
                content=PLACEHOLDER_SVG,
                media_type="image/svg+xml",
                headers={"Cache-Control": "public, max-age=3600"}
            )
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Thumbnail not found"
        )

    # ... rest of function ...
```

### Dependencies

- T007 (Thumbnails processed and stored)
- T003 (FastAPI app)

## 3. Implementation Verification

- [x] Endpoint returns JPG image with correct Content-Type
- [x] Cache-Control header is set for 24 hours
- [x] 404 returned for missing thumbnails (without fallback)
- [x] Placeholder SVG returned for missing thumbnails (with fallback)
- [x] Thumbnails display correctly in browser
- [x] FileResponse streams efficiently (no memory bloat)

### Tests to Write

```python
# tests/test_thumbnail_endpoint.py
from fastapi.testclient import TestClient
from app.main import app
import pytest

client = TestClient(app)

def test_thumbnail_not_found():
    response = client.get("/api/thumbnail/nonexistent")
    assert response.status_code == 404

def test_thumbnail_cache_headers():
    # This test requires a video with thumbnail to exist
    # Use a fixture or mock
    pass

def test_placeholder_endpoint():
    response = client.get("/api/thumbnail/test/placeholder")
    assert response.status_code == 200
    assert response.headers["content-type"] == "image/svg+xml"
    assert "Cache-Control" in response.headers
```

### Commands to Verify

```bash
# Check thumbnail endpoint
curl -I http://localhost:8000/api/thumbnail/VIDEO_ID

# Verify Content-Type
curl -I http://localhost:8000/api/thumbnail/VIDEO_ID | grep -i content-type

# Verify Cache-Control
curl -I http://localhost:8000/api/thumbnail/VIDEO_ID | grep -i cache-control

# View thumbnail in browser
open http://localhost:8000/api/thumbnail/VIDEO_ID
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Added thumbnail endpoint to routers/stream.py | Success | GET /api/thumbnail/{video_id} with fallback support |
| 2025-12-28 | Added placeholder SVG for missing thumbnails | Success | Lightweight 300-byte SVG fallback |
| 2025-12-28 | Rebuilt Docker image | Success | API rebuilt with thumbnail endpoint |
| 2025-12-28 | Tested thumbnail for existing video | Success | Returns 200 OK with Cache-Control: 24h, image/jpeg |
| 2025-12-28 | Tested 404 for missing video | Success | Returns 404 with "Video not found" |

## 5. Comments

- FileResponse is efficient for static files (uses sendfile when possible)
- 24-hour cache is a good balance; thumbnails rarely change
- Placeholder SVG is lightweight (~300 bytes) and infinitely scalable
- Thumbnails are served even for pending/downloading videos (extracted during ingest)
- Content-Disposition is inline to allow direct viewing in browser
- Combining thumbnail endpoint with stream.py keeps related media endpoints together
- Next ticket (T011) implements the full Videos CRUD API
