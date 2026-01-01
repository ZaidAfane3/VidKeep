from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text

from app.dependencies import get_db
from app.redis import get_redis

router = APIRouter(prefix="/health", tags=["Health"])


@router.get("")
async def health_check():
    """Basic liveness check"""
    return {"status": "healthy"}


@router.get("/ready")
async def readiness_check(
    db: AsyncSession = Depends(get_db)
):
    """Full readiness check including dependencies"""
    checks = {
        "api": "healthy",
        "database": "unknown",
        "redis": "unknown"
    }

    # Check database
    try:
        await db.execute(text("SELECT 1"))
        checks["database"] = "healthy"
    except Exception as e:
        checks["database"] = f"unhealthy: {str(e)}"

    # Check Redis
    try:
        redis_client = await get_redis()
        await redis_client.ping()
        checks["redis"] = "healthy"
    except Exception as e:
        checks["redis"] = f"unhealthy: {str(e)}"

    all_healthy = all(v == "healthy" for v in checks.values())

    return {
        "status": "healthy" if all_healthy else "degraded",
        "checks": checks
    }


@router.get("/db")
async def database_health(db: AsyncSession = Depends(get_db)):
    """Database connectivity check"""
    try:
        result = await db.execute(text("SELECT version()"))
        version = result.scalar()
        return {"status": "healthy", "version": version}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}


@router.get("/redis")
async def redis_health():
    """Redis connectivity check with worker information"""
    try:
        redis_client = await get_redis()
        info = await redis_client.info("server")
        
        # Count active workers by finding heartbeat keys
        worker_keys = await redis_client.keys("vidkeep:worker:*")
        worker_ids = [key.replace("vidkeep:worker:", "") for key in worker_keys]
        
        return {
            "status": "healthy",
            "version": info.get("redis_version"),
            "workers": {
                "active": len(worker_ids),
                "ids": worker_ids
            }
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
