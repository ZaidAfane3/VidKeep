import asyncio
import uuid
import redis.asyncio as aioredis
from arq import create_pool, ArqRedis
from arq.connections import RedisSettings

from app.config import settings
from app.tasks.download import download_video

# Global ARQ pool
_arq_pool: ArqRedis | None = None

# Worker heartbeat settings
HEARTBEAT_KEY_PREFIX = "vidkeep:worker:"
HEARTBEAT_INTERVAL = 30  # seconds
HEARTBEAT_TTL = 60  # seconds - worker considered dead if no heartbeat for this long


async def heartbeat_loop(ctx):
    """Background task that sends periodic heartbeats to Redis."""
    worker_id = ctx.get("worker_id")
    redis = ctx.get("redis")
    
    while True:
        try:
            key = f"{HEARTBEAT_KEY_PREFIX}{worker_id}"
            await redis.setex(key, HEARTBEAT_TTL, "alive")
        except Exception as e:
            print(f"Heartbeat error: {e}")
        await asyncio.sleep(HEARTBEAT_INTERVAL)


async def startup(ctx):
    """Called when worker starts"""
    # Generate unique worker ID
    worker_id = str(uuid.uuid4())[:8]
    ctx["worker_id"] = worker_id
    
    # Create redis connection for heartbeat
    ctx["redis"] = await aioredis.from_url(settings.redis_url)
    
    # Register worker immediately
    key = f"{HEARTBEAT_KEY_PREFIX}{worker_id}"
    await ctx["redis"].setex(key, HEARTBEAT_TTL, "alive")
    
    # Start heartbeat background task
    ctx["heartbeat_task"] = asyncio.create_task(heartbeat_loop(ctx))
    
    print(f"Worker {worker_id} started")


async def shutdown(ctx):
    """Called when worker shuts down"""
    worker_id = ctx.get("worker_id")
    redis = ctx.get("redis")
    heartbeat_task = ctx.get("heartbeat_task")
    
    # Cancel heartbeat task
    if heartbeat_task:
        heartbeat_task.cancel()
        try:
            await heartbeat_task
        except asyncio.CancelledError:
            pass
    
    # Remove worker from registry
    if redis and worker_id:
        key = f"{HEARTBEAT_KEY_PREFIX}{worker_id}"
        await redis.delete(key)
        await redis.aclose()
    
    print(f"Worker {worker_id} shutdown")


class WorkerSettings:
    redis_settings = RedisSettings.from_dsn(settings.redis_url)

    functions = [download_video]

    on_startup = startup
    on_shutdown = shutdown

    # Job settings
    max_jobs = 10
    job_timeout = 3600  # 1 hour max per download
    keep_result = 3600  # Keep results for 1 hour

    # Retry settings
    max_tries = 3


async def get_arq_pool() -> ArqRedis:
    """Get the ARQ connection pool"""
    global _arq_pool
    if _arq_pool is None:
        _arq_pool = await create_pool(
            RedisSettings.from_dsn(settings.redis_url)
        )
    return _arq_pool


async def enqueue_download(video_id: str, url: str) -> str:
    """Queue a download job and return the job ID"""
    pool = await get_arq_pool()
    job = await pool.enqueue_job("download_video", video_id, url)
    return job.job_id
