import Foundation
import SpriteKit

// MARK: - Block Type Model

/// Defines the different types of blocks available in the game
enum BlockType: String, CaseIterable, Identifiable {
    case single = "single"                 // 1x1 block
    case horizontal = "horizontal"         // 1x2 horizontal domino
    case vertical = "vertical"             // 2x1 vertical domino
    case lineThree = "lineThree"           // 1x3 bar
    case lineThreeVertical = "lineThreeVertical" // 3x1 vertical bar
    case lineFourVertical = "lineFourVertical"   // 4x1 vertical bar
    case square = "square"                 // 2x2 square
    case lShape = "lShape"                 // Classic corner piece
    case tShape = "tShape"                 // T-shaped piece
    case zigZag = "zigZag"                 // Z-shaped piece
    case plus = "plus"                     // Plus / cross piece
    
    var id: String { rawValue }
    
    /// Human readable name for accessibility and UI
    var displayName: String {
        switch self {
        case .single:
            return "Single Block"
        case .horizontal:
            return "Domino"
        case .vertical:
            return "Vertical Domino"
        case .lineThree:
            return "Triple Bar"
        case .lineThreeVertical:
            return "Vertical Triple Bar"
        case .lineFourVertical:
            return "Vertical Quad Bar"
        case .lShape:
            return "L-Shape Block"
        case .square:
            return "Square"
        case .tShape:
            return "T-Shape"
        case .zigZag:
            return "Zig-Zag"
        case .plus:
            return "Plus Piece"
        }
    }
    
    /// Block pattern definition showing occupied cells
    var pattern: [[Bool]] {
        switch self {
        case .single:
            return [[true]]
        case .horizontal:
            return [[true, true]]
        case .vertical:
            return [
                [true],
                [true]
            ]
        case .lineThree:
            return [[true, true, true]]
        case .lineThreeVertical:
            return [
                [true],
                [true],
                [true]
            ]
        case .lineFourVertical:
            return [
                [true],
                [true],
                [true],
                [true]
            ]
        case .square:
            return [
                [true, true],
                [true, true]
            ]
        case .lShape:
            return [
                [true, false],
                [true, true]
            ]
        case .tShape:
            return [
                [true, true, true],
                [false, true, false]
            ]
        case .zigZag:
            return [
                [false, true, true],
                [true, true, false]
            ]
        case .plus:
            return [
                [false, true, false],
                [true,  true, true],
                [false, true, false]
            ]
        }
    }
    
    /// Size of the block in grid cells
    var size: CGSize {
        let pattern = self.pattern
        let height = CGFloat(pattern.count)
        let width = CGFloat(pattern.max(by: { $0.count < $1.count })?.count ?? 0)
        return CGSize(width: width, height: height)
    }
    
    /// Get all occupied positions relative to top-left origin
    var occupiedPositions: [CGPoint] {
        var positions: [CGPoint] = []
        let pattern = self.pattern
        
        for (row, rowPattern) in pattern.enumerated() {
            for (col, isOccupied) in rowPattern.enumerated() {
                if isOccupied {
                    positions.append(CGPoint(x: col, y: row))
                }
            }
        }
        
        return positions
    }
    
    /// Number of cells this block occupies
    var cellCount: Int {
        return occupiedPositions.count
    }
}

// MARK: - Block Pattern

/// Represents a complete block pattern with visual properties
struct BlockPattern {
    let type: BlockType
    let color: BlockColor
    let cells: [[Bool]]
    let size: CGSize
    
    init(type: BlockType, color: BlockColor) {
        self.type = type
        self.color = color
        self.cells = type.pattern
        self.size = type.size
    }
    
    /// Get occupied positions for this pattern
    var occupiedPositions: [CGPoint] {
        return type.occupiedPositions
    }
    
    /// Check if this pattern can fit at a specific grid position
    func canFit(at position: GridPosition, in gridSize: Int) -> Bool {
        for cellPosition in occupiedPositions {
            let targetRow = position.row + Int(cellPosition.y)
            let targetCol = position.column + Int(cellPosition.x)
            
            // Check bounds
            if targetRow < 0 || targetRow >= gridSize || 
               targetCol < 0 || targetCol >= gridSize {
                return false
            }
        }
        return true
    }
    
