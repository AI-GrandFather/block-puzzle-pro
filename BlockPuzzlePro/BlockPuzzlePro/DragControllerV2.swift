import SwiftUI
import Combine
import UIKit
import os.log

// MARK: - Simplified Drag State

/// Clean, simple drag state machine
enum SimpleDragState: Equatable {
    case idle
    case active(blockIndex: Int, pattern: BlockPattern)

    var isActive: Bool {
        if case .active = self { return true }
        return false
    }
}

extension SimpleDragState {
    static func ==(lhs: SimpleDragState, rhs: SimpleDragState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.active(lIndex, lPattern), .active(rIndex, rPattern)):
            return lIndex == rIndex && lPattern.type == rPattern.type
        default:
            return false
        }
    }
}

// MARK: - Drag Controller V2 - Completely Rewritten

/// Simplified drag controller with pixel-perfect coordinate handling
@MainActor
final class DragControllerV2: ObservableObject {

    // MARK: - Published State

    @Published var dragState: SimpleDragState = .idle
    @Published var currentTouchLocation: CGPoint = .zero
    @Published var draggedPattern: BlockPattern?
    @Published var draggedBlockIndex: Int?

    // Animation properties
    @Published var dragScale: CGFloat = 1.0
    @Published var shadowOpacity: Double = 0.0

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "DragControllerV2")

    /// The finger's position relative to the block's top-left corner (in screen points)
    /// This stays constant throughout the drag
    private var fingerOffsetFromBlockOrigin: CGSize = .zero

    /// The cell size of the block in the tray (before dragging)
    private var trayCellSize: CGFloat = 0

    /// Device manager for haptics
    private let deviceManager: DeviceManager?

    /// ProMotion detection
    private let isProMotion: Bool

    // MARK: - Callbacks

    var onDragBegan: ((Int, BlockPattern, CGPoint) -> Void)?
    var onDragChanged: ((Int, BlockPattern, CGPoint) -> Void)?
    var onDragEnded: ((Int, BlockPattern, CGPoint) -> Void)?

    // MARK: - Initialization

    init(deviceManager: DeviceManager? = nil) {
        self.deviceManager = deviceManager
        let displayInfo = FrameRateConfigurator.currentDisplayInfo()
        self.isProMotion = displayInfo.maxRefreshRate >= 120
    }

    // MARK: - Public API

    /// Start dragging a block
    /// - Parameters:
    ///   - blockIndex: Index of the block in the tray
    ///   - pattern: The block pattern being dragged
    ///   - touchLocation: Where the finger is in global coordinates
    ///   - blockOrigin: Where the block's top-left corner is in global coordinates
    ///   - trayCellSize: The size of one cell in the tray
    func startDrag(
        blockIndex: Int,
        pattern: BlockPattern,
        touchLocation: CGPoint,
        blockOrigin: CGPoint,
        trayCellSize: CGFloat
    ) {
        guard case .idle = dragState else {
            logger.warning("Cannot start drag - already dragging")
            return
        }

        logger.info("🚀 START DRAG: block=\(blockIndex, privacy: .public) touch=\(touchLocation.debugDescription, privacy: .public) blockOrigin=\(blockOrigin.debugDescription, privacy: .public) trayCellSize=\(trayCellSize, privacy: .public)")

        // Calculate the finger's offset from the block's top-left corner
        // This offset remains constant throughout the entire drag
        fingerOffsetFromBlockOrigin = CGSize(
            width: touchLocation.x - blockOrigin.x,
            height: touchLocation.y - blockOrigin.y
        )

        self.trayCellSize = trayCellSize
        dragState = .active(blockIndex: blockIndex, pattern: pattern)
        currentTouchLocation = touchLocation
        draggedPattern = pattern
        draggedBlockIndex = blockIndex

        // Animate scale and shadow
        let response = isProMotion ? 0.15 : 0.2
        withAnimation(.interactiveSpring(response: response, dampingFraction: 0.8)) {
            dragScale = 1.15
            shadowOpacity = 0.3
        }

        // Haptic feedback
        deviceManager?.provideHapticFeedback(style: .light)

        onDragBegan?(blockIndex, pattern, touchLocation)
    }

    /// Update drag position
    func updateDrag(to touchLocation: CGPoint) {
        guard case .active(let blockIndex, let pattern) = dragState else { return }

        currentTouchLocation = touchLocation
        onDragChanged?(blockIndex, pattern, touchLocation)
    }

    /// End drag operation
    func endDrag(at touchLocation: CGPoint) {
        guard case .active(let blockIndex, let pattern) = dragState else {
            logger.warning("Cannot end drag - not dragging")
            return
        }

        logger.info("🎯 END DRAG: block=\(blockIndex, privacy: .public) touch=\(touchLocation.debugDescription, privacy: .public)")

        currentTouchLocation = touchLocation
        onDragEnded?(blockIndex, pattern, touchLocation)

        // Reset state
        reset()
    }

    /// Cancel the current drag
    func cancelDrag() {
        guard case .active = dragState else { return }

        logger.info("❌ CANCEL DRAG")

        // Animate back
        let response = isProMotion ? 0.25 : 0.3
        withAnimation(.interactiveSpring(response: response, dampingFraction: 0.8)) {
            dragScale = 1.0
            shadowOpacity = 0.0
        }

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + response) { [weak self] in
            self?.reset()
        }
    }

    /// Reset all drag state
    func reset() {
        dragState = .idle
        currentTouchLocation = .zero
        draggedPattern = nil
        draggedBlockIndex = nil
        fingerOffsetFromBlockOrigin = .zero
        trayCellSize = 0

        withAnimation(.easeOut(duration: 0.15)) {
            dragScale = 1.0
            shadowOpacity = 0.0
        }
    }

    // MARK: - Coordinate Helpers

    /// Get the block's top-left corner position based on current finger position
    /// This is the key method for pixel-perfect positioning
    func getBlockOrigin() -> CGPoint {
        return CGPoint(
            x: currentTouchLocation.x - fingerOffsetFromBlockOrigin.width,
            y: currentTouchLocation.y - fingerOffsetFromBlockOrigin.height
        )
    }

    /// Get the finger's offset within the block (normalized to grid cell size)
    /// - Parameter gridCellSize: The target cell size on the grid
    /// - Returns: The offset scaled to grid coordinates
    func getScaledFingerOffset(gridCellSize: CGFloat) -> CGSize {
        guard trayCellSize > 0, gridCellSize > 0 else {
            return fingerOffsetFromBlockOrigin
        }

        let scale = gridCellSize / trayCellSize

        return CGSize(
            width: fingerOffsetFromBlockOrigin.width * scale,
            height: fingerOffsetFromBlockOrigin.height * scale
        )
    }

    /// Check if a specific block is being dragged
    func isBlockDragged(_ index: Int) -> Bool {
        if case .active(let blockIndex, _) = dragState {
            return blockIndex == index
        }
        return false
    }
}
