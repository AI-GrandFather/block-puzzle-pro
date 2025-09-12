import XCTest
import UIKit
@testable import BlockPuzzlePro

// MARK: - Ad Integration Tests

final class AdIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var adManager: AdManager!
    private var attManager: ATTManager!
    private var gameAdIntegration: GameAdIntegration!
    private var mockGameViewController: MockGameViewController!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        // Initialize components
        adManager = AdManager.shared
        attManager = ATTManager.shared
        mockGameViewController = MockGameViewController()
        gameAdIntegration = GameAdIntegration(gameViewController: mockGameViewController)
        
        // Reset state for clean testing
        Task {
            await adManager.reset()
        }
        attManager.resetForTesting()
    }
    
    override func tearDown() {
        adManager = nil
        attManager = nil
        gameAdIntegration = nil
        mockGameViewController = nil
        super.tearDown()
    }
    
    // MARK: - Complete App Launch to Ad Display Workflow
    
    func testCompleteAdWorkflow_AppLaunchToAdDisplay_Success() async {
        // Given - Fresh app state
        let initialAdState = await adManager.isInitialized
        XCTAssertFalse(initialAdState, "AdManager should not be initialized initially")
        
        // PHASE 1: App Launch - Initialize AdMob
        await adManager.initializeAdMob()
        
        let isInitialized = await adManager.isInitialized
        XCTAssertTrue(isInitialized, "AdManager should be initialized after app launch")
        
        // PHASE 2: Background Preloading
        await adManager.preloadRewardedAd()
        
        let isAdReady = await adManager.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ad should be ready after preloading")
        
        // PHASE 3: Game Over Scenario
        await gameAdIntegration.handleGameOver()
        
        await MainActor.run {
            XCTAssertTrue(gameAdIntegration.canContinueGame, "Should offer continue option when ad is ready")
        }
        
        // PHASE 4: User Chooses to Continue - Show Ad
        let adShowSuccess = await gameAdIntegration.showContinueAd()
        XCTAssertTrue(adShowSuccess, "Ad should show successfully")
        
        // PHASE 5: Verify Ad Consumption
        let isAdReadyAfterShow = await adManager.isRewardedAdReady()
        XCTAssertFalse(isAdReadyAfterShow, "Ad should not be ready after being consumed")
        
        // PHASE 6: Next Game Over Should Trigger Preload
        await gameAdIntegration.handleGameOver()
        
        await MainActor.run {
            XCTAssertFalse(gameAdIntegration.canContinueGame, "Should not offer continue when no ad is ready")
        }
    }
    
    // MARK: - ATT Integration Workflow
    
    func testATTIntegrationWorkflow_FirstGameplayToPermissionRequest() async {
        // Given - Fresh ATT state
        XCTAssertEqual(attManager.attStatus, .notDetermined)
        XCTAssertFalse(attManager.hasRequestedPermission)
        
        // PHASE 1: First Gameplay - Should Trigger ATT Check
        let shouldRequestAfterGameplay = attManager.shouldRequestPermissionAfterGameplay()
        XCTAssertTrue(shouldRequestAfterGameplay, "Should want to request ATT after first gameplay")
        
        // PHASE 2: Request ATT Permission
        await attManager.requestTrackingPermissionIfNeeded()
        
        XCTAssertEqual(attManager.attStatus, .authorized, "ATT should be authorized after request")
        XCTAssertTrue(attManager.hasRequestedPermission, "Should have requested permission")
        
        // PHASE 3: Verify Personalized Ads Capability
        let canShowPersonalized = attManager.canShowPersonalizedAds()
        XCTAssertTrue(canShowPersonalized, "Should allow personalized ads after authorization")
        
        let adPersonalizationStatus = attManager.getAdPersonalizationStatus()
        XCTAssertEqual(adPersonalizationStatus, "Personalized ads enabled")
        
        // PHASE 4: Subsequent Gameplay - Should Not Request Again
        let shouldRequestAgain = attManager.shouldRequestPermissionAfterGameplay()
        XCTAssertFalse(shouldRequestAgain, "Should not request ATT again after already requested")
    }
    
    // MARK: - Error Recovery Workflow
    
    func testErrorRecoveryWorkflow_NetworkFailureToSuccessfulRecovery() async {
        // Given - Initialized AdManager
        await adManager.initializeAdMob()
        
        // PHASE 1: Simulate Network Error
        await adManager.handleNetworkError()
        
        let errorState = await adManager.rewardedAdState
        if case .failed(let error) = errorState {
            XCTAssertEqual(error.localizedDescription, AdError.networkUnavailable.localizedDescription)
        } else {
            XCTFail("Should be in failed state after network error")
        }
        
        // PHASE 2: Game Over with Failed Ad State
        await gameAdIntegration.handleGameOver()
        
        await MainActor.run {
            XCTAssertFalse(gameAdIntegration.canContinueGame, "Should not offer continue when ad failed")
        }
        
        // PHASE 3: Network Recovery - Retry Failed Ads
        await adManager.retryFailedAds()
        
        // PHASE 4: Verify Recovery Success
        let isAdReadyAfterRetry = await adManager.isRewardedAdReady()
        XCTAssertTrue(isAdReadyAfterRetry, "Ad should be ready after successful retry")
        
        // PHASE 5: Verify Game Over Now Offers Continue
        await gameAdIntegration.handleGameOver()
        
        await MainActor.run {
            XCTAssertTrue(gameAdIntegration.canContinueGame, "Should offer continue after recovery")
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceIntegration_AdOperationsDuringGameplay() async {
        // Given - Game in active state with performance monitoring
        await adManager.initializeAdMob()
        
        // PHASE 1: Intensive Gameplay - Pause Ad Operations
        await gameAdIntegration.pauseAdOperations()
        
        let isImpactingPerformance = gameAdIntegration.isAdOperationImpactingPerformance()
        XCTAssertFalse(isImpactingPerformance, "Ad operations should not impact performance")
        
        // PHASE 2: Performance Monitoring During Operations
        gameAdIntegration.monitorGamePerformance()
        
        // PHASE 3: Resume Ad Operations When Safe
        await gameAdIntegration.resumeAdOperations()
        
        // PHASE 4: Verify Ads Can Still Load After Performance Management
        await gameAdIntegration.preloadAdsForGameplay()
        
        // Give time for preloading
        try? await Task.sleep(for: .seconds(3))
        
        let isAdReady = await adManager.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ads should still load after performance management")
    }
    
    // MARK: - Multi-Ad Type Integration
    
    func testMultiAdTypeIntegration_ContinueAndPowerUpAds() async {
        // Given - Initialized system with loaded ads
        await adManager.initializeAdMob()
        await adManager.preloadRewardedAd()
        
        // PHASE 1: Show Continue Ad
        let continueSuccess = await gameAdIntegration.showContinueAd()
        XCTAssertTrue(continueSuccess, "Continue ad should show successfully")
        
        // PHASE 2: Verify Ad Consumed
        let isAdReadyAfterContinue = await adManager.isRewardedAdReady()
        XCTAssertFalse(isAdReadyAfterContinue, "Ad should be consumed after continue")
        
        // PHASE 3: Preload New Ad for Power-Up
        await adManager.preloadRewardedAd()
        
        let isAdReadyForPowerUp = await adManager.isRewardedAdReady()
        XCTAssertTrue(isAdReadyForPowerUp, "New ad should be ready for power-up")
        
        // PHASE 4: Show Power-Up Ad
        let powerUpSuccess = await gameAdIntegration.showPowerUpAd()
        XCTAssertTrue(powerUpSuccess, "Power-up ad should show successfully")
        
        // PHASE 5: Verify Second Ad Consumed
        let isAdReadyAfterPowerUp = await adManager.isRewardedAdReady()
        XCTAssertFalse(isAdReadyAfterPowerUp, "Ad should be consumed after power-up")
    }
    
    // MARK: - Configuration Integration Tests
    
    func testConfigurationIntegration_DevVsProductionSettings() async {
        // Given - AdMob configuration system
        
        // PHASE 1: Verify Development Configuration
        let isProduction = AdMobConfig.isProduction
        XCTAssertFalse(isProduction, "Should be in development mode during testing")
        
        let devAppID = AdMobConfig.appID
        let devAdUnitID = AdMobConfig.rewardedAdUnitID
        
        XCTAssertEqual(devAppID, "ca-app-pub-3940256099942544~1458002511", "Should use test app ID")
        XCTAssertEqual(devAdUnitID, "ca-app-pub-3940256099942544/1712485313", "Should use test ad unit ID")
        
        // PHASE 2: Verify Configuration Settings
        XCTAssertEqual(AdMobConfig.adLoadTimeout, 10.0, "Ad load timeout should be 10 seconds")
        XCTAssertEqual(AdMobConfig.maxRetryAttempts, 3, "Max retry attempts should be 3")
        XCTAssertEqual(AdMobConfig.retryDelay, 2.0, "Retry delay should be 2 seconds")
        XCTAssertTrue(AdMobConfig.shouldPreloadAds, "Should preload ads by default")
        
        // PHASE 3: Initialize with Configuration
        await adManager.initializeAdMob()
        
        let debugInfo = await adManager.getDebugInfo()
        XCTAssertTrue(debugInfo.contains("Test"), "Debug info should indicate test configuration")
    }
    
    // MARK: - Reward Delegate Integration Tests
    
    func testRewardDelegateIntegration_CompleteRewardFlow() async {
        // Given - Game integration set as reward delegate
        await adManager.initializeAdMob()
        await adManager.preloadRewardedAd()
        
        // Set up delegate monitoring
        let mockDelegate = MockAdRewardDelegate()
        adManager.rewardDelegate = mockDelegate
        
        // PHASE 1: Show Ad and Complete
        let showSuccess = await adManager.showRewardedAd(from: mockGameViewController)
        XCTAssertTrue(showSuccess, "Ad should show successfully")
        
        // PHASE 2: Verify Reward Callback
        XCTAssertTrue(mockDelegate.didEarnRewardCalled, "Reward delegate should be called")
        XCTAssertEqual(mockDelegate.lastRewardAmount, 1, "Reward amount should be 1")
        XCTAssertEqual(mockDelegate.lastRewardType, "continue_game", "Reward type should be continue_game")
        
        // PHASE 3: Test Error Scenario
        let errorDelegate = MockAdRewardDelegate()
        adManager.rewardDelegate = errorDelegate
        
        // Try to show ad when none is loaded
        let failureSuccess = await adManager.showRewardedAd(from: mockGameViewController)
        XCTAssertFalse(failureSuccess, "Should fail when no ad is loaded")
        XCTAssertTrue(errorDelegate.didFailToShowAdCalled, "Error delegate should be called")
    }
}

// MARK: - Mock Classes for Integration Testing

private class MockGameViewController: GameViewController {
    var didPresentAlert = false
    var presentedAlertTitle: String?
    var presentedAlertMessage: String?
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didPresentAlert = true
        
        if let alert = viewControllerToPresent as? UIAlertController {
            presentedAlertTitle = alert.title
            presentedAlertMessage = alert.message
        }
        
        completion?()
    }
}

private class MockAdRewardDelegate: AdRewardDelegate {
    var didEarnRewardCalled = false
    var didFailToShowAdCalled = false
    var didDismissAdCalled = false
    
    var lastRewardAmount: Int = 0
    var lastRewardType: String = ""
    var lastError: AdError?
    var lastDismissWasCompleted: Bool = false
    
    func adManager(_ manager: AdManager, didEarnReward amount: Int, type: String) {
        didEarnRewardCalled = true
        lastRewardAmount = amount
        lastRewardType = type
    }
    
    func adManager(_ manager: AdManager, didFailToShowAd error: AdError) {
        didFailToShowAdCalled = true
        lastError = error
    }
    
    func adManager(_ manager: AdManager, didDismissAd wasCompleted: Bool) {
        didDismissAdCalled = true
        lastDismissWasCompleted = wasCompleted
    }
}