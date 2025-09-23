import Foundation
import Combine
import os.log

// MARK: - Line Clear Models

/// Represents a single cleared line (row or column)
struct LineClear: Identifiable, Equatable {
    enum Kind: Equatable {
        case row(Int)
        case column(Int)
    }

    let kind: Kind
    let positions: [GridPosition]
    let fragments: [Fragment]

    struct Fragment: Identifiable, Equatable {
        let id = UUID()
        let position: GridPosition
        let color: BlockColor
    }

    var id: String {
        switch kind {
        case .row(let row):
            return "row-\(row)"
        case .column(let column):
            return "col-\(column)"
        }
    }
}

/// Summary of line clear results for a placement
struct LineClearResult {
    let clears: [LineClear]

    var rows: [Int] {
        clears.compactMap { if case .row(let row) = $0.kind { row } else { nil } }
    }

    var columns: [Int] {
        clears.compactMap { if case .column(let column) = $0.kind { column } else { nil } }
    }

    var totalClearedLines: Int { clears.count }

    var uniquePositions: Set<GridPosition> {
        Set(clears.flatMap { $0.positions })
    }

    var fragments: [LineClear.Fragment] {
        clears.flatMap { $0.fragments }
    }

    var isEmpty: Bool { clears.isEmpty }

    static let empty = LineClearResult(clears: [])
}

// MARK: - Game Engine

