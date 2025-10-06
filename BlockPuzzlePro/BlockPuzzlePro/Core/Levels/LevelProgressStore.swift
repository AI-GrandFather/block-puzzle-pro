import Foundation

struct LevelProgress: Codable, Equatable {
    var bestStars: Int
    var bestScore: Int
    var totalAttempts: Int
    var lastPlayed: Date?

    init(bestStars: Int = 0, bestScore: Int = 0, totalAttempts: Int = 0, lastPlayed: Date? = nil) {
        self.bestStars = bestStars
        self.bestScore = bestScore
        self.totalAttempts = totalAttempts
        self.lastPlayed = lastPlayed
    }
}

@MainActor
final class LevelProgressStore: ObservableObject {
    static let shared = LevelProgressStore(repository: .shared)

    @Published private(set) var progress: [Int: LevelProgress]

    private let repository: LevelsRepository
    private let defaults: UserDefaults
    private let storageKey = "levels_progress_records"

    init(repository: LevelsRepository, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
        self.progress = [:]
        load()
    }

    func recordCompletion(summary: LevelSessionSummary, stars: Int) {
        var entry = progress[summary.levelID, default: LevelProgress()]
        entry.bestStars = max(entry.bestStars, stars)
        entry.bestScore = max(entry.bestScore, summary.score)
        entry.totalAttempts += 1
        entry.lastPlayed = Date()
        progress[summary.levelID] = entry
        persist()
    }

    func recordAttempt(levelID: Int) {
        var entry = progress[levelID, default: LevelProgress()]
        entry.totalAttempts += 1
        entry.lastPlayed = Date()
        progress[levelID] = entry
        persist()
    }

    func recordFailure(levelID: Int) {
        var entry = progress[levelID, default: LevelProgress()]
        entry.totalAttempts += 1
        entry.lastPlayed = Date()
        progress[levelID] = entry
        persist()
    }

    func progress(for levelID: Int) -> LevelProgress {
        progress[levelID, default: LevelProgress()]
    }

    func starsEarned(in pack: LevelPack) -> Int {
        pack.levels.reduce(0) { partialResult, level in
            partialResult + progress(for: level.id).bestStars
        }
    }

    func completedLevels(in pack: LevelPack) -> Int {
        pack.levels.filter { progress(for: $0.id).bestStars > 0 }.count
    }

    func isLevelUnlocked(_ level: Level) -> Bool {
        switch level.unlockRequirement.type {
        case .none:
            return true
        case .level:
            guard let requiredID = level.unlockRequirement.value else { return true }
            return progress(for: requiredID).bestStars > 0
        case .stars:
            guard let required = level.unlockRequirement.value,
                  let pack = repository.pack(with: level.packID) else { return false }
            return starsEarned(in: pack) >= required
        case .pack:
            guard let requiredPackID = level.unlockRequirement.value,
                  let requiredPack = repository.pack(with: requiredPackID) else { return false }
            return completedLevels(in: requiredPack) == requiredPack.levels.count
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else {
            progress = [:]
            return
        }
        do {
            let decoded = try JSONDecoder().decode([Int: LevelProgress].self, from: data)
            progress = decoded
        } catch {
            progress = [:]
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(progress)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Silently fail, but avoid crashing the app
        }
    }
}
