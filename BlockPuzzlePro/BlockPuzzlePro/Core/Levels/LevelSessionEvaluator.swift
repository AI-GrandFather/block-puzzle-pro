import Foundation

enum LevelFailureReason: Equatable {
    case objectiveFailed
    case outOfMoves
    case timeExpired
}

struct LevelSessionResult: Equatable {
    let summary: LevelSessionSummary
    let starsEarned: Int
}

enum LevelEvaluationError: Error {
    case invalidConfiguration
}

enum LevelSessionEvaluator {
    static func evaluate(level: Level, summary: LevelSessionSummary, objectiveFulfilled: Bool) -> LevelSessionResult {
        let stars = starCount(for: level, summary: summary, objectiveFulfilled: objectiveFulfilled)
        return LevelSessionResult(summary: summary, starsEarned: stars)
    }

    private static func starCount(for level: Level, summary: LevelSessionSummary, objectiveFulfilled: Bool) -> Int {
        guard objectiveFulfilled else { return 0 }

        let requirements = [
            level.starThresholds.oneStar,
            level.starThresholds.twoStar,
            level.starThresholds.threeStar
        ]

        var stars = 0
        for requirement in requirements {
            if requirement.isSatisfied(by: summary, level: level, objectiveFulfilled: objectiveFulfilled) {
                stars += 1
            } else {
                break
            }
        }
        return stars
    }
}

private extension StarRequirement {
    func isSatisfied(by summary: LevelSessionSummary, level: Level, objectiveFulfilled: Bool) -> Bool {
        switch type {
        case .score:
            return summary.score >= value
        case .movesRemaining:
            guard let moveLimit = level.constraints.moveLimit else { return true }
            let remaining = max(0, moveLimit - summary.movesUsed)
            return remaining >= value
        case .timeRemaining:
            guard let remaining = summary.timeRemaining else { return false }
            return remaining >= value
        case .noHoldsUsed:
            return summary.holdsUsed <= value
        case .noUndosUsed:
            return summary.undosUsed <= value
        case .perfectClears:
            return summary.perfectClears >= value
        case .comboAchieved:
            return summary.maxComboAchieved >= value
        case .specificObjective:
            return objectiveFulfilled && summary.score >= 0
        }
    }
}
