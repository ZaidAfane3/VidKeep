# T024: Favicon Matching App Logo

## 1. Description

Create a favicon for VidKeep that matches the retro terminal aesthetic and logo branding. The favicon should be recognizable at small sizes while maintaining the "Phosphor Console" theme with the signature green-on-black color scheme.

**Why**: A proper favicon improves brand recognition in browser tabs, bookmarks, and when the app is saved to home screens. Currently, the app uses the default Vite favicon which doesn't match the VidKeep identity.

## 2. Technical Specification

### Design Concept

The favicon should represent the `>_` terminal prompt from the logo, styled with the phosphor green glow effect. At small sizes, a simplified version focusing on recognizable elements works best.

**Primary Design Options:**

1. **Terminal Prompt:** `>_` in phosphor green on black background
2. **"V" with Terminal Style:** Stylized "V" that looks like terminal brackets `<V>`
3. **Play + Terminal Hybrid:** A play triangle combined with terminal aesthetics

**Recommended:** Option 1 - The `>_` prompt is distinctive, on-brand, and scales well.

### Files to Create

```
/frontend/public/
  favicon.ico          # Legacy favicon (16x16, 32x32, 48x48 multi-size)
  favicon-16x16.png    # Small favicon
  favicon-32x32.png    # Standard favicon
  apple-touch-icon.png # iOS home screen (180x180)
  android-chrome-192x192.png  # Android/PWA (192x192)
  android-chrome-512x512.png  # Android/PWA splash (512x512)
  site.webmanifest     # Web app manifest
  favicon.svg          # Scalable vector favicon (modern browsers)
```

### Design Specifications

#### Color Palette (from Design.md)

| Element | Color | Hex |
|---------|-------|-----|
| Background | Term Black | `#050505` |
| Primary/Glow | Phosphor Green | `#00ff41` |
| Glow Shadow | Green Alpha | `rgba(0, 255, 65, 0.5)` |

#### SVG Favicon (favicon.svg)

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <defs>
    <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="1" result="coloredBlur"/>
      <feMerge>
        <feMergeNode in="coloredBlur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <!-- Background -->
  <rect width="32" height="32" fill="#050505"/>

  <!-- Terminal prompt >_ with glow -->
  <text
    x="16"
    y="22"
    font-family="monospace"
    font-size="18"
    font-weight="bold"
    fill="#00ff41"
    text-anchor="middle"
    filter="url(#glow)"
  >&gt;_</text>
</svg>
```

#### Alternative: Simplified Icon for Small Sizes

For 16x16, a simpler geometric approach may be clearer:

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16">
  <!-- Background -->
  <rect width="16" height="16" fill="#050505"/>

  <!-- Chevron > -->
  <path d="M4 3 L10 8 L4 13" stroke="#00ff41" stroke-width="2" fill="none"/>

  <!-- Underscore _ -->
  <rect x="11" y="11" width="3" height="2" fill="#00ff41"/>
</svg>
```

### HTML Head Updates (index.html)

```html
<head>
  <!-- Existing meta tags... -->

  <!-- Favicons -->
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  <link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png" />
  <link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png" />
  <link rel="apple-touch-icon" sizes="180x180" href="/apple-touch-icon.png" />
  <link rel="manifest" href="/site.webmanifest" />

  <!-- Theme color for mobile browsers -->
  <meta name="theme-color" content="#050505" />
  <meta name="msapplication-TileColor" content="#050505" />
</head>
```

### Web App Manifest (site.webmanifest)

```json
{
  "name": "VidKeep",
  "short_name": "VidKeep",
  "description": "Personal Video Library & Streamer",
  "icons": [
    {
      "src": "/android-chrome-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/android-chrome-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "theme_color": "#050505",
  "background_color": "#050505",
  "display": "standalone",
  "start_url": "/"
}
```

### Generation Tools

Use one of these tools to generate all favicon sizes from the SVG:

1. **realfavicongenerator.net** - Best for comprehensive favicon packages
2. **favicon.io** - Quick and simple
3. **sharp** (Node.js) - Programmatic generation

```bash
# Using sharp (if added as dev dependency)
npx sharp favicon.svg -o favicon-16x16.png --resize 16 16
npx sharp favicon.svg -o favicon-32x32.png --resize 32 32
npx sharp favicon.svg -o apple-touch-icon.png --resize 180 180
npx sharp favicon.svg -o android-chrome-192x192.png --resize 192 192
npx sharp favicon.svg -o android-chrome-512x512.png --resize 512 512
```

### Design Variations to Consider

#### Standard Version (Recommended)
- `>_` prompt centered
- Phosphor green on black
- Subtle glow effect

#### Animated Version (Optional - for modern browsers)
- Blinking underscore cursor (matches header logo)
- Only SVG supports animation

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <rect width="32" height="32" fill="#050505"/>

  <!-- > symbol -->
  <text x="8" y="22" font-family="monospace" font-size="18" fill="#00ff41">&gt;</text>

  <!-- Blinking _ cursor -->
  <text x="18" y="22" font-family="monospace" font-size="18" fill="#00ff41">
    _
    <animate attributeName="opacity" values="1;0;1" dur="1s" repeatCount="indefinite"/>
  </text>
</svg>
```

## 3. Implementation Verification

- [ ] favicon.svg created with terminal prompt design
- [ ] All PNG sizes generated (16, 32, 180, 192, 512)
- [ ] favicon.ico created with multiple sizes embedded
- [ ] site.webmanifest created with correct paths
- [ ] index.html updated with favicon links
- [ ] Favicon visible in browser tab
- [ ] Favicon visible in bookmarks
- [ ] Apple touch icon works on iOS (add to home screen)
- [ ] Android PWA icon works (add to home screen)
- [ ] Favicon maintains clarity at 16x16 size
- [ ] Green glow effect visible on larger sizes
- [ ] Old Vite favicon removed

### Browser Testing

- [ ] Chrome (desktop)
- [ ] Firefox (desktop)
- [ ] Safari (desktop)
- [ ] Chrome (Android)
- [ ] Safari (iOS)
- [ ] Edge

### Commands to Verify

```bash
# Check all favicon files exist
ls -la frontend/public/favicon* frontend/public/apple-touch-icon.png frontend/public/android-chrome-* frontend/public/site.webmanifest

# Validate manifest JSON
cat frontend/public/site.webmanifest | jq .

# Test with lighthouse (PWA check)
npx lighthouse http://localhost:5173 --only-categories=pwa
```

## 4. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|

## 5. Comments

- SVG favicon preferred for modern browsers (scales perfectly, supports animation)
- PNG fallbacks needed for older browsers and social media previews
- The `>_` terminal prompt is unique and recognizable at small sizes
- Green-on-black maintains brand consistency with the app
- Consider testing with colorblind users (green may need sufficient contrast)
- The blinking cursor animation is optional but adds personality (may be distracting in tabs)
- Apple touch icon should have slight padding (Apple adds rounded corners)
- Manifest enables "Add to Home Screen" functionality
- Remove default Vite favicon after implementation
