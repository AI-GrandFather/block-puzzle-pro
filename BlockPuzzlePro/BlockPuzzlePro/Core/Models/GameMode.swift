
import Foundation

enum GameMode: String, CaseIterable, Identifiable, Hashable {
    case classic
    case timedThreeMinutes
    case timedFiveMinutes
    case timedSevenMinutes

    var id: String { rawValue }

    var gridSize: Int {
        switch self {
        case .classic,
             .timedThreeMinutes,
             .timedFiveMinutes,
             .timedSevenMinutes:
            return 8
        }
    }

    var displayName: String {
        switch self {
        case .classic:
            return "Classic 8×8"
        case .timedThreeMinutes:
            return "3 Minute Challenge"
        case .timedFiveMinutes:
            return "5 Minute Challenge"
        case .timedSevenMinutes:
            return "7 Minute Challenge"
        }
    }

    var isTimed: Bool {
        switch self {
        case .timedThreeMinutes, .timedFiveMinutes, .timedSevenMinutes:
            return true
        case .classic:
            return false
        }
    }

    var timerDuration: TimeInterval? {
        switch self {
        case .timedThreeMinutes:
            return 180 // 3 * 60
        case .timedFiveMinutes:
            return 300 // 5 * 60
        case .timedSevenMinutes:
            return 420 // 7 * 60
        case .classic:
            return nil
        }
    }
}
