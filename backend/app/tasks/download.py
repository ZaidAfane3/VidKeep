import asyncio
import json
import logging
import time
import redis as sync_redis

from app.services.ytdlp import YTDLPService, extract_metadata
from app.services.thumbnail import ThumbnailService
from app.services.metrics import worker_metrics
from app.database import async_session
from app.models import Video
from app.redis import get_redis
from app.config import settings


logger = logging.getLogger(__name__)


class DownloadCancelledException(Exception):
    """Raised when a download is cancelled by user."""
    pass


# Sync Redis client for use in progress hook (sync context)
def get_sync_redis():
    """Get a synchronous Redis connection for use in sync callbacks."""
    return sync_redis.from_url(settings.redis_url, decode_responses=True)


async def cleanup_partial_files(video_id: str, reason: str = "cancelled"):
    """Clean up partial download files for a cancelled/failed video."""
    ytdlp = YTDLPService()
    ytdlp.cleanup_partial_files(video_id, reason)


async def download_video_task(video_id: str, url: str):
    """
    Download a video from YouTube using yt-dlp (T028 embedded worker version).

    Updates video status and publishes progress to Redis.
    Processes thumbnail and extracts metadata.
    Supports cancellation via Redis flag.
    Supports resume from partial files.
    """
    redis = await get_redis()
    ytdlp = YTDLPService()
    thumbnail_service = ThumbnailService()

    # Check for cancellation flag before starting
    cancel_flag = await redis.get(f"cancel:{video_id}")
    if cancel_flag:
        await redis.delete(f"cancel:{video_id}")
        await cleanup_partial_files(video_id, "cancelled")
        return {"status": "cancelled", "video_id": video_id}

    # Capture the event loop for use in sync callback
    loop = asyncio.get_running_loop()

    # Get sync Redis for progress hook (runs in thread)
    sync_redis_client = get_sync_redis()

    # Track download start time for metrics
    download_start_time = time.time()

    # Check for resume from partial file (T028)
    partial_path = ytdlp.get_partial_path(video_id)
    is_resuming = partial_path is not None
    resumed_bytes = 0
    
    if is_resuming:
        try:
            resumed_bytes = partial_path.stat().st_size
            logger.info(f"Resuming download for {video_id} from {resumed_bytes} bytes")
        except OSError:
            is_resuming = False
    
    # Update status and notify frontend
    status = "resuming" if is_resuming else "downloading"
    async with async_session() as db:
        video = await db.get(Video, video_id)
        if video:
            video.status = status
            await db.commit()

    # Notify frontend that download has started (with resume info if applicable)
    status_message = {
        "type": "status",
        "status": status,
        "video_id": video_id
    }
    if is_resuming:
        status_message["resumed_bytes"] = resumed_bytes
    
    await redis.publish(f"progress:{video_id}", json.dumps(status_message))

    try:
        # Track last cancellation check time to avoid hammering Redis
        last_cancel_check = [0]  # Use list for mutable closure

        # Track progress across multiple streams (video + audio)
        # yt-dlp downloads video and audio separately, then merges them
        stream_totals = {}  # {filename: total_bytes} - track each stream's size
        completed_bytes = [resumed_bytes]  # Include resumed bytes in total
        last_percent_sent = [0]  # Avoid sending duplicate/regressing percentages
        current_stream = [None]  # Track current stream filename

        # Progress callback for Redis pub/sub (called from sync context)
        def progress_hook(d):
            import time

            if d['status'] == 'downloading':
                filename = d.get('filename', 'unknown')
                # Use 'or 0' to handle None values from yt-dlp during post-processing
                total = d.get('total_bytes') or d.get('total_bytes_estimate') or 0
                downloaded = d.get('downloaded_bytes') or 0

                # Skip if no valid data (happens during post-processing/muxing)
                if total <= 0:
                    return

                # Detect stream change - if filename changed, previous stream completed
                if current_stream[0] is not None and current_stream[0] != filename:
                    # Previous stream finished, add its total to completed bytes
                    if current_stream[0] in stream_totals:
                        completed_bytes[0] += stream_totals[current_stream[0]]

                current_stream[0] = filename

                # Track this stream's total size
                stream_totals[filename] = total

                # Calculate combined progress: completed streams + current progress
                total_downloaded = completed_bytes[0] + downloaded
                total_size = completed_bytes[0] + total

                # If we have info about other pending streams, include them
                # (yt-dlp may have already informed us about audio stream size)
                for fn, size in stream_totals.items():
                    if fn != filename and fn not in [current_stream[0]]:
                        total_size += size

                percent = int((total_downloaded / total_size * 100)) if total_size > 0 else 0

                # Cap at 99% - only completion message should show 100%
                percent = min(percent, 99)

                # Don't send if percentage hasn't changed or regressed
                if percent <= last_percent_sent[0] and last_percent_sent[0] > 0:
                    # Still check for cancellation
                    current_time = time.time()
                    if current_time - last_cancel_check[0] >= 1.0:
                        last_cancel_check[0] = current_time
                        try:
                            if sync_redis_client.get(f"cancel:{video_id}"):
                                sync_redis_client.delete(f"cancel:{video_id}")
                                raise DownloadCancelledException("Download cancelled by user")
                        except sync_redis.exceptions.ConnectionError:
                            pass
                    return

                last_percent_sent[0] = percent

                # Check for cancellation every ~1 second (based on progress updates)
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
                            "downloaded_bytes": total_downloaded,
                            "total_bytes": total_size
                        })
                    ),
                    loop
                )

            elif d['status'] == 'finished':
                # Stream finished - mark it as completed
                filename = d.get('filename', 'unknown')
                total = d.get('total_bytes') or d.get('downloaded_bytes', 0)
                if total > 0:
                    stream_totals[filename] = total

        # Download the video (yt-dlp handles resume automatically with --continue)
        info = await ytdlp.download(url, video_id, progress_hook)

        # Check for cancellation after download (in case it completed during cancel request)
        cancel_flag = await redis.get(f"cancel:{video_id}")
        if cancel_flag:
            await redis.delete(f"cancel:{video_id}")
            await cleanup_partial_files(video_id, "cancelled")
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
                # Clear job tracking fields
                video.claimed_by = None
                video.claimed_at = None
                await db.commit()

        # Notify frontend that download is complete
        await redis.publish(
            f"progress:{video_id}",
            json.dumps({
                "type": "completion",
                "status": "complete",
                "video_id": video_id
            })
        )

        # Record successful download metrics
        download_duration = time.time() - download_start_time
        file_size_mb = (file_size / 1024 / 1024) if file_size else 0
        download_speed = (file_size_mb / download_duration) if download_duration > 0 else 0
        worker_metrics.record_download_complete(
            quality="1080p",  # Default quality
            duration=download_duration,
            speed_mbps=download_speed * 8  # Convert MB/s to Mbps
        )

        return {"status": "complete", "video_id": video_id}

    except DownloadCancelledException:
        # Clean up partial files
        await cleanup_partial_files(video_id, "cancelled")

        # Update database with cancelled status (may already be set by cancel endpoint)
        async with async_session() as db:
            video = await db.get(Video, video_id)
            if video and video.status != "cancelled":
                video.status = "cancelled"
                video.error_message = "Download cancelled by user"
                video.claimed_by = None
                video.claimed_at = None
                await db.commit()

        # Notify frontend that download was cancelled
        await redis.publish(
            f"progress:{video_id}",
            json.dumps({
                "type": "completion",
                "status": "cancelled",
                "video_id": video_id
            })
        )

        # Record cancelled metric
        worker_metrics.record_cancelled()

        return {"status": "cancelled", "video_id": video_id}

    except Exception as e:
        logger.error(f"Download failed for {video_id}: {e}")
        
        # Update database with failure
        async with async_session() as db:
            video = await db.get(Video, video_id)
            if video:
                video.status = "failed"
                video.error_message = str(e)[:500]  # Truncate long errors
                video.claimed_by = None
                video.claimed_at = None
                await db.commit()

        # Notify frontend that download failed
        await redis.publish(
            f"progress:{video_id}",
            json.dumps({
                "type": "completion",
                "status": "failed",
                "video_id": video_id
            })
        )

        # Record failure metric
        worker_metrics.record_failure()

        raise  # Re-raise for worker manager logging
    finally:
        # Close sync Redis connection
        sync_redis_client.close()


# Legacy function for backwards compatibility during migration
async def download_video(ctx, video_id: str, url: str):
    """Legacy ARQ wrapper - redirects to new task function."""
    return await download_video_task(video_id, url)
