# VidKeep Development Roadmap

## 📊 Project Status Overview

**Overall Progress: 18/22 tickets (82%)**

### Phase Completion Status

| Phase | Tickets | Status | Progress |
|-------|---------|--------|----------|
| **Phase 1: Foundation** | 4/4 | ✅ COMPLETE | 100% |
| **Phase 2: Ingestion Pipeline** | 4/4 | ✅ COMPLETE | 100% |
| **Phase 3: Streaming Service** | 3/3 | ✅ COMPLETE | 100% |
| **Phase 4: Frontend** | 7/7 | ✅ COMPLETE | 100% |
| **Phase 5: Polish** | 0/4 | ⏳ PENDING | 0% |

### Key Milestones Achieved
- ✅ Docker multi-container setup with PostgreSQL, Redis, and FastAPI
- ✅ Video ingestion pipeline with yt-dlp and ARQ workers
- ✅ HTTP Range-based video streaming with 206 Partial Content support
- ✅ Thumbnail serving with 24-hour cache headers
- ✅ Complete CRUD API for video management
- ✅ Channel aggregation and queue status endpoints
- ✅ React/Vite frontend with Phosphor Console theme (VT323 font, scanlines, green-on-black)
- ✅ Video grid with responsive layout (1-4 columns)
- ✅ Video cards with status badges, progress overlays, and RTL support
- ✅ Action overlay with YouTube, Play, Download buttons and mobile touch support
- ✅ Video player modal with HTML5 player, keyboard shortcuts, and collapsible description
- ✅ Channel filter dropdown and favorites toggle in responsive header
- ✅ Ingest form modal with YouTube URL validation and auto-refresh

### What's Next
Phase 5 (Polish) begins with WebSocket progress updates (T019).

---

## Progress Overview

| Metric | Count |
|--------|-------|
| Total Tickets | 22 |
| Completed | 18 |
| In Progress | 0 |
| Remaining | 4 |

## Current Focus

**Next Ticket**: [T019 - WebSocket Progress Updates](./tickets/T019-websocket-progress.md)

---

## Phase 1: Foundation

Setting up the core infrastructure: Docker, database, API skeleton, and health checks.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T001](./tickets/T001-project-structure-docker.md) | Project Structure & Docker Compose | Complete | None | Docker Compose validated |
| [T002](./tickets/T002-postgresql-alembic.md) | PostgreSQL & Alembic Migrations | Complete | T001 | Video model & migration ready |
| [T003](./tickets/T003-fastapi-skeleton.md) | FastAPI Application Skeleton | Complete | T002 | Schemas, config, CORS ready |
| [T004](./tickets/T004-redis-health-checks.md) | Redis & Health Check Endpoints | Complete | T003 | Phase 1 Complete! |

---

## Phase 2: Ingestion Pipeline

Building the download system: worker queue, yt-dlp integration, and ingest API.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T005](./tickets/T005-arq-worker.md) | ARQ Worker Setup | Complete | T004 | Worker ready for downloads |
| [T006](./tickets/T006-ytdlp-integration.md) | yt-dlp Integration | Complete | T005 | Downloads H.264/AAC/MP4 |
| [T007](./tickets/T007-thumbnail-metadata.md) | Thumbnail & Metadata Extraction | Complete | T006 | JPG conversion, metadata helpers |
| [T008](./tickets/T008-ingest-api.md) | Ingest API Endpoint | Complete | T007 | POST /api/videos/ingest ✓ |

---

## Phase 3: Streaming Service

Implementing video and thumbnail serving with proper HTTP headers.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T009](./tickets/T009-video-streaming.md) | Video Streaming with Range Support | Complete | T001, T003 | Phase 3 started |
| [T010](./tickets/T010-thumbnail-serving.md) | Thumbnail Static Serving | Complete | T007 | 24h cache headers |
| [T011](./tickets/T011-videos-crud-api.md) | Videos CRUD API | Complete | T003 | Phase 3 complete! |

---

