import UIKit

@MainActor
final class HapticManager {
    // Cache impact generators by style to avoid allocation jank
    private var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]
    // Single notification generator reused
    private var notificationGenerator: UINotificationFeedbackGenerator?

    init() {}

    /// Provide impact haptic feedback for the given style.
    /// Uses cached generators and re-prepares to minimize latency.
    func provideHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) async {
        let generator: UIImpactFeedbackGenerator
        if let cached = impactGenerators[style] {
            generator = cached
        } else {
            let newGen = UIImpactFeedbackGenerator(style: style)
            newGen.prepare()
            impactGenerators[style] = newGen
            generator = newGen
        }

        generator.impactOccurred()
        // Prepare again for subsequent events
        generator.prepare()
    }

    /// Provide notification haptic feedback of the given type.
    /// Uses a single cached generator and re-prepares to minimize latency.
    func provideNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) async {
        let generator: UINotificationFeedbackGenerator
        if let cached = notificationGenerator {
            generator = cached
        } else {
            let newGen = UINotificationFeedbackGenerator()
            newGen.prepare()
            notificationGenerator = newGen
            generator = newGen
        }

        generator.notificationOccurred(type)
        // Prepare again for subsequent events
        generator.prepare()
    }

    /// Clear cached generators, e.g., on memory warnings.
    func reset() {
        impactGenerators.removeAll()
        notificationGenerator = nil
    }
}
