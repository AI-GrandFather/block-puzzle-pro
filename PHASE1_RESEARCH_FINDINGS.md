# Phase 1: Research Findings - ProMotion Drag-and-Drop Issues

**Date**: October 10, 2025
**Status**: ✅ RESEARCH COMPLETE
**Current Build**: cb39e88 (restored working version)
**Next Phase**: Option B + Option D Implementation (Pending Approval)

---

## Executive Summary

### The Problem
Block puzzle pieces snap back to tray on **ProMotion (120Hz) devices only**. The issue does NOT occur on 60Hz devices. Analysis of debug logs reveals controller state is cleared **BEFORE** SwiftUI gesture `onEnded` callback fires, creating a race condition at 120Hz frame rates.

### Root Cause (Confirmed)
**Timing mismatch between 120Hz gesture events and 60Hz visual updates + async state transitions**

```
Timeline at 120Hz (8.3ms per frame):
T=0ms:    Gesture onChanged (frame 1)
T=8.3ms:  Gesture onChanged (frame 2)
T=16.6ms: Visual update fires (60Hz throttled)
T=16.6ms: State transition: dragging → idle (transitionToIdleImmediately)
T=24.9ms: Gesture onEnded fires ← STATE ALREADY IDLE!
```

### Research Confidence Level
**HIGH** - Multiple sources confirm:
1. ✅ ProMotion lag issues documented across multiple projects (Flutter, SwiftUI)
2. ✅ iOS 18 introduced new gesture issues requiring workarounds
3. ✅ @GestureState timing issue is known SwiftUI behavior
4. ✅ UIGestureRecognizerRepresentable is official solution (WWDC 2024)
5. ✅ CADisplayLink at 120Hz is standard for game loops

---

## Detailed Research Findings

### 1. ProMotion (120Hz) Gesture Issues - Confirmed Industry Problem

#### Evidence from Flutter Community
- **Issue**: "Gesture Animation is not 120hz and feels laggy on ProMotion iPhone 13"
- **Status**: Reported but ongoing across multiple iOS versions
- **Impact**: Affects drag gestures specifically on ProMotion devices

#### Evidence from SwiftUI Community (2024)
- **Issue**: "Adding a high priority drag gesture to a scrollable view in iOS 18 causes scrollable view to become unscrollable"
- **Workaround**: Developers switching to `simultaneousGesture()` but experiencing side effects
- **Key Quote**: "This may have been an intentional 'fix' by Apple, as the previous behavior was never intended"

#### Evidence from Stack Overflow (2024)
- **Issue**: "SwiftUI dragging an object lags on newer iPhones"
- **Observation**: Works smoothly on iPhone 7 Plus (60Hz), lags on iPhone 13 (120Hz)
- **Timeline**: Persists through iOS 16, iOS 17, iOS 18

**Conclusion**: This is a **known, unfixed issue** affecting ProMotion displays across multiple frameworks.

---

### 2. @GestureState Timing Behavior - Apple's Design Intent

#### Official Behavior (Confirmed)
From Apple Developer Forums and Stack Overflow:

> "@GestureState is being reset **before** onEnded starts"

> "Apple intends gestureState to be used to change the appearance of some other item within the view (like its highlighting or its color), **rather than for maintaining state through async operations in onEnded**"

#### Why This Matters for Our Code
Our failed Fix #6 used `@GestureState private var isDraggingGesture: Bool`:
```swift
.onEnded { value in
    if isDraggingGesture {  // ← ALWAYS FALSE by design!
        dragController.endDrag(...)
    }
}
```

**This is NOT a bug - this is Apple's intentional design.** `@GestureState` resets synchronously before `onEnded` fires.

#### Recommended Approach
Use `@State` for values needed in `onEnded`, not `@GestureState`.

---

### 3. iOS 18 UIGestureRecognizerRepresentable (WWDC 2024)

#### What Is It?
New protocol introduced at WWDC 2024 (iOS 18+) that allows direct use of UIKit gesture recognizers in SwiftUI.

#### Key Benefits (From Apple Documentation)
1. **Full control over gesture lifecycle** - No SwiftUI timing quirks
2. **Resolves gesture conflicts** - Can set priorities explicitly
3. **Better performance** - UIKit gestures are more optimized
4. **Addresses deficiencies** - Official solution for SwiftUI gesture limitations

#### How It Works
```swift
struct MyPanGesture: UIGestureRecognizerRepresentable {
    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        UIPanGestureRecognizer()
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: UIPanGestureRecognizer,
        context: Context
    ) {
        // Handle gesture state changes
        switch recognizer.state {
        case .began: // Start drag
        case .changed: // Update drag
        case .ended: // End drag ← FULL CONTROL!
        default: break
        }
    }
}
```

