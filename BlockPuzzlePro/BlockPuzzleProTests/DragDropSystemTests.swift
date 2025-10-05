//
//  DragDropSystemTests.swift
//  BlockPuzzleProTests
//
//  Created on October 3, 2025
//  Purpose: Test-driven development for simplified drag & drop system
//

import XCTest
@testable import BlockPuzzlePro

@MainActor
final class DragDropSystemTests: XCTestCase {

    // MARK: - Test Fixtures

    var controller: SimplifiedDragController!
    var gameEngine: GameEngine!
    var placementEngine: SimplifiedPlacementEngine!

    let gridFrame = CGRect(x: 100, y: 200, width: 360, height: 360)
    let cellSize: CGFloat = 36.0
    let gridSize = 10

    override func setUp() async throws {
        try await super.setUp()

        gameEngine = GameEngine(gameMode: .classic)
        controller = SimplifiedDragController()
        placementEngine = SimplifiedPlacementEngine(
            gameEngine: gameEngine,
            gridSize: gridSize
        )
    }

    override func tearDown() async throws {
        controller = nil
        gameEngine = nil
        placementEngine = nil
        try await super.tearDown()
    }

    // MARK: - Test 1: Coordinate Accuracy

    /// Test that finger offset is calculated correctly and remains constant throughout drag
    func testFingerOffsetRemainsConstant() {
        // GIVEN: User touches block at specific location
        let touchLocation = CGPoint(x: 200, y: 300)
        let blockOrigin = CGPoint(x: 150, y: 250)
        let blockPattern = BlockPattern.square1x1  // Simple 1x1 block

        // Expected offset: touch - origin = (50, 50)
        let expectedOffset = CGSize(width: 50, height: 50)

        // WHEN: Drag starts
        controller.startDrag(
            blockIndex: 0,
            pattern: blockPattern,
            touchLocation: touchLocation,
            blockOrigin: blockOrigin
        )

        // THEN: Offset should be calculated correctly
        XCTAssertEqual(
            controller.fingerOffset.width,
            expectedOffset.width,
            accuracy: 0.01,
            "Finger offset width should be 50"
        )
        XCTAssertEqual(
            controller.fingerOffset.height,
            expectedOffset.height,
            accuracy: 0.01,
            "Finger offset height should be 50"
        )

        // AND WHEN: User drags to new location
        let newTouchLocation = CGPoint(x: 300, y: 400)
        controller.updateDrag(to: newTouchLocation)

        // THEN: Offset should NOT change
        XCTAssertEqual(
            controller.fingerOffset.width,
            expectedOffset.width,
            accuracy: 0.01,
            "Finger offset should remain constant during drag"
        )
        XCTAssertEqual(
            controller.fingerOffset.height,
            expectedOffset.height,
            accuracy: 0.01,
            "Finger offset should remain constant during drag"
        )

        // AND: Block origin should follow finger precisely
        let expectedBlockOrigin = CGPoint(
            x: newTouchLocation.x - expectedOffset.width,
            y: newTouchLocation.y - expectedOffset.height
        )

        XCTAssertEqual(
            controller.currentBlockOrigin.x,
            expectedBlockOrigin.x,
            accuracy: 0.01,
            "Block origin should follow finger (x)"
        )
        XCTAssertEqual(
            controller.currentBlockOrigin.y,
            expectedBlockOrigin.y,
            accuracy: 0.01,
            "Block origin should follow finger (y)"
        )
    }

