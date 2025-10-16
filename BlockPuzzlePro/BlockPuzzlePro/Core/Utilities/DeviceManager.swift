import UIKit
import SwiftUI
import QuartzCore
import os.log

struct FrameRateInfo {
    let maxRefreshRate: Int
    let preferredRefreshRate: Int
}

enum FrameRateConfigurator {
    private static let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "FrameRate")
    @MainActor private static var monitor = FrameRateMonitor()

    @MainActor
    static func configurePreferredFrameRate() {
        logger.info("Starting frame rate monitor")
        monitor.start()
    }

    @MainActor
    static func currentDisplayInfo() -> FrameRateInfo {
        return FrameRateInfo(
            maxRefreshRate: monitor.maxRefreshRate,
            preferredRefreshRate: monitor.measuredRefreshRate
        )
    }

    @MainActor
    private final class FrameRateMonitor: NSObject {
        private(set) var measuredRefreshRate: Int
        private(set) var maxRefreshRate: Int

        private var displayLink: CADisplayLink?
        private var lastTimestamp: CFTimeInterval = 0
        private var samples: [Double] = []
        private let maxSamples = 12

        override init() {
            let detected = UIScreen.main.maximumFramesPerSecond
            let fallback = detected > 0 ? detected : 60
            self.maxRefreshRate = fallback
            self.measuredRefreshRate = fallback
        }

        @MainActor
        func start() {
            guard displayLink == nil else { return }

            let detected = UIScreen.main.maximumFramesPerSecond
            if detected > 0 {
                maxRefreshRate = detected
                measuredRefreshRate = detected
            }

            let link = CADisplayLink(target: self, selector: #selector(handleTick(_:)))

            if #available(iOS 15.0, *) {
                link.preferredFrameRateRange = CAFrameRateRange(
                    minimum: Float(maxRefreshRate),
                    maximum: Float(maxRefreshRate),
                    preferred: Float(maxRefreshRate)
                )
            } else {
                link.preferredFramesPerSecond = maxRefreshRate
            }

            link.add(to: .main, forMode: .common)
            displayLink = link
        }

        @objc private func handleTick(_ link: CADisplayLink) {
            let timestamp = link.timestamp

            if lastTimestamp == 0 {
                lastTimestamp = timestamp
                return
            }

            let delta = timestamp - lastTimestamp
            lastTimestamp = timestamp
            guard delta > 0 else { return }

            let instantaneousRate = min(Double(maxRefreshRate), 1.0 / delta)

            samples.append(instantaneousRate)
            if samples.count > maxSamples {
                samples.removeFirst()
            }

            let average = samples.reduce(0, +) / Double(samples.count)
            measuredRefreshRate = Int(round(average))
        }
    }
}

// MARK: - Device Type

/// Enumeration of supported device types
enum DeviceType {
    case iPhone
    case iPadMini
    case iPadRegular
    case iPadPro
    
    /// Current device type
    @MainActor static var current: DeviceType {
        let idiom = UIDevice.current.userInterfaceIdiom
        let screenSize = UIScreen.main.bounds.size
        let screenScale = UIScreen.main.scale
        
        switch idiom {
        case .phone:
            return .iPhone
        case .pad:
            let screenWidth = max(screenSize.width, screenSize.height) * screenScale
            if screenWidth < 2048 { // iPad Mini
                return .iPadMini
            } else if screenWidth < 2732 { // Regular iPad
                return .iPadRegular
            } else { // iPad Pro
                return .iPadPro
            }
        default:
            return .iPhone
        }
    }
}

// MARK: - Touch Configuration

/// Configuration for touch interactions based on device type
struct TouchConfiguration {
    let minimumTouchSize: CGFloat
    let dragThreshold: CGFloat
    let longPressMinimumDuration: TimeInterval
    let hapticFeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let animationDuration: TimeInterval
    
    /// Get configuration for current device
    @MainActor static var current: TouchConfiguration {
        switch DeviceType.current {
        case .iPhone:
            return TouchConfiguration(
                minimumTouchSize: 44.0,
                dragThreshold: 8.0,
                longPressMinimumDuration: 0.0,
                hapticFeedbackStyle: .light,
                animationDuration: 0.2
            )
        case .iPadMini:
            return TouchConfiguration(
                minimumTouchSize: 50.0,
                dragThreshold: 10.0,
                longPressMinimumDuration: 0.0,
                hapticFeedbackStyle: .medium,
                animationDuration: 0.25
            )
        case .iPadRegular, .iPadPro:
            return TouchConfiguration(
                minimumTouchSize: 56.0,
                dragThreshold: 12.0,
                longPressMinimumDuration: 0.0,
                hapticFeedbackStyle: .medium,
                animationDuration: 0.3
            )
        }
    }
}

