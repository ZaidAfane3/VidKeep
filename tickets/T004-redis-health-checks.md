# T004: Redis & Health Check Endpoints

## 1. Description

Configure Redis connection for the task queue and implement health check endpoints for all services (API, Database, Redis). Health checks enable Docker orchestration and monitoring of service availability.

**Why**: Health checks are essential for production deployments, allowing load balancers and orchestrators to verify service readiness. Redis is required for the ARQ task queue in subsequent tickets.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  redis.py
  routers/
    health.py
  main.py (update to include router)
/docker-compose.yml (update with healthchecks)
```

### Redis Connection (redis.py)

```python
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
```

### Health Check Router (routers/health.py)

```python
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
    """Redis connectivity check"""
    try:
        redis_client = await get_redis()
        info = await redis_client.info("server")
        return {
            "status": "healthy",
            "version": info.get("redis_version")
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

### Update main.py

```python
from app.routers import health

# Add router
app.include_router(health.router)

# Add startup/shutdown events
@app.on_event("shutdown")
async def shutdown():
    from app.redis import close_redis
    await close_redis()
```

### Docker Compose Healthchecks

```yaml
services:
  api:
    # ... existing config
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  postgres:
    # ... existing config
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U vidkeep -d vidkeep"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    # ... existing config
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### Requirements Update

```
redis>=5.0
```

### Dependencies

- T001 (Docker Compose)
- T002 (Database connection)
- T003 (FastAPI app)

## 3. Implementation Verification

- [ ] `/health` returns 200 with status "healthy"
- [ ] `/health/ready` checks all dependencies
- [ ] `/health/db` returns PostgreSQL version
- [ ] `/health/redis` returns Redis version
- [ ] Redis connection pool is reused
- [ ] Docker healthchecks pass for all services

### Tests to Write

```python
# tests/test_health.py
from fastapi.testclient import TestClient
from app.main import app
import pytest

client = TestClient(app)

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

@pytest.mark.asyncio
async def test_redis_connection():
    from app.redis import get_redis
    redis_client = await get_redis()
    assert await redis_client.ping() == True
```

### Commands to Verify

```bash
# Start all services
docker-compose up -d

# Check health endpoints
curl http://localhost:8000/health
curl http://localhost:8000/health/ready
curl http://localhost:8000/health/db
curl http://localhost:8000/health/redis

# Check Docker healthcheck status
docker-compose ps
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Created app/redis.py | Success | Async Redis connection pool with disconnect support |
| 2025-12-28 | Created app/routers/health.py | Success | /health, /health/ready, /health/db, /health/redis endpoints |
| 2025-12-28 | Updated app/main.py | Success | Added health router, lifespan context for cleanup |
| 2025-12-28 | Updated docker-compose.yml | Success | Healthchecks for api, postgres, redis; service_healthy conditions |

## 5. Comments

- Redis connection uses async redis library for non-blocking operations
- Connection pool is global and reused across requests
- Healthchecks are crucial for docker-compose depends_on with condition: service_healthy
- The `/health` endpoint is lightweight (no dependencies)
- The `/health/ready` endpoint is comprehensive (checks all services)
- Phase 1 is complete after this ticket; Phase 2 (ARQ worker) depends on Redis being ready
- Next ticket (T005) will use Redis for the ARQ task queue
