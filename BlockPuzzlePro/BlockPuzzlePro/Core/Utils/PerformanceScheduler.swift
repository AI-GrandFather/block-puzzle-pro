import SwiftUI

/// High-performance timeline schedulers optimized for 120Hz ProMotion
struct PerformanceScheduler {

    // MARK: - 120Hz Animation Scheduler

    /// Maximum refresh rate scheduler for ProMotion displays
    static let promotionAnimation = PeriodicTimelineSchedule(from: .now, by: 1.0 / 120.0)

    /// High refresh rate scheduler for smooth animations
    static let highRefresh = PeriodicTimelineSchedule(from: .now, by: 1.0 / 90.0)

    /// Standard refresh rate scheduler for normal animations
    static let standard = PeriodicTimelineSchedule(from: .now, by: 1.0 / 60.0)

    /// Power-efficient scheduler for background updates
    static let efficient = PeriodicTimelineSchedule(from: .now, by: 1.0 / 30.0)

    // MARK: - Adaptive Scheduler

    /// Adaptive scheduler that adjusts based on device capabilities
    static func adaptive(for context: AnimationContext = .standard) -> any TimelineSchedule {
        if #available(iOS 15.0, *) {
            // Check for ProMotion support
            if UIScreen.main.maximumFramesPerSecond >= 120 {
                switch context {
                case .gaming:
                    return promotionAnimation
                case .animation:
                    return highRefresh
                case .standard:
                    return standard
                case .background:
                    return efficient
                }
            }
        }

        // Fallback for non-ProMotion devices
        switch context {
        case .gaming, .animation:
            return standard
        case .standard:
            return standard
        case .background:
            return efficient
        }
    }

    // MARK: - Context Types

    enum AnimationContext {
        case gaming     // 120Hz for game loops
        case animation  // 90Hz for UI animations
        case standard   // 60Hz for normal UI
        case background // 30Hz for background updates
    }
}

// MARK: - Performance Timeline View

struct PerformanceTimelineView<Content: View>: View {
    let schedule: any TimelineSchedule
    let content: (TimelineViewDefaultContext) -> Content

    init(
        _ schedule: any TimelineSchedule,
        @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content
    ) {
        self.schedule = schedule
        self.content = content
    }

    var body: some View {
        TimelineView(schedule) { context in
            content(context)
        }
    }
}

// MARK: - Optimized Animation Modifiers

extension View {
    /// Apply high-performance animation with ProMotion support
    func highPerformanceAnimation<V: Equatable>(
        _ animation: Animation? = .default,
        value: V,
        context: PerformanceScheduler.AnimationContext = .animation
    ) -> some View {
        self.animation(animation, value: value)
    }

    /// Apply spring animation optimized for ProMotion
    func promotionSpring<V: Equatable>(
        response: Double = 0.4,
        dampingFraction: Double = 0.7,
        blendDuration: Double = 0,
        value: V
    ) -> some View {
        self.animation(
            .spring(
                response: response / 2.0, // Halve response for 120Hz
                dampingFraction: dampingFraction,
                blendDuration: blendDuration
            ),
            value: value
        )
    }

    /// Apply easing animation optimized for high refresh rates
    func promotionEasing<V: Equatable>(
        duration: Double = 0.25,
        value: V
    ) -> some View {
        self.animation(
            .easeInOut(duration: duration * 0.8), // Reduce duration for 120Hz
            value: value
        )
    }
}