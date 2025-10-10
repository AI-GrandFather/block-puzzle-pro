# Drag-and-Drop Diagnostic Plan

## Status: ✅ RESTORED TO WORKING VERSION (cb39e88)

Build Status: **BUILD SUCCEEDED**
Current commit: `cb39e88 - Fix: Grid preview now aligns with lifted piece position`

---

## Problem Analysis (Based on User Logs)

### Observed Issues:
1. **Snap-back on ProMotion devices**: Pieces return to tray even on valid placements
2. **NOT smooth**: Drag feels forced/laggy
3. **Inconsistent placement**: Sometimes pieces don't place where intended
4. **Works fine on 60Hz devices**: Issue is ProMotion-specific

### Evidence from Logs:

```
🏁 ===== GESTURE ENDED (Block 0) =====
🔍 isBlockDragged: false  ← Controller says NOT dragging!
🔍 Controller state: idle  ← Already idle!
🔍 didSendDragBegan: true  ← But gesture DID start!
⚠️ NOT calling endDrag - controller says block not being dragged
```

**Critical Finding**: Controller state is ALREADY `idle` when gesture `onEnded` fires, even though:
- Gesture successfully started (`didSendDragBegan: true`)
- Updates were sent (`updatePreview` logs show tracking)
- Placement was valid (`Preview valid: true`)

This indicates a **timing race condition specific to 120Hz ProMotion**.

---

## Research Plan (Before Any Implementation)

### Phase 1: Root Cause Analysis
**Goal**: Understand WHY controller state clears before gesture completes

**Tasks**:
1. ✅ Review timing of state transitions in DragController
2. ✅ Identify where `transitionToIdleImmediately()` is called
3. ✅ Check if multiple drag systems are interfering
4. ⏳ Measure gesture timing on ProMotion vs 60Hz devices
5. ⏳ Profile with Instruments to find the exact race condition

**Research Questions**:
- Does `transitionToIdleImmediately()` in `endDrag()` fire before gesture `onEnded`?
- Are there multiple gesture recognizers competing?
- Is SwiftUI gesture pipeline different at 120Hz?

### Phase 2: Industry Best Practices
**Goal**: Learn how successful SwiftUI games handle ProMotion gestures

**Research Sources**:
1. **Apple Documentation**:
   - WWDC sessions on gesture handling at 120Hz
   - ProMotion optimization guides
   - SwiftUI gesture pipeline documentation

2. **Similar Games**:
   - Block puzzle games on App Store using SwiftUI
   - Match-3 games with drag mechanics
   - ProMotion-optimized gesture demos

3. **Technical Resources**:
   - Stack Overflow: SwiftUI + ProMotion + gestures
   - GitHub: Open-source SwiftUI games with drag-drop
   - Apple Developer Forums: Known ProMotion gesture issues

### Phase 3: Hypothesis Formation
**Goal**: Form evidence-based hypothesis before coding

**Hypotheses to Test**:
1. **Async State Race**: `transitionToIdleImmediately()` called before `onEnded`
2. **Gesture Cancellation**: iOS 18 gesture system cancels at 120Hz differently
3. **Update Throttling**: Visual updates at 60Hz conflict with 120Hz gestures
4. **Multiple Drag Systems**: DragController, DragControllerV2, SimplifiedDragController interfering

---

## Proposed Solution (PENDING APPROVAL)

### Option A: Synchronize Gesture and State Lifecycle
**Approach**: Ensure controller state stays valid until gesture completes

**Changes**:
- Remove `transitionToIdleImmediately()` from `endDrag()`
- Use gesture completion callback to trigger state transition
- Keep drag state valid through entire gesture lifecycle

**Risk**: May cause state to linger if gesture cancelled

### Option B: Match Update Rate to Gesture Rate
**Approach**: Stop throttling updates on ProMotion, update at 120Hz

**Changes**:
- Remove update throttling on ProMotion devices
- Update visual effects every frame (120 FPS)
- Use CADisplayLink for precise frame timing

**Risk**: Higher CPU/battery usage

### Option C: Implement Gesture State Lock
**Approach**: Lock drag state during gesture, prevent premature clearing

**Changes**:
- Add `gestureInProgress` flag
- Block state transitions while gesture active
- Release lock only after gesture `onEnded` completes

**Risk**: Complex state management

### Option D: Use UIKit Gestures (iOS 18+ UIGestureRecognizerRepresentable)
**Approach**: Replace SwiftUI gestures with UIKit for better control

**Changes**:
- Implement UIGestureRecognizerRepresentable (WWDC 2024)
- Use UIPanGestureRecognizer with custom timing
- Full control over gesture lifecycle

**Risk**: Major refactor, iOS 18+ only

---

## Testing Plan (After Implementation)

### Test Matrix:

| Device | Frame Rate | Test Scenario | Expected Result |
|--------|-----------|---------------|-----------------|
| iPhone 16 Pro | 120Hz | Quick drag | Places correctly |
| iPhone 16 Pro | 120Hz | Slow drag | Places correctly |
| iPhone 16 Pro | 120Hz | Minimal movement | Places correctly |
| iPhone 16 | 60Hz | All scenarios | Places correctly |
| iPad Pro M4 | 120Hz | All scenarios | Places correctly |

### Success Criteria:
- ✅ 0% snap-back rate on valid placements
- ✅ Smooth drag feel (no lag)
- ✅ Pieces place exactly where released
- ✅ Works on both 60Hz and 120Hz devices
- ✅ No performance regression

---

## Timeline Estimate

1. **Research Phase**: 30-60 minutes (web research, documentation review)
2. **Implementation**: 1-2 hours (depending on chosen solution)
3. **Testing**: 30 minutes (on actual ProMotion device)
4. **Iteration**: 30 minutes (if issues found)

**Total**: 2.5-4 hours

---

## Next Steps (REQUIRES YOUR APPROVAL)

Please review this plan and:

1. **Approve research phase**: Let me spend 30-60 minutes researching
2. **Choose solution direction**: Which option (A, B, C, or D) sounds most promising?
3. **Specify testing device**: What ProMotion device are you testing on?

**I will NOT implement anything until you approve this plan.**

---

## Questions for You:

1. On the working version (cb39e88), does it still have snap-back issues?
2. What percentage of drags fail? (e.g., 1 in 10? 5 in 10?)
3. Does the issue happen more with quick drags or slow drags?
4. Are you testing on iPhone 15/16/17 Pro, or iPad Pro?
5. Do you have access to a non-ProMotion device to compare?
