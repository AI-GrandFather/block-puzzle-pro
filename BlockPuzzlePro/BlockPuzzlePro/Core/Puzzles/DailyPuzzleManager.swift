import Foundation

@MainActor
final class DailyPuzzleManager: ObservableObject {
    static let shared = DailyPuzzleManager()

    @Published private(set) var todayPuzzle: Puzzle
    @Published private(set) var archive: [Puzzle]
    @Published private(set) var progress: [String: PuzzleProgress]

    private let storageKey = "puzzle_progress_records"
    private let calendar: Calendar

    private init(calendar: Calendar = .current) {
        self.calendar = calendar
        self.progress = [:]
        self.archive = []

        let today = calendar.startOfDay(for: Date())
        self.todayPuzzle = DailyPuzzleManager.generatePuzzle(for: today)
        self.archive = Self.generateArchive(upTo: today)

        loadProgress()
    }

    func refreshIfNeeded(currentDate: Date = Date()) {
        let startOfDay = calendar.startOfDay(for: currentDate)
        guard startOfDay != todayPuzzle.id.date else { return }
        todayPuzzle = DailyPuzzleManager.generatePuzzle(for: startOfDay)
        archive = Self.generateArchive(upTo: startOfDay)
    }

    func markSolved(puzzle: Puzzle, time: TimeInterval?) {
        var entry = progress[puzzle.id.formattedDate, default: PuzzleProgress()]
        entry.isSolved = true
        if let time {
            entry.bestTime = min(entry.bestTime ?? time, time)
        }
        entry.lastPlayed = Date()
        progress[puzzle.id.formattedDate] = entry
        persistProgress()
    }

    func recordAttempt(puzzle: Puzzle) {
        var entry = progress[puzzle.id.formattedDate, default: PuzzleProgress()]
        entry.attempts += 1
        entry.lastPlayed = Date()
        progress[puzzle.id.formattedDate] = entry
        persistProgress()
    }

    func progress(for puzzle: Puzzle) -> PuzzleProgress {
        progress[puzzle.id.formattedDate, default: PuzzleProgress()]
    }

    func puzzle(with identifier: String) -> Puzzle? {
        if todayPuzzle.id.formattedDate == identifier {
            return todayPuzzle
        }
        return archive.first { $0.id.formattedDate == identifier }
    }

    func asLevel(for puzzle: Puzzle) -> Level {
        let baseID = abs(Int(puzzle.id.seed % UInt64(Int.max)))
        let levelObjective: LevelObjective
        switch puzzle.objective.type {
        case .clearLines:
            levelObjective = LevelObjective(type: .clearLines, targetValue: puzzle.objective.value)
        case .reachScore:
            levelObjective = LevelObjective(type: .reachScore, targetValue: puzzle.objective.value)
        case .clearBoard:
            levelObjective = LevelObjective(type: .clearAllBlocks, targetValue: 1)
        case .surviveTime:
            levelObjective = LevelObjective(type: .surviveTime, targetValue: Int(puzzle.timeLimit ?? puzzle.objective.value.toTimeInterval))
        }

        let constraints = LevelConstraints(
            moveLimit: puzzle.moveLimit,
            timeLimit: puzzle.timeLimit.map { Int($0) },
            allowedPieces: puzzle.availablePieces
        )

        let thresholds = LevelStarThresholds(
            oneStar: StarRequirement(type: .specificObjective, value: 1),
            twoStar: StarRequirement(type: .movesRemaining, value: max(1, puzzle.parMoves)),
            threeStar: StarRequirement(type: .timeRemaining, value: Int(puzzle.parTime))
        )

        let rewards = LevelRewards(
            xp: puzzle.xpReward,
            coins: puzzle.coinReward,
            unlock: nil
        )

        return Level(
            id: 10_000 + baseID,
            packID: 0,
            indexInPack: 0,
            title: puzzle.title,
            description: puzzle.description,
            objective: levelObjective,
            constraints: constraints,
            prefill: puzzle.prefill,
            starThresholds: thresholds,
            rewards: rewards,
            difficulty: mapDifficulty(puzzle.difficulty),
            unlockRequirement: .none
        )
    }

