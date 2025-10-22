# Ghost Preview Adjacency & Combo Timeout Fix — October 17, 2025

## Context
- Reviewed prior work: `docs/ghost_preview_positioning_fix_2025-10-16.md` and `docs/ghost_preview_and_combo_overlap_fix_2025-10-16.md`.
- Attempted to fetch fresh SwiftUI 6 documentation via Context7 MCP (`mcp__context7__resolve-library-id`) but the command is not available in this environment. Ref MCP remains configured for future use.
- Researched toast/score message dwell times via Android toast duration guidance (LENGTH_SHORT ≈ 2 s) as a practical baseline for transient combo messaging in fast-paced mobile games.

## Problems
1. **Magnet Snap pointing to wrong cell**  
   The magnet assist (`GhostPreviewManager.findMagnetSnapPosition`) evaluated candidate positions solely by overlap ratio, causing the preview to snap above the intended cluster in tight configurations (see IMG_9276.PNG).

2. **Combo banner never clears**  
   `LineClearAnimationManager` kept `currentCombo` and `isPerfectClear` set indefinitely, so “2× COMBO!” (and “PERFECT!”) overlays persisted and obscured the new animation work.

## Solutions
1. **Adjacency-aware magnet ranking**  
   - Added `placementAdjacencyScore` to count orthogonal neighbors already occupied by existing blocks.
   - Updated magnet selection tuple to prioritise higher adjacency before overlap/distance heuristics.  
   - Result: preview prefers positions that hug existing pieces (e.g., snapping to the open right edge instead of hovering above).

2. **Timed combo/perfect dismissal**  
   - Introduced scheduled dismissals (1.8 s for combos, 2.2 s for perfect clears) using cancellable `DispatchWorkItem`s.  
   - Reset `currentCombo`, `comboMultiplier`, and `isPerfectClear` after the timer with a gentle ease-out animation.
   - Prevents stale overlays and keeps the stage clear for line-clear effects.

## Validation
- `xcodebuild build -project BlockPuzzlePro/BlockPuzzlePro.xcodeproj -scheme BlockPuzzlePro -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6'`
- Manual sanity checklist:
  - Dragging across occupied clusters now prefers the densest empty adjacency.
  - “2× COMBO!” fades after ~1.8 s; perfect clears vanish shortly after.

## Next Steps
- Consider expanding magnet search radius adaptively for large patterns if players report remaining edge cases.
- Evaluate whether combo duration should scale with streak length (e.g., +0.2 s per additional line) after broader playtesting.

