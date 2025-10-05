# Feature: Ghost Preview & Hold Slot Mechanic

**Priority:** HIGH
**Timeline:** Week 3 (Phase 2)
**Dependencies:** Core drag-drop system, Grid placement logic
**Performance Target:** 120fps on ProMotion displays, 60fps minimum

---

## Overview

Implement two critical gameplay enhancement features:
1. **Ghost Preview System**: Real-time visual preview showing where pieces will be placed
2. **Hold Slot Mechanic**: Strategic piece storage system allowing players to swap and hold pieces

Both features significantly improve player experience by adding strategic depth and reducing placement errors.

---

## Feature 1: Ghost Preview System

### Purpose
Provide players with real-time visual feedback showing:
- Exact placement position of the dragged piece
- Validity of the placement (valid/invalid)
- Potential line clears that will result from placement
- Score gain preview

### Visual Design

**Ghost Overlay Appearance:**
- Semi-transparent overlay at 30% opacity
- Matches piece shape exactly
- Updates at 60fps minimum (120fps on ProMotion) as piece is dragged
- Smooth fade-in (0.1s) when dragging begins
- Fade-out (0.1s) when placement occurs or drag ends

**Color-Coded Validity:**
- **Valid Placement**: Green `#34C759` tint overlay
- **Invalid Placement**: Red `#FF3B30` tint overlay
- Dashed outline: 5px dash, 3px gap, 2px stroke width
- Outline matches validity color

**Snap-to-Grid Behavior:**
- Ghost snaps to nearest valid position when within 0.5 cell distance
- Smooth interpolation to snap position (0.1s ease-out)
- Magnetic feel without being jarring

### Functional Requirements

**Real-Time Updates:**
1. Ghost position updates continuously during drag gesture
2. Calculate grid position from touch coordinates
3. Validate placement at ghost position
4. Update visual state (valid/invalid) immediately
5. Highlight affected rows/columns if placement would clear lines

**Placement Validation:**
```swift
func validateGhostPlacement(piece: Piece, position: GridPosition) -> PlacementValidity {
    // Check if all cells in piece shape are:
    // 1. Within grid bounds
    // 2. Empty (not occupied)
    // Return .valid or .invalid with reason
}
```

**Line Clear Preview:**
- Highlight rows that would be cleared in preview color (green at 20% opacity)
- Highlight columns that would be cleared
- Show count of lines that will clear
- Visual distinction between single/double/triple clears

**Score Gain Preview:**
- Calculate score that will be earned from placement
- Display as floating number near ghost: "+250"
- Color-coded by magnitude:
  * 0-100: White
  * 100-500: Yellow
  * 500+: Gold
- Font size scales with score value
- Fade in/out smoothly with ghost

### Technical Implementation

**Performance Optimization:**
- Cache grid validation results for same position
- Invalidate cache only when grid state changes
- Use spatial hashing for quick collision detection
- Minimize alpha blending (pre-multiply alpha)

**Rendering:**
- Separate render layer for ghost (above grid, below active piece)
- Metal shader for efficient transparency rendering
- Reuse piece sprite with modified shader parameters
- Batch render ghost outline and fill

**Touch Handling:**
```swift
func handleDragUpdate(location: CGPoint) {
    let gridPos = convertToGridPosition(location)
    let validity = validateGhostPlacement(piece: draggedPiece, position: gridPos)

    // Update ghost position
    ghostView.position = snapToGrid ? gridPos.snapped : gridPos
    ghostView.validity = validity

    // Update line clear preview
    if validity == .valid {
        let clearedLines = calculateLineClear(piece: draggedPiece, at: gridPos)
        highlightClearPreview(clearedLines)
    }
}
```

### User Experience Details

**Visual Feedback Flow:**
1. User taps piece in tray → piece lifts with scale/shadow animation
2. User drags → ghost appears at 0 opacity
3. Ghost fades in over 0.1s
4. Ghost follows drag position with smooth interpolation
5. Ghost snaps to grid when close enough (magnetic effect)
6. Color changes instantly based on validity
7. Line clear preview highlights affected rows/columns
8. Score preview shows potential gain
9. User releases:
   - Valid: Ghost dissolves into actual placement (0.2s)
   - Invalid: Ghost shakes and fades out, piece returns to tray

**Accessibility:**
- VoiceOver announcement of validity state changes
- Haptic feedback on snap-to-grid
- High contrast mode: Increase ghost opacity to 50%
- Option to disable ghost in settings for advanced players

---

## Feature 2: Hold Slot Mechanic

### Purpose
Allow players to strategically store one piece for later use, enabling:
- Better planning and strategy
- Saving difficult pieces for better opportunities
- Creating combo setups
- Recovering from difficult situations

