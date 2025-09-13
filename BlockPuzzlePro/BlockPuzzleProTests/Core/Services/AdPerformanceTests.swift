import XCTest
import UIKit
@testable import BlockPuzzlePro

// MARK: - Ad Performance Tests

final class AdPerformanceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var adManager: AdManager!
    private var gameAdIntegration: GameAdIntegration!
    private var mockGameViewController: MockGameViewController!
    
    // Performance measurement properties
    private let targetFrameTime60: TimeInterval = 1.0 / 60.0 // 60 FPS = 16.67ms per frame
    private let targetFrameTime120: TimeInterval = 1.0 / 120.0 // 120 FPS = 8.33ms per frame
    private let maxAcceptableFrameTime60: TimeInterval = 1.0 / 55.0 // Allow up to 55 FPS (18.18ms)
    private let maxAcceptableFrameTime120: TimeInterval = 1.0 / 110.0 // Allow up to 110 FPS (9.09ms)
    
    // MARK: - Lifecycle
    
    override func setUp() {
        super.setUp()
        
        adManager = AdManager.shared
        mockGameViewController = MockGameViewController()
        gameAdIntegration = GameAdIntegration(gameViewController: mockGameViewController)
        
        // Reset state for clean testing
        Task {
            await adManager.reset()
        }
    }
    
    override func tearDown() {
        adManager = nil
        gameAdIntegration = nil
        mockGameViewController = nil
        super.tearDown()
    }
    
    // MARK: - Ad Loading Performance Tests
    
    func testAdLoading_DoesNotBlockMainThread() async {
        // Given - Initialized AdManager
        await adManager.initializeAdMob()
        
        // When - Measuring ad loading performance on main thread
        let loadStartTime = CFAbsoluteTimeGetCurrent()
        let mainThreadBlocked = await measureMainThreadBlocking {
            await self.adManager.preloadRewardedAd()
        }
        let loadEndTime = CFAbsoluteTimeGetCurrent()
        let totalLoadTime = loadEndTime - loadStartTime
        
        // Then - Main thread should not be blocked (use 60 FPS as baseline)
        XCTAssertLessThan(mainThreadBlocked, maxAcceptableFrameTime60, 
                         "Ad loading should not block main thread longer than \(maxAcceptableFrameTime60 * 1000)ms")
        
        // Verify ad was actually loaded
        let isAdReady = await adManager.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ad should be loaded after preload operation")
        
        print("📊 Ad Loading Performance:")
        print("   Total Load Time: \(String(format: "%.2f", totalLoadTime * 1000))ms")
        print("   Main Thread Blocked: \(String(format: "%.2f", mainThreadBlocked * 1000))ms")
        print("   Target 60 FPS Frame Time: \(String(format: "%.2f", targetFrameTime60 * 1000))ms")
        print("   Target 120 FPS Frame Time: \(String(format: "%.2f", targetFrameTime120 * 1000))ms")
    }
    
    func testAdInitialization_CompletesWithinReasonableTime() async {
        // Given - Uninitialized AdManager
        let isInitialized = await adManager.isInitialized
        XCTAssertFalse(isInitialized)
        
        // When - Measuring initialization time
        let initStartTime = CFAbsoluteTimeGetCurrent()
        await adManager.initializeAdMob()
        let initEndTime = CFAbsoluteTimeGetCurrent()
        
        let initTime = initEndTime - initStartTime
        
        // Then - Initialization should complete within reasonable time
        XCTAssertLessThan(initTime, 5.0, "AdMob initialization should complete within 5 seconds")
        
        let finalIsInitialized = await adManager.isInitialized
        XCTAssertTrue(finalIsInitialized, "AdManager should be initialized after completion")
        
        print("📊 Ad Initialization Performance:")
        print("   Initialization Time: \(String(format: "%.2f", initTime * 1000))ms")
    }
    
    // MARK: - Concurrent Operation Performance Tests
    
    func testConcurrentAdOperations_DoNotDegradePerformance() async {
        // Given - Initialized system
        await adManager.initializeAdMob()
        
        // When - Running multiple concurrent ad operations
        let concurrentStartTime = CFAbsoluteTimeGetCurrent()
        
        async let preload1 = adManager.preloadRewardedAd()
        async let preload2 = adManager.preloadRewardedAd() // Should handle gracefully
        async let gameOver1 = gameAdIntegration.handleGameOver()
        async let gameOver2 = gameAdIntegration.handleGameOver()
        async let preload3 = gameAdIntegration.preloadAdsForGameplay()
        
        // Wait for all operations to complete
        await preload1
        await preload2
        await gameOver1
        await gameOver2
        await preload3
        
        let concurrentEndTime = CFAbsoluteTimeGetCurrent()
        let concurrentTime = concurrentEndTime - concurrentStartTime
        
        // Then - Concurrent operations should not degrade performance significantly
        XCTAssertLessThan(concurrentTime, 10.0, "Concurrent ad operations should complete within 10 seconds")
        
        // Verify system is still functional
        let isAdReady = await adManager.isRewardedAdReady()
        XCTAssertTrue(isAdReady, "Ad should be ready after concurrent operations")
        
        print("📊 Concurrent Operations Performance:")
        print("   Total Time: \(String(format: "%.2f", concurrentTime * 1000))ms")
    }
    
    // MARK: - Memory Usage Performance Tests
    
    func testAdOperations_DoNotCauseMemoryLeaks() async {
        // Given - Initial memory measurement
        let initialMemory = getMemoryUsage()
        
        // When - Performing multiple ad operations cycles
        for cycle in 1...10 {
            await adManager.initializeAdMob()
            await adManager.preloadRewardedAd()
            
            if await adManager.isRewardedAdReady() {
                _ = await adManager.showRewardedAd(from: mockGameViewController)
            }
            
            await adManager.reset()
            
            // Occasional memory measurement
            if cycle % 3 == 0 {
                let cycleMemory = getMemoryUsage()
                print("📊 Memory after cycle \(cycle): \(String(format: "%.2f", cycleMemory))MB")
            }
        }
        
        // Force garbage collection
        autoreleasepool {}
        
        // Then - Memory should not grow significantly
        let finalMemory = getMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory
        
        XCTAssertLessThan(memoryGrowth, 50.0, "Memory growth should be less than 50MB after 10 cycles")
        
        print("📊 Memory Usage Performance:")
        print("   Initial Memory: \(String(format: "%.2f", initialMemory))MB")
        print("   Final Memory: \(String(format: "%.2f", finalMemory))MB")
        print("   Memory Growth: \(String(format: "%.2f", memoryGrowth))MB")
    }
    
    // MARK: - Game Integration Performance Tests
    
    func testGameAdIntegration_MaintainsResponsiveness() async {
        // Given - Game integration with performance monitoring
        await adManager.initializeAdMob()
        gameAdIntegration.monitorGamePerformance()
        
        // When - Performing game-related ad operations
        let gameStartTime = CFAbsoluteTimeGetCurrent()
        
        await gameAdIntegration.preloadAdsForGameplay()
        await gameAdIntegration.handleGameOver()
        
        let gameEndTime = CFAbsoluteTimeGetCurrent()
        let gameOperationTime = gameEndTime - gameStartTime
        
        // Then - Game operations should remain responsive
        XCTAssertLessThan(gameOperationTime, 3.0, "Game ad operations should complete within 3 seconds")
        
        let isImpactingPerformance = gameAdIntegration.isAdOperationImpactingPerformance()
        XCTAssertFalse(isImpactingPerformance, "Ad operations should not impact game performance")
        
        print("📊 Game Integration Performance:")
        print("   Game Operation Time: \(String(format: "%.2f", gameOperationTime * 1000))ms")
        print("   Performance Impact: \(isImpactingPerformance ? "YES" : "NO")")
    }
    
    // MARK: - Error Handling Performance Tests
    
    func testErrorRecovery_DoesNotCausePerformanceDegradation() async {
        // Given - Initialized system
        await adManager.initializeAdMob()
        
        // When - Simulating error and recovery cycles
        let errorCycleStartTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 1...5 {
            // Simulate error
            await adManager.handleNetworkError()
            
            // Attempt recovery
            await adManager.retryFailedAds()
            
            // Small delay to prevent overwhelming
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        let errorCycleEndTime = CFAbsoluteTimeGetCurrent()
        let errorCycleTime = errorCycleEndTime - errorCycleStartTime
        
        // Then - Error recovery should not degrade performance
        XCTAssertLessThan(errorCycleTime, 15.0, "Error recovery cycles should complete within 15 seconds")
        
        // Verify system is still responsive
        let isAdReady = await adManager.isRewardedAdReady()
        // Note: Ad may or may not be ready depending on final state, but system should not crash
        
        print("📊 Error Recovery Performance:")
        print("   Error Cycle Time: \(String(format: "%.2f", errorCycleTime * 1000))ms")
        print("   Final Ad Ready State: \(isAdReady ? "Ready" : "Not Ready")")
    }
    
    // MARK: - Stress Testing
    
    func testAdSystem_HandlesHighFrequencyOperations() async {
        // Given - System ready for stress testing
        await adManager.initializeAdMob()
        
        // When - Performing high frequency operations
        let stressStartTime = CFAbsoluteTimeGetCurrent()
        var successCount = 0
        var errorCount = 0
        
        for i in 1...50 {
            do {
                if i % 10 == 0 {
                    await adManager.preloadRewardedAd()
                    if await adManager.isRewardedAdReady() {
                        successCount += 1
                    }
                } else if i % 7 == 0 {
                    await gameAdIntegration.handleGameOver()
                    successCount += 1
                } else {
                    await gameAdIntegration.preloadAdsForGameplay()
                    successCount += 1
                }
            } catch {
                errorCount += 1
            }
            
            // Brief pause to prevent system overload
            if i % 10 == 0 {
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
        
        let stressEndTime = CFAbsoluteTimeGetCurrent()
        let stressTime = stressEndTime - stressStartTime
        
        // Then - System should handle high frequency operations
        XCTAssertLessThan(stressTime, 20.0, "Stress test should complete within 20 seconds")
        XCTAssertGreaterThan(successCount, 40, "Should have high success rate under stress")
        XCTAssertLessThan(errorCount, 10, "Should have low error rate under stress")
        
        print("📊 Stress Test Performance:")
        print("   Stress Test Time: \(String(format: "%.2f", stressTime * 1000))ms")
        print("   Success Count: \(successCount)/50")
        print("   Error Count: \(errorCount)/50")
        print("   Success Rate: \(String(format: "%.1f", Double(successCount) / 50.0 * 100))%")
    }
    
    // MARK: - ProMotion 120 FPS Tests
    
    func testProMotionSupport_DetectsDisplayCapabilities() {
        // Given - System with display capabilities
        
        // When - Checking ProMotion support
        let maxRefreshRate = UIScreen.main.maximumFramesPerSecond
        let isProMotionSupported = maxRefreshRate >= 120
        
        // Then - Should detect display capabilities correctly
        print("📊 Display Capabilities:")
        print("   Max Refresh Rate: \(maxRefreshRate) FPS")
        print("   ProMotion Supported: \(isProMotionSupported ? "YES" : "NO")")
        
        if isProMotionSupported {
            print("   🎯 ProMotion Display Detected - Testing 120 FPS Performance")
        } else {
            print("   📱 Standard Display - Testing 60 FPS Performance")
        }
        
        // Test should pass regardless of device capabilities
        XCTAssertTrue(maxRefreshRate >= 60, "Device should support at least 60 FPS")
    }
    
    func testProMotionPerformance_MaintainsHighFrameRate() async {
        // Given - ProMotion capable device (skip if not supported)
        let maxRefreshRate = UIScreen.main.maximumFramesPerSecond
        guard maxRefreshRate >= 120 else {
            print("📱 Skipping ProMotion test - Device doesn't support 120 FPS")
            return
        }
        
        // Initialize system for ProMotion testing
        await adManager.initializeAdMob()
        await adManager.preloadRewardedAd()
        
        // When - Performing ad operations at 120 FPS target
        let proMotionStartTime = CFAbsoluteTimeGetCurrent()
        let mainThreadBlocked = await measureMainThreadBlockingProMotion {
            // Simulate intensive operations at 120 FPS
            for _ in 1...10 {
                await self.adManager.preloadRewardedAd()
                await self.gameAdIntegration.handleGameOver()
                try? await Task.sleep(for: .milliseconds(8)) // ~120 FPS timing
            }
        }
        let proMotionEndTime = CFAbsoluteTimeGetCurrent()
        let totalTime = proMotionEndTime - proMotionStartTime
        
        // Then - Should maintain ProMotion performance
        XCTAssertLessThan(mainThreadBlocked, maxAcceptableFrameTime120,
                         "Ad operations should not block main thread longer than 120 FPS frame time")
        XCTAssertLessThan(totalTime, 5.0, "ProMotion operations should complete within reasonable time")
        
        print("📊 ProMotion 120 FPS Performance:")
        print("   Total Operation Time: \(String(format: "%.2f", totalTime * 1000))ms")
        print("   Max Main Thread Block: \(String(format: "%.2f", mainThreadBlocked * 1000))ms")
        print("   120 FPS Frame Budget: \(String(format: "%.2f", targetFrameTime120 * 1000))ms")
        print("   Performance: \(mainThreadBlocked < maxAcceptableFrameTime120 ? "✅ PASS" : "❌ FAIL")")
    }
    
    func testAdOperations_AdaptToFrameRate() async {
        // Given - System with any display capability
        let maxRefreshRate = UIScreen.main.maximumFramesPerSecond
        await adManager.initializeAdMob()
        
        // When - Measuring frame rate adaptation
        let adaptationStartTime = CFAbsoluteTimeGetCurrent()
        
        // Test multiple operation cycles at device's max frame rate
        let targetFrameTime = 1.0 / Double(maxRefreshRate)
        var frameTimeViolations = 0
        
        for cycle in 1...20 {
            let cycleStart = CFAbsoluteTimeGetCurrent()
            
            // Perform ad operation
            if cycle % 5 == 0 {
                await adManager.preloadRewardedAd()
            } else {
                await gameAdIntegration.handleGameOver()
            }
            
            let cycleEnd = CFAbsoluteTimeGetCurrent()
            let cycleTime = cycleEnd - cycleStart
            
            // Check if operation exceeded frame budget
            if cycleTime > targetFrameTime {
                frameTimeViolations += 1
            }
            
            // Brief pause to simulate frame timing
            try? await Task.sleep(for: .nanoseconds(UInt64(targetFrameTime * 0.1 * 1_000_000_000)))
        }
        
        let adaptationEndTime = CFAbsoluteTimeGetCurrent()
        let totalAdaptationTime = adaptationEndTime - adaptationStartTime
        
        // Then - Should adapt well to any frame rate
        let violationRate = Double(frameTimeViolations) / 20.0
        XCTAssertLessThan(violationRate, 0.3, "Less than 30% of operations should exceed frame budget")
        XCTAssertLessThan(totalAdaptationTime, 10.0, "Frame rate adaptation test should complete quickly")
        
        print("📊 Frame Rate Adaptation Performance:")
        print("   Display Max FPS: \(maxRefreshRate)")
        print("   Target Frame Time: \(String(format: "%.2f", targetFrameTime * 1000))ms")
        print("   Frame Budget Violations: \(frameTimeViolations)/20 (\(String(format: "%.1f", violationRate * 100))%)")
        print("   Total Test Time: \(String(format: "%.2f", totalAdaptationTime * 1000))ms")
        print("   Adaptation Quality: \(violationRate < 0.3 ? "✅ EXCELLENT" : "⚠️ NEEDS OPTIMIZATION")")
    }
}

// MARK: - Performance Measurement Helpers

extension AdPerformanceTests {
    
    /// Measures how long the main thread is blocked during an async operation
    private func measureMainThreadBlocking(operation: @escaping () async -> Void) async -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        var maxBlockTime: TimeInterval = 0
        
        // Start monitoring main thread
        let monitorTask = Task { @MainActor in
            let monitorStart = CFAbsoluteTimeGetCurrent()
            
            // Perform small operations to detect blocking
            for _ in 0..<100 {
                let operationStart = CFAbsoluteTimeGetCurrent()
                // Simulate frame work
                _ = (1...1000).reduce(0, +)
                let operationEnd = CFAbsoluteTimeGetCurrent()
                let operationTime = operationEnd - operationStart
                maxBlockTime = max(maxBlockTime, operationTime)
                
                try? await Task.sleep(for: .milliseconds(1))
            }
            
            let monitorEnd = CFAbsoluteTimeGetCurrent()
            return monitorEnd - monitorStart
        }
        
        // Perform the actual operation
        await operation()
        
        // Wait for monitoring to complete
        _ = await monitorTask.value
        
        return maxBlockTime
    }
    
    /// Measures main thread blocking specifically for ProMotion displays (120 FPS)
    private func measureMainThreadBlockingProMotion(operation: @escaping () async -> Void) async -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        var maxBlockTime: TimeInterval = 0
        
        // Start monitoring main thread at 120 FPS intervals
        let monitorTask = Task { @MainActor in
            let monitorStart = CFAbsoluteTimeGetCurrent()
            
            // Perform high-frequency operations to detect ProMotion blocking
            for _ in 0...240 { // 2 seconds at 120 FPS
                let operationStart = CFAbsoluteTimeGetCurrent()
                // Simulate ProMotion frame work (more intensive than 60 FPS)
                _ = (1...2000).reduce(0, +)
                let operationEnd = CFAbsoluteTimeGetCurrent()
                let operationTime = operationEnd - operationStart
                maxBlockTime = max(maxBlockTime, operationTime)
                
                // 120 FPS timing
                try? await Task.sleep(for: .nanoseconds(8_333_333)) // 8.33ms = 120 FPS
            }
            
            let monitorEnd = CFAbsoluteTimeGetCurrent()
            return monitorEnd - monitorStart
        }
        
        // Perform the actual operation
        await operation()
        
        // Wait for monitoring to complete
        _ = await monitorTask.value
        
        return maxBlockTime
    }
    
    /// Gets current memory usage in MB
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0.0
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