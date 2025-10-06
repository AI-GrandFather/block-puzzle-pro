import Foundation
import Combine

@MainActor
final class LevelSessionCoordinator: ObservableObject {
    enum State: Equatable {
        case idle
        case running
        case success(LevelSessionResult)
        case failed(LevelFailureReason)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var movesUsed: Int = 0
    @Published private(set) var linesCleared: Int = 0
    @Published private(set) var timeRemaining: Int?
    @Published private(set) var objectiveFulfilled: Bool = false

    let level: Level

    private let gameEngine: GameEngine
    private let placementEngine: PlacementEngine
    private let progressStore: LevelProgressStore

    private var cancellables: Set<AnyCancellable> = []
    private var timerTask: Task<Void, Never>?
    private var perfectClearCount: Int = 0
    private var maxComboAchieved: Int = 0

    init(level: Level,
         gameEngine: GameEngine,
         placementEngine: PlacementEngine,
         progressStore: LevelProgressStore = .shared) {
        self.level = level
        self.gameEngine = gameEngine
        self.placementEngine = placementEngine
        self.progressStore = progressStore

        observeGameEngine()
        observePlacementEngine()
    }

    deinit {
        timerTask?.cancel()
    }

    func begin() {
        movesUsed = 0
        linesCleared = 0
        perfectClearCount = 0
        maxComboAchieved = 0
        objectiveFulfilled = false
        timeRemaining = computeInitialTimeLimit()

        if let prefill = level.prefill {
            gameEngine.apply(prefill: prefill)
        }

        startTimerIfNeeded()
        state = .running
        progressStore.recordAttempt(levelID: level.id)
        evaluateObjectiveFulfilment()
    }

    func concludeDueToManualExit() {
        timerTask?.cancel()
        state = .idle
    }

    private func observeGameEngine() {
        gameEngine.$score
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.evaluateObjectiveFulfilment()
            }
            .store(in: &cancellables)
    }

    private func observePlacementEngine() {
        placementEngine.onPlacementCommitted = { [weak self] context in
            guard let self else { return }
            self.handlePlacement(context: context)
        }
    }

    private func handlePlacement(context: PlacementCommitContext) {
        guard case .running = state else { return }

        movesUsed += 1
        linesCleared += context.lineClearResult.totalClearedLines
        maxComboAchieved = max(maxComboAchieved, context.lineClearResult.totalClearedLines)

        if isBoardEmpty() {
            perfectClearCount += 1
        }

        evaluateObjectiveFulfilment()
        checkForFailureAfterPlacement()
        finalizeIfObjectiveComplete()
    }

    private func computeInitialTimeLimit() -> Int? {
        if let explicit = level.constraints.timeLimit {
            return explicit
        }
        if level.objective.type == .surviveTime {
            return level.objective.targetValue
        }
        return nil
    }

