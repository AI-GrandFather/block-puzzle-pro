import XCTest
import SpriteKit
@testable import BlockPuzzlePro

// MARK: - GridCell Tests

final class GridCellTests: XCTestCase {
    
    // MARK: - State Tests
    
    func testGridCell_EmptyState() {
        // Given
        let cell = GridCell.empty
        
        // When/Then
        XCTAssertTrue(cell.isEmpty)
        XCTAssertFalse(cell.isOccupied)
        XCTAssertFalse(cell.isPreview)
        XCTAssertNil(cell.color)
    }
    
    func testGridCell_OccupiedState() {
        // Given
        let color = BlockColor.blue
        let cell = GridCell.occupied(color: color)
        
        // When/Then
        XCTAssertFalse(cell.isEmpty)
        XCTAssertTrue(cell.isOccupied)
        XCTAssertFalse(cell.isPreview)
        XCTAssertEqual(cell.color, color)
    }
    
    func testGridCell_PreviewState() {
        // Given
        let color = BlockColor.orange
        let cell = GridCell.preview(color: color)
        
        // When/Then
        XCTAssertFalse(cell.isEmpty)
        XCTAssertFalse(cell.isOccupied)
        XCTAssertTrue(cell.isPreview)
        XCTAssertEqual(cell.color, color)
    }
    
    // MARK: - Equality Tests
    
    func testGridCell_Equality() {
        // Given
        let empty1 = GridCell.empty
        let empty2 = GridCell.empty
        let occupied1 = GridCell.occupied(color: .blue)
        let occupied2 = GridCell.occupied(color: .blue)
        let occupied3 = GridCell.occupied(color: .red)
        let preview1 = GridCell.preview(color: .green)
        let preview2 = GridCell.preview(color: .green)
        
        // When/Then
        XCTAssertEqual(empty1, empty2)
        XCTAssertEqual(occupied1, occupied2)
        XCTAssertEqual(preview1, preview2)
        
        XCTAssertNotEqual(empty1, occupied1)
        XCTAssertNotEqual(occupied1, occupied3)
        XCTAssertNotEqual(occupied1, preview1)
    }
}

// MARK: - BlockColor Tests

final class BlockColorTests: XCTestCase {
    
    // MARK: - AllCases Tests
    
    func testBlockColor_AllCasesExist() {
        // Given/When
        let allColors = BlockColor.allCases
        
        // Then
        XCTAssertEqual(allColors.count, 8)
        XCTAssertTrue(allColors.contains(.red))
        XCTAssertTrue(allColors.contains(.blue))
        XCTAssertTrue(allColors.contains(.green))
        XCTAssertTrue(allColors.contains(.yellow))
        XCTAssertTrue(allColors.contains(.purple))
        XCTAssertTrue(allColors.contains(.orange))
        XCTAssertTrue(allColors.contains(.cyan))
        XCTAssertTrue(allColors.contains(.pink))
    }
    
    // MARK: - SKColor Tests
    
    func testBlockColor_SKColorValues() {
        // Given/When/Then
        XCTAssertNotNil(BlockColor.red.skColor)
        XCTAssertNotNil(BlockColor.blue.skColor)
        XCTAssertNotNil(BlockColor.green.skColor)
        XCTAssertNotNil(BlockColor.yellow.skColor)
        XCTAssertNotNil(BlockColor.purple.skColor)
        XCTAssertNotNil(BlockColor.orange.skColor)
        XCTAssertNotNil(BlockColor.cyan.skColor)
        XCTAssertNotNil(BlockColor.pink.skColor)
        
        // Verify colors are distinct (at least different in some component)
        let redColor = BlockColor.red.skColor
        let blueColor = BlockColor.blue.skColor
        XCTAssertNotEqual(redColor, blueColor)
    }
    
    func testBlockColor_PreviewColorHasReducedAlpha() {
        // Given
        let color = BlockColor.blue
        
        // When
        let originalColor = color.skColor
        let previewColor = color.previewColor
        
        // Then
        // Preview color should have reduced alpha matching production constant
        let originalComponents = originalColor.cgColor.components ?? []
        let previewComponents = previewColor.cgColor.components ?? []
        
        if originalComponents.count >= 4 && previewComponents.count >= 4 {
            let originalAlpha = originalComponents[3]
            let previewAlpha = previewComponents[3]
            XCTAssertEqual(previewAlpha, 0.2, accuracy: 0.01)
            XCTAssertGreaterThan(originalAlpha, previewAlpha)
        }
    }
    
    // MARK: - High Contrast Tests
    
    func testBlockColor_HighContrastMapping() {
        // Given/When/Then
        XCTAssertEqual(BlockColor.red.highContrastColor, SKColor.systemRed)
        XCTAssertEqual(BlockColor.orange.highContrastColor, SKColor.systemRed)
        XCTAssertEqual(BlockColor.pink.highContrastColor, SKColor.systemRed)
        
        XCTAssertEqual(BlockColor.blue.highContrastColor, SKColor.systemBlue)
        XCTAssertEqual(BlockColor.cyan.highContrastColor, SKColor.systemBlue)
        
        XCTAssertEqual(BlockColor.green.highContrastColor, SKColor.systemGreen)
        XCTAssertEqual(BlockColor.yellow.highContrastColor, SKColor.systemYellow)
        XCTAssertEqual(BlockColor.purple.highContrastColor, SKColor.systemPurple)
    }
    
    // MARK: - Accessibility Pattern Tests
    
