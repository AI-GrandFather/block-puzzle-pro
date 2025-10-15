// ProMotionManager.swift
// Adaptive frame rate management for ProMotion displays
// Supports 120fps on iPhone 15/16/17 Pro and iPad Pro

import Foundation
import UIKit
import Observation

// MARK: - Display Capabilities

struct DisplayCapabilities {
    let maximumFramesPerSecond: Int
    let supportsProMotion: Bool
    let preferredFramesPerSecond: Int

    nonisolated(unsafe) static var current: DisplayCapabilities {
        let maxFPS = MainActor.assumeIsolated {
            UIScreen.main.maximumFramesPerSecond
        }
        return DisplayCapabilities(
            maximumFramesPerSecond: maxFPS,
            supportsProMotion: maxFPS > 60,
            preferredFramesPerSecond: maxFPS
        )
    }
}

// MARK: - Frame Rate Mode

enum FrameRateMode: String, CaseIterable {
    case adaptive = "Adaptive" // Auto-adjust based on performance
    case maximum = "Maximum"   // Always use maximum available
    case standard = "Standard" // 60fps
    case batterySaver = "Battery Saver" // 30fps

    var targetFPS: Int {
        switch self {
        case .adaptive, .maximum:
            return DisplayCapabilities.current.maximumFramesPerSecond
        case .standard:
            return 60
        case .batterySaver:
            return 30
        }
    }

    var displayName: String {
        switch self {
        case .adaptive:
            let caps = DisplayCapabilities.current
            return caps.supportsProMotion ? "Adaptive (Up to 120fps)" : "Adaptive (60fps)"
        case .maximum:
            let caps = DisplayCapabilities.current
            return caps.supportsProMotion ? "Maximum (120fps)" : "Maximum (60fps)"
        case .standard:
            return "Standard (60fps)"
        case .batterySaver:
            return "Battery Saver (30fps)"
        }
    }
}

// MARK: - ProMotion Manager

@Observable
final class ProMotionManager {

    // MARK: - Singleton

    nonisolated(unsafe) static let shared = ProMotionManager()

    // MARK: - Properties

    var frameRateMode: FrameRateMode {
        didSet {
            saveFrameRateMode()
            updateTargetFrameRate()
        }
    }

    private(set) var currentFPS: Int = 60
    private(set) var targetFPS: Int = 60
    private(set) var actualFPS: Double = 60.0
    private(set) var displayCapabilities: DisplayCapabilities

    // Performance monitoring
    private var frameCount: Int = 0
    private var lastFPSUpdate: Date = Date()
    private var frameTimes: [TimeInterval] = []
    private let maxFrameTimeSamples = 60

    // Auto-adjustment for adaptive mode
    private var performanceScore: Double = 1.0
    private let minPerformanceScore: Double = 0.8

    // User defaults
    private let defaults = UserDefaults.standard
    private let frameRateModeKey = "frame_rate_mode"

    // MARK: - Initialization

