import Foundation
import SpriteKit
import UIKit

// MARK: - Grid Cell Model

/// Represents the state of a single cell in the game grid
enum GridCell: Equatable {
    case empty
    case occupied(color: BlockColor)
    case preview(color: BlockColor)
    
    /// Whether this cell is empty and can be filled
    var isEmpty: Bool {
        if case .empty = self {
            return true
        }
        return false
    }
    
    /// Whether this cell is currently occupied
    var isOccupied: Bool {
        if case .occupied = self {
            return true
        }
        return false
    }

    /// Whether this cell is showing a preview
    var isPreview: Bool {
        if case .preview = self {
            return true
        }
        return false
    }
    
    /// Get the color associated with this cell if any
    var color: BlockColor? {
        switch self {
        case .empty:
            return nil
        case .occupied(let color), .preview(let color):
            return color
        }
    }
}

// MARK: - Grid Position

/// Represents a position in the 10x10 grid
struct GridPosition: Equatable, Hashable, CustomStringConvertible {
    let row: Int
    let column: Int
    
    /// Create a GridPosition with validation
    init?(row: Int, column: Int, gridSize: Int) {
        guard row >= 0 && row < gridSize && column >= 0 && column < gridSize else {
            return nil
        }
        self.row = row
        self.column = column
    }
    
    /// Create a GridPosition without validation (for internal use)
    init(unsafeRow row: Int, unsafeColumn column: Int) {
        self.row = row
        self.column = column
    }

    /// CustomStringConvertible conformance
    var description: String {
        return "(\(row), \(column))"
    }
}
