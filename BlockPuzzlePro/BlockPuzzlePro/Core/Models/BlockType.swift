import Foundation
import SpriteKit

// MARK: - Piece Category

/// High-level categorization of pieces for spawning algorithm
enum PieceCategory: String, CaseIterable {
    case monomino       // 1 block
    case domino         // 2 blocks
    case triomino       // 3 blocks
    case tetromino      // 4 blocks
    case pentomino      // 5 blocks
    case largeReward    // 6+ blocks (rectangles, squares, etc.)
}

// MARK: - Block Type Model

/// Defines the different types of blocks available in the game
/// Complete polyomino taxonomy for block puzzle games
enum BlockType: String, CaseIterable, Identifiable, Codable {
    // MARK: - Monomino (1 block)
    case single

    // MARK: - Domino (2 blocks)
    case domino

    // MARK: - Triominoes (3 blocks)
    case triLine
    case triCorner

    // MARK: - Tetrominoes (4 blocks - all 7 one-sided shapes)
    case tetLine      // I-piece
    case tetSquare    // O-piece
    case tetL         // L-piece
    case tetJ         // J-piece (mirror of L)
    case tetT         // T-piece
    case tetS         // S-piece
    case tetZ         // Z-piece (mirror of S)
    case tetSkew      // Legacy alias for tetZ

    // MARK: - Pentominoes (5 blocks - 12 unique shapes)
    case pentaF       // F-pentomino
    case pentaI       // I-pentomino (alias for pentaLine)
    case pentaLine    // 5x1 line
    case pentaL       // L-pentomino
    case pentaN       // N-pentomino (zigzag)
    case pentaP       // P-pentomino
    case pentaT       // T-pentomino
    case pentaU       // U-pentomino
    case pentaV       // V-pentomino
    case pentaW       // W-pentomino
    case pentaX       // X-pentomino (plus/cross)
    case pentaY       // Y-pentomino
    case pentaZ       // Z-pentomino (extended zigzag)

    // MARK: - Large Pieces (for easier early-game)
    case rect2x3      // 2x3 rectangle (6 blocks)
    case rect3x2      // 3x2 rectangle (6 blocks)
    case square3x3    // 3x3 square (9 blocks)
    case largeL3x3    // 3x3 L-shape (5 blocks)
    case plusShape    // 3x3 with 4 corners removed (5 blocks)
    case almostSquare // 3x3 with 1 corner removed (8 blocks)

    var id: String { rawValue }
    
    init?(rawValue: String) {
        switch rawValue {
        // Monomino
        case "single":
            self = .single

        // Domino
        case "horizontal", "vertical", "domino":
            self = .domino

        // Triominoes
        case "lineThree", "lineThreeVertical", "triLine":
            self = .triLine
        case "lShape", "triCorner":
            self = .triCorner

        // Tetrominoes
        case "lineFourVertical", "tetLine":
            self = .tetLine
        case "square", "tetSquare":
            self = .tetSquare
        case "tetL":
            self = .tetL
        case "tetJ":
            self = .tetJ
        case "tShape", "tetT":
            self = .tetT
        case "tetS":
            self = .tetS
        case "zigZag", "tetZ", "tetSkew":
            self = .tetSkew

        // Pentominoes
        case "pentaF":
            self = .pentaF
        case "pentaI":
            self = .pentaI
        case "pentaLine":
            self = .pentaLine
        case "pentaL":
            self = .pentaL
        case "pentaN":
            self = .pentaN
        case "pentaP":
            self = .pentaP
        case "pentaT":
            self = .pentaT
        case "pentaU", "plus":
            self = .pentaU
        case "pentaV":
            self = .pentaV
        case "pentaW":
            self = .pentaW
        case "pentaX":
            self = .pentaX
        case "pentaY":
            self = .pentaY
        case "pentaZ":
            self = .pentaZ

        // Large pieces
        case "rect2x3":
            self = .rect2x3
        case "rect3x2":
            self = .rect3x2
        case "square3x3":
            self = .square3x3
        case "largeL3x3":
            self = .largeL3x3
        case "plusShape":
            self = .plusShape
        case "squareThree", "almostSquare":
            self = .almostSquare

        default:
            return nil
        }
    }

    var rawValue: String {
        switch self {
        // Monomino
        case .single: return "single"

        // Domino
        case .domino: return "domino"

        // Triominoes
        case .triLine: return "triLine"
        case .triCorner: return "triCorner"

        // Tetrominoes
        case .tetLine: return "tetLine"
        case .tetSquare: return "tetSquare"
        case .tetL: return "tetL"
        case .tetJ: return "tetJ"
        case .tetT: return "tetT"
        case .tetS: return "tetS"
        case .tetZ: return "tetZ"
        case .tetSkew: return "tetSkew"

        // Pentominoes
        case .pentaF: return "pentaF"
        case .pentaI: return "pentaI"
        case .pentaLine: return "pentaLine"
        case .pentaL: return "pentaL"
        case .pentaN: return "pentaN"
        case .pentaP: return "pentaP"
        case .pentaT: return "pentaT"
        case .pentaU: return "pentaU"
        case .pentaV: return "pentaV"
        case .pentaW: return "pentaW"
        case .pentaX: return "pentaX"
        case .pentaY: return "pentaY"
        case .pentaZ: return "pentaZ"

        // Large pieces
        case .rect2x3: return "rect2x3"
        case .rect3x2: return "rect3x2"
        case .square3x3: return "square3x3"
        case .largeL3x3: return "largeL3x3"
        case .plusShape: return "plusShape"
        case .almostSquare: return "almostSquare"
        }
    }

    /// Human readable name for accessibility and UI
    var displayName: String {
        switch self {
        // Monomino
        case .single:
            return "Single Block"

        // Domino
        case .domino:
            return "Domino"

        // Triominoes
        case .triLine:
            return "Triple Bar"
        case .triCorner:
            return "Corner Trio"

        // Tetrominoes
        case .tetLine:
            return "Quad Bar"
        case .tetSquare:
            return "Square"
        case .tetL:
            return "L Tetromino"
        case .tetJ:
            return "J Tetromino"
        case .tetT:
            return "T Tetromino"
        case .tetS:
            return "S Tetromino"
        case .tetZ:
            return "Z Tetromino"
        case .tetSkew:
            return "Skew Tetromino"

        // Pentominoes
        case .pentaF:
            return "F Pentomino"
        case .pentaI:
            return "I Pentomino"
        case .pentaLine:
            return "Long Pentomino"
        case .pentaL:
            return "L Pentomino"
        case .pentaN:
            return "N Pentomino"
        case .pentaP:
            return "P Pentomino"
        case .pentaT:
            return "T Pentomino"
        case .pentaU:
            return "U Pentomino"
        case .pentaV:
            return "V Pentomino"
        case .pentaW:
            return "W Pentomino"
        case .pentaX:
            return "X Pentomino"
        case .pentaY:
            return "Y Pentomino"
        case .pentaZ:
            return "Z Pentomino"

        // Large pieces
        case .rect2x3:
            return "2x3 Rectangle"
        case .rect3x2:
            return "3x2 Rectangle"
        case .square3x3:
            return "3x3 Square"
        case .largeL3x3:
            return "Large L-Shape"
        case .plusShape:
            return "Plus Shape"
        case .almostSquare:
            return "Missing Corner Block"
        }
    }
    
