import Testing
@testable import YourAppModuleName

@Suite("GameEngine basic behavior")
struct GameEngineTests {

    @Test("New game resets state")
    func newGameResetsState() async throws {
        let engine = GameEngine()
        // Fill one cell
        let pos = try #require(GridPosition(row: 0, column: 0))
        _ = engine.placeBlocks(at: [pos], color: .red)
        // Mutate score artificially
        let _ = engine.processCompletedLines()

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
        let cleared = engine.processCompletedLines()
        #expect(cleared >= 1)
        // Row should be empty now
        for col in 0..<GameEngine.gridSize {
            let p = GridPosition(unsafeRow: row, unsafeColumn: col)
            #expect(engine.cell(at: p)?.isEmpty == true)
        }
    }
}
