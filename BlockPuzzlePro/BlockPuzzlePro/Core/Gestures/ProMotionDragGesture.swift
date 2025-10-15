import SwiftUI
import UIKit

// MARK: - ProMotion-Optimized Drag Gesture
// Implementation using UIGestureRecognizerRepresentable (iOS 18+)
// Based on WWDC 2024 recommendations for precise gesture control at 120Hz

/// Gesture state for ProMotion drag operations
struct ProMotionDragGestureState: Equatable {
    var translation: CGSize = .zero
    var location: CGPoint = .zero
    var startLocation: CGPoint = .zero
    var isActive: Bool = false

    static let inactive = ProMotionDragGestureState()
}

/// UIGestureRecognizer wrapper for ProMotion-optimized drag gestures
@available(iOS 18.0, *)
struct ProMotionDragGesture: UIGestureRecognizerRepresentable {

    // MARK: - Properties

    /// Minimum distance before drag is recognized (in points)
    let minimumDistance: CGFloat

    /// Coordinate space for gesture tracking
    let coordinateSpace: CoordinateSpace

    // MARK: - Callbacks

    var onBegan: ((CGPoint, CGPoint) -> Void)?
    var onChanged: ((CGPoint, CGSize, CGPoint) -> Void)?
    var onEnded: ((CGPoint, CGSize, CGPoint) -> Void)?
    var onCancelled: (() -> Void)?

    // MARK: - Initialization