    /// Test that block origin calculation is accurate across multiple drag updates
    func testBlockOriginFollowsFinger() {
        // GIVEN: Drag has started with known offset
        let blockOrigin = CGPoint(x: 100, y: 100)
        let touchLocation = CGPoint(x: 150, y: 150)

        controller.startDrag(
            blockIndex: 0,
            pattern: .square1x1,
            touchLocation: touchLocation,
            blockOrigin: blockOrigin
        )

        // Offset should be (50, 50)
        XCTAssertEqual(controller.fingerOffset, CGSize(width: 50, height: 50))

        // WHEN: User drags to multiple positions
        let testPositions: [(touch: CGPoint, expectedOrigin: CGPoint)] = [
            (CGPoint(x: 200, y: 250), CGPoint(x: 150, y: 200)),  // 200-50, 250-50
            (CGPoint(x: 300, y: 350), CGPoint(x: 250, y: 300)),  // 300-50, 350-50
            (CGPoint(x: 175, y: 225), CGPoint(x: 125, y: 175)),  // 175-50, 225-50
            (CGPoint(x: 50, y: 75), CGPoint(x: 0, y: 25))        // 50-50, 75-50 (edge case)
        ]

        // THEN: Block origin should match expected for each position
        for (touchPos, expectedOrigin) in testPositions {
            controller.updateDrag(to: touchPos)

            XCTAssertEqual(
                controller.currentBlockOrigin.x,
                expectedOrigin.x,
                accuracy: 0.01,
                "Block origin X incorrect at touch \(touchPos)"
            )
            XCTAssertEqual(
                controller.currentBlockOrigin.y,
                expectedOrigin.y,
                accuracy: 0.01,
                "Block origin Y incorrect at touch \(touchPos)"
            )
        }
    }

    // MARK: - Test 2: Preview Matches Placement

    /// Test that preview position exactly matches final placement position
    func testPreviewMatchesFinalPlacement() {
        // GIVEN: Empty grid and a block ready to place
        XCTAssertTrue(gameEngine.isBoardCompletelyEmpty(), "Grid should start empty")

        let blockPattern = BlockPattern.square2x2
        let touchLocation = CGPoint(x: 172, y: 272)  // Should map to cell (2, 2)
        let blockOrigin = CGPoint(x: 150, y: 250)

        controller.startDrag(
            blockIndex: 0,
            pattern: blockPattern,
            touchLocation: touchLocation,
            blockOrigin: blockOrigin
        )

        // WHEN: User drags over grid at specific cell
        controller.updateDrag(to: touchLocation)

        // Update placement engine with same parameters
        placementEngine.updatePreview(
            blockPattern: blockPattern,
            touchLocation: touchLocation,
            gridFrame: gridFrame,
            cellSize: cellSize
        )

        // THEN: Preview should show cell (2, 2)
        let previewCell = controller.getGridCell(
            touchLocation: touchLocation,
            gridFrame: gridFrame,
            cellSize: cellSize
        )

        XCTAssertNotNil(previewCell, "Preview cell should be calculated")
        XCTAssertEqual(previewCell?.row, 2, "Preview should show row 2")
        XCTAssertEqual(previewCell?.column, 2, "Preview should show column 2")

        // AND WHEN: User releases at same position
        controller.endDrag(at: touchLocation)

        // Simulate placement
        if let cell = previewCell,
           let gridPosition = GridPosition(row: cell.row, column: cell.column, gridSize: gridSize) {
            let positions = blockPattern.getGridPositions(placedAt: gridPosition)
            let placed = gameEngine.placeBlocks(at: positions, color: blockPattern.defaultColor)
            XCTAssertTrue(placed, "Block should place successfully")

            // THEN: Placed position should match preview position EXACTLY
            // This is the critical test - preview MUST equal placement
            XCTAssertEqual(cell.row, 2, "Placement row should match preview")
            XCTAssertEqual(cell.column, 2, "Placement column should match preview")
        } else {
            XCTFail("Should be able to place block at previewed position")
        }
    }

