# T007: Thumbnail & Metadata Extraction

## 1. Description

Handle thumbnail post-processing and ensure proper metadata extraction from yt-dlp. This includes converting thumbnails to a consistent JPG format, handling edge cases in metadata, and ensuring all video information is properly stored.

**Why**: Thumbnails may come in various formats (webp, png, jpg). Consistent JPG format ensures compatibility and smaller file sizes. Complete metadata enables filtering, sorting, and display features.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  services/
    thumbnail.py
    ytdlp.py (update)
  tasks/
    download.py (update)
```

### Thumbnail Service (services/thumbnail.py)

```python
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
```

### Update Download Task (tasks/download.py)

Add thumbnail processing after download:

```python
from app.services.thumbnail import ThumbnailService

async def download_video(ctx, video_id: str, url: str):
    # ... existing download code ...

    # After successful download, process thumbnail
    thumbnail_service = ThumbnailService()
    await thumbnail_service.process_thumbnail(video_id)

    # ... rest of success handling ...
```

### Metadata Extraction Helper (services/ytdlp.py addition)

```python
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
```

### Requirements Update

```
Pillow>=10.0
```

### Dependencies

- T006 (yt-dlp integration)

## 3. Implementation Verification

- [ ] Thumbnails are converted to JPG regardless of source format
- [ ] Thumbnails are resized to max 640px width
- [ ] Original non-JPG thumbnails are cleaned up
- [ ] Metadata extraction handles missing fields gracefully
- [ ] Long descriptions are truncated
- [ ] Channel name falls back through multiple fields

### Tests to Write

```python
# tests/test_thumbnail.py
import pytest
from pathlib import Path
from PIL import Image
from app.services.thumbnail import ThumbnailService
import tempfile

@pytest.fixture
def thumbnail_service():
    with tempfile.TemporaryDirectory() as tmpdir:
        yield ThumbnailService(data_path=tmpdir)

def test_find_thumbnail_various_formats(thumbnail_service):
    # Create test files
    videos_path = thumbnail_service.data_path / "videos"
    videos_path.mkdir(parents=True)

    # Create a webp thumbnail
    test_img = Image.new('RGB', (100, 100), color='red')
    webp_path = videos_path / "test123.webp"
    test_img.save(webp_path, 'WEBP')

    found = thumbnail_service._find_thumbnail("test123")
    assert found == webp_path

@pytest.mark.asyncio
async def test_process_thumbnail_converts_webp(thumbnail_service):
    # Create a webp source
    videos_path = thumbnail_service.data_path / "videos"
    videos_path.mkdir(parents=True)

    test_img = Image.new('RGB', (800, 600), color='blue')
    webp_path = videos_path / "test456.webp"
    test_img.save(webp_path, 'WEBP')

    result = await thumbnail_service.process_thumbnail("test456")

    assert result is not None
    assert result.suffix == '.jpg'
    assert result.exists()

    # Verify it's actually a JPEG
    with Image.open(result) as img:
        assert img.format == 'JPEG'
        assert img.width <= 640  # Should be resized

# tests/test_metadata.py
from app.services.ytdlp import extract_metadata, truncate_text

def test_extract_metadata_handles_missing():
    info = {'id': 'abc123', 'title': 'Test'}
    meta = extract_metadata(info)

    assert meta['video_id'] == 'abc123'
    assert meta['title'] == 'Test'
    assert meta['channel_name'] == 'Unknown'

def test_truncate_text():
    assert truncate_text(None, 100) is None
    assert truncate_text("short", 100) == "short"
    assert len(truncate_text("x" * 200, 100)) == 100
```

### Commands to Verify

```bash
# Check Pillow is installed
docker-compose exec worker python -c "from PIL import Image; print(Image.__version__)"

# Check thumbnail directory structure
docker-compose exec worker ls -la /data/thumbnails/

# Verify a thumbnail is valid JPEG
docker-compose exec worker python -c "from PIL import Image; Image.open('/data/thumbnails/VIDEO_ID.jpg').verify()"
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Created app/services/thumbnail.py | Success | ThumbnailService with PNG/WEBP/JPG conversion |
| 2025-12-28 | Updated app/services/ytdlp.py | Success | Added extract_metadata, truncate_text, parse_upload_date helpers |
| 2025-12-28 | Updated app/tasks/download.py | Success | Full integration with thumbnail processing and metadata extraction |
| 2025-12-28 | Tested metadata extraction | Success | extract_metadata handles missing fields with proper fallbacks |
| 2025-12-28 | Tested truncate_text | Success | Text truncation to max_length working correctly |
| 2025-12-28 | Tested PNG to JPEG conversion | Success | Resizes to 640px max, quality 85, file size reduced |
| 2025-12-28 | Tested RGBA to RGB conversion | Success | RGBA/P modes properly converted to RGB before JPEG |
| 2025-12-28 | Tested file cleanup | Success | Original files cleaned up after conversion |
| 2025-12-28 | Tested idempotency | Success | Calling process_thumbnail twice returns same path |
| 2025-12-28 | Tested channel fallbacks | Success | channel → uploader → "Unknown" fallback chain works |

## 5. Comments

- Pillow is required for image processing (added to requirements.txt)
- Thumbnails are resized to 640px max width to reduce storage and improve load times
- JPEG quality 85 is a good balance between size and quality
- RGBA/P mode images must be converted to RGB for JPEG
- Description is truncated to 5000 chars to prevent database bloat
- Channel name has fallbacks: channel → uploader → "Unknown"
- Next ticket (T008) will implement the ingest API endpoint
