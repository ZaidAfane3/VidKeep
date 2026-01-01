# VidKeep: Retro Terminal UI/UX Design Specification

**Theme:** "Phosphor Console" (Retro Terminal / Cyberpunk)
**Version:** 1.1 (Comprehensive)
**Target:** Frontend Development Team

---

## 1. Design Philosophy

The VidKeep interface is designed to emulate a high-fidelity command-line interface (CLI) or a retro monochrome monitor. The aesthetic prioritizes high contrast, monospaced typography, and sharp edges. It rejects modern "soft" UI patterns (rounded corners, subtle shadows, gradients) in favor of raw, utilitarian, and "hacker-chic" visuals.

### Core Visual Pillars

- **Phosphor Glow:** Elements should feel like they are emitting light against a black screen (`text-shadow: 0 0 2px rgba(0, 255, 65, 0.3)`).
- **Hard Edges:** 0px Border Radius globally. Everything is rectangular.
- **Terminal Interaction:** Inputs look like command prompts; buttons look like executed commands; text is uppercase-dominant.
- **CRT Artifacts:** Subtle scanlines and text glow simulate hardware imperfections.

---

## 2. Design Tokens

### 2.1 Color Palette

The palette is strictly limited to mimic 8-bit color depth. Use these exact hex codes.

| Token Name | Hex Code | Tailwind Name | Usage |
|------------|----------|---------------|-------|
| Term Black | `#050505` | `bg-term-bg` | Main page background |
| Term Card | `#0a0a0a` | `bg-term-card` | Component backgrounds (cards, modals) |
| Phosphor Green | `#00ff41` | `text-term-primary` | Primary Brand Color. Text, borders, active states |
| Dim Green | `#004611` | `border-term-dim` | Inactive borders, scrollbars, subtle separators |
| Dark Green | `#001a05` | `bg-term-dark` | Backgrounds for highlighted sections or dropdowns |
| Retro Red | `#cc0000` | `text-term-error` | Errors, delete actions, critical warnings |
| Amber | `#d69e00` | `text-term-warning` | Warnings, pending states |
| Invert White | `#ffffff` | `text-white` | Used on hover for high contrast against green backgrounds |

### 2.2 Typography Scale

**Font Family:** `VT323` (Google Fonts). Fallback: `monospace`.

| Role | Size (rem/px) | Line Height | Case | Tracking | Usage |
|------|---------------|-------------|------|----------|-------|
| Display (H1) | 3rem (48px) | 1.0 | Uppercase | `tracking-widest` | Empty State Numbers, Landing Heroes |
| Heading (H2) | 1.5rem (24px) | 1.2 | Uppercase | `tracking-wider` | Modal Titles, Section Headers |
| Heading (H3) | 1.125rem (18px) | 1.3 | Uppercase | `tracking-wide` | Video Titles (Card) |
| Body (Base) | 1.125rem (18px) | 1.5 | Sentence | `normal` | Descriptions, Paragraphs |
| Mono/Meta | 0.875rem (14px) | 1.4 | Uppercase | `tracking-tight` | File sizes, Dates, Badges |
| Input | 1.125rem (18px) | 1.5 | Uppercase | `tracking-widest` | Text Inputs |

### 2.3 Spacing System

Strict adherence to a 4px grid.

| Token | Size | Usage |
|-------|------|-------|
| `xs` | 4px | Badge padding |
| `sm` | 8px | Icon gaps, small margins |
| `md` | 16px | Card padding, button horizontal padding |
| `lg` | 24px | Grid gaps, Section margins |
| `xl` | 32px | Modal padding |
| `2xl` | 48px | Empty state margins |

---

## 3. Global Visual Effects (FX)

### 3.1 Scanlines Overlay

A fixed CSS overlay must sit on top of the entire application (`z-index: 9999`, `pointer-events: none`).

```css
background: linear-gradient(
    to bottom,
    rgba(255,255,255,0),
    rgba(255,255,255,0) 50%,
    rgba(0,0,0,0.1) 50%,
    rgba(0,0,0,0.1)
);
background-size: 100% 4px;
opacity: 0.6;
```

### 3.2 Text Shadow (The Glow)

Applied to all `#00ff41` text.

```css
text-shadow: 0 0 2px rgba(0, 255, 65, 0.3);
```

### 3.3 Selection

- **Background:** `#00ff41` (Phosphor Green)
- **Text Color:** `#000000` (Black)

---

## 4. Component Specifications

### 4.1 Buttons (The "Command" Pattern)

**Dimensions:** Height 36px (approx), Padding `px-4 py-1`.

#### Variant A: Primary Action (Execute)

- **Default:** `bg-term-primary`, `text-black`, `font-bold`, `border-none`
- **Hover:** `bg-white`, `text-black`
- **Active/Click:** `scale-95` transform
- **Disabled:** `opacity-50`, `cursor-not-allowed`

#### Variant B: Secondary/Outline (Ghost)

- **Default:** `bg-transparent`, `border-1 border-term-primary`, `text-term-primary`
- **Hover:** `bg-term-primary`, `text-black`

#### Variant C: Destructive

- **Default:** `bg-transparent`, `border-1 border-term-error`, `text-term-error`
- **Hover:** `bg-term-error`, `text-black`

