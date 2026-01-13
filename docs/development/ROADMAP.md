# VidKeep Development Roadmap

## 📊 Project Status Overview

**Overall Progress: 32/34 tickets (94%) | Phases 1-6 Complete ✅ | T026, T027, T028 Complete ✅**

### Phase Completion Status

| Phase | Tickets | Status | Progress | Testing |
|-------|---------|--------|----------|---------|
| **Phase 1: Foundation** | 4/4 | ✅ COMPLETE | 100% | ✅ |
| **Phase 2: Ingestion Pipeline** | 4/4 | ✅ COMPLETE | 100% | ✅ |
| **Phase 3: Streaming Service** | 3/3 | ✅ COMPLETE | 100% | ✅ |
| **Phase 4: Frontend** | 7/7 | ✅ COMPLETE & TESTED | 100% | ✅ |
| **Phase 5: Polish** | 4/4 | ✅ COMPLETE | 100% | ✅ |
| **Phase 6: Enhancements & Fixes** | 7/7 | ✅ COMPLETE | 100% | ✅ |
| **Phase 7: Future** | 4/6 | 🔨 IN PROGRESS | 67% | ✅ |

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
- ✅ **Phase 4 Frontend Testing Complete: 126/126 tests passed (100%)**
  - T012-T018: All features tested and verified
  - Error Handling: 3/3 tests (graceful backend failures, network timeouts)
  - Performance: 4/4 tests (< 3s load time, 63.5KB gzipped, no console errors, no memory leaks)
  - Cross-Browser: 6/6 browsers tested (Chrome, Firefox, Safari, Edge, Mobile Safari, Chrome Mobile)
- ✅ **Phase 5 Polish Complete:**
  - WebSocket real-time progress updates with Redis pub/sub
  - Delete confirmation modal with video details and file size
  - Toast notification system (success, error, warning, info types)
  - Queue status indicator in header (compact and full variants)
  - Mobile polish: touch targets, safe areas, tap highlight removal

### Core Features Complete! 🎉
All 29 implementation and bug-fix tickets across 6 phases have been implemented and tested.

- ✅ **Phase 6 Enhancements & Fixes Complete:**
  - T023: Cancel download with Redis flag and partial file cleanup
  - T024: Custom favicon with `>_` terminal prompt design (SVG + PNG)
  - T025: Data saver mode with network detection and polling adjustments
  - BUG-001: WebSocket singleton pattern fixes dev-mode double connections
  - BUG-002: Fixed Android action buttons triggering when invisible
  - BUG-003: Fixed download progress resetting at 100% and delayed status color
  - BUG-004: Fixed video status not updating from queued to downloading
  - iOS safe area support for footer (home indicator area)

- ✅ **Phase 7 T028 Embedded Worker Process Pool Complete:**
  - Replaced ARQ workers with embedded process pool (WorkerManager)
  - Redis-based job queue (`vidkeep:jobs:pending`, `vidkeep:jobs:processing`)
  - Heartbeat-based crash detection and stale job recovery
  - Download resume from partial files
  - Prometheus metrics endpoint (`/metrics`) with 7 custom metrics
  - Retry tracking with max 3 retries
  - Frontend UI updates: `resuming` status, retry badges

- ✅ **Phase 7 T026 Monolith Merge Complete:**
  - Merged frontend (React/Vite) and backend (FastAPI) into single container
  - Multi-stage Dockerfile at project root
  - SPA catch-all route with proper API 404 handling
  - Deleted `frontend/Dockerfile` and `frontend/nginx.conf`
  - App served on port 3001

---

## Progress Overview

| Total Tickets | 34 |
| Completed | 32 |
| In Progress | 1 |
| Planned | 1 |

## Current Focus

**T029 Mobile Offline Playback In Progress!** 🎉 Implementation complete, ready for manual testing on iOS/Android devices.

---

## Phase 1: Foundation

Setting up the core infrastructure: Docker, database, API skeleton, and health checks.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T001](../tickets/T001-project-structure-docker.md) | Project Structure & Docker Compose | Complete | None | Docker Compose validated |
| [T002](../tickets/T002-postgresql-alembic.md) | PostgreSQL & Alembic Migrations | Complete | T001 | Video model & migration ready |
| [T003](../tickets/T003-fastapi-skeleton.md) | FastAPI Application Skeleton | Complete | T002 | Schemas, config, CORS ready |
| [T004](../tickets/T004-redis-health-checks.md) | Redis & Health Check Endpoints | Complete | T003 | Phase 1 Complete! |

---

## Phase 2: Ingestion Pipeline

Building the download system: worker queue, yt-dlp integration, and ingest API.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T005](../tickets/T005-arq-worker.md) | ARQ Worker Setup | Complete | T004 | Worker ready for downloads |
| [T006](../tickets/T006-ytdlp-integration.md) | yt-dlp Integration | Complete | T005 | Downloads H.264/AAC/MP4 |
| [T007](../tickets/T007-thumbnail-metadata.md) | Thumbnail & Metadata Extraction | Complete | T006 | JPG conversion, metadata helpers |
| [T008](../tickets/T008-ingest-api.md) | Ingest API Endpoint | Complete | T007 | POST /api/videos/ingest ✓ |

---

## Phase 3: Streaming Service

Implementing video and thumbnail serving with proper HTTP headers.

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T009](../tickets/T009-video-streaming.md) | Video Streaming with Range Support | Complete | T001, T003 | Phase 3 started |
| [T010](../tickets/T010-thumbnail-serving.md) | Thumbnail Static Serving | Complete | T007 | 24h cache headers |
| [T011](../tickets/T011-videos-crud-api.md) | Videos CRUD API | Complete | T003 | Phase 3 complete! |

