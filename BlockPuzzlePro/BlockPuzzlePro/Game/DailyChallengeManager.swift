import Foundation
import SwiftUI
import Combine

// MARK: - Challenge Types

enum ChallengeType: String, Codable, CaseIterable {
    case scoreTarget = "score_target"
    case lineClearCount = "line_clear_count"
    case perfectPlacements = "perfect_placements"
    case comboChain = "combo_chain"
    case survivalTime = "survival_time"

    var displayName: String {
        switch self {
        case .scoreTarget: return "Score Master"
        case .lineClearCount: return "Line Breaker"
        case .perfectPlacements: return "Precision Pro"
        case .comboChain: return "Combo King"
        case .survivalTime: return "Survivor"
        }
    }

    var iconName: String {
        switch self {
        case .scoreTarget: return "star.fill"
        case .lineClearCount: return "line.3.horizontal"
        case .perfectPlacements: return "checkmark.circle.fill"
        case .comboChain: return "flame.fill"
        case .survivalTime: return "clock.fill"
        }
    }
}

// MARK: - Challenge Difficulty

enum ChallengeDifficulty: String, Codable {
    case easy
    case medium
    case hard

    var rewardMultiplier: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

// MARK: - Challenge Model

struct DailyChallenge: Identifiable, Codable {
    let id: UUID
    let type: ChallengeType
    let difficulty: ChallengeDifficulty
    let targetValue: Int
    var currentProgress: Int
    let reward: ChallengeReward
    let expirationDate: Date
    var isCompleted: Bool

    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentProgress) / Double(targetValue), 1.0)
    }

    var description: String {
        switch type {
        case .scoreTarget:
            return "Reach \(targetValue) points"
        case .lineClearCount:
            return "Clear \(targetValue) lines"
        case .perfectPlacements:
            return "Make \(targetValue) perfect placements"
        case .comboChain:
            return "Achieve a \(targetValue)x combo"
        case .survivalTime:
            return "Survive for \(targetValue) seconds"
        }
    }

    init(
        type: ChallengeType,
        difficulty: ChallengeDifficulty,
        targetValue: Int,
        reward: ChallengeReward,
        expirationDate: Date
    ) {
        self.id = UUID()
        self.type = type
        self.difficulty = difficulty
        self.targetValue = targetValue
        self.currentProgress = 0
        self.reward = reward
        self.expirationDate = expirationDate
        self.isCompleted = false
    }
}

// MARK: - Challenge Reward

struct ChallengeReward: Codable {
    let powerUps: [PowerUpType: Int]
    let points: Int

    init(powerUps: [PowerUpType: Int] = [:], points: Int = 0) {
        self.powerUps = powerUps
        self.points = points
    }
}

// MARK: - Daily Challenge Manager

@MainActor
final class DailyChallengeManager: ObservableObject {

    // MARK: - Published Properties

    @Published var dailyChallenges: [DailyChallenge] = []
    @Published var completedChallenges: Set<UUID> = []

    // MARK: - Private Properties

    private let userDefaultsKey = "daily_challenges"
    private let completedKey = "completed_challenges"
    private let lastRefreshKey = "last_challenge_refresh"

    // MARK: - Initialization

    init() {
        loadChallenges()
        refreshChallengesIfNeeded()
    }

    // MARK: - Challenge Generation

    func refreshChallengesIfNeeded() {
        let lastRefresh = UserDefaults.standard.object(forKey: lastRefreshKey) as? Date ?? .distantPast
        let calendar = Calendar.current

        // Check if we need to generate new challenges (daily refresh)
        if !calendar.isDateInToday(lastRefresh) {
            generateDailyChallenges()
            UserDefaults.standard.set(Date(), forKey: lastRefreshKey)
        }
    }

    private func generateDailyChallenges() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

        var newChallenges: [DailyChallenge] = []

        // Generate 3 daily challenges of varying difficulty
        newChallenges.append(generateChallenge(difficulty: .easy, expiresAt: tomorrow))
        newChallenges.append(generateChallenge(difficulty: .medium, expiresAt: tomorrow))
        newChallenges.append(generateChallenge(difficulty: .hard, expiresAt: tomorrow))

