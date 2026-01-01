# T001: Project Structure & Docker Compose

## 1. Description

Set up the foundational project structure and Docker Compose configuration for VidKeep. This ticket establishes the directory layout, creates the Docker Compose file with all required services (API, Worker, Frontend, PostgreSQL, Redis), and configures the base Dockerfiles for backend and frontend containers.

**Why**: All subsequent development depends on having a proper project structure and containerized environment. This is the starting point for the entire application.

## 2. Technical Specification

### Files to Create

```
/backend/
  Dockerfile
  requirements.txt
  app/
    __init__.py
/frontend/
  Dockerfile
/docker-compose.yml
/.env.example
/.gitignore
```

### Docker Compose Services

Based on PROJECT.md Section 8:

```yaml
services:
  api:
    build: ./backend
    ports:
      - "8000:8000"
    volumes:
      - vidkeep_data:/data
    env_file:
      - .env
    depends_on:
      - postgres
      - redis

  worker:
    build: ./backend
    command: arq app.worker.WorkerSettings
    volumes:
      - vidkeep_data:/data
    env_file:
      - .env
    deploy:
      replicas: ${WORKER_COUNT:-2}
    depends_on:
      - postgres
      - redis

  frontend:
    build: ./frontend
    ports:
      - "3000:80"

  postgres:
    image: postgres:16-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-vidkeep}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-vidkeep}
      POSTGRES_DB: ${POSTGRES_DB:-vidkeep}

  redis:
    image: redis:7-alpine

volumes:
  vidkeep_data:
  postgres_data:
```

### Environment Variables (.env.example)

```env
# Database
POSTGRES_USER=vidkeep
POSTGRES_PASSWORD=vidkeep
POSTGRES_DB=vidkeep
DATABASE_URL=postgresql+asyncpg://vidkeep:vidkeep@postgres:5432/vidkeep

# Redis
REDIS_URL=redis://redis:6379

# Workers
WORKER_COUNT=2

# Storage
DATA_PATH=/data

# yt-dlp
MAX_VIDEO_HEIGHT=1080
```

### Backend Dockerfile

```dockerfile
FROM python:3.12-slim

WORKDIR /app

# Install FFmpeg for yt-dlp
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Frontend Dockerfile (placeholder)

```dockerfile
FROM node:20-alpine as build
WORKDIR /app
# Will be completed in T012
COPY . .
RUN echo "Frontend placeholder"

FROM nginx:alpine
COPY --from=build /app /usr/share/nginx/html
```

### Dependencies

- None (first ticket)

## 3. Implementation Verification

- [ ] Directory structure matches specification
- [ ] `docker-compose.yml` is valid YAML (run `docker-compose config`)
- [ ] Backend Dockerfile builds successfully (`docker build ./backend`)
- [ ] `.env.example` contains all required variables
- [ ] `.gitignore` excludes `.env`, `__pycache__`, `node_modules`, `.venv`

### Tests to Write

- No code tests for this ticket (infrastructure only)

### Commands to Verify

```bash
# Validate docker-compose
docker-compose config

# Test backend container builds
docker build -t vidkeep-backend ./backend

# Verify directory structure
ls -la backend/ frontend/
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-12-28 | Created backend directory structure | Success | Created backend/Dockerfile, requirements.txt, app/__init__.py |
| 2025-12-28 | Created frontend placeholder | Success | Created frontend/Dockerfile (placeholder for T012) |
| 2025-12-28 | Created docker-compose.yml | Success | All 5 services configured: api, worker, frontend, postgres, redis |
| 2025-12-28 | Created .env.example | Success | All environment variables documented |
| 2025-12-28 | Created .gitignore | Success | Python, Node.js, IDE, Docker, media files excluded |
| 2025-12-28 | Validated docker-compose config | Success | `docker-compose config` passed, all services correctly configured |

## 5. Comments

- The frontend Dockerfile is a placeholder; it will be properly implemented in T012
- The `worker` service uses the same image as `api` but with a different command
- Volume `vidkeep_data` is shared between api and worker for file access
- PostgreSQL credentials are configurable via environment variables
- Next ticket (T002) will add Alembic migrations and the database schema