## Phase 4: Frontend

Building the React UI: video grid, player, filters, and forms.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T012](./tickets/T012-react-vite-setup.md) | React/Vite Project Setup | Complete | T001 | Phosphor Console theme |
| [T013](./tickets/T013-video-grid.md) | Video Grid Component | Complete | T012 | Responsive 1-4 columns |
| [T014](./tickets/T014-thumbnail-card.md) | Thumbnail Card Component | Complete | T013 | Status overlays, RTL |
| [T015](./tickets/T015-action-overlay.md) | Action Overlay | Complete | T014 | YouTube/Play/Download/Retry |
| [T016](./tickets/T016-video-player-modal.md) | Video Player Modal | Complete | T015 | Keyboard shortcuts, RTL |
| [T017](./tickets/T017-channel-filter-favorites.md) | Channel Filter & Favorites | Complete | T013, T011 | Responsive header with filters |
| [T018](./tickets/T018-ingest-form.md) | Ingest Form | Complete | T008, T012 | Modal with validation |

---

## Phase 5: Polish

Final touches: real-time updates, confirmations, and mobile optimization.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T019](./tickets/T019-websocket-progress.md) | WebSocket Progress Updates | Pending | T006, T014 | Real-time feedback |
| [T020](./tickets/T020-delete-modal.md) | Delete Confirmation Modal | Pending | T016, T011 | Prevents accidents |
| [T021](./tickets/T021-queue-status.md) | Queue Status Indicator | Pending | T011, T017 | Header display |
| [T022](./tickets/T022-error-toasts-mobile.md) | Error Toasts & Mobile Polish | Pending | All | **Final ticket** |

---

## Dependency Graph

```
Phase 1: Foundation
T001 → T002 → T003 → T004

Phase 2: Ingestion (parallel with Phase 3 after T004)
T004 → T005 → T006 → T007 → T008

Phase 3: Streaming (can start after T003)
T003 → T009, T010, T011

Phase 4: Frontend (starts with T012)
T012 → T013 → T014 → T015 → T016
          ↓
       T017, T018

Phase 5: Polish (after frontend)
T019, T020, T021 → T022
```

---

## Comments for Future Tickets

### From T001 to T002
- Volume `vidkeep_data` is configured for /data
- PostgreSQL uses default credentials (change in production)

### From T004 to T005
- Redis connection is established via `app/redis.py`
- Use `get_redis()` helper for connections

### From T006 to T007
- yt-dlp saves thumbnails alongside videos
- Thumbnails need conversion to JPG

### From T011 to T017
- Channels endpoint provides channel names with counts
- Use these for dropdown population

### From T016 to T017
- Modal.tsx is a reusable base component for all modals
- `fetchChannels()` in api/client.ts is ready for dropdown population
- useVideos hook accepts `channel` and `favoritesOnly` options

### From T017 to T018
- Header.tsx can be extended to include the ingest form button
- useVideos hook has `refresh()` function for refreshing after ingest
- Modal.tsx is reusable for the ingest form modal
- `ingestVideo()` in api/client.ts is already implemented

### From T018 to T019
- IngestForm.tsx calls refresh() on success to update video list
- Video cards already have ProgressOverlay component ready for real-time updates
- useVideos hook can be extended for WebSocket subscription
- Download progress is stored in video.download_progress field

---

## Ticket Status Legend

| Status | Meaning |
|--------|---------|
| Pending | Not started |
| In Progress | Currently being worked on |
| Blocked | Waiting on dependency or external factor |
| Complete | Finished and verified |

---

## How to Use This Roadmap

1. **Start with the current focus ticket** (shown at top)
2. **Read the ticket's full specification** in the tickets directory
3. **Implement following the technical specification**
4. **Log progress** in the ticket's Execution Logs table
5. **Update ticket status** in this roadmap when complete
6. **Check Comments section** for context from previous tickets
7. **Update Comments** with relevant info for future tickets
8. **Move to next ticket** based on dependency graph
