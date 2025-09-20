import SwiftUI
import Combine
import UIKit
import os.signpost

// MARK: - Drag State

/// Represents the current state of a drag operation with better determinism
enum DragState: Equatable {
    case idle
    case picking(blockIndex: Int, blockPattern: BlockPattern, startPosition: CGPoint, touchOffset: CGSize)
    case dragging(blockIndex: Int, blockPattern: BlockPattern, startPosition: CGPoint, touchOffset: CGSize)
    case settling(blockIndex: Int, blockPattern: BlockPattern, dropPosition: CGPoint, touchOffset: CGSize)
    case snapped(blockIndex: Int, blockPattern: BlockPattern, finalPosition: CGPoint)

    static func == (lhs: DragState, rhs: DragState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.picking(let l1, _, _, _), .picking(let r1, _, _, _)):
            return l1 == r1
        case (.dragging(let l1, _, _, _), .dragging(let r1, _, _, _)):
            return l1 == r1
        case (.settling(let l1, _, _, _), .settling(let r1, _, _, _)):
            return l1 == r1
        case (.snapped(let l1, _, _), .snapped(let r1, _, _)):
            return l1 == r1
        default:
            return false
        }
    }
}

// MARK: - Drag Controller

/// Manages drag and drop interactions for block placement with deterministic state machine
@MainActor
class DragController: ObservableObject {

    // MARK: - Properties

    /// Device manager for device-specific optimizations
    private let deviceManager: DeviceManager?

    /// Current drag state with deterministic transitions
    @Published private(set) var dragState: DragState = .idle

    /// Current drag offset from original position
    @Published var dragOffset: CGSize = .zero

    /// Whether a drag operation is currently active
    @Published var isDragging: Bool = false

    /// Current drag position in global coordinates
    @Published var currentDragPosition: CGPoint = .zero

    /// Current touch point in global coordinates
    @Published var currentTouchLocation: CGPoint = .zero

    /// Scale factor for dragged block during drag
    @Published var dragScale: CGFloat = 1.0

    /// Rotation for dragged block (for visual effect)
    @Published var dragRotation: Double = 0.0

    /// Shadow offset for dragged block
    @Published var shadowOffset: CGSize = .zero

    /// Offset from the user's touch point to the block's top-left in screen space
    @Published var dragTouchOffset: CGSize = .zero

    /// Currently dragged block pattern (if any)
    @Published var draggedBlockPattern: BlockPattern? = nil

    /// Currently dragged block index (if any)
    @Published var currentBlockIndex: Int? = nil

    // MARK: - Gesture Properties

    @GestureState private var gestureOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0

    // MARK: - Performance Optimization for 120Hz ProMotion

    /// Optimized update interval for 120Hz displays
    private let minUpdateInterval: TimeInterval

    /// Last update timestamp for throttling
    private var lastUpdateTime: TimeInterval = 0

    /// Whether we're running on ProMotion display
    private let isProMotionDisplay: Bool

    // MARK: - Instrumentation and Debug Logging

    private let logger = OSLog(subsystem: "com.blockpuzzlepro.dragcontroller", category: "DragOperations")
    private let signpostLog = OSSignpostLog(subsystem: "com.blockpuzzlepro.dragcontroller", category: "Performance")

    /// State transition logging
    private func logStateTransition(from: DragState, to: DragState) {
        os_log(.debug, log: logger, "State transition: %{public}@ -> %{public}@",
               String(describing: from), String(describing: to))
    }
    
    
    // MARK: - Callbacks
    
    /// Called when drag begins
    var onDragBegan: ((Int, BlockPattern, CGPoint) -> Void)?
    
    /// Called during drag movement
    var onDragChanged: ((Int, BlockPattern, CGPoint) -> Void)?
    
    /// Called when drag ends
    var onDragEnded: ((Int, BlockPattern, CGPoint) -> Void)?
    
    /// Called when a valid drop position is detected
    var onValidDrop: ((Int, BlockPattern, CGPoint) -> Void)?
    
