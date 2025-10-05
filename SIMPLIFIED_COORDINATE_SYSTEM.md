# Simplified Coordinate System Specification

**Date:** October 3, 2025
**Purpose:** Crystal-clear specification for V2 drag & drop system
**Goal:** Reduce from 12 transformations to 4, eliminate coordinate drift

---

## 🎯 DESIGN PRINCIPLES

### Principle 1: Single Source of Truth
**One coordinate system for everything:** Screen points (CGFloat)

### Principle 2: Constant Finger Offset
**Calculate once, use everywhere:** Finger position relative to block origin never changes during drag

### Principle 3: Direct Conversions
**No intermediate transformations:** Screen → Grid in one step

### Principle 4: Predictable Behavior
**Same input = Same output:** No state-dependent calculations

---

## 📐 COORDINATE SYSTEM

### Global Screen Space (The Only Space We Use)

```
┌─────────────────────────────────────────┐
│ Screen (UIScreen.main.bounds)           │
│                                          │
│   ┌─────────────────────┐               │
│   │ Grid (gridFrame)    │               │
│   │                     │               │
│   │  Cell(0,0)  Cell(0,1) ...          │
│   │  Cell(1,0)  Cell(1,1) ...          │
│   │  ...                │               │
│   └─────────────────────┘               │
│                                          │
│   ┌─────────────────────┐               │
│   │ Tray (trayFrame)    │               │
│   │  Block0  Block1  Block2            │
│   └─────────────────────┘               │
└─────────────────────────────────────────┘

All positions in CGPoint (screen coordinates)
All sizes in CGFloat (screen points)
```

---

## 🔢 THE MATH (4 Simple Transformations)

### TRANSFORM #1: Calculate Finger Offset (On Drag Start - ONCE)

```swift
// Given:
touchLocation: CGPoint      // Where user touched (screen coords)
blockOrigin: CGPoint        // Top-left corner of block (screen coords)

// Calculate:
fingerOffset = CGSize(
    width: touchLocation.x - blockOrigin.x,
    height: touchLocation.y - blockOrigin.y
)

// Example:
// User touches at (200, 300)
// Block origin at (150, 250)
// fingerOffset = (50, 50)
// ^^^ THIS NEVER CHANGES FOR THE ENTIRE DRAG
```

**Why constant?** User's finger stays at same relative position on block throughout drag.

---

### TRANSFORM #2: Calculate Block Origin (Every Frame)

```swift
// Given:
currentTouchLocation: CGPoint  // Where finger is now (screen coords)
fingerOffset: CGSize           // From Transform #1 (CONSTANT)

// Calculate:
blockOrigin = CGPoint(
    x: currentTouchLocation.x - fingerOffset.width,
    y: currentTouchLocation.y - fingerOffset.height
)

// Example:
// Finger moves to (300, 400)
// fingerOffset is still (50, 50)
// blockOrigin = (250, 350)
// Block follows finger perfectly!
```

**Why simple?** Just subtraction. No scaling, no lifting, no magic.

---

### TRANSFORM #3: Screen to Grid Cell (For Preview)

```swift
// Given:
touchLocation: CGPoint  // Finger position (screen coords)
gridFrame: CGRect       // Grid's frame (screen coords)
cellSize: CGFloat       // Size of one cell

// Calculate:
relativeX = touchLocation.x - gridFrame.minX
relativeY = touchLocation.y - gridFrame.minY

// Check if inside grid
guard relativeX >= 0, relativeY >= 0,
      relativeX < gridFrame.width,
      relativeY < gridFrame.height else {
    return nil  // Outside grid
}

// Convert to cell indices
column = Int(relativeX / cellSize)
row = Int(relativeY / cellSize)

gridCell = (row: row, column: column)

// Example:
// Finger at (200, 300)
// Grid starts at (100, 200), cellSize = 36
// relativeX = 100, relativeY = 100
// column = 2, row = 2
// Cell (2, 2) - simple!
```

**Why direct?** Finger position determines cell. No offset needed.

---

### TRANSFORM #4: Grid Cell to Screen Position (For Snapping)

```swift
// Given:
gridCell: (row: Int, column: Int)
gridFrame: CGRect
cellSize: CGFloat

// Calculate:
cellOriginX = gridFrame.minX + (CGFloat(column) * cellSize)
cellOriginY = gridFrame.minY + (CGFloat(row) * cellSize)

screenPosition = CGPoint(x: cellOriginX, y: cellOriginY)

// Example:
// Grid cell (2, 2)
// Grid starts at (100, 200), cellSize = 36
// cellOriginX = 100 + (2 * 36) = 172
// cellOriginY = 200 + (2 * 36) = 272
// screenPosition = (172, 272)
```

