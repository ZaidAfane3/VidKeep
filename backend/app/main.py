"""
VidKeep API Main Application (T028 Embedded Workers)
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import health, videos, stream, channels, queue, websocket, metrics
from app.services.worker_manager import WorkerManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global worker manager instance
worker_manager: WorkerManager | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global worker_manager
    
    # Startup: Initialize and start worker manager (T028)
    logger.info(f"Starting VidKeep API with {settings.max_workers} embedded workers")
    worker_manager = WorkerManager(settings.max_workers)
    await worker_manager.start()
    
    # Store in app state for access from other modules
    app.state.worker_manager = worker_manager
    
    yield
    
    # Shutdown: Gracefully stop workers
    logger.info("Shutting down VidKeep API...")
    if worker_manager:
        await worker_manager.shutdown(grace_period=300)
    
    from app.redis import close_redis
    await close_redis()
    logger.info("Shutdown complete")


app = FastAPI(
    title="VidKeep API",
    description="Personal Video Library & Streamer",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(health.router)
app.include_router(videos.router)
app.include_router(stream.router)
app.include_router(channels.router)
app.include_router(queue.router)
app.include_router(websocket.router)
app.include_router(metrics.router)


@app.get("/")
async def root():
    return {"message": "VidKeep API", "version": "1.0.0"}