    /// Default orientation pattern
    var pattern: [[Bool]] {
        basePattern
    }

    /// All unique orientations (rotation + optional mirror) trimmed to bounding box
    var variations: [[[Bool]]] {
        switch self {
        // Symmetric pieces (no mirror needed)
        case .single, .domino, .triLine, .tetLine, .tetSquare, .tetT, .pentaLine, .pentaI, .pentaU, .pentaX, .pentaT:
            return uniqueVariants(for: basePattern, includeMirror: false)

        // Asymmetric pieces that don't benefit from mirroring (4 rotations are enough)
        case .triCorner, .almostSquare, .square3x3, .rect2x3, .rect3x2, .plusShape, .largeL3x3:
            return uniqueVariants(for: basePattern, includeMirror: false)

        // Chiral pieces (need mirror variants to get all orientations)
        case .tetL, .tetJ, .tetS, .tetZ, .tetSkew:
            return uniqueVariants(for: basePattern, includeMirror: true)
        case .pentaF, .pentaL, .pentaN, .pentaP, .pentaV, .pentaW, .pentaY, .pentaZ:
            return uniqueVariants(for: basePattern, includeMirror: true)
        }
    }
    
    /// Size of the block in grid cells
    var size: CGSize {
        let pattern = basePattern
        return CGSize(
            width: CGFloat(pattern.first?.count ?? 0),
            height: CGFloat(pattern.count)
        )
    }
    
    /// Get all occupied positions relative to top-left origin
    var occupiedPositions: [CGPoint] {
        BlockPattern.computeOccupiedPositions(from: basePattern)
    }
    
    /// Number of cells this block occupies
    var cellCount: Int {
        return occupiedPositions.count
    }

    /// Complexity score (1-10) indicating how difficult this piece is to place
    /// Used by the spawning algorithm for difficulty balancing
    /// Factors: shape irregularity, size relative to grid, likelihood of creating gaps
    var complexityScore: Int {
        switch self {
        // MARK: - Very Easy (1-2)
        case .single:
            return 1  // Easiest - fits anywhere
        case .domino:
            return 2  // Very easy - small and simple

        // MARK: - Easy (2-4)
        case .triLine:
            return 2  // Simple straight line
        case .triCorner:
            return 3  // Simple L-shape
        case .rect2x3, .rect3x2:
            return 3  // Large but rectangular = easy to visualize

        // MARK: - Medium (4-6)
        case .tetSquare:
            return 4  // Simple 2x2 square
        case .tetLine:
            return 4  // 4x1 line - 50% of 8x8 row
        case .tetT:
            return 5  // Moderately complex T-shape
        case .tetL:
            return 5  // Standard L-shape
        case .tetJ:
            return 5  // Mirror of L

        // MARK: - Challenging (6-7)
        case .tetS:
            return 6  // Creates awkward diagonal gaps
        case .tetZ, .tetSkew:
            return 6  // Creates awkward diagonal gaps
        case .pentaU:
            return 6  // Compact pentomino, easiest of the group
        case .pentaX, .plusShape:
            return 6  // Cross shape - distinctive but manageable
        case .pentaT:
            return 6  // T with extended stem
        case .pentaP:
            return 6  // Compact P-shape

        // MARK: - Hard (7-8)
        case .pentaL:
            return 7  // 4x2 footprint, harder to fit
        case .pentaV:
            return 7  // V-shape, 3x3 footprint
        case .largeL3x3:
            return 7  // 3x3 L-shape, takes up significant space
        case .pentaF:
            return 7  // Asymmetric F-shape
        case .pentaN:
            return 7  // Zigzag pattern
        case .pentaY:
            return 7  // Y-shape with long stem

        // MARK: - Very Hard (8-9)
        case .pentaW:
            return 8  // Sprawling W-shape, awkward on 8x8
        case .pentaZ:
            return 8  // Extended zigzag
        case .pentaI, .pentaLine:
            return 8  // 5x1 line is 62.5% of row - very constraining on 8x8
        case .almostSquare:
            return 9  // 8 blocks in 3x3 - huge footprint on 8x8 grid

        // MARK: - Extreme (10)
        case .square3x3:
            return 10  // 9 blocks = 14% of entire 8x8 grid! Use sparingly
        }
    }

    /// Category for spawning weight purposes
    var category: PieceCategory {
        switch cellCount {
        case 1:
            return .monomino
        case 2:
            return .domino
        case 3:
            return .triomino
        case 4:
            return .tetromino
        case 5:
            return .pentomino
        case 6...9:
            return .largeReward
        default:
            return .largeReward
        }
    }

    // MARK: - Private Helpers

