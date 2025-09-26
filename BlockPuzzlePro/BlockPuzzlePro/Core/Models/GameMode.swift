
import Foundation

enum GameMode: String, CaseIterable, Identifiable, Hashable {
    case grid8x8
    case grid10x10

    var id: String { rawValue }

    var gridSize: Int {
        switch self {
        case .grid8x8:
            return 8
        case .grid10x10:
            return 10
        }
    }

    var displayName: String {
        switch self {
        case .grid8x8:
            return "8×8 Grid"
        case .grid10x10:
            return "10×10 Grid"
        }
    }
}
