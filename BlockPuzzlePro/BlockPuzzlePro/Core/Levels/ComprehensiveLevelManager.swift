// FILE: ComprehensiveLevelManager.swift
import Foundation

/**
 # Comprehensive Level Manager

 Research-backed level progression system for block puzzle game.
 Based on analysis of Candy Crush, 1010!, and successful block puzzle variants.

 ## Structure:
 - 10 Worlds, 15 levels each = 150 total levels
 - Each world introduces new mechanics and challenges
 - Smooth difficulty progression within and across worlds
 - Multiple level types: obstacles, targets, timed, limited pieces, score

 ## Level Distribution Per World:
 - 5 Tutorial/Easy levels (1-5)
 - 5 Medium levels (6-10)
 - 4 Hard levels (11-14)
 - 1 Boss level (15)

 ## Level Types:
 - Pre-placed obstacles: 40% of levels
 - Clear targets: 25% of levels
 - Timed challenges: 15% of levels
 - Limited pieces: 10% of levels
 - Score targets: 10% of levels

 - Author: Claude Code
 - Date: 2025-10-21
 */
@MainActor
class ComprehensiveLevelManager {

    // MARK: - Properties

    private let patternGenerator: LevelPatternGenerator
    private var allWorlds: [LevelPack] = []

    // MARK: - Initialization

    init() {
        self.patternGenerator = LevelPatternGenerator(gridSize: 8)
        generateAllWorlds()
    }

    // MARK: - Public API

    /// Get all level packs (worlds)
    func getAllWorlds() -> [LevelPack] {
        return allWorlds
    }

    /// Get a specific world by ID
    func getWorld(id: Int) -> LevelPack? {
        return allWorlds.first { $0.id == id }
    }

    /// Get a specific level by world and level number
    func getLevel(worldNumber: Int, levelNumber: Int) -> Level? {
        guard let world = getWorld(id: worldNumber) else { return nil }
        return world.levels.first { $0.indexInPack == levelNumber }
    }

    // MARK: - World Generation

    private func generateAllWorlds() {
        allWorlds = [
            createWorld1_TutorialPeaks(),
            createWorld2_StrategyValley(),
            createWorld3_PuzzlePlains(),
            createWorld4_ChallengeCanyons(),
            createWorld5_MasterMountains(),
            createWorld6_ExpertExpanse(),
            createWorld7_LegendLands(),
            createWorld8_InfiniteIsles(),
            createWorld9_UltimatePlateau(),
            createWorld10_GrandmasterGlacier()
        ]
    }

    // MARK: - World 1: Tutorial Peaks

    /**
     World 1: Tutorial Peaks

     Learning the basics - introduces core mechanics and controls.
     Difficulty: Tutorial → Easy
     Star requirement to unlock World 2: 30 stars (2-star average)
     */
    private func createWorld1_TutorialPeaks() -> LevelPack {
        let levels = [
            createLevel_1_1(),
            createLevel_1_2(),
            createLevel_1_3(),
            createLevel_1_4(),
            createLevel_1_5(),
            createLevel_1_6(),
            createLevel_1_7(),
            createLevel_1_8(),
            createLevel_1_9(),
            createLevel_1_10(),
            createLevel_1_11(),
            createLevel_1_12(),
            createLevel_1_13(),
            createLevel_1_14(),
            createLevel_1_15_BOSS()
        ]

        return LevelPack(
            id: 1,
            title: "Tutorial Peaks",
            subtitle: "Learn the Basics",
            difficultyBand: .tutorial,
            visual: LevelPack.Visual(
                primaryHex: "#4A90E2",
                secondaryHex: "#7CB9E8",
                iconName: "mountain.2.fill"
            ),
            xpReward: 500,
            coinReward: 100,
            completionReward: .theme,
            levels: levels
        )
    }

    // MARK: - World 1 Levels