// MARK: - Device Manager

/// Manages device-specific configurations and optimizations
final class DeviceManager: ObservableObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Current device type
    @Published private(set) var deviceType: DeviceType = .iPhone
    
    /// Current touch configuration
    @Published private(set) var touchConfig: TouchConfiguration = TouchConfiguration(
        minimumTouchSize: 44.0,
        dragThreshold: 8.0,
        longPressMinimumDuration: 0.0,
        hapticFeedbackStyle: .light,
        animationDuration: 0.2
    )
    
    /// Screen size information
    @Published private(set) var screenSize: CGSize = CGSize(width: 390, height: 844)
    
    /// Safe area insets
    @Published private(set) var safeAreaInsets: EdgeInsets = EdgeInsets()
    
    /// Whether device supports haptic feedback
    @Published private(set) var supportsHapticFeedback: Bool = true
    
    /// Preferred cell size for blocks based on device
    @Published private(set) var preferredCellSize: CGFloat = 30.0

    // Haptic feedback caches to avoid allocation cost during gameplay
    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private var hasRegisteredOrientationObserver = false
    
    // MARK: - Initialization
    
    init() {
        // Initialize with safe defaults for iPhone
        self.deviceType = .iPhone
        self.touchConfig = TouchConfiguration(
            minimumTouchSize: 44.0,
            dragThreshold: 8.0,
            longPressMinimumDuration: 0.0,
            hapticFeedbackStyle: .light,
            animationDuration: 0.2
        )
        self.screenSize = CGSize(width: 390, height: 844) // iPhone 14/15 Pro default
        self.safeAreaInsets = EdgeInsets()
        self.supportsHapticFeedback = true
        self.preferredCellSize = 30.0
        
        // Note: Actual device properties will be set via updateToCurrentDeviceAsync() 
        // when called from a MainActor context
    }
    
    /// Update to current device properties - call this from SwiftUI views or MainActor contexts
    @MainActor
    func updateToCurrentDeviceAsync() async {
        await updateToCurrentDevice()
    }
    
    @MainActor
    private func updateToCurrentDevice() async {
        self.deviceType = DeviceType.current
        self.touchConfig = TouchConfiguration.current
        self.screenSize = UIScreen.main.bounds.size
        self.safeAreaInsets = EdgeInsets()
        self.supportsHapticFeedback = UIDevice.current.hasHapticFeedback
        self.preferredCellSize = Self.calculatePreferredCellSize(for: DeviceType.current)
        
        self.setupDeviceObservation()
    }
    
    // MARK: - Device Optimization
    
    /// Calculate optimal cell size for current device
    @MainActor
    private static func calculatePreferredCellSize(for deviceType: DeviceType) -> CGFloat {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = min(screenSize.width, screenSize.height)
        
        switch deviceType {
        case .iPhone:
            // iPhone: Smaller cells for compact display
            return max(25.0, min(35.0, screenWidth / 12.0))
        case .iPadMini:
            // iPad Mini: Slightly larger cells
            return max(30.0, min(40.0, screenWidth / 15.0))
        case .iPadRegular:
            // Regular iPad: Medium cells
            return max(35.0, min(45.0, screenWidth / 18.0))
        case .iPadPro:
            // iPad Pro: Larger cells for better visibility
            return max(40.0, min(50.0, screenWidth / 20.0))
        }
    }
    
    /// Get optimal spacing for block tray based on device
    func getOptimalTraySpacing() -> CGFloat {
        switch deviceType {
        case .iPhone:
            return 16.0
        case .iPadMini:
            return 20.0
        case .iPadRegular, .iPadPro:
            return 24.0
        }
    }
    
    /// Get optimal drag animation parameters
    func getDragAnimationConfig() -> (duration: TimeInterval, dampingFraction: CGFloat) {
        switch deviceType {
        case .iPhone:
            return (duration: 0.2, dampingFraction: 0.8)
        case .iPadMini:
            return (duration: 0.25, dampingFraction: 0.75)
        case .iPadRegular, .iPadPro:
            return (duration: 0.3, dampingFraction: 0.7)
        }
    }
    
    /// Ideal drag update interval aligned with the device refresh rate
    @MainActor
    func idealDragUpdateInterval() -> TimeInterval {
        let displayInfo = FrameRateConfigurator.currentDisplayInfo()
        let preferred = displayInfo.preferredRefreshRate > 0 ? Double(displayInfo.preferredRefreshRate) : 0
        let maxRate = Double(displayInfo.maxRefreshRate)
        let refreshRate = preferred > 0 ? preferred : maxRate
        let resolvedRate = refreshRate > 0 ? refreshRate : 60.0
        return 1.0 / resolvedRate
    }

    /// Get optimal grid cell size for game board
    func getOptimalGridCellSize(for gridSize: Int = VisualConstants.Grid.defaultSize) -> CGFloat {
        let availableWidth = screenSize.width - (getOptimalTraySpacing() * 2)
        let cellsPerSide = CGFloat(gridSize)
        let cellSize = availableWidth / (cellsPerSide + 1) // Add some padding
        
        switch deviceType {
        case .iPhone:
            return max(25.0, min(35.0, cellSize))
        case .iPadMini:
            return max(30.0, min(40.0, cellSize))
        case .iPadRegular:
            return max(35.0, min(45.0, cellSize))
        case .iPadPro:
            return max(40.0, min(50.0, cellSize))
        }
    }
    
    // MARK: - Haptic Feedback
    
    /// Provide haptic feedback if supported, reusing cached generators to avoid jank
    func provideHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Intentionally left blank – gameplay haptics are coordinated elsewhere
        // to ensure they trigger only on successful placements.
    }

    /// Provide notification haptic feedback
    func provideNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        // No-op: placement-specific haptics are handled by FeedbackCoordinator.
    }
    
    // MARK: - Device Observation
    
    @MainActor
    private func setupDeviceObservation() {
        guard !hasRegisteredOrientationObserver else { return }
        hasRegisteredOrientationObserver = true
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.updateDeviceProperties()
            }
        }
    }
    
    @MainActor
    private func updateDeviceProperties() async {
        let newScreenSize = UIScreen.main.bounds.size
        if newScreenSize != screenSize {
            screenSize = newScreenSize
            preferredCellSize = Self.calculatePreferredCellSize(for: deviceType)
        }
    }
    
    // MARK: - Accessibility
    
    /// Check if accessibility features are enabled that affect touch
    var isAccessibilityEnabled: Bool {
        get async {
            await MainActor.run {
                return UIAccessibility.isVoiceOverRunning ||
                       UIAccessibility.isSwitchControlRunning ||
                       UIAccessibility.isAssistiveTouchRunning
            }
        }
    }
    
    /// Get accessibility-optimized touch configuration
    func accessibilityTouchConfig() async -> TouchConfiguration {
        var config = touchConfig
        
        if await isAccessibilityEnabled {
            // Increase touch targets for accessibility
            config = TouchConfiguration(
                minimumTouchSize: max(config.minimumTouchSize, 60.0),
                dragThreshold: max(config.dragThreshold, 15.0),
                longPressMinimumDuration: 0.5, // Longer for switch control
                hapticFeedbackStyle: .medium,
                animationDuration: config.animationDuration * 1.5
            )
        }
        
        return config
    }
}

