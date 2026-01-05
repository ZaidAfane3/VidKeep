# BUG-002: Android Action Buttons Trigger While Invisible

## 1. Description

**Type:** Bug (Mobile/Android)
**Severity:** Medium
**Status:** Complete
**Affected Platforms:** Android (Chrome, Firefox, etc.)
**Not Affected:** iOS, Desktop

On Android devices, when tapping on a video card where action buttons would appear, the first tap both reveals the overlay AND triggers the action button underneath. This causes unintended actions (e.g., opening YouTube, starting playback, or deleting) on the first tap instead of just revealing the buttons.

## 2. Root Cause Analysis

### The Problem

The action overlay in `VideoCard.tsx` (lines 154-266) uses CSS `opacity: 0` to hide buttons:

```tsx
<div
  className={`
    absolute inset-0 bg-term-bg/90
    transition-opacity duration-200 flex items-center justify-center
    ${isOverlayActive
      ? 'opacity-100'
      : 'opacity-0 group-hover:opacity-100'  // <-- PROBLEM: opacity:0 still allows clicks
    }
  `}
>
  {/* ActionButtons are rendered here but invisible */}
</div>
```

**Key Issue:** `opacity: 0` makes elements invisible but they remain in the DOM and continue to receive pointer/touch events. The buttons are "there" and clickable even when not visible.

### Event Sequence on Android

1. User taps on the card where an action button is located
2. `handleTouchEnd` fires on the card, calling `onOverlayActivate()` to show the overlay
3. **Simultaneously**, the browser dispatches a `click` event to the invisible button at that position
4. The action executes immediately (e.g., opening YouTube link)

### Why iOS Doesn't Have This Issue

iOS has different touch handling behavior:
- iOS has a 300ms delay before converting touch to click (for double-tap detection)
- iOS may not dispatch click events through elements with `opacity: 0` in certain contexts
- React's synthetic event system may handle iOS touches differently

### Why Desktop Doesn't Have This Issue

- Desktop uses mouse hover (`group-hover:opacity-100`) which shows buttons BEFORE any click can occur
- No touch event ordering ambiguity

## 3. Expected Behavior

1. First tap on a video card should ONLY reveal the action overlay
2. Second tap on a button should trigger the action
3. Action buttons should NOT be clickable when invisible

## 4. Technical Solution

Two fixes were required:

### Fix 1: Prevent synthetic click on Android

**File:** `frontend/src/components/VideoCard.tsx`

The browser synthesizes a `click` event after `touchend`. By the time the click fires, React has already re-rendered with the overlay visible, so the click hits the now-visible button.

**Solution:** Call `e.preventDefault()` in `handleTouchEnd` when activating the overlay:

```tsx
const handleTouchEnd = (e: React.TouchEvent) => {
  // ... swipe detection logic ...

  if (deltaX < SWIPE_THRESHOLD && deltaY < SWIPE_THRESHOLD) {
    // If overlay is not active, activate it and prevent the synthetic click
    if (!isOverlayActive) {
      e.preventDefault()  // Prevents browser from firing click event
      onOverlayActivate?.()
    }
  }
}
```

### Fix 2: Prevent sticky hover on iOS

**Files:**
- `frontend/src/components/ActionButton.tsx`
- `frontend/src/index.css`

On iOS, the `:hover` state persists after a tap until the user taps elsewhere.

**Solution:** Move hover styles to a `@media (hover: hover)` query so they only apply on devices with true hover capability (mouse):

```css
/* index.css */
@media (hover: hover) {
  .action-btn-default:hover {
    background-color: #00ff41;
    color: #000000;
  }
  .action-btn-danger:hover {
    background-color: #ff3333;
    color: #000000;
  }
}
```

```tsx
// ActionButton.tsx - Use CSS classes instead of Tailwind hover:
const variantClasses = {
  default: 'border-term-primary text-term-primary action-btn-default',
  danger: 'border-term-error text-term-error action-btn-danger'
}
```

## 5. Verification Checklist

After fix:
- [x] Android: First tap on video card only reveals overlay, doesn't trigger action
- [x] Android: Second tap on visible button triggers the action correctly
- [x] iOS: Existing behavior preserved (tap to reveal, tap to action)
- [x] iOS: No sticky hover state on buttons
- [x] Desktop: Hover reveals overlay, click triggers action
- [x] Desktop: Transition animation still works smoothly
- [x] Favorite button (separate from overlay) still works on first tap
- [x] All action buttons work: YouTube, Play, Download, Delete, Retry, Cancel

## 6. Test Devices

- Android Chrome (primary)
- Android Firefox
- Android Samsung Internet
- iOS Safari (regression test)
- Desktop Chrome/Firefox/Safari (regression test)

## 7. Related Files

- `frontend/src/components/VideoCard.tsx` - Contains overlay and touch handlers
- `frontend/src/components/ActionButton.tsx` - Individual button component (hover classes)
- `frontend/src/components/VideoGrid.tsx` - Manages `isOverlayActive` state
- `frontend/src/index.css` - Hover styles with media query

## 8. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-01-05 | Bug identified and documented | Ticket created | Root cause: opacity:0 doesn't block pointer events |
| 2025-01-05 | Initial fix attempted | Partial | Added `pointer-events-none` to overlay - didn't fix the issue |
| 2025-01-05 | Root cause refined | Fixed | Issue was synthetic click firing after touchend. Added `e.preventDefault()` in handleTouchEnd when activating overlay |
| 2025-01-05 | iOS sticky hover fix | Fixed | Moved hover styles to `@media (hover: hover)` in index.css to prevent stuck hover state on touch devices |
