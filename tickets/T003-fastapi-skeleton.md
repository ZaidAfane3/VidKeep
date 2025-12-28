# T003: FastAPI Application Skeleton

## 1. Description

Create the base FastAPI application with proper project structure, Pydantic schemas for request/response models, and dependency injection setup. This establishes the API foundation that all endpoints will build upon.

**Why**: A well-structured FastAPI application with proper schemas ensures type safety, automatic documentation, and consistent API responses across all endpoints.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/app/
  __init__.py
  main.py
  config.py
  schemas.py
  dependencies.py
  routers/
    __init__.py
```

### Main Application (main.py)

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app = FastAPI(
    title="VidKeep API",
    description="Personal Video Library & Streamer",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "VidKeep API", "version": "1.0.0"}
```

### Configuration (config.py)

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://vidkeep:vidkeep@postgres:5432/vidkeep"
    redis_url: str = "redis://redis:6379"
    data_path: str = "/data"
    max_video_height: int = 1080
    worker_count: int = 2

    class Config:
        env_file = ".env"

settings = Settings()
```

### Pydantic Schemas (schemas.py)

```python
from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional
from enum import Enum

class VideoStatus(str, Enum):
    pending = "pending"
    downloading = "downloading"
    complete = "complete"
    failed = "failed"

class VideoBase(BaseModel):
    title: str
    channel_name: str
    channel_id: Optional[str] = None
    duration_seconds: Optional[int] = None
    upload_date: Optional[date] = None
    description: Optional[str] = None

class VideoCreate(BaseModel):
    url: str = Field(..., description="YouTube URL to ingest")

class VideoUpdate(BaseModel):
    is_favorite: Optional[bool] = None

class VideoResponse(VideoBase):
    video_id: str
    is_favorite: bool
    status: VideoStatus
    file_size_bytes: Optional[int] = None
    created_at: datetime
    error_message: Optional[str] = None

    # Computed fields
    youtube_url: str
    download_progress: Optional[int] = None  # 0-100, only during downloading

    class Config:
        from_attributes = True

class VideoListResponse(BaseModel):
    videos: list[VideoResponse]
    total: int

class IngestResponse(BaseModel):
    video_id: str
    message: str
```

### Dependencies (dependencies.py)

```python
from app.database import async_session
from sqlalchemy.ext.asyncio import AsyncSession

async def get_db() -> AsyncSession:
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()
```

### Requirements Update

```
fastapi>=0.109
uvicorn[standard]>=0.27
pydantic>=2.5
pydantic-settings>=2.1
```

### Dependencies

- T001 (Docker setup)
- T002 (Database models)

## 3. Implementation Verification

- [ ] FastAPI app starts without errors
- [ ] Swagger UI accessible at `/docs`
- [ ] ReDoc accessible at `/redoc`
- [ ] CORS configured for frontend origin
- [ ] All Pydantic schemas validate correctly
- [ ] Settings load from environment variables

### Tests to Write

```python
# tests/test_main.py
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["message"] == "VidKeep API"

def test_docs_accessible():
    response = client.get("/docs")
    assert response.status_code == 200

# tests/test_schemas.py
from app.schemas import VideoCreate, VideoResponse, VideoStatus
import pytest

def test_video_create_requires_url():
    with pytest.raises(ValueError):
        VideoCreate()  # Missing required url

def test_video_status_enum():
    assert VideoStatus.pending.value == "pending"
    assert VideoStatus.complete.value == "complete"
```

### Commands to Verify

```bash
# Start the API
docker-compose up api

# Check API is running
curl http://localhost:8000/

# Access Swagger docs
open http://localhost:8000/docs
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Created app/config.py | Success | pydantic-settings with env file support |
| 2025-12-28 | Created app/schemas.py | Success | VideoCreate, VideoResponse, VideoListResponse, IngestResponse, ChannelResponse |
| 2025-12-28 | Created app/main.py | Success | FastAPI app with CORS middleware |
| 2025-12-28 | Created app/dependencies.py | Success | get_db dependency for DI |
| 2025-12-28 | Created app/routers/__init__.py | Success | Empty routers package ready for endpoints |

## 5. Comments

- `youtube_url` in VideoResponse is computed from video_id (not stored)
- `download_progress` is computed from Redis/in-memory state (not stored)
- The routers directory is created empty; endpoints added in later tickets
- CORS allows localhost:3000 for frontend development
- pydantic-settings handles environment variable loading
- Next ticket (T004) will add health check endpoints
