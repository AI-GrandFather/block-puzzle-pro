import Foundation

// MARK: - Levels Repository

@MainActor
final class LevelsRepository: ObservableObject {
    static let shared = LevelsRepository()

    private let packs: [LevelPack]
    private let levelsByID: [Int: Level]

    private init() {
        let generatedPacks = LevelDataFactory.buildPacks()
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
                title: "Foundations",
                subtitle: "Learn essentials and build early mastery",
                difficulty: .tutorial,
                visual: LevelPack.Visual(primaryHex: "6EE7B7", secondaryHex: "34D399", iconName: "leaf.fill"),
                baseXP: 200,
                baseCoins: 50,
                completionReward: .badge
            ),
            PackConfig(
                id: 2,
                title: "Pattern Craft",
                subtitle: "Shape-focused boards that reward foresight",
                difficulty: .easy,
                visual: LevelPack.Visual(primaryHex: "FDE68A", secondaryHex: "FBBF24", iconName: "square.grid.3x3.fill"),
                baseXP: 400,
                baseCoins: 100,
                completionReward: .theme
            ),
            PackConfig(
                id: 3,
                title: "Survival Tactics",
                subtitle: "Limited moves and resourceful clears",
                difficulty: .medium,
                visual: LevelPack.Visual(primaryHex: "FDBA74", secondaryHex: "F97316", iconName: "flame.fill"),
                baseXP: 600,
                baseCoins: 150,
                completionReward: .powerUp
            ),
            PackConfig(
                id: 4,
                title: "Puzzle Vault",
                subtitle: "Pre-filled grids with clever solutions",
                difficulty: .hard,
                visual: LevelPack.Visual(primaryHex: "BFDBFE", secondaryHex: "60A5FA", iconName: "puzzlepiece.fill"),
                baseXP: 800,
                baseCoins: 200,
                completionReward: .theme
            ),
            PackConfig(
                id: 5,
                title: "Master Trials",
                subtitle: "Hybrid objectives for elite players",
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
            let baseTarget = 500 + (levelOffset * 200)
            return LevelObjective(type: .reachScore, targetValue: baseTarget)
        case 2:
            let pattern: PatternType = [
                .twoByTwoSquare,
                .filledCorners,
                .filledCentre,
                .diagonal,
                .checkerboard
            ][levelOffset % 5]
            return LevelObjective(type: .createPattern, targetValue: 1, pattern: pattern)
        case 3:
            return LevelObjective(type: .clearLines, targetValue: 8 + levelOffset)
        case 4:
            return LevelObjective(type: .clearAllBlocks, targetValue: 1)
        case 5:
            switch levelOffset % 3 {
            case 0:
                return LevelObjective(type: .reachScore, targetValue: 4500 + levelOffset * 350)
            case 1:
                return LevelObjective(type: .clearLines, targetValue: 12 + levelOffset * 2)
            default:
                return LevelObjective(type: .clearAllBlocks, targetValue: 1)
            }
        default:
            return LevelObjective(type: .reachScore, targetValue: 1000)
        }
    }

    private static func constraintsForLevel(packID: Int, levelOffset: Int) -> LevelConstraints {
        switch packID {
        case 1:
            return LevelConstraints()
        case 2:
            let pieceSets: [[BlockType]] = [
                [.square, .horizontal, .vertical],
                [.lineThree, .lineThreeVertical, .lShape],
                [.rectangleTwoByThree, .rectangleThreeByTwo, .plus],
                [.tShape, .zigZag, .square],
                [.lineFourVertical, .horizontal, .vertical]
            ]
            return LevelConstraints(allowedPieces: pieceSets[levelOffset % pieceSets.count])
        case 3:
            let moveLimit = max(14 - levelOffset, 6)
            return LevelConstraints(moveLimit: moveLimit)
        case 4:
            let moveLimit = 18 - levelOffset
            return LevelConstraints(moveLimit: max(moveLimit, 8))
        case 5:
            let moveLimit = max(12 - (levelOffset / 2), 6)
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
        case 1: return "Lesson \(index + 1)"
        case 2: return "Pattern \(index + 1)"
        case 3: return "Survival \(index + 1)"
        case 4: return "Puzzle \(index + 1)"
        case 5: return "Trial \(index + 1)"
        default: return "Level \(index + 1)"
        }
    }

    private static func levelDescription(packID: Int, index: Int) -> String {
        switch packID {
        case 1:
            return "Learn a new mechanic and score efficiently."
        case 2:
            return "Arrange blocks to satisfy the highlighted pattern."
        case 3:
            return "Clear the board within the move limit."
        case 4:
            return "Solve the pre-filled grid without getting stuck."
        case 5:
            return "Hybrid objective that tests every skill."
        default:
            return "Take on a fresh challenge."
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
    static let puzzleLayouts: [[LevelPrefill.Cell]] = [
        makeFramePattern(color: .blue),
        makeCrossPattern(color: .purple),
        makeCheckerPattern(colorA: .orange, colorB: .cyan),
        makeSpiralPattern(color: .green)
    ]

    static let masterLayouts: [[LevelPrefill.Cell]] = [
        makeDiamondPattern(color: .pink),
        makeCascadePattern(color: .yellow)
    ]

    private static func makeFramePattern(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        let size = 10
        for row in 0..<size {
            for column in 0..<size {
                if row == 0 || row == size - 1 || column == 0 || column == size - 1 {
                    cells.append(LevelPrefill.Cell(row: row, column: column, color: color))
                }
            }
        }
        return cells
    }

    private static func makeCrossPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        let size = 10
        let mid = size / 2
        for index in 0..<size {
            cells.append(LevelPrefill.Cell(row: mid, column: index, color: color))
            cells.append(LevelPrefill.Cell(row: index, column: mid, color: color))
        }
        return cells
    }

    private static func makeCheckerPattern(colorA: BlockColor, colorB: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        for row in 0..<10 {
            for column in 0..<10 {
                if (row + column).isMultiple(of: 2) {
                    cells.append(LevelPrefill.Cell(row: row, column: column, color: colorA))
                } else if row % 3 == 0 {
                    cells.append(LevelPrefill.Cell(row: row, column: column, color: colorB))
                }
            }
        }
        return cells
    }

    private static func makeSpiralPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        let coordinates = [
            (1,1),(1,2),(1,3),(1,4),(1,5),(1,6),(1,7),
            (2,7),(3,7),(4,7),(5,7),(6,7),(7,7),(7,6),(7,5),
            (7,4),(7,3),(7,2),(7,1),(6,1),(5,1),(4,1),(3,1),(2,1),
            (2,2),(2,3),(2,4),(2,5),(2,6),(3,6),(4,6),(5,6),(6,6),(6,5),(6,4),(6,3),(5,3),(4,3),(3,3),(3,4),(3,5),(4,5),(5,5)
        ]
        for (row, column) in coordinates {
            cells.append(LevelPrefill.Cell(row: row, column: column, color: color))
        }
        return cells
    }

    private static func makeDiamondPattern(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        let size = 10
        let centre = size / 2
        for row in 0..<size {
            for column in 0..<size {
                let distance = abs(row - centre) + abs(column - centre)
                if distance <= 3 {
                    cells.append(LevelPrefill.Cell(row: row, column: column, color: color, isLocked: distance == 3))
                }
            }
        }
        return cells
    }

    private static func makeCascadePattern(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        for row in 0..<10 {
            for column in 0..<(row % 5 + 3) {
                cells.append(LevelPrefill.Cell(row: row, column: column, color: color, isLocked: row % 2 == 0 && column == 0))
            }
        }
        return cells
    }
}
