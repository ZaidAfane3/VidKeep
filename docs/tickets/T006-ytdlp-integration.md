# T006: yt-dlp Integration

## 1. Description

Implement the core video download functionality using yt-dlp. This ticket handles downloading videos in the universal format (H.264/AAC/MP4), progress tracking via Redis pub/sub, and proper error handling for various failure scenarios.

**Why**: yt-dlp is the industry-standard tool for downloading YouTube videos. Proper integration ensures reliable downloads in a format compatible with all devices.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  tasks/
    download.py (update from T005 placeholder)
  services/
    __init__.py
    ytdlp.py
```

### yt-dlp Service (services/ytdlp.py)

```python
import yt_dlp
import asyncio
from pathlib import Path
from typing import Callable, Optional
from app.config import settings

# Format string from PROJECT.md
FORMAT_STRING = 'bestvideo[vcodec^=avc1][height<={max_height}]+bestaudio[acodec^=mp4a]/best[ext=mp4]'

class YTDLPService:
    def __init__(self, data_path: str = None):
        self.data_path = Path(data_path or settings.data_path)
        self.videos_path = self.data_path / "videos"
        self.thumbnails_path = self.data_path / "thumbnails"

        # Ensure directories exist
        self.videos_path.mkdir(parents=True, exist_ok=True)
        self.thumbnails_path.mkdir(parents=True, exist_ok=True)

    def get_ydl_opts(
        self,
        video_id: str,
        progress_callback: Optional[Callable] = None
    ) -> dict:
        """Build yt-dlp options dictionary"""
        opts = {
            'format': FORMAT_STRING.format(max_height=settings.max_video_height),
            'merge_output_format': 'mp4',
            'outtmpl': str(self.videos_path / f'{video_id}.mp4'),
            'writethumbnail': True,
            'thumbnails_format': 'jpg',
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
        }

        if progress_callback:
            opts['progress_hooks'] = [progress_callback]

        return opts

    async def extract_info(self, url: str) -> dict:
        """Extract video metadata without downloading"""
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
            'skip_download': True,
        }

        def _extract():
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                return ydl.extract_info(url, download=False)

        return await asyncio.to_thread(_extract)

    async def download(
        self,
        url: str,
        video_id: str,
        progress_callback: Optional[Callable] = None
    ) -> dict:
        """Download video and return result info"""
        opts = self.get_ydl_opts(video_id, progress_callback)

        def _download():
            with yt_dlp.YoutubeDL(opts) as ydl:
                return ydl.extract_info(url, download=True)

        return await asyncio.to_thread(_download)

    def get_video_path(self, video_id: str) -> Path:
        return self.videos_path / f"{video_id}.mp4"

    def get_thumbnail_path(self, video_id: str) -> Path:
        return self.thumbnails_path / f"{video_id}.jpg"
```

### Download Task Implementation (tasks/download.py)

```python
import asyncio
import json
from datetime import date
from sqlalchemy import select
from app.services.ytdlp import YTDLPService
from app.database import async_session
from app.models import Video
from app.redis import get_redis

async def download_video(ctx, video_id: str, url: str):
    """
    Download a video from YouTube using yt-dlp.

    Updates video status and publishes progress to Redis.
    """
    redis = await get_redis()
    ytdlp = YTDLPService()

    # Update status to downloading
    async with async_session() as db:
        video = await db.get(Video, video_id)
        if video:
            video.status = "downloading"
            await db.commit()

    try:
        # Progress callback for Redis pub/sub
        def progress_hook(d):
            if d['status'] == 'downloading':
                total = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                downloaded = d.get('downloaded_bytes', 0)
                percent = int((downloaded / total * 100)) if total > 0 else 0

                # Publish progress (fire and forget)
                asyncio.create_task(
                    redis.publish(
                        f"progress:{video_id}",
                        json.dumps({
                            "percent": percent,
                            "downloaded_bytes": downloaded,
                            "total_bytes": total
                        })
                    )
                )

        # Download the video
        info = await ytdlp.download(url, video_id, progress_hook)

        # Get file size
        video_path = ytdlp.get_video_path(video_id)
        file_size = video_path.stat().st_size if video_path.exists() else None

        # Update database with success
        async with async_session() as db:
            video = await db.get(Video, video_id)
            if video:
                video.status = "complete"
                video.file_size_bytes = file_size
                video.duration_seconds = info.get('duration')
                video.upload_date = parse_upload_date(info.get('upload_date'))
                video.description = info.get('description')
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