    private init() {
        let capabilities = DisplayCapabilities.current
        self.displayCapabilities = capabilities

        // Load saved frame rate mode
        if let savedMode = defaults.string(forKey: frameRateModeKey),
           let mode = FrameRateMode(rawValue: savedMode) {
            self.frameRateMode = mode
        } else {
            // Default to adaptive if ProMotion supported, otherwise standard
            self.frameRateMode = capabilities.supportsProMotion ? .adaptive : .standard
        }

        defer { updateTargetFrameRate() }

        // Listen for low power mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerStateChanged),
            name: Notification.Name.NSProcessInfoPowerStateDidChange,
            object: nil
        )
    }

    // MARK: - Frame Rate Management

    private func updateTargetFrameRate() {
        switch frameRateMode {
        case .adaptive:
            targetFPS = displayCapabilities.maximumFramesPerSecond
            // Will be adjusted based on performance
        case .maximum:
            targetFPS = displayCapabilities.maximumFramesPerSecond
        case .standard:
            targetFPS = 60
        case .batterySaver:
            targetFPS = 30
        }

        // Auto-reduce if low power mode is on
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            targetFPS = min(targetFPS, 60)
        }

        currentFPS = targetFPS
    }

    /// Record a frame for FPS calculation
    func recordFrame(timestamp: TimeInterval) {
        frameCount += 1
        frameTimes.append(timestamp)

        // Keep only recent samples
        if frameTimes.count > maxFrameTimeSamples {
            frameTimes.removeFirst()
        }

        let now = Date()
        let timeSinceLastUpdate = now.timeIntervalSince(lastFPSUpdate)

        // Update FPS calculation every second
        if timeSinceLastUpdate >= 1.0 {
            calculateActualFPS(timeSinceLastUpdate: timeSinceLastUpdate)
            lastFPSUpdate = now
            frameCount = 0

            // Adaptive adjustment
            if frameRateMode == .adaptive {
                adjustFrameRateAdaptively()
            }
        }
    }

    private func calculateActualFPS(timeSinceLastUpdate: TimeInterval) {
        actualFPS = Double(frameCount) / timeSinceLastUpdate

        // Calculate performance score (0.0 to 1.0)
        performanceScore = actualFPS / Double(targetFPS)
    }

    private func adjustFrameRateAdaptively() {
        guard frameRateMode == .adaptive else { return }

        // If performance is poor, reduce target frame rate
        if performanceScore < minPerformanceScore {
            if currentFPS > 60 {
                currentFPS = 60
                print("📊 ProMotion: Reducing to 60fps due to performance")
            } else if currentFPS > 30 {
                currentFPS = 30
                print("📊 ProMotion: Reducing to 30fps due to performance")
            }
        }
        // If performance is good and below maximum, try increasing
        else if performanceScore > 0.95 && currentFPS < targetFPS {
            currentFPS = min(currentFPS * 2, targetFPS)
            print("📊 ProMotion: Increasing to \(currentFPS)fps")
        }
    }

    @objc private func powerStateChanged() {
        updateTargetFrameRate()
        print("📊 ProMotion: Power state changed, target FPS: \(targetFPS)")
    }

    // MARK: - Persistence

    private func saveFrameRateMode() {
        defaults.set(frameRateMode.rawValue, forKey: frameRateModeKey)
    }

    // MARK: - Public API

    /// Get the preferred frames per second for CADisplayLink
    var preferredFramesPerSecond: Int {
        currentFPS
    }

    /// Get delta time for frame-rate independent animations
    var deltaTime: TimeInterval {
        1.0 / Double(currentFPS)
    }

    /// Check if display supports ProMotion
    var isProMotionAvailable: Bool {
        displayCapabilities.supportsProMotion
    }

    /// Get human-readable performance info
    var performanceInfo: String {
        """
        Display: \(displayCapabilities.maximumFramesPerSecond)fps max
        Mode: \(frameRateMode.displayName)
        Target: \(targetFPS)fps
        Actual: \(String(format: "%.1f", actualFPS))fps
        Performance: \(String(format: "%.0f", performanceScore * 100))%
        """
    }

    /// Get frame time statistics
    var frameTimeStats: (avg: TimeInterval, min: TimeInterval, max: TimeInterval)? {
        guard !frameTimes.isEmpty else { return nil }

        let avg = frameTimes.reduce(0, +) / Double(frameTimes.count)
        let min = frameTimes.min() ?? 0
        let max = frameTimes.max() ?? 0

        return (avg, min, max)
    }

    /// Reset performance metrics
    func resetMetrics() {
        frameCount = 0
        frameTimes.removeAll()
        performanceScore = 1.0
        lastFPSUpdate = Date()
    }
}

// MARK: - CADisplayLink Helper

extension CADisplayLink {
    /// Configure CADisplayLink with ProMotion settings
    static func createOptimized(target: Any, selector: Selector) -> CADisplayLink {
        let displayLink = CADisplayLink(target: target, selector: selector)

        if #available(iOS 15.0, *) {
            let preferredFPS = ProMotionManager.shared.preferredFramesPerSecond
            displayLink.preferredFrameRateRange = CAFrameRateRange(
                minimum: Float(preferredFPS / 2),
                maximum: Float(preferredFPS),
                preferred: Float(preferredFPS)
            )
        } else {
            displayLink.preferredFramesPerSecond = ProMotionManager.shared.preferredFramesPerSecond
        }

        return displayLink
    }
}

// MARK: - Performance Monitoring View

#if DEBUG
import SwiftUI

struct PerformanceMonitorView: View {
    @State private var proMotion = ProMotionManager.shared
    @State private var updateTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Performance Monitor")
                .font(.headline)

            Text(proMotion.performanceInfo)
                .font(.caption.monospaced())

            Picker("Frame Rate Mode", selection: $proMotion.frameRateMode) {
                ForEach(FrameRateMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                MainActor.assumeIsolated {
                    ProMotionManager.shared.recordFrame(timestamp: Date().timeIntervalSince1970)
                }
            }
        }
        .onDisappear {
            updateTimer?.invalidate()
        }
    }
}
#endif
