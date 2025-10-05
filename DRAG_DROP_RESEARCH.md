# Block Puzzle Drag & Drop - Industry Research & Best Practices

**Date:** October 3, 2025
**Purpose:** Comprehensive research to inform drag & drop system design

---

## 📊 INDUSTRY STANDARDS

### 1. **Touch Target Sizes** (Critical for Mobile Games)

#### Minimum Sizes:
- **Absolute minimum:** 44pt x 44pt (iOS Human Interface Guidelines)
- **Android standard:** 48dp x 48dp (≈9mm - size of finger pad)
- **Recommended for games:** 11-12mm (42-46px) depending on screen position
- **With padding/spacing:** 48dp target with 8dp spacing between elements

#### Why This Matters:
- Smaller targets = more missed taps = frustration
- Research shows 7mm works in screen center, but 11-12mm needed at edges
- "Rage taps" occur when targets are too small

#### For Block Puzzle Games:
- **Tray blocks should have:** 60-80pt tap targets MINIMUM
- **Vicinity radius:** 60-100pt around block center for forgiving selection
- **Reasoning:** User is focusing on placement, not precisely tapping block

---

### 2. **Drag & Drop UX Principles** (From Industry Leaders)

#### Visual Affordances:
✅ **Must have:**
- Clear visual indication that item is draggable
- Immediate feedback when drag begins
- Visual cursor/preview that follows finger
- Clear drop zones with visual feedback

✅ **Recommended:**
- Lift animation on pickup (scale 1.2-1.4x)
- Shadow effect during drag
- Semi-transparent preview at drop location
- Different visual for valid vs invalid drop

#### Touch Interaction Pattern:
```
1. Tap on item (with forgiving hit target)
2. Item "lifts" with scale animation + shadow
3. Item follows finger precisely (no lag)
4. Preview shows where item will land
5. Release = item snaps to grid OR returns to origin
```

---

### 3. **Tetris & Block Game Mechanics** (Proven Standards)

#### Lock Delay (from Official Tetris Guideline):
- **Purpose:** Give player time to make final adjustments
- **Standard:** 0.5 seconds after piece touches down
- **Application:** In our game, this means showing preview BEFORE final commit

#### Super Rotation System (SRS):
- **Purpose:** Allow rotation even when constrained
- **Key insight:** Players expect pieces to "fit" even in tight spaces
- **Application:** Our game should snap blocks to nearest valid position

#### Mobile Tetris Controls:
- **Touch or on-screen buttons** - both must work
- **Swipe gestures** - optional but appreciated
- **Immediate visual feedback** - critical for feel

---

### 4. **Drag Preview Systems** (Best Practices)

#### The "Ghost Piece" Pattern:
**What it is:** Semi-transparent preview at drop location

**Why it works:**
- Player sees EXACTLY where piece will land
- Reduces guesswork and frustration
- Standard in Tetris, Block Blast, Woodoku

**Implementation requirements:**
- Update position in real-time (60-120fps)
- Show grid snapping behavior
- Different color for valid (green/blue) vs invalid (red/gray)
- Opacity: 0.3-0.5 for preview, 1.0 for actual piece

---

### 5. **Vicinity Touch** (Expanded Hit Targets)

#### What Top Games Do:
**Block Blast approach:**
- Block appears to be 60x60pt
- Actual touch target: 100x100pt
- Vicinity radius: 50pt beyond visual bounds

**Why this works:**
- User doesn't have to be pixel-perfect
- Especially important when blocks are small
- Reduces "missed tap" frustration

**Implementation:**
```swift
// Visual block size: 60pt
// Touch detection: 100pt (60 + 40pt padding)
let vicinityFrame = blockFrame.insetBy(dx: -20, dy: -20)
if vicinityFrame.contains(touchPoint) {
    // Select this block
}
```

---

### 6. **Lift & Enlarge Animation** (Feel & Feedback)