def parse_upload_date(date_str: str) -> date | None:
    """Parse yt-dlp date format (YYYYMMDD) to date object"""
    if not date_str or len(date_str) != 8:
        return None
    try:
        return date(
            year=int(date_str[:4]),
            month=int(date_str[4:6]),
            day=int(date_str[6:8])
        )
    except ValueError:
        return None
```

### Requirements Update

```
yt-dlp>=2024.1
```

### Error Handling Cases

| Error Type | Detection | Handling |
|------------|-----------|----------|
| Geo-blocked | yt_dlp.utils.GeoRestrictedError | status=failed, error_message set |
| Age-restricted | yt_dlp.utils.AgeRestrictedError | status=failed, error_message set |
| Video unavailable | yt_dlp.utils.DownloadError | status=failed, error_message set |
| Network timeout | TimeoutError | ARQ retry (up to 3 times) |

### Dependencies

- T005 (ARQ worker)
- T002 (Database models)
- T004 (Redis connection)

## 3. Implementation Verification

- [ ] Videos download in MP4/H.264/AAC format
- [ ] Progress is published to Redis channel
- [ ] Thumbnails are saved as JPG
- [ ] Metadata is extracted and saved to database
- [ ] File size is recorded on completion
- [ ] Errors are captured in error_message column
- [ ] Status transitions: pending → downloading → complete/failed

### Tests to Write

```python
# tests/test_ytdlp.py
import pytest
from app.services.ytdlp import YTDLPService
from unittest.mock import patch, MagicMock

@pytest.mark.asyncio
async def test_extract_info():
    ytdlp = YTDLPService()
    # Use a known short video for testing
    info = await ytdlp.extract_info("https://www.youtube.com/watch?v=jNQXAC9IVRw")
    assert info['id'] == 'jNQXAC9IVRw'
    assert 'title' in info
    assert 'channel' in info

def test_format_string():
    from app.services.ytdlp import FORMAT_STRING
    formatted = FORMAT_STRING.format(max_height=1080)
    assert 'avc1' in formatted
    assert 'mp4a' in formatted
    assert '1080' in formatted

# tests/test_download_task.py
from app.tasks.download import parse_upload_date
from datetime import date

def test_parse_upload_date():
    assert parse_upload_date("20240115") == date(2024, 1, 15)
    assert parse_upload_date(None) is None
    assert parse_upload_date("invalid") is None
```

### Commands to Verify

```bash
# Test yt-dlp is installed
docker-compose exec worker yt-dlp --version

# Test format selection (dry run)
docker-compose exec worker yt-dlp -F "https://www.youtube.com/watch?v=jNQXAC9IVRw"

# Monitor Redis progress channel
docker-compose exec redis redis-cli SUBSCRIBE "progress:*"
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Created app/services/__init__.py | Success | Services package initialized |
| 2025-12-28 | Created app/services/ytdlp.py | Success | YTDLPService with extract_info and download methods |
| 2025-12-28 | Updated app/tasks/download.py | Success | Full download task with progress tracking and DB updates |
| 2025-12-28 | Tested yt-dlp format selection | Success | avc1/mp4a formats available for all resolutions |
| 2025-12-28 | Tested metadata extraction | Success | Extracted video ID, title, channel, duration, upload date |
| 2025-12-28 | Tested date parsing | Success | parse_upload_date correctly converts YYYYMMDD format |
| 2025-12-28 | Tested paths configuration | Success | Video and thumbnail directories created at /data/videos and /data/thumbnails |
| 2025-12-28 | Verified worker registration | Success | Both workers registered for download_video function |

## 5. Comments

- Format string ensures H.264 video and AAC audio for universal playback
- `max_video_height` defaults to 1080 but is configurable
- Progress is published to `progress:{video_id}` Redis channel
- Thumbnail extraction happens automatically with `writethumbnail=True`
- yt-dlp runs in a thread pool to avoid blocking the async event loop
- Error messages are truncated to 500 chars to avoid DB overflow
- Next ticket (T007) will handle thumbnail post-processing