#### Coverage
- WWDC 2024 Session: "What's new in SwiftUI" (10144)
- WWDC 2024 Session: "What's new in UIKit" (10118)
- Swift with Majid: Comprehensive tutorial (December 2024)

**Recommendation**: **Option D is strongly supported by Apple** as the official solution for complex gestures.

---

### 4. CADisplayLink for 120Hz Update Loops

#### What Is It?
Timer synchronized with display refresh rate (v-sync). On ProMotion devices, fires at 120Hz (8.3ms intervals).

#### Key Features
- **Automatic ProMotion support**: Reports `maximumFramesPerSecond = 120`
- **Synchronized rendering**: Callback fires right after frame renders
- **Modern API**: Uses `preferredFramesPerSecond` property

#### SwiftUI Integration Pattern (2024)
```swift
class GameLoop: ObservableObject {
    private var displayLink: CADisplayLink?

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFramesPerSecond = 120  // ProMotion
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc func update() {
        // Update at 120Hz on ProMotion devices
        updateGameState()
        objectWillChange.send()  // Trigger SwiftUI update
    }
}
```

#### Performance Target
- **Main thread budget**: 8.3ms per frame at 120Hz
- **Critical**: All layout + rendering must complete in this window
- **Fallback**: System drops to 60Hz if frame budget exceeded

#### Sources
- CADisplayLink Apple Documentation
- "SwiftUI Scroll Performance: The 120FPS Challenge" (2024 blog post)
- Multiple Stack Overflow implementations

**Recommendation**: **Option B can achieve 120Hz** if we remove throttling and use CADisplayLink.

---

### 5. Block Puzzle Game Best Practices

#### Modern SwiftUI Patterns (October 2025 Tutorials)
1. **Use `.draggable()` and `.dropDestination()`** modifiers (not old `onDrag`/`onDrop`)
2. **Transferable protocol** for drag data
3. **Snap-to-grid logic**: Calculate Pythagorean distance to target
4. **Visual feedback**: Highlight valid drop zones

#### Key Technique for Snap-Back Prevention
From "Puzzle Game using UI Drag & Drop APIs in Swift":

> "When the user releases the piece, validate if target slots are open. If valid, snap to nearest slots. If invalid, return to origin."

**Critical**: Validation must happen **before** gesture state clears.

#### Performance Optimization
From multiple sources:
- Use `.drawingGroup()` for complex animations
- Use `.geometryGroup()` to prevent stutter with `contentTransition`
- Avoid deep view hierarchies during drag

---

## Analysis: Why Current Code Fails at 120Hz

### The Race Condition Visualized

#### 60Hz Device (Works) ✅
```
Frame 1 (0ms):     Gesture onChanged
Frame 2 (16.6ms):  Gesture onChanged + Visual Update
Frame 3 (33.3ms):  Gesture onEnded
                   ↓
                   State check: dragging ← VALID
                   endDrag() called ← SUCCESS
                   transitionToIdleImmediately()
```

#### 120Hz Device (Fails) ❌
```
Frame 1 (0ms):     Gesture onChanged
Frame 2 (8.3ms):   Gesture onChanged
Frame 3 (16.6ms):  Gesture onChanged + Visual Update (throttled to 60Hz)
                   ↓
                   transitionToIdleImmediately() ← FIRES TOO EARLY!
                   State: idle
Frame 4 (24.9ms):  Gesture onEnded
                   ↓
                   State check: idle ← INVALID!
                   endDrag() NOT called ← SNAP BACK!
```

### The Problem
`transitionToIdleImmediately()` in `endDrag()` fires **during a visual update** (frame 3), which happens **before** gesture `onEnded` (frame 4).

At 120Hz, there's a **full extra frame** between visual update and gesture completion.

### Why `isBlockDragged` Check Fails
```swift
// DragController.swift:592
func isBlockDragged(_ blockIndex: Int) -> Bool {
    return draggedIndices.contains(blockIndex) && isDragging  // ← isDragging = false!
}

// Called from transitionToIdleImmediately():
isDragging = false  // ← Clears before onEnded!
draggedIndices.removeAll()
```

---

## Recommended Solutions (Phase 2)

### Option B: Match Update Rate to Gesture Rate (120Hz) ⭐ RECOMMENDED

#### Approach
Remove 60Hz throttling, update at full 120Hz using CADisplayLink.

