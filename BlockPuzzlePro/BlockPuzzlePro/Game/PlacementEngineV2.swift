import Foundation
import CoreGraphics
import os.log

// MARK: - Placement Engine V2 - Completely Rewritten

/// Simplified placement engine with crystal-clear coordinate math
@MainActor
final class PlacementEngineV2: ObservableObject {

    // MARK: - Published State

    @Published private(set) var previewPositions: [GridPosition] = []
    @Published private(set) var isPreviewValid: Bool = false

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "PlacementEngineV2")
    private weak var gameEngine: GameEngine?

    private var gridSize: Int {
        gameEngine?.gridSize ?? 10
    }

    // MARK: - Initialization

    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
    }

    // MARK: - Core Placement Logic

    /// Update the placement preview based on finger position
    /// - Parameters:
    ///   - pattern: The block pattern being placed
    ///   - blockOrigin: The block's top-left corner in screen coordinates
    ///   - fingerOffset: Where the finger is relative to the block's top-left (in grid cell units)
    ///   - gridFrame: The grid's frame in screen coordinates
    ///   - gridCellSize: The size of one grid cell in screen points
    func updatePreview(
        pattern: BlockPattern,
        blockOrigin: CGPoint,
        fingerOffset: CGSize,
        gridFrame: CGRect,
        gridCellSize: CGFloat
    ) {
        // Clear previous preview
        gameEngine?.clearPreviews()
        previewPositions = []
        isPreviewValid = false

        // Calculate which grid cell the finger is over
        guard let fingerGridPosition = screenToGrid(
            screenPoint: CGPoint(
                x: blockOrigin.x + fingerOffset.width,
                y: blockOrigin.y + fingerOffset.height
            ),
            gridFrame: gridFrame,
            cellSize: gridCellSize
        ) else {
            logger.debug("Finger is outside grid bounds")
            return
        }

        logger.debug("Finger at grid position: \(fingerGridPosition)")

        // Calculate which cell within the pattern the finger corresponds to
        let patternCellX = Int(fingerOffset.width / gridCellSize)
        let patternCellY = Int(fingerOffset.height / gridCellSize)

        logger.debug("Finger is over pattern cell: (\(patternCellX), \(patternCellY))")

        // Calculate the pattern's top-left grid position
        // This is where the pattern needs to be placed so that the finger is over the correct cell
        let patternGridX = fingerGridPosition.column - patternCellX
        let patternGridY = fingerGridPosition.row - patternCellY

        guard let basePosition = GridPosition(row: patternGridY, column: patternGridX, gridSize: gridSize) else {
            logger.debug("Calculated base position out of bounds: (\(patternGridY), \(patternGridX))")
            return
        }

        logger.debug("Pattern base position: \(basePosition)")

        // Calculate all cells this pattern would occupy
        let targetPositions = calculateOccupiedCells(pattern: pattern, at: basePosition)

        // Check if all cells are valid and available
        let allValid = targetPositions.allSatisfy { position in
            isValidPosition(position) && canPlace(at: position)
        }

        if allValid {
            previewPositions = targetPositions
            isPreviewValid = true
            gameEngine?.setPreview(at: targetPositions, color: pattern.color)
            logger.debug("✅ Valid preview at \(basePosition) with \(targetPositions.count) cells")
        } else {
            logger.debug("❌ Invalid placement - collision or out of bounds")
        }
    }

    /// Clear the current preview
    func clearPreview() {
        gameEngine?.clearPreviews()
        previewPositions = []
        isPreviewValid = false
    }

    /// Commit the current preview to the grid
    func commitPreview(pattern: BlockPattern) -> Bool {
        guard isPreviewValid, !previewPositions.isEmpty else {
            logger.warning("Cannot commit - invalid preview")
            return false
        }

        guard let gameEngine = gameEngine else { return false }

        // Double-check all positions are still available
        let allAvailable = previewPositions.allSatisfy { gameEngine.canPlaceAt(position: $0) }
        guard allAvailable else {
            logger.warning("Cannot commit - positions no longer available")
            clearPreview()
            return false
        }

        // Place the blocks
        let success = gameEngine.placeBlocks(at: previewPositions, color: pattern.color)

        if success {
            logger.info("✅ Successfully placed \(pattern.type.displayName) at \(previewPositions.count) positions")

            // Process line clears
            let lineClearResult = gameEngine.processCompletedLines()
            if !lineClearResult.isEmpty {
                logger.info("Line clears: \(lineClearResult.totalClearedLines) lines")
            }

            // Apply score
            if let scoreEvent = gameEngine.applyScore(placedCells: previewPositions.count, lineClearResult: lineClearResult) {
                logger.info("Score: +\(scoreEvent.totalDelta) -> \(scoreEvent.newTotal)")
            }

            clearPreview()
            return true
        } else {
            logger.error("Failed to place blocks - should not happen after validation")
            clearPreview()
            return false
        }
    }

    // MARK: - Helper Methods

    /// Convert screen coordinates to grid position
    private func screenToGrid(
        screenPoint: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) -> GridPosition? {
        // Calculate relative position within the grid
        let relativeX = screenPoint.x - gridFrame.minX
        let relativeY = screenPoint.y - gridFrame.minY

        guard relativeX >= 0, relativeY >= 0 else { return nil }

        // Convert to grid coordinates
        let column = Int(relativeX / cellSize)
        let row = Int(relativeY / cellSize)

        return GridPosition(row: row, column: column, gridSize: gridSize)
    }

    /// Calculate which grid cells a pattern occupies
    private func calculateOccupiedCells(
        pattern: BlockPattern,
        at basePosition: GridPosition
    ) -> [GridPosition] {
        var positions: [GridPosition] = []

        for cellPosition in pattern.occupiedPositions {
            let targetRow = basePosition.row + Int(cellPosition.y)
            let targetCol = basePosition.column + Int(cellPosition.x)

            if let gridPos = GridPosition(row: targetRow, column: targetCol, gridSize: gridSize) {
                positions.append(gridPos)
            }
        }

        return positions
    }

    /// Check if a grid position is within bounds
    private func isValidPosition(_ position: GridPosition) -> Bool {
        return position.row >= 0 && position.row < gridSize &&
               position.column >= 0 && position.column < gridSize
    }

    /// Check if a position can be placed on
    private func canPlace(at position: GridPosition) -> Bool {
        guard let gameEngine = gameEngine else { return false }
        return gameEngine.canPlaceAt(position: position)
    }
}
