import Foundation

// MARK: - Grid State Snapshot

/// Represents a snapshot of the grid state for undo functionality
struct GridStateSnapshot: Codable {
    let timestamp: Date
    let filledCells: [[Bool]]  // Grid state
    let score: Int
    let moveCount: Int

    init(grid: [[Bool]], score: Int, moveCount: Int) {
        self.timestamp = Date()
        self.filledCells = grid
        self.score = score
        self.moveCount = moveCount
    }
}

// MARK: - Zen Undo Manager

/// Manages unlimited undo for Zen Mode
/// Children love being able to try again without consequences!
@Observable
class ZenUndoManager {
    private(set) var history: [GridStateSnapshot] = []
    private let maxHistorySize = 100  // Keep last 100 moves to prevent memory issues

    var canUndo: Bool {
        return history.count > 1
    }

    var undoCount: Int {
        return max(0, history.count - 1)
    }

    // MARK: - Record State

    /// Save the current game state
    func recordState(grid: [[Bool]], score: Int, moveCount: Int) {
        let snapshot = GridStateSnapshot(grid: grid, score: score, moveCount: moveCount)
        history.append(snapshot)

        // Limit history to prevent memory issues
        if history.count > maxHistorySize {
            history.removeFirst()
        }
    }

    // MARK: - Undo

    /// Undo the last move and return the previous state
    func undo() -> GridStateSnapshot? {
        guard canUndo else { return nil }

        // Remove current state
        history.removeLast()

        // Return previous state
        return history.last
    }

    // MARK: - Clear History

    /// Clear all undo history (used when starting new session)
    func clear() {
        history.removeAll()
    }

    // MARK: - Debug

    func printHistory() {
        print("📚 Undo History (\(history.count) states):")
        for (index, snapshot) in history.enumerated() {
            print("  \(index): Move \(snapshot.moveCount), Score \(snapshot.score)")
        }
    }
}