// MARK: - UIDevice Extension

extension UIDevice {
    /// Check if device supports haptic feedback
    var hasHapticFeedback: Bool {
        // Haptic feedback is available on iPhone 7 and later, and some iPads
        switch userInterfaceIdiom {
        case .phone:
            return true // Most modern iPhones support haptic feedback
        case .pad:
            // Some iPads support haptic feedback, assume true for now
            return true
        default:
            return false
        }
    }
}

// MARK: - Environment Values

/// Environment key for device manager
private struct DeviceManagerKey: EnvironmentKey {
    static let defaultValue = DeviceManager()
}

extension EnvironmentValues {
    var deviceManager: DeviceManager {
        get { self[DeviceManagerKey.self] }
        set { self[DeviceManagerKey.self] = newValue }
    }
}

// MARK: - Debug Logging Helper

/// Lightweight debug logger that is compiled out of release builds.
@MainActor
enum DebugLog {
#if DEBUG
    private static var isEnabled = false

    static func enable() {
        isEnabled = true
    }

    static func disable() {
        isEnabled = false
    }

    static func trace(_ message: @autoclosure () -> String) {
        guard isEnabled else { return }
        print(message())
    }

    static var isLoggingEnabled: Bool {
        isEnabled
    }

    static func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
#else
    static func enable() {}
    static func disable() {}
    static func trace(_ message: @autoclosure () -> String) {}
    static var isLoggingEnabled: Bool { false }
    static func setEnabled(_ enabled: Bool) {}
#endif
}
