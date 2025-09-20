import XCTest
@testable import BlockPuzzlePro

// MARK: - Drag Drop Tests

/// Unit tests for drag and drop functionality
final class DragDropTests: XCTestCase {
    
    // MARK: - Properties
    
    private var gameEngine: GameEngine!
    private var placementEngine: PlacementEngine!
    private var dragController: DragController!
    private var deviceManager: DeviceManager!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        gameEngine = GameEngine()
        deviceManager = DeviceManager()
        placementEngine = PlacementEngine(gameEngine: gameEngine)
        dragController = DragController(deviceManager: deviceManager)
        
        gameEngine.startNewGame()
    }
    
    override func tearDown() {
        gameEngine = nil
        placementEngine = nil
        dragController = nil
        deviceManager = nil
        
        super.tearDown()
    }
    
    // MARK: - Drag Controller Tests
    
    func testDragControllerInitialState() {
        // Given: Fresh drag controller
        // When: Checking initial state
        // Then: Should be idle
        XCTAssertFalse(dragController.isDragging)
        XCTAssertEqual(dragController.dragOffset, .zero)
        XCTAssertNil(dragController.draggedBlockIndex)
        XCTAssertNil(dragController.draggedBlockPattern)
    }
    
    func testStartDrag() {
        // Given: Block pattern and position
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let startPosition = CGPoint(x: 100, y: 100)
        let blockIndex = 0
        
        // When: Starting drag
        dragController.startDrag(
            blockIndex: blockIndex,
            blockPattern: blockPattern,
            at: startPosition,
            touchOffset: .zero
        )
        
        // Then: Drag state should be active
        XCTAssertTrue(dragController.isDragging)
        XCTAssertEqual(dragController.draggedBlockIndex, blockIndex)
        XCTAssertEqual(dragController.draggedBlockPattern?.type, blockPattern.type)
        XCTAssertEqual(dragController.currentDragPosition, startPosition)
    }
    
    func testUpdateDragPosition() {
        // Given: Active drag
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let startPosition = CGPoint(x: 100, y: 100)
        let newPosition = CGPoint(x: 150, y: 120)
        
        dragController.startDrag(blockIndex: 0, blockPattern: blockPattern, at: startPosition, touchOffset: .zero)
        
        // When: Updating drag position
        dragController.updateDrag(to: newPosition)
        
        // Then: Position should be updated
        XCTAssertEqual(dragController.currentDragPosition, newPosition)
        
        let expectedOffset = CGSize(
            width: newPosition.x - startPosition.x,
            height: newPosition.y - startPosition.y
        )
        XCTAssertEqual(dragController.dragOffset, expectedOffset)
    }
    
    func testEndDrag() {
        // Given: Active drag
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let startPosition = CGPoint(x: 100, y: 100)
        let endPosition = CGPoint(x: 150, y: 120)
        
        dragController.startDrag(blockIndex: 0, blockPattern: blockPattern, at: startPosition, touchOffset: .zero)
        
        // When: Ending drag
        dragController.endDrag(at: endPosition)
        
        // Then: Eventually should return to idle (after animation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(self.dragController.isDragging)
        }
    }
    
    // MARK: - Placement Engine Tests
    
    func testValidSingleBlockPlacement() {
        // Given: Empty grid and single block
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let gridPosition = GridPosition(row: 0, column: 0)!
        
        // When: Validating placement
        let result = placementEngine.validatePlacement(
            blockPattern: blockPattern,
            at: gridPosition
        )
        
        // Then: Should be valid
        switch result {
        case .valid(let positions):
            XCTAssertEqual(positions.count, 1)
            XCTAssertEqual(positions.first, gridPosition)
        case .invalid:
            XCTFail("Single block placement should be valid on empty grid")
        }
    }
    
    func testValidLShapeBlockPlacement() {
        // Given: Empty grid and L-shape block
        let blockPattern = BlockPattern(type: .lShape, color: .green)
        let gridPosition = GridPosition(row: 0, column: 0)!
        
        // When: Validating placement
        let result = placementEngine.validatePlacement(
            blockPattern: blockPattern,
            at: gridPosition
        )
        
        // Then: Should be valid with correct positions
        switch result {
        case .valid(let positions):
            XCTAssertEqual(positions.count, 3) // L-shape has 3 cells
            XCTAssertTrue(positions.contains(GridPosition(row: 0, column: 0)!))
            XCTAssertTrue(positions.contains(GridPosition(row: 1, column: 0)!))
            XCTAssertTrue(positions.contains(GridPosition(row: 1, column: 1)!))
        case .invalid:
            XCTFail("L-shape block placement should be valid at (0,0)")
        }
    }
    
    func testInvalidPlacementOutOfBounds() {
        // Given: Block pattern near grid edge
        let blockPattern = BlockPattern(type: .lShape, color: .green)
        let gridPosition = GridPosition(row: 9, column: 9)! // Bottom-right corner
        
        // When: Validating placement
        let result = placementEngine.validatePlacement(
            blockPattern: blockPattern,
            at: gridPosition
        )
        
        // Then: Should be invalid (out of bounds)
        switch result {
        case .valid:
            XCTFail("L-shape block at (9,9) should be invalid (out of bounds)")
        case .invalid(let reason):
            XCTAssertEqual(reason, .outOfBounds)
        }
    }
    
    func testInvalidPlacementCollision() {
        // Given: Occupied grid cell
        let gridPosition = GridPosition(row: 0, column: 0)!
        XCTAssertTrue(gameEngine.placeBlocks(at: [gridPosition], color: .red))
        
        let blockPattern = BlockPattern(type: .single, color: .blue)
        
        // When: Trying to place block on occupied cell
        let result = placementEngine.validatePlacement(
            blockPattern: blockPattern,
            at: gridPosition
        )
        
        // Then: Should be invalid (collision)
        switch result {
        case .valid:
            XCTFail("Block placement on occupied cell should be invalid")
        case .invalid(let reason):
            XCTAssertEqual(reason, .collision)
        }
    }
    
    func testScreenToGridPositionConversion() {
        // Given: Grid frame and cell size
        let gridFrame = CGRect(x: 50, y: 100, width: 300, height: 300)
        let cellSize: CGFloat = 30
        let screenPosition = CGPoint(x: 80, y: 130) // Should map to (1, 0)
        
        // When: Converting screen to grid position
        let gridPosition = placementEngine.screenToGridPosition(
            screenPosition: screenPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        )
        
        // Then: Should get correct grid position
        XCTAssertNotNil(gridPosition)
        XCTAssertEqual(gridPosition?.row, 1)
        XCTAssertEqual(gridPosition?.column, 0)
    }
    
    func testGridToScreenPositionConversion() {
        // Given: Grid position and frame
        let gridPosition = GridPosition(row: 2, column: 3)!
        let gridFrame = CGRect(x: 50, y: 100, width: 300, height: 300)
        let cellSize: CGFloat = 30
        
        // When: Converting grid to screen position
        let screenPosition = placementEngine.gridToScreenPosition(
            gridPosition: gridPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        )
        
        // Then: Should get correct screen position
        let expectedX = gridFrame.minX + (CGFloat(gridPosition.column) * cellSize) + (cellSize / 2)
        let expectedY = gridFrame.minY + (CGFloat(gridPosition.row) * cellSize) + (cellSize / 2)
        
        XCTAssertEqual(screenPosition.x, expectedX, accuracy: 0.01)
        XCTAssertEqual(screenPosition.y, expectedY, accuracy: 0.01)
    }
    
    func testPlacementPreview() {
        // Given: Block pattern and screen position
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let gridFrame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let cellSize: CGFloat = 30
        let screenPosition = CGPoint(x: 45, y: 45) // Should map to (1, 1)
        
        // When: Updating preview
        placementEngine.updatePreview(
            blockPattern: blockPattern,
            screenPosition: screenPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        )
        
        // Then: Preview should be set
        XCTAssertEqual(placementEngine.previewPositions.count, 1)
        XCTAssertTrue(placementEngine.isCurrentPreviewValid)
        XCTAssertEqual(placementEngine.previewPositions.first?.row, 1)
        XCTAssertEqual(placementEngine.previewPositions.first?.column, 1)
    }
    
    func testCommitPlacement() {
        // Given: Valid preview
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let gridFrame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let cellSize: CGFloat = 30
        let screenPosition = CGPoint(x: 15, y: 15)
        
        placementEngine.updatePreview(
            blockPattern: blockPattern,
            screenPosition: screenPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        )
        
        // When: Committing placement
        let success = placementEngine.commitPlacement(blockPattern: blockPattern)
        
        // Then: Should succeed and clear preview
        XCTAssertTrue(success)
        XCTAssertTrue(placementEngine.previewPositions.isEmpty)
        XCTAssertFalse(placementEngine.isCurrentPreviewValid)
        
        // And grid should be updated
        let gridPosition = GridPosition(row: 0, column: 0)!
        let cell = gameEngine.cell(at: gridPosition)
        XCTAssertTrue(cell?.isOccupied == true)
    }
    
    func testPreviewInvalidWhenOverlappingOccupiedCell() {
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let gridFrame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let cellSize: CGFloat = 30
        let screenPosition = CGPoint(x: 15, y: 15)

        placementEngine.updatePreview(
            blockPattern: blockPattern,
            screenPosition: screenPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        )
        XCTAssertTrue(placementEngine.commitPlacement(blockPattern: blockPattern))

        placementEngine.updatePreview(
            blockPattern: blockPattern,
            screenPosition: screenPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        )

        XCTAssertFalse(placementEngine.isCurrentPreviewValid)
        XCTAssertTrue(placementEngine.previewPositions.isEmpty)
    }

    // MARK: - Integration Tests
    
    func testCompleteDropSequence() {
        // Given: Complete drag and drop setup
        let blockPattern = BlockPattern(type: .single, color: .blue)
        let startPosition = CGPoint(x: 100, y: 100)
        let dropPosition = CGPoint(x: 15, y: 15) // Valid grid position
        let gridFrame = CGRect(x: 0, y: 0, width: 300, height: 300)
        let cellSize: CGFloat = 30
        
        // When: Performing complete sequence
        // 1. Start drag
        dragController.startDrag(blockIndex: 0, blockPattern: blockPattern, at: startPosition, touchOffset: .zero)
        XCTAssertTrue(dragController.isDragging)
        
        // 2. Update preview
        placementEngine.updatePreview(
            blockPattern: blockPattern,
            screenPosition: dropPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        )
        XCTAssertTrue(placementEngine.isCurrentPreviewValid)
        
        // 3. Commit placement
        let success = placementEngine.commitPlacement(blockPattern: blockPattern)
        XCTAssertTrue(success)
        
        // 4. End drag
        dragController.endDrag(at: dropPosition)
        
        // Then: Block should be placed on grid
        let gridPosition = GridPosition(row: 0, column: 0)!
        let cell = gameEngine.cell(at: gridPosition)
        XCTAssertTrue(cell?.isOccupied == true)
        XCTAssertEqual(cell?.color, blockPattern.color)
    }
    
    // MARK: - Performance Tests
    
    func testDragUpdatePerformance() {
        // Given: Active drag
        let blockPattern = BlockPattern(type: .lShape, color: .green)
        dragController.startDrag(blockIndex: 0, blockPattern: blockPattern, at: .zero, touchOffset: .zero)
        
        // When: Measuring update performance
        measure {
            for i in 0..<100 {
                let position = CGPoint(x: Double(i), y: Double(i))
                dragController.updateDrag(to: position)
            }
        }
    }
    
    func testPlacementValidationPerformance() {
        // Given: Complex block pattern
        let blockPattern = BlockPattern(type: .lShape, color: .green)
        
        // When: Measuring validation performance
        measure {
            for row in 0..<8 {
                for col in 0..<8 {
                    if let gridPos = GridPosition(row: row, column: col) {
                        _ = placementEngine.validatePlacement(blockPattern: blockPattern, at: gridPos)
                    }
                }
            }
        }
    }
}
