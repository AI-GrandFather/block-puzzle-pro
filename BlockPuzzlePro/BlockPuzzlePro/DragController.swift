import SwiftUI
import Combine
import UIKit
import os.log

// MARK: - Drag State

/// Represents the current state of a drag operation with better determinism
enum DragControllerState: Equatable {
    case idle
    case picking(blockIndex: Int, blockPattern: BlockPattern, startPosition: CGPoint, touchOffset: CGSize)
    case dragging(blockIndex: Int, blockPattern: BlockPattern, startPosition: CGPoint, touchOffset: CGSize)
    case settling(blockIndex: Int, blockPattern: BlockPattern, dropPosition: CGPoint, touchOffset: CGSize)
    case snapped(blockIndex: Int, blockPattern: BlockPattern, finalPosition: CGPoint)

    static func == (lhs: DragControllerState, rhs: DragControllerState) -> Bool {
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
    @Published var dragState: DragControllerState = .idle

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

    /// Visual lift offset (Y-axis) - piece rises when dragged for better visibility
    /// Default -100pt means piece appears 100pt above finger
    @Published var liftOffsetY: CGFloat = 0

    // MARK: - Gesture Properties

    @GestureState private var gestureOffset: CGSize = .zero
    @GestureState private var gestureScale: CGFloat = 1.0

    // MARK: - Performance Optimization for 120Hz ProMotion

    /// CADisplayLink for synchronized 120Hz visual updates
    private var displayLink: CADisplayLink?

    /// Whether we're running on ProMotion display
    private let isProMotionDisplay: Bool

    /// Pending visual update flag
    private var needsVisualUpdate: Bool = false

    // MARK: - Safety Mechanisms

    /// Timer to auto-reset stuck drags
    private var dragTimeoutTimer: Timer?

    /// Maximum time a drag can be active before auto-reset (10 seconds)
    private let maxDragDuration: TimeInterval = 10.0

    // MARK: - Instrumentation and Debug Logging

    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "DragController")
#if DEBUG
    private let signpostLog = OSLog(subsystem: "com.example.BlockPuzzlePro", category: "DragPerformance")
#endif

    /// State transition logging
    private func logStateTransition(from: DragControllerState, to: DragControllerState) {
        logger.debug("State transition: \(String(describing: from)) -> \(String(describing: to))")
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

        logger.info("DragController initialized: ProMotion=\(self.isProMotionDisplay), refreshRate=\(refreshRate)")

        // Set up CADisplayLink for 120Hz synchronized updates (Option B)
        setupDisplayLink()
    }

    convenience init() {
        self.init(deviceManager: nil)
    }

    // MARK: - Display Link Setup (Option B: 120Hz Synchronized Updates)

