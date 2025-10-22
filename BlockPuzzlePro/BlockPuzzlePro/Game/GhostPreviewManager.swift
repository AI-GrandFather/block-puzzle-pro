//
//  GhostPreviewManager.swift
//  BlockPuzzlePro
//
//  Created on October 5, 2025
//  Purpose: Manages ghost preview overlay for drag & drop with real-time validation
//

import SwiftUI
import Combine
import os.log

// MARK: - Placement Validity

/// Validity state of ghost preview placement
enum PlacementValidity: Equatable {
    case valid
    case invalid(reason: InvalidReason)

    enum InvalidReason: Equatable {
        case outOfBounds
        case collision
        case noPosition
    }

    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
}

// MARK: - Ghost Preview State

/// Visual state of the ghost preview
struct GhostPreviewState: Equatable {
    var isVisible: Bool = false
    var position: GridPosition?
    var validity: PlacementValidity = .invalid(reason: .noPosition)
    var blockPattern: BlockPattern?
    var affectedPositions: [GridPosition] = []
    var linesClearPreview: LineClearPreview?
    var scorePreview: ScorePreview?
    var snapPosition: CGPoint?

    static func == (lhs: GhostPreviewState, rhs: GhostPreviewState) -> Bool {
        return lhs.isVisible == rhs.isVisible &&
               lhs.position == rhs.position &&
               lhs.validity == rhs.validity &&
               lhs.affectedPositions == rhs.affectedPositions
    }
}

// MARK: - Line Clear Preview

/// Preview of which lines would be cleared
struct LineClearPreview: Equatable {
    let rows: Set<Int>
    let columns: Set<Int>

    var totalLines: Int {
        rows.count + columns.count
    }

    var hasClears: Bool {
        !rows.isEmpty || !columns.isEmpty
    }
}

// MARK: - Score Preview

/// Preview of score that will be gained
struct ScorePreview: Equatable {
    let placementScore: Int
    let lineClearScore: Int
    let totalScore: Int

    var magnitude: ScoreMagnitude {
        switch totalScore {
        case 0...100:
            return .low
        case 101...500:
            return .medium
        default:
            return .high
        }
    }

    enum ScoreMagnitude {
        case low
        case medium
        case high

        var color: Color {
            switch self {
            case .low:
                return .white
            case .medium:
                return .yellow
            case .high:
                return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .low:
                return 16
            case .medium:
                return 20
            case .high:
                return 24
            }
        }
    }
}

// MARK: - Ghost Preview Settings

/// User preferences for ghost preview
struct GhostPreviewSettings {
    var isEnabled: Bool = true
    var showLineClearPreview: Bool = true
    var showScorePreview: Bool = true
    var snapToGrid: Bool = true
    var ghostOpacity: Double = Double(GameConfig.previewAlpha)
    var snapThreshold: CGFloat = 0.5 // cells

    static let `default` = GhostPreviewSettings()
}

// MARK: - Ghost Preview Manager

/// Manages ghost preview system with real-time validation and visual feedback
@MainActor
@Observable
final class GhostPreviewManager {

    // MARK: - Published Properties

    var previewState: GhostPreviewState = GhostPreviewState()
    var settings: GhostPreviewSettings = .default

    // MARK: - Private Properties

    private weak var placementEngine: PlacementEngine?
    private weak var gameEngine: GameEngine?

    private let logger = Logger(subsystem: "com.blockpuzzlepro", category: "GhostPreviewManager")

    /// Cache for validation results to avoid redundant calculations
    private var validationCache: [String: PlacementValidity] = [:]

    /// ProMotion display detection
    private let isProMotionDisplay: Bool

    // MARK: - Initialization

    init(placementEngine: PlacementEngine?, gameEngine: GameEngine?) {
        self.placementEngine = placementEngine
        self.gameEngine = gameEngine

        // Detect ProMotion capability
        let displayInfo = FrameRateConfigurator.currentDisplayInfo()
        self.isProMotionDisplay = Double(displayInfo.maxRefreshRate) >= 120.0

        logger.info("GhostPreviewManager initialized (ProMotion: \(self.isProMotionDisplay))")
    }

    // MARK: - Public API

