# Drag Fix Attempt – 2025-10-12

## Context
- Issue: First drag feels laggy and some valid drops snap back on ProMotion (120 Hz) devices.
- Goal: Maintain the existing “keep the finger’s original offset” behaviour while eliminating the lag/snap-back bugs.

## Changes Implemented
1. **Recomputed touch offsets at full scale**  
   - `Views/DraggableBlockView.swift` now converts the touch location into a percentage inside the tray-sized block and rebuilds the offset using the block’s full-size dimensions.  
   - This keeps the finger anchored to the same cell once the block scales up for dragging (fixes the misalignment that triggered “fallback placement” and snap-backs).

2. **Primed the drag state immediately**  
   - After `startDrag` we send the initial `updateDrag` call so the very first frame already has a correct `currentDragPosition`.  
   - Removes the perceived “teleport” on the first drag frame.

3. **Refresh preview on drop**  
   - `Views/DragDropGameView.swift` re-runs `updatePlacementPreview` when the drag ends, ensuring the placement engine validates the final location even if the last `.onChanged` fired below the grid margin.

## Expected Outcomes
- Blocks track the finger smoothly from the very first drag frame on ProMotion devices.
- Valid placements no longer rely on the fallback branch or snap back to the tray.
- Existing user-facing behaviours (offset retention, lift, animations) remain intact.

## Verification
- `xcodebuild clean build -scheme BlockPuzzlePro -configuration Debug -destination "generic/platform=iOS Simulator"`

## Notes For Future Work
- If further fixes are attempted, read this file first to avoid repeating the same approach.  
- Document every new attempt in a separate markdown file following this format.
