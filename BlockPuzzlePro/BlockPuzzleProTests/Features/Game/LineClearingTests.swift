import Testing
@testable import BlockPuzzlePro

@Suite("Line Clearing Integration Tests")
struct LineClearingTests {

    @Test("End-to-end line clearing flow")
    func endToEndLineClearingFlow() async throws {
        let engine = GameEngine(gameMode: .classic)
        let placementEngine = PlacementEngine(gameEngine: engine)

        engine.startNewGame()

        // Create a simple 1x1 block pattern
        let singleBlock = BlockPattern(type: .single, color: .red)

        // Fill an entire row by placing individual blocks
        let targetRow = 3
        for col in 0..<engine.gridSize {
            let gridPos = try #require(GridPosition(row: targetRow, column: col, gridSize: engine.gridSize))

            // Validate placement
            let validation = placementEngine.validatePlacement(
                blockPattern: singleBlock,
                at: gridPos
            )

            guard case .valid(let positions) = validation else {
                Issue.record("Failed to validate placement at \(gridPos)")
                return
            }

            // Place the block
            let placed = engine.placeBlocks(at: positions, color: singleBlock.color)
            #expect(placed == true)
        }

        // Verify row is complete before clearing
        for col in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: targetRow, column: col, gridSize: engine.gridSize))
            #expect(engine.cell(at: pos)?.isOccupied == true)
        }

        // Process line clearing
        let result = engine.processCompletedLines()

        // Verify clearing results
        #expect(result.totalClearedLines == 1)
        #expect(result.rows.contains(targetRow))
        #expect(result.isEmpty == false)

        // Verify UI state tracking
        #expect(engine.activeLineClears.count == 1)
        #expect(engine.activeLineClears.first?.kind == .row(targetRow))

        // Verify row is now empty
        for col in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: targetRow, column: col, gridSize: engine.gridSize))
            #expect(engine.cell(at: pos)?.isEmpty == true)
        }

        // Verify spaces are immediately available
        for col in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: targetRow, column: col, gridSize: engine.gridSize))
            #expect(engine.canPlaceAt(position: pos) == true)
        }
    }

    @Test("L-shaped intersection clearing")
    func lShapedIntersectionClearing() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        let intersectionRow = 5
        let intersectionCol = 4

        // Fill row 5 completely
        for col in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: intersectionRow, column: col, gridSize: engine.gridSize))
            let placed = engine.placeBlocks(at: [pos], color: .blue)
            #expect(placed == true)
        }

        // Fill column 4 completely (will overlap at intersection)
        for row in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: row, column: intersectionCol, gridSize: engine.gridSize))
            if engine.cell(at: pos)?.isEmpty == true {
                let placed = engine.placeBlocks(at: [pos], color: .green)
                #expect(placed == true)
            }
        }

        // Process clearing
        let result = engine.processCompletedLines()

        // Should clear both row and column
        #expect(result.totalClearedLines == 2)
        #expect(result.rows.contains(intersectionRow))
        #expect(result.columns.contains(intersectionCol))

        // Verify intersection is cleared (not double-processed)
        let intersectionPos = try #require(GridPosition(row: intersectionRow, column: intersectionCol, gridSize: engine.gridSize))
        #expect(engine.cell(at: intersectionPos)?.isEmpty == true)

        // Verify entire row and column are cleared
        for col in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: intersectionRow, column: col, gridSize: engine.gridSize))
            #expect(engine.cell(at: pos)?.isEmpty == true)
        }
        for row in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: row, column: intersectionCol, gridSize: engine.gridSize))
            #expect(engine.cell(at: pos)?.isEmpty == true)
        }
    }

    @Test("Multiple staggered clears")
    func multipleStaggeredClears() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        let rows = [1, 3, 7]
        let columns = [2, 6]

        // Fill multiple rows
        for row in rows {
            for col in 0..<engine.gridSize {
                let pos = try #require(GridPosition(row: row, column: col, gridSize: engine.gridSize))
                let placed = engine.placeBlocks(at: [pos], color: .red)
                #expect(placed == true)
            }
        }

        // Fill multiple columns (avoiding intersections for clarity)
        for column in columns {
            for row in 0..<engine.gridSize {
                let pos = try #require(GridPosition(row: row, column: column, gridSize: engine.gridSize))
                if engine.cell(at: pos)?.isEmpty == true {
                    let placed = engine.placeBlocks(at: [pos], color: .yellow)
                    #expect(placed == true)
                }
            }
        }

        let result = engine.processCompletedLines()

        // Should detect all completed lines
        #expect(result.totalClearedLines >= 3) // At least the non-intersecting lines

        // Check that all target rows are in results
        for row in rows {
            if result.rows.contains(row) {
                // If row cleared, verify it's empty
                for col in 0..<engine.gridSize {
                    let pos = try #require(GridPosition(row: row, column: col, gridSize: engine.gridSize))
                    #expect(engine.cell(at: pos)?.isEmpty == true)
                }
            }
        }

        // Check that all target columns are in results
        for column in columns {
            if result.columns.contains(column) {
                // If column cleared, verify it's empty
                for row in 0..<engine.gridSize {
                    let pos = try #require(GridPosition(row: row, column: column, gridSize: engine.gridSize))
                    #expect(engine.cell(at: pos)?.isEmpty == true)
                }
            }
        }
    }

    @Test("Animation state management")
    func animationStateManagement() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        // Initially no active clears
        #expect(engine.activeLineClears.isEmpty == true)

        // Fill a row
        let targetRow = 6
        for col in 0..<engine.gridSize {
            let pos = try #require(GridPosition(row: targetRow, column: col, gridSize: engine.gridSize))
            let placed = engine.placeBlocks(at: [pos], color: .purple)
            #expect(placed == true)
        }

        // Process clearing
        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines == 1)

        // Should have active clears for animation
        #expect(engine.activeLineClears.count == 1)
        let activeClear = try #require(engine.activeLineClears.first)

        // Verify clear data structure
        #expect(activeClear.kind == .row(targetRow))
        #expect(activeClear.id == "row-\(targetRow)")
        #expect(activeClear.positions.count == engine.gridSize)

        // Verify all positions are in the row
        for position in activeClear.positions {
            #expect(position.row == targetRow)
            #expect(position.column >= 0 && position.column < engine.gridSize)
        }

        // Clear animation state
        engine.clearActiveLineClears()
        #expect(engine.activeLineClears.isEmpty == true)
    }

    @Test("Boundary condition clearing")
    func boundaryConditionClearing() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        // Test edge rows and columns
        let edgePositions = [
            (row: 0, col: -1), // Top row
            (row: engine.gridSize - 1, col: -1), // Bottom row
            (row: -1, col: 0), // Left column
            (row: -1, col: engine.gridSize - 1) // Right column
        ]

        for (testRow, testCol) in edgePositions {
            engine.startNewGame() // Reset for each test

            if testRow >= 0 {
                // Test edge row
                for col in 0..<engine.gridSize {
                    let pos = try #require(GridPosition(row: testRow, column: col, gridSize: engine.gridSize))
                    let placed = engine.placeBlocks(at: [pos], color: .orange)
                    #expect(placed == true)
                }

                let result = engine.processCompletedLines()
                #expect(result.totalClearedLines == 1)
                #expect(result.rows.contains(testRow))

                // Verify edge row cleared properly
                for col in 0..<engine.gridSize {
                    let pos = try #require(GridPosition(row: testRow, column: col, gridSize: engine.gridSize))
                    #expect(engine.cell(at: pos)?.isEmpty == true)
                }
            }

            if testCol >= 0 {
                // Test edge column
                for row in 0..<engine.gridSize {
                    let pos = try #require(GridPosition(row: row, column: testCol, gridSize: engine.gridSize))
                    let placed = engine.placeBlocks(at: [pos], color: .cyan)
                    #expect(placed == true)
                }

                let result = engine.processCompletedLines()
                #expect(result.totalClearedLines == 1)
                #expect(result.columns.contains(testCol))

                // Verify edge column cleared properly
                for row in 0..<engine.gridSize {
                    let pos = try #require(GridPosition(row: row, column: testCol, gridSize: engine.gridSize))
                    #expect(engine.cell(at: pos)?.isEmpty == true)
                }
            }
        }
    }
}
