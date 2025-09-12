import XCTest
import UIKit
@testable import BlockPuzzlePro

// MARK: - AdManager Tests

final class AdManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: AdManager!
    private var mockDelegate: MockAdRewardDelegate!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        sut = AdManager()
        mockDelegate = MockAdRewardDelegate()
    }
    
    override func tearDown() {
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testAdManager_InitialState_IsCorrect() async {
        // Given - Fresh AdManager instance
        
        // When - Checking initial state
        let isInitialized = await sut.isInitialized
        let adState = await sut.rewardedAdState
        let isAdReady = await sut.isRewardedAdReady()
        
        // Then - Should be in expected initial state
        XCTAssertFalse(isInitialized, "AdManager should not be initialized on creation")
        
        if case .notLoaded = adState {
            // Expected state
        } else {
            XCTFail("Initial ad state should be .notLoaded, got \(adState)")
        }
        
        XCTAssertFalse(isAdReady, "Rewarded ad should not be ready initially")
    }
    
    func testAdManager_Initialization_CompletesSuccessfully() async {
        // Given - Uninitialized AdManager
        let initialState = await sut.isInitialized
        XCTAssertFalse(initialState)
        
        // When - Initializing AdMob
        await sut.initializeAdMob()
        
        // Then - Should be initialized
        let finalState = await sut.isInitialized
        XCTAssertTrue(finalState, "AdManager should be initialized after initializeAdMob()")
    }
    
    func testAdManager_DoubleInitialization_DoesNotCauseDuplication() async {
        // Given - AdManager initialized once
        await sut.initializeAdMob()
        let firstInitState = await sut.isInitialized
        XCTAssertTrue(firstInitState)
        
        // When - Initializing again
        await sut.initializeAdMob()
        
        // Then - Should still be initialized (no side effects)
        let secondInitState = await sut.isInitialized
        XCTAssertTrue(secondInitState, "AdManager should remain initialized after double initialization")
    }
    
    // MARK: - Ad Loading Tests
    
    func testAdManager_PreloadRewardedAd_BeforeInitialization_Fails() async {
        // Given - Uninitialized AdManager
        let initialState = await sut.isInitialized
        XCTAssertFalse(initialState)
        
        // When - Attempting to preload ad
        await sut.preloadRewardedAd()
        
        // Then - Ad should not be loaded
        let isAdReady = await sut.isRewardedAdReady()
        XCTAssertFalse(isAdReady, "Ad should not load when AdManager is not initialized")
    }
    
    func testAdManager_PreloadRewardedAd_AfterInitialization_Succeeds() async {
        // Given - Initialized AdManager
        await sut.initializeAdMob()
        let isInitialized = await sut.isInitialized
        XCTAssertTrue(isInitialized)
        
        // When - Preloading ad
        await sut.preloadRewardedAd()
        
        // Then - Ad should be loaded (simulated success)
        let isAdReady = await sut.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ad should be loaded after successful preload")
        
        let adState = await sut.rewardedAdState
        if case .loaded = adState {
            // Expected state
        } else {
            XCTFail("Ad state should be .loaded after successful preload, got \(adState)")
        }
    }
    
    func testAdManager_PreloadRewardedAd_WhileAlreadyLoading_DoesNotStartNewLoad() async {
        // Given - Initialized AdManager
        await sut.initializeAdMob()
        
        // When - Starting two simultaneous preload operations
        async let firstLoad = sut.preloadRewardedAd()
        async let secondLoad = sut.preloadRewardedAd()
        
        // Wait for both to complete
        await firstLoad
        await secondLoad
        
        // Then - Should handle gracefully without conflicts
        let isAdReady = await sut.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ad should be loaded despite simultaneous load attempts")
    }
    
    // MARK: - Ad Display Tests
    
    func testAdManager_ShowRewardedAd_WithoutLoadedAd_Fails() async {
        // Given - Initialized AdManager with no loaded ad
        await sut.initializeAdMob()
        let mockViewController = MockViewController()
        await sut.setRewardDelegate(mockDelegate)
        
        // When - Attempting to show ad
        let success = await sut.showRewardedAd(from: mockViewController)
        
        // Then - Should fail
        XCTAssertFalse(success, "Showing ad without loaded ad should fail")
        XCTAssertTrue(mockDelegate.didFailToShowAdCalled, "Delegate should be notified of failure")
        XCTAssertEqual(mockDelegate.lastError?.localizedDescription, AdError.noAdsLoaded.localizedDescription)
    }
    
    func testAdManager_ShowRewardedAd_WithLoadedAd_Succeeds() async {
        // Given - Initialized AdManager with loaded ad
        await sut.initializeAdMob()
        await sut.preloadRewardedAd()
        let mockViewController = MockViewController()
        await sut.setRewardDelegate(mockDelegate)
        
        let isAdReady = await sut.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ad should be ready before test")
        
        // When - Showing ad
        let success = await sut.showRewardedAd(from: mockViewController)
        
        // Then - Should succeed and trigger reward
        XCTAssertTrue(success, "Showing loaded ad should succeed")
        XCTAssertTrue(mockDelegate.didEarnRewardCalled, "Delegate should be notified of reward")
        XCTAssertEqual(mockDelegate.lastRewardAmount, 1)
        XCTAssertEqual(mockDelegate.lastRewardType, "continue_game")
        
        // Ad should be consumed and not ready anymore
        let isAdReadyAfterShow = await sut.isRewardedAdReady()
        XCTAssertFalse(isAdReadyAfterShow, "Ad should not be ready after being shown")
    }
    
    // MARK: - Error Handling Tests
    
    func testAdManager_HandleNetworkError_UpdatesStateCorrectly() async {
        // Given - Initialized AdManager
        await sut.initializeAdMob()
        
        // When - Handling network error
        await sut.handleNetworkError()
        
        // Then - State should reflect network error
        let adState = await sut.rewardedAdState
        if case .failed(let error) = adState {
            XCTAssertEqual(error.localizedDescription, AdError.networkUnavailable.localizedDescription)
        } else {
            XCTFail("Ad state should be .failed with network error, got \(adState)")
        }
    }
    
    func testAdManager_RetryFailedAds_ResetsRetryAttempts() async {
        // Given - AdManager with failed ad state
        await sut.initializeAdMob()
        await sut.handleNetworkError()
        
        let initialState = await sut.rewardedAdState
        if case .failed(_) = initialState {
            // Expected state
        } else {
            XCTFail("Should be in failed state before retry")
        }
        
        // When - Retrying failed ads
        await sut.retryFailedAds()
        
        // Then - Should attempt to load again and succeed (simulated)
        let finalState = await sut.rewardedAdState
        if case .loaded = finalState {
            // Expected successful retry
        } else if case .loading = finalState {
            // Also acceptable - retry in progress
        } else {
            XCTFail("Ad state should be .loaded or .loading after retry, got \(finalState)")
        }
    }
    
    // MARK: - Debug Information Tests
    
    func testAdManager_GetDebugInfo_ContainsExpectedInformation() async {
        // Given - Initialized AdManager with loaded ad
        await sut.initializeAdMob()
        await sut.preloadRewardedAd()
        
        // When - Getting debug info
        let debugInfo = await sut.getDebugInfo()
        
        // Then - Should contain key information
        XCTAssertTrue(debugInfo.contains("AdManager Debug Info"), "Debug info should contain header")
        XCTAssertTrue(debugInfo.contains("Initialized: true"), "Debug info should show initialization status")
        XCTAssertTrue(debugInfo.contains("Ready to Show"), "Debug info should show ad ready state")
        XCTAssertTrue(debugInfo.contains("Configuration:"), "Debug info should include configuration")
    }
}

// MARK: - Mock Classes

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

private class MockViewController: UIViewController {
    // Mock view controller for testing
}

// MARK: - AdManager Test Extensions

extension AdManager {
    func setRewardDelegate(_ delegate: AdRewardDelegate?) async {
        self.rewardDelegate = delegate
    }
}