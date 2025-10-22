import Foundation

// MARK: - Levels Repository

@MainActor
final class LevelsRepository: ObservableObject {
    static let shared = LevelsRepository()

    private let packs: [LevelPack]
    private let levelsByID: [Int: Level]
    private let levelManager: ComprehensiveLevelManager

    private init() {
        // Use new comprehensive level manager with research-backed progression
        self.levelManager = ComprehensiveLevelManager()
        let generatedPacks = levelManager.getAllWorlds()
        self.packs = generatedPacks
        var lookup: [Int: Level] = [:]
        for pack in generatedPacks {
            for level in pack.levels {
                lookup[level.id] = level
            }
        }
        self.levelsByID = lookup
    }

    func allPacks() -> [LevelPack] {
        packs
    }

    func pack(with id: Int) -> LevelPack? {
        packs.first { $0.id == id }
    }

    func level(with id: Int) -> Level? {
        levelsByID[id]
    }
}

// MARK: - Data Factory

private enum LevelDataFactory {
    struct PackConfig {
        let id: Int
        let title: String
        let subtitle: String
        let difficulty: DifficultyLevel
        let visual: LevelPack.Visual
        let baseXP: Int
        let baseCoins: Int
        let completionReward: UnlockType?
    }

    static func buildPacks() -> [LevelPack] {
        let configs: [PackConfig] = [
            PackConfig(
                id: 1,
                title: "Learning Pack",
                subtitle: "Easy levels to learn and have fun",
                difficulty: .tutorial,
                visual: LevelPack.Visual(primaryHex: "6EE7B7", secondaryHex: "34D399", iconName: "leaf.fill"),
                baseXP: 200,
                baseCoins: 50,
                completionReward: .badge
            ),
            PackConfig(
                id: 2,
                title: "Shape Builder",
                subtitle: "Make cool shapes and patterns",
                difficulty: .easy,
                visual: LevelPack.Visual(primaryHex: "FDE68A", secondaryHex: "FBBF24", iconName: "square.grid.3x3.fill"),
                baseXP: 400,
                baseCoins: 100,
                completionReward: .theme
            ),
            PackConfig(
                id: 3,
                title: "Quick Challenge",
                subtitle: "Clear fast with fewer moves",
                difficulty: .medium,
                visual: LevelPack.Visual(primaryHex: "FDBA74", secondaryHex: "F97316", iconName: "flame.fill"),
                baseXP: 600,
                baseCoins: 150,
                completionReward: .powerUp
            ),
            PackConfig(
                id: 4,
                title: "Puzzle Solver",
                subtitle: "Clear blocks already on the board",
                difficulty: .hard,
                visual: LevelPack.Visual(primaryHex: "BFDBFE", secondaryHex: "60A5FA", iconName: "puzzlepiece.fill"),
                baseXP: 800,
                baseCoins: 200,
                completionReward: .theme
            ),
            PackConfig(
                id: 5,
                title: "Expert Zone",
                subtitle: "Super hard levels for champions",
                difficulty: .expert,
                visual: LevelPack.Visual(primaryHex: "FCA5A5", secondaryHex: "EF4444", iconName: "crown.fill"),
                baseXP: 1000,
                baseCoins: 250,
                completionReward: .avatar
            )
        ]

        return configs.map { config in
            LevelPack(
                id: config.id,
                title: config.title,
                subtitle: config.subtitle,
                difficultyBand: config.difficulty,
                visual: config.visual,
                xpReward: config.baseXP * 10,
                coinReward: config.baseCoins * 10,
                completionReward: config.completionReward,
                levels: buildLevels(for: config)
            )
        }
    }

    private static func buildLevels(for config: PackConfig) -> [Level] {
        (0..<10).map { index in
            let globalLevelID = (config.id - 1) * 10 + (index + 1)
            let objective = objectiveForLevel(packID: config.id, levelOffset: index)
            let thresholds = starThresholds(for: objective, packDifficulty: config.difficulty)
            let constraints = constraintsForLevel(packID: config.id, levelOffset: index)
            let prefill = prefillForLevel(packID: config.id, levelOffset: index)
            let rewards = LevelRewards(
                xp: config.baseXP,
                coins: config.baseCoins,
                unlock: unlockForLevel(packID: config.id, index: index)
            )

            let unlockRequirement: UnlockRequirement
            if index == 0 {
                unlockRequirement = .none
            } else {
                unlockRequirement = UnlockRequirement(type: .level, value: globalLevelID - 1)
            }

            return Level(
                id: globalLevelID,
                packID: config.id,
                indexInPack: index,
                title: levelTitle(packID: config.id, index: index),
                description: levelDescription(packID: config.id, index: index),
                objective: objective,
                constraints: constraints,
                prefill: prefill,
                starThresholds: thresholds,
                rewards: rewards,
                difficulty: difficultyForLevel(packDifficulty: config.difficulty, index: index),
                unlockRequirement: unlockRequirement
            )
        }
    }

