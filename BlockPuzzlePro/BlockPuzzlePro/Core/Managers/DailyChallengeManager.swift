// DailyChallengeManager.swift
// Manages daily challenges, tracking progress and rewards
// Generates new challenges daily and persists progress

import Foundation
import Combine

// MARK: - Challenge Type

enum ChallengeType: String, Codable, CaseIterable {
    case clearLines = "clear_lines"
    case scorePoints = "score_points"
    case perfectClears = "perfect_clears"
    case combos = "combos"
    case playGames = "play_games"

    var displayName: String {
        switch self {
        case .clearLines: return "Line Clearer"
        case .scorePoints: return "Score Master"
        case .perfectClears: return "Perfectionist"
        case .combos: return "Combo King"
        case .playGames: return "Dedicated Player"
        }
    }

    var iconName: String {
        switch self {
        case .clearLines: return "rectangle.stack.fill"
        case .scorePoints: return "star.fill"
        case .perfectClears: return "checkmark.seal.fill"
        case .combos: return "flame.fill"
        case .playGames: return "gamecontroller.fill"
        }
    }
}

// MARK: - Difficulty

enum ChallengeDifficulty: String, Codable {
    case easy, medium, hard

    var multiplier: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

// MARK: - Daily Challenge

struct DailyChallenge: Identifiable, Codable {
    let id: String
    let type: ChallengeType
    let difficulty: ChallengeDifficulty
    let targetValue: Int
    var currentProgress: Int
    let expiryDate: Date
    var isCompleted: Bool
    var isClaimed: Bool

    var description: String {
        switch type {
        case .clearLines:
            return "Clear \(targetValue) lines"
        case .scorePoints:
            return "Score \(targetValue) points"
        case .perfectClears:
            return "Achieve \(targetValue) perfect clears"
        case .combos:
            return "Get \(targetValue) combo clears"
        case .playGames:
            return "Play \(targetValue) games"
        }
    }

    var progressPercentage: Double {
        min(Double(currentProgress) / Double(targetValue), 1.0)
    }

    var reward: ChallengeReward {
        let basePoints = targetValue * 10
        let bonusPoints = basePoints * difficulty.multiplier

        return ChallengeReward(
            points: bonusPoints,
            powerUps: [(PowerUpType.rotateToken, difficulty.multiplier)]
        )
    }
}

// MARK: - Challenge Reward

struct ChallengeReward {
    let points: Int
    let powerUps: [(PowerUpType, Int)]
}

// MARK: - Daily Challenge Manager

@MainActor
final class DailyChallengeManager: ObservableObject {

    // MARK: - Published Properties

    @Published var dailyChallenges: [DailyChallenge] = []
    @Published var lastRefreshDate: Date?

    // MARK: - Private Properties

    private let userDefaultsKey = "daily_challenges"
    private let lastRefreshKey = "daily_challenges_last_refresh"

    // MARK: - Initialization

    init() {
        loadChallenges()
        checkAndRefreshChallenges()
    }

    // MARK: - Challenge Generation

    func generateDailyChallenges() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let expiryDate = calendar.startOfDay(for: tomorrow)

        // Generate 3 challenges of varying difficulty
        dailyChallenges = [
            generateChallenge(difficulty: .easy, expiryDate: expiryDate),
            generateChallenge(difficulty: .medium, expiryDate: expiryDate),
            generateChallenge(difficulty: .hard, expiryDate: expiryDate)
        ]

        lastRefreshDate = Date()
        saveChallenges()
    }

    private func generateChallenge(difficulty: ChallengeDifficulty, expiryDate: Date) -> DailyChallenge {
        let type = ChallengeType.allCases.randomElement()!
        let baseTarget: Int

        switch type {
        case .clearLines:
            baseTarget = difficulty == .easy ? 10 : difficulty == .medium ? 25 : 50
        case .scorePoints:
            baseTarget = difficulty == .easy ? 1000 : difficulty == .medium ? 5000 : 10000
        case .perfectClears:
            baseTarget = difficulty == .easy ? 2 : difficulty == .medium ? 5 : 10
        case .combos:
            baseTarget = difficulty == .easy ? 3 : difficulty == .medium ? 10 : 20
        case .playGames:
            baseTarget = difficulty == .easy ? 3 : difficulty == .medium ? 5 : 10
        }

        return DailyChallenge(
            id: UUID().uuidString,
            type: type,
            difficulty: difficulty,
            targetValue: baseTarget,
            currentProgress: 0,
            expiryDate: expiryDate,
            isCompleted: false,
            isClaimed: false
        )
    }

    // MARK: - Progress Tracking

    func updateProgress(for type: ChallengeType, amount: Int = 1) {
        for index in dailyChallenges.indices {
            if dailyChallenges[index].type == type && !dailyChallenges[index].isCompleted {
                dailyChallenges[index].currentProgress += amount

                if dailyChallenges[index].currentProgress >= dailyChallenges[index].targetValue {
                    dailyChallenges[index].isCompleted = true
                }
            }
        }
        saveChallenges()
    }

    // MARK: - Reward Claiming

    func claimReward(for challengeID: String, powerUpManager: PowerUpManager, scoreTracker: inout Int) -> ChallengeReward? {
        guard let index = dailyChallenges.firstIndex(where: { $0.id == challengeID }),
              dailyChallenges[index].isCompleted,
              !dailyChallenges[index].isClaimed else {
            return nil
        }

        let reward = dailyChallenges[index].reward

        // Award power-ups
        for (powerUpType, count) in reward.powerUps {
            powerUpManager.addPowerUp(powerUpType, count: count)
        }

        // Award points
        scoreTracker += reward.points

        // Mark as claimed
        dailyChallenges[index].isClaimed = true
        saveChallenges()

        return reward
    }

    // MARK: - Refresh Logic

    func checkAndRefreshChallenges() {
        let calendar = Calendar.current
        let now = Date()

        // Check if we need to refresh (either never refreshed or it's a new day)
        let shouldRefresh: Bool
        if let lastRefresh = lastRefreshDate {
            shouldRefresh = !calendar.isDate(lastRefresh, inSameDayAs: now)
        } else {
            shouldRefresh = true
        }

        if shouldRefresh || dailyChallenges.isEmpty {
            generateDailyChallenges()
        }
    }

    // MARK: - Persistence

    private func saveChallenges() {
        do {
            let data = try JSONEncoder().encode(dailyChallenges)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)

            if let lastRefresh = lastRefreshDate {
                UserDefaults.standard.set(lastRefresh, forKey: lastRefreshKey)
            }
        } catch {
            print("Failed to save daily challenges: \(error)")
        }
    }

    private func loadChallenges() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                dailyChallenges = try JSONDecoder().decode([DailyChallenge].self, from: data)
            } catch {
                print("Failed to load daily challenges: \(error)")
            }
        }

        lastRefreshDate = UserDefaults.standard.object(forKey: lastRefreshKey) as? Date
    }

    // MARK: - Reset

    func reset() {
        dailyChallenges.removeAll()
        lastRefreshDate = nil
        saveChallenges()
    }
}
