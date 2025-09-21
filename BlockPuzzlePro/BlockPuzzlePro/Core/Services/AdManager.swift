import Foundation
import UIKit
import os.log
// import GoogleMobileAds // Will be available once SDK is added via SPM

// MARK: - Ad Loading States

enum AdLoadingState: Equatable {
    case notLoaded
    case loading
    case loaded
    case failed(Error)
    case displaying
    
    static func == (lhs: AdLoadingState, rhs: AdLoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.notLoaded, .notLoaded), (.loading, .loading), (.loaded, .loaded), (.displaying, .displaying):
            return true
        case (.failed, .failed):
            return true // For simplicity, consider all failed states equal
        default:
            return false
        }
    }
}

// MARK: - Ad Errors

enum AdError: Error, LocalizedError {
    case networkUnavailable
    case adUnavailable
    case loadTimeout
    case alreadyLoading
    case noAdsLoaded
    case userDismissed
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable for ad loading"
        case .adUnavailable:
            return "No ads available at this time"
        case .loadTimeout:
            return "Ad loading timed out"
        case .alreadyLoading:
            return "Ad is already being loaded"
        case .noAdsLoaded:
            return "No ads loaded and ready to display"
        case .userDismissed:
            return "User dismissed the ad"
        }
    }
}

// MARK: - Ad Reward Protocol

protocol AdRewardDelegate: AnyObject {
    nonisolated func adManager(_ manager: AdManager, didEarnReward amount: Int, type: String)
    nonisolated func adManager(_ manager: AdManager, didFailToShowAd error: AdError)
    nonisolated func adManager(_ manager: AdManager, didDismissAd wasCompleted: Bool)
}

// MARK: - AdManager MainActor Class

