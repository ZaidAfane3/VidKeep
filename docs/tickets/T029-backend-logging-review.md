# T029: Backend Logging Review and Optimization

**Status:** Not Started  
**Priority:** Medium  
**Type:** Tech Debt / DevOps  

---

## 1. Problem Statement

The current backend logging configuration is overly verbose for production use, resulting in:
- **Duplicate log entries** for every SQL query
- **Full SQL query text** logged for every database operation
- **Transaction boundary spam** (BEGIN, ROLLBACK, COMMIT logs)
- **Health check noise** polluting logs every ~30 seconds
- **yt-dlp verbose output** during downloads
- Increased disk usage and reduced log signal-to-noise ratio

### Current Log Sample (Problematic)
```
app-1  | 2026-01-10 09:10:57,450 INFO sqlalchemy.engine.Engine SELECT videos.video_id, videos.title...
app-1  | FROM videos 
app-1  | WHERE videos.channel_name = $1::VARCHAR AND videos.is_favorite = true ORDER BY videos.created_at DESC
app-1  | 2026-01-10 09:10:57,450 INFO sqlalchemy.engine.Engine [cached since 4170s ago] ('Czardus',)
app-1  | 2026-01-10 09:10:57,450 - sqlalchemy.engine.Engine - INFO - SELECT videos.video_id, videos.title...
app-1  | FROM videos 
app-1  | WHERE videos.channel_name = $1::VARCHAR AND videos.is_favorite = true ORDER BY videos.created_at DESC
app-1  | 2026-01-10 09:10:57,450 - sqlalchemy.engine.Engine - INFO - [cached since 4170s ago] ('Czardus',)
app-1  | INFO:     142.251.37.142:21030 - "GET /api/videos?channel=Czardus&favorites_only=true HTTP/1.1" 200 OK
app-1  | 2026-01-10 09:10:57,454 - sqlalchemy.engine.Engine - INFO - ROLLBACK
app-1  | 2026-01-10 09:10:57,454 INFO sqlalchemy.engine.Engine ROLLBACK
app-1  | INFO:     127.0.0.1:35126 - "GET /health HTTP/1.1" 200 OK
```

**Issues visible:**
1. Every SQL query appears **twice** (duplicate handlers)
2. Full SQL text logged including parameters
3. ROLLBACK/COMMIT spam for every request
4. `/health` endpoint clogs logs

---

## 2. Root Cause Analysis