**Why needed?** To animate block snapping to exact grid position.

---

## ✅ THAT'S IT - ONLY 4 TRANSFORMS!

### Old System (12 transforms):
1. Touch in tray space
2. Calculate offset in tray coordinates
3. Convert to global coordinates
4. Adjust for scale difference (tray vs grid cells)
5. Convert to grid coordinates
6. Apply preview lift (magic constant)
7. Calculate snap position
8. Transform back to screen for preview
9. Scale offset for grid cell size
10. Adjust for anchor cell
11. Calculate snapped preview origin
12. Convert grid position back to screen

### New System (4 transforms):
1. **Calculate finger offset** (once on start)
2. **Calculate block origin** (every frame: touch - offset)
3. **Screen to grid** (for preview: simple division)
4. **Grid to screen** (for snap: simple multiplication)

**Reduction:** 66% fewer transformations = 66% fewer bugs!

---

## 🎮 USAGE EXAMPLES

### Example 1: Start Drag

```swift
func startDrag(
    blockIndex: Int,
    pattern: BlockPattern,
    touchLocation: CGPoint,
    blockFrame: CGRect
) {
    // TRANSFORM #1: Calculate constant offset
    fingerOffset = CGSize(
        width: touchLocation.x - blockFrame.minX,
        height: touchLocation.y - blockFrame.minY
    )

    dragState = .dragging(blockIndex: blockIndex, pattern: pattern)

    // Lift animation (separate from coordinates!)
    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
        dragScale = 1.3
    }

    haptic.impact(.light)
}
```

### Example 2: Update Drag (Every Frame)

```swift
func updateDrag(touchLocation: CGPoint) {
    currentTouchLocation = touchLocation

    // TRANSFORM #2: Block origin follows finger
    let blockOrigin = CGPoint(
        x: touchLocation.x - fingerOffset.width,
        y: touchLocation.y - fingerOffset.height
    )

    currentBlockOrigin = blockOrigin

    // TRANSFORM #3: Get grid cell for preview
    if let gridCell = screenToGridCell(touchLocation) {
        updatePreview(at: gridCell)
    } else {
        clearPreview()
    }
}
```

### Example 3: End Drag

```swift
func endDrag(touchLocation: CGPoint) {
    // TRANSFORM #3: Where did user release?
    guard let gridCell = screenToGridCell(touchLocation) else {
        returnToTray()
        return
    }

    // Validate placement
    guard gameEngine.canPlace(pattern, at: gridCell) else {
        returnToTray()
        return
    }

    // TRANSFORM #4: Calculate snap position
    let snapPosition = gridCellToScreen(gridCell)

    // Animate to snap position
    withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
        currentBlockOrigin = snapPosition
        dragScale = 1.0
    }

    // Place block
    gameEngine.placeBlock(pattern, at: gridCell)

    dragState = .idle
}
```

---

## 🚫 WHAT WE ELIMINATE

### ❌ No More:
- `dragPreviewLift` magic constant
- `scaledTouchOffset()` conversions
- `dragSourceCellSize` vs `gridCellSize` scaling
- `currentPreviewOrigin()` vs `snappedPreviewOrigin()`
- Dual position calculation methods
- Anchor cell detection
- Fallback grid position
- Projected base grid position

### ✅ Instead:
- **One position**: `currentBlockOrigin`
- **One conversion**: `screenToGridCell()`
- **One snap calc**: `gridCellToScreen()`
- **One offset**: `fingerOffset` (constant)

---

## 🧪 TESTABILITY

### Because math is simple, tests are simple:

```swift
func testFingerOffsetRemainsConstant() {
    // Given
    let startTouch = CGPoint(x: 200, y: 300)
    let blockOrigin = CGPoint(x: 150, y: 250)

    controller.startDrag(touchLocation: startTouch, blockOrigin: blockOrigin)

    // When
    controller.updateDrag(touchLocation: CGPoint(x: 300, y: 400))

    // Then
    let expectedOrigin = CGPoint(x: 250, y: 350)  // 300-50, 400-50
    XCTAssertEqual(controller.currentBlockOrigin, expectedOrigin)
}

func testScreenToGridConversion() {
    // Given
    let gridFrame = CGRect(x: 100, y: 200, width: 360, height: 360)
    let cellSize: CGFloat = 36

    // When
    let cell = controller.screenToGridCell(
        CGPoint(x: 172, y: 272),
        gridFrame: gridFrame,
        cellSize: cellSize
    )

    // Then
    XCTAssertEqual(cell?.row, 2)
    XCTAssertEqual(cell?.column, 2)
}

func testGridToScreenConversion() {
    // Given
    let gridFrame = CGRect(x: 100, y: 200, width: 360, height: 360)
    let cellSize: CGFloat = 36

    // When
    let position = controller.gridCellToScreen(
        row: 2,
        column: 2,
        gridFrame: gridFrame,
        cellSize: cellSize
    )

    // Then
    XCTAssertEqual(position.x, 172)
    XCTAssertEqual(position.y, 272)
}

func testPreviewMatchesPlacement() {
    // Given
    let touchLocation = CGPoint(x: 200, y: 300)
    controller.updateDrag(touchLocation: touchLocation)

    // When
    let previewCell = controller.currentPreviewCell
    controller.endDrag(touchLocation: touchLocation)
    let placedCell = gameEngine.lastPlacedCell

    // Then
    XCTAssertEqual(previewCell, placedCell)  // MUST match!
}
```