    private static func objectiveForLevel(packID: Int, levelOffset: Int) -> LevelObjective {
        switch packID {
        case 1:
            // Learning Pack: Start very easy (100-400 points)
            // Research: 1pt/block + 10pts/line = ~15pts per move avg
            // 100pts = ~7 moves, 400pts = ~27 moves (very achievable)
            let baseTarget = 100 + (levelOffset * 30)
            return LevelObjective(type: .reachScore, targetValue: baseTarget)
        case 2:
            // Shape Builder: Pattern objectives (keep as is)
            let pattern: PatternType = [
                .twoByTwoSquare,
                .filledCorners,
                .filledCentre,
                .diagonal,
                .checkerboard
            ][levelOffset % 5]
            return LevelObjective(type: .createPattern, targetValue: 1, pattern: pattern)
        case 3:
            // Quick Challenge: Realistic line counts
            // Research: 10 lines = ~10-15 moves, very doable
            return LevelObjective(type: .clearLines, targetValue: 5 + levelOffset)
        case 4:
            // Puzzle Solver: Just clear the pre-filled blocks
            return LevelObjective(type: .clearAllBlocks, targetValue: 1)
        case 5:
            // Expert Zone: Higher but still realistic (300-900 points)
            // 300pts = ~20 moves, 900pts = ~60 moves (challenging but fair)
            switch levelOffset % 3 {
            case 0:
                return LevelObjective(type: .reachScore, targetValue: 300 + levelOffset * 60)
            case 1:
                return LevelObjective(type: .clearLines, targetValue: 8 + levelOffset)
            default:
                return LevelObjective(type: .clearAllBlocks, targetValue: 1)
            }
        default:
            return LevelObjective(type: .reachScore, targetValue: 200)
        }
    }

    private static func constraintsForLevel(packID: Int, levelOffset: Int) -> LevelConstraints {
        switch packID {
        case 1:
            // Learning Pack: No limits, let players learn
            return LevelConstraints()
        case 2:
            // Shape Builder: Limit piece types for focused learning
            let pieceSets: [[BlockType]] = [
                [.tetSquare, .domino, .triLine],
                [.triLine, .triCorner, .tetT],
                [.tetL, .almostSquare, .pentaU],
                [.tetT, .tetSkew, .tetSquare],
                [.tetLine, .domino, .triLine]
            ]
            return LevelConstraints(allowedPieces: pieceSets[levelOffset % pieceSets.count])
        case 3:
            // Quick Challenge: Give plenty of moves (15-20)
            // Research: Players need breathing room, not frustration
            let moveLimit = max(20 - levelOffset, 15)
            return LevelConstraints(moveLimit: moveLimit)
        case 4:
            // Puzzle Solver: Generous moves for prefilled boards (25-30)
            // Prefilled boards need MORE moves, not less
            let moveLimit = 30 - levelOffset
            return LevelConstraints(moveLimit: max(moveLimit, 25))
        case 5:
            // Expert Zone: Challenging but fair (20-25 moves)
            let moveLimit = max(25 - (levelOffset / 2), 20)
            let timeLimit = levelOffset.isMultiple(of: 3) ? 180 : nil
            return LevelConstraints(moveLimit: moveLimit, timeLimit: timeLimit)
        default:
            return LevelConstraints()
        }
    }

    private static func prefillForLevel(packID: Int, levelOffset: Int) -> LevelPrefill? {
        switch packID {
        case 4:
            return LevelPrefill(
                cells: PrefillPatterns.puzzleLayouts[levelOffset % PrefillPatterns.puzzleLayouts.count]
            )
        case 5 where levelOffset.isMultiple(of: 2):
            return LevelPrefill(
                cells: PrefillPatterns.masterLayouts[levelOffset % PrefillPatterns.masterLayouts.count]
            )
        default:
            return nil
        }
    }