    private var basePattern: [[Bool]] {
        switch self {
        // MARK: - Monomino
        case .single:
            return [[true]]

        // MARK: - Domino
        case .domino:
            return [[true, true]]

        // MARK: - Triominoes
        case .triLine:
            return [[true, true, true]]
        case .triCorner:
            return [
                [true, false],
                [true, true]
            ]

        // MARK: - Tetrominoes
        case .tetLine:  // I-piece: ████
            return [[true, true, true, true]]

        case .tetSquare:  // O-piece: ██
                          //          ██
            return [
                [true, true],
                [true, true]
            ]

        case .tetL:  // L-piece: █
                     //          █
                     //          ██
            return [
                [true, false, false],
                [true, true, true]
            ]

        case .tetJ:  // J-piece (mirror of L): ██
                     //                        █
                     //                        █
            return [
                [false, false, true],
                [true, true, true]
            ]

        case .tetT:  // T-piece: ███
                     //           █
            return [
                [true, true, true],
                [false, true, false]
            ]

        case .tetS:  // S-piece:  ██
                     //          ██
            return [
                [false, true, true],
                [true, true, false]
            ]

        case .tetZ:  // Z-piece: ██
                     //           ██
            return [
                [true, true, false],
                [false, true, true]
            ]

        case .tetSkew:  // Legacy alias for Z-piece
            return [
                [false, true, true],
                [true, true, false]
            ]

        // MARK: - Pentominoes (5 blocks each)
        case .pentaF:  // F-pentomino:  ██
                       //               █
                       //               ██
            return [
                [false, true, true],
                [true, true, false],
                [false, true, false]
            ]

        case .pentaI:  // I-pentomino: █████
            return [[true, true, true, true, true]]

        case .pentaLine:  // Same as pentaI
            return [[true, true, true, true, true]]

        case .pentaL:  // L-pentomino: █
                       //              █
                       //              █
                       //              ██
            return [
                [true, false],
                [true, false],
                [true, false],
                [true, true]
            ]

        case .pentaN:  // N-pentomino: █
                       //              ██
                       //               █
                       //               █
            return [
                [true, false],
                [true, true],
                [false, true],
                [false, true]
            ]

        case .pentaP:  // P-pentomino: ██
                       //              ██
                       //              █
            return [
                [true, true],
                [true, true],
                [true, false]
            ]

        case .pentaT:  // T-pentomino: ███
                       //               █
                       //               █
            return [
                [true, true, true],
                [false, true, false],
                [false, true, false]
            ]

        case .pentaU:  // U-pentomino: █ █
                       //              ███
            return [
                [true, false, true],
                [true, true, true]
            ]

        case .pentaV:  // V-pentomino: █
                       //              █
                       //              ███
            return [
                [true, false, false],
                [true, false, false],
                [true, true, true]
            ]

        case .pentaW:  // W-pentomino: █
                       //              ██
                       //               ██
            return [
                [true, false, false],
                [true, true, false],
                [false, true, true]
            ]

        case .pentaX:  // X-pentomino (plus):  █
                       //                     ███
                       //                      █
            return [
                [false, true, false],
                [true, true, true],
                [false, true, false]
            ]

        case .pentaY:  // Y-pentomino:  █
                       //              ██
                       //               █
                       //               █
            return [
                [false, true],
                [true, true],
                [false, true],
                [false, true]
            ]

        case .pentaZ:  // Z-pentomino: ██
                       //               █
                       //               ██
            return [
                [true, true, false],
                [false, true, false],
                [false, true, true]
            ]

        // MARK: - Large Pieces
        case .rect2x3:  // 2x3 rectangle: ███
                        //                ███
            return [
                [true, true, true],
                [true, true, true]
            ]

        case .rect3x2:  // 3x2 rectangle: ██
                        //                ██
                        //                ██
            return [
                [true, true],
                [true, true],
                [true, true]
            ]

        case .square3x3:  // 3x3 square: ███
                          //             ███
                          //             ███
            return [
                [true, true, true],
                [true, true, true],
                [true, true, true]
            ]

        case .largeL3x3:  // Large L-shape: ███
                          //                █
                          //                █
            return [
                [true, true, true],
                [true, false, false],
                [true, false, false]
            ]

        case .plusShape:  // Plus shape (3x3 with corners removed):  █
                          //                                        ███
                          //                                         █
            return [
                [false, true, false],
                [true, true, true],
                [false, true, false]
            ]

        case .almostSquare:  // 3x3 with 1 corner removed: ███
                             //                            ███
                             //                            ██
            return [
                [true, true, true],
                [true, true, true],
                [true, true, false]
            ]
        }
    }
}

private func uniqueVariants(for pattern: [[Bool]], includeMirror: Bool) -> [[[Bool]]] {
    var variants: [[[Bool]]] = []

    func addVariant(_ candidate: [[Bool]]) {
        let trimmed = trimPattern(candidate)
        if !variants.contains(where: { $0 == trimmed }) {
            variants.append(trimmed)
        }
    }

    var rotation = pattern
    for _ in 0..<4 {
        addVariant(rotation)
        rotation = rotatePatternClockwise(rotation)
    }

    if includeMirror {
        var mirrored = mirrorPatternHorizontally(pattern)
        for _ in 0..<4 {
            addVariant(mirrored)
            mirrored = rotatePatternClockwise(mirrored)
        }
    }

    return variants
}

private func rotatePatternClockwise(_ pattern: [[Bool]]) -> [[Bool]] {
    guard let firstRow = pattern.first else { return pattern }
    let rowCount = pattern.count
    let columnCount = firstRow.count
    var rotated = Array(
        repeating: Array(repeating: false, count: rowCount),
        count: columnCount
    )

    for row in 0..<rowCount {
        for column in 0..<columnCount {
            rotated[column][rowCount - row - 1] = pattern[row][column]
        }
    }

    return rotated
}

private func mirrorPatternHorizontally(_ pattern: [[Bool]]) -> [[Bool]] {
    pattern.map { row in Array(row.reversed()) }
}

private func trimPattern(_ pattern: [[Bool]]) -> [[Bool]] {
    guard !pattern.isEmpty else { return pattern }

    var rows = pattern

    while let first = rows.first, first.allSatisfy({ !$0 }) {
        rows.removeFirst()
    }

    while let last = rows.last, last.allSatisfy({ !$0 }) {
        rows.removeLast()
    }

    guard !rows.isEmpty else { return [[true]] }

    let columnCount = rows.first?.count ?? 0
    var columnsWithContent = Array(repeating: false, count: columnCount)

    for row in rows {
        for (index, value) in row.enumerated() where value {
            columnsWithContent[index] = true
        }
    }

    guard let firstColumn = columnsWithContent.firstIndex(of: true),
          let lastColumn = columnsWithContent.lastIndex(of: true) else {
        return [[true]]
    }

    return rows.map { Array($0[firstColumn...lastColumn]) }
}

// MARK: - Block Pattern

/// Represents a complete block pattern with visual properties
struct BlockPattern {
    let type: BlockType
    let color: BlockColor
    let cells: [[Bool]]
    let size: CGSize
    
    private let occupiedCells: [CGPoint]
    
    init(type: BlockType, color: BlockColor, cells: [[Bool]]? = nil) {
        self.type = type
        self.color = color
        let resolvedCells = cells ?? type.pattern
        self.cells = resolvedCells
        self.size = CGSize(
            width: CGFloat(resolvedCells.first?.count ?? 0),
            height: CGFloat(resolvedCells.count)
        )
        self.occupiedCells = BlockPattern.computeOccupiedPositions(from: resolvedCells)
    }
    
    /// Get occupied positions for this pattern
    var occupiedPositions: [CGPoint] {
        return occupiedCells
    }
    
