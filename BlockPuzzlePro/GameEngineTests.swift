import Testing
@testable import BlockPuzzlePro

@Suite("GameEngine basic behavior")
struct GameEngineTests {

    @Test("New game resets state")
    func newGameResetsState() async throws {
        let engine = GameEngine()
        // Fill one cell
        let pos = try #require(GridPosition(row: 0, column: 0))
        _ = engine.placeBlocks(at: [pos], color: .red)
        // Mutate score artificially
        _ = engine.processCompletedLines()

        engine.startNewGame()

        // All cells empty
        for row in 0..<GameEngine.gridSize {
            for col in 0..<GameEngine.gridSize {
                let p = GridPosition(unsafeRow: row, unsafeColumn: col)
                let cell = engine.cell(at: p)
                #expect(cell?.isEmpty == true)
            }
        }
        #expect(engine.score == 0)
        #expect(engine.isGameActive == true)
    }

    @Test("Place a simple block succeeds")
    func placeSimpleBlock() async throws {
        let engine = GameEngine()
        engine.startNewGame()
        let p = try #require(GridPosition(row: 3, column: 3))
        let ok = engine.placeBlocks(at: [p], color: .blue)
        #expect(ok == true)
        #expect(engine.cell(at: p)?.isOccupied == true)
    }

    @Test("Clears a completed row")
    func clearsCompletedRow() async throws {
        let engine = GameEngine()
        engine.startNewGame()
        let row = 2
        var positions: [GridPosition] = []
        for col in 0..<GameEngine.gridSize {
            positions.append(GridPosition(unsafeRow: row, unsafeColumn: col))
        }
        let ok = engine.placeBlocks(at: positions, color: .green)
        #expect(ok == true)
        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines >= 1)
        #expect(result.rows.contains(row))
        // Row should be empty now
        for col in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
    }

    @Test("Clears a completed column")
    func clearsCompletedColumn() async throws {
        let engine = GameEngine()
        engine.startNewGame()
        let column = 3
        var positions: [GridPosition] = []
        for row in 0..<GameEngine.gridSize {
            positions.append(GridPosition(unsafeRow: row, unsafeColumn: column))
        }
        let ok = engine.placeBlocks(at: positions, color: .blue)
        #expect(ok == true)
        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines >= 1)
        #expect(result.columns.contains(column))
        // Column should be empty now
        for row in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: column)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
    }

    @Test("Clears simultaneous row and column")
    func clearsSimultaneousRowAndColumn() async throws {
        let engine = GameEngine()
        engine.startNewGame()
        let targetRow = 4
        let targetColumn = 5

        // Fill entire row 4
        for col in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: targetRow, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .red)
            #expect(ok == true)
        }

        // Fill entire column 5 (this will overlap with row 4)
        for row in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: targetColumn)
            if engine.cell(at: p)?.isEmpty == true {
                let ok = engine.placeBlocks(at: [p], color: .yellow)
                #expect(ok == true)
            }
        }

        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines == 2)
        #expect(result.rows.contains(targetRow))
        #expect(result.columns.contains(targetColumn))

        // Both row and column should be empty
        for col in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: targetRow, unsafeColumn: col)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
        for row in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: targetColumn)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
    }

    @Test("Multiple rows clear simultaneously")
    func clearsMultipleRows() async throws {
        let engine = GameEngine()
        engine.startNewGame()
        let row1 = 1
        let row2 = 3

        // Fill row 1
        for col in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row1, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .green)
            #expect(ok == true)
        }

        // Fill row 3
        for col in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row2, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .purple)
            #expect(ok == true)
        }

        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines == 2)
        #expect(result.rows.contains(row1))
        #expect(result.rows.contains(row2))

        // Both rows should be empty
        for col in 0..<GameEngine.gridSize {
            let p1 = GridPosition(unsafeRow: row1, unsafeColumn: col)
            let p2 = GridPosition(unsafeRow: row2, unsafeColumn: col)
            #expect(engine.cell(at: p1)?.isEmpty == true)
            #expect(engine.cell(at: p2)?.isEmpty == true)
        }
    }

    @Test("No partial line clears")
    func noPartialLineClears() async throws {
        let engine = GameEngine()
        engine.startNewGame()
        let row = 2

        // Fill 9 out of 10 cells in row (not complete)
        for col in 0..<(GameEngine.gridSize - 1) {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .orange)
            #expect(ok == true)
        }

        let result = engine.processCompletedLines()
        #expect(result.isEmpty == true)
        #expect(result.totalClearedLines == 0)

        // Row should still have blocks (not cleared)
        for col in 0..<(GameEngine.gridSize - 1) {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            #expect(engine.cell(at: p)?.isOccupied == true)
        }
    }

    @Test("Cleared spaces immediately available")
    func clearedSpacesImmediatelyAvailable() async throws {
        let engine = GameEngine()
        engine.startNewGame()
        let row = 5

        // Fill complete row
        var positions: [GridPosition] = []
        for col in 0..<GameEngine.gridSize {
            positions.append(GridPosition(unsafeRow: row, unsafeColumn: col))
        }
        let ok = engine.placeBlocks(at: positions, color: .cyan)
        #expect(ok == true)

        // Clear the row
        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines == 1)

        // Verify all positions are immediately available for placement
        for col in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            #expect(engine.canPlaceAt(position: p) == true)
        }

        // Place new blocks in cleared positions
        let newPositions = [GridPosition(unsafeRow: row, unsafeColumn: 0),
                           GridPosition(unsafeRow: row, unsafeColumn: 5)]
        let placementOk = engine.placeBlocks(at: newPositions, color: .magenta)
        #expect(placementOk == true)
    }

    @Test("Active line clears tracking")
    func activeLineClearsTracking() async throws {
        let engine = GameEngine()
        engine.startNewGame()

        // Initially no active clears
        #expect(engine.activeLineClears.isEmpty == true)

        let row = 7
        var positions: [GridPosition] = []
        for col in 0..<GameEngine.gridSize {
            positions.append(GridPosition(unsafeRow: row, unsafeColumn: col))
        }
        let ok = engine.placeBlocks(at: positions, color: .brown)
        #expect(ok == true)

        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines == 1)

        // Should have active line clears for UI animation
        #expect(engine.activeLineClears.count == 1)
        #expect(engine.activeLineClears.first?.kind == .row(row))

        // Clear active state
        engine.clearActiveLineClears()
        #expect(engine.activeLineClears.isEmpty == true)
    }
}
