# T002: PostgreSQL & Alembic Migrations

## 1. Description

Configure PostgreSQL database integration with Alembic for migrations. This ticket creates the initial database schema for the `videos` table as specified in PROJECT.md, sets up Alembic for version-controlled migrations, and establishes the SQLAlchemy async models.

**Why**: The videos table is the core data structure of VidKeep. All video metadata, status tracking, and file references depend on this schema.

## 2. Technical Specification

### Files to Create/Modify

```
/backend/
  alembic.ini
  alembic/
    env.py
    versions/
      001_create_videos_table.py
  app/
    database.py
    models.py
  requirements.txt (update)
```

### Database Schema (from PROJECT.md)

```sql
CREATE TABLE videos (
    video_id VARCHAR(11) PRIMARY KEY,
    title TEXT NOT NULL,
    channel_name VARCHAR(255) NOT NULL,
    channel_id VARCHAR(24),
    duration_seconds INTEGER,
    upload_date DATE,
    description TEXT,
    is_favorite BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'pending',
    file_size_bytes BIGINT,
    created_at TIMESTAMP DEFAULT NOW(),
    error_message TEXT
);

CREATE INDEX idx_channel_name ON videos(channel_name);
CREATE INDEX idx_is_favorite ON videos(is_favorite);
CREATE INDEX idx_status ON videos(status);
```

### SQLAlchemy Model

```python
# app/models.py
from sqlalchemy import Column, String, Text, Integer, BigInteger, Boolean, Date, DateTime, Index
from sqlalchemy.sql import func
from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass

class Video(Base):
    __tablename__ = "videos"

    video_id = Column(String(11), primary_key=True)
    title = Column(Text, nullable=False)
    channel_name = Column(String(255), nullable=False)
    channel_id = Column(String(24), nullable=True)
    duration_seconds = Column(Integer, nullable=True)
    upload_date = Column(Date, nullable=True)
    description = Column(Text, nullable=True)
    is_favorite = Column(Boolean, default=False)
    status = Column(String(20), default="pending")  # pending, downloading, complete, failed
    file_size_bytes = Column(BigInteger, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    error_message = Column(Text, nullable=True)

    __table_args__ = (
        Index("idx_channel_name", "channel_name"),
        Index("idx_is_favorite", "is_favorite"),
        Index("idx_status", "status"),
    )
```

### Database Connection

```python
# app/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.models import Base
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://vidkeep:vidkeep@postgres:5432/vidkeep")

engine = create_async_engine(DATABASE_URL, echo=True)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db():
    async with async_session() as session:
        yield session
```

### Requirements Update

```
sqlalchemy[asyncio]>=2.0
asyncpg>=0.29
alembic>=1.13
```

### Dependencies

- T001 (Docker Compose with PostgreSQL container)

## 3. Implementation Verification

- [ ] `alembic.ini` configured with async database URL
- [ ] Migration file creates videos table with all columns
- [ ] All three indexes are created
- [ ] SQLAlchemy model matches schema exactly
- [ ] Video.status has enum-like constraint (pending/downloading/complete/failed)

### Tests to Write

```python
# tests/test_models.py
import pytest
from app.models import Video

def test_video_model_has_required_fields():
    """Verify Video model has all required columns"""
    required = ["video_id", "title", "channel_name", "status", "created_at"]
    for field in required:
        assert hasattr(Video, field)

def test_video_status_default():
    """Verify default status is 'pending'"""
    video = Video(video_id="test123", title="Test", channel_name="Channel")
    assert video.status == "pending"
```

### Commands to Verify

```bash
# Run migrations
docker-compose exec api alembic upgrade head

# Verify table exists
docker-compose exec postgres psql -U vidkeep -d vidkeep -c "\d videos"

# Verify indexes
docker-compose exec postgres psql -U vidkeep -d vidkeep -c "\di"
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Created app/models.py | Success | Video model with all columns and 3 indexes |
| 2025-12-28 | Created app/database.py | Success | Async SQLAlchemy engine and session factory |
| 2025-12-28 | Created alembic.ini | Success | Configured for async PostgreSQL |
| 2025-12-28 | Created alembic/env.py | Success | Async migration support configured |
| 2025-12-28 | Created 001_create_videos_table.py | Success | Initial migration with all columns and indexes |

## 5. Comments

- Video ID is VARCHAR(11) because YouTube video IDs are exactly 11 characters
- Channel ID is VARCHAR(24) based on YouTube's channel ID format
- Status column uses string instead of enum for simpler migrations
- `file_size_bytes` is nullable because it's only populated after download completes
- Next ticket (T003) will use these models in the FastAPI application
- Alembic env.py must be configured for async SQLAlchemy