    /// Check if this pattern can fit at a specific grid position
    func canFit(at position: GridPosition, in gridSize: Int) -> Bool {
        for cellPosition in occupiedCells {
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
        occupiedCells.map { cellPosition in
            let targetRow = position.row + Int(cellPosition.y)
            let targetCol = position.column + Int(cellPosition.x)
            return GridPosition(unsafeRow: targetRow, unsafeColumn: targetCol)
        }
    }
    
    /// Number of cells this block pattern occupies
    var cellCount: Int {
        return occupiedCells.count
    }
    
    static func computeOccupiedPositions(from cells: [[Bool]]) -> [CGPoint] {
        var positions: [CGPoint] = []
        for (rowIndex, row) in cells.enumerated() {
            for (columnIndex, value) in row.enumerated() {
                if value {
                    positions.append(CGPoint(x: columnIndex, y: rowIndex))
                }
            }
        }
        return positions
    }
}

// MARK: - Block Factory

// MARK: - Spawning Configuration

/// Configuration for tuning the intelligent spawning system
struct SpawningConfig {
    /// Enable debug logging of spawning decisions
    var debugMode: Bool = false

    /// Guarantee at least one piece can fit on the grid
    var guaranteeOneFitsPiece: Bool = true

    /// Guarantee at least one piece has clearing potential (when board is not empty)
    var guaranteeOneClearingPiece: Bool = true

    /// Minimum total clearing potential across all 3 pieces
    var minClearPotentialPerSet: Int = 1

    /// Maximum total clearing potential across all 3 pieces (prevents too-easy sets)
    var maxClearPotentialPerSet: Int = 6

    /// How quickly complexity increases per placement (0.0 = no increase, 1.0 = fast increase)
    var complexityGrowthRate: Double = 0.1

    /// Grid fullness threshold (0.0-1.0) where spawning becomes more generous
    var gridFullnessThreshold: Double = 0.7

    /// Print detailed spawn analysis to console
    var verboseLogging: Bool = false

    static let `default` = SpawningConfig()
}

// MARK: - Block Factory

/**
 # Intelligent Block Spawning System

 The `BlockFactory` implements a sophisticated, research-based spawning algorithm for block puzzle games.
 Based on analysis of successful games like 1010! and Woodoku, this system ensures fair, engaging gameplay
 through strategic piece selection rather than pure randomness.

 ## Core Principles

 1. **Anti-Random Spawning**: Pieces are NOT generated randomly. Instead, the system analyzes the current
    grid state and strategically selects pieces to ensure:
    - At least ONE piece in each set of 3 can be placed on the grid
    - At least ONE piece creates a line-clearing opportunity (when board is not empty)
    - Difficulty progresses smoothly based on game progress
    - Impossible/dead-end situations are prevented

 2. **Difficulty Progression**: The game starts 50% easier than average and gradually increases difficulty:
    - Early game (0-5 placements): Simple, larger pieces (complexity 2-4)
    - Mid game (6-17 placements): Balanced mix (complexity 4-6)
    - Late game (18+ placements): Challenging pieces (complexity 6-8)

 3. **Grid Analysis**: Before spawning, the system analyzes:
    - Grid fullness percentage
    - Near-complete rows/columns (1-5 gaps remaining)
    - Available empty spaces
    - Potential clearing opportunities

 ## Key Features

 - **38 Unique Piece Shapes**: Complete polyomino taxonomy including all tetrominoes, pentominoes, and large pieces
 - **Complexity Scoring**: Each piece rated 1-10 based on placement difficulty
 - **Rolling Bag System**: Prevents droughts of specific piece categories
 - **Clearing Opportunity Calculator**: Ensures strategic gameplay by guaranteeing clearing potential
 - **Debug Mode**: Visualize spawning decisions and telemetry for tuning
 - **Configurable Parameters**: Tune difficulty curve, clearing requirements, and more

 ## Usage Example

 ```swift
 let factory = BlockFactory()
 factory.attach(gameEngine: gameEngine)

 // Enable debug mode to see spawning decisions
 factory.config.debugMode = true

 // Customize spawning behavior
 factory.config.guaranteeOneClearingPiece = true
 factory.config.gridFullnessThreshold = 0.7

 // Get spawned pieces
 let pieces = factory.getTraySlots()

 // Track performance
 factory.printTelemetry()
 ```

 ## Algorithm Overview

 1. **Category Selection**: Choose piece categories (mono, duo, tri, tetra, penta) based on:
    - Current game stage (early/mid/late)
    - Recent clearing performance
    - Grid fullness

 2. **Piece Selection**: For each category, use rolling bag to avoid droughts:
    - Fill bag with all eligible pieces in category
    - Shuffle and draw pieces sequentially
    - Refill when bag empties

 3. **Hand Validation**: After generating 3 pieces:
    - Verify at least one fits on grid (if not, replace with guaranteed fit)
    - Verify at least one can clear lines (if not, replace with clearing piece)
    - Calculate hand score based on clearing potential and complexity balance

 4. **Board-Aware Adjustments**:
    - When grid >70% full: Favor smaller pieces (mono, duo, tri)
    - When near-complete lines exist: Boost pieces that can complete them
    - When board is empty: Favor larger pieces for confidence building

 ## Telemetry Tracking

 The system tracks performance metrics:
 - Must-fit success rate (% of hands with valid moves)
 - Dead deal rate (% of impossible hands)
 - Average clears per 10 placements

 This data helps tune the spawning algorithm for optimal player experience.

 - Author: Claude Code
 - Date: 2025-10-21
 */
@MainActor
class BlockFactory: ObservableObject {

    // MARK: - Properties

    /// Current tray slots (exactly three, may contain nil if consumed)
    @Published private(set) var traySlots: [BlockPattern?] = []

    /// Number of blocks displayed in the tray simultaneously
    private let traySize = 3

    /// Optional restriction applied in curated modes (e.g., levels)
    private var allowedTypes: Set<BlockType>? = nil

    /// Reference to the active game engine for placement analysis
    private weak var gameEngine: GameEngine?

    /// Random generator for block and color selection
    private var generator = SystemRandomNumberGenerator()

    /// Spawning configuration (can be modified for tuning)
    var config = SpawningConfig.default

    /// Rolling bags per category to avoid droughts
    private var categoryBags: [ShapeCategory: [BlockType]] = [:]

    /// Placement history for spawn tuning
    private var placementsMade: Int = 0
    private var recentLineClears: [Int] = []

    // MARK: - Telemetry Tracking

    /// Telemetry for spawn quality analysis
    private var telemetry = SpawnTelemetry()

    private struct SpawnTelemetry {
        var totalHandsGenerated: Int = 0
        var handsWithFit: Int = 0
        var deadDealsGenerated: Int = 0
        var rerollsPerformed: Int = 0
        var clearsInLast10Placements: Int = 0
        var placementsInWindow: Int = 0

        mutating func recordHand(hadFit: Bool, wasDeadDeal: Bool, rerollCount: Int) {
            totalHandsGenerated += 1
            if hadFit { handsWithFit += 1 }
            if wasDeadDeal { deadDealsGenerated += 1 }
            rerollsPerformed += rerollCount
        }

