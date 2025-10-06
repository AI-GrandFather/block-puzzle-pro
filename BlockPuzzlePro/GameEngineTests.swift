import Testing
@testable import BlockPuzzlePro

@Suite("GameEngine basic behavior")
struct GameEngineTests {

    @Test("New game resets state")
    func newGameResetsState() async throws {
        let engine = GameEngine(gameMode: .classic)
        // Fill one cell
        let pos = try #require(GridPosition(row: 0, column: 0, gridSize: engine.gridSize))
        _ = engine.placeBlocks(at: [pos], color: .red)
        // Mutate score artificially
        _ = engine.processCompletedLines()

        engine.startNewGame()

        // All cells empty
        for row in 0..<engine.gridSize {
            for col in 0..<engine.gridSize {
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
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()
        let p = try #require(GridPosition(row: 3, column: 3, gridSize: engine.gridSize))
        let ok = engine.placeBlocks(at: [p], color: .blue)
        #expect(ok == true)
        #expect(engine.cell(at: p)?.isOccupied == true)
    }

    @Test("Clears a completed row")
    func clearsCompletedRow() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()
        let row = 2
        var positions: [GridPosition] = []
        for col in 0..<engine.gridSize {
            positions.append(GridPosition(unsafeRow: row, unsafeColumn: col))
        }
        let ok = engine.placeBlocks(at: positions, color: .green)
        #expect(ok == true)
        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines >= 1)
        #expect(result.rows.contains(row))
        // Row should be empty now
        for col in 0..<engine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
    }