    /// Set up CADisplayLink for synchronized visual updates at native refresh rate
    private func setupDisplayLink() {
        // Create display link on main thread
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))

        // For ProMotion displays, use native 120Hz
        // For standard displays, use native 60Hz
        // Apple recommendation: minimum 30Hz allows system to optimize power/thermal
        if #available(iOS 15.0, *) {
            displayLink?.preferredFrameRateRange = CAFrameRateRange(
                minimum: 30,  // Allow system to drop to 30fps if needed (power/thermal optimization)
                maximum: Float(UIScreen.main.maximumFramesPerSecond),
                preferred: Float(UIScreen.main.maximumFramesPerSecond)
            )
        }

        // Add to run loop (paused by default, will activate during drag)
        displayLink?.isPaused = true
        displayLink?.add(to: .main, forMode: .common)

        logger.info("📺 CADisplayLink configured for \(UIScreen.main.maximumFramesPerSecond)Hz updates")
    }

    /// Display link callback - called every frame at 120Hz on ProMotion
    @objc private func displayLinkCallback() {
        guard needsVisualUpdate, isDragging else {
            return
        }

        // Update visual effects at native refresh rate
        updateVisualEffects()

        // Clear update flag
        needsVisualUpdate = false
    }

    /// Start display link for drag operation
    private func startDisplayLink() {
        displayLink?.isPaused = false
        logger.debug("🎬 Display link started")
    }

    /// Stop display link after drag completes
    private func stopDisplayLink() {
        displayLink?.isPaused = true
        needsVisualUpdate = false
        logger.debug("⏸️ Display link paused")
    }

    // MARK: - Drag Management
    
    /// Start a drag operation with deterministic state transitions
    func startDrag(blockIndex: Int, blockPattern: BlockPattern, at position: CGPoint, touchOffset: CGSize) {
        let oldState = dragState
        logger.debug("🚀 startDrag called for block \(blockIndex), current state: \(String(describing: self.dragState)), isDragging: \(self.isDragging)")

        // Strict state validation - only allow starting from idle
        guard case .idle = dragState, !isDragging else {
            logger.error("❌ Attempted to start drag in invalid state: \(String(describing: self.dragState)), isDragging: \(self.isDragging)")
            return
        }

        // Begin signpost for performance tracking
#if DEBUG
        os_signpost(.begin, log: signpostLog, name: "DragSequence", "blockIndex=%d", blockIndex)
#endif

        // Transition directly to dragging state (no async delay)
        dragState = .dragging(blockIndex: blockIndex, blockPattern: blockPattern, startPosition: position, touchOffset: touchOffset)
        logStateTransition(from: oldState, to: dragState)

        // Set up drag state atomically
        isDragging = true // Set immediately to prevent race conditions
        dragTouchOffset = touchOffset
        draggedBlockPattern = blockPattern
        currentBlockIndex = blockIndex
        draggedIndices.insert(blockIndex)

        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: position.y - touchOffset.height
        )
        currentTouchLocation = position  // Keep raw finger for reference

        // Start visual feedback immediately
        let springResponse = isProMotionDisplay ? 0.15 : 0.2
        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: 0.8)) {
            dragScale = 1.0
            shadowOffset = CGSize(width: 3, height: 6)
            liftOffsetY = -100  // Lift piece 100pt above finger
        }

        // Haptic feedback
        deviceManager?.provideHapticFeedback(style: .light)

        // Start CADisplayLink for 120Hz updates (Option B)
        startDisplayLink()

        // Start safety timeout timer
        startDragTimeoutTimer()

        onDragBegan?(blockIndex, blockPattern, position)
    }

    
    /// Update drag position with immediate preview updates optimized for 120Hz
    func updateDrag(to position: CGPoint) {
        // Handle both dragging and picking states to prevent race conditions
        let (blockIndex, blockPattern, startPosition, touchOffset): (Int, BlockPattern, CGPoint, CGSize)

        switch dragState {
        case .dragging(let bIdx, let bPattern, let sPos, let tOffset):
            (blockIndex, blockPattern, startPosition, touchOffset) = (bIdx, bPattern, sPos, tOffset)
        case .picking(let bIdx, let bPattern, let sPos, let tOffset):
            // Immediately transition to dragging state to fix race condition
            let oldState = dragState
            dragState = .dragging(blockIndex: bIdx, blockPattern: bPattern, startPosition: sPos, touchOffset: tOffset)
            logStateTransition(from: oldState, to: dragState)
            isDragging = true
            (blockIndex, blockPattern, startPosition, touchOffset) = (bIdx, bPattern, sPos, tOffset)
        default:
            logger.debug("updateDrag called in invalid state: \(String(describing: self.dragState))")
            return
        }

        // Performance signpost for tracking
#if DEBUG
        os_signpost(.event, log: signpostLog, name: "DragUpdate")
#endif

        // Update position using VISUAL position (finger + lift offset)
        // This ensures placement logic uses where the piece visually appears
        let visualFingerY = position.y + liftOffsetY
        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: visualFingerY - touchOffset.height
        )
        dragOffset = CGSize(
            width: position.x - startPosition.x,
            height: position.y - startPosition.y
        )
        currentTouchLocation = position

        // Call onDragChanged immediately for real-time preview - this is critical for first drag
        onDragChanged?(blockIndex, blockPattern, position)

        // Mark that visual update is needed - CADisplayLink will handle it at 120Hz
        needsVisualUpdate = true
    }

    /// Update visual effects with optimized animations for 120Hz ProMotion
    private func updateVisualEffects() {
        let normalizedOffset = dragOffset.width / 100.0
        dragRotation = sin(normalizedOffset) * 1.5

        let shadowX = max(min(dragOffset.width * 0.05, 10), -10)
        let shadowY = max(min(8 + dragOffset.height * 0.03, 14), 2)
        shadowOffset = CGSize(width: shadowX, height: shadowY)
    }

    

    /// End drag operation with proper state transitions and optimized snapping
    func endDrag(at position: CGPoint) {
        logger.debug("🎯 endDrag called at position: (\(position.x), \(position.y)), current state: \(String(describing: self.dragState))")

        // Handle both dragging and picking states to prevent race conditions
        let (blockIndex, blockPattern, startPosition, touchOffset): (Int, BlockPattern, CGPoint, CGSize)

        switch dragState {
        case .dragging(let bIdx, let bPattern, let sPos, let tOffset):
            (blockIndex, blockPattern, startPosition, touchOffset) = (bIdx, bPattern, sPos, tOffset)
        case .picking(let bIdx, let bPattern, let sPos, let tOffset):
            // Allow ending drag even from picking state
            (blockIndex, blockPattern, startPosition, touchOffset) = (bIdx, bPattern, sPos, tOffset)
        case .idle:
            logger.debug("⚠️ endDrag called when already idle - ignoring")
            return
        case .settling, .snapped:
            logger.debug("⚠️ endDrag called when in \(String(describing: self.dragState)) state - ignoring")
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

        // Use VISUAL position (finger + lift) for final placement
        let visualFingerY = position.y + liftOffsetY
        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: visualFingerY - touchOffset.height
        )
        dragOffset = CGSize(
            width: position.x - startPosition.x,
            height: position.y - startPosition.y
        )
        currentTouchLocation = position

        // Call drag ended callback immediately (use visual position)
        let visualPosition = CGPoint(x: position.x, y: visualFingerY)
        onDragEnded?(blockIndex, blockPattern, visualPosition)

        // Clear dragged pattern immediately to hide floating preview
        // This prevents the green outline from persisting while animations complete
        draggedBlockPattern = nil
        currentBlockIndex = nil

        // Stop CADisplayLink since drag is complete (Option B)
        stopDisplayLink()

        // CRITICAL FIX: Complete state transition immediately instead of waiting for animation
        // The async animation was causing the drag controller to stay in 'settling' state
        // which prevented new drags from starting
        transitionToIdleImmediately()

        // Start visual settling animation without blocking state transitions
        performVisualSettlingAnimation()
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
            liftOffsetY = 0  // Reset lift offset
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
#if DEBUG
        os_signpost(.end, log: signpostLog, name: "DragSequence")
#endif

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

    /// Immediately transition to idle state to allow new drags (synchronous version)
    private func transitionToIdleImmediately() {
        let oldState = dragState
        logger.debug("🔄 transitionToIdleImmediately called, current state: \(String(describing: oldState))")

        // End performance signpost
#if DEBUG
        os_signpost(.end, log: signpostLog, name: "DragSequence")
#endif

        // Transition directly to idle state (no async delay)
        dragState = .idle
        logStateTransition(from: oldState, to: dragState)

        // Clear all drag state atomically
        isDragging = false
        dragTouchOffset = .zero
        draggedIndices.removeAll()
        // Note: draggedBlockPattern and currentBlockIndex already cleared above

        logger.debug("✅ State transition complete, dragState=\(String(describing: self.dragState)), isDragging=\(self.isDragging)")

        // Cancel timeout timer since drag completed successfully
        dragTimeoutTimer?.invalidate()
        dragTimeoutTimer = nil
    }

    /// Visual settling animation without state transitions
    private func performVisualSettlingAnimation() {
        // Target: 100-140ms for crisp feel at 120Hz
        let springResponse = isProMotionDisplay ? 0.12 : 0.18
        let dampingFraction: CGFloat = 0.85 // Higher damping for crisper animation

        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: dampingFraction)) {
            dragScale = 1.0
            dragRotation = 0.0
            shadowOffset = .zero
            dragOffset = .zero
            liftOffsetY = 0  // Reset lift offset
        }
    }

    /// Cancel drag operation (return to original position) with proper state management
    func cancelDrag() {
        // Handle both dragging and picking states to prevent race conditions
        let (blockIndex, blockPattern, startPosition): (Int, BlockPattern, CGPoint)

        switch dragState {
        case .dragging(let bIdx, let bPattern, let sPos, _):
            (blockIndex, blockPattern, startPosition) = (bIdx, bPattern, sPos)
        case .picking(let bIdx, let bPattern, let sPos, _):
            (blockIndex, blockPattern, startPosition) = (bIdx, bPattern, sPos)
        default:
            logger.debug("cancelDrag called in invalid state: \(String(describing: self.dragState))")
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
            liftOffsetY = 0  // Reset lift offset
        }

        onInvalidDrop?(blockIndex, blockPattern, startPosition)

        // Clear dragged pattern immediately to hide floating preview
        draggedBlockPattern = nil
        currentBlockIndex = nil

        // Stop CADisplayLink since drag is cancelled (Option B)
        stopDisplayLink()

        // Transition to idle after animation
        let animationDuration = springResponse * 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) { [weak self] in
            let oldState = self?.dragState ?? .idle
            self?.dragState = .idle
            self?.logStateTransition(from: oldState, to: .idle)

            // Clear remaining state atomically
            self?.isDragging = false
            self?.dragTouchOffset = .zero
            self?.draggedIndices.removeAll()

            // Cancel timeout timer since drag completed (even if canceled)
            self?.dragTimeoutTimer?.invalidate()
            self?.dragTimeoutTimer = nil
        }
    }
    
    /// Handle successful drop
    func handleValidDrop(at position: CGPoint) {
        let (blockIndex, blockPattern): (Int, BlockPattern)

        switch dragState {
        case .dragging(let bIdx, let bPattern, _, _), .picking(let bIdx, let bPattern, _, _):
            (blockIndex, blockPattern) = (bIdx, bPattern)
        default:
            return
        }

        // Success haptic feedback
        deviceManager?.provideNotificationFeedback(type: .success)

        onValidDrop?(blockIndex, blockPattern, position)
        endDrag(at: position)
    }

    /// Handle invalid drop
    func handleInvalidDrop() {
        let (blockIndex, blockPattern, startPosition): (Int, BlockPattern, CGPoint)

        switch dragState {
        case .dragging(let bIdx, let bPattern, let sPos, _), .picking(let bIdx, let bPattern, let sPos, _):
            (blockIndex, blockPattern, startPosition) = (bIdx, bPattern, sPos)
        default:
            return
        }

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
    
    // MARK: - Safety Timeout

    /// Start timeout timer to auto-reset stuck drags
    private func startDragTimeoutTimer() {
        // Cancel any existing timer
        dragTimeoutTimer?.invalidate()

        // Start new timer
        dragTimeoutTimer = Timer.scheduledTimer(withTimeInterval: maxDragDuration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleDragTimeout()
            }
        }

        logger.debug("🕒 Drag timeout timer started (\(self.maxDragDuration)s)")
    }

    /// Handle drag timeout - auto-reset stuck drags
    private func handleDragTimeout() {
        logger.warning("⏰ Drag timeout triggered - force resetting stuck drag")
        DebugLog.trace("🚨 DRAG TIMEOUT: Force resetting drag controller after \(self.maxDragDuration)s")

        // Force reset the entire drag controller
        reset()

        // Notify that drag was force-canceled
        // Note: We don't call onDragEnded/onInvalidDrop since the gesture is stuck
    }

    // MARK: - Reset
    
    /// Reset all drag state
    func reset() {
        // Cancel any pending timeout timer
        dragTimeoutTimer?.invalidate()
        dragTimeoutTimer = nil

        // Stop display link
        stopDisplayLink()

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

        // Reset visual update flag
        needsVisualUpdate = false
    }
    
    // MARK: - Cleanup

    deinit {
        // CADisplayLink and Timer cleanup handled automatically by Swift
        // Cannot access @MainActor properties from non-isolated deinit
    }
}
