import UIKit
import SwiftUI
import Combine

/// High-performance animator using CADisplayLink for 120Hz ProMotion support
final class DisplayLinkAnimator: ObservableObject {

    // MARK: - Properties

    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0

    @Published var deltaTime: TimeInterval = 0
    @Published var frameRate: Double = 0
    @Published var isRunning: Bool = false

    // Performance tracking
    private var frameCount: Int = 0
    private var performanceStartTime: CFTimeInterval = 0

    // MARK: - Callbacks

    var onFrame: ((TimeInterval) -> Void)?

    // MARK: - Lifecycle

    init() {
        setupDisplayLink()
    }

    deinit {
        stop()
    }

    // MARK: - Setup

    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))

        // Enable ProMotion 120Hz support
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(
                minimum: 80,    // Minimum 80fps for smooth experience
                maximum: 120,   // Maximum 120fps for ProMotion
                preferred: 120  // Prefer 120fps when possible
            )
        } else {
            displayLink?.preferredFramesPerSecond = 120
        }
    }

    // MARK: - Control

    func start() {
        guard !isRunning else { return }

        displayLink?.add(to: .main, forMode: .common)
        isRunning = true
        lastFrameTime = CACurrentMediaTime()
        performanceStartTime = lastFrameTime
        frameCount = 0

        print("🎮 DisplayLinkAnimator: Started with ProMotion support")
    }

    func stop() {
        guard isRunning else { return }

        displayLink?.invalidate()
        displayLink?.remove(from: .main, forMode: .common)
        isRunning = false

        print("🎮 DisplayLinkAnimator: Stopped")
    }

    func pause() {
        displayLink?.isPaused = true
    }

    func resume() {
        displayLink?.isPaused = false
        lastFrameTime = CACurrentMediaTime()
    }

    // MARK: - Frame Update

    @objc private func frameUpdate() {
        let currentTime = CACurrentMediaTime()
        deltaTime = currentTime - lastFrameTime
        lastFrameTime = currentTime

        // Update frame rate calculation
        frameCount += 1
        let elapsed = currentTime - performanceStartTime
        if elapsed >= 1.0 {
            frameRate = Double(frameCount) / elapsed
            frameCount = 0
            performanceStartTime = currentTime
        }

        // Call frame callback
        onFrame?(deltaTime)
    }

    // MARK: - Performance Monitoring

    var isRunningAt120Hz: Bool {
        return frameRate > 100 // Consider 100+ fps as 120Hz
    }

    var performanceStatus: String {
        if frameRate > 100 {
            return "🟢 ProMotion Active (\(Int(frameRate))fps)"
        } else if frameRate > 55 {
            return "🟡 Standard Rate (\(Int(frameRate))fps)"
        } else {
            return "🔴 Low Performance (\(Int(frameRate))fps)"
        }
    }
}

// MARK: - SwiftUI Integration

struct HighPerformanceAnimationView<Content: View>: View {
    @StateObject private var animator = DisplayLinkAnimator()
    let content: (TimeInterval, Double) -> Content

    init(@ViewBuilder content: @escaping (TimeInterval, Double) -> Content) {
        self.content = content
    }

    var body: some View {
        content(animator.deltaTime, animator.frameRate)
            .onAppear {
                animator.start()
            }
            .onDisappear {
                animator.stop()
            }
    }
}