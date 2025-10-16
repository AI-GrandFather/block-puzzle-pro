import Foundation
import SpriteKit

// MARK: - Block Type Model

/// Defines the different types of blocks available in the game
enum BlockType: String, CaseIterable, Identifiable, Codable {
    case single
    case domino
    case triLine
    case triCorner
    case tetLine
    case tetSquare
    case tetL
    case tetT
    case tetSkew
    case almostSquare
    case pentaLine
    case pentaL
    case pentaP
    case pentaU
    case pentaV
    case pentaW

    var id: String { rawValue }
    
    init?(rawValue: String) {
        switch rawValue {
        case "single":
            self = .single
        case "horizontal", "vertical", "domino":
            self = .domino
        case "lineThree", "lineThreeVertical", "triLine":
            self = .triLine
        case "lShape":
            self = .triCorner
        case "tShape":
            self = .tetT
        case "zigZag":
            self = .tetSkew
        case "square", "tetSquare":
            self = .tetSquare
        case "lineFourVertical", "tetLine":
            self = .tetLine
        case "rectangleTwoByThree", "rectangleThreeByTwo":
            self = .tetL
        case "plus":
            self = .pentaU
        case "squareThree":
            self = .almostSquare
        case "almostSquare":
            self = .almostSquare
        case "pentaLine":
            self = .pentaLine
        case "pentaL":
            self = .pentaL
        case "pentaP":
            self = .pentaP
        case "pentaU":
            self = .pentaU
        case "pentaV":
            self = .pentaV
        case "pentaW":
            self = .pentaW
        case "triCorner":
            self = .triCorner
        case "triLine":
            self = .triLine
        case "tetSquare":
            self = .tetSquare
        case "tetL":
            self = .tetL
        case "tetT":
            self = .tetT
        case "tetSkew":
            self = .tetSkew
        case "domino":
            self = .domino
        default:
            return nil
        }
    }

    var rawValue: String {
        switch self {
        case .single: return "single"
        case .domino: return "domino"
        case .triLine: return "triLine"
        case .triCorner: return "triCorner"
        case .tetLine: return "tetLine"
        case .tetSquare: return "tetSquare"
        case .tetL: return "tetL"
        case .tetT: return "tetT"
        case .tetSkew: return "tetSkew"
        case .almostSquare: return "almostSquare"
        case .pentaLine: return "pentaLine"
        case .pentaL: return "pentaL"
        case .pentaP: return "pentaP"
        case .pentaU: return "pentaU"
        case .pentaV: return "pentaV"
        case .pentaW: return "pentaW"
        }
    }

    /// Human readable name for accessibility and UI
    var displayName: String {
        switch self {
        case .single:
            return "Single Block"
        case .domino:
            return "Domino"
        case .triLine:
            return "Triple Bar"
        case .triCorner:
            return "Corner Trio"
        case .tetLine:
            return "Quad Bar"
        case .tetSquare:
            return "Square"
        case .tetL:
            return "L Tetromino"
        case .tetT:
            return "T Tetromino"
        case .tetSkew:
            return "Skew Tetromino"
        case .almostSquare:
            return "Missing Corner Block"
        case .pentaLine:
            return "Long Pentomino"
        case .pentaL:
            return "L Pentomino"
        case .pentaP:
            return "P Pentomino"
        case .pentaU:
            return "U Pentomino"
        case .pentaV:
            return "V Pentomino"
        case .pentaW:
            return "W Pentomino"
        }
    }
    
    /// Default orientation pattern
    var pattern: [[Bool]] {
        basePattern
    }

