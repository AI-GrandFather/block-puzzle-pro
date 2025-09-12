import Foundation
import UIKit
import os.log

// MARK: - Game Ad Integration

/// Handles ad integration specifically for game scenarios
class GameAdIntegration: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "GameAdIntegration")
    
    @Published var canContinueGame = false
    @Published var showATTPrompt = false
    
    private weak var gameViewController: GameViewController?
    
    // MARK: - Initialization
    
    init(gameViewController: GameViewController) {
        self.gameViewController = gameViewController
        setupAdManager()
    }
    
    // MARK: - Setup
    
    private func setupAdManager() {
        Task {
            // Set this instance as the reward delegate
            AdManager.shared.rewardDelegate = self
            
            // Request ATT permission after first game (better UX)
            await requestATTIfAppropriate()
        }
    }
    
    // MARK: - Game Over Scenario
    
    func handleGameOver() async {
        logger.info("Game over - checking continue options")
        
        // Check if rewarded ad is available for continue
        let adReady = await AdManager.shared.isRewardedAdReady()
        
        await MainActor.run {
            canContinueGame = adReady
        }
        
        if adReady {
            logger.info("Continue with ad option available")
        } else {
            logger.info("No ad available - loading one for next time")
            await AdManager.shared.preloadRewardedAd()
        }
    }
    
    func showContinueAd() async -> Bool {
        guard let viewController = gameViewController else {
            logger.error("No game view controller available")
            return false
        }
        
        logger.info("Showing continue ad...")
        return await AdManager.shared.showRewardedAd(from: viewController)
    }
    
    // MARK: - Power-Up Ads (Future Story)
    
    func showPowerUpAd() async -> Bool {
        guard let viewController = gameViewController else {
            logger.error("No game view controller available")
            return false
        }
        
        logger.info("Showing power-up ad...")
        return await AdManager.shared.showRewardedAd(from: viewController)
    }
    
    // MARK: - ATT Management
    
    private func requestATTIfAppropriate() async {
        // Request ATT after user has played at least one game
        // This provides better context than requesting immediately on app launch
        if ATTManager.shared.shouldRequestPermissionAfterGameplay() {
            await MainActor.run {
                showATTPrompt = true
            }
        }
    }
    
    func handleATTPromptResponse() async {
        await ATTManager.shared.requestTrackingPermissionIfNeeded()
        
        await MainActor.run {
            showATTPrompt = false
        }
        
        logger.info("ATT permission handled - \(ATTManager.shared.attStatus.description)")
    }
    
    // MARK: - Preloading Management
    
    func preloadAdsForGameplay() async {
        // Preload ads at appropriate times (not during active gameplay)
        logger.info("Preloading ads for upcoming gameplay")
        await AdManager.shared.preloadRewardedAd()
    }
    
    func pauseAdOperations() async {
        // Pause any non-essential ad operations during intensive gameplay
        logger.info("Pausing ad operations for intensive gameplay")
    }
    
    func resumeAdOperations() async {
        // Resume ad operations when gameplay is less intensive
        logger.info("Resuming ad operations")
        await preloadAdsForGameplay()
    }
}

// MARK: - AdRewardDelegate Implementation

extension GameAdIntegration: AdRewardDelegate {
    
    func adManager(_ manager: AdManager, didEarnReward amount: Int, type: String) {
        logger.info("Player earned reward: \(amount) \(type)")
        
        // Handle different reward types
        switch type {
        case "continue_game":
            handleContinueReward()
        case "power_up":
            handlePowerUpReward()
        default:
            logger.warning("Unknown reward type: \(type)")
        }
    }
    
    func adManager(_ manager: AdManager, didFailToShowAd error: AdError) {
        logger.error("Ad failed to show: \(error.localizedDescription)")
        
        Task { @MainActor in
            // Show user-friendly error message
            showAdErrorAlert(error)
        }
    }
    
    func adManager(_ manager: AdManager, didDismissAd wasCompleted: Bool) {
        logger.info("Ad dismissed - completed: \(wasCompleted)")
        
        if !wasCompleted {
            // User dismissed ad without completing - no reward
            Task { @MainActor in
                showAdDismissedMessage()
            }
        }
    }
    
    // MARK: - Reward Handling
    
    private func handleContinueReward() {
        Task { @MainActor in
            // Grant player continue opportunity
            // This will be implemented in game logic stories
            logger.info("Granting continue gameplay reward")
        }
    }
    
    private func handlePowerUpReward() {
        Task { @MainActor in
            // Grant power-up to player
            // This will be implemented in future power-up stories
            logger.info("Granting power-up reward")
        }
    }
    
    // MARK: - Error UI
    
    @MainActor
    private func showAdErrorAlert(_ error: AdError) {
        guard let viewController = gameViewController else { return }
        
        let alert = UIAlertController(
            title: "Ad Unavailable",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    @MainActor  
    private func showAdDismissedMessage() {
        // Could show a subtle message that reward wasn't earned
        logger.info("Ad was dismissed - no reward granted")
    }
}

// MARK: - Game Performance Monitoring

extension GameAdIntegration {
    
    /// Monitor game performance during ad operations
    func monitorGamePerformance() {
        // Ensure 60fps is maintained during ad loading
        // This would integrate with performance monitoring in future stories
        logger.info("Monitoring game performance during ad operations")
    }
    
    /// Check if ad operations are impacting gameplay
    func isAdOperationImpactingPerformance() -> Bool {
        // Would implement actual performance monitoring
        // For now, assume ad operations are optimized
        return false
    }
}