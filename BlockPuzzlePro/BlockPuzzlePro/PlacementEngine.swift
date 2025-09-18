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
enum PlacementError {
    case outOfBounds
    case collision
    case invalidPattern
    case noValidPosition
}

// MARK: - Placement Engine

/// Manages block placement validation and collision detection
@MainActor
class PlacementEngine: ObservableObject {
    
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
        
        // Check if all positions are valid
        for position in targetPositions {
            // Check bounds
            if !isValidGridPosition(position) {
                return .invalid(reason: .outOfBounds)
            }
            
            // Check collision with existing blocks
            if !gameEngine.canPlaceAt(position: position) {
                return .invalid(reason: .collision)
            }
        }
        
        return .valid(positions: targetPositions)
    }
    
    /// Convert screen position to grid position
    func screenToGridPosition(
        screenPosition: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) -> GridPosition? {
        // Calculate relative position within grid
        let relativeX = screenPosition.x - gridFrame.minX
        let relativeY = screenPosition.y - gridFrame.minY
        
        // Convert to grid coordinates
        let gridX = Int(relativeX / cellSize)
        let gridY = Int(relativeY / cellSize)
        
        // Validate bounds and return
        return GridPosition(row: gridY, column: gridX)
    }
    
    /// Convert grid position to screen position
    func gridToScreenPosition(
        gridPosition: GridPosition,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) -> CGPoint {
        let screenX = gridFrame.minX + (CGFloat(gridPosition.column) * cellSize) + (cellSize / 2)
        let screenY = gridFrame.minY + (CGFloat(gridPosition.row) * cellSize) + (cellSize / 2)
        
        return CGPoint(x: screenX, y: screenY)
    }
    
    /// Find the best placement position for a block near a target position
    func findBestPlacement(
        for blockPattern: BlockPattern,
        near targetPosition: GridPosition,
        maxDistance: Int = 2
    ) -> GridPosition? {
        // Try exact position first
        if case .valid(_) = validatePlacement(blockPattern: blockPattern, at: targetPosition) {
            return targetPosition
        }
        
        // Search in expanding rings around target position
        for distance in 1...maxDistance {
            for row in (targetPosition.row - distance)...(targetPosition.row + distance) {
                for col in (targetPosition.column - distance)...(targetPosition.column + distance) {
                    // Only check perimeter of current ring
                    if abs(row - targetPosition.row) == distance || 
                       abs(col - targetPosition.column) == distance {
                        
                        if let candidate = GridPosition(row: row, column: col),
                           case .valid(_) = validatePlacement(blockPattern: blockPattern, at: candidate) {
                            return candidate
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Preview Management
    
    /// Update placement preview
    func updatePreview(
        blockPattern: BlockPattern,
        screenPosition: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat
    ) {
        guard let gameEngine = gameEngine else { return }
        
        // Clear existing preview
        gameEngine.clearPreviews()
        previewPositions.removeAll()
        
        // Convert screen position to grid position
        guard let gridPosition = screenToGridPosition(
            screenPosition: screenPosition,
            gridFrame: gridFrame,
            cellSize: cellSize
        ) else {
            isCurrentPreviewValid = false
            return
        }
        
        // Validate placement
        let result = validatePlacement(blockPattern: blockPattern, at: gridPosition)
        
        switch result {
        case .valid(let positions):
            previewPositions = positions
            isCurrentPreviewValid = true
            
            // Set preview on grid
            gameEngine.setPreview(at: positions, color: blockPattern.color)
            
        case .invalid(_):
            isCurrentPreviewValid = false
        }
    }
    
    /// Clear placement preview
    func clearPreview() {
        guard let gameEngine = gameEngine else { return }
        
        gameEngine.clearPreviews()
        previewPositions.removeAll()
        isCurrentPreviewValid = false
    }
    
    /// Get valid placement zones for highlighting
    func getValidPlacementZones(for blockPattern: BlockPattern) -> [GridPosition] {
        guard let gameEngine = gameEngine else { return [] }
        
        var validPositions: [GridPosition] = []
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if let gridPos = GridPosition(row: row, column: col),
                   case .valid(_) = validatePlacement(blockPattern: blockPattern, at: gridPos) {
                    validPositions.append(gridPos)
                }
            }
        }
        
        return validPositions
    }
    
    // MARK: - Block Placement
    
    /// Attempt to place a block at the current preview position
    func commitPlacement(blockPattern: BlockPattern) -> Bool {
        guard let gameEngine = gameEngine,
              isCurrentPreviewValid,
              !previewPositions.isEmpty else {
            logger.warning("Cannot commit placement: invalid preview state")
            return false
        }
        
        // Place blocks on grid
        let success = gameEngine.placeBlocks(at: previewPositions, color: blockPattern.color)
        
        if success {
            logger.info("Successfully placed \(blockPattern.type.displayName) at \(previewPositions.count) positions")
            
            // Clear preview after successful placement
            clearPreview()
            
            // Process any completed lines
            let completedLines = gameEngine.processCompletedLines()
            if completedLines > 0 {
                logger.info("Cleared \(completedLines) completed lines")
            }
        } else {
            logger.error("Failed to place block")
        }
        
        return success
    }
    
    // MARK: - Helper Methods
    
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
    
    // MARK: - Collision Detection Algorithms
    
    /// Advanced collision detection with optimization for complex blocks
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
            // Check bounds
            if !isValidGridPosition(position) {
                conflictPositions.append(position)
                continue
            }
            
            // Check collision
            if !gameEngine.canPlaceAt(position: position) {
                conflictPositions.append(position)
            }
        }
        
        return (conflictPositions.isEmpty, conflictPositions)
    }
    
    /// Check if two block patterns would collide
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
    
    /// Get suggested placement positions for a block
    func getSuggestedPlacements(
        for blockPattern: BlockPattern,
        limit: Int = 5
    ) -> [GridPosition] {
        var suggestions: [GridPosition] = []
        
        // Start from top-left and work across
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if let gridPos = GridPosition(row: row, column: col),
                   case .valid(_) = validatePlacement(blockPattern: blockPattern, at: gridPos) {
                    suggestions.append(gridPos)
                    
                    if suggestions.count >= limit {
                        return suggestions
                    }
                }
            }
        }
        
        return suggestions
    }
    
    /// Calculate placement score for optimization
    func calculatePlacementScore(
        blockPattern: BlockPattern,
        at gridPosition: GridPosition
    ) -> Int {
        guard case .valid(let positions) = validatePlacement(blockPattern: blockPattern, at: gridPosition) else {
            return -1
        }
        
        var score = 0
        
        // Bonus for completing lines
        score += calculateLineCompletionBonus(for: positions)
        
        // Bonus for corner placement (more strategic)
        score += calculateCornerBonus(for: positions)
        
        // Penalty for fragmented placement
        score -= calculateFragmentationPenalty(for: positions)
        
        return score
    }
    
    // MARK: - Scoring Helpers
    
    private func calculateLineCompletionBonus(for positions: [GridPosition]) -> Int {
        guard let gameEngine = gameEngine else { return 0 }
        
        var bonus = 0
        
        // Check rows
        for row in 0..<gridSize {
            let rowPositions = positions.filter { $0.row == row }
            if !rowPositions.isEmpty {
                let occupiedInRow = (0..<gridSize).filter { col in
                    let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                    return gameEngine.cell(at: pos)?.isOccupied == true
                }.count
                
                // Bonus increases as row gets closer to completion
                bonus += (occupiedInRow + rowPositions.count) * 2
            }
        }
        
        // Check columns
        for col in 0..<gridSize {
            let colPositions = positions.filter { $0.column == col }
            if !colPositions.isEmpty {
                let occupiedInCol = (0..<gridSize).filter { row in
                    let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                    return gameEngine.cell(at: pos)?.isOccupied == true
                }.count
                
                // Bonus increases as column gets closer to completion
                bonus += (occupiedInCol + colPositions.count) * 2
            }
        }
        
        return bonus
    }
    
    private func calculateCornerBonus(for positions: [GridPosition]) -> Int {
        let corners = [
            (0, 0), (0, gridSize-1),
            (gridSize-1, 0), (gridSize-1, gridSize-1)
        ]
        
        let cornerBonus = positions.filter { pos in
            corners.contains { corner in
                corner.0 == pos.row && corner.1 == pos.column
            }
        }.count * 5
        
        return cornerBonus
    }
    
    private func calculateFragmentationPenalty(for positions: [GridPosition]) -> Int {
        guard let gameEngine = gameEngine else { return 0 }
        
        var penalty = 0
        
        for position in positions {
            let neighbors = [
                GridPosition(row: position.row - 1, column: position.column),
                GridPosition(row: position.row + 1, column: position.column),
                GridPosition(row: position.row, column: position.column - 1),
                GridPosition(row: position.row, column: position.column + 1)
            ].compactMap { $0 }
            
            let occupiedNeighbors = neighbors.filter { neighbor in
                gameEngine.cell(at: neighbor)?.isOccupied == true
            }.count
            
            // Penalty for isolated placement
            if occupiedNeighbors == 0 {
                penalty += 3
            }
        }
        
        return penalty
    }
}