    @Test("Clears a completed column")
    func clearsCompletedColumn() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()
        let column = 3
        var positions: [GridPosition] = []
        for row in 0..<engine.gridSize {
            positions.append(GridPosition(unsafeRow: row, unsafeColumn: column))
        }
        let ok = engine.placeBlocks(at: positions, color: .blue)
        #expect(ok == true)
        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines >= 1)
        #expect(result.columns.contains(column))
        // Column should be empty now
        for row in 0..<engine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: column)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
    }

    @Test("Clears simultaneous row and column")
    func clearsSimultaneousRowAndColumn() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()
        let targetRow = 4
        let targetColumn = 5

        // Fill entire row 4
        for col in 0..<engine.gridSize {
            let p = GridPosition(unsafeRow: targetRow, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .red)
            #expect(ok == true)
        }

        // Fill entire column 5 (this will overlap with row 4)
        for row in 0..<engine.gridSize {
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
        for col in 0..<engine.gridSize {
            let p = GridPosition(unsafeRow: targetRow, unsafeColumn: col)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
        for row in 0..<engine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: targetColumn)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
    }

    @Test("Multiple rows clear simultaneously")
    func clearsMultipleRows() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()
        let row1 = 1
        let row2 = 3

        // Fill row 1
        for col in 0..<engine.gridSize {
            let p = GridPosition(unsafeRow: row1, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .green)
            #expect(ok == true)
        }

        // Fill row 3
        for col in 0..<engine.gridSize {
            let p = GridPosition(unsafeRow: row2, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .purple)
            #expect(ok == true)
        }

        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines == 2)
        #expect(result.rows.contains(row1))
        #expect(result.rows.contains(row2))

        // Both rows should be empty
        for col in 0..<engine.gridSize {
            let p1 = GridPosition(unsafeRow: row1, unsafeColumn: col)
            let p2 = GridPosition(unsafeRow: row2, unsafeColumn: col)
            #expect(engine.cell(at: p1)?.isEmpty == true)
            #expect(engine.cell(at: p2)?.isEmpty == true)
        }
    }

    @Test("No partial line clears")
    func noPartialLineClears() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()
        let row = 2

        // Fill 9 out of 10 cells in row (not complete)
        for col in 0..<(engine.gridSize - 1) {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            let ok = engine.placeBlocks(at: [p], color: .orange)
            #expect(ok == true)
        }

        let result = engine.processCompletedLines()
        #expect(result.isEmpty == true)
        #expect(result.totalClearedLines == 0)

        // Row should still have blocks (not cleared)
        for col in 0..<(engine.gridSize - 1) {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            #expect(engine.cell(at: p)?.isOccupied == true)
        }
    }

    @Test("Cleared spaces immediately available")
    func clearedSpacesImmediatelyAvailable() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()
        let row = 5

        // Fill complete row
        var positions: [GridPosition] = []
        for col in 0..<engine.gridSize {
            positions.append(GridPosition(unsafeRow: row, unsafeColumn: col))
        }
        let ok = engine.placeBlocks(at: positions, color: .cyan)
        #expect(ok == true)

        // Clear the row
        let result = engine.processCompletedLines()
        #expect(result.totalClearedLines == 1)

        // Verify all positions are immediately available for placement
        for col in 0..<engine.gridSize {
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
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        // Initially no active clears
        #expect(engine.activeLineClears.isEmpty == true)

        let row = 7
        var positions: [GridPosition] = []
        for col in 0..<engine.gridSize {
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

    @Test("Placement scoring adds base cell points")
    func placementScoringAddsBasePoints() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        let positions = [
            GridPosition(unsafeRow: 0, unsafeColumn: 0),
            GridPosition(unsafeRow: 0, unsafeColumn: 1),
            GridPosition(unsafeRow: 1, unsafeColumn: 0)
        ]

        let placed = engine.placeBlocks(at: positions, color: .blue)
        #expect(placed == true)

        let lineResult = engine.processCompletedLines()
        #expect(lineResult.isEmpty == true)

        let event = engine.applyScore(placedCells: positions.count, lineClearResult: lineResult)
        #expect(event?.placementPoints == positions.count)
        #expect(event?.lineClearBonus == 0)
        #expect(engine.score == positions.count)
    }

    @Test("Single line clear awards correct bonus")
    func singleLineClearAwardsCorrectBonus() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        let targetRow = 4
        let color: BlockColor = .purple

        for col in 0..<(engine.gridSize - 1) {
            let position = GridPosition(unsafeRow: targetRow, unsafeColumn: col)
            engine.setCell(at: position, to: .occupied(color: color))
        }

        let finalPosition = GridPosition(unsafeRow: targetRow, unsafeColumn: engine.gridSize - 1)
        let placementSuccess = engine.placeBlocks(at: [finalPosition], color: color)
        #expect(placementSuccess == true)

        let lineResult = engine.processCompletedLines()
        #expect(lineResult.rows.contains(targetRow))
        #expect(lineResult.totalClearedLines == 1)

        let event = engine.applyScore(placedCells: 1, lineClearResult: lineResult)
        #expect(event?.lineClearBonus == 100)
        #expect(event?.totalDelta == 101)
        #expect(engine.score == 101)
    }

    @Test("Simultaneous multi-line clear uses exponential bonus")
    func simultaneousMultiLineClearBonus() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        let column = engine.gridSize - 1
        let firstRow = 3
        let secondRow = 4
        let fillColor: BlockColor = .red

        for row in 0..<engine.gridSize {
            if row != firstRow && row != secondRow {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                engine.setCell(at: position, to: .occupied(color: fillColor))
            }
        }

        for col in 0..<(engine.gridSize - 1) {
            let pos1 = GridPosition(unsafeRow: firstRow, unsafeColumn: col)
            let pos2 = GridPosition(unsafeRow: secondRow, unsafeColumn: col)
            engine.setCell(at: pos1, to: .occupied(color: fillColor))
            engine.setCell(at: pos2, to: .occupied(color: fillColor))
        }

        let placementPositions = [
            GridPosition(unsafeRow: firstRow, unsafeColumn: column),
            GridPosition(unsafeRow: secondRow, unsafeColumn: column)
        ]

        let placementSuccess = engine.placeBlocks(at: placementPositions, color: fillColor)
        #expect(placementSuccess == true)

        let lineResult = engine.processCompletedLines()
        #expect(lineResult.totalClearedLines == 3)
        #expect(lineResult.rows.contains(firstRow))
        #expect(lineResult.rows.contains(secondRow))
        #expect(lineResult.columns.contains(column))

        let event = engine.applyScore(placedCells: placementPositions.count, lineClearResult: lineResult)
        #expect(event?.placementPoints == placementPositions.count)
        #expect(event?.lineClearBonus == 600)
        #expect(event?.totalDelta == placementPositions.count + 600)
        #expect(engine.score == placementPositions.count + 600)
    }

    @Test("High score updates and persists across sessions")
    func highScorePersistsAcrossGames() async throws {
        let engine = GameEngine(gameMode: .classic)
        engine.startNewGame()

        let position = try #require(GridPosition(row: 0, column: 0, gridSize: engine.gridSize))
        let placed = engine.placeBlocks(at: [position], color: .cyan)
        #expect(placed == true)

        let noClearResult = engine.processCompletedLines()
        let singleEvent = engine.applyScore(placedCells: 1, lineClearResult: noClearResult)
        #expect(singleEvent != nil)
        #expect(engine.highScore == 1)

        engine.startNewGame()
        #expect(engine.score == 0)
        #expect(engine.highScore == 1)

        let rowPositions = (0..<engine.gridSize).map { GridPosition(unsafeRow: 0, unsafeColumn: $0) }
        let rowPlaced = engine.placeBlocks(at: rowPositions, color: .orange)
        #expect(rowPlaced == true)

        let rowClearResult = engine.processCompletedLines()
        let rowEvent = engine.applyScore(placedCells: rowPositions.count, lineClearResult: rowClearResult)
        #expect(rowEvent?.isNewHighScore == true)
        #expect(engine.highScore == rowEvent?.newTotal)
    }
}