    private func createLevel_1_1() -> Level {
        return Level(
            id: 101,
            packID: 1,
            indexInPack: 1,
            title: "First Steps",
            description: "Clear 2 rows to begin your journey!",
            objective: LevelObjective(type: .clearLines, targetValue: 2),
            constraints: LevelConstraints(moveLimit: 5, timeLimit: nil, allowedPieces: nil),
            prefill: nil,  // Empty grid
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 2),
                threeStar: StarRequirement(type: .movesRemaining, value: 3)
            ),
            rewards: LevelRewards(xp: 50, coins: 10),
            difficulty: .tutorial,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_2() -> Level {
        let corners = patternGenerator.generatePattern(difficulty: 1, patternType: .corners)

        return Level(
            id: 102,
            packID: 1,
            indexInPack: 2,
            title: "Corner Challenge",
            description: "Navigate around corner obstacles",
            objective: LevelObjective(type: .clearLines, targetValue: 2),
            constraints: LevelConstraints(moveLimit: 6, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: corners),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 2),
                threeStar: StarRequirement(type: .movesRemaining, value: 4)
            ),
            rewards: LevelRewards(xp: 50, coins: 10),
            difficulty: .tutorial,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_3() -> Level {
        let scattered = patternGenerator.generatePattern(difficulty: 2, patternType: .scattered)

        return Level(
            id: 103,
            packID: 1,
            indexInPack: 3,
            title: "Scattered Blocks",
            description: "Clear 3 rows with obstacles in the way",
            objective: LevelObjective(type: .clearLines, targetValue: 3),
            constraints: LevelConstraints(moveLimit: 7, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: scattered),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 2),
                threeStar: StarRequirement(type: .movesRemaining, value: 4)
            ),
            rewards: LevelRewards(xp: 60, coins: 12),
            difficulty: .easy,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_4() -> Level {
        let borders = patternGenerator.generatePattern(difficulty: 2, patternType: .borders)

        return Level(
            id: 104,
            packID: 1,
            indexInPack: 4,
            title: "Border Patrol",
            description: "Work within the borders",
            objective: LevelObjective(type: .clearLines, targetValue: 2),
            constraints: LevelConstraints(moveLimit: 7, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: borders),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 2),
                threeStar: StarRequirement(type: .movesRemaining, value: 4)
            ),
            rewards: LevelRewards(xp: 60, coins: 12),
            difficulty: .easy,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_5() -> Level {
        let cross = patternGenerator.generatePattern(difficulty: 2, patternType: .cross)

        return Level(
            id: 105,
            packID: 1,
            indexInPack: 5,
            title: "Cross Roads",
            description: "Navigate the cross pattern",
            objective: LevelObjective(type: .clearLines, targetValue: 3),
            constraints: LevelConstraints(moveLimit: 8, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: cross),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 3),
                threeStar: StarRequirement(type: .movesRemaining, value: 5)
            ),
            rewards: LevelRewards(xp: 70, coins: 14),
            difficulty: .easy,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_6() -> Level {
        let checkerboard = patternGenerator.generatePattern(difficulty: 3, patternType: .checkerboard)

        return Level(
            id: 106,
            packID: 1,
            indexInPack: 6,
            title: "Checker Pattern",
            description: "Clear 4 rows around the checkerboard",
            objective: LevelObjective(type: .clearLines, targetValue: 4),
            constraints: LevelConstraints(moveLimit: 9, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: checkerboard),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 3),
                threeStar: StarRequirement(type: .movesRemaining, value: 5)
            ),
            rewards: LevelRewards(xp: 80, coins: 16),
            difficulty: .medium,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_7() -> Level {
        let lShape = patternGenerator.generatePattern(difficulty: 3, patternType: .lShape)

        return Level(
            id: 107,
            packID: 1,
            indexInPack: 7,
            title: "L-Shaped Barriers",
            description: "Clear rows and columns together",
            objective: LevelObjective(type: .clearLines, targetValue: 5),  // Mix of rows and columns
            constraints: LevelConstraints(moveLimit: 10, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: lShape),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 3),
                threeStar: StarRequirement(type: .movesRemaining, value: 6)
            ),
            rewards: LevelRewards(xp: 90, coins: 18),
            difficulty: .medium,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_8() -> Level {
        let clusters = patternGenerator.generatePattern(difficulty: 3, patternType: .clusters)

        return Level(
            id: 108,
            packID: 1,
            indexInPack: 8,
            title: "Clustered Chaos",
            description: "Clear 5 rows amid the clusters",
            objective: LevelObjective(type: .clearLines, targetValue: 5),
            constraints: LevelConstraints(moveLimit: 11, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: clusters),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 3),
                threeStar: StarRequirement(type: .movesRemaining, value: 6)
            ),
            rewards: LevelRewards(xp: 100, coins: 20),
            difficulty: .medium,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_9() -> Level {
        let scattered = patternGenerator.generatePattern(difficulty: 3, patternType: .scattered)

        return Level(
            id: 109,
            packID: 1,
            indexInPack: 9,
            title: "Race Against Time",
            description: "Clear 3 rows in 60 seconds!",
            objective: LevelObjective(type: .surviveTime, targetValue: 60),  // Must clear objective within time
            constraints: LevelConstraints(moveLimit: nil, timeLimit: 60, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: scattered),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .timeRemaining, value: 20),
                threeStar: StarRequirement(type: .timeRemaining, value: 35)
            ),
            rewards: LevelRewards(xp: 110, coins: 22),
            difficulty: .medium,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_10() -> Level {
        let diagonal = patternGenerator.generatePattern(difficulty: 4, patternType: .diagonal)

        return Level(
            id: 110,
            packID: 1,
            indexInPack: 10,
            title: "Diagonal Divide",
            description: "Clear 4 rows across the diagonal",
            objective: LevelObjective(type: .clearLines, targetValue: 4),
            constraints: LevelConstraints(moveLimit: 10, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: diagonal),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 3),
                threeStar: StarRequirement(type: .movesRemaining, value: 6)
            ),
            rewards: LevelRewards(xp: 120, coins: 24),
            difficulty: .medium,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_11() -> Level {
        let cross = patternGenerator.generatePattern(difficulty: 5, patternType: .cross)

        return Level(
            id: 111,
            packID: 1,
            indexInPack: 11,
            title: "Double Cross",
            description: "Clear 5 rows through complex obstacles",
            objective: LevelObjective(type: .clearLines, targetValue: 5),
            constraints: LevelConstraints(moveLimit: 12, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: cross),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 4),
                threeStar: StarRequirement(type: .movesRemaining, value: 7)
            ),
            rewards: LevelRewards(xp: 130, coins: 26),
            difficulty: .hard,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_12() -> Level {
        // Limited pieces - only tetrominoes
        let scattered = patternGenerator.generatePattern(difficulty: 4, patternType: .scattered)

        return Level(
            id: 112,
            packID: 1,
            indexInPack: 12,
            title: "Tetromino Only",
            description: "Clear 4 rows using only tetromino pieces",
            objective: LevelObjective(type: .clearLines, targetValue: 4),
            constraints: LevelConstraints(
                moveLimit: 11,
                timeLimit: nil,
                allowedPieces: [.tetLine, .tetSquare, .tetL, .tetJ, .tetT, .tetS, .tetZ]
            ),
            prefill: LevelPrefill(gridSize: 8, cells: scattered),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 3),
                threeStar: StarRequirement(type: .movesRemaining, value: 6)
            ),
            rewards: LevelRewards(xp: 140, coins: 28),
            difficulty: .hard,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_13() -> Level {
        let frame = patternGenerator.generatePattern(difficulty: 5, patternType: .frame)

        return Level(
            id: 113,
            packID: 1,
            indexInPack: 13,
            title: "Framed",
            description: "Clear 6 rows within the frame",
            objective: LevelObjective(type: .clearLines, targetValue: 6),
            constraints: LevelConstraints(moveLimit: 14, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: frame),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 4),
                threeStar: StarRequirement(type: .movesRemaining, value: 8)
            ),
            rewards: LevelRewards(xp: 150, coins: 30),
            difficulty: .hard,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_14() -> Level {
        let clusters = patternGenerator.generatePattern(difficulty: 6, patternType: .clusters)

        return Level(
            id: 114,
            packID: 1,
            indexInPack: 14,
            title: "Complex Scatter",
            description: "Clear 5 rows and 4 columns",
            objective: LevelObjective(type: .clearLines, targetValue: 9),  // Combined target
            constraints: LevelConstraints(moveLimit: 15, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: clusters),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 5),
                threeStar: StarRequirement(type: .movesRemaining, value: 9)
            ),
            rewards: LevelRewards(xp: 160, coins: 32),
            difficulty: .hard,
            unlockRequirement: .none
        )
    }

    private func createLevel_1_15_BOSS() -> Level {
        let spiral = patternGenerator.generatePattern(difficulty: 7, patternType: .spiral)

        return Level(
            id: 115,
            packID: 1,
            indexInPack: 15,
            title: "BOSS: Spiral Summit",
            description: "Conquer the spiral to reach the peak!",
            objective: LevelObjective(type: .clearLines, targetValue: 8),
            constraints: LevelConstraints(moveLimit: 18, timeLimit: nil, allowedPieces: nil),
            prefill: LevelPrefill(gridSize: 8, cells: spiral),
            starThresholds: LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: 6),
                threeStar: StarRequirement(type: .movesRemaining, value: 11)
            ),
            rewards: LevelRewards(xp: 200, coins: 50, unlock: .powerUp),
            difficulty: .hard,
            unlockRequirement: .none
        )
    }

    // MARK: - World 2: Strategy Valley

    private func createWorld2_StrategyValley() -> LevelPack {
        // World 2 focuses on planning ahead and strategic thinking
        let levels = createWorldLevels(
            worldID: 2,
            startLevelID: 201,
            worldName: "Strategy Valley",
            baseDifficulty: 3,
            unlockRequirement: UnlockRequirement(type: .stars, value: 30)
        )

        return LevelPack(
            id: 2,
            title: "Strategy Valley",
            subtitle: "Plan Your Moves",
            difficultyBand: .easy,
            visual: LevelPack.Visual(
                primaryHex: "#50C878",
                secondaryHex: "#90EE90",
                iconName: "map.fill"
            ),
            xpReward: 750,
            coinReward: 150,
            completionReward: .theme,
            levels: levels
        )
    }

    // MARK: - Worlds 3-10 (Templates)

    private func createWorld3_PuzzlePlains() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 3,
            startLevelID: 301,
            worldName: "Puzzle Plains",
            baseDifficulty: 4,
            unlockRequirement: UnlockRequirement(type: .stars, value: 55)
        )

        return createLevelPack(
            id: 3,
            title: "Puzzle Plains",
            subtitle: "Master the Basics",
            difficulty: .medium,
            colorPrimary: "#FFD700",
            colorSecondary: "#FFA500",
            icon: "square.grid.3x3.fill",
            levels: levels
        )
    }

    private func createWorld4_ChallengeCanyons() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 4,
            startLevelID: 401,
            worldName: "Challenge Canyons",
            baseDifficulty: 5,
            unlockRequirement: UnlockRequirement(type: .stars, value: 80)
        )

        return createLevelPack(
            id: 4,
            title: "Challenge Canyons",
            subtitle: "Test Your Skills",
            difficulty: .medium,
            colorPrimary: "#CD5C5C",
            colorSecondary: "#F08080",
            icon: "triangle.fill",
            levels: levels
        )
    }

    private func createWorld5_MasterMountains() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 5,
            startLevelID: 501,
            worldName: "Master Mountains",
            baseDifficulty: 6,
            unlockRequirement: UnlockRequirement(type: .stars, value: 105)
        )

        return createLevelPack(
            id: 5,
            title: "Master Mountains",
            subtitle: "Climb Higher",
            difficulty: .hard,
            colorPrimary: "#8B4513",
            colorSecondary: "#D2691E",
            icon: "mountain.2.fill",
            levels: levels
        )
    }

    private func createWorld6_ExpertExpanse() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 6,
            startLevelID: 601,
            worldName: "Expert Expanse",
            baseDifficulty: 7,
            unlockRequirement: UnlockRequirement(type: .stars, value: 130)
        )

        return createLevelPack(
            id: 6,
            title: "Expert Expanse",
            subtitle: "For the Skilled",
            difficulty: .hard,
            colorPrimary: "#9370DB",
            colorSecondary: "#BA55D3",
            icon: "star.fill",
            levels: levels
        )
    }

    private func createWorld7_LegendLands() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 7,
            startLevelID: 701,
            worldName: "Legend Lands",
            baseDifficulty: 8,
            unlockRequirement: UnlockRequirement(type: .stars, value: 155)
        )

        return createLevelPack(
            id: 7,
            title: "Legend Lands",
            subtitle: "Legendary Challenges",
            difficulty: .expert,
            colorPrimary: "#FF1493",
            colorSecondary: "#FF69B4",
            icon: "crown.fill",
            levels: levels
        )
    }

    private func createWorld8_InfiniteIsles() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 8,
            startLevelID: 801,
            worldName: "Infinite Isles",
            baseDifficulty: 9,
            unlockRequirement: UnlockRequirement(type: .stars, value: 180)
        )

        return createLevelPack(
            id: 8,
            title: "Infinite Isles",
            subtitle: "Endless Puzzles",
            difficulty: .expert,
            colorPrimary: "#00CED1",
            colorSecondary: "#48D1CC",
            icon: "drop.fill",
            levels: levels
        )
    }

    private func createWorld9_UltimatePlateau() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 9,
            startLevelID: 901,
            worldName: "Ultimate Plateau",
            baseDifficulty: 10,
            unlockRequirement: UnlockRequirement(type: .stars, value: 205)
        )

        return createLevelPack(
            id: 9,
            title: "Ultimate Plateau",
            subtitle: "Ultimate Tests",
            difficulty: .expert,
            colorPrimary: "#FF4500",
            colorSecondary: "#FF6347",
            icon: "flame.fill",
            levels: levels
        )
    }

    private func createWorld10_GrandmasterGlacier() -> LevelPack {
        let levels = createWorldLevels(
            worldID: 10,
            startLevelID: 1001,
            worldName: "Grandmaster Glacier",
            baseDifficulty: 11,
            unlockRequirement: UnlockRequirement(type: .stars, value: 230)
        )

        return createLevelPack(
            id: 10,
            title: "Grandmaster Glacier",
            subtitle: "The Final Frontier",
            difficulty: .expert,
            colorPrimary: "#00BFFF",
            colorSecondary: "#87CEEB",
            icon: "snow",
            levels: levels
        )
    }

    // MARK: - Helper Methods

    private func createLevelPack(
        id: Int,
        title: String,
        subtitle: String,
        difficulty: DifficultyLevel,
        colorPrimary: String,
        colorSecondary: String,
        icon: String,
        levels: [Level]
    ) -> LevelPack {
        return LevelPack(
            id: id,
            title: title,
            subtitle: subtitle,
            difficultyBand: difficulty,
            visual: LevelPack.Visual(
                primaryHex: colorPrimary,
                secondaryHex: colorSecondary,
                iconName: icon
            ),
            xpReward: 500 + (id * 250),
            coinReward: 100 + (id * 50),
            completionReward: id % 2 == 0 ? .theme : .powerUp,
            levels: levels
        )
    }

    /**
     Generate 15 levels for a world using template patterns
     This creates levels with increasing difficulty following the research-backed progression
     */
    private func createWorldLevels(
        worldID: Int,
        startLevelID: Int,
        worldName: String,
        baseDifficulty: Int,
        unlockRequirement: UnlockRequirement
    ) -> [Level] {
        var levels: [Level] = []

        for levelIndex in 1...15 {
            let levelID = startLevelID + levelIndex - 1
            let difficulty = calculateLevelDifficulty(worldDifficulty: baseDifficulty, levelIndex: levelIndex)
            let patternType = selectPatternType(worldID: worldID, levelIndex: levelIndex)
            let pattern = patternGenerator.generatePattern(difficulty: difficulty, patternType: patternType)

            // Determine level type based on distribution
            let levelType = determineLevelType(worldID: worldID, levelIndex: levelIndex)

            let level = createTemplateLevel(
                id: levelID,
                packID: worldID,
                indexInPack: levelIndex,
                title: "\(worldName) \(levelIndex)",
                description: generateLevelDescription(type: levelType, difficulty: difficulty),
                pattern: pattern,
                difficulty: difficulty,
                levelType: levelType,
                unlockRequirement: levelIndex == 1 ? unlockRequirement : .none
            )

            levels.append(level)
        }

        return levels
    }

    private func calculateLevelDifficulty(worldDifficulty: Int, levelIndex: Int) -> Int {
        // Smooth progression within world
        let baseDiff = worldDifficulty
        let levelBonus = (levelIndex - 1) / 3  // Increases every 3 levels
        return min(12, baseDiff + levelBonus)
    }

    private func selectPatternType(worldID: Int, levelIndex: Int) -> LevelPatternGenerator.PatternType {
        let allPatterns: [LevelPatternGenerator.PatternType] = [
            .scattered, .checkerboard, .cross, .diagonal, .lShape,
            .frame, .spiral, .maze, .symmetrical, .clusters, .borders
        ]

        let index = (worldID * 15 + levelIndex) % allPatterns.count
        return allPatterns[index]
    }

    enum TemplateLevelType {
        case prePlacedObstacle
        case clearTarget
        case timedChallenge
        case limitedPieces
        case scoreTarget
    }

    private func determineLevelType(worldID: Int, levelIndex: Int) -> TemplateLevelType {
        // Distribution: 40% obstacles, 25% clear, 15% timed, 10% limited, 10% score
        let typeValue = (worldID * 17 + levelIndex * 7) % 100

        if typeValue < 40 { return .prePlacedObstacle }
        if typeValue < 65 { return .clearTarget }
        if typeValue < 80 { return .timedChallenge }
        if typeValue < 90 { return .limitedPieces }
        return .scoreTarget
    }

    private func generateLevelDescription(type: TemplateLevelType, difficulty: Int) -> String {
        switch type {
        case .prePlacedObstacle:
            return "Navigate around obstacles to clear lines"
        case .clearTarget:
            return "Clear the target number of lines"
        case .timedChallenge:
            return "Race against the clock!"
        case .limitedPieces:
            return "Complete with limited piece types"
        case .scoreTarget:
            return "Reach the score target"
        }
    }

    private func createTemplateLevel(
        id: Int,
        packID: Int,
        indexInPack: Int,
        title: String,
        description: String,
        pattern: [LevelPrefill.Cell],
        difficulty: Int,
        levelType: TemplateLevelType,
        unlockRequirement: UnlockRequirement
    ) -> Level {
        let difficultyEnum = convertDifficultyToEnum(difficulty: difficulty, isBoss: indexInPack == 15)
        let moves = calculateMoveLimit(difficulty: difficulty, levelType: levelType)
        let objective = createObjective(type: levelType, difficulty: difficulty)
        let constraints = createConstraints(type: levelType, moves: moves, difficulty: difficulty)

        return Level(
            id: id,
            packID: packID,
            indexInPack: indexInPack,
            title: title,
            description: description,
            objective: objective,
            constraints: constraints,
            prefill: pattern.isEmpty ? nil : LevelPrefill(gridSize: 8, cells: pattern),
            starThresholds: createStarThresholds(moves: moves, timeLimit: constraints.timeLimit),
            rewards: LevelRewards(
                xp: 50 + (difficulty * 10),
                coins: 10 + (difficulty * 2),
                unlock: indexInPack == 15 ? .powerUp : nil
            ),
            difficulty: difficultyEnum,
            unlockRequirement: unlockRequirement
        )
    }

    private func convertDifficultyToEnum(difficulty: Int, isBoss: Bool) -> DifficultyLevel {
        if isBoss { return .expert }
        switch difficulty {
        case 1...3: return .easy
        case 4...6: return .medium
        case 7...9: return .hard
        default: return .expert
        }
    }

    private func calculateMoveLimit(difficulty: Int, levelType: TemplateLevelType) -> Int {
        if levelType == .timedChallenge { return 999 }  // No move limit for timed

        let baseMoves = [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
        let index = min(difficulty - 1, baseMoves.count - 1)
        return baseMoves[max(0, index)]
    }

    private func createObjective(type: TemplateLevelType, difficulty: Int) -> LevelObjective {
        let targetLines = min(3 + difficulty / 2, 10)

        switch type {
        case .prePlacedObstacle, .clearTarget:
            return LevelObjective(type: .clearLines, targetValue: targetLines)
        case .timedChallenge:
            return LevelObjective(type: .surviveTime, targetValue: max(45, 90 - difficulty * 3))
        case .limitedPieces:
            return LevelObjective(type: .clearLines, targetValue: targetLines - 1)
        case .scoreTarget:
            return LevelObjective(type: .reachScore, targetValue: 2000 + (difficulty * 500))
        }
    }

    private func createConstraints(type: TemplateLevelType, moves: Int, difficulty: Int) -> LevelConstraints {
        switch type {
        case .timedChallenge:
            return LevelConstraints(
                moveLimit: nil,
                timeLimit: max(45, 90 - difficulty * 3),
                allowedPieces: nil
            )
        case .limitedPieces:
            let allowedPieces: [BlockType] = difficulty % 2 == 0 ?
                [.tetLine, .tetSquare, .tetL, .tetJ] :
                [.pentaU, .pentaT, .pentaL, .pentaP]
            return LevelConstraints(moveLimit: moves, timeLimit: nil, allowedPieces: allowedPieces)
        default:
            return LevelConstraints(moveLimit: moves, timeLimit: nil, allowedPieces: nil)
        }
    }

    private func createStarThresholds(moves: Int, timeLimit: Int?) -> LevelStarThresholds {
        if let time = timeLimit {
            return LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .timeRemaining, value: Int(Double(time) * 0.3)),
                threeStar: StarRequirement(type: .timeRemaining, value: Int(Double(time) * 0.6))
            )
        } else {
            return LevelStarThresholds(
                oneStar: StarRequirement(type: .specificObjective, value: 1),
                twoStar: StarRequirement(type: .movesRemaining, value: Int(Double(moves) * 0.3)),
                threeStar: StarRequirement(type: .movesRemaining, value: Int(Double(moves) * 0.6))
            )
        }
    }
}
