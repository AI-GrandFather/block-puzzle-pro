import Foundation
import Combine
import os.log

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
    
    /// Whether the game is currently active
    @Published private(set) var isGameActive: Bool = false
    
    // MARK: - Constants
    
    static let gridSize = 10
    
    // MARK: - Initialization
    
    init() {
        // Initialize empty 10x10 grid
        self.gameGrid = Array(
            repeating: Array(repeating: GridCell.empty, count: Self.gridSize), 
            count: Self.gridSize
        )
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
        isGameActive = true
        
        logger.info("New game started")
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
        
        logger.info("Placed \(positions.count) blocks with color \(String(describing: color))")
        return true
    }
    
    /// Check for completed lines and clear them
    func processCompletedLines() -> Int {
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
        
        // Clear completed lines
        for row in completedRows {
            for column in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                setCell(at: position, to: .empty)
            }
        }
        
        for column in completedColumns {
            for row in 0..<Self.gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)
                setCell(at: position, to: .empty)
            }
        }
        
        let totalCompleted = completedRows.count + completedColumns.count
        if totalCompleted > 0 {
            logger.info("Cleared \(completedRows.count) rows and \(completedColumns.count) columns")
        }
        
        return totalCompleted
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