    func testBlockColor_AccessibilityPatterns() {
        // Given/When/Then
        XCTAssertEqual(BlockColor.red.accessibilityPattern, "solid")
        XCTAssertEqual(BlockColor.blue.accessibilityPattern, "dots")
        XCTAssertEqual(BlockColor.green.accessibilityPattern, "stripes")
        XCTAssertEqual(BlockColor.yellow.accessibilityPattern, "grid")
        XCTAssertEqual(BlockColor.purple.accessibilityPattern, "diagonal")
        XCTAssertEqual(BlockColor.orange.accessibilityPattern, "cross")
        XCTAssertEqual(BlockColor.cyan.accessibilityPattern, "waves")
        XCTAssertEqual(BlockColor.pink.accessibilityPattern, "checker")
        
        // Verify all patterns are unique
        let patterns = BlockColor.allCases.map { $0.accessibilityPattern }
        let uniquePatterns = Set(patterns)
        XCTAssertEqual(patterns.count, uniquePatterns.count, "All accessibility patterns should be unique")
    }
    
    // MARK: - Accessibility Description Tests
    
    func testBlockColor_AccessibilityDescriptions() {
        // Given/When/Then
        XCTAssertEqual(BlockColor.red.accessibilityDescription, "Red block")
        XCTAssertEqual(BlockColor.blue.accessibilityDescription, "Blue block")
        XCTAssertEqual(BlockColor.green.accessibilityDescription, "Green block")
        XCTAssertEqual(BlockColor.yellow.accessibilityDescription, "Yellow block")
        XCTAssertEqual(BlockColor.purple.accessibilityDescription, "Purple block")
        XCTAssertEqual(BlockColor.orange.accessibilityDescription, "Orange block")
        XCTAssertEqual(BlockColor.cyan.accessibilityDescription, "Cyan block")
        XCTAssertEqual(BlockColor.pink.accessibilityDescription, "Pink block")
        
        // Verify all descriptions are unique and non-empty
        let descriptions = BlockColor.allCases.map { $0.accessibilityDescription }
        let uniqueDescriptions = Set(descriptions)
        XCTAssertEqual(descriptions.count, uniqueDescriptions.count, "All accessibility descriptions should be unique")
        
        for description in descriptions {
            XCTAssertFalse(description.isEmpty, "No accessibility description should be empty")
        }
    }
}

// MARK: - GridPosition Tests

final class GridPositionTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testGridPosition_ValidInitialization() {
        // Given/When
        let position1 = GridPosition(row: 0, column: 0, gridSize: 10)
        let position2 = GridPosition(row: 5, column: 7, gridSize: 10)
        let position3 = GridPosition(row: 9, column: 9, gridSize: 10)
        
        // Then
        XCTAssertNotNil(position1)
        XCTAssertNotNil(position2)
        XCTAssertNotNil(position3)
        
        XCTAssertEqual(position1?.row, 0)
        XCTAssertEqual(position1?.column, 0)
        XCTAssertEqual(position2?.row, 5)
        XCTAssertEqual(position2?.column, 7)
        XCTAssertEqual(position3?.row, 9)
        XCTAssertEqual(position3?.column, 9)
    }
    
    func testGridPosition_InvalidInitialization() {
        // Given/When
        let invalidPosition1 = GridPosition(row: -1, column: 0, gridSize: 10)
        let invalidPosition2 = GridPosition(row: 0, column: -1, gridSize: 10)
        let invalidPosition3 = GridPosition(row: 10, column: 0, gridSize: 10)
        let invalidPosition4 = GridPosition(row: 0, column: 10, gridSize: 10)
        let invalidPosition5 = GridPosition(row: 15, column: 15, gridSize: 10)
        
        // Then
        XCTAssertNil(invalidPosition1)
        XCTAssertNil(invalidPosition2)
        XCTAssertNil(invalidPosition3)
        XCTAssertNil(invalidPosition4)
        XCTAssertNil(invalidPosition5)
    }
    
    // MARK: - Unsafe Initialization Tests
    
    func testGridPosition_UnsafeInitialization() {
        // Given/When
        let position1 = GridPosition(unsafeRow: -5, unsafeColumn: -3)
        let position2 = GridPosition(unsafeRow: 15, unsafeColumn: 20)
        
        // Then
        XCTAssertEqual(position1.row, -5)
        XCTAssertEqual(position1.column, -3)
        XCTAssertEqual(position2.row, 15)
        XCTAssertEqual(position2.column, 20)
    }

    
    // MARK: - Equality and Hashable Tests
    
    func testGridPosition_Equality() {
        // Given
        let position1 = GridPosition(unsafeRow: 3, unsafeColumn: 5)
        let position2 = GridPosition(unsafeRow: 3, unsafeColumn: 5)
        let position3 = GridPosition(unsafeRow: 3, unsafeColumn: 4)
        let position4 = GridPosition(unsafeRow: 2, unsafeColumn: 5)
        
        // When/Then
        XCTAssertEqual(position1, position2)
        XCTAssertNotEqual(position1, position3)
        XCTAssertNotEqual(position1, position4)
        XCTAssertNotEqual(position3, position4)
    }
    
    func testGridPosition_Hashable() {
        // Given
        let position1 = GridPosition(unsafeRow: 3, unsafeColumn: 5)
        let position2 = GridPosition(unsafeRow: 3, unsafeColumn: 5)
        let position3 = GridPosition(unsafeRow: 4, unsafeColumn: 5)
        
        // When
        let set = Set([position1, position2, position3])
        
        // Then
        XCTAssertEqual(set.count, 2) // position1 and position2 should be treated as same
        XCTAssertTrue(set.contains(position1))
        XCTAssertTrue(set.contains(position2))
        XCTAssertTrue(set.contains(position3))
    }
}
