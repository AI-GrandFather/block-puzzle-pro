import XCTest
@testable import BlockPuzzlePro

// MARK: - BlockType Tests

final class BlockTypeTests: XCTestCase {
    
    // MARK: - Properties Tests
    
    func testBlockType_AllCasesExist() {
        // Given/When
        let allCases = BlockType.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.single))
        XCTAssertTrue(allCases.contains(.horizontal))
        XCTAssertTrue(allCases.contains(.lShape))
    }
    
    func testBlockType_DisplayNames() {
        // Given/When/Then
        XCTAssertEqual(BlockType.single.displayName, "Single Block")
        XCTAssertEqual(BlockType.horizontal.displayName, "Horizontal Block")
        XCTAssertEqual(BlockType.lShape.displayName, "L-Shape Block")
    }
    
    func testBlockType_IdsMatchRawValues() {
        // Given/When/Then
        XCTAssertEqual(BlockType.single.id, "single")
        XCTAssertEqual(BlockType.horizontal.id, "horizontal")
        XCTAssertEqual(BlockType.lShape.id, "lShape")
    }
    
    // MARK: - Pattern Tests
    
    func testSingleBlock_Pattern() {
        // Given
        let blockType = BlockType.single
        
        // When
        let pattern = blockType.pattern
        
        // Then
        let expectedPattern = [[true]]
        XCTAssertEqual(pattern.count, 1)
        XCTAssertEqual(pattern[0].count, 1)
        XCTAssertEqual(pattern[0][0], true)
        XCTAssertEqual(pattern, expectedPattern)
    }
    
    func testHorizontalBlock_Pattern() {
        // Given
        let blockType = BlockType.horizontal
        
        // When
        let pattern = blockType.pattern
        
        // Then
        let expectedPattern = [[true, true]]
        XCTAssertEqual(pattern.count, 1)
        XCTAssertEqual(pattern[0].count, 2)
        XCTAssertEqual(pattern[0][0], true)
        XCTAssertEqual(pattern[0][1], true)
        XCTAssertEqual(pattern, expectedPattern)
    }
    
    func testLShapeBlock_Pattern() {
        // Given
        let blockType = BlockType.lShape
        
        // When
        let pattern = blockType.pattern
        
        // Then
        let expectedPattern = [
            [true, false],
            [true, true]
        ]
        XCTAssertEqual(pattern.count, 2)
        XCTAssertEqual(pattern[0].count, 2)
        XCTAssertEqual(pattern[1].count, 2)
        XCTAssertEqual(pattern, expectedPattern)
    }
    
    // MARK: - Size Tests
    
    func testSingleBlock_Size() {
        // Given
        let blockType = BlockType.single
        
        // When
        let size = blockType.size
        
        // Then
        XCTAssertEqual(size.width, 1.0)
        XCTAssertEqual(size.height, 1.0)
    }
    
    func testHorizontalBlock_Size() {
        // Given
        let blockType = BlockType.horizontal
        
        // When
        let size = blockType.size
        
        // Then
        XCTAssertEqual(size.width, 2.0)
        XCTAssertEqual(size.height, 1.0)
    }
    
    func testLShapeBlock_Size() {
        // Given
        let blockType = BlockType.lShape
        
        // When
        let size = blockType.size
        
        // Then
        XCTAssertEqual(size.width, 2.0)
        XCTAssertEqual(size.height, 2.0)
    }
    
    // MARK: - Occupied Positions Tests
    
    func testSingleBlock_OccupiedPositions() {
        // Given
        let blockType = BlockType.single
        
        // When
        let positions = blockType.occupiedPositions
        
        // Then
        XCTAssertEqual(positions.count, 1)
        XCTAssertTrue(positions.contains(CGPoint(x: 0, y: 0)))
    }
    
    func testHorizontalBlock_OccupiedPositions() {
        // Given
        let blockType = BlockType.horizontal
        
        // When
        let positions = blockType.occupiedPositions
        
        // Then
        XCTAssertEqual(positions.count, 2)
        XCTAssertTrue(positions.contains(CGPoint(x: 0, y: 0)))
        XCTAssertTrue(positions.contains(CGPoint(x: 1, y: 0)))
    }
    
    func testLShapeBlock_OccupiedPositions() {
        // Given
        let blockType = BlockType.lShape
        
        // When
        let positions = blockType.occupiedPositions
        
        // Then
        XCTAssertEqual(positions.count, 3)
        XCTAssertTrue(positions.contains(CGPoint(x: 0, y: 0)))
        XCTAssertTrue(positions.contains(CGPoint(x: 0, y: 1)))
        XCTAssertTrue(positions.contains(CGPoint(x: 1, y: 1)))
    }
    
    // MARK: - Cell Count Tests
    
    func testBlockType_CellCounts() {
        // Given/When/Then
        XCTAssertEqual(BlockType.single.cellCount, 1)
        XCTAssertEqual(BlockType.horizontal.cellCount, 2)
        XCTAssertEqual(BlockType.vertical.cellCount, 2)
        XCTAssertEqual(BlockType.lineThree.cellCount, 3)
        XCTAssertEqual(BlockType.square.cellCount, 4)
        XCTAssertEqual(BlockType.lShape.cellCount, 3)
        XCTAssertEqual(BlockType.tShape.cellCount, 4)
        XCTAssertEqual(BlockType.zigZag.cellCount, 4)
        XCTAssertEqual(BlockType.plus.cellCount, 5)
    }
}

