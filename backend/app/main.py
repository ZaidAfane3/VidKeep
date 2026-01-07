"""
VidKeep API Main Application (T028 Embedded Workers, T026 Monolith)
"""
import logging
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse

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

# Static files directory (T026 Monolith Merge)
STATIC_DIR = Path(__file__).parent.parent / "static"


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
    version="1.1.0",  # Bumped for T026
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # T026: Allow all origins (Ingress handles in production)
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

# Mount static assets if directory exists (T026 Monolith Merge)
if STATIC_DIR.exists() and (STATIC_DIR / "assets").exists():
    app.mount("/assets", StaticFiles(directory=STATIC_DIR / "assets"), name="assets")
    logger.info(f"Mounted static assets from {STATIC_DIR / 'assets'}")


# SPA catch-all route - MUST be last (T026 Monolith Merge)
@app.get("/{path:path}")
async def spa_catch_all(path: str):
    """
    Serve React SPA for all non-API routes.
    Excludes /api, /ws, /health, /metrics to preserve proper 404 handling.
    """
    # Don't catch API/WS/health/metrics routes - let them 404 properly
    if path.startswith(("api/", "ws/", "health", "metrics")):
        raise HTTPException(status_code=404, detail="Not found")
    
    # Serve static file if it exists
    if STATIC_DIR.exists():
        static_file = STATIC_DIR / path
        if static_file.exists() and static_file.is_file():
            return FileResponse(static_file)
        # Fallback to index.html for SPA routing
        index_file = STATIC_DIR / "index.html"
        if index_file.exists():
            return FileResponse(index_file)
    
    # No static files available (dev mode without frontend build)
    return {"message": "VidKeep API", "version": "1.1.0", "note": "Frontend not built"}

