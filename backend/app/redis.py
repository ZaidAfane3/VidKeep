import redis.asyncio as redis

from app.config import settings

redis_pool = None


async def get_redis() -> redis.Redis:
    global redis_pool
    if redis_pool is None:
        redis_pool = redis.ConnectionPool.from_url(
            settings.redis_url,
            decode_responses=True
        )
    return redis.Redis(connection_pool=redis_pool)


async def close_redis():
    global redis_pool
    if redis_pool:
        await redis_pool.disconnect()
        redis_pool = None