### 2.1 SQLAlchemy Echo Mode
**File:** [`backend/app/database.py`](file:///Users/zafaneh/Developer/Personal/ViKeep/backend/app/database.py)

```python
engine = create_async_engine(DATABASE_URL, echo=True)  # Line 12
```

The `echo=True` parameter enables SQLAlchemy's built-in query logging at INFO level. This causes:
- Full SQL statements to be printed
- Connection pool events to be logged
- Transaction boundaries (BEGIN, COMMIT, ROLLBACK) to appear

### 2.2 Duplicate Handlers
**File:** [`backend/app/main.py`](file:///Users/zafaneh/Developer/Personal/ViKeep/backend/app/main.py)

```python
logging.basicConfig(                    # Lines 18-21
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

Combined with SQLAlchemy's internal logging and uvicorn's logger, this creates duplicate output because:
- `logging.basicConfig()` adds a StreamHandler to the root logger
- SQLAlchemy's engine logger propagates to root
- Result: each SQLAlchemy log message appears twice with different formats

### 2.3 No Health Check Filtering
Uvicorn logs all HTTP requests including `/health` probes (Kubernetes liveness/readiness checks), which execute every 10-30 seconds.

### 2.4 Log Sources in VidKeep

| Component | What It Logs |
|-----------|--------------|
| App code (`app.*`) | Business logic, worker lifecycle |
| SQLAlchemy | Queries, transactions, pool events |
| uvicorn/FastAPI | HTTP access logs |
| yt-dlp | Download progress, errors |
| WebSocket | Connection events |

---

## 3. Proposed Solution: Unified Log Level

> [!IMPORTANT]
> Instead of multiple environment variables (LOG_LEVEL, SQL_LOG_LEVEL, ACCESS_LOG_LEVEL, etc.), use a **single unified variable** with sensible per-component mappings.

### 3.1 Single Variable Design

```bash
LOG_LEVEL=INFO   # That's it. One variable.
```

### 3.2 Mapping Table

| LOG_LEVEL | App Code | SQLAlchemy | uvicorn | yt-dlp | SQL Echo |
|-----------|----------|------------|---------|--------|----------|
| `ERROR` | ERROR | ERROR | ERROR | quiet | off |
| `WARNING` | WARNING | WARNING | WARNING | quiet | off |
| `INFO` | INFO | WARNING | INFO | normal | off |
| `DEBUG` | DEBUG | INFO | DEBUG | verbose | off |
| `TRACE` | DEBUG | DEBUG | DEBUG | verbose | on |

**Why the mappings aren't 1:1:**
- **SQLAlchemy stays at WARNING when app is INFO** - SQL logs are extremely noisy, you only want them when explicitly debugging DB issues
- **SQL echo only turns on at TRACE** - it's the nuclear option
- **yt-dlp stays quiet at WARNING/ERROR** - its output is verbose even at "normal"

### 3.3 Implementation

**New file:** `backend/app/core/logging_config.py`

```python
import os
import logging

# Register TRACE level (below DEBUG=10)
TRACE = 5
logging.addLevelName(TRACE, "TRACE")

LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()

# Use logging constants for explicit level setting
_LOG_MAPPINGS = {
    "ERROR":   {"app": logging.ERROR,   "sqlalchemy": logging.ERROR,   "uvicorn": logging.ERROR,   "ytdlp": "quiet",   "sql_echo": False},
    "WARNING": {"app": logging.WARNING, "sqlalchemy": logging.WARNING, "uvicorn": logging.WARNING, "ytdlp": "quiet",   "sql_echo": False},
    "INFO":    {"app": logging.INFO,    "sqlalchemy": logging.WARNING, "uvicorn": logging.INFO,    "ytdlp": "normal",  "sql_echo": False},
    "DEBUG":   {"app": logging.DEBUG,   "sqlalchemy": logging.INFO,    "uvicorn": logging.DEBUG,   "ytdlp": "verbose", "sql_echo": False},
    "TRACE":   {"app": TRACE,           "sqlalchemy": logging.DEBUG,   "uvicorn": logging.DEBUG,   "ytdlp": "verbose", "sql_echo": True},
}


def get_config():
    """Get logging configuration for current LOG_LEVEL."""
    return _LOG_MAPPINGS.get(LOG_LEVEL, _LOG_MAPPINGS["INFO"])


def configure_logging():
    """Configure all loggers based on unified LOG_LEVEL."""
    config = get_config()
    
    # Root logger setup
    logging.basicConfig(
        level=config["app"],
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    # App loggers (explicit constant, no string conversion)
    logging.getLogger("app").setLevel(config["app"])
    
    # SQLAlchemy - kept quieter than app by default
    logging.getLogger("sqlalchemy.engine").setLevel(config["sqlalchemy"])
    logging.getLogger("sqlalchemy.pool").setLevel(config["sqlalchemy"])
    
    # Uvicorn access logs
    logging.getLogger("uvicorn.access").setLevel(config["uvicorn"])
    
    # Suppress overly chatty libraries at all levels
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    
    # Add health check filter
    logging.getLogger("uvicorn.access").addFilter(HealthCheckFilter())


class HealthCheckFilter(logging.Filter):
    """Filter out noisy health check requests."""
    def filter(self, record: logging.LogRecord) -> bool:
        return "/health" not in record.getMessage()


def get_sql_echo() -> bool:
    """Get SQL echo setting for SQLAlchemy engine."""
    return get_config()["sql_echo"]


def get_ytdlp_verbosity() -> str:
    """Get yt-dlp verbosity level."""
    return get_config()["ytdlp"]
```

### 3.4 Usage in Other Files

**`backend/app/database.py`:**
```python
from app.core.logging_config import get_sql_echo

engine = create_async_engine(DATABASE_URL, echo=get_sql_echo())
```

**`backend/app/tasks/download.py`:**
```python
from app.core.logging_config import get_ytdlp_verbosity

def get_ydl_opts():
    verbosity = get_ytdlp_verbosity()
    return {
        "quiet": verbosity == "quiet",
        "verbose": verbosity == "verbose",
        # ... other options
    }
```

**`backend/app/main.py`:**
```python
from app.core.logging_config import configure_logging

# Replace logging.basicConfig() with:
configure_logging()
```

---

## 4. What Each Level Shows

### Production (LOG_LEVEL=INFO, default)
```
app-1  | 2026-01-10 09:10:57,450 - app.main - INFO - Starting VidKeep API with 1 embedded workers
app-1  | 2026-01-10 09:10:57,600 - app.services.worker_manager - INFO - WorkerManager started successfully
app-1  | INFO:     142.251.37.142:21030 - "GET /api/videos?channel=Czardus HTTP/1.1" 200 OK
app-1  | 2026-01-10 09:11:00,000 - app.services.worker_manager - INFO - Claimed job dQw4w9WgXcQ
app-1  | 2026-01-10 09:11:00,050 - app.services.worker_manager - INFO - Spawned worker 12345
app-1  | 2026-01-10 09:12:00,000 - app.services.worker_manager - INFO - Worker finished for video dQw4w9WgXcQ
```

- ✅ App startup/shutdown
- ✅ Worker lifecycle (spawn, finish)
- ✅ Job claims and completions
- ✅ HTTP requests (200, 404, 500)
- ✅ Download start/complete
- ❌ No SQL queries
- ❌ No yt-dlp verbose output
- ❌ No health check spam

### Development (LOG_LEVEL=DEBUG)
- ✅ Everything from INFO
- ✅ Detailed app tracing
- ✅ SQLAlchemy connection pool events
- ✅ yt-dlp verbose output
- ❌ No raw SQL (use TRACE for that)

### Database Debugging (LOG_LEVEL=TRACE)
- ✅ Everything from DEBUG
- ✅ Full SQL statements with parameters
- ✅ BEGIN/COMMIT/ROLLBACK
- ⚠️ Very noisy - don't run in production

---

## 5. Configuration

### Environment Variable

| Variable | Default | Values |
|----------|---------|--------|
| `LOG_LEVEL` | `INFO` | `ERROR`, `WARNING`, `INFO`, `DEBUG`, `TRACE` |

### Benefits
1. **One thing to remember** - operators don't need to know which internal variables exist
2. **Sensible defaults** - noisy components are quieter than verbose ones at each level
3. **Single place to update** - adding a new component means updating one mapping table
4. **Standard levels** - ERROR/WARNING/INFO/DEBUG are familiar to everyone, TRACE is a common extension

---

## 6. Files to Modify

| File | Change |
|------|--------|
| [`backend/app/core/logging_config.py`](file:///Users/zafaneh/Developer/Personal/ViKeep/backend/app/core/logging_config.py) | **[NEW]** Centralized logging configuration module |
| [`backend/app/database.py`](file:///Users/zafaneh/Developer/Personal/ViKeep/backend/app/database.py) | Use `get_sql_echo()` instead of hardcoded `echo=True` |
| [`backend/app/main.py`](file:///Users/zafaneh/Developer/Personal/ViKeep/backend/app/main.py) | Replace `logging.basicConfig()` with `configure_logging()` |
| [`backend/app/tasks/download.py`](file:///Users/zafaneh/Developer/Personal/ViKeep/backend/app/tasks/download.py) | Use `get_ytdlp_verbosity()` for yt-dlp options |

---

## 7. Verification Plan

### 7.1 Manual Testing

| Step | Action | Expected Result |
|------|--------|-----------------|
| 1 | Start with `LOG_LEVEL=INFO` (default) | Clean logs, no SQL spam |
| 2 | Hit `/api/videos` multiple times | HTTP logs visible, no SQL |
| 3 | Wait 1 minute | No `/health` entries |
| 4 | Restart with `LOG_LEVEL=DEBUG` | More verbose, still no raw SQL |
| 5 | Restart with `LOG_LEVEL=TRACE` | Full SQL with parameters visible |
| 6 | Start a download | yt-dlp output matches verbosity level |
| 7 | **Negative test:** Submit invalid video URL | Error logged at all levels including ERROR |
| 8 | **Negative test:** Try to delete non-existent video | 404 error logged, not silenced |

### 7.2 Regression Check
- Ensure all existing functionality works (video list, download, stream)
- Verify error logs still appear for actual errors (not silenced)

---

## 8. Out of Scope

- Log aggregation / centralized logging (ELK, Loki, etc.)
- Structured JSON logging
- Log rotation configuration
- Frontend logging

---

## 9. References

- [SQLAlchemy Engine Configuration](https://docs.sqlalchemy.org/en/20/core/engines.html#configuring-logging)
- [Python Logging HOWTO](https://docs.python.org/3/howto/logging.html)
- [Uvicorn Access Log Configuration](https://www.uvicorn.org/settings/#logging)
