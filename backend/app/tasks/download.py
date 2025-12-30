import asyncio
import json

from app.services.ytdlp import YTDLPService, extract_metadata
from app.services.thumbnail import ThumbnailService
from app.database import async_session
from app.models import Video
from app.redis import get_redis


async def download_video(ctx, video_id: str, url: str):
    """
    Download a video from YouTube using yt-dlp.

    Updates video status and publishes progress to Redis.
    Processes thumbnail and extracts metadata.
    """
    redis = await get_redis()
    ytdlp = YTDLPService()
    thumbnail_service = ThumbnailService()

    # Capture the event loop for use in sync callback
    loop = asyncio.get_running_loop()

    # Clean up any partial files from previous attempts (for retries)
    ytdlp.cleanup_partial_files(video_id)

    # Update status to downloading
    async with async_session() as db:
        video = await db.get(Video, video_id)
        if video:
            video.status = "downloading"
            await db.commit()

    try:
        # Progress callback for Redis pub/sub (called from sync context)
        def progress_hook(d):
            if d['status'] == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                downloaded = d.get('downloaded_bytes', 0)
                percent = int((downloaded / total * 100)) if total > 0 else 0

                # Schedule coroutine from sync callback (thread-safe)
                asyncio.run_coroutine_threadsafe(
                    redis.publish(
                        f"progress:{video_id}",
                        json.dumps({
                            "percent": percent,
                            "downloaded_bytes": downloaded,
                            "total_bytes": total
                        })
                    ),
                    loop
                )

        # Download the video
        info = await ytdlp.download(url, video_id, progress_hook)

        # Process thumbnail after download
        await thumbnail_service.process_thumbnail(video_id)

        # Get file size
        video_path = ytdlp.get_video_path(video_id)
        file_size = video_path.stat().st_size if video_path.exists() else None

        # Extract and normalize metadata
        metadata = extract_metadata(info)

        # Update database with success
        async with async_session() as db:
            video = await db.get(Video, video_id)
            if video:
                video.status = "complete"
                video.file_size_bytes = file_size
                video.title = metadata['title']
                video.channel_name = metadata['channel_name']
                video.channel_id = metadata['channel_id']
                video.duration_seconds = metadata['duration_seconds']
                video.upload_date = metadata['upload_date']
                video.description = metadata['description']
                await db.commit()

        return {"status": "complete", "video_id": video_id}

    except Exception as e:
        # Update database with failure
        async with async_session() as db:
            video = await db.get(Video, video_id)
            if video:
                video.status = "failed"
                video.error_message = str(e)[:500]  # Truncate long errors
                await db.commit()

        raise  # Re-raise for ARQ retry logic
