import Foundation

// MARK: - Difficulty

enum DifficultyLevel: String, Codable, CaseIterable, Identifiable {
    case tutorial
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }
}

// MARK: - Objectives

enum LevelObjectiveType: String, Codable {
    case reachScore
    case clearLines
    case createPattern
    case surviveTime
    case clearAllBlocks
    case clearSpecificColor
    case achieveCombo
    case perfectClear
    case useOnlyPieces
    case clearWithMoves
}

struct LevelObjective: Codable, Equatable {
    let type: LevelObjectiveType
    let targetValue: Int
    let pattern: PatternType?
    let color: BlockColor?
    let allowedPieces: [BlockType]?

    init(
        type: LevelObjectiveType,
        targetValue: Int,
        pattern: PatternType? = nil,
        color: BlockColor? = nil,
        allowedPieces: [BlockType]? = nil
    ) {
        self.type = type
        self.targetValue = targetValue
        self.pattern = pattern
        self.color = color
        self.allowedPieces = allowedPieces
    }
}

extension LevelObjective {
    private enum CodingKeys: String, CodingKey {
        case type
        case targetValue
        case pattern
        case color
        case allowedPieces
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(LevelObjectiveType.self, forKey: .type)
        targetValue = try container.decode(Int.self, forKey: .targetValue)

        if let patternRaw = try container.decodeIfPresent(String.self, forKey: .pattern) {
            pattern = PatternType(rawValue: patternRaw)
        } else {
            pattern = nil
        }

        if let colorRaw = try container.decodeIfPresent(String.self, forKey: .color) {
            color = BlockColor(rawValue: colorRaw)
        } else {
            color = nil
        }

        if let allowedRaw = try container.decodeIfPresent([String].self, forKey: .allowedPieces) {
            let pieces = allowedRaw.compactMap(BlockType.init(rawValue:))
            allowedPieces = pieces.isEmpty ? nil : pieces
        } else {
            allowedPieces = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(targetValue, forKey: .targetValue)
        try container.encodeIfPresent(pattern?.rawValue, forKey: .pattern)
        try container.encodeIfPresent(color?.rawValue, forKey: .color)
        try container.encodeIfPresent(allowedPieces?.map { $0.rawValue }, forKey: .allowedPieces)
    }
}

// MARK: - Patterns

enum PatternType: String, Codable {
    case twoByTwoSquare
    case filledCorners
    case filledCentre
    case diagonal
    case checkerboard
}

// MARK: - Star Requirements

enum StarRequirementType: String, Codable {
    case score
    case movesRemaining
    case timeRemaining
    case noHoldsUsed
    case noUndosUsed
    case perfectClears
    case comboAchieved
    case specificObjective
}

struct StarRequirement: Codable, Equatable {
    let type: StarRequirementType
    let value: Int

    init(type: StarRequirementType, value: Int) {
        self.type = type
        self.value = value
    }
}

struct LevelStarThresholds: Codable, Equatable {
    let oneStar: StarRequirement
    let twoStar: StarRequirement
    let threeStar: StarRequirement
}

// MARK: - Constraints

struct LevelConstraints: Codable, Equatable {
    let moveLimit: Int?
    let timeLimit: Int?
    let allowedPieces: [BlockType]?

    init(moveLimit: Int? = nil, timeLimit: Int? = nil, allowedPieces: [BlockType]? = nil) {
        self.moveLimit = moveLimit
        self.timeLimit = timeLimit
        self.allowedPieces = allowedPieces
    }
}

// MARK: - Prefill

struct LevelPrefill: Codable, Equatable {
    struct Cell: Codable, Equatable {
        let row: Int
        let column: Int
        let color: BlockColor
        let isLocked: Bool

        init(row: Int, column: Int, color: BlockColor, isLocked: Bool = false) {
            self.row = row
            self.column = column
            self.color = color
            self.isLocked = isLocked
        }
    }

    let gridSize: Int
    let cells: [Cell]

    init(gridSize: Int = 10, cells: [Cell]) {
        self.gridSize = gridSize
        self.cells = cells
    }
}

extension LevelPrefill.Cell {
    private enum CodingKeys: String, CodingKey {
        case row
        case column
        case color
        case isLocked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        row = try container.decode(Int.self, forKey: .row)
        column = try container.decode(Int.self, forKey: .column)
        let colorRaw = try container.decode(String.self, forKey: .color)
        guard let decodedColor = BlockColor(rawValue: colorRaw) else {
            throw DecodingError.dataCorruptedError(forKey: .color, in: container, debugDescription: "Unknown block color \(colorRaw)")
        }
        color = decodedColor
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(row, forKey: .row)
        try container.encode(column, forKey: .column)
        try container.encode(color.rawValue, forKey: .color)
        try container.encode(isLocked, forKey: .isLocked)
    }
}

// MARK: - Rewards & Unlocks

enum UnlockRequirementType: String, Codable {
    case none
    case stars
    case level
    case pack
}

struct UnlockRequirement: Codable, Equatable {
    let type: UnlockRequirementType
    let value: Int?

    static let none = UnlockRequirement(type: .none, value: nil)

    init(type: UnlockRequirementType, value: Int?) {
        self.type = type
        self.value = value
    }
}

enum UnlockType: String, Codable {
    case theme
    case powerUp
    case badge
    case avatar
}

struct LevelRewards: Codable, Equatable {
    let xp: Int
    let coins: Int
    let unlock: UnlockType?

    init(xp: Int, coins: Int, unlock: UnlockType? = nil) {
        self.xp = xp
        self.coins = coins
        self.unlock = unlock
    }
}

// MARK: - Level Definition

struct Level: Identifiable, Codable, Equatable {
    let id: Int
    let packID: Int
    let indexInPack: Int
    let title: String
    let description: String
    let objective: LevelObjective
    let constraints: LevelConstraints
    let prefill: LevelPrefill?
    let starThresholds: LevelStarThresholds
    let rewards: LevelRewards
    let difficulty: DifficultyLevel
    let unlockRequirement: UnlockRequirement
}

struct LevelPack: Identifiable, Codable, Equatable {
    struct Visual: Codable, Equatable {
        let primaryHex: String
        let secondaryHex: String
        let iconName: String

        init(primaryHex: String, secondaryHex: String, iconName: String) {
            self.primaryHex = primaryHex
            self.secondaryHex = secondaryHex
            self.iconName = iconName
        }
    }

    let id: Int
    let title: String
    let subtitle: String
    let difficultyBand: DifficultyLevel
    let visual: Visual
    let xpReward: Int
    let coinReward: Int
    let completionReward: UnlockType?
    let levels: [Level]
}

// MARK: - Session Summary

struct LevelSessionSummary: Equatable {
    let levelID: Int
    let score: Int
    let movesUsed: Int
    let remainingMoves: Int?
    let timeRemaining: Int?
    let holdsUsed: Int
    let undosUsed: Int
    let perfectClears: Int
    let maxComboAchieved: Int
}