/// Core game engine managing the 10x10 grid and game state
@MainActor
class GameEngine: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "GameEngine")
    
    /// 10x10 game grid
    @Published private(set) var gameGrid: [[GridCell]]
    
    /// Current score
    @Published private(set) var score: Int = 0

    /// Breakdown of the most recent scoring update for UI animations
    @Published private(set) var lastScoreEvent: ScoreEvent? = nil

    /// Highest score achieved in the current app session
    @Published private(set) var highScore: Int = 0
    
    /// Whether the game is currently active
    @Published private(set) var isGameActive: Bool = false

    /// Recently cleared lines for animation/highlight purposes
    @Published private(set) var activeLineClears: [LineClear] = []

    // MARK: - Constants

    static let gridSize = 10

    // MARK: - Private State

    private var scoreTracker = ScoreTracker()
    
    // MARK: - Initialization
    
    init() {
        // Initialize empty 10x10 grid
        self.gameGrid = Array(
            repeating: Array(repeating: GridCell.empty, count: Self.gridSize), 
            count: Self.gridSize
        )
        scoreTracker.reset()
        logger.info("GameEngine initialized with \(Self.gridSize)x\(Self.gridSize) grid")
    }
    
    // MARK: - Grid Management
    
    /// Get the cell at a specific position
    func cell(at position: GridPosition) -> GridCell? {
        guard position.isValid else { return nil }
        return gameGrid[position.row][position.column]
    }
    
    /// Set a cell at a specific position
    func setCell(at position: GridPosition, to cell: GridCell) {
        guard position.isValid else {
            logger.warning("Attempted to set cell at invalid position: \(String(describing: position))")
            return
        }
        objectWillChange.send()
        var row = gameGrid[position.row]
        row[position.column] = cell
        gameGrid[position.row] = row
    }
    
    /// Check if a position is empty and can be filled
    func canPlaceAt(position: GridPosition) -> Bool {
        guard let cell = cell(at: position) else { return false }
        // Allow placement on empty cells or preview cells (preview cells can be overwritten)
        return cell.isEmpty || cell.isPreview
    }

    /// Determine if a full block pattern can be placed anywhere on the grid.
    func canPlace(blockPattern: BlockPattern) -> Bool {
        for row in 0..<Self.gridSize {
            for column in 0..<Self.gridSize {
                guard let origin = GridPosition(row: row, column: column) else { continue }
                guard blockPattern.canFit(at: origin, in: Self.gridSize) else { continue }

                let positions = blockPattern.getGridPositions(placedAt: origin)
                if positions.allSatisfy({ canPlaceAt(position: $0) }) {
                    return true
                }
            }
        }

        return false
    }

    /// Evaluate if any blocks from the provided collection can be placed on the grid.
    func hasAnyValidMove(using blocks: [BlockPattern]) -> Bool {
        for block in blocks {
            if canPlace(blockPattern: block) {
                return true
            }
        }
        return false
    }
    
    /// Get all empty positions in the grid
    func getEmptyPositions() -> [GridPosition] {
        var emptyPositions: [GridPosition] = []
        
        for row in 0..<Self.gridSize {
            for column in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                if let cell = cell(at: position), cell.isEmpty {
                    emptyPositions.append(position)
                }
            }
        }
        
        return emptyPositions
    }
    
    /// Clear all preview cells from the grid
    func clearPreviews() {
        for row in 0..<Self.gridSize {
            for column in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                if let cell = cell(at: position), cell.isPreview {
                    setCell(at: position, to: .empty)
                }
            }
        }
    }
    
    /// Set preview for multiple positions
    func setPreview(at positions: [GridPosition], color: BlockColor) {
        for position in positions {
            if canPlaceAt(position: position) {
                setCell(at: position, to: .preview(color: color))
            }
        }
    }
    
    // MARK: - Game Logic
    
    /// Start a new game
    func startNewGame() {
        // Reset grid to empty
        gameGrid = Array(
            repeating: Array(repeating: GridCell.empty, count: Self.gridSize), 
            count: Self.gridSize
        )

        score = 0
        lastScoreEvent = nil
        scoreTracker.reset()
        isGameActive = true

        logger.info("New game started")
    }

    /// Mark the current session as ended without mutating grid contents.
    func endGame() {
        guard isGameActive else { return }
        isGameActive = false
        logger.info("Game ended")
    }
    
    /// Place blocks at specified positions
    func placeBlocks(at positions: [GridPosition], color: BlockColor) -> Bool {
        // Validate all positions are available
        for position in positions {
            if !canPlaceAt(position: position) {
                logger.warning("Cannot place block at position \(String(describing: position))")
                return false
            }
        }

        // Place all blocks
        for position in positions {
            setCell(at: position, to: .occupied(color: color))
        }

        logger.info("Placed \(positions.count) blocks with color \(color.rawValue)")
        return true
    }

    /// Apply scoring for a placement and its resulting line clears.
    @discardableResult
    func applyScore(placedCells: Int, lineClearResult: LineClearResult) -> ScoreEvent? {
        let totalLinesCleared = lineClearResult.totalClearedLines
        guard placedCells > 0 || totalLinesCleared > 0 else {
            return nil
        }

        let breakdown = scoreTracker.recordPlacement(
            placedCells: max(0, placedCells),
            linesCleared: max(0, totalLinesCleared)
        )

        score = scoreTracker.totalScore

        let didSetNewHigh = scoreTracker.bestScore > highScore
        if didSetNewHigh {
            highScore = scoreTracker.bestScore
        }

        let event = ScoreEvent(
            placedCells: breakdown.placedCells,
            linesCleared: breakdown.linesCleared,
            placementPoints: breakdown.placementPoints,
            lineClearBonus: breakdown.lineClearBonus,
            totalDelta: breakdown.totalPoints,
            newTotal: score,
            highScore: highScore,
            isNewHighScore: didSetNewHigh
        )

        lastScoreEvent = event

        logger.info(
            "Score updated by \(event.totalDelta) points (placement: \(event.placementPoints), bonus: \(event.lineClearBonus)) -> total \(event.newTotal)"
        )

        return event
    }

    /// Check for completed lines and clear them
    func processCompletedLines() -> LineClearResult {
        var completedRows: [Int] = []
        var completedColumns: [Int] = []
        
        // Check rows
        for row in 0..<Self.gridSize {
            var isComplete = true
            for column in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                if let cell = cell(at: position), !cell.isOccupied {
                    isComplete = false
                    break
                }
            }
            if isComplete {
                completedRows.append(row)
            }
        }
        
        // Check columns
        for column in 0..<Self.gridSize {
            var isComplete = true
            for row in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                if let cell = cell(at: position), !cell.isOccupied {
                    isComplete = false
                    break
                }
            }
            if isComplete {
                completedColumns.append(column)
            }
        }
        
        var lineClears: [LineClear] = []

        // Clear completed lines
        for row in completedRows {
            var rowFragments: [LineClear.Fragment] = []
            
            for column in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                if let cell = cell(at: position), case .occupied(let color) = cell {
                    rowFragments.append(LineClear.Fragment(position: position, color: color))
                }
                setCell(at: position, to: .empty)
            }
            let positions = (0..<Self.gridSize).compactMap { GridPosition(row: row, column: $0) }
            lineClears.append(LineClear(kind: .row(row), positions: positions, fragments: rowFragments))
        }

        for column in completedColumns {
            var columnFragments: [LineClear.Fragment] = []
            for row in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                if let cell = cell(at: position), case .occupied(let color) = cell {
                    columnFragments.append(LineClear.Fragment(position: position, color: color))
                }
                setCell(at: position, to: .empty)
            }
            let positions = (0..<Self.gridSize).compactMap { GridPosition(row: $0, column: column) }
            lineClears.append(LineClear(kind: .column(column), positions: positions, fragments: columnFragments))
        }

        activeLineClears = lineClears

        if !lineClears.isEmpty {
            logger.info("Cleared \(completedRows.count) rows and \(completedColumns.count) columns")
        }

        return LineClearResult(clears: lineClears)
    }

    /// Clears the published line-clear state after animations complete
    func clearActiveLineClears() {
        activeLineClears = []
    }
    
    // MARK: - Debug Utilities
    
    /// Print current grid state for debugging
    func printGrid() {
        logger.debug("Current grid state:")
        for row in 0..<Self.gridSize {
            var rowString = ""
            for column in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                if let cell = cell(at: position) {
                    switch cell {
                    case .empty:
                        rowString += "."
                    case .occupied(_):
                        rowString += "X"
                    case .preview(_):
                        rowString += "?"
                    }
                }
            }
            logger.debug("Row \(row): \(rowString)")
        }
    }
}
