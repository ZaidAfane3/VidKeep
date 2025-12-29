from pathlib import Path
from typing import Generator

from fastapi import HTTPException, status

from app.config import settings

CHUNK_SIZE = 1024 * 1024  # 1MB chunks


class StreamingService:
    def __init__(self, data_path: str = None):
        self.data_path = Path(data_path or settings.data_path)
        self.videos_path = self.data_path / "videos"

    def get_video_path(self, video_id: str) -> Path:
        """Get path to video file, raise 404 if not found."""
        path = self.videos_path / f"{video_id}.mp4"
        if not path.exists():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Video file not found: {video_id}"
            )
        return path

    def get_file_size(self, path: Path) -> int:
        """Get file size in bytes."""
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
        end = end if end is not None else file_size - 1

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