#### Industry Standard:
- **Scale:** 1.2x - 1.4x (not too big, not too small)
- **Duration:** 0.15-0.2s (instant feedback, not sluggish)
- **Easing:** Spring animation (natural, bouncy)
- **Shadow:** Add depth (radius: 8-12pt, opacity: 0.3)

#### Why Specific Scale Matters:
- **Too small (1.1x):** Barely noticeable, feels unresponsive
- **Too large (1.8x+):** Obscures grid, feels clumsy
- **Sweet spot (1.3x):** Clear feedback without blocking view

#### Additional Effects:
- Slight rotation (2-3°) - adds playfulness
- Pulse/glow effect - emphasizes selection
- Haptic feedback - tactile confirmation

---

## 🎯 CURRENT SYSTEM ANALYSIS

Let me document what we currently have and what needs fixing:

### What Exists:
✅ UIKit touch detection layer (UITouchBlockTrayView)
✅ Vicinity touch detection (vicinityRadius parameter)
✅ Drag scale animation (dragController.dragScale)
✅ FloatingBlockPreview component
✅ PlacementEngine with preview system
✅ ProMotion 120fps optimization

### What's Broken:
❌ Preview position doesn't match finger precisely
❌ Snap behavior unpredictable
❌ Coordinate transformations too complex
❌ Preview flickers or disappears
❌ Final placement doesn't match preview

### Root Cause:
The issue is **coordinate space complexity:**
- Tray uses one cell size
- Grid uses different cell size
- Multiple transformations between spaces
- Offset calculations accumulate errors
- Preview lift adds another variable

---

## 💡 SOLUTION DESIGN

### Core Principle:
**"One Source of Truth for Block Position"**

### The Math:
```
At any moment in time:
  fingerPosition = (x, y) in screen coordinates

When drag starts:
  fingerOffset = fingerPosition - blockOrigin
  ^ This NEVER changes during drag

During drag:
  blockOrigin = fingerPosition - fingerOffset
  ^ Simple subtraction, always accurate

For preview:
  gridPosition = screenToGrid(fingerPosition)
  ^ Direct conversion, no offset needed
```

### Why This Works:
1. **Constant offset** - No recalculation, no drift
2. **Direct conversion** - Finger position → grid cell in one step
3. **Predictable** - Same input always gives same output
4. **Debuggable** - Can log exact numbers at each step

---

## 🎮 IMPLEMENTATION REQUIREMENTS

### 1. **Lift & Enlarge** (0.15s spring to 1.3x scale)
```swift
// On touch down
withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
    dragScale = 1.3
    shadowOpacity = 0.3
}
```

**Why:**
- Response 0.15s = instant feel
- Damping 0.8 = slight bounce
- Scale 1.3 = visible but not blocking
- Shadow = depth perception

### 2. **Vicinity Touch** (80-100pt radius)
```swift
let vicinityRadius: CGFloat = 80  // ~11mm at standard density

func findBlockNearTouch(at point: CGPoint) -> Int? {
    for (index, blockFrame) in blockFrames {
        let expandedFrame = blockFrame.insetBy(dx: -vicinityRadius, dy: -vicinityRadius)
        if expandedFrame.contains(point) {
            return index
        }
    }
    return nil
}
```

**Why:**
- 80pt = 11mm = ergonomic for thumb
- Works even if user taps "near" block
- Critical for small pieces (1x1, 2x1)

### 3. **Ghost Preview** (follows finger, shows snap)
```swift
// Update every frame
func updatePreview(fingerPosition: CGPoint) {
    let gridCell = positionToGridCell(fingerPosition)

    if canPlace(pattern, at: gridCell) {
        showPreview(at: gridCell, color: .blue, opacity: 0.4)
    } else {
        showPreview(at: gridCell, color: .red, opacity: 0.3)
    }
}
```

**Why:**
- Real-time update = responsive feel
- Color coding = instant feedback
- Opacity = distinguishes from actual blocks
- Shows exact final position

