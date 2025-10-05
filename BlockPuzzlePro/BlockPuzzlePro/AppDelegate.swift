// FILE: AppDelegate.swift
import UIKit
import os.log

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "AppDelegate")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        logger.info("Application did finish launching")

        // Initialize theme - set default for new installs
        let currentTheme = Theme.current
        logger.info("Current theme: \(currentTheme.displayName)")

        // Performance optimizations
        PerformanceMonitor.Flags.enableNodePooling = true
        PerformanceMonitor.Flags.enableSpatialIndexing = true
        PerformanceMonitor.Flags.enableMemoryOptimizations = true

        // Enable 120Hz ProMotion support for smoother gameplay
        if #available(iOS 15.0, *) {
            let maxRefreshRate = UIScreen.main.maximumFramesPerSecond
            logger.info("Device supports up to \(maxRefreshRate)Hz refresh rate")
            if maxRefreshRate >= 120 {
                logger.info("🚀 ProMotion (120Hz) enabled for enhanced performance")
            }
        }

        #if DEBUG
        PerformanceMonitor.Flags.showPerformanceOverlay = true
        DebugFlags.enableDebugMode()
        #endif

        return true
    }

    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        logger.warning("Application received memory warning")
        MemoryProfiler.logMemoryUsage(context: "Memory Warning")

        // Enable aggressive optimizations
        PerformanceMonitor.Flags.enableFrameSkipping = true
        PerformanceMonitor.Flags.maxNodesPerFrame = 500
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.info("Application will terminate")
        PerformanceMonitor.shared.logPerformanceStats()
    }
}
