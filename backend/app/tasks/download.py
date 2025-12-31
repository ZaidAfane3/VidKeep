import asyncio
import json
import redis as sync_redis

from app.services.ytdlp import YTDLPService, extract_metadata
from app.services.thumbnail import ThumbnailService
from app.database import async_session
from app.models import Video
from app.redis import get_redis
from app.config import settings


class DownloadCancelledException(Exception):
    """Raised when a download is cancelled by user."""
    pass


# Sync Redis client for use in progress hook (sync context)
def get_sync_redis():
    """Get a synchronous Redis connection for use in sync callbacks."""
    return sync_redis.from_url(settings.redis_url, decode_responses=True)


async def cleanup_partial_files(video_id: str):
    """Clean up partial download files for a cancelled/failed video."""
    ytdlp = YTDLPService()
    ytdlp.cleanup_partial_files(video_id)


async def download_video(ctx, video_id: str, url: str):
    """
    Download a video from YouTube using yt-dlp.

    Updates video status and publishes progress to Redis.
    Processes thumbnail and extracts metadata.
    Supports cancellation via Redis flag.
    """
    redis = await get_redis()
    ytdlp = YTDLPService()
    thumbnail_service = ThumbnailService()

    # Check for cancellation flag before starting
    cancel_flag = await redis.get(f"cancel:{video_id}")
    if cancel_flag:
        await redis.delete(f"cancel:{video_id}")
        # Clean up any partial files
        await cleanup_partial_files(video_id)
        return {"status": "cancelled", "video_id": video_id}

    # Capture the event loop for use in sync callback
    loop = asyncio.get_running_loop()

    # Get sync Redis for progress hook (runs in thread)
    sync_redis_client = get_sync_redis()

    # Clean up any partial files from previous attempts (for retries)
    ytdlp.cleanup_partial_files(video_id)

    # Update status to downloading
    async with async_session() as db:
        video = await db.get(Video, video_id)
        if video:
            video.status = "downloading"
            await db.commit()

    try:
        # Track last cancellation check time to avoid hammering Redis
        last_cancel_check = [0]  # Use list for mutable closure

        # Progress callback for Redis pub/sub (called from sync context)
        def progress_hook(d):
            if d['status'] == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                downloaded = d.get('downloaded_bytes', 0)
                percent = int((downloaded / total * 100)) if total > 0 else 0

                # Check for cancellation every ~1 second (based on progress updates)
                import time
                current_time = time.time()
                if current_time - last_cancel_check[0] >= 1.0:
                    last_cancel_check[0] = current_time
                    try:
                        if sync_redis_client.get(f"cancel:{video_id}"):
                            sync_redis_client.delete(f"cancel:{video_id}")
                            raise DownloadCancelledException("Download cancelled by user")
                    except sync_redis.exceptions.ConnectionError:
                        pass  # Ignore Redis connection errors during progress

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

        # Check for cancellation after download (in case it completed during cancel request)
        cancel_flag = await redis.get(f"cancel:{video_id}")
        if cancel_flag:
            await redis.delete(f"cancel:{video_id}")
            await cleanup_partial_files(video_id)
            return {"status": "cancelled", "video_id": video_id}

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

    except DownloadCancelledException:
        # Clean up partial files
        await cleanup_partial_files(video_id)

        # Update database with cancelled status (may already be set by cancel endpoint)
        async with async_session() as db:
            video = await db.get(Video, video_id)
            if video and video.status != "cancelled":
                video.status = "cancelled"
                video.error_message = "Download cancelled by user"
                await db.commit()

        return {"status": "cancelled", "video_id": video_id}

    except Exception as e:
        # Update database with failure
        async with async_session() as db:
            video = await db.get(Video, video_id)
            if video:
                video.status = "failed"
                video.error_message = str(e)[:500]  # Truncate long errors
                await db.commit()

        raise  # Re-raise for ARQ retry logic
    finally:
        # Close sync Redis connection
        sync_redis_client.close()
