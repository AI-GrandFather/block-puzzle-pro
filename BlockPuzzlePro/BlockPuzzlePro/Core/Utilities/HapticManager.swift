import UIKit
import CoreHaptics
import os.log

// MARK: - Haptic Intensity Level

/// User-configurable haptic intensity
enum HapticIntensity: String, Codable, CaseIterable {
    case light = "Light"
    case medium = "Medium"
    case strong = "Strong"

    var multiplier: Float {
        switch self {
        case .light: return 0.7
        case .medium: return 1.0
        case .strong: return 1.3
        }
    }
}

// MARK: - Haptic Event Types

/// Game-specific haptic events
enum HapticEvent {
    case piecePickup
    case piecePlacement
    case invalidPlacement
    case lineClear(count: Int)
    case combo(level: Int)
    case perfectClear
    case holdSwap
    case powerUpActivation
    case levelUp
    case gameOver
}

// MARK: - Enhanced Haptics Manager

/// Comprehensive haptics manager with Core Haptics support
@MainActor
final class HapticManager: ObservableObject {

    // MARK: - Properties

    /// Whether haptics are enabled
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "haptics_enabled")
            if !isEnabled {
                stopAllHaptics()
            }
        }
    }

    /// Haptic intensity level
    @Published var intensity: HapticIntensity {
        didSet {
            UserDefaults.standard.set(intensity.rawValue, forKey: "haptic_intensity")
        }
    }

    /// Reduced haptics mode (accessibility)
    @Published var reduceHaptics: Bool {
        didSet {
            UserDefaults.standard.set(reduceHaptics, forKey: "reduce_haptics")
        }
    }

    // MARK: - Private Properties

    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    private var notificationGenerator: UINotificationFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?

    // Core Haptics (iPhone 8+)
    private var hapticEngine: CHHapticEngine?
    private let supportsHaptics: Bool

    private let logger = Logger(subsystem: "com.blockpuzzlepro", category: "HapticManager")

    // MARK: - Initialization

    init() {
        // Load settings
        isEnabled = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
        reduceHaptics = UserDefaults.standard.object(forKey: "reduce_haptics") as? Bool ?? false

        if let intensityString = UserDefaults.standard.string(forKey: "haptic_intensity"),
           let savedIntensity = HapticIntensity(rawValue: intensityString) {
            intensity = savedIntensity
        } else {
            intensity = .medium
        }

        // Check device capabilities
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

        if supportsHaptics {
            setupCoreHaptics()
        }

        // Prepare basic generators
        prepareGenerators()

        logger.info("HapticManager initialized (Core Haptics: \(self.supportsHaptics), Enabled: \(self.isEnabled))")
    }

    // MARK: - Setup

    private func setupCoreHaptics() {
        do {
            hapticEngine = try CHHapticEngine()

            // Start engine
            try hapticEngine?.start()

            // Handle engine stopped
            hapticEngine?.stoppedHandler = { [weak self] reason in
                self?.logger.warning("Haptic engine stopped: \(reason.rawValue)")
            }

            // Handle engine reset
            hapticEngine?.resetHandler = { [weak self] in
                self?.logger.info("Haptic engine reset")
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    self?.logger.error("Failed to restart haptic engine: \(error.localizedDescription)")
                }
            }

            logger.info("Core Haptics engine initialized")
        } catch {
            logger.error("Failed to setup Core Haptics: \(error.localizedDescription)")
        }
    }

    private func prepareGenerators() {
        // Prepare commonly used generators
        _ = getImpactGenerator(.soft)
        _ = getImpactGenerator(.medium)
        _ = getImpactGenerator(.heavy)

        notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator?.prepare()

        selectionGenerator = UISelectionFeedbackGenerator()
        selectionGenerator?.prepare()
    }

    // MARK: - Public API

    /// Trigger haptic for game event
    func trigger(_ event: HapticEvent) {
        guard isEnabled && !isLowPowerMode() else { return }

        Task {
            await triggerEventHaptic(event)
        }
    }

    /// Low-level impact haptic
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isEnabled && !isLowPowerMode() else { return }

        let adjustedIntensity = min(1.0, intensity * CGFloat(self.intensity.multiplier))
        let generator = getImpactGenerator(style)
        generator.impactOccurred(intensity: adjustedIntensity)
        generator.prepare()
    }

    /// Low-level notification haptic
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled && !isLowPowerMode() else { return }
        guard !reduceHaptics || type != .error else { return }

        notificationGenerator?.notificationOccurred(type)
        notificationGenerator?.prepare()
    }

    /// Selection changed haptic
    func selectionChanged() {
        guard isEnabled && !isLowPowerMode() && !reduceHaptics else { return }

        selectionGenerator?.selectionChanged()
        selectionGenerator?.prepare()
    }

    // MARK: - Event-Specific Haptics

    private func triggerEventHaptic(_ event: HapticEvent) async {
        switch event {
        case .piecePickup:
            await piecePickupHaptic()

        case .piecePlacement:
            await piecePlacementHaptic()

        case .invalidPlacement:
            await invalidPlacementHaptic()

        case .lineClear(let count):
            await lineClearHaptic(count: count)

        case .combo(let level):
            await comboHaptic(level: level)

        case .perfectClear:
            await perfectClearHaptic()

        case .holdSwap:
            await holdSwapHaptic()

        case .powerUpActivation:
            await powerUpActivationHaptic()

        case .levelUp:
            await levelUpHaptic()

        case .gameOver:
            await gameOverHaptic()
        }
    }

    // MARK: - Haptic Patterns

    private func piecePickupHaptic() async {
        impact(style: .soft, intensity: 0.6)
    }

    private func piecePlacementHaptic() async {
        impact(style: .soft, intensity: 0.45)
    }

    private func invalidPlacementHaptic() async {
        guard !reduceHaptics else { return }
        notification(type: .error)
    }

    private func lineClearHaptic(count: Int) async {
        switch count {
        case 1:
            impact(style: .light, intensity: 0.5)

        case 2:
            impact(style: .medium, intensity: 0.8)

        case 3...:
            impact(style: .heavy, intensity: 1.0)

        default:
            break
        }
    }

    private func comboHaptic(level: Int) async {
        if supportsHaptics, let engine = hapticEngine {
            await playComboPattern(level: level, using: engine)
        } else {
            await playComboPatternFallback(level: level)
        }
    }

    private func playComboPattern(level: Int, using engine: CHHapticEngine) async {
        var events: [CHHapticEvent] = []

        let baseIntensity = min(1.0, 0.5 + (Float(level) * 0.05))
        let baseSharpness = min(1.0, 0.3 + (Float(level) * 0.07))
        let adjustedIntensity = baseIntensity * intensity.multiplier

        // Create pattern based on combo level
        switch level {
        case 2:
            // Double tap
            events = [
                createHapticEvent(intensity: adjustedIntensity, sharpness: baseSharpness, time: 0.0),
                createHapticEvent(intensity: adjustedIntensity, sharpness: baseSharpness, time: 0.1)
            ]

        case 5:
            // tap-pause-tap-tap
            events = [
                createHapticEvent(intensity: adjustedIntensity * 0.9, sharpness: baseSharpness, time: 0.0),
                createHapticEvent(intensity: adjustedIntensity, sharpness: baseSharpness, time: 0.15),
                createHapticEvent(intensity: adjustedIntensity, sharpness: baseSharpness, time: 0.25)
            ]

        case 10...:
            // Rapid sequence
            for i in 0..<4 {
                events.append(createHapticEvent(
                    intensity: adjustedIntensity * 0.95,
                    sharpness: baseSharpness * 1.2,
                    time: TimeInterval(i) * 0.08
                ))
            }

        default:
            // Simple impact for other levels
            events = [createHapticEvent(intensity: adjustedIntensity, sharpness: baseSharpness, time: 0.0)]
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            logger.error("Failed to play combo haptic: \(error.localizedDescription)")
        }
    }

    private func playComboPatternFallback(level: Int) async {
        let generator = getImpactGenerator(.medium)
        let baseIntensity = CGFloat(min(1.0, 0.6 + (Float(level) * 0.03))) * CGFloat(intensity.multiplier)

        switch level {
        case 2:
            generator.impactOccurred(intensity: baseIntensity)
            try? await Task.sleep(nanoseconds: 100_000_000)
            generator.impactOccurred(intensity: baseIntensity)

        case 5:
            generator.impactOccurred(intensity: baseIntensity * 0.9)
            try? await Task.sleep(nanoseconds: 150_000_000)
            generator.impactOccurred(intensity: baseIntensity)
            try? await Task.sleep(nanoseconds: 100_000_000)
            generator.impactOccurred(intensity: baseIntensity)

        case 10...:
            let rigidGen = getImpactGenerator(.rigid)
            for _ in 0..<4 {
                rigidGen.impactOccurred(intensity: baseIntensity * 0.95)
                try? await Task.sleep(nanoseconds: 80_000_000)
            }

        default:
            generator.impactOccurred(intensity: baseIntensity)
        }

        generator.prepare()
    }

    private func perfectClearHaptic() async {
        notification(type: .success)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let generator = getImpactGenerator(.light)
        let pattern: [TimeInterval] = [0.0, 0.15, 0.25, 0.5]

        for delay in pattern {
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            generator.impactOccurred(intensity: 0.7 * CGFloat(intensity.multiplier))
        }

        generator.prepare()
    }

    private func holdSwapHaptic() async {
        impact(style: .light, intensity: 0.5)
    }

    private func powerUpActivationHaptic() async {
        impact(style: .medium, intensity: 0.8)
        try? await Task.sleep(nanoseconds: 50_000_000)
        notification(type: .success)
    }

    private func levelUpHaptic() async {
        notification(type: .success)

        try? await Task.sleep(nanoseconds: 50_000_000)

        let generator = getImpactGenerator(.medium)
        for i in 0..<3 {
            let intensityValue = (0.6 + (Double(i) * 0.15)) * Double(intensity.multiplier)
            generator.impactOccurred(intensity: min(1.0, intensityValue))
            try? await Task.sleep(nanoseconds: 120_000_000)
        }

        generator.prepare()
    }

    private func gameOverHaptic() async {
        guard !reduceHaptics else { return }

        notification(type: .warning)

        try? await Task.sleep(nanoseconds: 100_000_000)

        let generator = getImpactGenerator(.soft)
        for i in 0..<3 {
            let intensityValue = (0.7 - (Double(i) * 0.2)) * Double(intensity.multiplier)
            generator.impactOccurred(intensity: max(0.3, intensityValue))
            try? await Task.sleep(nanoseconds: 150_000_000)
        }

        generator.prepare()
    }

    // MARK: - Helpers

    private func createHapticEvent(intensity: Float, sharpness: Float, time: TimeInterval) -> CHHapticEvent {
        return CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1.0, intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: min(1.0, sharpness))
            ],
            relativeTime: time
        )
    }

    private func getImpactGenerator(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        if let cached = impactGenerators[style] {
            return cached
        }

        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        impactGenerators[style] = generator
        return generator
    }

    private func isLowPowerMode() -> Bool {
        return ProcessInfo.processInfo.isLowPowerModeEnabled
    }

    // MARK: - Cleanup

    func stopAllHaptics() {
        hapticEngine?.stop()
    }

    func reset() {
        impactGenerators.removeAll()
        notificationGenerator = nil
        selectionGenerator = nil
        prepareGenerators()
    }
}
