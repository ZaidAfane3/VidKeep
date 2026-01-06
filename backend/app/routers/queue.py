from fastapi import APIRouter

from app.redis import get_redis
from app.config import settings

router = APIRouter(prefix="/api/queue", tags=["Queue"])

# Redis queue keys (T028)
PENDING_QUEUE = "vidkeep:jobs:pending"
PROCESSING_QUEUE = "vidkeep:jobs:processing"


@router.get("/status")
async def queue_status():
    """Get current queue depth, active job count, and worker capacity."""
    redis = await get_redis()

    pending = await redis.llen(PENDING_QUEUE)
    processing = await redis.llen(PROCESSING_QUEUE)

    return {
        "pending": pending,
        "processing": processing,
        "total": pending + processing,
        "max_workers": settings.max_workers,
    }
