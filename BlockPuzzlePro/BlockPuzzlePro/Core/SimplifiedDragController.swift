//
//  SimplifiedDragController.swift
//  BlockPuzzlePro
//
//  Created on October 3, 2025
//  Purpose: Simplified drag & drop controller with pixel-perfect coordinate math
//  Target: 250-300 lines (vs 641 in original)
//

import SwiftUI
import Combine
import os.log

/// Simplified drag state - only 2 states needed
enum SimplifiedDragState: Equatable {
    case idle
    case dragging(blockIndex: Int, pattern: BlockPattern)
}

extension SimplifiedDragState {
    static func ==(lhs: SimplifiedDragState, rhs: SimplifiedDragState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case let (.dragging(lIndex, lPattern), .dragging(rIndex, rPattern)):
            return lIndex == rIndex && lPattern.type == rPattern.type
        default:
            return false
        }
    }
}

/// Manages drag & drop interactions with simplified coordinate system
@MainActor
class SimplifiedDragController: ObservableObject {

    // MARK: - Published Properties

    /// Current drag state (2 states only)
    @Published private(set) var dragState: SimplifiedDragState = .idle

    /// Current touch location in screen coordinates
    @Published private(set) var currentTouchLocation: CGPoint = .zero

    /// Current block origin in screen coordinates
    @Published private(set) var currentBlockOrigin: CGPoint = .zero

    /// Visual scale (for lift animation)
    @Published var dragScale: CGFloat = 1.0

    /// Shadow properties (visual only)
    @Published var shadowOpacity: Double = 0.0
    @Published var shadowRadius: CGFloat = 0.0
    @Published var shadowOffset: CGSize = .zero

    /// Optional rotation (cosmetic)
    @Published var dragRotation: Angle = .zero

    /// Whether block should return to tray
    @Published private(set) var shouldReturnToTray: Bool = false

    /// Position to return to when invalid placement
    @Published private(set) var returnToTrayPosition: CGPoint = .zero

    // MARK: - Private Properties

    /// Finger offset from block origin (CONSTANT during drag)
    private(set) var fingerOffset: CGSize = .zero

    /// Logger for debugging
    private let logger = Logger(subsystem: "com.blockpuzzlepro", category: "SimplifiedDragController")

    /// Device manager for haptics
    private weak var deviceManager: DeviceManager?

    /// ProMotion display detection
    private let isProMotionDisplay: Bool

    // MARK: - Initialization

    init(deviceManager: DeviceManager? = nil) {
        self.deviceManager = deviceManager

        // Detect ProMotion capability
        let displayInfo = FrameRateConfigurator.currentDisplayInfo()
        self.isProMotionDisplay = Double(displayInfo.maxRefreshRate) >= 120.0

        logger.info("SimplifiedDragController initialized (ProMotion: \(self.isProMotionDisplay))")
    }

    // MARK: - Public API

    /// Check if controller is idle
    var isIdle: Bool {
        if case .idle = dragState {
            return true
        }
        return false
    }

    /// Check if currently dragging
    var isDragging: Bool {
        if case .dragging = dragState {
            return true
        }
        return false
    }

    /// Get currently dragged block pattern
    var draggedBlockPattern: BlockPattern? {
        if case .dragging(_, let pattern) = dragState {
            return pattern
        }
        return nil
    }

    /// Get currently dragged block index
    var draggedBlockIndex: Int? {
        if case .dragging(let index, _) = dragState {
            return index
        }
        return nil
    }

    // MARK: - Drag Lifecycle

