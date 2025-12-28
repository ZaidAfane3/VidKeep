from pathlib import Path
from PIL import Image
import asyncio

from app.config import settings


class ThumbnailService:
    def __init__(self, data_path: str = None):
        self.data_path = Path(data_path or settings.data_path)
        self.thumbnails_path = self.data_path / "thumbnails"
        self.thumbnails_path.mkdir(parents=True, exist_ok=True)

    async def process_thumbnail(self, video_id: str, source_path: Path = None) -> Path | None:
        """
        Convert thumbnail to JPG format and move to thumbnails directory.

        Args:
            video_id: Video ID for naming
            source_path: Optional explicit source path; otherwise searches videos dir

        Returns:
            Path to processed thumbnail or None if not found
        """
        target_path = self.thumbnails_path / f"{video_id}.jpg"

        # If already processed, return existing
        if target_path.exists():
            return target_path

        # Find source thumbnail (yt-dlp may create various formats)
        source = source_path or self._find_thumbnail(video_id)
        if not source:
            return None

        # Convert to JPG
        def _convert():
            with Image.open(source) as img:
                # Convert to RGB (in case of RGBA/P modes)
                if img.mode in ('RGBA', 'P'):
                    img = img.convert('RGB')

                # Resize if too large (max 640px width)
                max_width = 640
                if img.width > max_width:
                    ratio = max_width / img.width
                    new_size = (max_width, int(img.height * ratio))
                    img = img.resize(new_size, Image.Resampling.LANCZOS)

                # Save as JPG with optimization
                img.save(target_path, 'JPEG', quality=85, optimize=True)

            # Remove original if different from target
            if source != target_path and source.exists():
                source.unlink()

        await asyncio.to_thread(_convert)
        return target_path

    def _find_thumbnail(self, video_id: str) -> Path | None:
        """Search for thumbnail in various formats"""
        videos_path = self.data_path / "videos"

        # yt-dlp may create thumbnails with various extensions
        for ext in ['jpg', 'jpeg', 'webp', 'png']:
            # Check videos directory (yt-dlp default location)
            path = videos_path / f"{video_id}.{ext}"
            if path.exists():
                return path

            # Check thumbnails directory
            path = self.thumbnails_path / f"{video_id}.{ext}"
            if path.exists():
                return path

        return None

    def get_thumbnail_path(self, video_id: str) -> Path | None:
        """Get path to thumbnail if it exists"""
        path = self.thumbnails_path / f"{video_id}.jpg"
        return path if path.exists() else None

    async def delete_thumbnail(self, video_id: str) -> bool:
        """Delete thumbnail for a video"""
        path = self.thumbnails_path / f"{video_id}.jpg"
        if path.exists():
            path.unlink()
            return True
        return False
