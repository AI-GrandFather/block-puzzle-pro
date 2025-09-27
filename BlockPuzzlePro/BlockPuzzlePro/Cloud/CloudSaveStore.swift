import Foundation
import Supabase

@MainActor
final class CloudSaveStore: ObservableObject {
    @Published private(set) var saves: [GameMode: GameSavePayload] = [:]
    @Published private(set) var isSyncing: Bool = false
    @Published var lastError: String?

    private var currentUserID: UUID?

    func configure(session: Session?) {
        currentUserID = session?.user.id
        if session == nil {
            saves.removeAll()
            lastError = nil
        }
    }

    func refresh(for session: Session) async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let userID = session.user.id
        currentUserID = userID

        do {
            let response: PostgrestResponse<[UserProgressRecord]> = try await SupabaseService.shared
                .from("user_progress")
                .select()
                .eq("user_id", value: userID.uuidString)
                .execute()

            let records = response.value

            var result: [GameMode: GameSavePayload] = [:]
            for record in records {
                guard let mode = GameMode(rawValue: record.game_mode) else { continue }
                if let payload = record.save_blob {
                    result[mode] = payload
                }
            }
            saves = result
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func save(payload: GameSavePayload, mode: GameMode) async {
        guard let userID = currentUserID else { return }

        let upsert = UserProgressUpsertInput(
            user_id: userID,
            game_mode: mode.rawValue,
            save_blob: payload,
            high_score: payload.highScore
        )

        do {
            _ = try await SupabaseService.shared
                .from("user_progress")
                .upsert(
                    upsert,
                    onConflict: "user_id,game_mode",
                    returning: .minimal
                )
                .execute()
            saves[mode] = payload
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
