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
        if case .occupied(_) = self {
            return true
        }
        return false
    }
    
    /// Whether this cell is showing a preview
    var isPreview: Bool {
        if case .preview(_) = self {
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

// MARK: - Block Color Model

/// Represents the different colors blocks can have
enum BlockColor: String, CaseIterable {
    case red = "red"
    case blue = "blue"
    case green = "green"
    case yellow = "yellow"
    case purple = "purple"
    case orange = "orange"
    case cyan = "cyan"
    case pink = "pink"
    
    /// Get the SKColor representation for rendering (vibrant colors optimized for blocks)
    var skColor: SKColor {
        switch self {
        case .red:
            return SKColor(red: 0.92, green: 0.26, blue: 0.21, alpha: 1.0) // #EB4336 - Vibrant red
        case .blue:
            return SKColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0) // #4A90E2 - Trustworthy blue
        case .green:
            return SKColor(red: 0.49, green: 0.83, blue: 0.13, alpha: 1.0) // #7ED321 - Fresh green
        case .yellow:
            return SKColor(red: 0.95, green: 0.77, blue: 0.06, alpha: 1.0) // #F3C40F - Bright yellow
        case .purple:
            return SKColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.0) // #9B59B6 - Royal purple
        case .orange:
            return SKColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0) // #FF6B35 - Vibrant orange
        case .cyan:
            return SKColor(red: 0.11, green: 0.73, blue: 0.81, alpha: 1.0) // #1CBACF - Electric cyan
        case .pink:
            return SKColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0) // #E91E63 - Vibrant pink
        }
    }
    
    /// Get a preview version of the color (semi-transparent)
    var previewColor: SKColor {
        return skColor.withAlphaComponent(0.2)
    }
    
    /// Get high contrast version for accessibility
    var highContrastColor: SKColor {
        switch self {
        case .red, .orange, .pink:
            return SKColor.systemRed
        case .blue, .cyan:
            return SKColor.systemBlue
        case .green:
            return SKColor.systemGreen
        case .yellow:
            return SKColor.systemYellow
        case .purple:
            return SKColor.systemPurple
        }
    }
    
    /// Get pattern identifier for colorblind accessibility
    var accessibilityPattern: String {
        switch self {
        case .red: return "solid"
        case .blue: return "dots"
        case .green: return "stripes"
        case .yellow: return "grid"
        case .purple: return "diagonal"
        case .orange: return "cross"
        case .cyan: return "waves"
        case .pink: return "checker"
        }
    }
    
    /// Accessibility description for VoiceOver
    var accessibilityDescription: String {
        switch self {
        case .red: return "Red block"
        case .blue: return "Blue block" 
        case .green: return "Green block"
        case .yellow: return "Yellow block"
        case .purple: return "Purple block"
        case .orange: return "Orange block"
        case .cyan: return "Cyan block"
        case .pink: return "Pink block"
        }
    }
    
    /// Get UIColor for SwiftUI compatibility
    var uiColor: UIColor {
        switch self {
        case .red:
            return UIColor(red: 0.92, green: 0.26, blue: 0.21, alpha: 1.0) // #EB4336
        case .blue:
            return UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0) // #4A90E2
        case .green:
            return UIColor(red: 0.49, green: 0.83, blue: 0.13, alpha: 1.0) // #7ED321
        case .yellow:
            return UIColor(red: 0.95, green: 0.77, blue: 0.06, alpha: 1.0) // #F3C40F
        case .purple:
            return UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.0) // #9B59B6
        case .orange:
            return UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0) // #FF6B35
        case .cyan:
            return UIColor(red: 0.11, green: 0.73, blue: 0.81, alpha: 1.0) // #1CBACF
        case .pink:
            return UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0) // #E91E63
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