    /// Start dragging a block
    /// - Parameters:
    ///   - blockIndex: Index of block in tray
    ///   - pattern: Block pattern being dragged
    ///   - touchLocation: Where user touched (screen coords)
    ///   - blockOrigin: Top-left of block (screen coords)
    func startDrag(
        blockIndex: Int,
        pattern: BlockPattern,
        touchLocation: CGPoint,
        blockOrigin: CGPoint
    ) {
        // TRANSFORM #1: Calculate finger offset (ONCE, CONSTANT)
        fingerOffset = CGSize(
            width: touchLocation.x - blockOrigin.x,
            height: touchLocation.y - blockOrigin.y
        )

        // Set initial positions
        currentTouchLocation = touchLocation
        currentBlockOrigin = blockOrigin
        returnToTrayPosition = blockOrigin  // Save for potential return
        shouldReturnToTray = false

        // Update state
        dragState = .dragging(blockIndex: blockIndex, pattern: pattern)

        // Lift animation (visual only, doesn't affect coordinates)
        let springResponse = isProMotionDisplay ? 0.15 : 0.2
        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: 0.8)) {
            dragScale = 1.3
            shadowOpacity = 0.3
            shadowRadius = 8.0
            shadowOffset = CGSize(width: 2, height: 4)
        }

        // Haptic feedback
        deviceManager?.provideHapticFeedback(style: .light)

        logger.debug("Drag started: block \(blockIndex), offset (\(self.fingerOffset.width), \(self.fingerOffset.height))")
    }

    /// Update drag position
    /// - Parameter touchLocation: Current finger position (screen coords)
    func updateDrag(to touchLocation: CGPoint) {
        guard isDragging else {
            logger.warning("updateDrag called but not dragging")
            return
        }

        // Update touch location
        currentTouchLocation = touchLocation

        // TRANSFORM #2: Calculate block origin (touch - offset)
        currentBlockOrigin = CGPoint(
            x: touchLocation.x - fingerOffset.width,
            y: touchLocation.y - fingerOffset.height
        )
    }

    /// End drag
    /// - Parameter touchLocation: Where user released (screen coords)
    func endDrag(at touchLocation: CGPoint) {
        guard isDragging else {
            logger.warning("endDrag called but not dragging")
            return
        }

        currentTouchLocation = touchLocation

        logger.debug("Drag ended at (\(touchLocation.x), \(touchLocation.y))")

        // State will be updated by caller after placement validation
        // Don't reset here - let animation complete first
    }

    /// Complete placement successfully
    /// - Parameter snapPosition: Final grid position to snap to
    func completePlacement(snapToPosition snapPosition: CGPoint) {
        let springResponse = isProMotionDisplay ? 0.2 : 0.25

        // Animate to snap position
        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: 0.9)) {
            currentBlockOrigin = snapPosition
            dragScale = 1.0
            shadowOpacity = 0.0
            shadowRadius = 0.0
            shadowOffset = .zero
        }

        // Success haptic
        deviceManager?.provideHapticFeedback(style: .medium)

        // Reset state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.reset()
        }

        logger.info("Placement completed successfully")
    }

    /// Reject placement and return to tray
    func returnToTray() {
        shouldReturnToTray = true

        // Animate back to tray
        let springResponse = isProMotionDisplay ? 0.25 : 0.3
        withAnimation(.interactiveSpring(response: springResponse, dampingFraction: 0.8)) {
            currentBlockOrigin = returnToTrayPosition
            dragScale = 1.0
            shadowOpacity = 0.0
            shadowRadius = 0.0
            shadowOffset = .zero
        }

        // Error haptic
        deviceManager?.provideNotificationFeedback(type: .error)

        // Reset state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.reset()
        }

        logger.info("Block returned to tray")
    }

    /// Reset to idle state
    func reset() {
        dragState = .idle
        currentTouchLocation = .zero
        currentBlockOrigin = .zero
        fingerOffset = .zero
        shouldReturnToTray = false
        dragScale = 1.0
        shadowOpacity = 0.0
        shadowRadius = 0.0
        shadowOffset = .zero
        dragRotation = .zero
    }

    // MARK: - Coordinate Conversions

    /// Convert screen position to grid cell
    /// - Parameters:
    ///   - touchLocation: Touch position in screen coords
    ///   - gridFrame: Grid's frame in screen coords
    ///   - cellSize: Size of one grid cell
    /// - Returns: Grid cell (row, column) or nil if outside grid
    func getGridCell(
        touchLocation: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) -> (row: Int, column: Int)? {
        // TRANSFORM #3: Screen to grid cell (direct conversion)

        let relativeX = touchLocation.x - gridFrame.minX
        let relativeY = touchLocation.y - gridFrame.minY

        // Check if inside grid bounds
        guard relativeX >= 0, relativeY >= 0,
              relativeX < gridFrame.width,
              relativeY < gridFrame.height else {
            return nil
        }

        // Convert to cell indices
        let column = Int(relativeX / cellSize)
        let row = Int(relativeY / cellSize)

        // Clamp to grid size (safety check)
        let gridSize = Int(gridFrame.width / cellSize)
        guard row >= 0, row < gridSize, column >= 0, column < gridSize else {
            return nil
        }

        return (row: row, column: column)
    }

    /// Convert grid cell to screen position
    /// - Parameters:
    ///   - row: Grid row
    ///   - column: Grid column
    ///   - gridFrame: Grid's frame in screen coords
    ///   - cellSize: Size of one grid cell
    /// - Returns: Screen position (top-left of cell)
    func gridCellToScreen(
        row: Int,
        column: Int,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) -> CGPoint {
        // TRANSFORM #4: Grid cell to screen position

        let x = gridFrame.minX + (CGFloat(column) * cellSize)
        let y = gridFrame.minY + (CGFloat(row) * cellSize)

        return CGPoint(x: x, y: y)
    }

    // MARK: - Vicinity Touch

    /// Check if touch is within vicinity radius of block center
    /// - Parameters:
    ///   - touchLocation: Where user touched
    ///   - blockCenter: Center of block
    ///   - vicinityRadius: Expanded touch radius (default: 80pt)
    /// - Returns: True if touch should select block
    func shouldSelectBlock(
        touchLocation: CGPoint,
        blockCenter: CGPoint,
        vicinityRadius: CGFloat = 80.0
    ) -> Bool {
        let distance = hypot(
            touchLocation.x - blockCenter.x,
            touchLocation.y - blockCenter.y
        )

        return distance <= vicinityRadius
    }

    /// Alternative vicinity check using expanded frame
    /// - Parameters:
    ///   - touchLocation: Where user touched
    ///   - blockFrame: Visual bounds of block
    ///   - vicinityRadius: Expanded touch radius (default: 80pt)
    /// - Returns: True if touch should select block
    func shouldSelectBlockByFrame(
        touchLocation: CGPoint,
        blockFrame: CGRect,
        vicinityRadius: CGFloat = 80.0
    ) -> Bool {
        let expandedFrame = blockFrame.insetBy(
            dx: -vicinityRadius,
            dy: -vicinityRadius
        )

        return expandedFrame.contains(touchLocation)
    }
}