    /// Update ghost preview based on current drag position
    /// - Parameters:
    ///   - blockPattern: The block being dragged
    ///   - blockOrigin: Top-left position of block in screen coordinates
    ///   - gridFrame: Grid's frame in screen coordinates
    ///   - cellSize: Size of one grid cell
    ///   - gridSpacing: Spacing between grid cells
    func updatePreview(
        blockPattern: BlockPattern,
        blockOrigin: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat = 0
    ) {
        guard settings.isEnabled else {
            clearPreview()
            return
        }

        // Convert screen position to grid position
        guard let gridPosition = screenToGridPosition(
            screenPosition: blockOrigin,
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSpacing: gridSpacing
        ) else {
            // Outside grid bounds
            updatePreviewState(
                blockPattern: blockPattern,
                position: nil,
                validity: .invalid(reason: .outOfBounds),
                affectedPositions: []
            )
            return
        }

        // Apply snap-to-grid if enabled
        let finalPosition: GridPosition
        if settings.snapToGrid {
            finalPosition = applySnapToGrid(
                currentPosition: gridPosition,
                blockPattern: blockPattern,
                blockOrigin: blockOrigin,
                gridFrame: gridFrame,
                cellSize: cellSize,
                gridSpacing: gridSpacing
            )
        } else {
            finalPosition = gridPosition
        }

        // Validate placement
        var resolvedPosition = finalPosition
        var validity = validatePlacement(blockPattern: blockPattern, at: resolvedPosition)

        // Attempt to assist by snapping to a nearby valid position if we're almost aligned
        if !validity.isValid,
           let snappedPosition = findMagnetSnapPosition(
                from: finalPosition,
                blockPattern: blockPattern,
                blockOrigin: blockOrigin,
                gridFrame: gridFrame,
                cellSize: cellSize,
                gridSpacing: gridSpacing
           ) {
            resolvedPosition = snappedPosition
            validity = validatePlacement(blockPattern: blockPattern, at: snappedPosition)
        }

        // Calculate affected positions
        let affectedPositions = blockPattern.getGridPositions(placedAt: resolvedPosition)

        // Calculate line clear preview if valid
        var lineClearPreview: LineClearPreview?
        var scorePreview: ScorePreview?

        if validity.isValid, let gameEngine = gameEngine {
            lineClearPreview = calculateLineClearPreview(
                positions: affectedPositions,
                gameEngine: gameEngine
            )

            scorePreview = calculateScorePreview(
                blockPattern: blockPattern,
                lineClearPreview: lineClearPreview
            )
        }

        // Calculate snap position for smooth animation
        let snapPosition = gridToScreenPosition(
            gridPosition: resolvedPosition,
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSpacing: gridSpacing
        )

        // Update state
        updatePreviewState(
            blockPattern: blockPattern,
            position: resolvedPosition,
            validity: validity,
            affectedPositions: affectedPositions,
            lineClearPreview: lineClearPreview,
            scorePreview: scorePreview,
            snapPosition: snapPosition
        )
    }

    /// Show ghost preview with fade-in animation
    func showPreview() {
        withAnimation(.easeIn(duration: 0.1)) {
            previewState.isVisible = true
        }
    }

    /// Hide and clear ghost preview
    func clearPreview() {
        withAnimation(.easeOut(duration: 0.1)) {
            previewState.isVisible = false
        }

        // Clear state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.resetPreviewState()
        }

