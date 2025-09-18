import Foundation
import SpriteKit

// MARK: - Block Type Model

/// Defines the different types of blocks available in the game
enum BlockType: String, CaseIterable, Identifiable {
    case single = "single"           // 1x1 block
    case horizontal = "horizontal"   // 1x2 block  
    case lShape = "lShape"          // L-shape block
    
    var id: String { rawValue }
    
    /// Human readable name for accessibility and UI
    var displayName: String {
        switch self {
        case .single:
            return "Single Block"
        case .horizontal:
            return "Horizontal Block"
        case .lShape:
            return "L-Shape Block"
        }
    }
    
    /// Block pattern definition showing occupied cells
    var pattern: [[Bool]] {
        switch self {
        case .single:
            return [[true]]
        case .horizontal:
            return [[true, true]]
        case .lShape:
            return [
                [true, false],
                [true, true]
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
            
            if let gridPos = GridPosition(row: targetRow, column: targetCol) {
                positions.append(gridPos)
            }
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
    
    /// Current available blocks in the tray
    @Published private(set) var availableBlocks: [BlockPattern] = []
    
    /// The three starting block types for this story
    private let startingBlockTypes: [BlockType] = [.lShape, .single, .horizontal]
    
    /// Color assignments for each block type
    private let blockColors: [BlockType: BlockColor] = [
        .lShape: .orange,      // Most complex, warm attention color
        .single: .blue,        // Simple, cool and reliable  
        .horizontal: .green    // Medium complexity, fresh growth color
    ]
    
    // MARK: - Initialization
    
    init() {
        generateInitialBlocks()
    }
    
    // MARK: - Block Generation
    
    /// Generate the initial set of three blocks
    private func generateInitialBlocks() {
        availableBlocks = startingBlockTypes.map { blockType in
            let color = blockColors[blockType] ?? .blue
            return BlockPattern(type: blockType, color: color)
        }
    }
    
    /// Get the current available blocks
    func getAvailableBlocks() -> [BlockPattern] {
        return availableBlocks
    }
    
    /// Regenerate a specific block after placement (infinite supply)
    func regenerateBlock(at index: Int) {
        guard index >= 0 && index < availableBlocks.count else { return }
        
        let blockType = startingBlockTypes[index]
        let color = blockColors[blockType] ?? .blue
        var updatedBlocks = availableBlocks
        updatedBlocks[index] = BlockPattern(type: blockType, color: color)
        availableBlocks = updatedBlocks
    }
    
    /// Regenerate all blocks (for testing or reset scenarios)
    func regenerateAllBlocks() {
        generateInitialBlocks()
    }
    
    /// Check if any blocks are available for placement
    var hasAvailableBlocks: Bool {
        return !availableBlocks.isEmpty
    }
    
    /// Get a specific block pattern by index
    func getBlock(at index: Int) -> BlockPattern? {
        guard index >= 0 && index < availableBlocks.count else { return nil }
        return availableBlocks[index]
    }
}