        dailyChallenges = newChallenges
        completedChallenges.removeAll()
        saveChallenges()
    }

    private func generateChallenge(difficulty: ChallengeDifficulty, expiresAt: Date) -> DailyChallenge {
        let type = ChallengeType.allCases.randomElement() ?? .scoreTarget

        let targetValue: Int
        let rewardPoints: Int

        switch (type, difficulty) {
        case (.scoreTarget, .easy):
            targetValue = 1000
            rewardPoints = 100
        case (.scoreTarget, .medium):
            targetValue = 2500
            rewardPoints = 250
        case (.scoreTarget, .hard):
            targetValue = 5000
            rewardPoints = 500

        case (.lineClearCount, .easy):
            targetValue = 10
            rewardPoints = 100
        case (.lineClearCount, .medium):
            targetValue = 25
            rewardPoints = 250
        case (.lineClearCount, .hard):
            targetValue = 50
            rewardPoints = 500

        case (.perfectPlacements, .easy):
            targetValue = 5
            rewardPoints = 100
        case (.perfectPlacements, .medium):
            targetValue = 15
            rewardPoints = 250
        case (.perfectPlacements, .hard):
            targetValue = 30
            rewardPoints = 500

        case (.comboChain, .easy):
            targetValue = 3
            rewardPoints = 100
        case (.comboChain, .medium):
            targetValue = 5
            rewardPoints = 250
        case (.comboChain, .hard):
            targetValue = 8
            rewardPoints = 500

        case (.survivalTime, .easy):
            targetValue = 60 // 1 minute
            rewardPoints = 100
        case (.survivalTime, .medium):
            targetValue = 180 // 3 minutes
            rewardPoints = 250
        case (.survivalTime, .hard):
            targetValue = 300 // 5 minutes
            rewardPoints = 500
        }

        // Random power-up reward
        let randomPowerUp = PowerUpType.allCases.randomElement() ?? .rotateToken
        let powerUpReward: [PowerUpType: Int] = [randomPowerUp: difficulty.rewardMultiplier]

        let reward = ChallengeReward(powerUps: powerUpReward, points: rewardPoints)

        return DailyChallenge(
            type: type,
            difficulty: difficulty,
            targetValue: targetValue,
            reward: reward,
            expirationDate: expiresAt
        )
    }

    // MARK: - Progress Tracking

    func updateProgress(for challengeType: ChallengeType, value: Int) {
        for index in dailyChallenges.indices {
            if dailyChallenges[index].type == challengeType && !dailyChallenges[index].isCompleted {
                dailyChallenges[index].currentProgress += value

                // Check if challenge is completed
                if dailyChallenges[index].currentProgress >= dailyChallenges[index].targetValue {
                    completeChallenge(at: index)
                }
            }
        }
        saveChallenges()
    }

    private func completeChallenge(at index: Int) {
        guard index < dailyChallenges.count else { return }

        dailyChallenges[index].isCompleted = true
        dailyChallenges[index].currentProgress = dailyChallenges[index].targetValue

        let challengeID = dailyChallenges[index].id
        completedChallenges.insert(challengeID)

        saveChallenges()
    }

    func claimReward(for challengeID: UUID, powerUpManager: PowerUpManager, scoreTracker: inout Int) -> ChallengeReward? {
        guard let challenge = dailyChallenges.first(where: { $0.id == challengeID }),
              challenge.isCompleted,
              !completedChallenges.contains(challengeID) else {
            return nil
        }

        // Grant rewards
        for (powerUp, count) in challenge.reward.powerUps {
            powerUpManager.addPowerUp(powerUp, count: count)
        }

        scoreTracker += challenge.reward.points

        completedChallenges.insert(challengeID)
        saveChallenges()

        return challenge.reward
    }

    // MARK: - Persistence

    private func saveChallenges() {
        do {
            let challengesData = try JSONEncoder().encode(dailyChallenges)
            let completedData = try JSONEncoder().encode(completedChallenges)

            UserDefaults.standard.set(challengesData, forKey: userDefaultsKey)
            UserDefaults.standard.set(completedData, forKey: completedKey)
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

        if let data = UserDefaults.standard.data(forKey: completedKey) {
            do {
                completedChallenges = try JSONDecoder().decode(Set<UUID>.self, from: data)
            } catch {
                print("Failed to load completed challenges: \(error)")
            }
        }
    }

    // MARK: - Reset

    func reset() {
        dailyChallenges.removeAll()
        completedChallenges.removeAll()
        saveChallenges()
        UserDefaults.standard.removeObject(forKey: lastRefreshKey)
    }
}
