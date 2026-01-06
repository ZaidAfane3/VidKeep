import yt_dlp
import asyncio
from datetime import date
from pathlib import Path
from typing import Callable, Optional
import time

from app.config import settings
from app.services.metrics import worker_metrics

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
            'thumbnail_format': 'jpg',
            'quiet': True,
            'no_warnings': True,
            'extract_flat': False,
        }

        if progress_callback:
            opts['progress_hooks'] = [progress_callback]
            
            # Add postprocessor hook for muxing duration tracking
            muxing_start = {}
            
            def postprocessor_hook(d):
                if d.get('postprocessor') == 'Merger':
                    status = d.get('status')
                    if status == 'started':
                        muxing_start['time'] = time.time()
                    elif status == 'finished' and 'time' in muxing_start:
                        duration = time.time() - muxing_start['time']
                        worker_metrics.record_muxing(duration)
            
            opts['postprocessor_hooks'] = [postprocessor_hook]

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

    def get_partial_path(self, video_id: str) -> Path | None:
        """
        Return path to partial file if it exists, for resume detection.
        
        Returns the first found partial file or None.
        """
        patterns = [
            f"{video_id}.mp4.part",
            f"{video_id}.mp4.part-Frag*",
            f"{video_id}.f*.mp4",
            f"{video_id}.f*.m4a",
        ]
        for pattern in patterns:
            matches = list(self.videos_path.glob(pattern))
            if matches:
                return matches[0]
        return None

    def cleanup_partial_files(self, video_id: str, reason: str = "cancelled") -> None:
        """
        Remove partial download files based on cleanup reason.
        
        Args:
            video_id: The video ID to clean up
            reason: One of:
                - "cancelled": User cancelled, delete everything
                - "max_retries_exceeded": Failed after all retries, delete everything
                - "worker_crash_recovery": Keep partial files for resume
        """
        if reason == "worker_crash_recovery":
            # Keep files for resume
            return
        
        patterns = [
            f"{video_id}.mp4.part",
            f"{video_id}.mp4.part-*",
            f"{video_id}.f*.mp4",
            f"{video_id}.f*.m4a",
            f"{video_id}.*.ytdl",
            f"{video_id}.temp.*",
        ]
        for pattern in patterns:
            for file in self.videos_path.glob(pattern):
                try:
                    file.unlink()
                except OSError:
                    pass



def extract_metadata(info: dict) -> dict:
    """
    Extract and normalize metadata from yt-dlp info dict.

    Returns cleaned metadata dict for database storage.
    """
    return {
        'video_id': info.get('id'),
        'title': info.get('title', 'Untitled'),
        'channel_name': info.get('channel') or info.get('uploader') or 'Unknown',
        'channel_id': info.get('channel_id'),
        'duration_seconds': info.get('duration'),
        'upload_date': parse_upload_date(info.get('upload_date')),
        'description': truncate_text(info.get('description'), 5000),
    }


def truncate_text(text: str | None, max_length: int) -> str | None:
    """Truncate text to max_length, preserving None"""
    if text is None:
        return None
    return text[:max_length] if len(text) > max_length else text


def parse_upload_date(date_str: str | None) -> date | None:
    """Parse YYYYMMDD format to date object"""
    if not date_str or len(date_str) != 8:
        return None
    try:
        return date(
            year=int(date_str[:4]),
            month=int(date_str[4:6]),
            day=int(date_str[6:8])
        )
    except (ValueError, TypeError):
        return None