    private static func starThresholds(for objective: LevelObjective, packDifficulty: DifficultyLevel) -> LevelStarThresholds {
        let scaling: (Double, Double) = {
            switch packDifficulty {
            case .tutorial: return (1.0, 1.2)
            case .easy: return (1.1, 1.3)
            case .medium: return (1.15, 1.4)
            case .hard: return (1.2, 1.45)
            case .expert: return (1.25, 1.5)
            }
        }()

        let baseRequirement: StarRequirement
        let second: StarRequirement
        let third: StarRequirement

        switch objective.type {
        case .reachScore:
            baseRequirement = StarRequirement(type: .score, value: objective.targetValue)
            second = StarRequirement(type: .score, value: Int(Double(objective.targetValue) * scaling.0))
            third = StarRequirement(type: .score, value: Int(Double(objective.targetValue) * scaling.1))
        case .clearLines:
            baseRequirement = StarRequirement(type: .specificObjective, value: objective.targetValue)
            second = StarRequirement(type: .movesRemaining, value: max(3, objective.targetValue / 2))
            third = StarRequirement(type: .movesRemaining, value: max(5, objective.targetValue))
        case .createPattern:
            baseRequirement = StarRequirement(type: .specificObjective, value: 1)
            second = StarRequirement(type: .movesRemaining, value: 4)
            third = StarRequirement(type: .movesRemaining, value: 2)
        case .surviveTime:
            baseRequirement = StarRequirement(type: .timeRemaining, value: max(30, objective.targetValue / 4))
            second = StarRequirement(type: .timeRemaining, value: max(60, objective.targetValue / 3))
            third = StarRequirement(type: .timeRemaining, value: max(90, objective.targetValue / 2))
        case .clearAllBlocks:
            baseRequirement = StarRequirement(type: .specificObjective, value: 1)
            second = StarRequirement(type: .movesRemaining, value: 4)
            third = StarRequirement(type: .movesRemaining, value: 2)
        case .clearSpecificColor, .achieveCombo, .perfectClear, .useOnlyPieces, .clearWithMoves:
            baseRequirement = StarRequirement(type: .specificObjective, value: objective.targetValue)
            second = StarRequirement(type: .movesRemaining, value: max(1, objective.targetValue))
            third = StarRequirement(type: .movesRemaining, value: max(1, objective.targetValue + 1))
        }

        return LevelStarThresholds(
            oneStar: baseRequirement,
            twoStar: second,
            threeStar: third
        )
    }

    private static func unlockForLevel(packID: Int, index: Int) -> UnlockType? {
        switch (packID, index) {
        case (1, 9):
            return .powerUp
        case (2, 4):
            return .powerUp
        case (3, 9):
            return .theme
        case (4, 5):
            return .powerUp
        case (5, 9):
            return .avatar
        default:
            return nil
        }
    }

    private static func levelTitle(packID: Int, index: Int) -> String {
        switch packID {
        case 1:
            let titles = ["Learn to Score", "Fill Lines", "Clear Rows", "Make Combos", "Score Big",
                         "Master Basics", "Think Ahead", "Plan Moves", "Clear Smart", "Level Up!"]
            return titles[index]
        case 2:
            let titles = ["Make a Square", "Fill Corners", "Fill Center", "Make Diagonal", "Make Pattern",
                         "Square Again", "Corner Challenge", "Center Goal", "Diagonal Line", "Pattern Pro"]
            return titles[index]
        case 3:
            let titles = ["Quick Clear", "Beat the Clock", "Few Moves", "Think Fast", "Smart Moves",
                         "Speed Run", "Race Time", "Fast Clear", "Quick Win", "Time Master"]
            return titles[index]
        case 4:
            let titles = ["Solve Frame", "Clear Cross", "Fix Checker", "Solve Spiral", "Clear Smiley",
                         "Fix Heart", "Clear Arrow", "Solve Corners", "Fix Maze", "Clear Stairs"]
            return titles[index]
        case 5:
            let titles = ["Master Test 1", "Master Test 2", "Master Test 3", "Master Test 4", "Master Test 5",
                         "Expert Level 1", "Expert Level 2", "Expert Level 3", "Expert Level 4", "Expert Level 5"]
            return titles[index]
        default: return "Level \(index + 1)"
        }
    }

