import re
from typing import Optional

# YouTube URL patterns
YOUTUBE_PATTERNS = [
    # Standard watch URLs
    r'(?:https?://)?(?:www\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})',
    # Shortened URLs
    r'(?:https?://)?youtu\.be/([a-zA-Z0-9_-]{11})',
    # Embed URLs
    r'(?:https?://)?(?:www\.)?youtube\.com/embed/([a-zA-Z0-9_-]{11})',
    # Mobile URLs
    r'(?:https?://)?m\.youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})',
]


def extract_video_id(url: str) -> Optional[str]:
    """
    Extract YouTube video ID from various URL formats.

    Returns video ID (11 chars) or None if invalid.
    """
    for pattern in YOUTUBE_PATTERNS:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None


def validate_youtube_url(url: str) -> tuple[bool, str, Optional[str]]:
    """
    Validate a YouTube URL.

    Returns:
        (is_valid, message, video_id)
    """
    if not url:
        return False, "URL is required", None

    video_id = extract_video_id(url)
    if not video_id:
        return False, "Invalid YouTube URL format", None

    if len(video_id) != 11:
        return False, "Invalid video ID length", None

    return True, "Valid YouTube URL", video_id