---

## 📊 DATA FLOW DIAGRAM

```
User Touch
    ↓
┌───────────────────────────────────────┐
│ DRAG START                            │
│                                       │
│ Input: touchLocation, blockFrame      │
│                                       │
│ fingerOffset = touch - blockOrigin    │ ← TRANSFORM #1 (ONCE)
│                                       │
│ dragState = .dragging                 │
│ dragScale = 1.3                       │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│ DRAG UPDATE (Every Frame)             │
│                                       │
│ Input: currentTouchLocation           │
│                                       │
│ blockOrigin =                         │ ← TRANSFORM #2
│   touch - fingerOffset                │
│                                       │
│ gridCell =                            │ ← TRANSFORM #3
│   screenToGridCell(touch)             │
│                                       │
│ updatePreview(gridCell)               │
└───────────────────────────────────────┘
    ↓
┌───────────────────────────────────────┐
│ DRAG END                              │
│                                       │
│ Input: finalTouchLocation             │
│                                       │
│ gridCell =                            │ ← TRANSFORM #3
│   screenToGridCell(touch)             │
│                                       │
│ if valid:                             │
│   snapPos = gridCellToScreen(cell)    │ ← TRANSFORM #4
│   animate to snapPos                  │
│   placeBlock(pattern, cell)           │
│ else:                                 │
│   returnToTray()                      │
│                                       │
│ dragState = .idle                     │
└───────────────────────────────────────┘
```

---

## 🎨 VISUAL EFFECTS (Separate from Coordinates)

**Important:** Visual effects don't affect coordinate calculations!

```swift
// Lift & Shadow (cosmetic only)
@Published var dragScale: CGFloat = 1.0        // 1.3 when dragging
@Published var shadowOpacity: Double = 0.0     // 0.3 when dragging
@Published var shadowRadius: CGFloat = 0       // 8pt when dragging

// Rotation (optional, cosmetic)
@Published var dragRotation: Angle = .zero     // 2° constant tilt

// These are purely visual - they DON'T affect:
// - fingerOffset calculation
// - blockOrigin calculation
// - grid cell calculation
// - snap position calculation
```

---

## 🔍 DEBUGGING

Because system is simple, debugging is simple:

```swift
func logCurrentState() {
    print("─────────────────────────────────")
    print("Touch Location:  \(currentTouchLocation)")
    print("Finger Offset:   \(fingerOffset)")
    print("Block Origin:    \(currentBlockOrigin)")
    print("Expected Origin: \(currentTouchLocation.x - fingerOffset.width, currentTouchLocation.y - fingerOffset.height)")
    print("Match? \(currentBlockOrigin == expectedOrigin)")

    if let cell = currentGridCell {
        print("Grid Cell:       (\(cell.row), \(cell.column))")
        print("Cell Screen Pos: \(gridCellToScreen(cell))")
    }
    print("─────────────────────────────────")
}
```

**If preview doesn't match placement:**
1. Print finger offset (should be constant)
2. Print block origin (should be touch - offset)
3. Print grid cell (should be same for preview and placement)
4. Print snap position (should match visual position)

**One of these 4 will be wrong - easy to fix!**

---

## ✅ SUCCESS CRITERIA

After implementing this system:

### Quantitative:
- [ ] `fingerOffset` never changes during drag (log every frame)
- [ ] Block origin = touch - offset (verify with assertions)
- [ ] Preview cell = placement cell (100% match)
- [ ] Code reduced from 641+500 = 1141 lines to ~300 lines
- [ ] Transforms reduced from 12 to 4

### Qualitative:
- [ ] Block "sticks" to finger (no lag)
- [ ] Preview shows exactly where block will land
- [ ] Snap is predictable (same finger position → same cell)
- [ ] No flicker or jitter
- [ ] Feels responsive and polished

---

**Status:** ✅ Specification Complete
**Next Step:** Write tests based on this spec
**Confidence:** HIGH (simple math, easy to verify)