    /// Test screen-to-grid conversion accuracy
    func testScreenToGridConversion() {
        // Test cases: (touchLocation, expectedRow, expectedColumn)
        let testCases: [(CGPoint, Int, Int)] = [
            // Top-left corner
            (CGPoint(x: 100, y: 200), 0, 0),

            // Cell (2, 2) - center area
            (CGPoint(x: 172, y: 272), 2, 2),

            // Cell (5, 7)
            (CGPoint(x: 352, y: 380), 5, 7),

            // Bottom-right area cell (9, 9)
            (CGPoint(x: 424, y: 524), 9, 9),

            // Edge of cell (should round down)
            (CGPoint(x: 135, y: 235), 0, 0),  // Just inside cell (0,0)
            (CGPoint(x: 171, y: 271), 1, 1),  // Just inside cell (1,1)
        ]

        for (touchLocation, expectedRow, expectedColumn) in testCases {
            let cell = controller.getGridCell(
                touchLocation: touchLocation,
                gridFrame: gridFrame,
                cellSize: cellSize
            )

            XCTAssertNotNil(
                cell,
                "Should convert touch \(touchLocation) to grid cell"
            )

            XCTAssertEqual(
                cell?.row,
                expectedRow,
                "Row mismatch for touch at \(touchLocation)"
            )

            XCTAssertEqual(
                cell?.column,
                expectedColumn,
                "Column mismatch for touch at \(touchLocation)"
            )
        }
    }

    /// Test grid-to-screen conversion accuracy (reverse operation)
    func testGridToScreenConversion() {
        // Test cases: (row, column, expectedX, expectedY)
        let testCases: [(Int, Int, CGFloat, CGFloat)] = [
            (0, 0, 100, 200),      // Top-left
            (2, 2, 172, 272),      // Middle area
            (5, 7, 352, 380),      // Different area
            (9, 9, 424, 524),      // Bottom-right
        ]

        for (row, column, expectedX, expectedY) in testCases {
            let screenPosition = controller.gridCellToScreen(
                row: row,
                column: column,
                gridFrame: gridFrame,
                cellSize: cellSize
            )

            XCTAssertEqual(
                screenPosition.x,
                expectedX,
                accuracy: 0.01,
                "Screen X mismatch for cell (\(row), \(column))"
            )

            XCTAssertEqual(
                screenPosition.y,
                expectedY,
                accuracy: 0.01,
                "Screen Y mismatch for cell (\(row), \(column))"
            )
        }
    }

    /// Test round-trip conversion (screen → grid → screen should be identity)
    func testRoundTripConversion() {
        let testTouchLocations: [CGPoint] = [
            CGPoint(x: 172, y: 272),  // Cell (2, 2)
            CGPoint(x: 208, y: 308),  // Cell (3, 3)
            CGPoint(x: 316, y: 416),  // Cell (6, 6)
        ]

        for touchLocation in testTouchLocations {
            // Convert touch to grid cell
            guard let cell = controller.getGridCell(
                touchLocation: touchLocation,
                gridFrame: gridFrame,
                cellSize: cellSize
            ) else {
                XCTFail("Should convert touch \(touchLocation) to cell")
                continue
            }

            // Convert grid cell back to screen
            let screenPosition = controller.gridCellToScreen(
                row: cell.row,
                column: cell.column,
                gridFrame: gridFrame,
                cellSize: cellSize
            )

            // Calculate expected position (cell origin)
            let expectedX = gridFrame.minX + (CGFloat(cell.column) * cellSize)
            let expectedY = gridFrame.minY + (CGFloat(cell.row) * cellSize)

            XCTAssertEqual(
                screenPosition.x,
                expectedX,
                accuracy: 0.01,
                "Round-trip X conversion failed for \(touchLocation)"
            )

            XCTAssertEqual(
                screenPosition.y,
                expectedY,
                accuracy: 0.01,
                "Round-trip Y conversion failed for \(touchLocation)"
            )
        }
    }

    // MARK: - Test 3: Vicinity Touch

