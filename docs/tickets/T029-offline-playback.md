# T029: VidKeep Mobile Offline Playback

## 1. Overview

**Ticket Type**: Feature Development  
**Priority**: Medium  
**Platforms**: Android + iOS  
**Dependencies**: T027 (Flutter Mobile App)  
**Scope**: Full Implementation

### Summary

Enable users to download videos from their VidKeep library to their mobile device for offline viewing. This includes background downloads, storage management, and seamless offline/online playback.

---

## 2. Finalized Decisions

| # | Decision | Choice | Details |
|---|----------|--------|---------|
| 1 | Download Scope | **A: Video only** | Video file only, thumbnail/metadata fetched from cache |
| 2 | Storage Location | **Public folders** | iOS: Files app accessible / Android: File manager accessible |
| 3 | Download Trigger | **A: Manual only** | Explicit download button, no auto-downloads |
| 4 | Background Behavior | **B: Background download** | Continues after app close, graceful resume |
| 5 | Storage Management | **A: Manual delete** | User controls what to keep/delete |
| 6 | Offline UI | **A: Badge on card** | Downloaded icon overlay on video cards |
| 7 | Concurrent Downloads | **C: Configurable** | User sets 1-5 in settings |
| 8 | WiFi-Only | **B: Default + toggle** | WiFi-only by default, optional cellular |

### Additional Features Confirmed

- ✅ **Low Battery Mode**: Pause downloads when device enters low battery mode
- ✅ **iOS URLSession**: Accept iOS background limitations (works like YouTube/Netflix)
- ✅ **Configurable Storage Limit**: User-defined quota including DB + media + thumbnails

---

## 3. Technical Architecture

### 3.1 Package Selection

| Component | Package | Purpose |
|-----------|---------|---------|
| Background downloads | `background_downloader` | iOS URLSession + Android DownloadManager |
| Local database | `drift` (SQLite) | Track downloaded videos, status, paths |
| File storage | `path_provider` | Get public document directories |
| Battery status | `battery_plus` | Detect low battery mode |
| Connectivity | `connectivity_plus` | WiFi vs cellular detection |

### 3.2 Data Models

```dart
enum LocalDownloadStatus {
  pending,      // Queued for download
  downloading,  // Currently downloading
  paused,       // Paused (low battery, user action, or network)
  complete,     // Successfully downloaded
  failed,       // Download failed
}

class DownloadedVideo {
  final String videoId;
  final String localFilePath;
  final DateTime downloadedAt;
  final int fileSizeBytes;
  final LocalDownloadStatus status;
  final double progress;        // 0.0 - 1.0
  final String? errorMessage;
}

class DownloadSettings {
  final bool wifiOnly;          // Default: true
  final int maxConcurrent;      // Default: 2, range 1-5
  final int? storageLimitMB;    // null = unlimited
  final bool pauseOnLowBattery; // Default: true
}
```

### 3.3 Storage Locations

| Platform | Path | User Access |
|----------|------|-------------|
| iOS | `Documents/VidKeep/` | Visible in Files app |
| Android | `Downloads/VidKeep/` or `Movies/VidKeep/` | Visible in file manager |

### 3.4 Database Schema

```sql
CREATE TABLE downloaded_videos (
  video_id TEXT PRIMARY KEY,
  local_path TEXT NOT NULL,
  downloaded_at INTEGER NOT NULL,
  file_size_bytes INTEGER NOT NULL,
  status TEXT NOT NULL,
  progress REAL DEFAULT 0.0,
  error_message TEXT
);

CREATE TABLE download_settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  wifi_only INTEGER DEFAULT 1,
  max_concurrent INTEGER DEFAULT 2,
  storage_limit_mb INTEGER,
  pause_on_low_battery INTEGER DEFAULT 1
);
```

---

## 4. Implementation Phases

### Phase 1: Core Download Service (2 days)
- [ ] Add `background_downloader` and `drift` packages
- [ ] Create download database and models
- [ ] Implement `DownloadService` with queue management
- [ ] Download button in video detail screen
- [ ] Basic progress tracking

### Phase 2: Storage & Settings (1 day)
- [ ] Public folder storage for iOS/Android
- [ ] Settings screen for download preferences
- [ ] Storage usage calculation and display
- [ ] Configurable concurrent downloads (1-5)
- [ ] WiFi-only toggle

### Phase 3: Offline Playback (1 day)
- [ ] Detect if video is downloaded
- [ ] Play from local file instead of stream
- [ ] Downloaded badge on video cards
- [ ] Works without internet connection

### Phase 4: Smart Features (1 day)
- [ ] Low battery mode detection and pause
- [ ] Storage quota enforcement
- [ ] Background download notifications
- [ ] Resume interrupted downloads

### Phase 5: Polish & Testing (1 day)
- [ ] Delete downloaded videos
- [ ] Error handling and retry
- [ ] Integration tests
- [ ] iOS/Android testing

---

## 5. UI Changes

### 5.1 Video Detail Screen
- Add "DOWNLOAD" button in action bar
- Show download progress during download
- Change to "DOWNLOADED ✓" when complete
- Add "DELETE DOWNLOAD" option

### 5.2 Video Card
- Small download badge (↓) overlay on thumbnail for downloaded videos
- Optional: Different border color for downloaded

### 5.3 Settings Screen (New Section)
```
DOWNLOADS
├── WiFi only           [Toggle: ON]
├── Concurrent downloads [Picker: 1-5, default 2]
├── Pause on low battery [Toggle: ON]
├── Storage limit        [Picker: Unlimited/1GB/5GB/10GB/Custom]
└── Storage used         [Progress bar: 2.3 GB of 10 GB]
```

### 5.4 Downloads Management
- Option A: "Downloads" section in existing settings
- Option B: Dedicated downloads screen (shows all downloaded videos)

---

## 6. Acceptance Criteria

- [ ] User can download a video by tapping download button
- [ ] Download continues in background after app close
- [ ] Downloaded videos play offline (no internet required)
- [ ] Downloaded videos show badge on card
- [ ] Downloads pause on low battery mode
- [ ] WiFi-only mode prevents cellular downloads
- [ ] User can configure concurrent downloads (1-5)
- [ ] User can set storage limit
- [ ] User can delete downloaded videos
- [ ] Downloads visible in iOS Files / Android file manager

---

## 7. Estimated Effort

| Phase | Days |
|-------|------|
| Core Download Service | 2 |
| Storage & Settings | 1 |
| Offline Playback | 1 |
| Smart Features | 1 |
| Polish & Testing | 1 |
| **Total** | **6 days** |

---

## 8. Execution Log

| Date | Phase | Action | Details |
|------|-------|--------|---------|
| 2026-01-12 | Planning | Ticket created | Decision matrix completed |
| 2026-01-12 | Planning | Decisions finalized | All 8 decisions + additional features confirmed |
