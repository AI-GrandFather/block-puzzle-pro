import Foundation
import CoreGraphics
import os.log

// MARK: - Placement Result

/// Result of a block placement attempt
enum PlacementResult {
    case valid(positions: [GridPosition])
    case invalid(reason: PlacementError)
}

/// Reasons why a placement might be invalid
enum PlacementError: Equatable {
    case outOfBounds
    case collision
    case invalidPattern
    case noValidPosition
}

extension PlacementError: CustomStringConvertible {
    var description: String {
        switch self {
        case .outOfBounds:
            return "outOfBounds"
        case .collision:
            return "collision"
        case .invalidPattern:
            return "invalidPattern"
        case .noValidPosition:
            return "noValidPosition"
        }
    }
}

// MARK: - Placement Engine

/// Manages block placement validation and collision detection
@MainActor
final class PlacementEngine: ObservableObject {

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "PlacementEngine")

    /// Reference to the game engine for grid state
    private weak var gameEngine: GameEngine?

    /// Current placement preview positions
    @Published private(set) var previewPositions: [GridPosition] = []

    /// Whether current preview is valid
    @Published private(set) var isCurrentPreviewValid: Bool = false

    /// Grid size constant
    private let gridSize = GameEngine.gridSize

    /// Cached last base grid position calculated from drag
    private var lastBaseGridPosition: GridPosition?

    // MARK: - Initialization

    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
    }

    // MARK: - Placement Validation

    /// Validate if a block pattern can be placed at a specific grid position
    func validatePlacement(
        blockPattern: BlockPattern,
        at gridPosition: GridPosition
    ) -> PlacementResult {
        guard let gameEngine = gameEngine else {
            return .invalid(reason: .invalidPattern)
        }

        let targetPositions = calculateTargetPositions(
            for: blockPattern,
            at: gridPosition
        )

        for position in targetPositions {
            if !isValidGridPosition(position) {
                return .invalid(reason: .outOfBounds)
            }

            if !gameEngine.canPlaceAt(position: position) {
                return .invalid(reason: .collision)
            }
        }

        return .valid(positions: targetPositions)
    }

    /// Convert a screen coordinate to the grid position whose top-left cell contains it
    func screenToGridPosition(
        screenPosition: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat = 0
    ) -> GridPosition? {
        let originX = gridFrame.minX + gridSpacing
        let originY = gridFrame.minY + gridSpacing
        let cellSpan = cellSize + gridSpacing

        let relativeX = screenPosition.x - originX
        let relativeY = screenPosition.y - originY

        guard relativeX >= 0, relativeY >= 0 else { return nil }

        let tolerance: CGFloat = 0.0001
        let adjustedX = max(relativeX - tolerance, 0)
        let adjustedY = max(relativeY - tolerance, 0)

        let column = Int(floor(adjustedX / cellSpan))
        let row = Int(floor(adjustedY / cellSpan))

        guard column >= 0, row >= 0, column < gridSize, row < gridSize else { return nil }

        return GridPosition(row: row, column: column)
    }

    /// Convert grid position to screen position (cell centre)
    func gridToScreenPosition(
        gridPosition: GridPosition,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat = 0
    ) -> CGPoint {
        let originX = gridFrame.minX + gridSpacing
        let originY = gridFrame.minY + gridSpacing
        let cellSpan = cellSize + gridSpacing

        let screenX = originX + (CGFloat(gridPosition.column) * cellSpan) + (cellSize / 2)
        let screenY = originY + (CGFloat(gridPosition.row) * cellSpan) + (cellSize / 2)

        return CGPoint(x: screenX, y: screenY)
    }

    /// Find the best placement position for a block near a target position
    func findBestPlacement(
        for blockPattern: BlockPattern,
        near targetPosition: GridPosition,
        maxDistance: Int = 2
    ) -> GridPosition? {
        if case .valid = validatePlacement(blockPattern: blockPattern, at: targetPosition) {
            return targetPosition
        }

        for distance in 1...maxDistance {
            for row in (targetPosition.row - distance)...(targetPosition.row + distance) {
                for col in (targetPosition.column - distance)...(targetPosition.column + distance) {
                    if abs(row - targetPosition.row) == distance ||
                        abs(col - targetPosition.column) == distance {
                        if let candidate = GridPosition(row: row, column: col),
                           case .valid = validatePlacement(blockPattern: blockPattern, at: candidate) {
                            return candidate
                        }
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Preview Management

    /// Update placement preview using a raw screen position (typically the centre of the first cell)
    func updatePreview(
        blockPattern: BlockPattern,
        screenPosition: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat = 0
    ) {
        let origin = CGPoint(
            x: screenPosition.x - (cellSize / 2),
            y: screenPosition.y - (cellSize / 2)
        )

        updatePreview(
            blockPattern: blockPattern,
            blockOrigin: origin,
            touchPoint: screenPosition,
            touchOffset: .zero,
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSpacing: gridSpacing
        )
    }

    /// Update preview using the dragged block's top-left origin
    func updatePreview(
        blockPattern: BlockPattern,
        blockOrigin: CGPoint,
        touchPoint: CGPoint,
        touchOffset: CGSize,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat
    ) {
        guard let gameEngine = gameEngine else { return }

        gameEngine.clearPreviews()
        previewPositions.removeAll()
        isCurrentPreviewValid = false

        guard let baseGridPosition = projectedBaseGridPosition(
            for: blockPattern,
            blockOrigin: blockOrigin,
            touchPoint: touchPoint,
            touchOffset: touchOffset,
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSpacing: gridSpacing
        ) else {
            logger.debug("Preview rejected: origin=(\(blockOrigin.x), \(blockOrigin.y)), touch=(\(touchPoint.x), \(touchPoint.y)), frame=(\(gridFrame.origin.x), \(gridFrame.origin.y), \(gridFrame.size.width), \(gridFrame.size.height))")
            lastBaseGridPosition = nil
            return
        }

        lastBaseGridPosition = baseGridPosition

        switch validatePlacement(blockPattern: blockPattern, at: baseGridPosition) {
        case .valid(let positions):
            previewPositions = positions
            isCurrentPreviewValid = true
            gameEngine.setPreview(at: positions, color: blockPattern.color)
        case .invalid(let reason):
            isCurrentPreviewValid = false
            logger.debug("Placement invalid: reason=\(reason) origin=(\(blockOrigin.x), \(blockOrigin.y)) base=\(baseGridPosition)")
        }
    }

    /// Clear placement preview
    func clearPreview() {
        guard let gameEngine = gameEngine else { return }

        gameEngine.clearPreviews()
        previewPositions.removeAll()
        isCurrentPreviewValid = false
        lastBaseGridPosition = nil
    }

    /// Attempt to place a block at the current preview position
    func commitPlacement(blockPattern: BlockPattern) -> Bool {
        guard let gameEngine = gameEngine,
              isCurrentPreviewValid,
              !previewPositions.isEmpty else {
            logger.warning("Cannot commit placement: invalid preview state")
            clearPreview()
            return false
        }

        // Double-check that all preview positions are still available
        // This prevents race conditions between preview validation and commit
        for position in previewPositions {
            if !gameEngine.canPlaceAt(position: position) {
                logger.warning("Cannot commit placement: position \(position) is no longer available")
                clearPreview()
                return false
            }
        }

        let success = gameEngine.placeBlocks(at: previewPositions, color: blockPattern.color)

        if success {
            logger.info("Successfully placed \(blockPattern.type.displayName) at \(self.previewPositions.count) positions")
            let completedLines = gameEngine.processCompletedLines()
            if completedLines > 0 {
                logger.info("Cleared \(completedLines) completed lines")
            }
        } else {
            logger.error("Failed to place block at positions: \(self.previewPositions) - this should not happen after validation")
        }

        // Always clear preview regardless of success/failure to prevent stuck green outlines
        clearPreview()

        return success
    }

    // MARK: - Helper Methods

    private func projectedBaseGridPosition(
        for blockPattern: BlockPattern,
        blockOrigin: CGPoint,
        touchPoint: CGPoint,
        touchOffset: CGSize,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat
    ) -> GridPosition? {
        let cellSpan = cellSize + gridSpacing
        let originX = gridFrame.minX + gridSpacing
        let originY = gridFrame.minY + gridSpacing

        let candidateOriginX = touchPoint.x - touchOffset.width
        let candidateOriginY = touchPoint.y - touchOffset.height

        let blockOriginX = candidateOriginX.isFinite ? candidateOriginX : blockOrigin.x
        let blockOriginY = candidateOriginY.isFinite ? candidateOriginY : blockOrigin.y

        let adjustedX = blockOriginX - originX + (cellSpan / 2)
        let adjustedY = blockOriginY - originY + (cellSpan / 2)

        guard adjustedX >= 0, adjustedY >= 0 else { return nil }

        let column = Int(floor(adjustedX / cellSpan))
        let row = Int(floor(adjustedY / cellSpan))

        guard column >= 0, row >= 0, column < gridSize, row < gridSize else { return nil }

        let patternHeight = Int(ceil(blockPattern.size.height))
        let patternWidth = Int(ceil(blockPattern.size.width))
        let maxRow = row + patternHeight - 1
        let maxColumn = column + patternWidth - 1

        guard maxRow < gridSize, maxColumn < gridSize else {
            logger.debug("Projected origin out of bounds: origin=(\(blockOriginX), \(blockOriginY)) row=\(row) col=\(column) maxRow=\(maxRow) maxCol=\(maxColumn)")
            return nil
        }

        return GridPosition(row: row, column: column)
    }


    /// Calculate target positions for a block pattern at a grid position
    private func calculateTargetPositions(
        for blockPattern: BlockPattern,
        at gridPosition: GridPosition
    ) -> [GridPosition] {
        var positions: [GridPosition] = []

        for cellPosition in blockPattern.occupiedPositions {
            let targetRow = gridPosition.row + Int(cellPosition.y)
            let targetCol = gridPosition.column + Int(cellPosition.x)

            if let targetGridPos = GridPosition(row: targetRow, column: targetCol) {
                positions.append(targetGridPos)
            }
        }

        return positions
    }

    /// Check if a grid position is valid (within bounds)
    private func isValidGridPosition(_ position: GridPosition) -> Bool {
        return position.row >= 0 && position.row < gridSize &&
            position.column >= 0 && position.column < gridSize
    }

    // MARK: - Placement Suggestions

    func getValidPlacementZones(for blockPattern: BlockPattern) -> [GridPosition] {
        guard gameEngine != nil else { return [] }

        var validPositions: [GridPosition] = []

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if let gridPos = GridPosition(row: row, column: col),
                   case .valid = validatePlacement(blockPattern: blockPattern, at: gridPos) {
                    validPositions.append(gridPos)
                }
            }
        }

        return validPositions
    }

    // MARK: - Collision Detection Algorithms

    func advancedCollisionDetection(
        blockPattern: BlockPattern,
        at gridPosition: GridPosition
    ) -> (isValid: Bool, conflictPositions: [GridPosition]) {
        guard let gameEngine = gameEngine else {
            return (false, [])
        }

        var conflictPositions: [GridPosition] = []
        let targetPositions = calculateTargetPositions(for: blockPattern, at: gridPosition)

        for position in targetPositions {
            if !isValidGridPosition(position) || !gameEngine.canPlaceAt(position: position) {
                conflictPositions.append(position)
            }
        }

        return (conflictPositions.isEmpty, conflictPositions)
    }

    func wouldCollide(
        blockPattern1: BlockPattern,
        at position1: GridPosition,
        blockPattern2: BlockPattern,
        at position2: GridPosition
    ) -> Bool {
        let positions1 = Set(calculateTargetPositions(for: blockPattern1, at: position1))
        let positions2 = Set(calculateTargetPositions(for: blockPattern2, at: position2))

        return !positions1.isDisjoint(with: positions2)
    }

    // MARK: - Placement Suggestions

    func getSuggestedPlacements(
        for blockPattern: BlockPattern,
        limit: Int = 5
    ) -> [GridPosition] {
        var suggestions: [GridPosition] = []

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if let gridPos = GridPosition(row: row, column: col),
                   case .valid = validatePlacement(blockPattern: blockPattern, at: gridPos) {
                    suggestions.append(gridPos)
                    if suggestions.count >= limit {
                        return suggestions
                    }
                }
            }
        }

        return suggestions
    }

    func calculatePlacementScore(
        blockPattern: BlockPattern,
        at gridPosition: GridPosition
    ) -> Int {
        guard case .valid(let positions) = validatePlacement(blockPattern: blockPattern, at: gridPosition) else {
            return -1
        }

        var score = 0
        score += calculateLineCompletionBonus(for: positions)
        score += calculateCornerBonus(for: positions)
        score -= calculateFragmentationPenalty(for: positions)
        return score
    }

    // MARK: - Scoring Helpers

    private func calculateLineCompletionBonus(for positions: [GridPosition]) -> Int {
        guard let gameEngine = gameEngine else { return 0 }

        var bonus = 0

        for row in 0..<gridSize {
            let rowPositions = positions.filter { $0.row == row }
            if !rowPositions.isEmpty {
                let occupiedInRow = (0..<gridSize).filter { col in
                    let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                    return gameEngine.cell(at: pos)?.isOccupied == true
                }.count
                bonus += (occupiedInRow + rowPositions.count) * 2
            }
        }

        for col in 0..<gridSize {
            let colPositions = positions.filter { $0.column == col }
            if !colPositions.isEmpty {
                let occupiedInCol = (0..<gridSize).filter { row in
                    let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                    return gameEngine.cell(at: pos)?.isOccupied == true
                }.count
                bonus += (occupiedInCol + colPositions.count) * 2
            }
        }

        return bonus
    }

    private func calculateCornerBonus(for positions: [GridPosition]) -> Int {
        let corners = [
            GridPosition(unsafeRow: 0, unsafeColumn: 0),
            GridPosition(unsafeRow: 0, unsafeColumn: gridSize - 1),
            GridPosition(unsafeRow: gridSize - 1, unsafeColumn: 0),
            GridPosition(unsafeRow: gridSize - 1, unsafeColumn: gridSize - 1)
        ]

        var bonus = 0
        for corner in corners {
            if positions.contains(corner) {
                bonus += 5
            }
        }
        return bonus
    }

    private func calculateFragmentationPenalty(for positions: [GridPosition]) -> Int {
        guard let minRow = positions.map({ $0.row }).min(),
              let maxRow = positions.map({ $0.row }).max(),
              let minCol = positions.map({ $0.column }).min(),
              let maxCol = positions.map({ $0.column }).max() else {
            return 0
        }

        let boundingBoxArea = (maxRow - minRow + 1) * (maxCol - minCol + 1)
        let unusedCells = boundingBoxArea - positions.count
        return unusedCells
    }
}
