import SwiftUI
import Combine

// MARK: - Animation Type

/// Types of placement animations
enum PlacementAnimationType {
    case snapToGrid
    case placementComplete
    case invalidReturn
    case lineComplete
    case blockAppear
}

// MARK: - Animation Configuration

/// Configuration for placement animations
struct AnimationConfiguration {
    let duration: TimeInterval
    let delay: TimeInterval
    let springResponse: Double
    let springDamping: Double
    let curve: Animation
    
    static func forType(_ type: PlacementAnimationType, deviceType: DeviceType) -> AnimationConfiguration {
        switch type {
        case .snapToGrid:
            return AnimationConfiguration(
                duration: deviceType == .iPhone ? 0.25 : 0.3,
                delay: 0.0,
                springResponse: 0.5,
                springDamping: 0.7,
                curve: .spring(response: 0.5, dampingFraction: 0.7)
            )
        case .placementComplete:
            return AnimationConfiguration(
                duration: 0.4,
                delay: 0.1,
                springResponse: 0.3,
                springDamping: 0.6,
                curve: .spring(response: 0.3, dampingFraction: 0.6)
            )
        case .invalidReturn:
            return AnimationConfiguration(
                duration: 0.4,
                delay: 0.0,
                springResponse: 0.4,
                springDamping: 0.8,
                curve: .spring(response: 0.4, dampingFraction: 0.8)
            )
        case .lineComplete:
            return AnimationConfiguration(
                duration: 0.6,
                delay: 0.2,
                springResponse: 0.3,
                springDamping: 0.5,
                curve: .spring(response: 0.3, dampingFraction: 0.5)
            )
        case .blockAppear:
            return AnimationConfiguration(
                duration: 0.3,
                delay: 0.0,
                springResponse: 0.4,
                springDamping: 0.7,
                curve: .spring(response: 0.4, dampingFraction: 0.7)
            )
        }
    }
}

// MARK: - Placement Animator

/// Manages all placement-related animations
@MainActor
class PlacementAnimator: ObservableObject {
    
    // MARK: - Properties
    
    /// Device manager for device-specific animations
    private let deviceManager: DeviceManager
    
    /// Current animation states
    @Published var isAnimatingSnap: Bool = false
    @Published var isAnimatingPlacement: Bool = false
    @Published var isAnimatingReturn: Bool = false
    @Published var isAnimatingLineComplete: Bool = false
    
    /// Animation progress values
    @Published var snapProgress: CGFloat = 0.0
    @Published var placementProgress: CGFloat = 0.0
    @Published var completionScale: CGFloat = 1.0
    @Published var completionRotation: Double = 0.0
    @Published var glowOpacity: Double = 0.0
    
    /// Animation completion callbacks
    private var completionCallbacks: [String: () -> Void] = [:]
    private var animationCancellables: Set<AnyCancellable> = []
    
    // MARK: - Initialization
    
    init(deviceManager: DeviceManager = DeviceManager()) {
        self.deviceManager = deviceManager
    }
    
    // MARK: - Snap Animation
    
