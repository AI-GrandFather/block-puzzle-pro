import Foundation

// MARK: - AdMob Configuration

struct AdMobConfig {
    
    // MARK: - Build Configuration Detection
    
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    // MARK: - AdMob App IDs
    
    static var appID: String {
        return isProduction ? productionAppID : testAppID
    }
    
    private static let testAppID = "ca-app-pub-3940256099942544~1458002511"
    private static let productionAppID = "ca-app-pub-9658051267955550~6177451298" // Production AdMob App ID
    
    // MARK: - Rewarded Ad Unit IDs
    
    static var rewardedAdUnitID: String {
        return isProduction ? productionRewardedAdUnitID : testRewardedAdUnitID
    }
    
    private static let testRewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private static let productionRewardedAdUnitID = "REPLACE_WITH_REWARDED_AD_UNIT_ID_FROM_GOOGLE_ADMOB_CONSOLE" // Set this when Apple Developer account is ready and AdMob account is created
    
    // MARK: - Configuration Info
    
    @MainActor
    static func logCurrentConfiguration() {
        let config = isProduction ? "PRODUCTION" : "TEST"
        DebugLog.trace("🎯 AdMob Configuration: \(config)")
        DebugLog.trace("📱 App ID: \(appID)")
        DebugLog.trace("🎬 Rewarded Ad Unit: \(rewardedAdUnitID)")
    }
}

// MARK: - Ad Configuration Extensions

extension AdMobConfig {
    
    /// Ad loading timeout in seconds
    static let adLoadTimeout: TimeInterval = 10.0
    
    /// Maximum number of retry attempts for failed ad loads
    static let maxRetryAttempts = 3
    
    /// Delay between retry attempts in seconds
    static let retryDelay: TimeInterval = 2.0
    
    /// Whether to preload ads in background
    static let shouldPreloadAds = true
}
