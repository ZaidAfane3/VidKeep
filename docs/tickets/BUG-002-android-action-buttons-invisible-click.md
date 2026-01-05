# BUG-002: Android Action Buttons Trigger While Invisible

## 1. Description

**Type:** Bug (Mobile/Android)
**Severity:** Medium
**Status:** Open
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

Add `pointer-events: none` to the overlay when hidden, and `pointer-events: auto` when visible.

### Files to Modify

- `frontend/src/components/VideoCard.tsx`

### Implementation

```tsx
// Lines 154-162 - Add pointer-events control
<div
  className={`
    absolute inset-0 bg-term-bg/90
    transition-opacity duration-200 flex items-center justify-center
    ${isOverlayActive
      ? 'opacity-100 pointer-events-auto'
      : 'opacity-0 group-hover:opacity-100 pointer-events-none group-hover:pointer-events-auto'
    }
  `}
>
```

### Why This Works

- `pointer-events: none` prevents all mouse/touch events from reaching the element and its children
- When the overlay is hidden (`opacity-0`), clicks pass through to the card (triggering overlay activation)
- When the overlay is visible (`opacity-100` or `group-hover:opacity-100`), buttons receive events normally
- The `group-hover:pointer-events-auto` ensures desktop hover behavior still works

### Alternative Solutions Considered

1. **Conditional rendering (`{isOverlayActive && <ActionButtons />}`):**
   - Pros: Simpler, no hidden clickable elements
   - Cons: Breaks CSS transitions (no fade-in effect), breaks desktop hover behavior entirely

2. **`visibility: hidden` instead of `opacity: 0`:**
   - Pros: Also disables pointer events
   - Cons: No smooth fade transitions (visibility is binary)

3. **Touch event prevention on buttons:**
   - Pros: Could selectively block
   - Cons: Complex, may cause other issues with button responsiveness

The `pointer-events` solution is preferred because it:
- Preserves existing CSS transitions
- Works with both touch (mobile) and hover (desktop)
- Is a minimal, targeted fix
- Is widely supported across browsers

## 5. Verification Checklist

After fix:
- [ ] Android: First tap on video card only reveals overlay, doesn't trigger action
- [ ] Android: Second tap on visible button triggers the action correctly
- [ ] iOS: Existing behavior preserved (tap to reveal, tap to action)
- [ ] Desktop: Hover reveals overlay, click triggers action
- [ ] Desktop: Transition animation still works smoothly
- [ ] Favorite button (separate from overlay) still works on first tap
- [ ] All action buttons work: YouTube, Play, Download, Delete, Retry, Cancel

## 6. Test Devices

- Android Chrome (primary)
- Android Firefox
- Android Samsung Internet
- iOS Safari (regression test)
- Desktop Chrome/Firefox/Safari (regression test)

## 7. Related Files

- `frontend/src/components/VideoCard.tsx` - Contains overlay and action buttons
- `frontend/src/components/ActionButton.tsx` - Individual button component
- `frontend/src/components/VideoGrid.tsx` - Manages `isOverlayActive` state

## 8. Execution Logs

| Date | Action | Outcome | Issues & Resolutions |
|------|--------|---------|----------------------|
| 2025-01-05 | Bug identified and documented | Ticket created | Root cause: opacity:0 doesn't block pointer events |