    /// All unique orientations (rotation + optional mirror) trimmed to bounding box
    var variations: [[[Bool]]] {
        switch self {
        case .single, .domino, .triLine, .tetLine, .tetSquare, .tetT, .pentaLine, .pentaU:
            return uniqueVariants(for: basePattern, includeMirror: false)
        case .triCorner, .almostSquare:
            return uniqueVariants(for: basePattern, includeMirror: false)
        case .tetL, .tetSkew, .pentaL, .pentaP, .pentaV, .pentaW:
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

    // MARK: - Private Helpers

    private var basePattern: [[Bool]] {
        switch self {
        case .single:
            return [[true]]
        case .domino:
            return [[true, true]]
        case .triLine:
            return [[true, true, true]]
        case .triCorner:
            return [
                [true, false],
                [true, true]
            ]
        case .tetLine:
            return [[true, true, true, true]]
        case .tetSquare:
            return [
                [true, true],
                [true, true]
            ]
        case .tetL:
            return [
                [true, false, false],
                [true, true, true]
            ]
        case .tetT:
            return [
                [true, true, true],
                [false, true, false]
            ]
        case .tetSkew:
            return [
                [false, true, true],
                [true, true, false]
            ]
        case .almostSquare:
            return [
                [true, true, true],
                [true, true, true],
                [true, true, false]
            ]
        case .pentaLine:
            return [[true, true, true, true, true]]
        case .pentaL:
            return [
                [true, false],
                [true, false],
                [true, false],
                [true, true]
            ]
        case .pentaP:
            return [
                [true, true],
                [true, true],
                [true, false]
            ]
        case .pentaU:
            return [
                [true, false, true],
                [true, true, true]
            ]
        case .pentaV:
            return [
                [true, false, false],
                [true, false, false],
                [true, true, true]
            ]
        case .pentaW:
            return [
                [true, false, false],
                [true, true, false],
                [false, true, true]
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

/// Responsible for creating and managing block instances
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

    /// Rolling bags per category to avoid droughts
    private var categoryBags: [ShapeCategory: [BlockType]] = [:]

    /// Placement history for spawn tuning
    private var placementsMade: Int = 0
    private var recentLineClears: [Int] = []

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

        var totalGap1: Int { gap1Rows + gap1Columns }
        var totalGap2: Int { gap2Rows + gap2Columns }
        var nearClearCount: Int { totalGap1 + totalGap2 }
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
        ShapeDefinition(type: .single, category: .mono, baseWeight: 1.0, minStage: .early, requiresStreak: false, isReward: false),

        ShapeDefinition(type: .domino, category: .duo, baseWeight: 1.0, minStage: .early, requiresStreak: false, isReward: false),

        ShapeDefinition(type: .triLine, category: .trio, baseWeight: 0.95, minStage: .early, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .triCorner, category: .trio, baseWeight: 0.85, minStage: .early, requiresStreak: false, isReward: false),

        ShapeDefinition(type: .tetSquare, category: .tetro, baseWeight: 0.9, minStage: .early, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetLine, category: .tetro, baseWeight: 0.8, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetL, category: .tetro, baseWeight: 0.8, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetT, category: .tetro, baseWeight: 0.75, minStage: .mid, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .tetSkew, category: .tetro, baseWeight: 0.45, minStage: .mid, requiresStreak: false, isReward: false),

        ShapeDefinition(type: .pentaLine, category: .pento, baseWeight: 0.55, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaL, category: .pento, baseWeight: 0.5, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaP, category: .pento, baseWeight: 0.55, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaU, category: .pento, baseWeight: 0.6, minStage: .late, requiresStreak: false, isReward: false),
        ShapeDefinition(type: .pentaV, category: .pento, baseWeight: 0.5, minStage: .late, requiresStreak: true, isReward: false),
        ShapeDefinition(type: .pentaW, category: .pento, baseWeight: 0.45, minStage: .late, requiresStreak: true, isReward: false),

        ShapeDefinition(type: .almostSquare, category: .reward, baseWeight: 0.35, minStage: .late, requiresStreak: true, isReward: true)
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
    }

    // MARK: - Tray Generation

    private func refillTray() {
        let patterns = generateHand()
        traySlots = patterns.map { Optional($0) }
    }

    private func generateHand() -> [BlockPattern] {
        var hand: [BlockPattern] = []
        var attempts = 0

        while hand.count < traySize && attempts < 12 {
            hand.append(generatePiece())
            attempts += 1
        }

        ensureHandHasFit(&hand)
        return hand
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

        if analysis.nearClearCount > 0 {
            switch category {
            case .mono:
                adjusted *= 1.4 + Double(analysis.totalGap1) * 0.15
            case .duo:
                adjusted *= 1.25 + Double(analysis.totalGap2) * 0.12
            case .trio:
                adjusted *= 1.15
            default:
                break
            }
        }

        if analysis.emptyCells <= 8 {
            switch category {
            case .mono:
                adjusted *= 2.2
            case .duo:
                adjusted *= 1.8
            case .trio:
                adjusted *= 1.4
            default:
                adjusted *= 0.35
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
        var gap1Cols = 0
        var gap2Cols = 0

        for row in 0..<size {
            let emptyCount = grid[row].reduce(0) { $0 + ($1.isOccupied ? 0 : 1) }
            totalEmpty += emptyCount

            switch emptyCount {
            case 1:
                gap1Rows += 1
            case 2:
                gap2Rows += 1
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
            default:
                break
            }
        }

        return BoardAnalysis(
            emptyCells: totalEmpty,
            gap1Rows: gap1Rows,
            gap2Rows: gap2Rows,
            gap1Columns: gap1Cols,
            gap2Columns: gap2Cols
        )
    }

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