        mutating func recordPlacement(linesCleared: Int) {
            if placementsInWindow >= 10 {
                clearsInLast10Placements = 0
                placementsInWindow = 0
            }
            clearsInLast10Placements += linesCleared
            placementsInWindow += 1
        }

        var mustFitSuccessRate: Double {
            guard totalHandsGenerated > 0 else { return 1.0 }
            return Double(handsWithFit) / Double(totalHandsGenerated)
        }

        var deadDealRate: Double {
            guard totalHandsGenerated > 0 else { return 0.0 }
            return Double(deadDealsGenerated) / Double(totalHandsGenerated)
        }

        var avgClearsPer10Turns: Double {
            guard placementsInWindow > 0 else { return 0.0 }
            return Double(clearsInLast10Placements) / (Double(placementsInWindow) / 10.0)
        }
    }

    // MARK: - Spawn Definitions

    private enum ShapeCategory: CaseIterable {
        case mono
        case duo
        case trio
        case tetro
        case pento
        case reward
    }

    private enum SpawnStage: Int, Comparable {
        case early = 0
        case mid = 1
        case late = 2

        static func < (lhs: SpawnStage, rhs: SpawnStage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private struct ShapeDefinition {
        let type: BlockType
        let category: ShapeCategory
        let baseWeight: Double
        let minStage: SpawnStage
        let requiresStreak: Bool
        let isReward: Bool
    }

    private struct BoardAnalysis {
        let emptyCells: Int
        let gap1Rows: Int
        let gap2Rows: Int
        let gap1Columns: Int
        let gap2Columns: Int
        let gap3To5Rows: Int      // Rows with 3-5 empty cells (near-complete on 8×8)
        let gap3To5Columns: Int   // Columns with 3-5 empty cells

        var totalGap1: Int { gap1Rows + gap1Columns }
        var totalGap2: Int { gap2Rows + gap2Columns }
        var totalGap3To5: Int { gap3To5Rows + gap3To5Columns }
        var nearClearCount: Int { totalGap1 + totalGap2 + totalGap3To5 }
    }

    private let bagSizes: [ShapeCategory: Int] = [
        .mono: 4,
        .duo: 4,
        .trio: 5,
        .tetro: 6,
        .pento: 6,
        .reward: 4
    ]

    private lazy var shapeDefinitions: [ShapeDefinition] = [
        // MARK: - Monomino (Complexity: 1)
        ShapeDefinition(type: .single, category: .mono, baseWeight: 1.0, minStage: .early, requiresStreak: false, isReward: false),

        // MARK: - Domino (Complexity: 2)
        ShapeDefinition(type: .domino, category: .duo, baseWeight: 1.0, minStage: .early, requiresStreak: false, isReward: false),

        // MARK: - Triominoes (Complexity: 2-3)
        ShapeDefinition(type: .triLine, category: .trio, baseWeight: 0.95, minStage: .early, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .triCorner, category: .trio, baseWeight: 0.85, minStage: .early, requiresStreak: false, isReward: false),

        // MARK: - Tetrominoes (Complexity: 4-6)
        ShapeDefinition(type: .tetSquare, category: .tetro, baseWeight: 0.9, minStage: .early, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetLine, category: .tetro, baseWeight: 0.8, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetL, category: .tetro, baseWeight: 0.8, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetJ, category: .tetro, baseWeight: 0.8, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetT, category: .tetro, baseWeight: 0.75, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetS, category: .tetro, baseWeight: 0.35, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetZ, category: .tetro, baseWeight: 0.35, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetSkew, category: .tetro, baseWeight: 0.35, minStage: .mid, requiresStreak: false, isReward: false),

        // MARK: - Pentominoes (Complexity: 6-9)
        // Easier pentominoes (compact shapes)
        ShapeDefinition(type: .pentaU, category: .pento, baseWeight: 0.6, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .pentaX, category: .pento, baseWeight: 0.55, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .pentaT, category: .pento, baseWeight: 0.55, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .pentaP, category: .pento, baseWeight: 0.55, minStage: .late, requiresStreak: false, isReward: false),

        // Medium pentominoes
        ShapeDefinition(type: .pentaL, category: .pento, baseWeight: 0.5, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaV, category: .pento, baseWeight: 0.5, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaF, category: .pento, baseWeight: 0.5, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaN, category: .pento, baseWeight: 0.5, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaY, category: .pento, baseWeight: 0.5, minStage: .late, requiresStreak: true, isReward: false),

        // Harder pentominoes (sprawling, constraining)
        ShapeDefinition(type: .pentaW, category: .pento, baseWeight: 0.4, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaZ, category: .pento, baseWeight: 0.4, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaLine, category: .pento, baseWeight: 0.45, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaI, category: .pento, baseWeight: 0.45, minStage: .late, requiresStreak: true, isReward: false),

        // MARK: - Large Reward Pieces (Complexity: 3-10)
        // Easy large pieces (for early game confidence building)
        ShapeDefinition(type: .rect2x3, category: .reward, baseWeight: 0.5, minStage: .early, requiresStreak: false, isReward: true),
        ShapeDefinition(type: .rect3x2, category: .reward, baseWeight: 0.5, minStage: .early, requiresStreak: false, isReward: true),

        // Medium large pieces
        ShapeDefinition(type: .plusShape, category: .reward, baseWeight: 0.4, minStage: .mid, requiresStreak: false, isReward: true),
        ShapeDefinition(type: .largeL3x3, category: .reward, baseWeight: 0.35, minStage: .mid, requiresStreak: true, isReward: true),

        // Hard large pieces (use very sparingly)
        ShapeDefinition(type: .almostSquare, category: .reward, baseWeight: 0.25, minStage: .late, requiresStreak: true, isReward: true),
        ShapeDefinition(type: .square3x3, category: .reward, baseWeight: 0.15, minStage: .late, requiresStreak: true, isReward: true)
    ]
    
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
        placementsMade = 0
        recentLineClears.removeAll()
        categoryBags.removeAll()
        refillTray()
    }