### Visual Design

**Hold Slot Appearance:**
- Positioned above or beside piece tray (configurable in settings)
- Same size as piece tray slots
- Distinct visual design indicating "Hold" functionality:
  * Label: "HOLD" text above slot
  * Icon: Circular arrows or pause symbol
  * Border: Thicker border (3px) in theme accent color
  * Background: Slightly darker than piece tray

**Piece Display:**
- Stored piece shown at same scale as tray pieces
- Subtle glow indicating it can be swapped
- Pulsing animation (subtle, 2s cycle, opacity 90%-100%) when ready to use

**Cooldown Indicator (if limited swaps):**
- Circular progress overlay showing cooldown
- Semi-transparent gray overlay (60% opacity) when on cooldown
- Text showing remaining turns/time
- Color transitions: Gray (cooldown) → Green (ready)

### Swap Animation

**Smooth Rotation Effect (0.3s duration):**
1. Active dragged piece rotates out (180° clockwise)
2. Held piece rotates in (180° counter-clockwise)
3. Both pieces scale during rotation:
   - Start: 1.0x scale
   - Middle (90°): 0.8x scale
   - End: 1.0x scale
4. Z-position changes to create depth (piece going back moves behind, coming forward moves front)
5. Ease-in-out timing function

**Visual Sequence:**
```
Active Piece (in hand) ⟲ 180° → Hold Slot
Hold Slot → ⟳ 180° → Active Piece (in hand)
Duration: 0.3 seconds
```

### Functional Requirements

**Hold Mechanics:**

**Option A: Unlimited Swaps (Beginner-Friendly)**
- Can swap active piece with held piece anytime during turn
- No cooldown or limitations
- Promotes learning and experimentation
- Default for Easy/Zen modes

**Option B: Limited Swaps (Strategic)**
- One swap per turn (per piece placement)
- Cannot hold-swap twice in same turn
- Cooldown resets after piece is placed on grid
- Default for Normal/Hard modes

**Option C: Limited Uses (Challenge)**
- Fixed number of hold swaps per game (e.g., 10 holds per game)
- Counter shows remaining holds
- Strategic resource management
- Optional for Levels mode challenges

**Configurable in Settings:**
- Players can choose swap limitation style
- Different modes can have different defaults
- Tutorial explains chosen system

**Interaction Methods:**

**Method 1: Tap Hold Slot**
- While dragging piece, tap hold slot
- Swap animation triggers
- Now dragging the previously held piece

**Method 2: Swipe to Hold**
- Swipe piece toward hold slot area
- Requires swipe distance > 100px in direction of hold slot
- Swap triggers on swipe completion

**Method 3: Button Press**
- Dedicated "Hold" button on screen
- Tap while dragging to trigger swap
- Alternative for accessibility

**First Use Tutorial:**
- Tooltip appears on first hold slot unlock (Level 3)
- Animated demonstration: "Tap here to store pieces for later"
- Sample scenario showing strategic hold usage
- Can replay tutorial from settings

### Technical Implementation

**Hold Slot Manager:**
```swift
class HoldSlotManager: ObservableObject {
    @Published var heldPiece: Piece?
    @Published var isOnCooldown: Bool = false
    @Published var remainingHolds: Int = 10 // if using limited mode
    @Published var swapMode: SwapMode = .unlimited

    enum SwapMode {
        case unlimited
        case oncePerTurn
        case limitedUses(Int)
    }

    func swapPiece(activePiece: Piece) -> Piece? {
        guard canSwap() else { return nil }

        let temp = heldPiece
        heldPiece = activePiece

        if swapMode == .oncePerTurn {
            isOnCooldown = true
        } else if case .limitedUses(let count) = swapMode {
            remainingHolds = count - 1
        }

        triggerSwapAnimation()
        return temp ?? generateNewPiece()
    }

    func canSwap() -> Bool {
        if isOnCooldown { return false }
        if case .limitedUses(let count) = swapMode, count <= 0 {
            return false
        }
        return true
    }

    func resetCooldown() {
        // Called after piece placement
        isOnCooldown = false
    }
}
```

**Animation Controller:**
```swift
func triggerSwapAnimation(activePiece: PieceView, heldPiece: PieceView?) {
    let duration: TimeInterval = 0.3

    UIView.animate(withDuration: duration, delay: 0, options: .curveEaseInOut) {
        // Active piece rotates out
        activePiece.transform = CGAffineTransform(rotationAngle: .pi)
            .scaledBy(x: 0.8, y: 0.8)
        activePiece.layer.zPosition = -1

        // Held piece rotates in
        if let held = heldPiece {
            held.transform = CGAffineTransform(rotationAngle: -.pi)
                .scaledBy(x: 0.8, y: 0.8)
            held.layer.zPosition = 1
        }
    } completion: { _ in
        UIView.animate(withDuration: duration / 2) {
            activePiece.transform = .identity
            heldPiece?.transform = .identity
            activePiece.layer.zPosition = 0
            heldPiece?.layer.zPosition = 0
        }
    }
}
```

