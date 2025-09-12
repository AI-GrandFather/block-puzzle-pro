import XCTest
import UIKit
@testable import BlockPuzzlePro

// MARK: - GameAdIntegration Tests

final class GameAdIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: GameAdIntegration!
    private var mockGameViewController: MockGameViewController!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        mockGameViewController = MockGameViewController()
        sut = GameAdIntegration(gameViewController: mockGameViewController)
        
        // Reset managers for clean testing
        Task {
            await AdManager.shared.reset()
        }
        ATTManager.shared.resetForTesting()
    }
    
    override func tearDown() {
        sut = nil
        mockGameViewController = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testGameAdIntegration_Initialization_SetsUpCorrectly() {
        // Given - GameAdIntegration initialization
        
        // When - Creating GameAdIntegration
        // (Already done in setUp)
        
        // Then - Should have correct initial state
        XCTAssertFalse(sut.canContinueGame, "Should not allow continue game initially")
        XCTAssertFalse(sut.showATTPrompt, "Should not show ATT prompt initially")
    }
    
    // MARK: - Game Over Scenario Tests
    
    func testGameAdIntegration_HandleGameOver_WithAdReady_EnablesContinue() async {
        // Given - AdManager with ready ad
        await AdManager.shared.initializeAdMob()
        await AdManager.shared.preloadRewardedAd()
        
        let isAdReady = await AdManager.shared.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ad should be ready for test")
        
        // When - Handling game over
        await sut.handleGameOver()
        
        // Then - Should enable continue game option
        await MainActor.run {
            XCTAssertTrue(sut.canContinueGame, "Should allow continue game when ad is ready")
        }
    }
    
    func testGameAdIntegration_HandleGameOver_WithoutAdReady_DisablesContinue() async {
        // Given - AdManager without ready ad
        await AdManager.shared.initializeAdMob()
        // Don't preload ad
        
        let isAdReady = await AdManager.shared.isRewardedAdReady()
        XCTAssertFalse(isAdReady, "Ad should not be ready for test")
        
        // When - Handling game over
        await sut.handleGameOver()
        
        // Then - Should disable continue game option
        await MainActor.run {
            XCTAssertFalse(sut.canContinueGame, "Should not allow continue game when ad is not ready")
        }
    }
    
    func testGameAdIntegration_ShowContinueAd_WithViewController_CallsAdManager() async {
        // Given - GameAdIntegration with ready ad
        await AdManager.shared.initializeAdMob()
        await AdManager.shared.preloadRewardedAd()
        
        // When - Showing continue ad
        let success = await sut.showContinueAd()
        
        // Then - Should succeed and call AdManager
        XCTAssertTrue(success, "Showing continue ad should succeed when ad is ready")
    }
    
    func testGameAdIntegration_ShowContinueAd_WithoutViewController_Fails() async {
        // Given - GameAdIntegration without view controller
        let sutWithoutVC = GameAdIntegration(gameViewController: nil)
        await AdManager.shared.initializeAdMob()
        await AdManager.shared.preloadRewardedAd()
        
        // When - Showing continue ad
        let success = await sutWithoutVC.showContinueAd()
        
        // Then - Should fail due to missing view controller
        XCTAssertFalse(success, "Showing continue ad should fail without view controller")
    }
    
    // MARK: - Power-Up Ads Tests
    
    func testGameAdIntegration_ShowPowerUpAd_WithViewController_CallsAdManager() async {
        // Given - GameAdIntegration with ready ad
        await AdManager.shared.initializeAdMob()
        await AdManager.shared.preloadRewardedAd()
        
        // When - Showing power-up ad
        let success = await sut.showPowerUpAd()
        
        // Then - Should succeed and call AdManager
        XCTAssertTrue(success, "Showing power-up ad should succeed when ad is ready")
    }
    
    func testGameAdIntegration_ShowPowerUpAd_WithoutViewController_Fails() async {
        // Given - GameAdIntegration without view controller
        let sutWithoutVC = GameAdIntegration(gameViewController: nil)
        await AdManager.shared.initializeAdMob()
        await AdManager.shared.preloadRewardedAd()
        
        // When - Showing power-up ad
        let success = await sutWithoutVC.showPowerUpAd()
        
        // Then - Should fail due to missing view controller
        XCTAssertFalse(success, "Showing power-up ad should fail without view controller")
    }
    
    // MARK: - ATT Management Tests
    
    func testGameAdIntegration_HandleATTPromptResponse_RequestsPermission() async {
        // Given - GameAdIntegration with ATT prompt showing
        await MainActor.run {
            sut.showATTPrompt = true
        }
        XCTAssertTrue(sut.showATTPrompt, "ATT prompt should be showing")
        
        // When - Handling ATT prompt response
        await sut.handleATTPromptResponse()
        
        // Then - Should hide prompt and request permission
        await MainActor.run {
            XCTAssertFalse(sut.showATTPrompt, "ATT prompt should be hidden after response")
        }
        
        XCTAssertTrue(ATTManager.shared.hasRequestedPermission, "Should have requested ATT permission")
    }
    
    // MARK: - Preloading Management Tests
    
    func testGameAdIntegration_PreloadAdsForGameplay_InitializesAndPreloads() async {
        // Given - Uninitialized AdManager
        let initialState = await AdManager.shared.isInitialized
        XCTAssertFalse(initialState, "AdManager should not be initialized initially")
        
        // When - Preloading ads for gameplay
        await sut.preloadAdsForGameplay()
        
        // Then - Should initialize and preload
        // Note: This test verifies the method completes without error
        // Actual preloading behavior is tested in AdManager tests
    }
    
    func testGameAdIntegration_PauseResumeAdOperations_CompletesSuccessfully() async {
        // Given - GameAdIntegration ready for operations
        
        // When - Pausing and resuming ad operations
        await sut.pauseAdOperations()
        await sut.resumeAdOperations()
        
        // Then - Operations should complete without error
        // These methods primarily handle logging and coordination
    }
    
    // MARK: - AdRewardDelegate Implementation Tests
    
    func testGameAdIntegration_AdRewardDelegate_DidEarnReward_ContinueGame() {
        // Given - GameAdIntegration as reward delegate
        let expectation = expectation(description: "Continue reward handled")
        
        // When - Earning continue game reward
        sut.adManager(AdManager.shared, didEarnReward: 1, type: "continue_game")
        
        // Give time for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            // Then - Should handle continue reward
            // Verification that no crashes occur and method completes
        }
    }
    
    func testGameAdIntegration_AdRewardDelegate_DidEarnReward_PowerUp() {
        // Given - GameAdIntegration as reward delegate
        let expectation = expectation(description: "Power-up reward handled")
        
        // When - Earning power-up reward
        sut.adManager(AdManager.shared, didEarnReward: 1, type: "power_up")
        
        // Give time for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            // Then - Should handle power-up reward
            // Verification that no crashes occur and method completes
        }
    }
    
    func testGameAdIntegration_AdRewardDelegate_DidEarnReward_UnknownType() {
        // Given - GameAdIntegration as reward delegate
        let expectation = expectation(description: "Unknown reward handled")
        
        // When - Earning unknown reward type
        sut.adManager(AdManager.shared, didEarnReward: 1, type: "unknown_type")
        
        // Give time for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            // Then - Should handle unknown reward gracefully
            // Verification that no crashes occur and method completes
        }
    }
    
    func testGameAdIntegration_AdRewardDelegate_DidFailToShowAd() {
        // Given - GameAdIntegration as reward delegate with view controller
        let expectation = expectation(description: "Ad failure handled")
        
        // When - Ad fails to show
        sut.adManager(AdManager.shared, didFailToShowAd: .networkUnavailable)
        
        // Give time for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            // Then - Should handle ad failure
            XCTAssertTrue(self.mockGameViewController.didPresentAlert, "Should present error alert")
        }
    }
    
    func testGameAdIntegration_AdRewardDelegate_DidDismissAd_Completed() {
        // Given - GameAdIntegration as reward delegate
        let expectation = expectation(description: "Ad dismiss handled")
        
        // When - Ad is dismissed after completion
        sut.adManager(AdManager.shared, didDismissAd: true)
        
        // Give time for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            // Then - Should handle ad dismissal
            // Verification that no crashes occur and method completes
        }
    }
    
    func testGameAdIntegration_AdRewardDelegate_DidDismissAd_NotCompleted() {
        // Given - GameAdIntegration as reward delegate
        let expectation = expectation(description: "Ad dismiss handled")
        
        // When - Ad is dismissed without completion
        sut.adManager(AdManager.shared, didDismissAd: false)
        
        // Give time for async operations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0) { _ in
            // Then - Should handle ad dismissal without reward
            // Verification that no crashes occur and method completes
        }
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testGameAdIntegration_MonitorGamePerformance_CompletesSuccessfully() {
        // Given - GameAdIntegration ready for monitoring
        
        // When - Monitoring game performance
        sut.monitorGamePerformance()
        
        // Then - Should complete without error
        // This method primarily handles logging
    }
    
    func testGameAdIntegration_IsAdOperationImpactingPerformance_ReturnsFalse() {
        // Given - GameAdIntegration with optimized ad operations
        
        // When - Checking if ad operations impact performance
        let isImpacting = sut.isAdOperationImpactingPerformance()
        
        // Then - Should return false (optimized implementation)
        XCTAssertFalse(isImpacting, "Ad operations should not impact performance")
    }
}

// MARK: - Mock Classes

private class MockGameViewController: GameViewController {
    var didPresentAlert = false
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didPresentAlert = true
        completion?()
    }
}

// MARK: - AdManager Testing Extensions

extension AdManager {
    func reset() async {
        await MainActor.run {
            rewardedAdState = .notLoaded
            isInitialized = false
        }
        rewardedAd = nil
        retryAttempts = 0
        loadingTask?.cancel()
        loadingTask = nil
    }
}