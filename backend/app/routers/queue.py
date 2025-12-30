from fastapi import APIRouter

from app.redis import get_redis

router = APIRouter(prefix="/api/queue", tags=["Queue"])


@router.get("/status")
async def queue_status():
    """Get current queue depth and active job count."""
    redis = await get_redis()

    # ARQ uses sorted set (zset) for queue
    pending = await redis.zcard("arq:queue")

    # Count in-progress jobs by finding arq:in-progress:* keys
    in_progress_keys = await redis.keys("arq:in-progress:*")
    processing = len(in_progress_keys)

    return {
        "pending": pending,
        "processing": processing,
        "total": pending + processing
    }