    /// Animate block snapping to grid position
    func animateSnapToGrid(
        from startPosition: CGPoint,
        to endPosition: CGPoint,
        blockType: BlockType,
        completion: @escaping () -> Void
    ) {
        let config = AnimationConfiguration.forType(.snapToGrid, deviceType: deviceManager.deviceType)
        
        isAnimatingSnap = true
        snapProgress = 0.0
        
        withAnimation(config.curve.delay(config.delay)) {
            snapProgress = 1.0
        }
        
        // Store completion callback
        let callbackId = UUID().uuidString
        completionCallbacks[callbackId] = {
            self.isAnimatingSnap = false
            completion()
        }
        
        // Schedule completion
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration + config.delay) {
            self.completionCallbacks[callbackId]?()
            self.completionCallbacks.removeValue(forKey: callbackId)
        }
    }
    
    // MARK: - Placement Complete Animation
    
    /// Animate successful block placement
    func animatePlacementComplete(
        at positions: [GridPosition],
        blockType: BlockType,
        completion: @escaping () -> Void
    ) {
        let config = AnimationConfiguration.forType(.placementComplete, deviceType: deviceManager.deviceType)
        
        isAnimatingPlacement = true
        placementProgress = 0.0
        completionScale = 1.0
        glowOpacity = 0.0
        
        // Phase 1: Brief glow and scale
        withAnimation(.easeOut(duration: 0.15)) {
            completionScale = 1.1
            glowOpacity = 0.6
        }
        
        // Phase 2: Settle
        withAnimation(config.curve.delay(0.15)) {
            completionScale = 1.0
            glowOpacity = 0.0
            placementProgress = 1.0
        }
        
        // Haptic feedback
        deviceManager.provideNotificationFeedback(type: .success)
        
        // Store completion callback
        let callbackId = UUID().uuidString
        completionCallbacks[callbackId] = {
            self.isAnimatingPlacement = false
            completion()
        }
        
        // Schedule completion
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration + config.delay) {
            self.completionCallbacks[callbackId]?()
            self.completionCallbacks.removeValue(forKey: callbackId)
        }
    }
    
    // MARK: - Invalid Return Animation
    
    /// Animate block returning to tray after invalid placement
    func animateInvalidReturn(
        from position: CGPoint,
        to trayPosition: CGPoint,
        blockType: BlockType,
        completion: @escaping () -> Void
    ) {
        let config = AnimationConfiguration.forType(.invalidReturn, deviceType: deviceManager.deviceType)
        
        isAnimatingReturn = true
        
        // Shake animation first
        withAnimation(.easeInOut(duration: 0.1).repeatCount(3, autoreverses: true)) {
            completionRotation = 2.0
        }
        
        // Then return animation
        withAnimation(config.curve.delay(0.3)) {
            completionRotation = 0.0
        }
        
        // Error haptic feedback
        deviceManager.provideNotificationFeedback(type: .error)
        
        // Store completion callback
        let callbackId = UUID().uuidString
        completionCallbacks[callbackId] = {
            self.isAnimatingReturn = false
            completion()
        }
        
        // Schedule completion
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration + config.delay) {
            self.completionCallbacks[callbackId]?()
            self.completionCallbacks.removeValue(forKey: callbackId)
        }
    }
    
    // MARK: - Line Complete Animation
    
    /// Animate line completion with satisfying effects
    func animateLineComplete(
        positions: [GridPosition],
        completion: @escaping () -> Void
    ) {
        let config = AnimationConfiguration.forType(.lineComplete, deviceType: deviceManager.deviceType)
        
        isAnimatingLineComplete = true
        
        // Staggered animation for each cell
        for index in positions.indices {
            let delay = Double(index) * 0.05 // 50ms stagger
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.3)) {
                    // Individual cell animation would be handled by the grid view
                }
            }
        }
        
        // Success haptic feedback
        deviceManager.provideNotificationFeedback(type: .success)
        
        // Store completion callback
        let callbackId = UUID().uuidString
        completionCallbacks[callbackId] = {
            self.isAnimatingLineComplete = false
            completion()
        }
        
        // Schedule completion
        let totalDuration = config.duration + (Double(positions.count) * 0.05)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            self.completionCallbacks[callbackId]?()
            self.completionCallbacks.removeValue(forKey: callbackId)
        }
    }
    
    // MARK: - Block Appearance Animation
    
    /// Animate new block appearing in tray
    func animateBlockAppearance(
        blockType: BlockType,
        delay: TimeInterval = 0.0,
        completion: @escaping () -> Void
    ) {
        let config = AnimationConfiguration.forType(.blockAppear, deviceType: deviceManager.deviceType)
        
        withAnimation(config.curve.delay(delay)) {
            // Animation would be handled by the block view itself
        }
        
        // Subtle haptic feedback
        deviceManager.provideHapticFeedback(style: .light)
        
        // Schedule completion
        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration + delay) {
            completion()
        }
    }
    
    // MARK: - Animation Interruption
    
    /// Cancel all running animations
    func cancelAllAnimations() {
        // Reset animation states
        isAnimatingSnap = false
        isAnimatingPlacement = false
        isAnimatingReturn = false
        isAnimatingLineComplete = false
        
        // Reset progress values
        snapProgress = 0.0
        placementProgress = 0.0
        completionScale = 1.0
        completionRotation = 0.0
        glowOpacity = 0.0
        
        // Clear completion callbacks
        completionCallbacks.removeAll()
        
        // Cancel any pending work
        animationCancellables.removeAll()
    }
    
    /// Cancel specific animation type
    func cancelAnimation(type: PlacementAnimationType) {
        switch type {
        case .snapToGrid:
            isAnimatingSnap = false
            snapProgress = 0.0
        case .placementComplete:
            isAnimatingPlacement = false
            placementProgress = 0.0
            completionScale = 1.0
            glowOpacity = 0.0
        case .invalidReturn:
            isAnimatingReturn = false
            completionRotation = 0.0
        case .lineComplete:
            isAnimatingLineComplete = false
        case .blockAppear:
            break // No specific state to reset
        }
    }
    
    // MARK: - Animation State Queries
    
    /// Check if any animation is currently running
    var isAnimating: Bool {
        return isAnimatingSnap || isAnimatingPlacement || 
               isAnimatingReturn || isAnimatingLineComplete
    }
    
    /// Get optimal animation timing for block type
    func getOptimalTiming(for blockType: BlockType) -> TimeInterval {
        let baseTiming = deviceManager.getDragAnimationConfig().duration
        let cellCount = blockType.cellCount

        switch cellCount {
        case 1:
            return baseTiming * 0.8
        case 2...3:
            return baseTiming
        case 4...6:
            return baseTiming * 1.1
        default:
            return baseTiming * 1.25
        }
    }
    
    // MARK: - Device-Specific Optimizations
    
    /// Get performance-optimized animation settings
    private func getOptimizedSettings() -> (reduceMotion: Bool, preferredFrameRate: Int) {
        let reduceMotion = UIAccessibility.isReduceMotionEnabled
        let preferredFrameRate: Int

        // Check for ProMotion display (120Hz capable)
        let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120

        switch deviceManager.deviceType {
        case .iPhone:
            preferredFrameRate = reduceMotion ? 30 : (isProMotion ? 120 : 60)
        case .iPadMini:
            preferredFrameRate = reduceMotion ? 30 : (isProMotion ? 120 : 60)
        case .iPadRegular, .iPadPro:
            preferredFrameRate = reduceMotion ? 30 : (isProMotion ? 120 : 60)
        }

        return (reduceMotion, preferredFrameRate)
    }
    
    /// Apply accessibility modifications to animation
    private func accessibilityModifiedAnimation(_ animation: Animation) -> Animation {
        let settings = getOptimizedSettings()
        
        if settings.reduceMotion {
            // Reduce animation duration and complexity for accessibility
            return .easeInOut(duration: 0.1)
        } else {
            return animation
        }
    }
}

