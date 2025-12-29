# T012: React/Vite Project Setup

## 1. Description

Initialize the frontend project using React with Vite as the build tool, and configure Tailwind CSS for styling. This establishes the foundation for all frontend components.

**Why**: Vite provides fast development builds and HMR. React enables component-based UI. Tailwind CSS offers utility-first styling that's perfect for rapid development.

## 2. Technical Specification

### Files to Create/Modify

```
/frontend/
  package.json
  vite.config.ts
  tailwind.config.js
  postcss.config.js
  tsconfig.json
  tsconfig.node.json
  index.html
  src/
    main.tsx
    App.tsx
    index.css
    vite-env.d.ts
    api/
      client.ts
      types.ts
    components/
      .gitkeep
    hooks/
      .gitkeep
  Dockerfile
  nginx.conf
```

### Package.json

```json
{
  "name": "vidkeep-frontend",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.16",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.2.2",
    "vite": "^5.0.8"
  }
}
```

### Vite Config (vite.config.ts)

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
})
```

### Tailwind Config (tailwind.config.js)

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        // Custom dark theme colors
        'vidkeep': {
          bg: '#0f0f1a',
          card: '#1a1a2e',
          accent: '#4a4a6a',
          primary: '#6366f1',
        }
      }
    },
  },
  plugins: [],
}
```

### PostCSS Config (postcss.config.js)

```javascript
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

### Index CSS (src/index.css)

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Base styles */
body {
  @apply bg-vidkeep-bg text-white min-h-screen;
}

/* RTL support */
[dir="rtl"] {
  text-align: right;
}
```

### App Component (src/App.tsx)

```typescript
function App() {
  return (
    <div className="min-h-screen bg-vidkeep-bg">
      <header className="bg-vidkeep-card border-b border-vidkeep-accent px-6 py-4">
        <h1 className="text-2xl font-bold">VidKeep</h1>
      </header>
      <main className="container mx-auto px-4 py-8">
        <p className="text-vidkeep-accent">
          Video library coming soon...
        </p>
      </main>
    </div>
  )
}

export default App
```

### Main Entry (src/main.tsx)

```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
```

### API Client (src/api/client.ts)

```typescript
const API_BASE = '/api'

export async function fetchVideos(params?: {
  channel?: string
  favorites_only?: boolean
}) {
  const searchParams = new URLSearchParams()
  if (params?.channel) searchParams.set('channel', params.channel)
  if (params?.favorites_only) searchParams.set('favorites_only', 'true')

  const url = `${API_BASE}/videos?${searchParams}`
  const response = await fetch(url)
  if (!response.ok) throw new Error('Failed to fetch videos')
  return response.json()
}

export async function fetchChannels() {
  const response = await fetch(`${API_BASE}/channels`)
  if (!response.ok) throw new Error('Failed to fetch channels')
  return response.json()
}

export async function ingestVideo(url: string) {
  const response = await fetch(`${API_BASE}/videos/ingest`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ url })
  })
  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.detail || 'Failed to ingest video')
  }
  return response.json()
}

export async function updateVideoFavorite(videoId: string, isFavorite: boolean) {
  const response = await fetch(`${API_BASE}/videos/${videoId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ is_favorite: isFavorite })
  })
  if (!response.ok) throw new Error('Failed to update video')
  return response.json()
}

export async function deleteVideo(videoId: string) {
  const response = await fetch(`${API_BASE}/videos/${videoId}`, {
    method: 'DELETE'
  })
  if (!response.ok) throw new Error('Failed to delete video')
}
```

### API Types (src/api/types.ts)

```typescript
export type VideoStatus = 'pending' | 'downloading' | 'complete' | 'failed'

export interface Video {
  video_id: string
  title: string
  channel_name: string
  channel_id: string | null
  duration_seconds: number | null
  upload_date: string | null
  description: string | null
  is_favorite: boolean
  status: VideoStatus
  file_size_bytes: number | null
  created_at: string
  error_message: string | null
  youtube_url: string
  download_progress: number | null
}

export interface VideoListResponse {
  videos: Video[]
  total: number
}

export interface Channel {
  name: string
  video_count: number
}

export interface ChannelsResponse {
  channels: Channel[]
}
```

### Production Dockerfile

```dockerfile
# Build stage
FROM node:20-alpine as build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Nginx Config (nginx.conf)

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api {
        proxy_pass http://api:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
```

### Dependencies

- T001 (Docker Compose frontend service)

## 3. Implementation Verification

- [x] `npm install` completes without errors
- [x] `npm run dev` starts Vite dev server on port 3000
- [x] Tailwind CSS classes work in components
- [x] API proxy works (requests to /api/* reach backend)
- [x] `npm run build` creates production bundle
- [x] Docker build succeeds
- [x] Custom colors (term-*) are available (Phosphor Console theme)

### Tests to Write

```typescript
// src/__tests__/App.test.tsx
import { render, screen } from '@testing-library/react'
import App from '../App'

test('renders VidKeep header', () => {
  render(<App />)
  expect(screen.getByText('VidKeep')).toBeInTheDocument()
})
```

Add test dependencies to package.json:
```json
"devDependencies": {
  "@testing-library/react": "^14.1.0",
  "@testing-library/jest-dom": "^6.1.0",
  "vitest": "^1.1.0",
  "jsdom": "^23.0.0"
}
```

### Commands to Verify

```bash
# Install dependencies
cd frontend && npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Test Docker build
docker build -t vidkeep-frontend ./frontend

# Run production container
docker run -p 3000:80 vidkeep-frontend
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2024-12-29 | Created package.json with React 18, Vite 5, Tailwind 3.4, lucide-react | Success | 134 packages installed |
| 2024-12-29 | Created tsconfig.json, tsconfig.node.json | Success | TypeScript strict mode enabled |
| 2024-12-29 | Created vite.config.ts with API proxy | Success | Port 3000, proxy to localhost:8000 |
| 2024-12-29 | Created tailwind.config.js with Phosphor Console theme | Success | Used Design.md colors instead of ticket defaults |
| 2024-12-29 | Created index.css with terminal FX (scanlines, glow, scrollbars) | Success | Full Phosphor Console implementation |
| 2024-12-29 | Created API client (types.ts, client.ts) | Success | Type-safe API functions ready |
| 2024-12-29 | Created App.tsx with terminal header | Success | Blinking cursor logo implemented |
| 2024-12-29 | Created Dockerfile and nginx.conf | Success | Multi-stage build ready |
| 2024-12-29 | Verified npm run build | Success | dist: 145KB JS, 8KB CSS |
| 2024-12-29 | Verified npm run dev | Success | Starts on http://localhost:3000 |

## 5. Comments

- Vite proxy config handles API requests during development
- Nginx handles SPA routing and API proxy in production
- Custom color palette provides consistent dark theme
- TypeScript provides type safety for API responses
- API client functions are ready for use in components
- RTL support is prepared via CSS (used in T013)
- Next ticket (T013) implements the video grid layout