    /// Get all grid positions this block would occupy if placed at the given position
    func getGridPositions(placedAt position: GridPosition) -> [GridPosition] {
        var positions: [GridPosition] = []
        
        for cellPosition in occupiedPositions {
            let targetRow = position.row + Int(cellPosition.y)
            let targetCol = position.column + Int(cellPosition.x)
            
            let gridPos = GridPosition(unsafeRow: targetRow, unsafeColumn: targetCol)
            positions.append(gridPos)
        }
        
        return positions
    }
    
    /// Number of cells this block pattern occupies
    var cellCount: Int {
        return type.cellCount
    }
}

// MARK: - Block Factory

/// Responsible for creating and managing block instances
@MainActor
class BlockFactory: ObservableObject {
    
    // MARK: - Properties
    
    /// Current tray slots (exactly three, may contain nil if consumed)
    @Published private(set) var traySlots: [BlockPattern?] = []

    /// Number of blocks displayed in the tray simultaneously
    private let traySize = 3

    /// Remember the previous tray selection to avoid repetition
    private var lastTrayTypes: Set<BlockType> = []

    /// Random generator for block and color selection
    private var generator = SystemRandomNumberGenerator()
    
    // MARK: - Initialization
    
    init() {
        refillTray()
    }

    // MARK: - Public API

    /// Current tray contents (nil entries indicate a consumed slot)
    func getTraySlots() -> [BlockPattern?] {
        traySlots
    }

    /// Retrieve a block at a specific tray index
    func getBlock(at index: Int) -> BlockPattern? {
        guard traySlots.indices.contains(index) else { return nil }
        return traySlots[index]
    }

    /// Consume a block; tray refreshes only when all slots are empty
    func consumeBlock(at index: Int) {
        guard traySlots.indices.contains(index), traySlots[index] != nil else { return }

        var updatedSlots = traySlots
        updatedSlots[index] = nil
        traySlots = updatedSlots

        if traySlots.compactMap({ $0 }).isEmpty {
            refillTray()
        }
    }

    /// Reset the tray to a fresh random selection (used when starting a new game)
    func resetTray() {
        refillTray()
    }

    /// Legacy API: behave like consuming a block so tray only refreshes when empty
    func regenerateBlock(at index: Int) {
        consumeBlock(at: index)
    }

    /// Legacy API: reset the full tray with a fresh random selection
    func regenerateAllBlocks() {
        resetTray()
    }

    /// Determine if any blocks remain unplaced in the current tray cycle
    var hasAvailableBlocks: Bool {
        traySlots.contains { $0 != nil }
    }

    /// Convenience accessor for non-empty blocks (legacy API compatibility)
    var availableBlocks: [BlockPattern] {
        traySlots.compactMap { $0 }
    }

    /// Legacy helper returning only non-empty blocks
    func getAvailableBlocks() -> [BlockPattern] {
        availableBlocks
    }

    // MARK: - Tray Generation

    private func refillTray() {
        let types = pickTrayTypes()
        traySlots = types.map { makePattern(for: $0) }
    }

    private func pickTrayTypes() -> [BlockType] {
        var pool = BlockType.allCases.shuffled(using: &generator)

        if pool.count < traySize {
            return Array(repeating: .single, count: traySize)
        }

        var selected = Array(pool.prefix(traySize))

        var attempts = 0
        while Set(selected) == lastTrayTypes && attempts < 5 {
            pool.shuffle(using: &generator)
            selected = Array(pool.prefix(traySize))
            attempts += 1
        }

        lastTrayTypes = Set(selected)
        return selected
    }

    private func makePattern(for type: BlockType) -> BlockPattern {
        let color = BlockColor.allCases.randomElement(using: &generator) ?? .blue
        return BlockPattern(type: type, color: color)
    }
}
