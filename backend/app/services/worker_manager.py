"""
Embedded Worker Process Pool Manager (T028)

Manages a pool of download worker processes within the API pod.
Replaces the separate ARQ worker containers with embedded workers.
"""

import asyncio
import json
import logging
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Callable

from sqlalchemy import select, and_

from app.config import settings
from app.database import async_session
from app.models import Video
from app.redis import get_redis
from app.services.metrics import worker_metrics

logger = logging.getLogger(__name__)


# Redis key prefixes
PENDING_QUEUE = "vidkeep:jobs:pending"
PROCESSING_QUEUE = "vidkeep:jobs:processing"
HEARTBEAT_PREFIX = "vidkeep:heartbeat:"


@dataclass
class WorkerProcess:
    """Represents a single download worker process."""
    process_id: str
    video_id: str
    started_at: datetime = field(default_factory=datetime.utcnow)
    task: asyncio.Task | None = None


class WorkerManager:
    """
    Manages a pool of download worker processes.
    
    Responsibilities:
    - Claim jobs from Redis queue
    - Spawn and monitor worker tasks
    - Send heartbeats to Redis
    - Recover stale jobs from crashed workers
    """

    def __init__(self, max_workers: int):
        self.max_workers = max_workers
        self.active_workers: dict[str, WorkerProcess] = {}  # video_id -> WorkerProcess
        self.redis = None
        self._shutdown = False
        self._tasks: list[asyncio.Task] = []
        self._worker_counter = 0

    async def start(self):
        """Start the worker manager and begin consuming jobs."""
        self.redis = await get_redis()
        
        logger.info(f"Starting WorkerManager with max_workers={self.max_workers}")
        
        # Start background loops
        self._tasks.append(asyncio.create_task(self._job_consumer_loop()))
        self._tasks.append(asyncio.create_task(self._heartbeat_loop()))
        self._tasks.append(asyncio.create_task(self._stale_job_recovery_loop()))
        
        logger.info("WorkerManager started successfully")

    async def shutdown(self, grace_period: int = 300):
        """
        Gracefully shutdown all workers.
        
        Args:
            grace_period: Max seconds to wait for in-progress downloads
        """
        logger.info("WorkerManager shutdown initiated")
        self._shutdown = True

        # Cancel background loops
        for task in self._tasks:
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass

        # Wait for in-progress workers with timeout
        if self.active_workers:
            logger.info(f"Waiting for {len(self.active_workers)} active workers (grace_period={grace_period}s)")
            
            try:
                worker_tasks = [w.task for w in self.active_workers.values() if w.task]
                if worker_tasks:
                    await asyncio.wait_for(
                        asyncio.gather(*worker_tasks, return_exceptions=True),
                        timeout=grace_period
                    )
            except asyncio.TimeoutError:
                logger.warning("Grace period exceeded, workers will be recovered by other pods")
        
        logger.info("WorkerManager shutdown complete")

    def get_active_count(self) -> int:
        """Return number of currently active workers."""
        return len(self.active_workers)

    async def _job_consumer_loop(self):
        """Main loop that claims and processes jobs."""
        # Import here to avoid circular imports
        from app.tasks.download import download_video_task
        
        while not self._shutdown:
            try:
                # Only claim if we have capacity
                if len(self.active_workers) < self.max_workers:
                    job = await self._claim_next_job()
                    if job:
                        video_id, url = job
                        await self._spawn_worker(video_id, url, download_video_task)
                
                # Small delay to prevent tight loop
                await asyncio.sleep(1)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in job consumer loop: {e}")
                await asyncio.sleep(5)

    async def _claim_next_job(self) -> tuple[str, str] | None:
        """
        Atomically claim the next job from the queue.
        
        Returns:
            Tuple of (video_id, url) if job claimed, None otherwise
        """
        try:
            # BRPOPLPUSH moves job from pending to processing atomically
            result = await self.redis.brpoplpush(
                PENDING_QUEUE,
                PROCESSING_QUEUE,
                timeout=1
            )
            
            if not result:
                return None
            
            video_id = result.decode() if isinstance(result, bytes) else result
            
            # Update database with claim info
            async with async_session() as db:
                video = await db.get(Video, video_id)
                if not video:
                    logger.warning(f"Video {video_id} not found in database, removing from queue")
                    await self.redis.lrem(PROCESSING_QUEUE, 1, video_id)
                    return None
                
                # Get URL from video ID
                url = f"https://www.youtube.com/watch?v={video_id}"
                
                # Mark as claimed
                worker_id = f"{settings.pod_name}:{self._get_next_worker_id()}"
                video.claimed_by = worker_id
                video.claimed_at = datetime.utcnow()
                video.status = "downloading"
                await db.commit()
                
                logger.info(f"Claimed job {video_id} by {worker_id}")
                return (video_id, url)
                
        except Exception as e:
            logger.error(f"Error claiming job: {e}")
            return None

    async def _spawn_worker(self, video_id: str, url: str, download_func: Callable):
        """Spawn a worker task for the given video."""
        self._worker_counter += 1
        process_id = f"w{self._worker_counter}"
        
        worker = WorkerProcess(
            process_id=process_id,
            video_id=video_id
        )
        
        # Create the download task
        worker.task = asyncio.create_task(
            self._run_download(video_id, url, download_func)
        )
        
        self.active_workers[video_id] = worker
        
        # Update active workers metric
        worker_metrics.set_active_workers(len(self.active_workers))
        
        # Set initial heartbeat
        await self._send_heartbeat(video_id)
        
        logger.info(f"Spawned worker {process_id} for video {video_id}")

    async def _run_download(self, video_id: str, url: str, download_func: Callable):
        """Run the download and clean up when done."""
        try:
            await download_func(video_id, url)
        except Exception as e:
            logger.error(f"Download failed for {video_id}: {e}")
            # Status is updated by download_func on failure
        finally:
            # Clean up worker
            if video_id in self.active_workers:
                del self.active_workers[video_id]
            
            # Update active workers metric
            worker_metrics.set_active_workers(len(self.active_workers))
            
            # Remove from processing queue
            await self.redis.lrem(PROCESSING_QUEUE, 1, video_id)
            
            # Remove heartbeat
            await self.redis.delete(f"{HEARTBEAT_PREFIX}{video_id}")
            
            logger.info(f"Worker finished for video {video_id}")

    async def _heartbeat_loop(self):
        """Send heartbeats for all active workers and collect resource metrics."""
        import os
        import psutil
        
        pid = os.getpid()
        process = psutil.Process(pid)
        
        while not self._shutdown:
            try:
                for video_id in list(self.active_workers.keys()):
                    await self._send_heartbeat(video_id)
                
                # Collect process resource metrics if workers are active
                if self.active_workers:
                    try:
                        memory_mb = process.memory_info().rss / 1024 / 1024
                        cpu_percent = process.cpu_percent()
                        worker_metrics.update_worker_resources(
                            settings.pod_name,
                            pid
                        )
                    except Exception:
                        pass  # Ignore resource collection errors
                
                await asyncio.sleep(settings.worker_heartbeat_interval)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in heartbeat loop: {e}")
                await asyncio.sleep(5)

    async def _send_heartbeat(self, video_id: str):
        """Send heartbeat for a specific video."""
        try:
            key = f"{HEARTBEAT_PREFIX}{video_id}"
            worker = self.active_workers.get(video_id)
            if worker:
                value = f"{settings.pod_name}:{worker.process_id}"
                await self.redis.setex(key, settings.worker_heartbeat_ttl, value)
        except Exception as e:
            logger.error(f"Error sending heartbeat for {video_id}: {e}")

    async def _stale_job_recovery_loop(self):
        """Periodic task to recover jobs from crashed workers."""
        from app.services.ytdlp import YTDLPService
        
        while not self._shutdown:
            try:
                await asyncio.sleep(30)  # Check every 30 seconds
                
                if self._shutdown:
                    break
                
                stale_threshold = datetime.utcnow() - timedelta(
                    seconds=settings.stale_job_threshold_seconds
                )
                
                async with async_session() as db:
                    # Find stale jobs
                    result = await db.execute(
                        select(Video).where(
                            and_(
                                Video.status == "downloading",
                                Video.claimed_at < stale_threshold,
                            )
                        )
                    )
                    
                    stale_videos = result.scalars().all()
                    
                    for video in stale_videos:
                        # Check if heartbeat exists in Redis
                        heartbeat = await self.redis.get(f"{HEARTBEAT_PREFIX}{video.video_id}")
                        
                        if not heartbeat:
                            # Worker is dead, handle recovery
                            if video.retry_count < settings.max_download_retries:
                                # Re-queue for retry
                                video.status = "pending"
                                video.claimed_by = None
                                video.claimed_at = None
                                video.retry_count += 1
                                
                                # Push back to Redis queue
                                await self.redis.lpush(PENDING_QUEUE, video.video_id)
                                
                                logger.warning(
                                    f"Re-queued stale job: {video.video_id} "
                                    f"(attempt {video.retry_count}/{settings.max_download_retries})"
                                )
                            else:
                                # Max retries exceeded
                                video.status = "failed"
                                video.error_message = "Max retries exceeded after worker failures"
                                
                                # Clean up partial files
                                ytdlp = YTDLPService()
                                ytdlp.cleanup_partial_files(video.video_id, "max_retries_exceeded")
                                
                                logger.error(
                                    f"Job {video.video_id} failed: max retries exceeded"
                                )
                    
                    await db.commit()
                    
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error in stale job recovery: {e}")
                await asyncio.sleep(30)

    def _get_next_worker_id(self) -> str:
        """Generate unique worker ID."""
        return f"w{self._worker_counter}"


# Global instance (set by main.py on startup)
worker_manager: WorkerManager | None = None


async def get_worker_manager() -> WorkerManager:
    """Get the global worker manager instance."""
    if worker_manager is None:
        raise RuntimeError("WorkerManager not initialized")
    return worker_manager
