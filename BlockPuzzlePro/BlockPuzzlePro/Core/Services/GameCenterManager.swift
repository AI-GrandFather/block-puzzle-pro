import Foundation
import GameKit
import SwiftUI
import os.log

/// Manages Game Center integration for leaderboards and achievements
@MainActor
final class GameCenterManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isAuthenticated: Bool = false
    @Published var localPlayer: GKLocalPlayer?
    @Published var authenticationError: Error?

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "GameCenter")

    // Leaderboard IDs (these need to be configured in App Store Connect)
    private let leaderboardIDs = [
        "high_score_classic": "com.blockpuzzlepro.leaderboard.highscore",
        "high_score_daily": "com.blockpuzzlepro.leaderboard.daily",
        "high_score_weekly": "com.blockpuzzlepro.leaderboard.weekly"
    ]

    // Achievement IDs
    private let achievementIDs = [
        "first_win": "com.blockpuzzlepro.achievement.firstwin",
        "score_1000": "com.blockpuzzlepro.achievement.score1000",
        "score_5000": "com.blockpuzzlepro.achievement.score5000",
        "score_10000": "com.blockpuzzlepro.achievement.score10000",
        "clear_100_lines": "com.blockpuzzlepro.achievement.lines100",
        "perfect_board": "com.blockpuzzlepro.achievement.perfectboard"
    ]

    // MARK: - Singleton

    static let shared = GameCenterManager()

    // MARK: - Initialization

    private override init() {
        super.init()
    }

    // MARK: - Authentication

    func authenticatePlayer() {
        let localPlayer = GKLocalPlayer.local

        localPlayer.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let viewController = viewController {
                    // Present the Game Center login view controller
                    self?.presentAuthenticationViewController(viewController)
                } else if localPlayer.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.localPlayer = localPlayer
                    self?.logger.info("Game Center authenticated: \(localPlayer.displayName)")
                } else {
                    self?.isAuthenticated = false
                    self?.authenticationError = error
                    if let error = error {
                        self?.logger.error("Game Center authentication failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func presentAuthenticationViewController(_ viewController: UIViewController) {
        // Find the root view controller to present Game Center login
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            logger.warning("Could not find root view controller to present Game Center login")
            return
        }

        rootViewController.present(viewController, animated: true)
    }

    // MARK: - Leaderboards

    func submitScore(_ score: Int, to leaderboardID: String = "high_score_classic") {
        guard isAuthenticated else {
            logger.warning("Cannot submit score: not authenticated")
            return
        }

        guard let actualID = leaderboardIDs[leaderboardID] else {
            logger.error("Unknown leaderboard ID: \(leaderboardID)")
            return
        }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [actualID]
                )
                logger.info("Successfully submitted score \(score) to leaderboard \(actualID)")
            } catch {
                logger.error("Failed to submit score: \(error.localizedDescription)")
            }
        }
    }

    func showLeaderboard(leaderboardID: String = "high_score_classic") {
        guard isAuthenticated else {
            logger.warning("Cannot show leaderboard: not authenticated")
            return
        }

        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self

        presentGameCenterViewController(viewController)
    }

    func showAllLeaderboards() {
        guard isAuthenticated else {
            logger.warning("Cannot show leaderboards: not authenticated")
            return
        }

        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self

        presentGameCenterViewController(viewController)
    }

    // MARK: - Achievements

    func reportAchievement(_ achievementID: String, percentComplete: Double = 100.0) {
        guard isAuthenticated else {
            logger.warning("Cannot report achievement: not authenticated")
            return
        }

        guard let actualID = achievementIDs[achievementID] else {
            logger.error("Unknown achievement ID: \(achievementID)")
            return
        }

        let achievement = GKAchievement(identifier: actualID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true

        Task {
            do {
                try await GKAchievement.report([achievement])
                logger.info("Successfully reported achievement \(actualID) at \(percentComplete)%")
            } catch {
                logger.error("Failed to report achievement: \(error.localizedDescription)")
            }
        }
    }

    func showAchievements() {
        guard isAuthenticated else {
            logger.warning("Cannot show achievements: not authenticated")
            return
        }

        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = self

        presentGameCenterViewController(viewController)
    }

    // MARK: - Helper Methods

    private func presentGameCenterViewController(_ viewController: GKGameCenterViewController) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            logger.warning("Could not find root view controller to present Game Center")
            return
        }

        rootViewController.present(viewController, animated: true)
    }

    // MARK: - Score Tracking Convenience Methods

    func checkAndReportAchievements(score: Int, linesCleared: Int, boardCleared: Bool) {
        // Score milestones
        if score >= 1000 {
            reportAchievement("score_1000")
        }
        if score >= 5000 {
            reportAchievement("score_5000")
        }
        if score >= 10000 {
            reportAchievement("score_10000")
        }

        // Line clearing milestones
        if linesCleared >= 100 {
            reportAchievement("clear_100_lines")
        }

        // Perfect board
        if boardCleared {
            reportAchievement("perfect_board")
        }
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    nonisolated func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
