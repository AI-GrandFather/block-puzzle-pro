//
//  SimplifiedPlacementEngine.swift
//  BlockPuzzlePro
//
//  Created on October 3, 2025
//  Purpose: Simplified placement validation with direct coordinate math
//  Target: ~150 lines (vs 500+ in original)
//

import SwiftUI
import os.log

/// Simplified placement engine - validates block placements
@MainActor
class SimplifiedPlacementEngine: ObservableObject {

    // MARK: - Published Properties

    /// Positions to preview (for ghost display)
    @Published private(set) var previewPositions: [GridPosition] = []

    /// Whether current preview is valid
    @Published private(set) var isCurrentPreviewValid: Bool = false

    /// Predicted line clears for current preview
    @Published private(set) var predictedLineClears: [LineClear.Kind] = []

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.blockpuzzlepro", category: "SimplifiedPlacementEngine")
    private weak var gameEngine: GameEngine?
    private let gridSize: Int

    // MARK: - Initialization

    init(gameEngine: GameEngine, gridSize: Int) {
        self.gameEngine = gameEngine
        self.gridSize = gridSize
    }

    // MARK: - Preview Management

    /// Update placement preview
    /// - Parameters:
    ///   - blockPattern: Pattern being dragged
    ///   - touchLocation: Current finger position (screen coords)
    ///   - gridFrame: Grid's frame (screen coords)
    ///   - cellSize: Grid cell size
    func updatePreview(
        blockPattern: BlockPattern,
        touchLocation: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) {
        // Convert touch to grid cell
        guard let gridCell = screenToGridCell(
            touchLocation: touchLocation,
            gridFrame: gridFrame,
            cellSize: cellSize
        ) else {
            clearPreview()
            return
        }

        // Create grid position
        guard let gridPosition = GridPosition(
            row: gridCell.row,
            column: gridCell.column,
            gridSize: gridSize
        ) else {
            clearPreview()
            return
        }

        // Calculate target positions for this pattern
        let targetPositions = blockPattern.getGridPositions(placedAt: gridPosition)

        // Validate all positions
        let allValid = targetPositions.allSatisfy { position in
            gameEngine?.canPlaceAt(position: position) ?? false
        }

        // Update preview
        previewPositions = targetPositions
        isCurrentPreviewValid = allValid

        // Predict line clears if valid
        if allValid {
            predictedLineClears = gameEngine?.predictedLineClears(for: targetPositions) ?? []
        } else {
            predictedLineClears = []
        }

        // Update game engine preview cells
        if allValid {
            gameEngine?.setPreview(at: targetPositions, color: blockPattern.defaultColor)
        } else {
            gameEngine?.clearPreviews()
        }

        logger.debug("Preview updated: \(targetPositions.count) cells, valid: \(allValid)")
    }

    /// Clear current preview
    func clearPreview() {
        previewPositions = []
        isCurrentPreviewValid = false
        predictedLineClears = []
        gameEngine?.clearPreviews()
    }

    // MARK: - Placement Validation

    /// Validate if block can be placed at grid position
    /// - Parameters:
    ///   - blockPattern: Pattern to place
    ///   - gridPosition: Target grid position
    /// - Returns: True if placement is valid
    func canPlace(
        blockPattern: BlockPattern,
        at gridPosition: GridPosition
    ) -> Bool {
        guard let gameEngine = gameEngine else { return false }

        let targetPositions = blockPattern.getGridPositions(placedAt: gridPosition)

        return targetPositions.allSatisfy { position in
            gameEngine.canPlaceAt(position: position)
        }
    }

    /// Place block at current preview position
    /// - Parameter blockPattern: Pattern to place
    /// - Returns: True if placement succeeded
    @discardableResult
    func placeAtPreview(blockPattern: BlockPattern) -> Bool {
        guard isCurrentPreviewValid, !previewPositions.isEmpty else {
            logger.warning("Cannot place: invalid preview")
            return false
        }

        guard let gameEngine = gameEngine else { return false }

        // Place blocks
        let success = gameEngine.placeBlocks(
            at: previewPositions,
            color: blockPattern.defaultColor
        )

        if success {
            logger.info("Placed block at \(self.previewPositions.count) positions")

            // Process line clears
            let clearResult = gameEngine.processCompletedLines()

            // Apply scoring
            gameEngine.applyScore(
                placedCells: previewPositions.count,
                lineClearResult: clearResult
            )
        }

        // Clear preview
        clearPreview()

        return success
    }

    // MARK: - Coordinate Conversion

    /// Convert screen position to grid cell (same logic as controller)
    private func screenToGridCell(
        touchLocation: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) -> (row: Int, column: Int)? {
        let relativeX = touchLocation.x - gridFrame.minX
        let relativeY = touchLocation.y - gridFrame.minY

        guard relativeX >= 0, relativeY >= 0,
              relativeX < gridFrame.width,
              relativeY < gridFrame.height else {
            return nil
        }

        let column = Int(relativeX / cellSize)
        let row = Int(relativeY / cellSize)

        guard row >= 0, row < gridSize, column >= 0, column < gridSize else {
            return nil
        }

        return (row: row, column: column)
    }

    /// Convert grid position to screen position
    func gridToScreenPosition(
        gridPosition: GridPosition,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat = 0
    ) -> CGPoint {
        let x = gridFrame.minX + (CGFloat(gridPosition.column) * (cellSize + gridSpacing))
        let y = gridFrame.minY + (CGFloat(gridPosition.row) * (cellSize + gridSpacing))

        return CGPoint(x: x, y: y)
    }
}
