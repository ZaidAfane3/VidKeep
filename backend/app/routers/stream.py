from pathlib import Path

from fastapi import APIRouter, Depends, Request, HTTPException, status
from fastapi.responses import StreamingResponse, FileResponse, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.database import get_db
from app.models import Video
from app.services.streaming import StreamingService

# Placeholder SVG for videos without thumbnails
PLACEHOLDER_SVG = '''<svg xmlns="http://www.w3.org/2000/svg" width="640" height="360" viewBox="0 0 640 360">
  <rect fill="#1a1a2e" width="640" height="360"/>
  <text x="50%" y="50%" fill="#4a4a6a" font-family="sans-serif" font-size="24"
        text-anchor="middle" dominant-baseline="middle">No Thumbnail</text>
</svg>'''

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


@router.get("/thumbnail/{video_id}")
async def get_thumbnail(
    video_id: str,
    fallback: bool = True,
    db: AsyncSession = Depends(get_db)
):
    """
    Serve thumbnail image for a video.

    Returns JPG image with caching headers.
    Thumbnails are available even for pending/downloading videos
    (extracted during metadata fetch).

    Args:
        video_id: The video ID
        fallback: If True, return placeholder SVG when thumbnail missing
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

    return FileResponse(
        path=thumbnail_path,
        media_type="image/jpeg",
        headers={
            "Cache-Control": "public, max-age=86400",
            "Content-Disposition": f'inline; filename="{video_id}.jpg"'
        }
    )
