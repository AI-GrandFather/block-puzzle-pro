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
        XCTAssertEqual(BlockType.lShape.cellCount, 3)
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
    
    // MARK: - Initialization Tests
    
    func testBlockFactory_InitialBlocksGenerated() {
        // Given/When (factory initialized in setUp)
        let availableBlocks = blockFactory.getAvailableBlocks()
        
        // Then
        XCTAssertEqual(availableBlocks.count, 3)
    }
    
    func testBlockFactory_InitialBlockTypes() {
        // Given/When
        let availableBlocks = blockFactory.getAvailableBlocks()
        
        // Then
        let blockTypes = availableBlocks.map { $0.type }
        XCTAssertTrue(blockTypes.contains(.lShape))
        XCTAssertTrue(blockTypes.contains(.single))
        XCTAssertTrue(blockTypes.contains(.horizontal))
    }
    
    func testBlockFactory_InitialBlockColors() {
        // Given/When
        let availableBlocks = blockFactory.getAvailableBlocks()
        
        // Then
        let lShapeBlock = availableBlocks.first { $0.type == .lShape }
        let singleBlock = availableBlocks.first { $0.type == .single }
        let horizontalBlock = availableBlocks.first { $0.type == .horizontal }
        
        XCTAssertEqual(lShapeBlock?.color, .orange)
        XCTAssertEqual(singleBlock?.color, .blue)
        XCTAssertEqual(horizontalBlock?.color, .green)
    }
    
    // MARK: - Block Access Tests
    
    func testBlockFactory_HasAvailableBlocks() {
        // Given/When
        let hasBlocks = blockFactory.hasAvailableBlocks
        
        // Then
        XCTAssertTrue(hasBlocks)
    }
    
    func testBlockFactory_GetBlockByIndex() {
        // Given
        let availableBlocks = blockFactory.getAvailableBlocks()
        
        // When
        let firstBlock = blockFactory.getBlock(at: 0)
        let secondBlock = blockFactory.getBlock(at: 1)
        let thirdBlock = blockFactory.getBlock(at: 2)
        
        // Then
        XCTAssertNotNil(firstBlock)
        XCTAssertNotNil(secondBlock)
        XCTAssertNotNil(thirdBlock)
        XCTAssertEqual(firstBlock?.type, availableBlocks[0].type)
        XCTAssertEqual(secondBlock?.type, availableBlocks[1].type)
        XCTAssertEqual(thirdBlock?.type, availableBlocks[2].type)
    }
    
    func testBlockFactory_GetBlockByInvalidIndex() {
        // Given/When
        let invalidBlock1 = blockFactory.getBlock(at: -1)
        let invalidBlock2 = blockFactory.getBlock(at: 3)
        
        // Then
        XCTAssertNil(invalidBlock1)
        XCTAssertNil(invalidBlock2)
    }
    
    // MARK: - Block Regeneration Tests
    
    func testBlockFactory_RegenerateBlock() {
        // Given
        let originalBlocks = blockFactory.getAvailableBlocks()
        let originalFirstBlock = originalBlocks[0]
        
        // When
        blockFactory.regenerateBlock(at: 0)
        let newBlocks = blockFactory.getAvailableBlocks()
        let newFirstBlock = newBlocks[0]
        
        // Then
        XCTAssertEqual(newBlocks.count, 3)
        XCTAssertEqual(newFirstBlock.type, originalFirstBlock.type)
        XCTAssertEqual(newFirstBlock.color, originalFirstBlock.color)
    }
    
    func testBlockFactory_RegenerateBlockInvalidIndex() {
        // Given
        let originalBlocks = blockFactory.getAvailableBlocks()
        
        // When
        blockFactory.regenerateBlock(at: -1)
        blockFactory.regenerateBlock(at: 3)
        let newBlocks = blockFactory.getAvailableBlocks()
        
        // Then - blocks should remain unchanged
        XCTAssertEqual(newBlocks.count, originalBlocks.count)
        for (index, block) in newBlocks.enumerated() {
            XCTAssertEqual(block.type, originalBlocks[index].type)
            XCTAssertEqual(block.color, originalBlocks[index].color)
        }
    }
    
    func testBlockFactory_RegenerateAllBlocks() {
        // Given
        let originalBlocks = blockFactory.getAvailableBlocks()
        
        // When
        blockFactory.regenerateAllBlocks()
        let newBlocks = blockFactory.getAvailableBlocks()
        
        // Then
        XCTAssertEqual(newBlocks.count, 3)
        
        // Verify types and colors are preserved
        let newBlockTypes = newBlocks.map { $0.type }
        let originalBlockTypes = originalBlocks.map { $0.type }
        
        for originalType in originalBlockTypes {
            XCTAssertTrue(newBlockTypes.contains(originalType))
        }
    }
}