    /// Called when an invalid drop is attempted
    var onInvalidDrop: ((Int, BlockPattern, CGPoint) -> Void)?
    
    // Track which block indices are currently dragged (usually only one)
    private var draggedIndices: Set<Int> = []

    // MARK: - Initialization

    init(deviceManager: DeviceManager? = nil) {
        self.deviceManager = deviceManager

        // Detect ProMotion display capability
        let refreshRate = Double(UIScreen.main.maximumFramesPerSecond)
        self.isProMotionDisplay = refreshRate >= 120.0

        // Optimize update interval for 120Hz ProMotion displays
        if let interval = deviceManager?.idealDragUpdateInterval() {
            self.minUpdateInterval = interval
        } else {
            let resolvedRate = refreshRate > 0 ? refreshRate : 60.0
            // For ProMotion, use higher frequency updates (every 2-3 frames instead of every frame)
            self.minUpdateInterval = self.isProMotionDisplay ? (1.0 / 60.0) : (1.0 / resolvedRate)
        }

        os_log(.info, log: logger, "DragController initialized: ProMotion=%{public}@, refreshRate=%{public}f, updateInterval=%{public}f",
               String(isProMotionDisplay), refreshRate, minUpdateInterval)
    }

    convenience init() {
        self.init(deviceManager: nil)
    }
    
    // MARK: - Drag Management
    
    /// Start a drag operation with deterministic state transitions
    func startDrag(blockIndex: Int, blockPattern: BlockPattern, at position: CGPoint, touchOffset: CGSize) {
        let oldState = dragState

        // Strict state validation - only allow starting from idle
        guard case .idle = dragState, !isDragging else {
            os_log(.error, log: logger, "Attempted to start drag in invalid state: %{public}@", String(describing: dragState))
            return
        }

        // Begin signpost for performance tracking
        os_signpost(.begin, log: signpostLog, name: "DragSequence", "blockIndex=%d", blockIndex)

        // Transition to picking state first
        dragState = .picking(blockIndex: blockIndex, blockPattern: blockPattern, startPosition: position, touchOffset: touchOffset)
        logStateTransition(from: oldState, to: dragState)

        // Set up drag state atomically
        isDragging = false // Will be set to true when actually dragging starts
        dragTouchOffset = touchOffset
        draggedBlockPattern = blockPattern
        currentBlockIndex = blockIndex
        draggedIndices.insert(blockIndex)

        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: position.y - touchOffset.height
        )
        currentTouchLocation = position

        // Immediate transition to dragging state
        DispatchQueue.main.async { [weak self] in
            self?.transitionToDragging()
        }