    init(minimumDistance: CGFloat = 1.0, coordinateSpace: CoordinateSpace = .global) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
    }

    // MARK: - UIGestureRecognizerRepresentable

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let recognizer = UIPanGestureRecognizer()

        // Configure for ProMotion optimization
        recognizer.maximumNumberOfTouches = 1
        recognizer.minimumNumberOfTouches = 1

        // iOS 18+: Enable high-frequency updates for ProMotion
        recognizer.allowedScrollTypesMask = []

        return recognizer
    }

    func updateUIGestureRecognizer(_ recognizer: UIPanGestureRecognizer, context: Context) {
        // Update context with latest callbacks
        context.coordinator.onBegan = onBegan
        context.coordinator.onChanged = onChanged
        context.coordinator.onEnded = onEnded
        context.coordinator.onCancelled = onCancelled
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPanGestureRecognizer, context: Context) {
        guard let view = recognizer.view else { return }

        // Get location in global coordinate space (screen coordinates)
        let location = recognizer.location(in: nil)
        let translationPoint = recognizer.translation(in: view)
        let translation = CGSize(width: translationPoint.x, height: translationPoint.y)

        switch recognizer.state {
        case .began:
            context.coordinator.handleBegan(location: location, in: view)

        case .changed:
            context.coordinator.handleChanged(location: location, translation: translation, in: view)

        case .ended:
            context.coordinator.handleEnded(location: location, translation: translation, in: view)

        case .cancelled, .failed:
            context.coordinator.handleCancelled()

        default:
            break
        }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator {
        var startLocation: CGPoint = .zero
        var hasStarted: Bool = false

        var onBegan: ((CGPoint, CGPoint) -> Void)?
        var onChanged: ((CGPoint, CGSize, CGPoint) -> Void)?
        var onEnded: ((CGPoint, CGSize, CGPoint) -> Void)?
        var onCancelled: (() -> Void)?

        func handleBegan(location: CGPoint, in view: UIView) {
            startLocation = location
            hasStarted = true
            onBegan?(location, startLocation)
        }

        func handleChanged(location: CGPoint, translation: CGSize, in view: UIView) {
            guard hasStarted else { return }
            onChanged?(location, translation, startLocation)
        }

        func handleEnded(location: CGPoint, translation: CGSize, in view: UIView) {
            guard hasStarted else { return }
            onEnded?(location, translation, startLocation)
            reset()
        }

        func handleCancelled() {
            guard hasStarted else { return }
            onCancelled?()
            reset()
        }

        func reset() {
            hasStarted = false
            startLocation = .zero
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply ProMotion-optimized drag gesture (iOS 18+)
    @available(iOS 18.0, *)
    func proMotionDrag(
        minimumDistance: CGFloat = 1.0,
        coordinateSpace: CoordinateSpace = .global,
        onBegan: @escaping (CGPoint, CGPoint) -> Void,
        onChanged: @escaping (CGPoint, CGSize, CGPoint) -> Void,
        onEnded: @escaping (CGPoint, CGSize, CGPoint) -> Void,
        onCancelled: @escaping () -> Void = {}
    ) -> some View {
        self.gesture(
            ProMotionDragGesture(minimumDistance: minimumDistance, coordinateSpace: coordinateSpace)
                .onBegan(onBegan)
                .onChanged(onChanged)
                .onEnded(onEnded)
                .onCancelled(onCancelled)
        )
    }
}

// MARK: - Gesture Modifier Extensions

@available(iOS 18.0, *)
extension ProMotionDragGesture {
    func onBegan(_ action: @escaping (CGPoint, CGPoint) -> Void) -> ProMotionDragGesture {
        var gesture = self
        gesture.onBegan = action
        return gesture
    }

    func onChanged(_ action: @escaping (CGPoint, CGSize, CGPoint) -> Void) -> ProMotionDragGesture {
        var gesture = self
        gesture.onChanged = action
        return gesture
    }

    func onEnded(_ action: @escaping (CGPoint, CGSize, CGPoint) -> Void) -> ProMotionDragGesture {
        var gesture = self
        gesture.onEnded = action
        return gesture
    }

    func onCancelled(_ action: @escaping () -> Void) -> ProMotionDragGesture {
        var gesture = self
        gesture.onCancelled = action
        return gesture
    }
}

// MARK: - Fallback for iOS 17 and below

/// Fallback drag gesture for iOS 17 and below (uses standard SwiftUI DragGesture)
struct FallbackDragGesture {
    let minimumDistance: CGFloat
    let coordinateSpace: CoordinateSpace

    var onBegan: (@Sendable @MainActor (CGPoint, CGPoint) -> Void)?
    var onChanged: (@Sendable @MainActor (CGPoint, CGSize, CGPoint) -> Void)?
    var onEnded: (@Sendable @MainActor (CGPoint, CGSize, CGPoint) -> Void)?
    var onCancelled: (@Sendable @MainActor () -> Void)?

    init(minimumDistance: CGFloat = 1.0, coordinateSpace: CoordinateSpace = .global) {
        self.minimumDistance = minimumDistance
        self.coordinateSpace = coordinateSpace
    }

    @MainActor
    var gesture: some Gesture {
        DragGesture(minimumDistance: minimumDistance, coordinateSpace: coordinateSpace)
            .onChanged { @MainActor value in
                onChanged?(value.location, value.translation, value.startLocation)
            }
            .onEnded { @MainActor value in
                onEnded?(value.location, value.translation, value.startLocation)
            }
    }
}

extension FallbackDragGesture {
    func onBegan(_ action: @escaping @Sendable @MainActor (CGPoint, CGPoint) -> Void) -> FallbackDragGesture {
        var gesture = self
        gesture.onBegan = action
        return gesture
    }

    func onChanged(_ action: @escaping @Sendable @MainActor (CGPoint, CGSize, CGPoint) -> Void) -> FallbackDragGesture {
        var gesture = self
        gesture.onChanged = action
        return gesture
    }

    func onEnded(_ action: @escaping @Sendable @MainActor (CGPoint, CGSize, CGPoint) -> Void) -> FallbackDragGesture {
        var gesture = self
        gesture.onEnded = action
        return gesture
    }

    func onCancelled(_ action: @escaping @Sendable @MainActor () -> Void) -> FallbackDragGesture {
        var gesture = self
        gesture.onCancelled = action
        return gesture
    }
}