        validationCache.removeAll()
    }

    /// Get ghost preview color based on validity
    func getGhostColor(for pattern: BlockPattern, validity: PlacementValidity) -> Color {
        let baseColor = Color(pattern.color.uiColor)
        let validOpacity = settings.ghostOpacity
        let invalidOpacity = min(validOpacity * 0.6, Double(GameConfig.invalidPreviewAlpha))
        let targetOpacity = validity.isValid ? validOpacity : invalidOpacity

        return baseColor.opacity(targetOpacity)
    }

    // MARK: - Validation

    /// Validate if block can be placed at position
    private func validatePlacement(
        blockPattern: BlockPattern,
        at position: GridPosition
    ) -> PlacementValidity {
        // Check cache first
        let cacheKey = "\(blockPattern.type.rawValue)_\(position.row)_\(position.column)"
        if let cached = validationCache[cacheKey] {
            return cached
        }

        guard let placementEngine = placementEngine else {
            return .invalid(reason: .noPosition)
        }

        // Validate using placement engine
        let result = placementEngine.validatePlacement(blockPattern: blockPattern, at: position)

        let validity: PlacementValidity
        switch result {
        case .valid:
            validity = .valid
        case .invalid(let reason):
            switch reason {
            case .outOfBounds:
                validity = .invalid(reason: .outOfBounds)
            case .collision:
                validity = .invalid(reason: .collision)
            default:
                validity = .invalid(reason: .noPosition)
            }
        }

        // Cache result
        validationCache[cacheKey] = validity

        return validity
    }

    /// Invalidate validation cache when grid changes
    func invalidateCache() {
        validationCache.removeAll()
    }

    // MARK: - Line Clear Preview

    /// Calculate which lines would be cleared
    private func calculateLineClearPreview(
        positions: [GridPosition],
        gameEngine: GameEngine
    ) -> LineClearPreview? {
        guard settings.showLineClearPreview else { return nil }

        let gridSize = gameEngine.gridSize
        var clearedRows = Set<Int>()
        var clearedColumns = Set<Int>()

        // Check rows
        for row in 0..<gridSize {
            let positionsInRow = positions.filter { $0.row == row }
            if !positionsInRow.isEmpty {
                // Count how many cells would be occupied after placement
                var occupiedCount = positionsInRow.count

                for col in 0..<gridSize {
                    let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                    if !positions.contains(pos), gameEngine.cell(at: pos)?.isOccupied == true {
                        occupiedCount += 1
                    }
                }

                if occupiedCount == gridSize {
                    clearedRows.insert(row)
                }
            }
        }

        // Check columns
        for col in 0..<gridSize {
            let positionsInCol = positions.filter { $0.column == col }
            if !positionsInCol.isEmpty {
                // Count how many cells would be occupied after placement
                var occupiedCount = positionsInCol.count

                for row in 0..<gridSize {
                    let pos = GridPosition(unsafeRow: row, unsafeColumn: col)
                    if !positions.contains(pos), gameEngine.cell(at: pos)?.isOccupied == true {
                        occupiedCount += 1
                    }
                }

                if occupiedCount == gridSize {
                    clearedColumns.insert(col)
                }
            }
        }

        if clearedRows.isEmpty && clearedColumns.isEmpty {
            return nil
        }

        return LineClearPreview(rows: clearedRows, columns: clearedColumns)
    }

    // MARK: - Score Preview

    /// Calculate score that would be gained
    private func calculateScorePreview(
        blockPattern: BlockPattern,
        lineClearPreview: LineClearPreview?
    ) -> ScorePreview? {
        guard settings.showScorePreview else { return nil }

        // Base placement score (10 points per cell)
        let placementScore = blockPattern.cellCount * 10

        // Line clear bonus
        let lineClearScore: Int
        if let preview = lineClearPreview {
            let totalLines = preview.totalLines
            // Progressive bonus: 100 for first line, 200 for second, etc.
            lineClearScore = (1...totalLines).reduce(0) { $0 + $1 * 100 }
        } else {
            lineClearScore = 0
        }

        let totalScore = placementScore + lineClearScore

        return ScorePreview(
            placementScore: placementScore,
            lineClearScore: lineClearScore,
            totalScore: totalScore
        )
    }

    // MARK: - Snap-to-Grid

    /// Apply magnetic snap-to-grid behavior
    private func applySnapToGrid(
        currentPosition: GridPosition,
        blockPattern: BlockPattern,
        blockOrigin: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat
    ) -> GridPosition {
        // Calculate the ideal center of the block
        let blockCenterX = blockOrigin.x + (blockPattern.size.width * cellSize) / 2
        let blockCenterY = blockOrigin.y + (blockPattern.size.height * cellSize) / 2
        let blockCenter = CGPoint(x: blockCenterX, y: blockCenterY)

        // Calculate grid cell center
        let cellCenterOffset = cellSize / 2
        let currentCellCenter = CGPoint(
            x: gridFrame.minX + CGFloat(currentPosition.column) * cellSize + cellCenterOffset,
            y: gridFrame.minY + CGFloat(currentPosition.row) * cellSize + cellCenterOffset
        )

        // Calculate distance from block center to cell center
        let distance = hypot(
            blockCenter.x - currentCellCenter.x,
            blockCenter.y - currentCellCenter.y
        )

        // If within snap threshold, keep current position
        let snapDistanceThreshold = cellSize * settings.snapThreshold
        if distance <= snapDistanceThreshold {
            return currentPosition
        }

        // Otherwise, return nearest valid position
        return currentPosition
    }

    /// Attempt to locate a nearby valid placement when current alignment slightly overlaps existing blocks.
    private func findMagnetSnapPosition(
        from basePosition: GridPosition,
        blockPattern: BlockPattern,
        blockOrigin: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat
    ) -> GridPosition? {
        guard let placementEngine = placementEngine else { return nil }

        let widthCells = blockPattern.size.width
        let heightCells = blockPattern.size.height

        let horizontalSpacing = max(CGFloat.zero, widthCells - 1) * gridSpacing
        let verticalSpacing = max(CGFloat.zero, heightCells - 1) * gridSpacing

        let blockWidth = widthCells * cellSize + horizontalSpacing
        let blockHeight = heightCells * cellSize + verticalSpacing

        guard blockWidth > 0, blockHeight > 0 else { return nil }

        let pointerRect = CGRect(
            x: blockOrigin.x,
            y: blockOrigin.y,
            width: blockWidth,
            height: blockHeight
        )

        let totalArea = pointerRect.width * pointerRect.height
        guard totalArea > 0 else { return nil }

        let pointerCenter = CGPoint(x: pointerRect.midX, y: pointerRect.midY)

        let searchRadius = 1
        let overlapTolerance: CGFloat = 0.005
        var bestCandidate: (position: GridPosition, adjacency: Int, overlap: CGFloat, baseDistance: Int, distance: CGFloat)?

        for rowOffset in -searchRadius...searchRadius {
            for columnOffset in -searchRadius...searchRadius {
                let candidate = GridPosition(
                    unsafeRow: basePosition.row + rowOffset,
                    unsafeColumn: basePosition.column + columnOffset
                )

                switch placementEngine.validatePlacement(blockPattern: blockPattern, at: candidate) {
                case .valid:
                    let candidateOrigin = gridToScreenPosition(
                        gridPosition: candidate,
                        gridFrame: gridFrame,
                        cellSize: cellSize,
                        gridSpacing: gridSpacing
                    )

                    let candidateRect = CGRect(
                        x: candidateOrigin.x,
                        y: candidateOrigin.y,
                        width: blockWidth,
                        height: blockHeight
                    )

                    let overlapRect = pointerRect.intersection(candidateRect)
                    guard !overlapRect.isNull, overlapRect.width > 0, overlapRect.height > 0 else { continue }

                    let overlapArea = overlapRect.width * overlapRect.height
                    let overlapRatio = overlapArea / totalArea
                    // Show ghost preview at any overlap - removed threshold for exact positioning
                    guard overlapRatio > 0 else { continue }

                    let adjacencyScore = placementAdjacencyScore(for: candidate, blockPattern: blockPattern)
                    let candidateCenter = CGPoint(x: candidateRect.midX, y: candidateRect.midY)
                    let distance = hypot(pointerCenter.x - candidateCenter.x, pointerCenter.y - candidateCenter.y)
                    let baseDistance = abs(rowOffset) + abs(columnOffset)

                    if let currentBest = bestCandidate {
                        if adjacencyScore > currentBest.adjacency {
                            bestCandidate = (candidate, adjacencyScore, overlapRatio, baseDistance, distance)
                        } else if adjacencyScore == currentBest.adjacency {
                            if overlapRatio > currentBest.overlap + overlapTolerance {
                                bestCandidate = (candidate, adjacencyScore, overlapRatio, baseDistance, distance)
                            } else if abs(overlapRatio - currentBest.overlap) <= overlapTolerance {
                                if baseDistance < currentBest.baseDistance ||
                                    (baseDistance == currentBest.baseDistance && distance < currentBest.distance) {
                                    bestCandidate = (candidate, adjacencyScore, overlapRatio, baseDistance, distance)
                                }
                            }
                        } else if overlapRatio > currentBest.overlap + overlapTolerance {
                            bestCandidate = (candidate, adjacencyScore, overlapRatio, baseDistance, distance)
                        } else if abs(overlapRatio - currentBest.overlap) <= overlapTolerance &&
                                    (baseDistance < currentBest.baseDistance ||
                                     (baseDistance == currentBest.baseDistance && distance < currentBest.distance)) {
                            bestCandidate = (candidate, adjacencyScore, overlapRatio, baseDistance, distance)
                        }
                    } else {
                        bestCandidate = (candidate, adjacencyScore, overlapRatio, baseDistance, distance)
                    }
                case .invalid:
                    continue
                }
            }
        }

        return bestCandidate?.position
    }

    // MARK: - Coordinate Conversions

    /// Convert screen position to grid position
    private func screenToGridPosition(
        screenPosition: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat
    ) -> GridPosition? {
        let cellSpan = cellSize + gridSpacing
        let originX = gridFrame.minX + gridSpacing
        let originY = gridFrame.minY + gridSpacing

        let relativeX = screenPosition.x - originX
        let relativeY = screenPosition.y - originY

        guard relativeX >= 0, relativeY >= 0 else { return nil }

        let column = Int(floor(relativeX / cellSpan))
        let row = Int(floor(relativeY / cellSpan))

        guard let gameEngine = gameEngine else { return nil }
        let gridSize = gameEngine.gridSize

        guard column >= 0, row >= 0, column < gridSize, row < gridSize else { return nil }

        return GridPosition(unsafeRow: row, unsafeColumn: column)
    }

    /// Convert grid position to screen position (top-left corner)
    private func gridToScreenPosition(
        gridPosition: GridPosition,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat
    ) -> CGPoint {
        let cellSpan = cellSize + gridSpacing
        let originX = gridFrame.minX + gridSpacing
        let originY = gridFrame.minY + gridSpacing

        let x = originX + CGFloat(gridPosition.column) * cellSpan
        let y = originY + CGFloat(gridPosition.row) * cellSpan

        return CGPoint(x: x, y: y)
    }

    /// Compute how many neighboring occupied cells would touch the candidate placement.
    private func placementAdjacencyScore(
        for basePosition: GridPosition,
        blockPattern: BlockPattern
    ) -> Int {
        guard let gameEngine else { return 0 }

        let occupiedPositions = blockPattern.getGridPositions(placedAt: basePosition)
        let occupiedSet = Set(occupiedPositions)
        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        var adjacency = 0

        for position in occupiedPositions {
            for (dr, dc) in directions {
                guard let neighbor = GridPosition(
                    row: position.row + dr,
                    column: position.column + dc,
                    gridSize: gameEngine.gridSize
                ) else {
                    continue
                }

                if occupiedSet.contains(neighbor) { continue }

                if gameEngine.cell(at: neighbor)?.isOccupied == true {
                    adjacency += 1
                }
            }
        }

        return adjacency
    }

    // MARK: - State Management

    private func updatePreviewState(
        blockPattern: BlockPattern,
        position: GridPosition?,
        validity: PlacementValidity,
        affectedPositions: [GridPosition],
        lineClearPreview: LineClearPreview? = nil,
        scorePreview: ScorePreview? = nil,
        snapPosition: CGPoint? = nil
    ) {
        previewState.blockPattern = blockPattern
        previewState.position = position
        previewState.validity = validity
        previewState.affectedPositions = affectedPositions
        previewState.linesClearPreview = lineClearPreview
        previewState.scorePreview = scorePreview
        previewState.snapPosition = snapPosition
        previewState.isVisible = true
    }

    private func resetPreviewState() {
        previewState = GhostPreviewState()
    }
}

// MARK: - Extensions

extension BlockPattern: Equatable {
    static func == (lhs: BlockPattern, rhs: BlockPattern) -> Bool {
        return lhs.type == rhs.type && lhs.color == rhs.color
    }
}