        onDragBegan?(blockIndex, blockPattern, position)
    }

    /// Internal method to transition from picking to dragging
    private func transitionToDragging() {
        guard case .picking(let blockIndex, let blockPattern, let startPosition, let touchOffset) = dragState else {
            return
        }

        let oldState = dragState
        dragState = .dragging(blockIndex: blockIndex, blockPattern: blockPattern, startPosition: startPosition, touchOffset: touchOffset)
        logStateTransition(from: oldState, to: dragState)

        isDragging = true

        // Optimized animation for ProMotion displays
        let animationDuration = isProMotionDisplay ? 0.08 : 0.12
        let springResponse = isProMotionDisplay ? 0.15 : 0.2

        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: 0.8)) {
            dragScale = 1.1
            shadowOffset = CGSize(width: 3, height: 6)
        }

        // Haptic feedback
        deviceManager?.provideHapticFeedback(style: .light)
    }
    
    /// Update drag position with immediate preview updates optimized for 120Hz
    func updateDrag(to position: CGPoint) {
        guard case let .dragging(blockIndex, blockPattern, startPosition, touchOffset) = dragState else {
            os_log(.debug, log: logger, "updateDrag called in non-dragging state: %{public}@", String(describing: dragState))
            return
        }

        // Performance signpost for tracking
        os_signpost(.event, log: signpostLog, name: "DragUpdate")

        // Update position immediately for smooth preview
        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: position.y - touchOffset.height
        )
        dragOffset = CGSize(
            width: position.x - startPosition.x,
            height: position.y - startPosition.y
        )
        currentTouchLocation = position

        // Call onDragChanged immediately for real-time preview - this is critical for first drag
        onDragChanged?(blockIndex, blockPattern, position)

        // Throttle visual effects for performance, but be more responsive on ProMotion
        let currentTime = CACurrentMediaTime()
        if currentTime - lastUpdateTime >= minUpdateInterval {
            updateVisualEffects()
            lastUpdateTime = currentTime
        }
    }

    /// Update visual effects with optimized animations for 120Hz ProMotion
    private func updateVisualEffects() {
        // Subtle rotation effect based on drag velocity (optimized calculation)
        let normalizedOffset = dragOffset.width / 100.0
        let rotation = sin(normalizedOffset) * 1.5 // Reduced rotation for smoother feel

        // Use optimized animation timing for ProMotion displays
        let animationDuration = isProMotionDisplay ? 0.016 : 0.03 // ~1 frame at 60Hz or 120Hz

        withAnimation(.linear(duration: animationDuration)) {
            dragRotation = rotation
        }
    }

    

    /// End drag operation with proper state transitions and optimized snapping
    func endDrag(at position: CGPoint) {
        guard case let .dragging(blockIndex, blockPattern, startPosition, touchOffset) = dragState else {
            os_log(.debug, log: logger, "endDrag called in non-dragging state: %{public}@", String(describing: dragState))
            return
        }

        let oldState = dragState

        // Transition to settling state first
        dragState = .settling(
            blockIndex: blockIndex,
            blockPattern: blockPattern,
            dropPosition: position,
            touchOffset: touchOffset
        )
        logStateTransition(from: oldState, to: dragState)

        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: position.y - touchOffset.height
        )
        dragOffset = CGSize(
            width: position.x - startPosition.x,
            height: position.y - startPosition.y
        )
        currentTouchLocation = position

        // Call drag ended callback immediately
        onDragEnded?(blockIndex, blockPattern, position)

        // Start settling animation optimized for 120Hz
        performSettlingAnimation { [weak self] in
            self?.transitionToSnappedOrIdle()
        }
    }

    /// Optimized settling animation for ProMotion displays (100-140ms target)
    private func performSettlingAnimation(completion: @escaping () -> Void) {
        // Target: 100-140ms for crisp feel at 120Hz
        let springResponse = isProMotionDisplay ? 0.12 : 0.18
        let dampingFraction: CGFloat = 0.85 // Higher damping for crisper animation

        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: dampingFraction)) {
            dragScale = 1.0
            dragRotation = 0.0
            shadowOffset = .zero
            dragOffset = .zero
        }

        // Schedule completion after animation
        let animationDuration = springResponse * 1.5 // Account for spring settling
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            completion()
        }
    }

    /// Complete the drag sequence by transitioning to final state
    private func transitionToSnappedOrIdle() {
        guard case .settling(let blockIndex, let blockPattern, let dropPosition, _) = dragState else {
            return
        }

        let oldState = dragState

        // End performance signpost
        os_signpost(.end, log: signpostLog, name: "DragSequence")

        // Transition to snapped state briefly before going idle
        dragState = .snapped(blockIndex: blockIndex, blockPattern: blockPattern, finalPosition: dropPosition)
        logStateTransition(from: oldState, to: dragState)

        // Immediately transition to idle - this ensures tray refreshes
        DispatchQueue.main.async { [weak self] in
            let oldState = self?.dragState ?? .idle
            self?.dragState = .idle
            self?.logStateTransition(from: oldState, to: .idle)

            // Clear all drag state atomically
            self?.isDragging = false
            self?.dragTouchOffset = .zero
            self?.draggedBlockPattern = nil
            self?.currentBlockIndex = nil
            self?.draggedIndices.removeAll()
        }
    }

    /// Cancel drag operation (return to original position) with proper state management
    func cancelDrag() {
        guard case let .dragging(blockIndex, blockPattern, startPosition, _) = dragState else {
            os_log(.debug, log: logger, "cancelDrag called in non-dragging state: %{public}@", String(describing: dragState))
            return
        }

        let oldState = dragState

        // Transition through settling state for consistency
        dragState = .settling(blockIndex: blockIndex, blockPattern: blockPattern, dropPosition: startPosition, touchOffset: .zero)
        logStateTransition(from: oldState, to: dragState)

        // Optimized return animation for ProMotion
        let springResponse = isProMotionDisplay ? 0.25 : 0.4
        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: 0.8)) {
            dragOffset = .zero
            dragScale = 1.0
            dragRotation = 0.0
            shadowOffset = .zero
        }

        onInvalidDrop?(blockIndex, blockPattern, startPosition)

        // Transition to idle after animation
        let animationDuration = springResponse * 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            let oldState = self?.dragState ?? .idle
            self?.dragState = .idle
            self?.logStateTransition(from: oldState, to: .idle)

            // Clear state atomically
            self?.isDragging = false
            self?.dragTouchOffset = .zero
            self?.draggedBlockPattern = nil
            self?.currentBlockIndex = nil
            self?.draggedIndices.removeAll()
        }
    }
    
    /// Handle successful drop
    func handleValidDrop(at position: CGPoint) {
        guard case let .dragging(blockIndex, blockPattern, _, _) = dragState else { return }

        // Success haptic feedback
        deviceManager?.provideNotificationFeedback(type: .success)

        onValidDrop?(blockIndex, blockPattern, position)
        endDrag(at: position)
    }
    
    /// Handle invalid drop
    func handleInvalidDrop() {
        guard case let .dragging(blockIndex, blockPattern, startPosition, _) = dragState else { return }

        // Error haptic feedback
        deviceManager?.provideNotificationFeedback(type: .error)

        onInvalidDrop?(blockIndex, blockPattern, startPosition)
        cancelDrag()
    }
    
    // MARK: - Gesture Creation
    
    /// Create a drag gesture for a block
    func createDragGesture(
        for blockIndex: Int,
        blockPattern: BlockPattern,
        coordinateSpace: CoordinateSpace = .global
    ) -> some Gesture {
        DragGesture(coordinateSpace: coordinateSpace)
            .updating($gestureOffset) { value, state, _ in
                state = value.translation
            }
            .onChanged { value in
                if !self.isDragging {
                    self.startDrag(
                        blockIndex: blockIndex,
                        blockPattern: blockPattern,
                        at: value.startLocation,
                        touchOffset: .zero
                    )
                }
                self.updateDrag(to: value.location)
            }
            .onEnded { value in
                self.endDrag(at: value.location)
            }
    }
    
    // MARK: - State Queries
    
    /// Get the currently dragged block index if any
    var draggedBlockIndex: Int? {
        switch dragState {
        case .idle:
            return nil
        case .picking(let blockIndex, _, _, _),
             .dragging(let blockIndex, _, _, _),
             .settling(let blockIndex, _, _, _),
             .snapped(let blockIndex, _, _):
            return blockIndex
        }
    }
    
    
    /// Check if a specific block is currently being dragged
    func isBlockDragged(_ blockIndex: Int) -> Bool {
        return draggedIndices.contains(blockIndex) && isDragging
    }
    
    // MARK: - Reset
    
    /// Reset all drag state
    func reset() {
        // Reset state
        dragState = .idle
        isDragging = false
        dragOffset = .zero
        currentDragPosition = .zero
        currentTouchLocation = .zero
        dragScale = 1.0
        dragRotation = 0.0
        shadowOffset = .zero
        dragTouchOffset = .zero
        draggedBlockPattern = nil
        currentBlockIndex = nil
        draggedIndices.removeAll()

        // Reset performance tracking
        lastUpdateTime = 0
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Timer cleanup handled automatically through reset() called before deallocation
        // Cannot access @MainActor properties from deinit
    }
}