// MARK: - BlockPattern Tests

final class BlockPatternTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testBlockPattern_InitializationWithSingleBlock() {
        // Given
        let blockType = BlockType.single
        let color = BlockColor.blue
        
        // When
        let pattern = BlockPattern(type: blockType, color: color)
        
        // Then
        XCTAssertEqual(pattern.type, blockType)
        XCTAssertEqual(pattern.color, color)
        XCTAssertEqual(pattern.cells, blockType.pattern)
        XCTAssertEqual(pattern.size, blockType.size)
    }
    
    func testBlockPattern_InitializationWithLShape() {
        // Given
        let blockType = BlockType.lShape
        let color = BlockColor.orange
        
        // When
        let pattern = BlockPattern(type: blockType, color: color)
        
        // Then
        XCTAssertEqual(pattern.type, blockType)
        XCTAssertEqual(pattern.color, color)
        XCTAssertEqual(pattern.cells, blockType.pattern)
        XCTAssertEqual(pattern.size, blockType.size)
    }
    
    // MARK: - Position Tests
    
    func testBlockPattern_OccupiedPositions() {
        // Given
        let blockType = BlockType.lShape
        let color = BlockColor.orange
        let pattern = BlockPattern(type: blockType, color: color)
        
        // When
        let positions = pattern.occupiedPositions
        
        // Then
        XCTAssertEqual(positions.count, 3)
        XCTAssertEqual(positions, blockType.occupiedPositions)
    }
    
    // MARK: - Grid Fit Tests
    
    func testBlockPattern_CanFitAtOrigin() {
        // Given
        let pattern = BlockPattern(type: .lShape, color: .orange)
        let position = GridPosition(unsafeRow: 0, unsafeColumn: 0)
        
        // When
        let canFit = pattern.canFit(at: position, in: 10)
        
        // Then
        XCTAssertTrue(canFit)
    }
    
    func testBlockPattern_CannotFitNearEdge() {
        // Given
        let pattern = BlockPattern(type: .lShape, color: .orange)
        let position = GridPosition(unsafeRow: 9, unsafeColumn: 9)
        
        // When
        let canFit = pattern.canFit(at: position, in: 10)
        
        // Then
        XCTAssertFalse(canFit)
    }
    
    func testBlockPattern_CanFitNearEdge() {
        // Given
        let pattern = BlockPattern(type: .lShape, color: .orange)
        let position = GridPosition(unsafeRow: 8, unsafeColumn: 8)
        
        // When
        let canFit = pattern.canFit(at: position, in: 10)
        
        // Then
        XCTAssertTrue(canFit)
    }
    
    // MARK: - Grid Position Mapping Tests
    
    func testBlockPattern_GetGridPositions() {
        // Given
        let pattern = BlockPattern(type: .lShape, color: .orange)
        let position = GridPosition(unsafeRow: 2, unsafeColumn: 3)
        
        // When
        let gridPositions = pattern.getGridPositions(placedAt: position)
        
        // Then
        XCTAssertEqual(gridPositions.count, 3)
        
        let expectedPositions = [
            GridPosition(unsafeRow: 2, unsafeColumn: 3), // (0,0) offset
            GridPosition(unsafeRow: 3, unsafeColumn: 3), // (0,1) offset
            GridPosition(unsafeRow: 3, unsafeColumn: 4)  // (1,1) offset
        ]
        
        for expectedPos in expectedPositions {
            XCTAssertTrue(gridPositions.contains(expectedPos))
        }
    }
}

