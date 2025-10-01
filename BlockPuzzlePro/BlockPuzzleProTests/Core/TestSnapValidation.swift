// FILE: TestSnapValidation.swift
import XCTest
import SpriteKit
@testable import BlockPuzzlePro

final class SnapValidationTests: XCTestCase {
    var forecastOverlay: ForecastOverlay!
    var testGridBounds: CGRect!
    let testCellSize: CGFloat = 32
    let testGridSpacing: CGFloat = 2

    override func setUp() {
        super.setUp()
        testGridBounds = CGRect(x: 100, y: 100, width: 340, height: 340) // 10x10 grid with spacing
        forecastOverlay = ForecastOverlay(
            gridBounds: testGridBounds,
            cellSize: testCellSize,
            gridSpacing: testGridSpacing
        )
    }

    override func tearDown() {
        forecastOverlay = nil
        testGridBounds = nil
        super.tearDown()
    }

    func testGridBoundsEnforcement() {
        let block = Block(type: .square, color: .red) // 2x2 block

        // Test block that would partially extend outside grid
        let invalidPosition = Grid.Point(x: 9, y: 9) // Would place 2x2 block at edges
        let clippedCells = getClippedCellsForBlock(block, at: invalidPosition)

        // Should only contain cells within grid bounds
        for cell in clippedCells {
            XCTAssertTrue(cell.x >= 0 && cell.x < GameConfig.gridSize)
            XCTAssertTrue(cell.y >= 0 && cell.y < GameConfig.gridSize)
        }

        // Should have fewer cells than the full block pattern
        XCTAssertLessThan(clippedCells.count, block.points.count)
    }

    func testCompletelyOutsideBounds() {
        let block = Block(type: .single, color: .blue)

        // Test block completely outside grid
        let outsidePosition = Grid.Point(x: 15, y: 15)
        let clippedCells = getClippedCellsForBlock(block, at: outsidePosition)

        XCTAssertEqual(clippedCells.count, 0)
    }

    func testCompletelyInsideBounds() {
        let block = Block(type: .square, color: .green) // 2x2 block

        // Test block completely inside grid
        let insidePosition = Grid.Point(x: 4, y: 4)
        let clippedCells = getClippedCellsForBlock(block, at: insidePosition)

        XCTAssertEqual(clippedCells.count, block.points.count)

        // All cells should be within bounds
        for cell in clippedCells {
            XCTAssertTrue(cell.x >= 0 && cell.x < GameConfig.gridSize)
            XCTAssertTrue(cell.y >= 0 && cell.y < GameConfig.gridSize)
        }
    }

    func testPartiallyOutsideBounds() {
        let block = Block(type: .lineThree, color: .yellow) // 1x3 horizontal block

        // Test block partially outside - starts at column 8, extends to column 10
        let partiallyOutsidePosition = Grid.Point(x: 8, y: 5)
        let clippedCells = getClippedCellsForBlock(block, at: partiallyOutsidePosition)

        // Should only contain 2 cells (columns 8 and 9, not 10)
        XCTAssertEqual(clippedCells.count, 2)

        for cell in clippedCells {
            XCTAssertTrue(cell.x >= 0 && cell.x < GameConfig.gridSize)
            XCTAssertTrue(cell.y >= 0 && cell.y < GameConfig.gridSize)
        }
    }

    func testComplexShapeClipping() {
        let block = Block(type: .lShape, color: .purple)

        // Test L-shape at edge
        let edgePosition = Grid.Point(x: 9, y: 9)
        let clippedCells = getClippedCellsForBlock(block, at: edgePosition)

        // Should only contain cells within bounds
        for cell in clippedCells {
            XCTAssertTrue(cell.x >= 0 && cell.x < GameConfig.gridSize)
            XCTAssertTrue(cell.y >= 0 && cell.y < GameConfig.gridSize)
        }

        // Should have fewer cells than the full L-shape
        XCTAssertLessThan(clippedCells.count, block.points.count)
    }

    func testNegativePositions() {
        let block = Block(type: .single, color: .red)

        // Test negative position
        let negativePosition = Grid.Point(x: -1, y: -1)
        let clippedCells = getClippedCellsForBlock(block, at: negativePosition)

        XCTAssertEqual(clippedCells.count, 0)
    }

    func testMixedValidInvalidCells() {
        let block = Block(type: .tShape, color: .orange) // T-shape: 3 wide, 2 tall

        // Position T-shape so some cells are valid, some invalid
        let mixedPosition = Grid.Point(x: 8, y: -1) // Top row outside, bottom row partially inside
        let clippedCells = getClippedCellsForBlock(block, at: mixedPosition)

        // Should only contain valid cells
        for cell in clippedCells {
            XCTAssertTrue(cell.x >= 0 && cell.x < GameConfig.gridSize)
            XCTAssertTrue(cell.y >= 0 && cell.y < GameConfig.gridSize)
        }

        XCTAssertGreaterThan(clippedCells.count, 0) // Some cells should be valid
        XCTAssertLessThan(clippedCells.count, block.points.count) // Some cells should be clipped
    }

    func testPerformanceOfClipping() {
        let blocks = [
            Block(type: .squareThree, color: .red),
            Block(type: .plus, color: .blue),
            Block(type: .zigZag, color: .green)
        ]

        let startTime = CFAbsoluteTimeGetCurrent()

        // Test 1000 clipping operations
        for _ in 0..<1000 {
            for block in blocks {
                let randomPosition = Grid.Point(
                    x: Int.random(in: -2...GameConfig.gridSize + 2),
                    y: Int.random(in: -2...GameConfig.gridSize + 2)
                )
                _ = getClippedCellsForBlock(block, at: randomPosition)
            }
        }

        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(elapsedTime, 0.5) // Should complete 3000 clipping ops in under 500ms
    }

    // Helper method to simulate the grid clipping logic
    private func getClippedCellsForBlock(_ block: Block, at position: Grid.Point) -> [Grid.Point] {
        let placedPoints = block.placedPoints(at: position)
        return placedPoints.filter { point in
            point.x >= 0 && point.x < GameConfig.gridSize &&
            point.y >= 0 && point.y < GameConfig.gridSize
        }
    }
}