// MARK: - Animation Modifier

/// SwiftUI modifier for placement animations
struct PlacementAnimationModifier: ViewModifier {
    
    @ObservedObject var animator: PlacementAnimator
    let animationType: PlacementAnimationType
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleEffect)
            .rotationEffect(.degrees(rotationEffect))
            .opacity(opacityEffect)
            .overlay(glowOverlay)
    }
    
    private var scaleEffect: CGFloat {
        switch animationType {
        case .placementComplete:
            return animator.completionScale
        case .snapToGrid:
            return 1.0 + (animator.snapProgress * 0.05) // Subtle scale during snap
        default:
            return 1.0
        }
    }
    
    private var rotationEffect: Double {
        switch animationType {
        case .invalidReturn:
            return animator.completionRotation
        default:
            return 0.0
        }
    }
    
    private var opacityEffect: Double {
        switch animationType {
        case .blockAppear:
            return animator.placementProgress
        default:
            return 1.0
        }
    }
    
    @ViewBuilder
    private var glowOverlay: some View {
        if animationType == .placementComplete && animator.glowOpacity > 0 {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.green, lineWidth: 2)
                .opacity(animator.glowOpacity)
                .scaleEffect(1.1)
        }
    }
}

// MARK: - View Extension

extension View {
    func placementAnimation(
        _ animator: PlacementAnimator,
        type: PlacementAnimationType
    ) -> some View {
        self.modifier(PlacementAnimationModifier(animator: animator, animationType: type))
    }
}
