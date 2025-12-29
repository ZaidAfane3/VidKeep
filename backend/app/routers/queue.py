from fastapi import APIRouter

from app.redis import get_redis

router = APIRouter(prefix="/api/queue", tags=["Queue"])


@router.get("/status")
async def queue_status():
    """Get current queue depth and active job count."""
    redis = await get_redis()

    # ARQ stores jobs in specific keys
    pending = await redis.llen("arq:queue")
    processing = await redis.scard("arq:in-progress")

    return {
        "pending": pending,
        "processing": processing,
        "total": pending + processing
    }
