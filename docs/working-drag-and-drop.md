# Working Drag-and-Drop Migration Notes

## Overview
The drag-and-drop system was ported from the SpriteKit prototype into a pure SwiftUI implementation. The UI looked correct, but any attempt to drag a block onto the grid would freeze the piece for several seconds and eventually abort the gesture. These notes capture the root causes, the resolution, and the guardrails needed when rebuilding or extending the feature.

## Symptoms Observed
- First block dragged onto the grid stops responding and eventually snaps back.
- Console spammed with `Preview rejected` and `Fallback placement` messages.
- `DragController` remains in the `.dragging` state and refuses to start a new drag (`Cannot start drag` errors).
- After ~3.6 s, the watchdog forces a reset (`Gesture appears stuck`).

## Root Causes
1. **Gesture removal mid-flight** – the tray hid (`if !isDragged`) the `DraggableBlockView` being dragged. SwiftUI removes that view, so its `DragGesture` never emits `.onEnded`, leaving the controller stuck in `.dragging`.
2. **Placement origin alignment** – the placement engine projected the drag origin using the top-left of the block. When part of the block hovered outside the board, the projection failed. A fallback existed, but the controller never saw a stable, valid preview, so it could not settle.

## Fix Summary
1. **Keep the tray view alive during drag**
   - Always render `DraggableBlockView` inside `DraggableBlockTrayView`, even while the block is in-flight.
   - Fade the view to near transparent and disable hit-testing when it’s being dragged so it no longer interferes with the floating preview but the gesture stays alive.
2. **Stabilise placement preview**
   - Clamp the inferred base grid position inside `PlacementEngine` so a valid preview is produced as soon as any occupied cell is over the board.
   - Add debug logging to trace the entire pipeline (gesture → drag controller → placement engine).

## Implementation Steps
1. **Tray adjustments** (`Views/DraggableBlockView.swift`)
   - Remove the `if !isDragged` guard.
   - Apply `.opacity(isDragged ? 0.0001 : 1)` and `.allowsHitTesting(!isDragged || dragController.draggedBlockIndex == index)` to keep the view alive but inert while dragging.
2. **Placement engine guard rails** (`Game/PlacementEngine.swift`)
   - Clamp the base row/column before validation.
   - Log anchor cell, finger grid, and final base selection for easier diagnostics.
3. **Optional instrumentation**
   - Added temporary logs to confirm state transitions while testing. Remove or gate behind debug flags when shipping.

## Lessons Learned / Guard Rails
- Never remove the original gesture target during a drag; SwiftUI treats gesture recognisers as tied to the view’s lifetime.
- When translating touch points between coordinate spaces, always clamp the inferred origin so the entire block fits the grid before validation.
- Keep an eye on `DragController.dragState`; if it never leaves `.dragging`, the UI and controller disagree on whether the gesture ended.

## Rebuilding Checklist
1. Implement the grid and tray layout.
2. Build a `DragController` with explicit state transitions.
3. Ensure tray blocks stay in the view hierarchy during drags.
4. Convert tray gesture coordinates to the global space your placement maths expects.
5. In `PlacementEngine.updatePreview`, clamp the base grid position and verify previews become valid.
6. Commit and test on device/simulator; watch logs for `Preview valid` events.

## Reference Commit
- `cf59ac6 Fix drag drop gesture staying active`
