from fastapi import APIRouter, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime

from app.database import get_db
from app.models import Video
from app.schemas import VideoCreate, IngestResponse
from app.services.url_validator import validate_youtube_url
from app.services.ytdlp import YTDLPService
from app.worker import enqueue_download

router = APIRouter(prefix="/api/videos", tags=["videos"])


@router.post("/ingest", response_model=IngestResponse, status_code=status.HTTP_202_ACCEPTED)
async def ingest_video(
    request: VideoCreate,
    db: AsyncSession = Depends(get_db)
):
    """
    Ingest a YouTube video for download and archiving.

    Accepts a YouTube URL, validates it, checks for duplicates, fetches metadata,
    creates a database record, and queues the download.

    Returns 202 Accepted with video_id for async processing.
    """
    url = request.url.strip()

    # Validate URL format
    is_valid, message, video_id = validate_youtube_url(url)
    if not is_valid or not video_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=message
        )

    # Check for existing video
    stmt = select(Video).where(Video.video_id == video_id)
    existing_video = await db.scalar(stmt)

    if existing_video:
        # If video is complete, pending, or downloading, return conflict
        if existing_video.status in ["complete", "pending", "downloading"]:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Video already exists with status: {existing_video.status}"
            )

        # If video failed, allow retry by resetting status
        if existing_video.status == "failed":
            existing_video.status = "pending"
            existing_video.error_message = None
            await db.commit()

            # Re-queue the download
            await enqueue_download(video_id, url)

            return IngestResponse(
                video_id=video_id,
                message="Video retry queued for download"
            )

    # Fetch metadata from yt-dlp
    ytdlp = YTDLPService()
    try:
        info = await ytdlp.extract_info(url)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Failed to fetch video metadata: {str(e)}"
        )

    # Create new video record with pending status
    new_video = Video(
        video_id=video_id,
        title=info.get('title', 'Untitled'),
        channel_name=info.get('channel') or info.get('uploader') or 'Unknown',
        channel_id=info.get('channel_id'),
        duration_seconds=info.get('duration'),
        upload_date=None,  # Will be set by download task
        description=None,  # Will be set by download task
        status="pending",
        file_size_bytes=None,
        is_favorite=False,
        created_at=datetime.utcnow(),
        error_message=None
    )

    db.add(new_video)
    await db.commit()

    # Queue download job
    await enqueue_download(video_id, url)

    return IngestResponse(
        video_id=video_id,
        message="Video queued for download"
    )
