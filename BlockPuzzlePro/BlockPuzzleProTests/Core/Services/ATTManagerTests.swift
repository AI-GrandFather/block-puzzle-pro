import XCTest
import UIKit
@testable import BlockPuzzlePro

// MARK: - ATTManager Tests

final class ATTManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ATTManager!
    private var notificationObserver: TestNotificationObserver!
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        sut = ATTManager.shared
        notificationObserver = TestNotificationObserver()
        
        // Reset ATTManager state for testing
        sut.resetForTesting()
    }
    
    override func tearDown() {
        notificationObserver?.stopObserving()
        notificationObserver = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testATTManager_InitialState_IsCorrect() {
        // Given - Fresh ATTManager instance
        
        // When - Checking initial state
        let initialStatus = sut.attStatus
        let hasRequested = sut.hasRequestedPermission
        
        // Then - Should be in expected initial state
        XCTAssertEqual(initialStatus, .notDetermined, "Initial ATT status should be notDetermined")
        XCTAssertFalse(hasRequested, "Should not have requested permission initially")
        XCTAssertFalse(sut.canShowPersonalizedAds(), "Should not allow personalized ads initially")
    }
    
    func testATTManager_Singleton_ReturnsSameInstance() {
        // Given - Multiple calls to shared instance
        
        // When - Getting shared instances
        let instance1 = ATTManager.shared
        let instance2 = ATTManager.shared
        
        // Then - Should return same instance
        XCTAssertTrue(instance1 === instance2, "ATTManager.shared should return the same instance")
    }
    
    // MARK: - Permission Request Tests
    
    func testATTManager_RequestTrackingPermission_WhenNotDetermined_UpdatesStatus() async {
        // Given - ATTManager in notDetermined state
        XCTAssertEqual(sut.attStatus, .notDetermined)
        XCTAssertFalse(sut.hasRequestedPermission)
        
        // When - Requesting tracking permission
        await sut.requestTrackingPermission()
        
        // Then - Status should be updated and request flag set
        XCTAssertEqual(sut.attStatus, .authorized, "Status should be authorized after simulated permission grant")
        XCTAssertTrue(sut.hasRequestedPermission, "hasRequestedPermission should be true after request")
        XCTAssertTrue(sut.canShowPersonalizedAds(), "Should allow personalized ads after authorization")
    }
    
    func testATTManager_RequestTrackingPermission_WhenAlreadyDetermined_DoesNotChangeStatus() async {
        // Given - ATTManager with already determined status
        await sut.requestTrackingPermission() // First request
        let statusAfterFirstRequest = sut.attStatus
        let requestFlagAfterFirst = sut.hasRequestedPermission
        
        // When - Requesting permission again
        await sut.requestTrackingPermission()
        
        // Then - Status should remain unchanged
        XCTAssertEqual(sut.attStatus, statusAfterFirstRequest, "Status should not change on duplicate request")
        XCTAssertEqual(sut.hasRequestedPermission, requestFlagAfterFirst, "Request flag should not change")
    }
    
    func testATTManager_RequestTrackingPermissionIfNeeded_WhenNeeded_MakesRequest() async {
        // Given - ATTManager that needs permission request
        XCTAssertEqual(sut.attStatus, .notDetermined)
        XCTAssertFalse(sut.hasRequestedPermission)
        
        // When - Requesting permission if needed
        await sut.requestTrackingPermissionIfNeeded()
        
        // Then - Should make the request
        XCTAssertTrue(sut.hasRequestedPermission, "Should have requested permission when needed")
        XCTAssertEqual(sut.attStatus, .authorized, "Status should be updated after request")
    }
    
    func testATTManager_RequestTrackingPermissionIfNeeded_WhenNotNeeded_DoesNotMakeRequest() async {
        // Given - ATTManager that already requested permission
        await sut.requestTrackingPermission()
        let initialRequestStatus = sut.hasRequestedPermission
        let initialATTStatus = sut.attStatus
        
        // When - Requesting permission if needed again
        await sut.requestTrackingPermissionIfNeeded()
        
        // Then - Should not make another request
        XCTAssertEqual(sut.hasRequestedPermission, initialRequestStatus, "Request status should not change")
        XCTAssertEqual(sut.attStatus, initialATTStatus, "ATT status should not change")
    }
    
    // MARK: - Permission Timing Tests
    
    func testATTManager_ShouldRequestPermissionAfterGameplay_WhenNotDetermined_ReturnsTrue() {
        // Given - ATTManager in notDetermined state
        XCTAssertEqual(sut.attStatus, .notDetermined)
        XCTAssertFalse(sut.hasRequestedPermission)
        
        // When - Checking if should request after gameplay
        let shouldRequest = sut.shouldRequestPermissionAfterGameplay()
        
        // Then - Should return true
        XCTAssertTrue(shouldRequest, "Should request permission after gameplay when not determined")
    }
    
    func testATTManager_ShouldRequestPermissionAfterGameplay_WhenAlreadyRequested_ReturnsFalse() async {
        // Given - ATTManager that already requested permission
        await sut.requestTrackingPermission()
        
        // When - Checking if should request after gameplay
        let shouldRequest = sut.shouldRequestPermissionAfterGameplay()
        
        // Then - Should return false
        XCTAssertFalse(shouldRequest, "Should not request permission again after already requested")
    }
    
    // MARK: - Ad Personalization Tests
    
    func testATTManager_CanShowPersonalizedAds_WhenAuthorized_ReturnsTrue() async {
        // Given - ATTManager with authorized status
        await sut.requestTrackingPermission() // Simulates authorization
        
        // When - Checking if can show personalized ads
        let canShow = sut.canShowPersonalizedAds()
        
        // Then - Should return true
        XCTAssertTrue(canShow, "Should allow personalized ads when authorized")
    }
    
    func testATTManager_CanShowPersonalizedAds_WhenNotAuthorized_ReturnsFalse() {
        // Given - ATTManager in notDetermined state
        XCTAssertEqual(sut.attStatus, .notDetermined)
        
        // When - Checking if can show personalized ads
        let canShow = sut.canShowPersonalizedAds()
        
        // Then - Should return false
        XCTAssertFalse(canShow, "Should not allow personalized ads when not authorized")
    }
    
    func testATTManager_GetAdPersonalizationStatus_ReturnsCorrectStatus() async {
        // Given - ATTManager in different states
        
        // When not authorized
        let statusWhenNotAuthorized = sut.getAdPersonalizationStatus()
        XCTAssertEqual(statusWhenNotAuthorized, "Non-personalized ads only")
        
        // When authorized
        await sut.requestTrackingPermission()
        let statusWhenAuthorized = sut.getAdPersonalizationStatus()
        XCTAssertEqual(statusWhenAuthorized, "Personalized ads enabled")
    }
    
    // MARK: - Status Description Tests
    
    func testATTStatus_Descriptions_AreCorrect() {
        // Given - Different ATTStatus values
        
        // When - Getting descriptions
        let notDeterminedDesc = ATTStatus.notDetermined.description
        let deniedDesc = ATTStatus.denied.description
        let authorizedDesc = ATTStatus.authorized.description
        let restrictedDesc = ATTStatus.restricted.description
        let unavailableDesc = ATTStatus.unavailable.description
        
        // Then - Should have correct descriptions
        XCTAssertEqual(notDeterminedDesc, "Not Determined")
        XCTAssertEqual(deniedDesc, "Denied")
        XCTAssertEqual(authorizedDesc, "Authorized")
        XCTAssertEqual(restrictedDesc, "Restricted")
        XCTAssertEqual(unavailableDesc, "Unavailable (iOS < 14.5)")
    }
    
    func testATTStatus_CanShowPersonalizedAds_OnlyTrueForAuthorized() {
        // Given - Different ATTStatus values
        let statuses: [ATTStatus] = [.notDetermined, .denied, .authorized, .restricted, .unavailable]
        
        // When - Checking canShowPersonalizedAds for each
        let results = statuses.map { $0.canShowPersonalizedAds }
        
        // Then - Only authorized should return true
        XCTAssertEqual(results, [false, false, true, false, false])
    }
    
    // MARK: - Debug Information Tests
    
    func testATTManager_GetDebugInfo_ContainsExpectedInformation() async {
        // Given - ATTManager with some state
        await sut.requestTrackingPermission()
        
        // When - Getting debug info
        let debugInfo = sut.getDebugInfo()
        
        // Then - Should contain key information
        XCTAssertTrue(debugInfo.contains("ATT Manager Debug Info"), "Debug info should contain header")
        XCTAssertTrue(debugInfo.contains("Status: Authorized"), "Debug info should show current status")
        XCTAssertTrue(debugInfo.contains("Has Requested: true"), "Debug info should show request status")
        XCTAssertTrue(debugInfo.contains("Can Show Personalized Ads: true"), "Debug info should show ad capability")
        XCTAssertTrue(debugInfo.contains("Should Request Permission: false"), "Debug info should show permission need")
    }
    
    // MARK: - Notification Tests
    
    func testATTManager_RequestTrackingPermission_PostsNotification() async {
        // Given - Notification observer
        notificationObserver.startObserving()
        
        // When - Requesting tracking permission
        await sut.requestTrackingPermission()
        
        // Then - Should post notification
        XCTAssertTrue(notificationObserver.didReceiveATTStatusChanged, "Should post ATT status changed notification")
        XCTAssertEqual(notificationObserver.lastReceivedStatus, .authorized)
    }
}

// MARK: - Test Helpers

private class TestNotificationObserver {
    var didReceiveATTStatusChanged = false
    var lastReceivedStatus: ATTStatus?
    
    func startObserving() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleATTStatusChanged(_:)),
            name: .attStatusChanged,
            object: nil
        )
    }
    
    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleATTStatusChanged(_ notification: Notification) {
        didReceiveATTStatusChanged = true
        lastReceivedStatus = notification.userInfo?["status"] as? ATTStatus
    }
}

// MARK: - ATTManager Testing Extensions

extension ATTManager {
    func resetForTesting() {
        attStatus = .notDetermined
        hasRequestedPermission = false
    }
}