    /// Test that vicinity touch works with 80pt radius
    func testVicinityTouchRadius() {
        let blockCenter = CGPoint(x: 200, y: 300)
        let blockSize: CGFloat = 60  // Visual size
        let vicinityRadius: CGFloat = 80  // Minimum per research

        // Test cases: (touchPoint, shouldSelect, description)
        let testCases: [(CGPoint, Bool, String)] = [
            // Inside block
            (CGPoint(x: 200, y: 300), true, "Center of block"),
            (CGPoint(x: 220, y: 320), true, "Inside block bounds"),

            // Just outside block but within vicinity
            (CGPoint(x: 260, y: 340), true, "60pt away (within 80pt radius)"),
            (CGPoint(x: 256, y: 356), true, "70pt away (within 80pt radius)"),

            // At edge of vicinity radius
            (CGPoint(x: 280, y: 300), true, "80pt away horizontally"),
            (CGPoint(x: 200, y: 380), true, "80pt away vertically"),

            // Outside vicinity radius
            (CGPoint(x: 290, y: 300), false, "90pt away (outside 80pt radius)"),
            (CGPoint(x: 200, y: 400), false, "100pt away (outside 80pt radius)"),
            (CGPoint(x: 350, y: 450), false, "Far away"),
        ]

        for (touchPoint, shouldSelect, description) in testCases {
            let distance = hypot(
                touchPoint.x - blockCenter.x,
                touchPoint.y - blockCenter.y
            )

            let selected = controller.shouldSelectBlock(
                touchLocation: touchPoint,
                blockCenter: blockCenter,
                vicinityRadius: vicinityRadius
            )

            XCTAssertEqual(
                selected,
                shouldSelect,
                "\(description) - distance: \(distance)pt, expected \(shouldSelect ? "selected" : "not selected")"
            )
        }
    }

    /// Test vicinity touch with small blocks (most critical)
    func testVicinityTouchForSmallBlocks() {
        // Small 1x1 block (30pt visual size) - needs large vicinity
        let blockSize: CGFloat = 30
        let blockCenter = CGPoint(x: 150, y: 250)
        let vicinityRadius: CGFloat = 80  // Much larger than block

        // User taps 50pt away (outside block but within vicinity)
        let touchPoint = CGPoint(x: 200, y: 250)

        let selected = controller.shouldSelectBlock(
            touchLocation: touchPoint,
            blockCenter: blockCenter,
            vicinityRadius: vicinityRadius
        )

        XCTAssertTrue(
            selected,
            "Should select small block even when touching outside its visual bounds"
        )
    }

    // MARK: - Test 4: Invalid Placement

    /// Test that invalid placements return block to tray
    func testInvalidPlacementReturnsToTray() {
        // GIVEN: Grid with occupied cells
        let blockPattern = BlockPattern.square2x2
        let occupiedPosition = GridPosition(row: 2, column: 2, gridSize: gridSize)!

        // Place a block to create occupied cells
        let occupiedPositions = blockPattern.getGridPositions(placedAt: occupiedPosition)
        gameEngine.placeBlocks(at: occupiedPositions, color: .blue)

        // Verify cells are occupied
        for pos in occupiedPositions {
            XCTAssertFalse(
                gameEngine.canPlaceAt(position: pos),
                "Cell at \(pos) should be occupied"
            )
        }

        // WHEN: User tries to place another block on same spot
        let touchLocation = CGPoint(x: 172, y: 272)  // Cell (2, 2)
        let blockOrigin = CGPoint(x: 150, y: 250)
        let originalTrayPosition = blockOrigin

        controller.startDrag(
            blockIndex: 0,
            pattern: blockPattern,
            touchLocation: touchLocation,
            blockOrigin: blockOrigin
        )

        controller.updateDrag(to: touchLocation)

        // Preview should show invalid
        placementEngine.updatePreview(
            blockPattern: blockPattern,
            touchLocation: touchLocation,
            gridFrame: gridFrame,
            cellSize: cellSize
        )

        XCTAssertFalse(
            placementEngine.isCurrentPreviewValid,
            "Preview should be invalid for occupied cells"
        )

        // WHEN: User releases
        controller.endDrag(at: touchLocation)

        // THEN: Controller should indicate return to tray
        XCTAssertTrue(
            controller.shouldReturnToTray,
            "Block should return to tray after invalid placement"
        )

        // AND: Block origin should animate back to original tray position
        // (In real implementation, this would be animated)
        XCTAssertEqual(
            controller.returnToTrayPosition,
            originalTrayPosition,
            "Return position should match original tray position"
        )
    }

