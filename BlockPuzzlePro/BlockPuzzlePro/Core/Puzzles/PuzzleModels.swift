import Foundation

// MARK: - Puzzle Identifiers

struct PuzzleID: Codable, Hashable, Identifiable {
    let date: Date
    let seed: UInt64

    var id: String { formattedDate }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - Difficulty & Categories

enum PuzzleDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    case expert

    var id: String { rawValue }

    var colorName: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "orange"
        case .expert: return "red"
        }
    }

    var targetSolveTime: TimeInterval {
        switch self {
        case .easy: return 60
        case .medium: return 180
        case .hard: return 300
        case .expert: return 600
        }
    }
}

enum PuzzleCategory: String, Codable, CaseIterable, Identifiable {
    case clearInOne
    case patternMatch
    case blockBreaker
    case comboBuilder
    case survival
    case constraint

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clearInOne: return "Clear in One"
        case .patternMatch: return "Pattern Match"
        case .blockBreaker: return "Block Breaker"
        case .comboBuilder: return "Combo Builder"
        case .survival: return "Survival"
        case .constraint: return "Constraint"
        }
    }
}

// MARK: - Puzzle Objective

enum PuzzleObjectiveType: String, Codable {
    case clearLines
    case reachScore
    case clearBoard
    case surviveTime
}

struct PuzzleObjective: Codable, Equatable {
    let type: PuzzleObjectiveType
    let value: Int

    init(type: PuzzleObjectiveType, value: Int) {
        self.type = type
        self.value = value
    }
}

// MARK: - Puzzle Model

struct Puzzle: Codable, Identifiable {
    let id: PuzzleID
    let category: PuzzleCategory
    let difficulty: PuzzleDifficulty
    let title: String
    let description: String

    let gridSize: Int
    let prefill: LevelPrefill?

    let objective: PuzzleObjective
    let availablePieces: [BlockType]?
    let moveLimit: Int?
    let timeLimit: TimeInterval?

    let parMoves: Int
    let parTime: TimeInterval

    let xpReward: Int
    let coinReward: Int

    init(
        id: PuzzleID,
        category: PuzzleCategory,
        difficulty: PuzzleDifficulty,
        title: String,
        description: String,
        gridSize: Int,
        prefill: LevelPrefill?,
        objective: PuzzleObjective,
        availablePieces: [BlockType]?,
        moveLimit: Int?,
        timeLimit: TimeInterval?,
        parMoves: Int,
        parTime: TimeInterval,
        xpReward: Int,
        coinReward: Int
    ) {
        self.id = id
        self.category = category
        self.difficulty = difficulty
        self.title = title
        self.description = description
        self.gridSize = gridSize
        self.prefill = prefill
        self.objective = objective
        self.availablePieces = availablePieces
        self.moveLimit = moveLimit
        self.timeLimit = timeLimit
        self.parMoves = parMoves
        self.parTime = parTime
        self.xpReward = xpReward
        self.coinReward = coinReward
    }
}

struct PuzzleProgress: Codable {
    var isSolved: Bool
    var attempts: Int
    var bestTime: TimeInterval?
    var lastPlayed: Date?

    init(isSolved: Bool = false, attempts: Int = 0, bestTime: TimeInterval? = nil, lastPlayed: Date? = nil) {
        self.isSolved = isSolved
        self.attempts = attempts
        self.bestTime = bestTime
        self.lastPlayed = lastPlayed
    }
}