    private static func levelDescription(packID: Int, index: Int) -> String {
        switch packID {
        case 1:
            return "🎓 Learn how to play and score points!"
        case 2:
            return "🎨 Fill blocks to make special shapes!"
        case 3:
            return "⚡ Clear everything quickly with few moves!"
        case 4:
            return "🧩 Some blocks are already placed - clear them all!"
        case 5:
            return "👑 Expert challenge - use all your skills!"
        default:
            return "🎮 Fun puzzle challenge!"
        }
    }

    private static func difficultyForLevel(packDifficulty: DifficultyLevel, index: Int) -> DifficultyLevel {
        switch packDifficulty {
        case .tutorial:
            return index < 5 ? .tutorial : .easy
        case .easy:
            return index < 5 ? .easy : .medium
        case .medium:
            return index < 5 ? .medium : .hard
        case .hard:
            return index < 5 ? .hard : .expert
        case .expert:
            return .expert
        }
    }
}

// MARK: - Objective Helpers

// MARK: - Prefill Patterns

private enum PrefillPatterns {
    // SIMPLIFIED PATTERNS: Less clutter = more fun!
    // Research shows: 12-20 blocks = sweet spot for pre-filled puzzles
    static let puzzleLayouts: [[LevelPrefill.Cell]] = [
        makeFramePattern(color: .blue),        // ~12 blocks
        makeCrossPattern(color: .purple),      // ~12 blocks
        makeSpiralPattern(color: .green),      // ~12 blocks
        makeSmileyPattern(color: .yellow),     // ~20 blocks
        makeHeartPattern(color: .pink),        // ~30 blocks (a bit more)
        makeArrowPattern(color: .cyan),        // ~18 blocks
        makeMazePattern(color: .purple),       // ~13 blocks
        makeCornerDotsPattern(color: .orange), // ~8 blocks (very easy!)
        makeLinePattern(color: .cyan),         // ~10 blocks
        makeTPattern(color: .green)            // ~15 blocks
    ]

    static let masterLayouts: [[LevelPrefill.Cell]] = [
        makePlusPattern(color: .blue),         // ~20 blocks
        makeTargetPattern(colorA: .red, colorB: .orange), // ~25 blocks
        makeWindowsPattern(color: .pink),      // ~16 blocks
        makeZigZagPattern(color: .yellow)      // ~18 blocks
    ]

