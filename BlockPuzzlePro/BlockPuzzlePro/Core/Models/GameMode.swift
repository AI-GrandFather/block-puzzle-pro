
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
            return "Play & Relax"
        case .timedThreeMinutes:
            return "Quick Play (3 Min)"
        case .timedFiveMinutes:
            return "Beat the Clock (5 Min)"
        case .timedSevenMinutes:
            return "Time Challenge (7 Min)"
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