### 4.2 Inputs (The "Prompt" Pattern)

**Layout:** Flexbox container.

- **Label/Prompt:** Left side, text `>`, Color: `term-primary`
- **Field:**
  - Background: `#050505` (Term Black)
  - Border: `1px solid #004611` (Dim Green)
  - Padding: `pl-8` (to clear prompt) `pr-2 py-2`
  - Text: `#00ff41`, Uppercase

**States:**

- **Focus:** Border becomes `#00ff41`. No outline ring.
- **Error:** Border becomes `#cc0000`, Text becomes `#cc0000`.
- **Autofill:** Override WebKit defaults to maintain black background and green text.

### 4.3 Video Cards

#### Container

- **Background:** `#0a0a0a`
- **Border:** `1px solid #004611`
- **Hover:** Border changes to `#00ff41`, Box Shadow `0 0 8px rgba(0,255,65,0.4)`
- **Transition:** `all 150ms ease-in-out`

#### Thumbnail Area (`aspect-video`)

- **Image:** `grayscale(100%)`, `opacity-80`
- **Hover:** `grayscale-0`, `opacity-100`
- **Scanline:** SVG/CSS overlay specifically on image

#### Badges (Status Indicators)

- **Position:** Absolute `top-0 left-0`
- **Style:** Sharp corners, `border-b border-r border-black` (1px)
- **Font:** `text-sm`, `font-bold`, `uppercase`

| Status | Style | Text |
|--------|-------|------|
| PENDING | `bg-[#d69e00]`, `text-black` | `[ PENDING ]` |
| DOWNLOADING | `bg-[#00ff41]`, `text-black` | `[ DOWNLOADING ]` |
| ERROR | `bg-[#cc0000]`, `text-black` | `[ ERROR ]` |

#### Progress Overlay (Downloading State)

- **Background:** `bg-black/80`
- **Z-Index:** 20
- **Content:** SVG Circle
  - Track: `#004611`, Stroke 6px
  - Value: `#00ff41`, Stroke 6px
- **Text:** Percentage in center (`font-bold`, `text-lg`)
- **Label:** `>> DOWNLOADING_DATA <<` (`text-xs`, `animate-pulse`)

#### Typography (Card Body)

- **Title:** `text-lg` (18px), `font-bold`, `text-term-primary`, `leading-tight`
- **Metadata Row:** `mt-2`, `flex`, `justify-between`
- **Channel:** `text-sm`, `text-term-primary/60`, Uppercase, Hover `text-term-primary`
- **Size:** `text-sm`, `font-mono`

### 4.4 Modals (The "System Window")

#### Overlay

- `fixed`, `inset-0`, `bg-black/95`, `backdrop-blur-none`

#### Panel

- **Max Width:** `max-w-5xl` (Player), `max-w-md` (Delete)
- **Border:** `2px solid #00ff41` (or `#cc0000` for Delete)
- **Shadow:** `0 0 30px rgba(0, 255, 65, 0.2)`

#### Header Bar

- **Background:** `bg-term-primary`
- **Text:** `text-black`, `font-bold`, Uppercase
- **Padding:** `px-4 py-1`
- **Close Button:** `hover:bg-black hover:text-term-primary`

#### Content Area

- **Padding:** `p-6`
- **Background:** `#050505`

---

## 5. Layout & Navigation

### 5.1 Sticky Header

- **Height:** `h-16` (64px)
- **Background:** `bg-[#050505]` at 95% opacity
- **Border Bottom:** `1px solid rgba(0, 255, 65, 0.3)`
- **Z-Index:** 40
- **Logo:** `>_ VIDKEEP` (Text only, no SVG graphics). The underscore `_` must blink (`animate-blink`).

### 5.2 Grid System

- **Container:** `max-w-[1440px]`, `mx-auto`, `px-4`
- **Grid Specs:**
  - `grid-cols-1` (Mobile < 640px)
  - `grid-cols-2` (Tablet < 1024px)
  - `grid-cols-3` (Desktop < 1280px)
  - `grid-cols-4` (Wide >= 1280px)
- **Gap:** `gap-6` (24px)

---

## 6. Iconography

Using **Lucide React**.

- **Stroke Width:** 2px (Standard)
- **Style:** Sharp, geometric where possible

### Common Icons

| Icon | Usage |
|------|-------|
| Play (Triangle) | Play video |
| Square (Stop) | Stop |
| Trash2 (Delete) | Delete |
| Heart (Favorite) | Favorite |
| Terminal (Logo placeholder) | Branding |

---

## 7. Implementation Checklist (Frontend)

- [ ] **Reset CSS:** Enforce `border-radius: 0 !important` globally.
- [ ] **Font Loading:** VT323 must be loaded before rendering to prevent FOUT (Flash of Unstyled Text).
- [ ] **Color Variables:** Define `term-primary`, `term-bg`, etc., in `tailwind.config.js`.
- [ ] **Selection Style:** Add `::selection` CSS rule globally.
- [ ] **Input Auto-fill:** Use box-shadow hack to prevent browser default yellow/blue backgrounds on autocomplete.
- [ ] **Scrollbars:** Style `::-webkit-scrollbar` to be 12px wide, black track, green border thumb.

---

*End of Specification*