@MainActor
class AdManager: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "AdManager")
    
    @Published private(set) var rewardedAdState: AdLoadingState = .notLoaded
    @Published private(set) var isInitialized = false
    
    /// Get initialization status (exposed for external access)
    var isAdManagerInitialized: Bool {
        return isInitialized
    }
    
    private var rewardedAd: Any? // GADRewardedAd? - will be typed once SDK is available
    private var retryAttempts = 0
    private var loadingTask: Task<Void, Never>?
    
    weak var rewardDelegate: AdRewardDelegate?
    
    // MARK: - Delegate Management
    
    /// Set the reward delegate
    func setRewardDelegate(_ delegate: AdRewardDelegate?) {
        self.rewardDelegate = delegate
    }
    
    // MARK: - Singleton
    
    static let shared = AdManager()
    
    private init() {
        logger.info("AdManager initialized")
    }
    
    // MARK: - SDK Initialization
    
    func initializeAdMob() async {
        guard !isInitialized else {
            logger.info("AdMob already initialized")
            return
        }
        
        logger.info("Initializing AdMob SDK...")
        AdMobConfig.logCurrentConfiguration()
        
        // In real implementation:
        // GADMobileAds.sharedInstance().start { [weak self] status in
        //     Task { @MainActor in
        //         self?.isInitialized = true
        //         self?.logger.info("AdMob SDK initialized successfully")
        //         if AdMobConfig.shouldPreloadAds {
        //             await self?.preloadRewardedAd()
        //         }
        //     }
        // }
        
        // Simulated initialization for development
        try? await Task.sleep(for: .seconds(1))
        isInitialized = true
        logger.info("AdMob SDK initialized successfully (simulated)")
        
        if AdMobConfig.shouldPreloadAds {
            await preloadRewardedAd()
        }
    }
    
    // MARK: - Rewarded Ad Loading
    
    func preloadRewardedAd() async {
        guard isInitialized else {
            logger.error("Cannot preload ads - AdMob not initialized")
            return
        }
        
        guard rewardedAdState != .loading else {
            logger.warning("Rewarded ad already loading")
            return
        }
        
        updateAdState(.loading)
        logger.info("Starting to preload rewarded ad...")
        
        loadingTask = Task { [weak self] in
            await self?.loadRewardedAdInternal()
        }
    }
    
    private func loadRewardedAdInternal() async {
        let adUnitID = AdMobConfig.rewardedAdUnitID
        logger.info("Loading rewarded ad with unit ID: \(adUnitID)")
        
        do {
            // Simulate network delay and loading
            try await Task.sleep(for: .seconds(2))
            
            // In real implementation:
            // let request = GADRequest()
            // let ad = try await GADRewardedAd.load(withAdUnitID: adUnitID, request: request)
            // self.rewardedAd = ad
            
            // Simulated success
            updateAdState(.loaded)
            retryAttempts = 0
            logger.info("Rewarded ad loaded successfully")
            
        } catch {
            logger.error("Failed to load rewarded ad: \(error.localizedDescription)")
            await handleAdLoadFailure(error)
        }
    }
    
    private func handleAdLoadFailure(_ error: Error) async {
        retryAttempts += 1
        
        if retryAttempts < AdMobConfig.maxRetryAttempts {
            logger.info("Retrying ad load (attempt \(self.retryAttempts)/\(AdMobConfig.maxRetryAttempts))")
            
            try? await Task.sleep(for: .seconds(AdMobConfig.retryDelay))
            await loadRewardedAdInternal()
        } else {
            logger.error("Max retry attempts reached for ad loading")
            let adError = mapToAdError(error)
            updateAdState(.failed(adError))
            retryAttempts = 0
        }
    }
    
    private func mapToAdError(_ error: Error) -> AdError {
        // Map various error types to our custom AdError enum
        if error.localizedDescription.contains("network") {
            return .networkUnavailable
        } else if error.localizedDescription.contains("timeout") {
            return .loadTimeout
        } else {
            return .adUnavailable
        }
    }
    
    @MainActor
    private func updateAdState(_ newState: AdLoadingState) {
        rewardedAdState = newState
    }
    
    // MARK: - Ad Display
    
    func showRewardedAd(from viewController: UIViewController) async -> Bool {
        guard case .loaded = rewardedAdState else {
            logger.error("Cannot show rewarded ad - no ad loaded")
            rewardDelegate?.adManager(self, didFailToShowAd: .noAdsLoaded)
            return false
        }
        
        updateAdState(.displaying)
        logger.info("Showing rewarded ad...")
        
        // In real implementation:
        // rewardedAd?.present(from: viewController) { [weak self] in
        //     // Handle reward
        //     self?.handleAdReward()
        // }
        
        // Simulated ad display
        try? await Task.sleep(for: .seconds(3)) // Simulate ad duration
        
        // Simulate successful completion
        await handleAdReward()
        updateAdState(.notLoaded)
        
        // Preload next ad
        if AdMobConfig.shouldPreloadAds {
            await preloadRewardedAd()
        }
        
        return true
    }
    
    private func handleAdReward() async {
        logger.info("User earned reward from ad")
        
        // Standard rewarded video completion reward
        let rewardAmount = 1
        let rewardType = "continue_game"
        
        rewardDelegate?.adManager(self, didEarnReward: rewardAmount, type: rewardType)
    }
    
    // MARK: - Ad Availability
    
    func isRewardedAdReady() async -> Bool {
        if case .loaded = rewardedAdState {
            return true
        }
        return false
    }
    
    // MARK: - Error Handling
    
    func handleNetworkError() async {
        logger.warning("Network error detected, pausing ad loading")
        updateAdState(.failed(AdError.networkUnavailable))
    }
    
    func retryFailedAds() async {
        guard case .failed(_) = rewardedAdState else { return }
        
        logger.info("Retrying failed ad loads...")
        retryAttempts = 0
        await preloadRewardedAd()
    }
}

// MARK: - AdManager Extensions

extension AdManager {
    
    // MARK: - Debug Helpers
    
    func getDebugInfo() -> String {
        let stateDescription: String
        
        switch rewardedAdState {
        case .notLoaded:
            stateDescription = "Not Loaded"
        case .loading:
            stateDescription = "Loading..."
        case .loaded:
            stateDescription = "Ready to Show"
        case .failed(let error):
            stateDescription = "Failed: \(error.localizedDescription)"
        case .displaying:
            stateDescription = "Currently Displaying"
        }
        
        return """
        AdManager Debug Info:
        - Initialized: \(isInitialized)
        - Rewarded Ad State: \(stateDescription)
        - Configuration: \(AdMobConfig.isProduction ? "Production" : "Test")
        - Retry Attempts: \(retryAttempts)/\(AdMobConfig.maxRetryAttempts)
        """
    }
}