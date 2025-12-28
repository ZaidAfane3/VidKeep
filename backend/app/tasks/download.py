import asyncio


async def download_video(ctx, video_id: str, url: str):
    """
    Download a video from YouTube using yt-dlp.

    Args:
        ctx: ARQ context
        video_id: YouTube video ID
        url: Full YouTube URL

    This is a placeholder that will be fully implemented in T006.
    """
    print(f"Download task received: {video_id}")

    # Placeholder - actual implementation in T006
    await asyncio.sleep(1)

    return {"video_id": video_id, "status": "queued"}