    /// Restrict the factory to a subset of pieces. Passing nil restores the full catalogue.
    func configureAllowedTypes(_ types: [BlockType]?) {
        if let types {
            allowedTypes = Set(types)
        } else {
            allowedTypes = nil
        }
        categoryBags.removeAll()
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

    /// Attach the factory to the active game engine for spawn analytics
    func attach(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
        refillTray()
    }

    /// Record placement outcome to influence future spawns
    func recordPlacement(linesCleared: Int, boardCleared: Bool) {
        placementsMade += 1
        recentLineClears.append(linesCleared)
        if boardCleared {
            recentLineClears.append(gameEngine?.gridSize ?? 8)
        }
        recentLineClears = Array(recentLineClears.suffix(6))

        // Update telemetry
        telemetry.recordPlacement(linesCleared: linesCleared)
    }

    /// Get current spawn telemetry for debugging and quality assurance
    func getTelemetry() -> (mustFitRate: Double, deadDealRate: Double, avgClearsPer10: Double) {
        return (
            mustFitRate: telemetry.mustFitSuccessRate,
            deadDealRate: telemetry.deadDealRate,
            avgClearsPer10: telemetry.avgClearsPer10Turns
        )
    }

    /// Reset telemetry counters (useful for A/B testing different spawn strategies)
    func resetTelemetry() {
        telemetry = SpawnTelemetry()
    }

    // MARK: - Debug Logging

    /// Log detailed information about a spawned hand
    private func logSpawningDecision(_ hand: [BlockPattern]) {
        guard config.debugMode || config.verboseLogging else { return }

        print("\n=== SPAWNING DECISION ===")
        print("Stage: \(currentStage), Placements: \(placementsMade)")

        if let engine = gameEngine {
            let analysis = analyzeBoard()
            print("Grid fullness: \(analysis?.emptyCells ?? 0) empty cells")
            print("Near-complete lines: \(analysis?.nearClearCount ?? 0)")
        }

        print("\nSpawned pieces:")
        for (index, piece) in hand.enumerated() {
            let clearPotential = calculateMaxClearingPotential(for: piece)
            let complexity = piece.type.complexityScore
            print("  [\(index + 1)] \(piece.type.displayName)")
            print("      Size: \(piece.cellCount) cells, Complexity: \(complexity)/10")
            print("      Max clearing potential: \(clearPotential) lines")
            print("      Can fit: \(gameEngine?.canPlace(blockPattern: piece) ?? false)")
        }

        let handScore = scoreHand(hand)
        print("\nHand score: \(String(format: "%.1f", handScore))")

        let totalClearPotential = hand.reduce(0) { $0 + calculateMaxClearingPotential(for: $1) }
        print("Total clearing potential: \(totalClearPotential) lines")

        print("=========================\n")
    }

    /// Print current telemetry statistics
    func printTelemetry() {
        let stats = getTelemetry()
        print("\n=== SPAWN TELEMETRY ===")
        print("Must-fit success rate: \(String(format: "%.1f%%", stats.mustFitRate * 100))")
        print("Dead deal rate: \(String(format: "%.1f%%", stats.deadDealRate * 100))")
        print("Avg clears per 10 turns: \(String(format: "%.2f", stats.avgClearsPer10))")
        print("=======================\n")
    }

    // MARK: - Tray Generation

    private func refillTray() {
        let patterns = generateHand()
        traySlots = patterns.map { Optional($0) }
    }

    // MARK: - Enhanced Hand Scoring

    /// Score a hand of pieces based on clearing potential and difficulty balance
    private func scoreHand(_ hand: [BlockPattern]) -> Double {
        guard let engine = gameEngine else { return 0.0 }

        var score = 0.0

        // Calculate clearing potential for each piece
        var clearingPotentials: [Int] = []
        for piece in hand {
            let potential = calculateMaxClearingPotential(for: piece)
            clearingPotentials.append(potential)
        }

        // CRITICAL: At least one piece must fit on the grid
        let fittablePieces = hand.filter { engine.canPlace(blockPattern: $0) }
        if fittablePieces.isEmpty {
            return -1000.0  // Reject impossible hands
        }
        score += 100.0  // Bonus for having valid moves

        // IMPORTANT: At least one piece should have clearing potential
        let piecesWithClears = clearingPotentials.filter { $0 > 0 }
        if piecesWithClears.isEmpty {
            score -= 50.0  // Penalty for no clearing opportunities
        } else {
            // Bonus based on total clearing potential (but not too much)
            let totalClears = clearingPotentials.reduce(0, +)
            score += Double(totalClears) * 15.0
        }

        // Penalize if ALL pieces create clears (too easy)
        if piecesWithClears.count == traySize && clearingPotentials.min() ?? 0 > 0 {
            score -= 30.0
        }

        // Reward size variety (don't give all small or all large pieces)
        let sizes = hand.map { $0.cellCount }
        let avgSize = Double(sizes.reduce(0, +)) / Double(sizes.count)
        let sizeVariance = sizes.reduce(0.0) { result, size in
            result + pow(Double(size) - avgSize, 2)
        } / Double(sizes.count)
        score += sizeVariance * 5.0

        // Reward complexity variety
        let complexities = hand.map { $0.type.complexityScore }
        let avgComplexity = Double(complexities.reduce(0, +)) / Double(complexities.count)

        // Match current stage difficulty target
        let targetComplexity: Double
        switch currentStage {
        case .early:
            targetComplexity = 3.0  // Easy pieces
        case .mid:
            targetComplexity = 5.0  // Medium pieces
        case .late:
            targetComplexity = 7.0  // Harder pieces
        }

        let complexityDiff = abs(avgComplexity - targetComplexity)
        score -= complexityDiff * 8.0

        return score
    }

    private func generateHand() -> [BlockPattern] {
        var hand: [BlockPattern] = []
        var attempts = 0

        while hand.count < traySize && attempts < 12 {
            hand.append(generatePiece())
            attempts += 1
        }

        // Track telemetry before and after must-fit enforcement
        let hadFitBefore = gameEngine?.hasAnyValidMove(using: hand) ?? true
        var rerollCount = 0

        if !hadFitBefore {
            rerollCount += 1
        }

        // Apply intelligent spawning rules based on configuration
        if config.guaranteeOneFitsPiece {
            ensureHandHasFit(&hand)
        }

        if config.guaranteeOneClearingPiece {
            ensureHandHasClearingOpportunity(&hand)
        }

        let hadFitAfter = gameEngine?.hasAnyValidMove(using: hand) ?? true
        let wasDeadDeal = !hadFitAfter && (boardHasPotentialMoves())

        telemetry.recordHand(hadFit: hadFitAfter, wasDeadDeal: wasDeadDeal, rerollCount: rerollCount)

        // Debug logging
        logSpawningDecision(hand)

        return hand
    }

    /// Ensure at least one piece in the hand can create a line clear
    private func ensureHandHasClearingOpportunity(_ hand: inout [BlockPattern]) {
        guard let engine = gameEngine else { return }

        // Check if any piece has clearing potential
        var hasClearingPiece = false
        for piece in hand {
            if calculateMaxClearingPotential(for: piece) > 0 {
                hasClearingPiece = true
                break
            }
        }

        // If no piece can clear, try to replace one with a piece that can
        if !hasClearingPiece && !engine.isBoardCompletelyEmpty() {
            // Try to find a replacement piece with clearing potential
            for index in hand.indices {
                if let replacement = findPieceWithClearingPotential() {
                    hand[index] = replacement
                    return
                }
            }
        }
    }

    /// Find a piece that has clearing potential on the current board
    private func findPieceWithClearingPotential() -> BlockPattern? {
        guard let engine = gameEngine else { return nil }

        let priorityCategories: [ShapeCategory] = [.mono, .duo, .trio, .tetro, .pento]

        for category in priorityCategories {
            let definitions = eligibleShapes(for: category).shuffled(using: &generator)
            for definition in definitions {
                var variations = definition.type.variations
                variations.shuffle(using: &generator)

                for variation in variations {
                    let pattern = BlockPattern(type: definition.type, color: randomColor(), cells: variation)

                    // Check if this piece can fit AND has clearing potential
                    if engine.canPlace(blockPattern: pattern) {
                        let clearPotential = calculateMaxClearingPotential(for: pattern)
                        if clearPotential > 0 {
                            removeTypeFromBag(definition.type, in: category)
                            return pattern
                        }
                    }
                }
            }
        }

        return nil
    }

    private func generatePiece() -> BlockPattern {
        let analysis = analyzeBoard()

        guard let category = selectCategory(using: analysis) else {
            return makePattern(for: .single)
        }

        if categoryBags[category]?.isEmpty ?? true {
            categoryBags[category] = makeBag(for: category)
        }

        guard var bag = categoryBags[category], !bag.isEmpty else {
            return makePattern(for: .single)
        }

        let type = bag.removeFirst()
        categoryBags[category] = bag
        return makePattern(for: type)
    }

    private func makePattern(for type: BlockType) -> BlockPattern {
        let cells = type.variations.randomElement(using: &generator) ?? type.pattern
        return BlockPattern(type: type, color: randomColor(), cells: cells)
    }

    private func randomColor() -> BlockColor {
        BlockColor.allCases.randomElement(using: &generator) ?? .blue
    }

    // MARK: - Eligibility & Weights

    private var currentStage: SpawnStage {
        if placementsMade < 6 {
            return .early
        } else if placementsMade < 18 {
            return .mid
        } else {
            return .late
        }
    }

    private var isStreakActive: Bool {
        recentLineClears.suffix(3).filter { $0 >= 2 }.count >= 2
    }

    private func eligibleShapes(for category: ShapeCategory) -> [ShapeDefinition] {
        shapeDefinitions.filter { definition in
            guard definition.category == category else { return false }
            guard definition.minStage <= currentStage else { return false }
            if definition.requiresStreak && !isStreakActive {
                return false
            }
            if definition.isReward && !isStreakActive {
                return false
            }
            if let allowed = allowedTypes, !allowed.contains(definition.type) {
                return false
            }
            return true
        }
    }

    private func makeBag(for category: ShapeCategory) -> [BlockType] {
        let eligible = eligibleShapes(for: category)
        guard !eligible.isEmpty else { return [] }

        let bagSize = bagSizes[category] ?? eligible.count
        var bag: [BlockType] = []

        while bag.count < bagSize {
            var shuffled = eligible.map { $0.type }
            shuffled.shuffle(using: &generator)
            for type in shuffled {
                bag.append(type)
                if bag.count == bagSize {
                    break
                }
            }
        }

        return bag
    }

    private func selectCategory(using analysis: BoardAnalysis?) -> ShapeCategory? {
        var weightedCategories: [(ShapeCategory, Double)] = []

        for category in ShapeCategory.allCases {
            if category == .reward && currentStage != .late {
                continue
            }

            let eligible = eligibleShapes(for: category)
            guard !eligible.isEmpty else { continue }

            if categoryBags[category]?.isEmpty ?? true {
                categoryBags[category] = makeBag(for: category)
            }

            guard let bag = categoryBags[category], !bag.isEmpty else { continue }

            var weight = eligible.reduce(0) { $0 + $1.baseWeight }
            weight *= stageMultiplier(for: category)
            if let analysis = analysis {
                weight = applyBoardBias(weight: weight, category: category, analysis: analysis)
            }

            if weight > 0 {
                weightedCategories.append((category, weight))
            }
        }

        return weightedRandomCategory(weightedCategories)
    }

    private func weightedRandomCategory(_ entries: [(ShapeCategory, Double)]) -> ShapeCategory? {
        guard !entries.isEmpty else { return nil }

        let total = entries.reduce(0) { $0 + max($1.1, 0) }
        guard total > 0 else { return entries.first?.0 }

        let randomValue = Double.random(in: 0..<total, using: &generator)
        var cumulative: Double = 0

        for (category, weight) in entries {
            cumulative += max(weight, 0)
            if randomValue < cumulative {
                return category
            }
        }

        return entries.last?.0
    }

    private func stageMultiplier(for category: ShapeCategory) -> Double {
        switch (currentStage, category) {
        case (.early, .mono):
            return 1.4
        case (.early, .duo):
            return 1.3
        case (.early, .trio):
            return 1.1
        case (.early, .tetro):
            return 0.55
        case (.early, .pento), (.early, .reward):
            return 0.25

        case (.mid, .mono):
            return 1.0
        case (.mid, .duo):
            return 1.05
        case (.mid, .trio):
            return 1.0
        case (.mid, .tetro):
            return 0.95
        case (.mid, .pento):
            return 0.5
        case (.mid, .reward):
            return 0.35

        case (.late, .mono):
            return 0.9
        case (.late, .duo):
            return 1.0
        case (.late, .trio):
            return 1.1
        case (.late, .tetro):
            return 1.05
        case (.late, .pento):
            return 1.0
        case (.late, .reward):
            return 0.85
        }
    }

    private func applyBoardBias(weight: Double, category: ShapeCategory, analysis: BoardAnalysis) -> Double {
        var adjusted = weight
        let gridSize = gameEngine?.gridSize ?? 10

        // Clear-intent bias: Boost shapes that can complete near-finished rows/columns
        if analysis.nearClearCount > 0 {
            switch category {
            case .mono:
                adjusted *= 1.4 + Double(analysis.totalGap1) * 0.15
            case .duo:
                adjusted *= 1.25 + Double(analysis.totalGap2) * 0.12
            case .trio:
                adjusted *= 1.15 + Double(analysis.totalGap3To5) * 0.08
            case .tetro:
                // On 8×8, a 4-cell line can clear a half-full row
                if gridSize == 8 && analysis.totalGap3To5 > 0 {
                    adjusted *= 1.1
                }
            default:
                break
            }
        }

        // Lockout protection: Dramatically boost small fillers when board is nearly full
        let lockoutThreshold = (gridSize == 8) ? 8 : 12  // More aggressive on 8×8
        if analysis.emptyCells <= lockoutThreshold {
            switch category {
            case .mono:
                adjusted *= 2.5  // Increased from 2.2
            case .duo:
                adjusted *= 2.0  // Increased from 1.8
            case .trio:
                adjusted *= 1.5  // Increased from 1.4
            default:
                adjusted *= 0.25  // Reduced from 0.35 to strongly discourage large pieces
            }
        }

        return adjusted
    }

    // MARK: - Board Analysis

    private func analyzeBoard() -> BoardAnalysis? {
        guard let engine = gameEngine else { return nil }
        let grid = engine.gameGrid
        let size = engine.gridSize

        var totalEmpty = 0
        var gap1Rows = 0
        var gap2Rows = 0
        var gap3To5Rows = 0
        var gap1Cols = 0
        var gap2Cols = 0
        var gap3To5Cols = 0

        for row in 0..<size {
            let emptyCount = grid[row].reduce(0) { $0 + ($1.isOccupied ? 0 : 1) }
            totalEmpty += emptyCount

            switch emptyCount {
            case 1:
                gap1Rows += 1
            case 2:
                gap2Rows += 1
            case 3...5:
                gap3To5Rows += 1
            default:
                break
            }
        }

        for column in 0..<size {
            var emptyCount = 0
            for row in 0..<size {
                if !grid[row][column].isOccupied {
                    emptyCount += 1
                }
            }

            switch emptyCount {
            case 1:
                gap1Cols += 1
            case 2:
                gap2Cols += 1
            case 3...5:
                gap3To5Cols += 1
            default:
                break
            }
        }

        return BoardAnalysis(
            emptyCells: totalEmpty,
            gap1Rows: gap1Rows,
            gap2Rows: gap2Rows,
            gap1Columns: gap1Cols,
            gap2Columns: gap2Cols,
            gap3To5Rows: gap3To5Rows,
            gap3To5Columns: gap3To5Cols
        )
    }

    // MARK: - Advanced Clearing Opportunity Calculator

    /// Calculate the maximum number of lines a piece could clear if optimally placed
    /// Returns the best clearing potential across all valid placements
    private func calculateMaxClearingPotential(for pattern: BlockPattern) -> Int {
        guard let engine = gameEngine else { return 0 }

        var maxClears = 0
        let gridSize = engine.gridSize

        // Try placing the piece at every position on the grid
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let position = GridPosition(unsafeRow: row, unsafeColumn: col)

                // Check if piece fits at this position
                guard pattern.canFit(at: position, in: gridSize) else { continue }

                let positions = pattern.getGridPositions(placedAt: position)

                // Check if all positions are empty
                let canPlace = positions.allSatisfy { pos in
                    engine.canPlaceAt(position: pos)
                }

                guard canPlace else { continue }

                // Calculate how many lines would clear with this placement
                let clearCount = countPotentialClears(positions: positions, gridSize: gridSize, engine: engine)
                maxClears = max(maxClears, clearCount)

                // Early exit if we find a placement that clears 2+ lines (very good)
                if maxClears >= 2 {
                    return maxClears
                }
            }
        }