    private static func makeFramePattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Simple border - just top and bottom rows
        var cells: [LevelPrefill.Cell] = []
        for col in 2..<8 {
            cells.append(LevelPrefill.Cell(row: 1, column: col, color: color))
            cells.append(LevelPrefill.Cell(row: 8, column: col, color: color))
        }
        return cells
    }

    private static func makeCrossPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Simple + sign in center
        var cells: [LevelPrefill.Cell] = []
        let mid = 4
        for i in 2...7 {
            cells.append(LevelPrefill.Cell(row: mid, column: i, color: color))
            cells.append(LevelPrefill.Cell(row: i, column: mid, color: color))
        }
        return cells
    }

    private static func makeCheckerPattern(colorA: BlockColor, colorB: BlockColor) -> [LevelPrefill.Cell] {
        // Scattered checkerboard - not too cluttered
        var cells: [LevelPrefill.Cell] = []
        for row in stride(from: 1, to: 9, by: 2) {
            for col in stride(from: 1, to: 9, by: 2) {
                let color = (row + col).isMultiple(of: 4) ? colorA : colorB
                cells.append(LevelPrefill.Cell(row: row, column: col, color: color))
            }
        }
        return cells
    }

    private static func makeSpiralPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Simple L-shaped path
        let coords = [
            (1,1), (1,2), (1,3),
            (2,3), (3,3), (4,3),
            (4,4), (4,5), (4,6),
            (5,6), (6,6), (7,6)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: color) }
    }

    private static func makeSmileyPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Create a smiley face on a 10x10 grid
        let coords = [
            // Eyes
            (2,3), (2,6),
            // Smile
            (6,2), (7,3), (7,4), (7,5), (7,6), (6,7),
            // Outline
            (1,2), (1,3), (1,6), (1,7),
            (2,1), (2,8),
            (6,1), (6,8),
            (7,1), (7,8),
            (8,2), (8,3), (8,6), (8,7)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: color) }
    }

    private static func makeHeartPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Create a heart shape
        let coords = [
            (1,2), (1,3), (1,6), (1,7),
            (2,1), (2,2), (2,3), (2,4), (2,5), (2,6), (2,7), (2,8),
            (3,1), (3,2), (3,3), (3,4), (3,5), (3,6), (3,7), (3,8),
            (4,2), (4,3), (4,4), (4,5), (4,6), (4,7),
            (5,3), (5,4), (5,5), (5,6),
            (6,4), (6,5),
            (7,4)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: color) }
    }

    private static func makeArrowPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Create an upward arrow
        let coords = [
            // Arrow head
            (1,4), (1,5),
            (2,3), (2,4), (2,5), (2,6),
            (3,2), (3,3), (3,4), (3,5), (3,6), (3,7),
            // Arrow shaft
            (4,4), (4,5),
            (5,4), (5,5),
            (6,4), (6,5),
            (7,4), (7,5),
            (8,4), (8,5)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: color) }
    }

    private static func makeMazePattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Create a simple maze-like pattern
        let coords = [
            // Horizontal walls
            (1,1), (1,2), (1,3), (1,4),
            (3,5), (3,6), (3,7), (3,8),
            (5,1), (5,2), (5,3), (5,4),
            (7,5), (7,6), (7,7), (7,8),
            // Vertical walls
            (2,5), (4,2), (6,7), (8,4)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: color) }
    }

    private static func makeCornerDotsPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Just 2x2 blocks in each corner - very simple!
        var cells: [LevelPrefill.Cell] = []
        let corners = [(0,0), (0,8), (8,0), (8,8)]
        for (r, c) in corners {
            cells.append(LevelPrefill.Cell(row: r, column: c, color: color))
            cells.append(LevelPrefill.Cell(row: r+1, column: c, color: color))
        }
        return cells
    }

    private static func makeLinePattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Simple horizontal line in middle
        var cells: [LevelPrefill.Cell] = []
        for col in 2...7 {
            cells.append(LevelPrefill.Cell(row: 4, column: col, color: color))
        }
        return cells
    }

    private static func makeTPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // T-shape pattern
        let coords = [
            (1,3), (1,4), (1,5), (1,6),  // Top of T
            (2,4), (2,5),                 // Vertical
            (3,4), (3,5),
            (4,4), (4,5),
            (5,4), (5,5)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: color) }
    }

    private static func makePlusPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Simple + sign in center - not too big!
        var cells: [LevelPrefill.Cell] = []
        // Vertical line (middle 6 blocks)
        for row in 2...7 {
            cells.append(LevelPrefill.Cell(row: row, column: 4, color: color))
        }
        // Horizontal line (middle 6 blocks)
        for col in 2...7 {
            cells.append(LevelPrefill.Cell(row: 4, column: col, color: color))
        }
        return cells
    }

    private static func makeTargetPattern(colorA: BlockColor, colorB: BlockColor) -> [LevelPrefill.Cell] {
        // Simple concentric squares (not circles - easier to clear!)
        let coords: [(Int, Int, BlockColor)] = [
            // Center 2x2
            (4,4,colorA), (4,5,colorA), (5,4,colorA), (5,5,colorA),
            // Ring around center
            (3,3,colorB), (3,4,colorB), (3,5,colorB), (3,6,colorB),
            (4,3,colorB), (4,6,colorB),
            (5,3,colorB), (5,6,colorB),
            (6,3,colorB), (6,4,colorB), (6,5,colorB), (6,6,colorB)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: $0.2) }
    }

    private static func makeWindowsPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Four separate 2x2 squares (like windows)
        let windows = [(1,1), (1,6), (6,1), (6,6)]
        var cells: [LevelPrefill.Cell] = []
        for (r, c) in windows {
            for dr in 0...1 {
                for dc in 0...1 {
                    cells.append(LevelPrefill.Cell(row: r+dr, column: c+dc, color: color))
                }
            }
        }
        return cells
    }

    private static func makeZigZagPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        // Diagonal zigzag pattern
        let coords = [
            (1,1), (1,2),
            (2,2), (2,3),
            (3,3), (3,4),
            (4,4), (4,5),
            (5,5), (5,6),
            (6,6), (6,7),
            (7,7), (7,8)
        ]
        return coords.map { LevelPrefill.Cell(row: $0.0, column: $0.1, color: color) }
    }
}