    private func mapDifficulty(_ difficulty: PuzzleDifficulty) -> DifficultyLevel {
        switch difficulty {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        case .expert: return .expert
        }
    }

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            progress = try JSONDecoder().decode([String: PuzzleProgress].self, from: data)
        } catch {
            progress = [:]
        }
    }

    private func persistProgress() {
        do {
            let data = try JSONEncoder().encode(progress)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // ignore persistence failures for now
        }
    }
}

private extension DailyPuzzleManager {
    static func generatePuzzle(for date: Date) -> Puzzle {
        let seed = Self.seed(for: date)
        var generator = SeededGenerator(seed: seed)

        let difficulty = pickDifficulty(date: date)
        let category = pickCategory(generator: &generator)
        let id = PuzzleID(date: date, seed: seed)

        let objective: PuzzleObjective
        let moveLimit: Int?
        let timeLimit: TimeInterval?
        let parMoves: Int
        let parTime: TimeInterval
        let prefill = PrefillFactory.prefill(for: category, generator: &generator)
        let pieces = PrefillFactory.pieces(for: category)

        switch category {
        case .clearInOne:
            // Easy: 3 moves, Medium: 2 moves, Hard+: 1 move
            let moves = difficulty == .easy ? 3 : (difficulty == .medium ? 2 : 1)
            objective = PuzzleObjective(type: .clearBoard, value: 1)
            moveLimit = moves
            timeLimit = nil
            parMoves = moves
            parTime = 60
        case .patternMatch:
            // Clear 3-5 lines based on difficulty
            let lines = difficulty == .easy ? 3 : (difficulty == .medium ? 4 : 5)
            let moves = difficulty == .easy ? 8 : (difficulty == .medium ? 6 : 5)
            objective = PuzzleObjective(type: .clearLines, value: lines)
            moveLimit = moves
            timeLimit = nil
            parMoves = max(moves - 2, 3)
            parTime = 180
        case .blockBreaker:
            // Realistic scoring: Easy: 150pts (~10 moves), Medium: 250pts, Hard: 400pts
            let score = difficulty == .easy ? 150 : (difficulty == .medium ? 250 : 400)
            let moves = difficulty == .easy ? 12 : (difficulty == .medium ? 18 : 30)
            objective = PuzzleObjective(type: .reachScore, value: score)
            moveLimit = moves
            timeLimit = nil
            parMoves = max(moves - 3, 8)
            parTime = 240
        case .comboBuilder:
            // Clear 5-10 lines based on difficulty
            let lines = difficulty == .easy ? 5 : (difficulty == .medium ? 7 : 10)
            let moves = difficulty == .easy ? 12 : (difficulty == .medium ? 15 : 20)
            objective = PuzzleObjective(type: .clearLines, value: lines)
            moveLimit = moves
            timeLimit = nil
            parMoves = max(moves - 4, 8)
            parTime = 260
        case .survival:
            objective = PuzzleObjective(type: .surviveTime, value: Int(difficulty.targetSolveTime))
            moveLimit = nil
            timeLimit = difficulty.targetSolveTime * 1.2
            parMoves = 0
            parTime = difficulty.targetSolveTime
        case .constraint:
            // Adjust constraint difficulty too
            let lines = difficulty == .easy ? 4 : (difficulty == .medium ? 5 : 6)
            let moves = difficulty == .easy ? 8 : (difficulty == .medium ? 7 : 6)
            objective = PuzzleObjective(type: .clearLines, value: lines)
            moveLimit = moves
            timeLimit = nil
            parMoves = max(moves - 1, 4)
            parTime = 200
        }

        return Puzzle(
            id: id,
            category: category,
            difficulty: difficulty,
            title: title(for: category, difficulty: difficulty),
            description: description(for: category),
            gridSize: 10,
            prefill: prefill,
            objective: objective,
            availablePieces: pieces,
            moveLimit: moveLimit,
            timeLimit: timeLimit,
            parMoves: parMoves,
            parTime: parTime,
            xpReward: rewardXP(for: difficulty),
            coinReward: rewardCoins(for: difficulty)
        )
    }

    static func generateArchive(upTo date: Date) -> [Puzzle] {
        (1...7).compactMap { offset -> Puzzle? in
            guard let pastDate = Calendar.current.date(byAdding: .day, value: -offset, to: date) else { return nil }
            return generatePuzzle(for: pastDate)
        }
    }

    static func seed(for date: Date) -> UInt64 {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyyMMdd"
        let str = formatter.string(from: date)
        // Use bitPattern to safely convert Int (which can be negative) to UInt64
        return UInt64(bitPattern: Int64(str.hashValue))
    }

