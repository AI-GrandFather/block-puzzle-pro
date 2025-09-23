import XCTest
import SwiftUI
@testable import BlockPuzzlePro

// MARK: - BlockTrayView Tests

@MainActor
final class BlockTrayViewTests: XCTestCase {
    
    // MARK: - Properties
    
    private var blockFactory: BlockFactory!
    private var blockSelectedCallbackInvoked: Bool = false
    private var selectedBlockIndex: Int?
    private var selectedBlockPattern: BlockPattern?
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        blockFactory = BlockFactory()
        blockSelectedCallbackInvoked = false
        selectedBlockIndex = nil
        selectedBlockPattern = nil
    }
    
    override func tearDown() {
        blockFactory = nil
        super.tearDown()
    }
    
    // MARK: - Test Helpers
    
    private func createBlockTrayView() -> BlockTrayView {
        return BlockTrayView(
            blockFactory: blockFactory,
            cellSize: 35,
            onBlockSelected: { index, pattern in
                self.blockSelectedCallbackInvoked = true
                self.selectedBlockIndex = index
                self.selectedBlockPattern = pattern
            }
        )
    }
    
    // MARK: - Initialization Tests
    
    func testBlockTrayView_Initialization() {
        // Given/When
        let trayView = createBlockTrayView()
        
        // Then
        // View should initialize without crashing
        XCTAssertNotNil(trayView)
    }
    
    func testBlockTrayView_InitializationWithCustomCellSize() {
        // Given/When
        let customCellSize: CGFloat = 50
        let trayView = BlockTrayView(
            blockFactory: blockFactory,
            cellSize: customCellSize,
            onBlockSelected: { _, _ in }
        )
        
        // Then
        XCTAssertNotNil(trayView)
        XCTAssertEqual(trayView.cellSize, customCellSize)
    }
    
    // MARK: - Block Display Tests
    
    func testBlockTrayView_DisplaysThreeSlots() {
        // Given
        _ = createBlockTrayView()
        let traySlots = blockFactory.getTraySlots()

        // When/Then
        XCTAssertEqual(traySlots.count, 3, "Tray should expose three slots")
        XCTAssertTrue(traySlots.allSatisfy { $0 != nil }, "All slots should be filled on initialization")
    }
    
    // MARK: - Block Selection Simulation Tests
    
    func testBlockTrayView_BlockSelectionCallback() {
        // Given
        let trayView = createBlockTrayView()
        guard let firstBlock = blockFactory.getBlock(at: 0) else {
            XCTFail("Expected a block at index 0")
            return
        }

        // When - Simulate selecting first block
        trayView.onBlockSelected(0, firstBlock)

        // Then
        XCTAssertTrue(blockSelectedCallbackInvoked)
        XCTAssertEqual(selectedBlockIndex, 0)
        XCTAssertEqual(selectedBlockPattern?.type, firstBlock.type)
        XCTAssertEqual(selectedBlockPattern?.color, firstBlock.color)
    }
    
    func testBlockTrayView_MultipleBlockSelections() {
        // Given
        let trayView = createBlockTrayView()
        let availableBlocks = blockFactory.availableBlocks

        // When - Select each block in sequence
        for (index, block) in availableBlocks.enumerated() {
            // Reset callback state
            blockSelectedCallbackInvoked = false
            selectedBlockIndex = nil
            selectedBlockPattern = nil
            
            // Simulate selection
            trayView.onBlockSelected(index, block)
            
            // Then
            XCTAssertTrue(blockSelectedCallbackInvoked, "Callback should be invoked for block \(index)")
            XCTAssertEqual(selectedBlockIndex, index, "Selected index should match for block \(index)")
            XCTAssertEqual(selectedBlockPattern?.type, block.type, "Selected block type should match for block \(index)")
            XCTAssertEqual(selectedBlockPattern?.color, block.color, "Selected block color should match for block \(index)")
        }
    }
    
    // MARK: - Block Regeneration Tests
    
    func testBlockTrayView_BlockRegenerationMaintainsCount() {
        // Given
        let originalSlots = blockFactory.getTraySlots()
        XCTAssertEqual(originalSlots.count, 3)

        blockFactory.consumeBlock(at: 0)
        let midCycleSlots = blockFactory.getTraySlots()
        XCTAssertNil(midCycleSlots[0])
        XCTAssertTrue(midCycleSlots[1...].allSatisfy { $0 != nil })

        blockFactory.consumeBlock(at: 1)
        blockFactory.consumeBlock(at: 2)
        let refreshedSlots = blockFactory.getTraySlots()
        XCTAssertTrue(refreshedSlots.allSatisfy { $0 != nil })
        XCTAssertEqual(refreshedSlots.count, 3)
    }

    func testBlockTrayView_TrayRefreshIntroducesVariety() {
        // Given
        let initialTypes = Set(blockFactory.getTraySlots().compactMap { $0?.type })

        // When - Consume entire tray to force refresh
        for index in 0..<3 {
            blockFactory.consumeBlock(at: index)
        }

        let refreshedTypes = Set(blockFactory.getTraySlots().compactMap { $0?.type })

        // Then
        XCTAssertEqual(refreshedTypes.count, 3)
        XCTAssertNotEqual(initialTypes, refreshedTypes)
    }

    // MARK: - Accessibility Tests

    func testBlockTrayView_BlocksHaveAccessibilityLabels() {
        // Given
        let availableBlocks = blockFactory.availableBlocks

        // When/Then - Verify each block type has accessibility description
        for block in availableBlocks {
            let accessibilityDescription = block.color.accessibilityDescription
            let blockTypeDescription = block.type.displayName
            
            XCTAssertFalse(accessibilityDescription.isEmpty, "Block should have accessibility description")
            XCTAssertFalse(blockTypeDescription.isEmpty, "Block should have display name")
            
            XCTAssertFalse(blockTypeDescription.isEmpty)
        }
    }
    
    // MARK: - Cell Size Calculation Tests
    
    func testBlockTrayView_CellSizeCalculation() {
        // Given - Different cell sizes
        let cellSizes: [CGFloat] = [25, 30, 35, 40, 50]
        
        // When/Then - Each should create valid tray views
        for cellSize in cellSizes {
            let trayView = BlockTrayView(
                blockFactory: blockFactory,
                cellSize: cellSize,
                onBlockSelected: { _, _ in }
            )
            
            XCTAssertNotNil(trayView, "Should create valid tray view with cell size \(cellSize)")
            XCTAssertEqual(trayView.cellSize, cellSize, "Cell size should match")
        }
    }
    
    // MARK: - Block Pattern Validation Tests
    
    func testBlockTrayView_BlockPatternsAreCorrect() {
        // Given
        let availableBlocks = blockFactory.getAvailableBlocks()
        
        // When/Then - Verify each block has correct pattern
        for block in availableBlocks {
            switch block.type {
            case .single:
                XCTAssertEqual(block.cells, [[true]], "Single block should have 1x1 pattern")
                XCTAssertEqual(block.cellCount, 1, "Single block should have 1 cell")
                
            case .horizontal:
                XCTAssertEqual(block.cells, [[true, true]], "Horizontal block should have 1x2 pattern")
                XCTAssertEqual(block.cellCount, 2, "Horizontal block should have 2 cells")
                
            case .lShape:
                let expectedPattern = [
                    [true, false],
                    [true, true]
                ]
                XCTAssertEqual(block.cells, expectedPattern, "L-Shape block should have L pattern")
                XCTAssertEqual(block.cellCount, 3, "L-Shape block should have 3 cells")
            }
        }
    }
}

