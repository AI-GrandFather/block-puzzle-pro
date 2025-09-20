import SwiftUI
import Combine
import UIKit

// MARK: - Drag State

/// Represents the current state of a drag operation
enum DragState {
    case idle
    case dragging(blockIndex: Int, blockPattern: BlockPattern, startPosition: CGPoint, touchOffset: CGSize)
    case dropping(blockIndex: Int, blockPattern: BlockPattern, dropPosition: CGPoint, touchOffset: CGSize)
}

// MARK: - Drag Controller

/// Manages drag and drop interactions for block placement
@MainActor
class DragController: ObservableObject {

    // MARK: - Properties

    /// Device manager for device-specific optimizations
    private let deviceManager: DeviceManager?

    /// Current drag state
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
    
    // MARK: - Performance Optimization
    
    /// Minimum time interval between drag updates (defaults to current display refresh rate)
    private let minUpdateInterval: TimeInterval
    
    /// Last update timestamp
    private var lastUpdateTime: TimeInterval = 0
    
    
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
        if let interval = deviceManager?.idealDragUpdateInterval() {
            self.minUpdateInterval = interval
        } else {
            let refreshRate = Double(UIScreen.main.maximumFramesPerSecond)
            let resolvedRate = refreshRate > 0 ? refreshRate : 60.0
            self.minUpdateInterval = 1.0 / resolvedRate
        }
    }

    convenience init() {
        self.init(deviceManager: nil)
    }
    
    // MARK: - Drag Management
    
    /// Start a drag operation
    func startDrag(blockIndex: Int, blockPattern: BlockPattern, at position: CGPoint, touchOffset: CGSize) {
        // Prevent multiple blocks from being dragged simultaneously
        guard case .idle = dragState, !isDragging else { return }

        dragState = .dragging(blockIndex: blockIndex, blockPattern: blockPattern, startPosition: position, touchOffset: touchOffset)
        isDragging = true
        dragTouchOffset = touchOffset
        draggedBlockPattern = blockPattern
        currentBlockIndex = blockIndex
        draggedIndices.insert(blockIndex)

        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: position.y - touchOffset.height
        )

        currentTouchLocation = position

        // Device-optimized visual feedback for drag start
        withAnimation(.easeOut(duration: 0.12)) {
            dragScale = 1.1
            shadowOffset = CGSize(width: 3, height: 6)
        }

        // Haptic feedback if device manager is available
        if let deviceManager = deviceManager {
            deviceManager.provideHapticFeedback(style: .light)
        }

        onDragBegan?(blockIndex, blockPattern, position)
    }
    
    /// Update drag position with immediate preview updates
    func updateDrag(to position: CGPoint) {
        guard case let .dragging(blockIndex, blockPattern, startPosition, touchOffset) = dragState else { return }

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

        // Call onDragChanged immediately for real-time preview
        onDragChanged?(blockIndex, blockPattern, position)

        // Throttle only visual effects like rotation for performance
        let currentTime = CACurrentMediaTime()
        if currentTime - lastUpdateTime >= minUpdateInterval {
            updateVisualEffects()
            lastUpdateTime = currentTime
        }
    }

    /// Update visual effects with throttling for performance
    private func updateVisualEffects() {
        // Subtle rotation effect based on drag velocity (optimized calculation)
        let normalizedOffset = dragOffset.width / 100.0
        let rotation = sin(normalizedOffset) * 2.0

        // Use lightweight animation for better performance
        withAnimation(.linear(duration: 0.03)) {
            dragRotation = rotation
        }
    }

    

    /// End drag operation
    func endDrag(at position: CGPoint) {
        guard case let .dragging(blockIndex, blockPattern, startPosition, touchOffset) = dragState else { return }

        dragState = .dropping(
            blockIndex: blockIndex,
            blockPattern: blockPattern,
            dropPosition: position,
            touchOffset: touchOffset
        )

        currentDragPosition = CGPoint(
            x: position.x - touchOffset.width,
            y: position.y - touchOffset.height
        )
        dragOffset = CGSize(
            width: position.x - startPosition.x,
            height: position.y - startPosition.y
        )
        currentTouchLocation = position

        // Reset visual effects
        withAnimation(.spring(response: 0.18, dampingFraction: 0.75)) {
            dragScale = 1.0
            dragRotation = 0.0
            shadowOffset = .zero
            dragOffset = .zero
        }

        onDragEnded?(blockIndex, blockPattern, position)

        // Reset to idle synchronously so tray refreshes immediately
        dragState = .idle
        isDragging = false
        dragTouchOffset = .zero
        draggedBlockPattern = nil
        currentBlockIndex = nil
        draggedIndices.removeAll()
    }

    /// Cancel drag operation (return to original position)
    func cancelDrag() {
        guard case let .dragging(blockIndex, blockPattern, startPosition, _) = dragState else { return }

        // Animate back to start position
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = .zero
            dragScale = 1.0
            dragRotation = 0.0
            shadowOffset = .zero
        }

        onInvalidDrop?(blockIndex, blockPattern, startPosition)

        dragState = .idle
        isDragging = false
        dragTouchOffset = .zero
        draggedBlockPattern = nil
        currentBlockIndex = nil
        draggedIndices.removeAll()
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
        case .dragging(let blockIndex, _, _, _), .dropping(let blockIndex, _, _, _):
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