### Strategic Indicator System

**AI Suggestion (Optional, Subtle):**
- Analyze current grid state and available pieces
- If holding current piece would be beneficial, show subtle hint:
  * Faint glow on hold slot border
  * Very subtle pulsing (2s cycle)
  * Never intrusive or tutorial-like
  * Can be disabled in settings

**Indicator Logic:**
```swift
func shouldSuggestHold(piece: Piece, gridState: Grid, upcomingPieces: [Piece]) -> Bool {
    // Check if:
    // 1. Current piece has no good placement options
    // 2. Upcoming piece would have better placement
    // 3. Holding wouldn't put player in worse position
    // Return true if strategic to hold
}
```

### Hold Slot Badge (Limited Uses Mode)

**Count Display:**
- Small badge in corner of hold slot
- Shows remaining hold swaps: "8" in circular badge
- Color-coded:
  * Green: 6+ remaining
  * Yellow: 3-5 remaining
  * Orange: 1-2 remaining
  * Red: 0 remaining
- Font: Bold, high contrast
- Updates with smooth count-down animation

---

## Integration Points

### With Game Engine
- Ghost preview requires grid state access for validation
- Hold slot integrates with piece generation system
- Both features need save state support (restore held piece, ghost settings)

### With Tutorial System
- Ghost preview introduced in tutorial level 1
- Hold slot unlocked at level 3 with dedicated tutorial
- Strategic usage tips shown in loading screens

### With Themes
- Ghost preview color adjusts based on theme (always readable)
- Hold slot styling matches theme visual language
- Animations adapt to theme aesthetic

---

## Settings & Configuration

**User Preferences:**
- **Ghost Preview**:
  * Enable/Disable (default: On)
  * Show line clear preview (default: On)
  * Show score preview (default: On)
  * Snap to grid (default: On)
  * Ghost opacity: 20%-50% slider (default: 30%)

- **Hold Slot**:
  * Enable/Disable (default: On after unlock)
  * Swap limitation mode (default: varies by mode)
  * Hold slot position: Above/Beside/Bottom (default: Above)
  * Show strategic hints (default: Off)
  * Swap interaction method (default: Tap)

---

## Performance Requirements

**Frame Rate:**
- Ghost updates at 120fps on ProMotion displays
- 60fps minimum on all other devices
- Zero frame drops during ghost rendering

**Memory:**
- Ghost preview: < 5MB additional memory
- Hold slot: < 2MB additional memory
- No memory leaks from repeated swaps

**Latency:**
- Touch-to-ghost-update: < 16ms (sub-frame)
- Swap animation trigger: < 10ms
- Validation calculation: < 5ms

---

## Implementation Checklist

- [ ] Create GhostPreviewManager class
- [ ] Implement real-time position tracking
- [ ] Build placement validation system
- [ ] Create ghost overlay rendering (Metal shader)
- [ ] Implement color-coded validity visual
- [ ] Add dashed outline rendering
- [ ] Build snap-to-grid magnetic behavior
- [ ] Implement line clear preview highlighting
- [ ] Create score gain preview display
- [ ] Optimize ghost rendering for 120fps
- [ ] Create HoldSlotManager class
- [ ] Implement swap animation (rotation + scale)
- [ ] Build cooldown system with visual indicator
- [ ] Create hold slot UI component
- [ ] Implement all interaction methods (tap, swipe, button)
- [ ] Build strategic indicator system (optional)
- [ ] Create first-use tutorial flow
- [ ] Add settings for both features
- [ ] Implement save state support
- [ ] Integrate with existing game modes
- [ ] Test on all device sizes
- [ ] Verify accessibility compliance
- [ ] Performance test on target devices

---

## Success Criteria

✅ Ghost preview appears within 0.1s of drag start
✅ Ghost position updates smoothly at 120fps on ProMotion
✅ Validity color changes instantly and accurately
✅ Snap-to-grid feels natural and helpful
✅ Line clear preview highlights correctly
✅ Score preview shows accurate calculation
✅ Hold slot swap animation is smooth (0.3s)
✅ Cooldown indicator is clear and accurate
✅ All interaction methods work reliably
✅ Tutorial effectively teaches hold mechanic
✅ No performance impact on gameplay (120fps maintained)
✅ Memory usage remains under target (< 150MB total)
✅ Features work across all themes
✅ Settings persist correctly
✅ Accessibility features functional (VoiceOver, high contrast)