    private func startTimerIfNeeded() {
        guard let initial = timeRemaining else { return }
        timerTask?.cancel()
        timeRemaining = initial
        timerTask = Task { [weak self] in
            guard let self else { return }
            while let remaining = self.timeRemaining, remaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.timeRemaining = max(0, remaining - 1)
                    if self.timeRemaining == 0 {
                        self.handleTimerExpired()
                    }
                }
            }
        }
    }

    private func handleTimerExpired() {
        guard case .running = state else { return }
        if level.objective.type == .surviveTime {
            objectiveFulfilled = true
            finalizeIfObjectiveComplete()
        } else {
            triggerFailure(reason: .timeExpired)
        }
    }

    private func checkForFailureAfterPlacement() {
        if let moveLimit = level.constraints.moveLimit, movesUsed > moveLimit {
            triggerFailure(reason: .outOfMoves)
        }
    }

    private func finalizeIfObjectiveComplete() {
        guard case .running = state, objectiveFulfilled else { return }

        timerTask?.cancel()

        let summary = LevelSessionSummary(
            levelID: level.id,
            score: gameEngine.score,
            movesUsed: movesUsed,
            remainingMoves: level.constraints.moveLimit.map { max(0, $0 - movesUsed) },
            timeRemaining: timeRemaining,
            holdsUsed: 0,
            undosUsed: 0,
            perfectClears: perfectClearCount,
            maxComboAchieved: maxComboAchieved
        )

        let result = LevelSessionEvaluator.evaluate(level: level, summary: summary, objectiveFulfilled: true)
        progressStore.recordCompletion(summary: summary, stars: result.starsEarned)
        state = .success(result)
    }

    private func triggerFailure(reason: LevelFailureReason) {
        timerTask?.cancel()
        state = .failed(reason)
        progressStore.recordFailure(levelID: level.id)
    }

    private func evaluateObjectiveFulfilment() {
        objectiveFulfilled = checkObjectiveSatisfied()
    }

    private func checkObjectiveSatisfied() -> Bool {
        switch level.objective.type {
        case .reachScore:
            return gameEngine.score >= level.objective.targetValue
        case .clearLines:
            return linesCleared >= level.objective.targetValue
        case .createPattern:
            guard let pattern = level.objective.pattern else { return false }
            return patternSatisfied(pattern)
        case .surviveTime:
            return false // handled via timer completion
        case .clearAllBlocks:
            return isBoardEmpty()
        case .clearSpecificColor:
            return false
        case .achieveCombo:
            return maxComboAchieved >= level.objective.targetValue
        case .perfectClear:
            return perfectClearCount >= level.objective.targetValue
        case .useOnlyPieces:
            return false
        case .clearWithMoves:
            if let limit = level.constraints.moveLimit {
                return movesUsed <= limit && isBoardEmpty()
            }
            return false
        }
    }

    private func patternSatisfied(_ pattern: PatternType) -> Bool {
        switch pattern {
        case .twoByTwoSquare:
            return containsBlock(width: 2, height: 2)
        case .filledCorners:
            return cornersFilled()
        case .filledCentre:
            return centreFilled()
        case .diagonal:
            return diagonalFilled()
        case .checkerboard:
            return checkerboardHighlightSatisfied()
        }
    }

    private func containsBlock(width: Int, height: Int) -> Bool {
        let grid = gameEngine.gameGrid
        guard !grid.isEmpty else { return false }
        let size = grid.count
        guard width <= size, height <= size else { return false }

        for row in 0...(size - height) {
            for column in 0...(size - width) {
                var filled = true
                for dy in 0..<height where filled {
                    for dx in 0..<width {
                        if !grid[row + dy][column + dx].isOccupied {
                            filled = false
                            break
                        }
                    }
                }
                if filled { return true }
            }
        }
        return false
    }

    private func cornersFilled() -> Bool {
        let grid = gameEngine.gameGrid
        guard !grid.isEmpty else { return false }
        let maxIndex = grid.count - 1
        return grid[0][0].isOccupied &&
            grid[0][maxIndex].isOccupied &&
            grid[maxIndex][0].isOccupied &&
            grid[maxIndex][maxIndex].isOccupied
    }

    private func centreFilled() -> Bool {
        let grid = gameEngine.gameGrid
        guard !grid.isEmpty else { return false }
        let mid = grid.count / 2
        let positions = [
            (mid, mid),
            (mid - 1, mid),
            (mid, mid - 1),
            (mid - 1, mid - 1)
        ].filter { $0.0 >= 0 && $0.1 >= 0 && $0.0 < grid.count && $0.1 < grid.count }
        return positions.allSatisfy { grid[$0.0][$0.1].isOccupied }
    }

    private func diagonalFilled() -> Bool {
        let grid = gameEngine.gameGrid
        guard !grid.isEmpty else { return false }
        let size = grid.count
        for index in 0..<size {
            if !grid[index][index].isOccupied { return false }
        }
        return true
    }

    private func checkerboardHighlightSatisfied() -> Bool {
        let grid = gameEngine.gameGrid
        guard !grid.isEmpty else { return false }
        var matches = 0
        for row in 0..<grid.count {
            for column in 0..<grid[row].count {
                if (row + column).isMultiple(of: 2) && grid[row][column].isOccupied {
                    matches += 1
                }
            }
        }
        return matches >= level.objective.targetValue
    }

    private func isBoardEmpty() -> Bool {
        gameEngine.gameGrid.flatMap { $0 }.allSatisfy { $0.isEmpty }
    }
}
