import Foundation

/// Represents the breakdown for a single scoring update.
struct ScoreBreakdown: Equatable {
    let placedCells: Int
    let linesCleared: Int
    let placementPoints: Int
    let lineClearBonus: Int

    var totalPoints: Int {
        placementPoints + lineClearBonus
    }
}

/// Captures the public-facing score event after applying a breakdown.
struct ScoreEvent: Equatable {
    let placedCells: Int
    let linesCleared: Int
    let placementPoints: Int
    let lineClearBonus: Int
    let totalDelta: Int
    let newTotal: Int
    let highScore: Int
    let isNewHighScore: Bool
}

/// Calculates and tracks score progression for the current game session.
struct ScoreTracker {
    private(set) var totalScore: Int = 0
    private(set) var bestScore: Int = 0

    mutating func reset() {
        totalScore = 0
    }

    mutating func restore(totalScore: Int, bestScore: Int) {
        self.totalScore = max(0, totalScore)
        self.bestScore = max(self.totalScore, bestScore)
    }

    mutating func recordPlacement(placedCells: Int, linesCleared: Int) -> ScoreBreakdown {
        let placementPoints = max(0, placedCells)
        let lineClearBonus = bonus(for: linesCleared)
        totalScore += placementPoints + lineClearBonus

        if totalScore > bestScore {
            bestScore = totalScore
        }

        return ScoreBreakdown(
            placedCells: placementPoints > 0 ? placedCells : 0,
            linesCleared: max(0, linesCleared),
            placementPoints: placementPoints,
            lineClearBonus: lineClearBonus
        )
    }

    private func bonus(for linesCleared: Int) -> Int {
        guard linesCleared > 0 else { return 0 }

        // Base 100 points per line plus exponential bonus for combos.
        let base = 100 * linesCleared
        let comboMultiplier = (1 << max(linesCleared - 1, 0)) - 1
        return base + (comboMultiplier * 100)
    }
}
