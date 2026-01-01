# VidKeep UI/UX Design Specification

**Document Version**: 1.0
**Last Updated**: December 2024
**Prepared For**: UI/UX Design Team

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Overview](#2-product-overview)
3. [User Personas & Use Cases](#3-user-personas--use-cases)
4. [Information Architecture](#4-information-architecture)
5. [Design System](#5-design-system)
6. [Screen Specifications](#6-screen-specifications)
7. [Component Library](#7-component-library)
8. [User Flows](#8-user-flows)
9. [Interaction Patterns](#9-interaction-patterns)
10. [Responsive Design Requirements](#10-responsive-design-requirements)
11. [Accessibility Requirements](#11-accessibility-requirements)
12. [API Data Reference](#12-api-data-reference)
13. [Assets & Deliverables](#13-assets--deliverables)

---

## 1. Executive Summary

### Project Name
**VidKeep** — Personal Video Library & Streamer

### Purpose
VidKeep is a self-hosted web application that allows users to archive, organize, and stream YouTube videos within a private home lab environment. The application provides a clean, single-view interface to manage a personal video library.

### Primary Goals
- Enable users to easily ingest YouTube videos by pasting URLs
- Provide a visually appealing grid-based library view
- Support dual-source viewing (YouTube original or local stream)
- Allow mobile-friendly downloads for offline viewing
- Support RTL (Arabic) text for international content

### Target Platform
- **Primary**: Desktop web browsers (Chrome, Firefox, Safari)
- **Secondary**: Mobile browsers (iOS Safari, Android Chrome)
- **Environment**: Self-hosted on local network / Tailscale

---

## 2. Product Overview

### Core Features

| Feature | Description | Priority |
|---------|-------------|----------|
| Video Grid | Responsive thumbnail grid displaying all archived videos | P0 |
| Video Ingestion | URL input form to queue YouTube videos for download | P0 |
| Local Streaming | In-app video player with seek support | P0 |
| Channel Filtering | Filter videos by YouTube channel | P1 |
| Favorites | Mark and filter favorite videos | P1 |
| Download Progress | Real-time progress overlay during downloads | P1 |
| Delete Confirmation | Protected deletion with confirmation modal | P2 |
| Queue Status | Display active download queue depth | P2 |

### Video Status States

Videos progress through these states:

```
pending → downloading → complete
                    ↘ failed
```

| State | Visual Indicator | User Can... |
|-------|------------------|-------------|
| `pending` | Yellow badge, spinner | Wait |
| `downloading` | Blue badge, progress % | Wait |
| `complete` | Duration badge | Play, Download, Open YouTube |
| `failed` | Red badge, error message | Retry |

---

## 3. User Personas & Use Cases

### Primary Persona: Home Lab Enthusiast

**Profile**:
- Tech-savvy individual running self-hosted services
- Wants to preserve favorite YouTube content
- Values privacy and data ownership
- Accesses library from multiple devices on home network

**Goals**:
- Archive educational/entertainment content before it's removed
- Build a personal video library organized by channel
- Watch content offline on mobile devices
- Quick access to frequently watched videos via favorites

### Use Cases

| # | Use Case | User Action | System Response |
|---|----------|-------------|-----------------|
| UC1 | Add new video | Paste YouTube URL, click "Add Video" | Validate URL, show confirmation, begin download |
| UC2 | Browse library | Open app | Display video grid sorted by newest |
| UC3 | Filter by channel | Select channel from dropdown | Show only videos from that channel |
| UC4 | View favorites | Toggle "Favorites" filter | Show only favorited videos |
| UC5 | Play locally | Click play button on card | Open modal with video player |
| UC6 | Watch on YouTube | Click YouTube icon | Open original video in new tab |
| UC7 | Download for offline | Click download icon | Browser downloads MP4 file |
| UC8 | Mark favorite | Click heart icon | Toggle favorite status |
| UC9 | Delete video | Click delete → Confirm | Remove video and files |
| UC10 | Check queue | View header indicator | See pending/active download count |

---

## 4. Information Architecture

### Site Structure

```
VidKeep (Single Page Application)
│
├── Header (Sticky)
│   ├── Logo
│   ├── Add Video Button / Form
│   ├── Channel Filter Dropdown
│   ├── Favorites Toggle
│   └── Queue Status Indicator
│
├── Main Content
│   ├── Active Filter Display
│   ├── Video Grid
│   │   └── Video Card (repeated)
│   │       ├── Thumbnail
│   │       ├── Status Badge / Progress Overlay
│   │       ├── Duration Badge
│   │       ├── Favorite Button
│   │       ├── Title (RTL-aware)
│   │       ├── Channel Name
│   │       └── Action Overlay (on hover/tap)
│   │           ├── YouTube Button
│   │           ├── Play Button
│   │           └── Download Button
│   └── Empty State (when no videos)
│
└── Modals (Overlay)
    ├── Video Player Modal
    │   ├── HTML5 Video Player
    │   ├── Title & Channel
    │   ├── Description (collapsible)
    │   └── Keyboard Shortcuts Hint
    └── Delete Confirmation Modal
        ├── Warning Icon
        ├── Video Preview
        └── Cancel / Delete Buttons
```

### Content Hierarchy

1. **Video identification**: Thumbnail, Title, Channel
2. **Video status**: Progress/Status badge, Duration
3. **User personalization**: Favorite indicator
4. **Actions**: Play, Download, YouTube, Delete

---

## 5. Design System

### Color Palette

#### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| Background | `#0f0f1a` | Page background |
| Card | `#1a1a2e` | Card backgrounds, header |
| Accent | `#4a4a6a` | Secondary text, borders |
| Primary | `#6366f1` | Buttons, links, focus states |
| White | `#ffffff` | Primary text |

#### Semantic Colors

| Name | Hex | Usage |
|------|-----|-------|
| Success | `#22c55e` | Complete status, success feedback |
| Warning | `#eab308` | Pending status |
| Info | `#3b82f6` | Downloading status |
| Error | `#ef4444` | Failed status, delete actions |
| Favorite | `#ef4444` | Favorited heart icon |

### Typography

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Logo | System sans-serif | 24px | Bold | White + Primary |
| Card Title | System sans-serif | 14px | Medium | White |
| Card Subtitle | System sans-serif | 12px | Normal | Accent |
| Badge | System sans-serif | 12px | Medium | White |
| Button | System sans-serif | 14px | Medium | White |
| Body | System sans-serif | 14px | Normal | Accent |

**Note**: Use system fonts (`-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`) for optimal performance and native feel.

### Spacing Scale

| Size | Value | Usage |
|------|-------|-------|
| xs | 4px | Tight spacing, badge padding |
| sm | 8px | Icon margins, small gaps |
| md | 16px | Card padding, grid gaps |
| lg | 24px | Section spacing |
| xl | 32px | Large section margins |

### Border Radius

| Element | Radius |
|---------|--------|
| Cards | 8px |
| Buttons | 8px |
| Badges | 4px |
| Modals | 8px |
| Inputs | 8px |
| Circular buttons | 50% |

### Shadows

Minimal shadow usage to maintain dark theme aesthetic:
- Modal backdrop: `rgba(0, 0, 0, 0.8)`
- Cards: No shadow (rely on background contrast)

---

## 6. Screen Specifications

### 6.1 Main Library View

**Purpose**: Display all videos in a browsable grid format

**Layout**:
- Header: Sticky, full width
- Content: Centered container, max-width 1440px
- Grid: Responsive columns (see Section 10)

**Elements**:
```
┌─────────────────────────────────────────────────────────┐
│  [Logo]         [+ Add Video] [Channel ▼] [♥ Favorites] │  ← Header
├─────────────────────────────────────────────────────────┤
│  Showing: All videos from "ChannelName"                 │  ← Filter indicator
├─────────────────────────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                │
│  │      │  │      │  │      │  │      │                │
│  │ Card │  │ Card │  │ Card │  │ Card │                │  ← Video Grid
│  │      │  │      │  │      │  │      │                │
│  └──────┘  └──────┘  └──────┘  └──────┘                │
│  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐                │
│  │      │  │      │  │      │  │      │                │
│  │ Card │  │ Card │  │ Card │  │ Card │                │
│  │      │  │      │  │      │  │      │                │
│  └──────┘  └──────┘  └──────┘  └──────┘                │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Empty State

**Purpose**: Guide new users when no videos exist

**Layout**:
- Centered vertically and horizontally
- Video camera icon
- Primary message: "No videos yet"
- Secondary message: "Add a YouTube URL to get started"

**Visual Style**:
- Icon: 64px, Accent color
- Primary text: 18px, Accent color
- Secondary text: 14px, Accent color (lighter)

### 6.3 Video Player Modal

**Purpose**: In-app video playback experience

**Layout**:
```
┌─────────────────────────────────────────────┐
│  Video Title                            [X] │  ← Header with close
├─────────────────────────────────────────────┤
│                                             │
│                                             │
│            [VIDEO PLAYER]                   │  ← 16:9 aspect ratio
│               with controls                 │
│                                             │
├─────────────────────────────────────────────┤
│  Channel Name              Duration: 5:32   │
│                                             │
│  ▶ Show description                         │  ← Collapsible
│                                             │
│  Shortcuts: Space=Play/Pause, ←→=Seek...    │  ← Hint text
└─────────────────────────────────────────────┘
```

**Keyboard Shortcuts**:
| Key | Action |
|-----|--------|
| Space / K | Play / Pause |
| ← | Seek -10 seconds |
| → | Seek +10 seconds |
| ↑ | Volume up |
| ↓ | Volume down |
| M | Toggle mute |
| F | Toggle fullscreen |
| Escape | Close modal |

### 6.4 Delete Confirmation Modal

**Purpose**: Prevent accidental deletions

**Layout**:
```
┌─────────────────────────────────────────────┐
│                                             │
│              ⚠️ (Warning Icon)              │
│                                             │
│            Delete Video?                    │
│                                             │
│   This action cannot be undone. The video   │
│   and thumbnail will be permanently deleted.│
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ [Thumb] Title of the Video          │   │  ← Video preview
│  │         Channel Name                │   │
│  │         150.5 MB                    │   │
│  └─────────────────────────────────────┘   │
│                                             │
│       [Cancel]           [🗑 Delete]        │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 7. Component Library

### 7.1 Video Card

**Dimensions**:
- Thumbnail: 16:9 aspect ratio
- Card content: 12px padding

**States**:

| State | Visual Treatment |
|-------|------------------|
| Default | Card background, white text |
| Hover | Action overlay appears, favorite button visible |
| Complete | Duration badge (bottom-right of thumbnail) |
| Pending | Yellow "Pending" badge (top-left), spinner on hover |
| Downloading | Blue "Downloading" badge, circular progress overlay |
| Failed | Red "Failed" badge, error message below title |
| Favorited | Heart icon filled red |

**Thumbnail Overlays**:
```
┌────────────────────────────────┐
│ [BADGE]              [♥]      │  ← Status badge (left), Favorite (right)
│                                │
│                                │
│       [Progress Circle]        │  ← Only during download
│            42%                 │
│                                │
│                        [5:32]  │  ← Duration badge (complete only)
└────────────────────────────────┘
```

**Action Overlay (on hover)**:
```
┌────────────────────────────────┐
│                                │
│    [▶ YT]  [▶ Play]  [↓ DL]   │  ← Three circular buttons
│                                │
└────────────────────────────────┘
```

### 7.2 Status Badge

**Variants**:

| Status | Background | Text | Label |
|--------|------------|------|-------|
| Pending | `rgba(234, 179, 8, 0.8)` | Yellow-100 | "Pending" |
| Downloading | `rgba(59, 130, 246, 0.8)` | Blue-100 | "Downloading" |
| Failed | `rgba(239, 68, 68, 0.8)` | Red-100 | "Failed" |
| Complete | (no badge shown) | — | — |

**Styling**: 4px radius, 8px horizontal padding, 2px vertical padding

### 7.3 Progress Overlay

**Visual**: Semi-transparent black overlay (`rgba(0,0,0,0.7)`) with centered circular progress indicator

**Circular Progress**:
- Diameter: 64px
- Track: Accent color at 30% opacity
- Progress: Primary color
- Center text: Percentage in white, 14px

### 7.4 Action Button (Overlay)

**Design**: Circular icon button with label below

```
    ┌───┐
    │ ▶ │   ← 40px diameter, white/20% background
    └───┘
     Play   ← 12px label
```

**States**:
- Default: `bg-white/20`
- Hover: `bg-white/30`
- Active: Scale down slightly (95%)
- Disabled: 50% opacity

### 7.5 Favorite Button

**Location**: Top-right of thumbnail, visible on hover

**States**:
| State | Icon | Color |
|-------|------|-------|
| Not favorited | Heart outline | White |
| Favorited | Heart filled | Red (#ef4444) |

**Size**: 20px icon in 32px touch target

### 7.6 Channel Filter Dropdown

**Design**: Custom select with dark theme styling

```
┌──────────────────────────────┐
│ All Channels              ▼ │
└──────────────────────────────┘
```

**Options format**: `Channel Name (count)`

**States**:
- Default: Border accent color
- Focus: Border primary color, ring
- Disabled: 50% opacity

### 7.7 Favorites Toggle

**Design**: Pill button with icon and label

```
┌─────────────────────┐
│ ♥ Favorites   [5]   │
└─────────────────────┘
```

**States**:
| State | Background | Border | Text |
|-------|------------|--------|------|
| Inactive | Transparent | Accent | Accent |
| Active | Red/20% | Red/50% | Red |

### 7.8 Ingest Form

**Layout**: Input field with submit button

```
┌─────────────────────────────────────┬──────────────┐
│ Paste YouTube URL...                │ + Add Video  │
└─────────────────────────────────────┴──────────────┘
```

**States**:
| State | Input Border | Button | Feedback |
|-------|--------------|--------|----------|
| Empty | Accent | Disabled (muted) | — |
| Valid URL | Accent | Primary (enabled) | — |
| Loading | Accent | Spinner + "Adding..." | — |
| Success | Green | Primary | Checkmark icon |
| Error | Red | Primary | Error icon + message |

### 7.9 Queue Status Indicator

**Design**: Subtle badge in header showing queue depth

```
┌────────────┐
│ ↓ 2 queued │
└────────────┘
```

**Visibility**: Only shown when queue has items (pending > 0 or processing > 0)

### 7.10 Modal Base

**Behavior**:
- Centered overlay
- Click outside to close
- Press Escape to close
- Body scroll locked when open
- Max width: 640px (medium) / 1024px (video player)
- Max height: 90vh

**Backdrop**: `rgba(0, 0, 0, 0.8)`

---

## 8. User Flows

### 8.1 Add New Video

```
[User] → Clicks "+ Add Video" button
         ↓
[UI]   → Expands/reveals URL input form
         ↓
[User] → Pastes YouTube URL
         ↓
[UI]   → Validates URL format (client-side)
         ├── Invalid → Show error, red border
         └── Valid → Enable submit button
         ↓
[User] → Clicks "Add Video"
         ↓
[UI]   → Show loading spinner
         ↓
[API]  → POST /api/videos/ingest
         ├── 202 Accepted → Show success checkmark
         │                  Clear input
         │                  Add video to grid (pending state)
         ├── 409 Conflict → Show "Video already exists" error
         └── 400 Bad Request → Show error message
         ↓
[UI]   → Video card appears in grid with "Pending" badge
         ↓
[Worker] → Downloads video (progress updates via WebSocket)
         ↓
[UI]   → Card shows progress overlay (42%)
         ↓
[Worker] → Complete
         ↓
[UI]   → Card shows duration badge, actions enabled
```

### 8.2 Play Local Video

```
[User] → Hovers over video card
         ↓
[UI]   → Shows action overlay with Play button
         ↓
[User] → Clicks Play button
         ↓
[UI]   → Opens Video Player Modal
         ↓
[Player] → Loads video from /api/stream/{id}
         ↓
[User] → Uses native controls or keyboard shortcuts
         ↓
[User] → Presses Escape or clicks X
         ↓
[UI]   → Closes modal, returns to grid
```

### 8.3 Delete Video

```
[User] → Hovers over video card
         ↓
[UI]   → Shows delete button (trash icon)
         ↓
[User] → Clicks delete button
         ↓
[UI]   → Opens Delete Confirmation Modal
         → Shows video thumbnail, title, file size
         ↓
[User] → Clicks "Cancel"
         └── Modal closes, no action

[User] → Clicks "Delete"
         ↓
[UI]   → Shows loading spinner on button
         ↓
[API]  → DELETE /api/videos/{id}
         ├── 204 No Content → Modal closes
         │                    Video removed from grid
         └── Error → Show error message in modal
```

### 8.4 Filter Videos

```
[User] → Clicks Channel dropdown
         ↓
[UI]   → Shows list of channels with video counts
         ↓
[User] → Selects "TechChannel (12)"
         ↓
[UI]   → Updates grid to show only TechChannel videos
         → Shows filter indicator: "Showing: All videos from TechChannel"
         → Shows "Clear filters" link
         ↓
[User] → Clicks Favorites toggle
         ↓
[UI]   → Further filters to favorited TechChannel videos
         → Updates indicator: "Showing: Favorites from TechChannel"
```

---

## 9. Interaction Patterns

### Hover States

| Element | Hover Effect |
|---------|--------------|
| Video Card | Action overlay fades in (opacity 0→1) |
| Action Button | Background lightens, slight scale |
| Favorite Button | Background appears |
| Delete Button | Background turns red |
| Text Button | Text color changes to white |
| Primary Button | Background darkens |

### Loading States

| Context | Indicator |
|---------|-----------|
| Initial page load | Skeleton cards (pulsing animation) |
| Adding video | Spinner in button + "Adding..." |
| Deleting video | Spinner in button + "Deleting..." |
| Video download | Circular progress with percentage |

### Feedback States

| Event | Feedback |
|-------|----------|
| Video added | Green checkmark icon, input clears |
| Video deleted | Card removed from grid (fade out) |
| Favorite toggled | Heart icon fills/unfills immediately |
| Error | Red border, error message |

### Transitions

| Element | Transition |
|---------|------------|
| Card overlay | `opacity 200ms ease` |
| Button hover | `background-color 150ms ease` |
| Modal | `opacity 200ms ease` |
| Badge | No transition (immediate) |

### Mobile Touch Interactions

| Desktop Action | Mobile Equivalent |
|----------------|-------------------|
| Hover to reveal overlay | Tap card to show overlay (3s timeout) |
| Click Play | Tap Play |
| Right-click context menu | Long press (optional) |

---

## 10. Responsive Design Requirements

### Breakpoints

| Name | Width | Grid Columns |
|------|-------|--------------|
| Mobile | < 640px | 1 column |
| Tablet | 640px - 1023px | 2 columns |
| Desktop | 1024px - 1279px | 3 columns |
| Wide | ≥ 1280px | 4 columns |

### Layout Adaptations

**Header**:
- Desktop: Logo left, controls right (single row)
- Mobile: Logo top, controls below (stacked)

**Video Card**:
- All sizes: Same card design, grid adjusts
- Touch targets: Minimum 44px

**Ingest Form**:
- Desktop: Inline (input + button side by side)
- Mobile: Stacked (input above button)

**Modals**:
- Desktop: Centered, max-width constrained
- Mobile: Full width with padding, max-height 90vh

### Container Widths

| Breakpoint | Container Max-Width |
|------------|---------------------|
| Mobile | 100% (with 16px padding) |
| Tablet | 100% (with 16px padding) |
| Desktop | 1280px (centered) |
| Wide | 1440px (centered) |

---

## 11. Accessibility Requirements

### Color Contrast
- All text must meet WCAG AA contrast ratio (4.5:1 for normal text)
- Interactive elements must have visible focus states

### Keyboard Navigation
- All interactive elements focusable via Tab
- Modal traps focus while open
- Escape closes modals
- Video player has full keyboard control

### Screen Reader Support
- Images have alt text (video titles)
- Buttons have aria-labels
- Status changes announced via aria-live regions
- Modal has proper focus management

### RTL Support
- Text elements use `dir="auto"` for automatic direction detection
- Arabic titles and channel names display correctly
- Layout does not break with mixed LTR/RTL content

### Reduced Motion
- Respect `prefers-reduced-motion` media query
- Provide alternative for progress animations

---

## 12. API Data Reference

### Video Object

```typescript
{
  video_id: string        // YouTube ID (e.g., "dQw4w9WgXcQ")
  title: string           // Video title (may be RTL)
  channel_name: string    // Channel name (may be RTL)
  channel_id: string      // YouTube channel ID
  duration_seconds: number // Duration for badge (e.g., 312 → "5:12")
  upload_date: string     // ISO date string
  description: string     // Full description (collapsible)
  is_favorite: boolean    // Favorite status
  status: "pending" | "downloading" | "complete" | "failed"
  file_size_bytes: number // For delete modal (e.g., 157286400 → "150.0 MB")
  created_at: string      // For sorting (newest first)
  error_message: string   // Shown for failed downloads
  youtube_url: string     // Computed: https://youtube.com/watch?v={id}
  download_progress: number // 0-100 during download, null otherwise
}
```

### Channel Object

```typescript
{
  channel_name: string    // Display name
  video_count: number     // For dropdown label
}
```

### Queue Status

```typescript
{
  pending: number         // Videos waiting to download
  processing: number      // Videos currently downloading
  total: number           // pending + processing
}
```

### API Endpoints Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/videos` | GET | List videos (with filters) |
| `/api/videos/ingest` | POST | Queue new video |
| `/api/videos/{id}` | GET | Single video details |
| `/api/videos/{id}` | PATCH | Update favorite status |
| `/api/videos/{id}` | DELETE | Remove video + files |
| `/api/stream/{id}` | GET | Video file stream |
| `/api/thumbnail/{id}` | GET | Thumbnail image |
| `/api/channels` | GET | List channels |
| `/api/queue/status` | GET | Queue depth |

---

## 13. Assets & Deliverables

### Required Designs

1. **Main Library View**
   - Empty state
   - With 1-2 videos
   - With 8+ videos (scrolling)
   - With active filter

2. **Video Card States**
   - Default (complete)
   - Hover with overlay
   - Pending
   - Downloading (with progress)
   - Failed
   - Favorited

3. **Video Player Modal**
   - Playing state
   - With description expanded

4. **Delete Confirmation Modal**
   - Default state
   - Loading state

5. **Header Variants**
   - With ingest form collapsed
   - With ingest form expanded
   - With queue indicator visible

6. **Responsive Layouts**
   - Desktop (1440px)
   - Tablet (768px)
   - Mobile (375px)

### Design Tokens Export

Please provide:
- Color palette as CSS custom properties
- Typography scale
- Spacing scale
- Component specifications

### Icon Set

Required icons (recommend: Heroicons or custom SVG):
- Video camera (empty state)
- Play (action button)
- Download (action button)
- YouTube logo (action button)
- Heart (favorite - outline and filled)
- Trash (delete)
- Plus (add video)
- Chevron down (dropdown)
- X (close modal)
- Check (success)
- Alert triangle (warning)
- Info circle (error)
- Spinner (loading)
- Refresh (retry)

---

## Appendix: Visual Reference Sketches

### Video Card Anatomy
```
┌────────────────────────────────────┐
│ [PENDING]                     [♥]  │ ← Badges layer
│                                    │
│         ┌────────────────┐         │
│         │    PROGRESS    │         │ ← Progress overlay
│         │      42%       │         │   (downloading only)
│         └────────────────┘         │
│                                    │
│                            [5:32]  │ ← Duration badge
├────────────────────────────────────┤   (complete only)
│ Video Title Goes Here And May...   │ ← Title (2 lines max)
│ Channel Name                       │ ← Channel (1 line)
│ 150.5 MB                          │ ← File size (complete)
└────────────────────────────────────┘
```

### Header Layout
```
┌──────────────────────────────────────────────────────────────────┐
│ VidKeep    [+ Add Video]   │   [Channel ▼] [♥ Favorites] [↓ 2]  │
└──────────────────────────────────────────────────────────────────┘
             └── Primary ──┘     └────── Filters ──────┘  └Queue┘
```

---

**End of Design Specification Document**

*For questions or clarifications, please contact the development team.*