### 4. **Predictable Snap** (finger determines cell)
```swift
func screenToGrid(_ point: CGPoint) -> GridPosition {
    let relativeX = point.x - gridFrame.minX
    let relativeY = point.y - gridFrame.minY

    let column = Int(relativeX / cellSize)
    let row = Int(relativeY / cellSize)

    return GridPosition(row: row, column: column)
}
```

**Why:**
- Direct conversion = no ambiguity
- Finger position determines cell
- Works same way every time
- Easy to understand and debug

---

## 📋 TESTING CHECKLIST

After implementation, test these scenarios:

### Basic Functionality:
- [ ] Tap small block (1x1) in tray → lifts immediately
- [ ] Tap large block (3x3) in tray → lifts immediately
- [ ] Drag block over grid → preview appears
- [ ] Release on valid spot → block places exactly where previewed
- [ ] Release on invalid spot → block returns to tray

### Edge Cases:
- [ ] Tap between two blocks → selects nearest
- [ ] Tap slightly off-center → still selects block
- [ ] Drag very fast → preview keeps up
- [ ] Grid is full → preview shows all invalid
- [ ] Rotate device → touch targets still work

### Feel & Polish:
- [ ] Lift animation feels snappy (not slow)
- [ ] Block follows finger without lag
- [ ] Preview updates smoothly at 60fps+
- [ ] Snap is predictable (same spot every time)
- [ ] Haptic feedback confirms actions

---

## 🔬 WHY PRECISION MATTERS

### User Psychology:
When a player picks up a block and drags it to the grid, they form a **mental model:**
- "My finger is here"
- "The block will go here"
- "This looks like it fits"

If the final placement doesn't match this mental model:
- ❌ Confusion ("Why did it go there?")
- ❌ Frustration ("That's not where I put it!")
- ❌ Mistrust ("I can't rely on this game")
- ❌ Abandonment (Uninstall)

### The "Magic Moment":
When drag & drop works perfectly:
- ✨ Player feels **in control**
- ✨ Actions feel **responsive**
- ✨ Game feels **polished**
- ✨ Player **trusts** the mechanics
- ✨ **Flow state** achieved

This is the difference between a 3-star and 5-star rated puzzle game.

---

## 📐 MATHEMATICAL PRECISION

### The Coordinate Problem:
```
Problem: Tray uses 32pt cells, Grid uses 36pt cells

Bad approach (current):
1. Get touch in tray coordinates
2. Calculate offset in tray coordinates
3. Convert to global coordinates
4. Adjust for scale difference
5. Convert to grid coordinates
6. Apply preview lift
7. Calculate snap position

^ 7 transformations = 7 chances for error
```

### The Solution:
```
Good approach (V2):
1. Get touch in screen coordinates
2. Calculate fingerOffset = touch - blockOrigin
3. During drag: blockOrigin = touch - fingerOffset
4. Convert screen to grid: gridCell = (touch.x - gridX) / cellSize

^ 4 steps total, all in absolute coordinates
```

### Why This is Better:
- **Fewer transformations** = fewer errors
- **Absolute coordinates** = no accumulation
- **Single source of truth** = consistent results
- **Debuggable** = can print exact values

---

## 🎯 SUCCESS METRICS

After implementing improvements, we should see:

### Quantitative:
- [ ] 0ms perceived lag between finger and preview
- [ ] 100% accuracy: preview position = final position
- [ ] 120fps animation on ProMotion devices
- [ ] <5% "undo" rate (player places wrong block)

### Qualitative:
- [ ] Drag feels "sticky" to finger (follows precisely)
- [ ] Lift animation feels satisfying
- [ ] Snap feels predictable
- [ ] Overall feel is "polished" and "professional"

---

**Next Steps:**
1. Apply these principles to current system
2. Fix coordinate math to use single source of truth
3. Implement proper lift & enlarge (1.3x, 0.15s)
4. Ensure vicinity touch is 80-100pt
5. Make preview follow finger precisely
6. Test thoroughly

**Time Estimate:** 6-8 hours for proper implementation
**Priority:** CRITICAL - This is the core game mechanic