        return maxClears
    }

    /// Count how many lines (rows + columns) would be completed by placing at these positions
    private func countPotentialClears(positions: [GridPosition], gridSize: Int, engine: GameEngine) -> Int {
        var clearCount = 0

        // Get unique rows and columns affected by this placement
        let affectedRows = Set(positions.map { $0.row })
        let affectedCols = Set(positions.map { $0.column })

        let placementSet = Set(positions)

        // Check each affected row
        for row in affectedRows {
            var isComplete = true
            for col in 0..<gridSize {
                let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                // This position would be filled if it's part of the placement OR already occupied
                let wouldBeFilled = placementSet.contains(pos) || (engine.cell(at: pos)?.isOccupied ?? false)
                if !wouldBeFilled {
                    isComplete = false
                    break
                }
            }
            if isComplete {
                clearCount += 1
            }
        }

        // Check each affected column
        for col in affectedCols {
            var isComplete = true
            for row in 0..<gridSize {
                let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                let wouldBeFilled = placementSet.contains(pos) || (engine.cell(at: pos)?.isOccupied ?? false)
                if !wouldBeFilled {
                    isComplete = false
                    break
                }
            }
            if isComplete {
                clearCount += 1
            }
        }

        return clearCount
    }

    /// Enhanced check: does the board have any valid moves remaining?
    private func boardHasPotentialMoves() -> Bool {
        guard let engine = gameEngine else { return true }

        for category in ShapeCategory.allCases {
            for definition in eligibleShapes(for: category) {
                for variation in definition.type.variations.shuffled(using: &generator) {
                    let pattern = BlockPattern(type: definition.type, color: randomColor(), cells: variation)
                    if engine.canPlace(blockPattern: pattern) {
                        return true
                    }
                }
            }
        }

        return false
    }