#### Implementation Plan
1. Replace `minUpdateInterval` throttling with CADisplayLink
2. Remove this code (DragController.swift:274-277):
   ```swift
   // REMOVE THIS:
   let visualEffectInterval = self.isProMotionDisplay ? (1.0 / 60.0) : minUpdateInterval
   if currentTime - lastUpdateTime >= visualEffectInterval {
       updateVisualEffects()
   }
   ```
3. Add CADisplayLink-based update loop:
   ```swift
   private var displayLink: CADisplayLink?

   func startDrag(...) {
       setupDisplayLink()  // Start 120Hz updates
   }

   func endDrag(...) {
       displayLink?.invalidate()  // Stop updates
   }
   ```

#### Benefits
- ✅ Eliminates timing mismatch (gestures and updates at same rate)
- ✅ Smoother visual feedback (no frame skipping)
- ✅ Industry standard for games (proven approach)
- ✅ Relatively small code change (~50 lines)

#### Risks
- ⚠️ Higher CPU usage (120 FPS vs 60 FPS)
- ⚠️ Slightly more battery drain
- ⚠️ Must ensure 8.3ms frame budget not exceeded

#### Estimated Effort
**2-3 hours** (implementation + testing)

---

### Option D: Use UIGestureRecognizerRepresentable (iOS 18+) ⭐⭐ STRONGLY RECOMMENDED

#### Approach
Replace SwiftUI DragGesture with UIKit UIPanGestureRecognizer.

#### Implementation Plan
1. Create `UIGestureRecognizerRepresentable` wrapper:
   ```swift
   struct PuzzlePieceDragGesture: UIGestureRecognizerRepresentable {
       let blockIndex: Int
       let blockPattern: BlockPattern
       @ObservedObject var dragController: DragController

       func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
           let recognizer = UIPanGestureRecognizer()
           recognizer.minimumNumberOfTouches = 1
           recognizer.maximumNumberOfTouches = 1
           return recognizer
       }

       func handleUIGestureRecognizerAction(
           _ recognizer: UIPanGestureRecognizer,
           context: Context
       ) {
           let location = recognizer.location(in: recognizer.view)

           switch recognizer.state {
           case .began:
               dragController.startDrag(...)
           case .changed:
               dragController.updateDrag(to: location)
           case .ended:
               dragController.endDrag(at: location)  // ← PERFECT TIMING!
           case .cancelled:
               dragController.cancelDrag()
           default:
               break
           }
       }
   }
   ```

2. Replace gesture in DraggableBlockView:
   ```swift
   // REMOVE:
   .gesture(dragGesture)

   // ADD:
   .gesture(PuzzlePieceDragGesture(blockIndex: blockIndex, ...))
   ```