---

## Phase 4: Frontend

Building the React UI: video grid, player, filters, and forms. **✅ TESTING COMPLETE (126/126 tests)**

| Ticket | Title | Status | Testing | Comments |
|--------|-------|--------|---------|----------|
| [T012](../tickets/T012-react-vite-setup.md) | React/Vite Project Setup | Complete | ✅ 7/7 | Phosphor Console theme tested |
| [T013](../tickets/T013-video-grid.md) | Video Grid Component | Complete | ✅ 7/7 | Responsive 1-4 columns, empty state, loading state tested |
| [T014](../tickets/T014-thumbnail-card.md) | Thumbnail Card Component | Complete | ✅ 12/12 | Status overlays, RTL, favorites tested |
| [T015](../tickets/T015-action-overlay.md) | Action Overlay | Complete | ✅ 16/16 | YouTube/Play/Download/Delete/Retry, tap/swipe detection tested |
| [T016](../tickets/T016-video-player-modal.md) | Video Player Modal | Complete | ✅ 24/24 | All keyboard shortcuts, description panel, RTL tested |
| [T017](../tickets/T017-channel-filter-favorites.md) | Channel Filter & Favorites | Complete | ✅ 17/17 | Filter dropdown, combined filters, responsiveness tested |
| [T018](../tickets/T018-ingest-form.md) | Ingest Form | Complete | ✅ 24/24 | URL validation, error handling, network failure tested |

---

## Phase 5: Polish

Final touches: real-time updates, confirmations, and mobile optimization. **✅ ALL COMPLETE**

| Ticket | Title | Status | Dependencies | Comments |
|--------|-------|--------|--------------|----------|
| [T019](../tickets/T019-websocket-progress.md) | WebSocket Progress Updates | Complete | T006, T014 | Redis pub/sub, auto-reconnect |
| [T020](../tickets/T020-delete-modal.md) | Delete Confirmation Modal | Complete | T016, T011 | Video details, loading state |
| [T021](../tickets/T021-queue-status.md) | Queue Status Indicator | Complete | T011, T017 | Compact + full variants |
| [T022](../tickets/T022-error-toasts-mobile.md) | Error Toasts & Mobile Polish | Complete | All | Toast system + mobile CSS |

---

## Phase 6: Enhancements & Fixes

Optional enhancements and bugfixes. **✅ ALL COMPLETE**

| Ticket | Title | Type | Status | Priority | Comments |
|--------|-------|------|--------|----------|----------|
| [T023](../tickets/T023-cancel-download.md) | Cancel Download with Cleanup | Feature | Complete | Medium | Cancel button, Redis flag, cleanup task |
| [T024](../tickets/T024-favicon.md) | Favicon Matching App Logo | Feature | Complete | Low | `>_` terminal prompt, all sizes generated |
| [T025](../tickets/T025-optimize-data-usage.md) | Optimize Data Usage for Cellular | Feature | Complete | Low | Data saver toggle, polling adjustments |
| [BUG-001](../tickets/BUG-001-websocket-multiple-connections.md) | WebSocket Multiple Connections (Dev) | Bug | Complete | Low | Singleton WebSocket pattern implemented |
| [BUG-002](../tickets/BUG-002-android-action-buttons-invisible-click.md) | Android Action Buttons Invisible Click | Bug | Complete | Medium | Added `e.preventDefault()` in touchEnd, media query for hover |
| [BUG-003](../tickets/BUG-003-download-progress-reset-and-delayed-status.md) | Download Progress Reset at 100% | Bug | Complete | Low | Backend sends completion messages, frontend auto-refreshes |
| [BUG-004](../tickets/BUG-004-video-status-not-updating-queued-to-downloading.md) | Video Status Not Updating Queued→Downloading | Bug | Complete | Medium | Infer status from progress, WebSocket status messages |

---

## Phase 7: Future Enhancements

Planned future tickets for extended functionality. **📋 PLANNED**

| Ticket | Title | Type | Status | Priority | Comments |
|--------|-------|------|--------|----------|----------|
| [T026](../tickets/T026-monolith-merge-evaluation.md) | Frontend/Backend Monolith Merge | Architecture | **Complete** | Medium | Merged into single container, multi-stage Dockerfile |
| [T027](../tickets/T027-flutter-mobile-app.md) | VidKeep Flutter Mobile App | Feature | **Complete** | Medium | Phases 1-8 Complete (Setup→Testing), 44 tests passing |
| [T028](../tickets/T028-embedded-worker-process-pool.md) | Embedded Worker Process Pool | Architecture | **Complete** | Medium | Replaced ARQ with embedded WorkerManager, Prometheus metrics, resume capability |
| [BUG-005](../tickets/BUG-005-favorite-icon-not-updating.md) | Mobile: Favorite Icon Not Updating | Bug | **Complete** | Medium | Fixed state watching in VideoDetailScreen and VideoCard |
| [T029](../tickets/T029-offline-playback.md) | Mobile Offline Playback | Feature | **In Progress** | Medium | Download videos for offline viewing, background downloads, storage management |
| [T030](../tickets/T030-android-carlinkit-testing.md) | Android CarLinkit TBox Testing | Testing | **Planned** | Medium | Configure and test app on Android 13 for in-car CarLinkit device |

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

Phase 6: Enhancements & Fixes (can be implemented anytime):
T023 (depends on T006 worker infrastructure)
T024 (standalone, no dependencies)
T025 (depends on T019 WebSocket, T021 Queue Status)
BUG-001, BUG-002, BUG-003, BUG-004 (bug fixes)

Phase 7: Future (independent/parallel):
T027 (Mobile App - standalone)
T028 (Embedded Workers - architecture refactor)
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
