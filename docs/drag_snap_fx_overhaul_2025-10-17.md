# Drag Snap & FX Overhaul — October 17, 2025

## Summary
- Reviewed prior work: `docs/ghost_preview_positioning_fix_2025-10-16.md`, `docs/ghost_preview_adjacency_combo_timeout_fix_2025-10-17.md`, and the SpriteKit FX spec provided in the latest prompt.
- Context7 MCP CLI unavailable (command not found); proceeded with existing local documentation and spec.
- Restored the smoother drag-flow from commit `feb89771545b63bdaa8984abd9135a90ac292b65`, removed the ghost preview overlay, and left the floating piece free under the finger while preserving the snapping logic on drop.
- Implemented the full SpriteKit-driven effects pipeline (`EffectsEngine`) per spec, including sweeps, pop-shrink timing, sparkles, starbursts, micro-shake, combo badge orchestration, and perfect-clear ensemble with confetti + wave flash + vacuum collapse.

## Problems Addressed
1. **Drag preview regression** — floating block stopped snapping with the magnet logic, and the additional ghost overlay caused visual mismatch.
2. **Missing FX** — no SpriteKit-driven line clear or perfect-clear effects, violating the supplied Game FX spec.

## Key Changes
- Removed `GhostPreviewOverlay` usage and restored the floating preview’s snapped origin, matching commit `feb8977` behaviour while keeping improved placement heuristics.
- Introduced `EffectsEngine` (SpriteKit-backed) with `EffectsEvent` API, `BoardGeometry` mapping, combo tracking, and Reduce Motion fallbacks.
- Replaced the SwiftUI-only line-clear overlay with a `SpriteView` hosting `EffectsScene`, covering PopShrink, SweepWipe, Sparkle, Starburst, CameraMicroShake, GridWaveFlash, VacuumCollapse, and ConfettiBurst per spec timings.
- Wired `EffectsEngine` into `DragDropGameView` for line-clear and perfect-clear triggers, plus a SwiftUI `PerfectClearBanner` tied to engine state.
- Updated combo UI to read from the new engine (`ComboCounterView`) so combo badges mirror the SpriteKit tier escalations.

## Validation
- `xcodebuild build -project BlockPuzzlePro/BlockPuzzlePro.xcodeproj -scheme BlockPuzzlePro -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6'`

## Follow-ups
- Monitor performance on-device to ensure particle counts stay within the budget (≤220 normal / ≤520 perfect clear). Consider caching gradient textures/emitter nodes if profiling shows spikes.
- Expose streak-level UI hooks once streak mechanics are live so `EffectsEngine.trigger(.streakChanged…)` can be exercised outside of the effect tests.
