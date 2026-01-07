# VidKeep

<p align="center">
  <img src="frontend/public/favicon.svg" alt="VidKeep Logo" width="80" height="80">
</p>

<p align="center">
  <strong>Personal Video Library & Streamer</strong>
</p>

<p align="center">
  A lightweight, self-hosted web application to manage, stream, and archive YouTube content within your home lab environment.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=flat&logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/React-61DAFB?style=flat&logo=react&logoColor=black" alt="React">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat&logo=postgresql&logoColor=white" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/yt--dlp-FF0000?style=flat&logo=youtube&logoColor=white" alt="yt-dlp">
</p>

---

## ✨ Features

- **📥 Easy Video Ingestion** — Paste a YouTube URL, and VidKeep handles the rest
- **🎬 Dual-Source Viewing** — Watch from your local server or open the original on YouTube
- **📱 Mobile-Friendly Downloads** — Videos stored in universal MP4/H.264 format for offline viewing
- **📺 Channel Organization** — Automatic grouping by YouTube channel with filtering
- **⭐ Favorites** — Mark and filter your favorite videos
- **🌐 RTL Support** — Full support for Arabic and other RTL titles
- **📊 Real-Time Progress** — WebSocket-powered download progress with live updates
- **🎨 Retro Terminal Theme** — Unique Phosphor Console aesthetic with VT323 font

## 🖥️ Screenshots

<details>
<summary>Click to view screenshots</summary>

*Coming soon*

</details>

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | React (Vite) + Tailwind CSS |
| **Backend** | FastAPI (Python) |
| **Database** | PostgreSQL |
| **Task Queue** | Embedded Worker Pool (Redis-based) |
| **Storage** | Local filesystem |
| **Downloader** | yt-dlp + FFmpeg |
| **Real-time** | WebSocket + Redis Pub/Sub |

## 📋 Prerequisites

- **Docker** and **Docker Compose** installed
- Sufficient disk space (~500MB per 1080p video)
- Network access to YouTube

## 🚀 Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/VidKeep.git
cd VidKeep
```

### 2. Start with Docker Compose

```bash
docker-compose up -d
```

### 3. Access the application

- **Application**: http://localhost:3001
- **API Docs**: http://localhost:3001/docs
- **Metrics**: http://localhost:3001/metrics

## ⚙️ Configuration

### Environment Variables

Create a `.env` file or modify `docker-compose.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | `postgresql+asyncpg://vidkeep:vidkeep@postgres:5432/vidkeep` | PostgreSQL connection string |
| `REDIS_URL` | `redis://redis:6379` | Redis connection string |
| `DATA_PATH` | `/data` | Volume mount path for videos |
| `MAX_VIDEO_HEIGHT` | `1080` | Maximum video resolution |
| `MAX_WORKERS` | `2` | Number of concurrent download workers |

### Example `.env` files

See [`backend/.env.example`](backend/.env.example) and [`frontend/.env.example`](frontend/.env.example) for reference.

## 📁 Project Structure

```
VidKeep/
├── Dockerfile              # Unified multi-stage build
├── docker-compose.yml
├── backend/                # FastAPI backend
│   ├── app/
│   │   ├── routers/        # API endpoints
│   │   ├── services/       # Business logic (WorkerManager, metrics)
│   │   └── tasks/          # Download task
│   ├── alembic/            # Database migrations
│   └── requirements.txt
├── frontend/               # React frontend
│   └── src/
│       ├── components/     # UI components
│       ├── hooks/          # Custom React hooks
│       └── api/            # API client
└── docs/                   # Documentation & tickets
```

## 🎥 Video Format

VidKeep downloads videos in a universal format for maximum compatibility:

| Component | Specification |
|-----------|---------------|
| **Video Codec** | H.264 (AVC) |
| **Audio Codec** | AAC |
| **Container** | MP4 |
| **Max Resolution** | 1080p |

This ensures native playback in all modern browsers and mobile devices.

## 📡 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/videos/ingest` | Submit YouTube URL for download |
| `GET` | `/api/videos` | List all videos (with filters) |
| `GET` | `/api/videos/{id}` | Get video metadata |
| `PATCH` | `/api/videos/{id}` | Update favorite status |
| `DELETE` | `/api/videos/{id}` | Remove video and files |
| `GET` | `/api/stream/{id}` | Stream video (with range support) |
| `GET` | `/api/thumbnail/{id}` | Serve thumbnail image |
| `GET` | `/api/channels` | List unique channels |
| `GET` | `/api/queue/status` | Queue depth and status |

Full API documentation available at `/docs` when running.

## ⌨️ Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` / `K` | Play / Pause |
| `←` | Seek -10 seconds |
| `→` | Seek +10 seconds |
| `↑` / `↓` | Volume up / down |
| `M` | Toggle mute |
| `F` | Toggle fullscreen |
| `Escape` | Close modal |

## 🔧 Development

### Running locally without Docker

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
```

### Running database migrations

```bash
docker-compose exec app alembic upgrade head
```

## 📜 Data Storage

Videos and thumbnails are stored in a Docker volume:

```
/data/
├── videos/
│   └── {video_id}.mp4
└── thumbnails/
    └── {video_id}.jpg
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## ⚠️ Disclaimer

This project is for personal archival use only. Please respect YouTube's Terms of Service and copyright laws in your jurisdiction.

---

<p align="center">
  Made with ❤️ for the self-hosted community
</p>
