import Foundation

// MARK: - Session Summary

struct ZenSessionSummary: Codable {
    let date: Date
    let duration: TimeInterval
    let blocksPlaced: Int
    let linesCleared: Int
    let perfectClears: Int
    let mood: ZenMood?

    var displayDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Zen Mood

enum ZenMood: String, Codable, CaseIterable {
    case calm = "Calm"
    case focused = "Focused"
    case relaxed = "Relaxed"
    case energized = "Energized"
    case peaceful = "Peaceful"

    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .focused: return "🎯"
        case .relaxed: return "😊"
        case .energized: return "⚡"
        case .peaceful: return "🕊️"
        }
    }

    var displayName: String {
        return "\(emoji) \(rawValue)"
    }
}

// MARK: - Zen Statistics

/// Track personal insights for Zen Mode - NO competition, NO comparisons
@Observable
class ZenStatistics: Codable {
    // Session stats
    var totalSessions: Int = 0
    var totalPlayTime: TimeInterval = 0
    var longestSession: TimeInterval = 0

    // Gameplay stats
    var totalBlocksPlaced: Int = 0
    var totalLinesCleared: Int = 0
    var totalPerfectClears: Int = 0

    // Streaks
    var currentDailyStreak: Int = 0
    var longestDailyStreak: Int = 0
    var lastPlayedDate: Date?

    // Session history
    var playHistory: [Date: ZenSessionSummary] = [:]

    enum CodingKeys: CodingKey {
        case totalSessions, totalPlayTime, longestSession
        case totalBlocksPlaced, totalLinesCleared, totalPerfectClears
        case currentDailyStreak, longestDailyStreak, lastPlayedDate
        case playHistory
    }

    init() {}

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalSessions = try container.decode(Int.self, forKey: .totalSessions)
        totalPlayTime = try container.decode(TimeInterval.self, forKey: .totalPlayTime)
        longestSession = try container.decode(TimeInterval.self, forKey: .longestSession)
        totalBlocksPlaced = try container.decode(Int.self, forKey: .totalBlocksPlaced)
        totalLinesCleared = try container.decode(Int.self, forKey: .totalLinesCleared)
        totalPerfectClears = try container.decode(Int.self, forKey: .totalPerfectClears)
        currentDailyStreak = try container.decode(Int.self, forKey: .currentDailyStreak)
        longestDailyStreak = try container.decode(Int.self, forKey: .longestDailyStreak)
        lastPlayedDate = try container.decodeIfPresent(Date.self, forKey: .lastPlayedDate)
        playHistory = try container.decode([Date: ZenSessionSummary].self, forKey: .playHistory)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalSessions, forKey: .totalSessions)
        try container.encode(totalPlayTime, forKey: .totalPlayTime)
        try container.encode(longestSession, forKey: .longestSession)
        try container.encode(totalBlocksPlaced, forKey: .totalBlocksPlaced)
        try container.encode(totalLinesCleared, forKey: .totalLinesCleared)
        try container.encode(totalPerfectClears, forKey: .totalPerfectClears)
        try container.encode(currentDailyStreak, forKey: .currentDailyStreak)
        try container.encode(longestDailyStreak, forKey: .longestDailyStreak)
        try container.encode(lastPlayedDate, forKey: .lastPlayedDate)
        try container.encode(playHistory, forKey: .playHistory)
    }

    // MARK: - Session Management

    /// Record a completed session
    func recordSession(
        duration: TimeInterval,
        blocksPlaced: Int,
        linesCleared: Int,
        perfectClears: Int,
        mood: ZenMood? = nil
    ) {
        let summary = ZenSessionSummary(
            date: Date(),
            duration: duration,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            perfectClears: perfectClears,
            mood: mood
        )

        // Update totals
        totalSessions += 1
        totalPlayTime += duration
        totalBlocksPlaced += blocksPlaced
        totalLinesCleared += linesCleared
        totalPerfectClears += perfectClears

        if duration > longestSession {
            longestSession = duration
        }

        // Update streak
        updateStreak()

        // Save to history
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: Date())
        playHistory[dateKey] = summary

        // Save to UserDefaults
        save()
    }

    // MARK: - Streak Management

    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastPlayed = lastPlayedDate {
            let lastPlayedDay = calendar.startOfDay(for: lastPlayed)
            let daysBetween = calendar.dateComponents([.day], from: lastPlayedDay, to: today).day ?? 0

            if daysBetween == 1 {
                // Consecutive day - increment streak
                currentDailyStreak += 1
                if currentDailyStreak > longestDailyStreak {
                    longestDailyStreak = currentDailyStreak
                }
            } else if daysBetween > 1 {
                // Streak broken - reset
                currentDailyStreak = 1
            }
            // If daysBetween == 0, same day - don't change streak
        } else {
            // First time playing
            currentDailyStreak = 1
            longestDailyStreak = 1
        }

        lastPlayedDate = Date()
    }

    // MARK: - Computed Properties

    var averageSessionLength: TimeInterval {
        guard totalSessions > 0 else { return 0 }
        return totalPlayTime / TimeInterval(totalSessions)
    }

    var averageBlocksPerSession: Int {
        guard totalSessions > 0 else { return 0 }
        return totalBlocksPlaced / totalSessions
    }

    var displayTotalPlayTime: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    var displayAverageSessionLength: String {
        let minutes = Int(averageSessionLength) / 60
        let seconds = Int(averageSessionLength) % 60
        return "\(minutes)m \(seconds)s"
    }

    var displayLongestSession: String {
        let hours = Int(longestSession) / 3600
        let minutes = (Int(longestSession) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Persistence

    private static let storageKey = "zenStatistics"

    func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: ZenStatistics.storageKey)
        }
    }

    static func load() -> ZenStatistics {
        if let data = UserDefaults.standard.data(forKey: ZenStatistics.storageKey),
           let decoded = try? JSONDecoder().decode(ZenStatistics.self, from: data) {
            return decoded
        }
        return ZenStatistics()
    }
}