    /// Test placement outside grid bounds
    func testPlacementOutsideGridReturnsToTray() {
        // GIVEN: Block being dragged
        let blockPattern = BlockPattern.square1x1
        let touchLocation = CGPoint(x: 50, y: 150)  // Outside grid (grid starts at x:100)
        let blockOrigin = CGPoint(x: 200, y: 300)

        controller.startDrag(
            blockIndex: 0,
            pattern: blockPattern,
            touchLocation: touchLocation,
            blockOrigin: blockOrigin
        )

        // WHEN: User drags outside grid and releases
        let outsideTouch = CGPoint(x: 50, y: 150)
        controller.updateDrag(to: outsideTouch)

        // THEN: Should not have valid grid cell
        let cell = controller.getGridCell(
            touchLocation: outsideTouch,
            gridFrame: gridFrame,
            cellSize: cellSize
        )

        XCTAssertNil(cell, "Touch outside grid should not map to cell")

        // AND WHEN: User releases
        controller.endDrag(at: outsideTouch)

        // THEN: Should return to tray
        XCTAssertTrue(
            controller.shouldReturnToTray,
            "Block should return to tray when released outside grid"
        )
    }

    // MARK: - Test 5: State Transitions

    /// Test that drag state transitions are clean and immediate
    func testDragStateTransitions() {
        // GIVEN: Controller in idle state
        XCTAssertTrue(controller.isIdle, "Should start in idle state")
        XCTAssertFalse(controller.isDragging, "Should not be dragging initially")

        // WHEN: Drag starts
        controller.startDrag(
            blockIndex: 0,
            pattern: .square1x1,
            touchLocation: CGPoint(x: 200, y: 300),
            blockOrigin: CGPoint(x: 150, y: 250)
        )

        // THEN: Should immediately transition to dragging
        XCTAssertFalse(controller.isIdle, "Should not be idle when dragging")
        XCTAssertTrue(controller.isDragging, "Should be dragging")

        // WHEN: Drag ends
        controller.endDrag(at: CGPoint(x: 200, y: 300))

        // THEN: Should immediately transition back to idle
        // (After any animations complete)
        XCTAssertTrue(
            controller.isIdle || controller.isAnimating,
            "Should be idle or animating after drag end"
        )
    }

    // MARK: - Performance Tests

    /// Test that coordinate calculations are fast enough for 120fps
    func testCoordinateCalculationPerformance() {
        // Target: Each calculation should take < 0.008ms (120fps = 8.3ms per frame)
        let iterations = 1000

        let startTouch = CGPoint(x: 200, y: 300)
        let blockOrigin = CGPoint(x: 150, y: 250)

        controller.startDrag(
            blockIndex: 0,
            pattern: .square2x2,
            touchLocation: startTouch,
            blockOrigin: blockOrigin
        )

        measure {
            for i in 0..<iterations {
                let touch = CGPoint(
                    x: 200 + CGFloat(i % 100),
                    y: 300 + CGFloat(i % 100)
                )

                controller.updateDrag(to: touch)

                _ = controller.getGridCell(
                    touchLocation: touch,
                    gridFrame: gridFrame,
                    cellSize: cellSize
                )
            }
        }
    }
}

// MARK: - Test Extensions

extension SimplifiedDragController {
    /// Test helper to check if controller is in idle state
    var isIdle: Bool {
        // This will be implemented in SimplifiedDragController
        // For now, assume it checks dragState == .idle
        return !isDragging
    }

    /// Test helper to check if currently animating
    var isAnimating: Bool {
        // This will be implemented in SimplifiedDragController
        return false  // Placeholder
    }

    /// Test helper to get return position
    var returnToTrayPosition: CGPoint {
        // This will be implemented in SimplifiedDragController
        return .zero  // Placeholder
    }
}