// MARK: - TrayContainerView Tests

@MainActor
final class TrayContainerViewTests: XCTestCase {
    
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
    
    func testTrayContainerView_Initialization() {
        // Given
        let screenSize = CGSize(width: 375, height: 812) // iPhone X size
        
        // When
        let containerView = TrayContainerView(
            blockFactory: blockFactory,
            screenSize: screenSize,
            onBlockSelected: { _, _ in }
        )
        
        // Then
        XCTAssertNotNil(containerView)
    }
    
    // MARK: - Screen Size Adaptation Tests
    
    func testTrayContainerView_AdaptsToScreenSizes() {
        // Given - Different screen sizes
        let screenSizes = [
            CGSize(width: 320, height: 568), // iPhone SE
            CGSize(width: 375, height: 667), // iPhone 6/7/8
            CGSize(width: 375, height: 812), // iPhone X/11 Pro
            CGSize(width: 414, height: 896), // iPhone 11/XR
            CGSize(width: 428, height: 926), // iPhone 12/13 Pro Max
        ]
        
        // When/Then - Should create valid containers for all sizes
        for screenSize in screenSizes {
            let containerView = TrayContainerView(
                blockFactory: blockFactory,
                screenSize: screenSize,
                onBlockSelected: { _, _ in }
            )
            
            XCTAssertNotNil(containerView, "Should create valid container for screen size \(screenSize)")
        }
    }
    
    // MARK: - Cell Size Calculation Tests
    
    func testTrayContainerView_CellSizeCalculation() {
        // Given
        let smallScreen = CGSize(width: 320, height: 568)
        let largeScreen = CGSize(width: 428, height: 926)
        
        // When
        let smallContainer = TrayContainerView(
            blockFactory: blockFactory,
            screenSize: smallScreen,
            onBlockSelected: { _, _ in }
        )
        
        let largeContainer = TrayContainerView(
            blockFactory: blockFactory,
            screenSize: largeScreen,
            onBlockSelected: { _, _ in }
        )
        
        // Then
        XCTAssertNotNil(smallContainer)
        XCTAssertNotNil(largeContainer)
        
        // Note: We can't directly test the private calculateOptimalCellSize method,
        // but we can verify the containers initialize properly with different screen sizes
    }
}