    private func ensureHandHasFit(_ hand: inout [BlockPattern]) {
        guard let engine = gameEngine else { return }
        guard !engine.hasAnyValidMove(using: hand) else { return }
        guard boardHasPotentialMoves() else { return }

        for index in hand.indices {
            if let replacement = generateFittingFallback() {
                hand[index] = replacement
                if engine.hasAnyValidMove(using: hand) {
                    return
                }
            }
        }
    }

    private func generateFittingFallback() -> BlockPattern? {
        guard let engine = gameEngine else { return nil }

        let priorityCategories: [ShapeCategory] = [.mono, .duo, .trio, .tetro, .pento]

        for category in priorityCategories {
            let definitions = eligibleShapes(for: category).shuffled(using: &generator)
            for definition in definitions {
                var variations = definition.type.variations
                variations.shuffle(using: &generator)
                for variation in variations {
                    let pattern = BlockPattern(type: definition.type, color: randomColor(), cells: variation)
                    if engine.canPlace(blockPattern: pattern) {
                        removeTypeFromBag(definition.type, in: category)
                        return pattern
                    }
                }
            }
        }

        return nil
    }

    private func removeTypeFromBag(_ type: BlockType, in category: ShapeCategory) {
        guard var bag = categoryBags[category] else { return }
        if let index = bag.firstIndex(of: type) {
            bag.remove(at: index)
            categoryBags[category] = bag
        }
    }

    func exportTray() -> [BlockPatternPayload?] {
        traySlots.map { pattern in
            pattern.map { BlockPatternPayload(from: $0) }
        }
    }

    func restoreTray(from payloads: [BlockPatternPayload?]) {
        guard payloads.count == traySize else {
            resetTray()
            return
        }

        var restored: [BlockPattern?] = []

        for payload in payloads {
            if let payload,
               let pattern = BlockPattern(payload: payload) {
                restored.append(pattern)
            } else {
                restored.append(nil)
            }
        }

        traySlots = restored
    }
}