    static func pickDifficulty(date: Date) -> PuzzleDifficulty {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1, 7: return .expert
        case 6: return .hard
        case 3, 4: return .medium
        default: return .easy
        }
    }

    static func pickCategory(generator: inout SeededGenerator) -> PuzzleCategory {
        let categories = PuzzleCategory.allCases
        let index = Int.random(in: 0..<categories.count, using: &generator)
        return categories[index]
    }

    static func title(for category: PuzzleCategory, difficulty: PuzzleDifficulty) -> String {
        switch category {
        case .clearInOne: return "Perfect Placement"
        case .patternMatch: return "Pattern Play"
        case .blockBreaker: return "Block Breaker"
        case .comboBuilder: return "Combo Quest"
        case .survival: return "Survival Run"
        case .constraint: return "Limited Moves"
        }
    }

    static func description(for category: PuzzleCategory) -> String {
        switch category {
        case .clearInOne:
            return "Find the single move that clears the entire board."
        case .patternMatch:
            return "Recreate the highlighted pattern with the available pieces."
        case .blockBreaker:
            return "Crack the pre-filled core and rack up points."
        case .comboBuilder:
            return "Chain together precise clears to hit the combo target."
        case .survival:
            return "Hold out as long as you can before the clock hits zero."
        case .constraint:
            return "Limited moves. No mistakes. Plan every placement."
        }
    }

    static func rewardXP(for difficulty: PuzzleDifficulty) -> Int {
        switch difficulty {
        case .easy: return 300
        case .medium: return 500
        case .hard: return 800
        case .expert: return 1200
        }
    }

    static func rewardCoins(for difficulty: PuzzleDifficulty) -> Int {
        switch difficulty {
        case .easy: return 100
        case .medium: return 150
        case .hard: return 200
        case .expert: return 300
        }
    }
}

// MARK: - Utilities

private extension Int {
    var toTimeInterval: TimeInterval { TimeInterval(self) }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

private enum PrefillFactory {
    static func prefill(for category: PuzzleCategory, generator: inout SeededGenerator) -> LevelPrefill? {
        switch category {
        case .clearInOne:
            return LevelPrefill(cells: makeRing(color: .blue))
        case .patternMatch:
            return LevelPrefill(cells: makePattern(color: .purple))
        case .blockBreaker:
            return LevelPrefill(cells: makeCore(color: .orange))
        case .comboBuilder:
            return LevelPrefill(cells: makeStaggered(color: .green))
        case .survival:
            return nil
        case .constraint:
            return LevelPrefill(cells: makeConstraint(color: .red))
        }
    }

    static func pieces(for category: PuzzleCategory) -> [BlockType]? {
        switch category {
        case .clearInOne:
            return [.triLine, .tetL, .tetSquare]
        case .patternMatch:
            return [.tetT, .triCorner, .almostSquare, .tetSquare]
        case .blockBreaker:
            return [.tetLine, .tetL, .tetSkew]
        case .comboBuilder:
            return [.triLine, .triCorner, .tetSquare, .domino]
        case .survival:
            return nil
        case .constraint:
            return [.tetSquare, .domino, .triCorner]
        }
    }

    private static func makeRing(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        for index in 1..<9 {
            cells.append(.init(row: 1, column: index, color: color))
            cells.append(.init(row: 8, column: index, color: color))
            cells.append(.init(row: index, column: 1, color: color))
            cells.append(.init(row: index, column: 8, color: color))
        }
        return cells
    }

    private static func makePattern(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        for offset in 2...7 {
            cells.append(.init(row: offset, column: offset, color: color))
        }
        return cells
    }

    private static func makeCore(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        for row in 3...6 {
            for column in 3...6 {
                cells.append(.init(row: row, column: column, color: color))
            }
        }
        return cells
    }

    private static func makeStaggered(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        for row in 2..<9 {
            for column in 2..<9 where (row + column).isMultiple(of: 2) {
                cells.append(.init(row: row, column: column, color: color))
            }
        }
        return cells
    }

    private static func makeConstraint(color: BlockColor) -> [LevelPrefill.Cell] {
        var cells: [LevelPrefill.Cell] = []
        for row in 0..<10 {
            cells.append(.init(row: row, column: 0, color: color, isLocked: row.isMultiple(of: 2)))
        }
        return cells
    }
}
