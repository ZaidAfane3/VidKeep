from arq import create_pool, ArqRedis
from arq.connections import RedisSettings

from app.config import settings
from app.tasks.download import download_video

# Global ARQ pool
_arq_pool: ArqRedis | None = None


async def startup(ctx):
    """Called when worker starts"""
    print("Worker started")


async def shutdown(ctx):
    """Called when worker shuts down"""
    print("Worker shutdown")


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