// MARK: - BlockFactory Tests

@MainActor
final class BlockFactoryTests: XCTestCase {
    
    // MARK: - Properties
    
    private var blockFactory: BlockFactory!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        blockFactory = BlockFactory()
    }
    
    override func tearDown() {
        blockFactory = nil
        super.tearDown()
    }
    
    // MARK: - Tray Behaviour

    func testFactoryStartsWithThreeTraySlots() {
        let slots = blockFactory.getTraySlots()
        XCTAssertEqual(slots.count, 3)
        XCTAssertTrue(slots.allSatisfy { $0 != nil })
    }

    func testFactoryProvidesUniqueTypesPerTray() {
        let slots = blockFactory.getTraySlots().compactMap { $0 }
        let uniqueTypes = Set(slots.map { $0.type })
        XCTAssertEqual(uniqueTypes.count, slots.count)
    }

    func testFactoryConsumeBlockKeepsRemainingSlots() {
        let initialSlots = blockFactory.getTraySlots()
        blockFactory.consumeBlock(at: 0)

        let updatedSlots = blockFactory.getTraySlots()
        XCTAssertEqual(updatedSlots.count, initialSlots.count)
        XCTAssertNil(updatedSlots[0])
        XCTAssertTrue(updatedSlots[1...].allSatisfy { $0 != nil })
        XCTAssertTrue(blockFactory.hasAvailableBlocks)
    }

    func testFactoryRefreshesAfterAllConsumed() {
        let firstCycleTypes = Set(blockFactory.getTraySlots().compactMap { $0?.type })

        for index in 0..<3 {
            blockFactory.consumeBlock(at: index)
        }

        let refreshedSlots = blockFactory.getTraySlots()
        XCTAssertTrue(refreshedSlots.allSatisfy { $0 != nil })
        let refreshedTypes = Set(refreshedSlots.compactMap { $0?.type })
        XCTAssertEqual(refreshedTypes.count, 3)
        XCTAssertNotEqual(refreshedTypes, firstCycleTypes)
    }

    func testFactoryGetBlockHandlesInvalidIndex() {
        XCTAssertNil(blockFactory.getBlock(at: -1))
        XCTAssertNil(blockFactory.getBlock(at: 3))
        XCTAssertNil(blockFactory.getBlock(at: 99))
    }

    func testFactoryResetTrayGeneratesNewSet() {
        let originalTypes = Set(blockFactory.getTraySlots().compactMap { $0?.type })
        blockFactory.resetTray()
        let refreshedTypes = Set(blockFactory.getTraySlots().compactMap { $0?.type })

        XCTAssertEqual(refreshedTypes.count, 3)
        XCTAssertNotEqual(originalTypes, refreshedTypes)
    }
}