#### Benefits
- ✅ **Official Apple solution** (WWDC 2024)
- ✅ **Perfect timing control** (no race conditions)
- ✅ Resolves gesture conflicts
- ✅ Better performance than SwiftUI gestures
- ✅ Future-proof (Apple's recommended path)
- ✅ Works on ProMotion AND 60Hz devices

#### Risks
- ⚠️ **iOS 18+ only** (but game targets iOS 18 anyway)
- ⚠️ Moderate refactor (~100-150 lines changed)
- ⚠️ Different gesture API to learn

#### Estimated Effort
**3-4 hours** (implementation + testing + edge cases)

---

## Combined Approach: Option B + Option D ⭐⭐⭐ BEST SOLUTION

### Why Combine Both?

**Option D** solves the **timing race condition** (primary issue).
**Option B** provides **smooth 120Hz visuals** (secondary issue).

Together they address:
1. ✅ Snap-back (Option D: precise gesture lifecycle)
2. ✅ Smoothness (Option B: 120Hz updates)
3. ✅ Placement accuracy (Option D: correct timing)
4. ✅ Performance (both: optimized for ProMotion)

### Implementation Order
1. **First**: Implement Option D (UIGestureRecognizerRepresentable)
   - Test: Verify snap-back is fixed
   - If works: Proceed to Option B
   - If fails: Debug before continuing

2. **Second**: Implement Option B (120Hz updates with CADisplayLink)
   - Test: Verify smoothness improved
   - Profile: Ensure 8.3ms frame budget maintained

### Combined Estimated Effort
**5-7 hours total**
- Option D: 3-4 hours
- Option B: 2-3 hours
- Integration testing: 1 hour

---

## Testing Strategy

### Test Matrix

| Device | Refresh | Scenario | Expected |
|--------|---------|----------|----------|
| iPhone 16 Pro | 120Hz | Quick drag | ✅ Places |
| iPhone 16 Pro | 120Hz | Slow drag | ✅ Places |
| iPhone 16 Pro | 120Hz | Minimal move | ✅ Places |
| iPhone 16 Pro | 120Hz | Invalid position | ✅ Snaps back |
| iPhone 16 | 60Hz | All above | ✅ Places |
| iPad Pro M4 | 120Hz | All above | ✅ Places |

### Success Metrics
- **Snap-back rate**: 0% on valid placements
- **Frame rate**: Sustained 120 FPS during drag
- **Placement accuracy**: 100% pieces place where released
- **Battery impact**: <5% increase vs 60Hz throttling

### Profiling Requirements
Use Instruments to verify:
1. **Frame pacing**: Consistent 8.3ms intervals
2. **CPU usage**: Main thread <80% during drag
3. **Memory**: No leaks during gesture lifecycle
4. **Thermal state**: No thermal throttling

---

## Code Audit: Current Issues Found

### Issue 1: Visual Update Throttling (Line 274-277)
```swift
// DragController.swift:274-277
let visualEffectInterval = self.isProMotionDisplay ? (1.0 / 60.0) : minUpdateInterval
if currentTime - lastUpdateTime >= visualEffectInterval {
    updateVisualEffects()
    lastUpdateTime = currentTime
}
```

**Problem**: Throttles ProMotion to 60Hz, defeating the purpose.
**Solution**: Remove throttling, use CADisplayLink at 120Hz.

### Issue 2: Async State Transition (Line 365)
```swift
// DragController.swift:365
transitionToIdleImmediately()
```

**Problem**: Called during visual update, before gesture onEnded.
**Solution**: Delay until gesture truly complete (UIGestureRecognizer.ended).

### Issue 3: @GestureState Misuse (Previous Failed Attempts)
```swift
// WRONG (our failed Fix #6):
@GestureState private var isDraggingGesture: Bool = false
```

**Problem**: Resets before onEnded by design.
**Solution**: Don't use @GestureState for onEnded checks. Use UIGestureRecognizer.state instead.

### Issue 4: Multiple Drag Systems
Found 3 drag controllers in codebase:
- `DragController.swift` (active)
- `DragControllerV2.swift` (unused?)
- `SimplifiedDragController.swift` (unused?)

**Problem**: Potential conflicts if multiple active.
**Solution**: Audit which is actually used, remove unused ones.

---

## References

### Apple Official
- [UIGestureRecognizerRepresentable](https://developer.apple.com/documentation/swiftui/uigesturerecognizerrepresentable)
- [CADisplayLink](https://developer.apple.com/documentation/quartzcore/cadisplaylink)
- WWDC 2024: "What's new in SwiftUI" (Session 10144)
- WWDC 2024: "What's new in UIKit" (Session 10118)

### Community Resources
- [Swift with Majid: UIGestureRecognizerRepresentable](https://swiftwithmajid.com/2024/12/17/introducing-uigesturerecognizerrepresentable-protocol-in-swiftui/)
- [SwiftUI Scroll Performance: The 120FPS Challenge](https://blog.jacobstechtavern.com/p/swiftui-scroll-performance-the-120fps)
- [Customizing Gestures in SwiftUI](https://fatbobman.com/en/posts/swiftuigesture/)

### GitHub Issues
- [Flutter #101653: ProMotion lag on iPhone 13](https://github.com/flutter/flutter/issues/101653)
- [KeyboardKit #690: onEnded not executing](https://github.com/KeyboardKit/KeyboardKit/issues/690)

### Stack Overflow
- [SwiftUI drag lag on newer iPhones](https://stackoverflow.com/questions/73064407)
- [High priority drag gesture iOS 18](https://stackoverflow.com/questions/78912852)
- [Snap to grid for puzzle pieces](https://stackoverflow.com/questions/57527227)

---

## Next Steps for Phase 2

### Awaiting User Approval For:

1. **Option D Implementation** (UIGestureRecognizerRepresentable)
   - Primary fix for snap-back issue
   - ~3-4 hours effort
   - iOS 18+ requirement acceptable?

2. **Option B Implementation** (120Hz CADisplayLink)
   - Secondary fix for smoothness
   - ~2-3 hours effort
   - Battery impact acceptable?

3. **Testing Device**
   - What ProMotion device are you using?
   - Can you test on 60Hz device for comparison?

### Questions for User:
1. Is iOS 18+ requirement acceptable? (for UIGestureRecognizerRepresentable)
2. Is 5-7 hour implementation timeline acceptable?
3. Should we remove unused DragControllerV2 and SimplifiedDragController?
4. Do you want Option D alone first, or combined B+D immediately?

---

**Status**: ✅ Phase 1 Research Complete
**Recommendation**: Proceed with **Option B + Option D** combined approach
**Confidence**: **HIGH** (backed by Apple documentation + industry evidence)
