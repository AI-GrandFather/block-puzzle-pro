import Foundation

struct GridCellPayload: Codable {
    enum State: String, Codable {
        case empty
        case occupied
        case preview
    }

    let state: State
    let color: String?
}

struct BlockPatternPayload: Codable {
    let type: String
    let color: String
    let cells: [[Bool]]?
}

struct GameSavePayload: Codable {
    let version: Int
    let timestamp: Date
    let score: Int
    let highScore: Int
    let isGameActive: Bool
    let grid: [[GridCellPayload]]
    let tray: [BlockPatternPayload?]
}

struct UserProgressRecord: Codable {
    let id: UUID?
    let user_id: UUID
    let game_mode: String
    let save_blob: GameSavePayload?
    let high_score: Int
    let updated_at: Date?
}

struct UserProgressUpsertInput: Codable {
    let user_id: UUID
    let game_mode: String
    let save_blob: GameSavePayload
    let high_score: Int
}
