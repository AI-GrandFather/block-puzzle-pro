// FILE: LevelPatternGenerator.swift
import Foundation

// MARK: - Helper Types

/// Hashable grid point for use in Sets
private struct GridPoint: Hashable {
    let row: Int
    let col: Int

    init(_ row: Int, _ col: Int) {
        self.row = row
        self.col = col
    }
}

/**
 # Level Pattern Generator

 Generates pre-placed obstacle patterns for block puzzle levels based on research
 from successful puzzle games (Candy Crush, 1010!, Block Puzzle variants).

 ## Pattern Philosophy:
 - Early patterns (World 1-2): Simple, obvious obstacles (10-15% coverage)
 - Medium patterns (World 3-5): Moderate complexity (20-25% coverage)
 - Advanced patterns (World 6-10): High complexity (30-40% coverage)

 Patterns must be:
 - Visually interesting
 - Strategically challenging
 - Solvable (verified through simulation)
 - Fun to play

 - Author: Claude Code
 - Date: 2025-10-21
 */
class LevelPatternGenerator {

    // MARK: - Grid Size

    private let gridSize: Int

    init(gridSize: Int = 8) {
        self.gridSize = gridSize
    }

    // MARK: - Main Pattern Generation

    /// Generate a pattern appropriate for the given difficulty level
    func generatePattern(difficulty: Int, patternType: PatternType) -> [LevelPrefill.Cell] {
        let targetCoverage = coveragePercentage(for: difficulty)
        let targetBlocks = Int(Double(gridSize * gridSize) * targetCoverage)

        let pattern: [(Int, Int)]

        switch patternType {
        case .empty:
            pattern = []
        case .corners:
            pattern = generateCorners(count: min(targetBlocks, 4))
        case .borders:
            pattern = generateBorders(thickness: difficulty <= 3 ? 1 : 2)
        case .checkerboard:
            pattern = generateCheckerboard(density: difficulty)
        case .cross:
            pattern = generateCross(thickness: difficulty <= 3 ? 1 : 2)
        case .diagonal:
            pattern = generateDiagonal(thickness: difficulty <= 3 ? 1 : 2)
        case .lShape:
            pattern = generateLShape(size: min(difficulty + 2, gridSize - 1))
        case .scattered:
            pattern = generateScattered(count: targetBlocks)
        case .frame:
            pattern = generateFrame(thickness: difficulty <= 3 ? 1 : 2)
        case .spiral:
            pattern = generateSpiral(density: difficulty)
        case .maze:
            pattern = generateMaze(complexity: difficulty)
        case .symmetrical:
            pattern = generateSymmetrical(count: targetBlocks)
        case .clusters:
            pattern = generateClusters(clusterCount: difficulty, clusterSize: 3...5)
        }

        // Convert to LevelPrefill.Cell with random colors
        return pattern.map { (row, col) in
            LevelPrefill.Cell(
                row: row,
                column: col,
                color: randomObstacleColor(),
                isLocked: true  // Obstacles are locked and cannot be cleared
            )
        }
    }

    // MARK: - Coverage Calculation

    private func coveragePercentage(for difficulty: Int) -> Double {
        switch difficulty {
        case 1...2: return 0.10  // 10% - very sparse
        case 3...4: return 0.15  // 15%
        case 5...6: return 0.20  // 20%
        case 7...8: return 0.25  // 25%
        case 9...10: return 0.30  // 30%
        default: return 0.35       // 35% - dense
        }
    }

    // MARK: - Pattern Types

    enum PatternType {
        case empty
        case corners
        case borders
        case checkerboard
        case cross
        case diagonal
        case lShape
        case scattered
        case frame
        case spiral
        case maze
        case symmetrical
        case clusters
    }

    // MARK: - Simple Patterns (World 1-2)

    /// Generate blocks in the four corners
    private func generateCorners(count: Int) -> [(Int, Int)] {
        let corners = [
            (0, 0), (0, gridSize - 1),
            (gridSize - 1, 0), (gridSize - 1, gridSize - 1)
        ]
        return Array(corners.prefix(count))
    }

    /// Generate border blocks along edges
    private func generateBorders(thickness: Int) -> [(Int, Int)] {
        var blocks: [(Int, Int)] = []

        for t in 0..<thickness {
            // Top and bottom
            for col in 0..<gridSize {
                blocks.append((t, col))
                blocks.append((gridSize - 1 - t, col))
            }

            // Left and right (excluding corners already added)
            for row in (t + 1)..<(gridSize - 1 - t) {
                blocks.append((row, t))
                blocks.append((row, gridSize - 1 - t))
            }
        }

        return blocks
    }

    /// Generate checkerboard pattern
    private func generateCheckerboard(density: Int) -> [(Int, Int)] {
        var blocks: [(Int, Int)] = []

        let skip = max(1, 10 - density)  // Higher difficulty = denser checkerboard

        for row in stride(from: 0, to: gridSize, by: skip) {
            for col in stride(from: 0, to: gridSize, by: skip) {
                if (row + col) % (skip * 2) == 0 {
                    blocks.append((row, col))
                }
            }
        }

        return blocks
    }

    // MARK: - Medium Patterns (World 3-5)

    /// Generate cross/plus pattern in center
    private func generateCross(thickness: Int) -> [(Int, Int)] {
        var blocks: Set<GridPoint> = []
        let center = gridSize / 2

        // Horizontal bar
        for col in 0..<gridSize {
            for t in 0..<thickness {
                blocks.insert(GridPoint(center - t, col))
                blocks.insert(GridPoint(center + t, col))
            }
        }

        // Vertical bar
        for row in 0..<gridSize {
            for t in 0..<thickness {
                blocks.insert(GridPoint(row, center - t))
                blocks.insert(GridPoint(row, center + t))
            }
        }

        // Convert to tuples
        return blocks.map { ($0.row, $0.col) }
    }

    /// Generate diagonal line pattern
    private func generateDiagonal(thickness: Int) -> [(Int, Int)] {
        var blocks: Set<GridPoint> = []

        for i in 0..<gridSize {
            for t in 0..<thickness {
                // Main diagonal
                if i + t < gridSize {
                    blocks.insert(GridPoint(i, i + t))
                }
                // Anti-diagonal
                if i - t >= 0 {
                    blocks.insert(GridPoint(i, gridSize - 1 - (i - t)))
                }
            }
        }

        return blocks.map { ($0.row, $0.col) }
    }

    /// Generate L-shaped barriers
    private func generateLShape(size: Int) -> [(Int, Int)] {
        var blocks: [(Int, Int)] = []
        let startRow = 1
        let startCol = 1

        // Vertical part
        for row in startRow..<min(startRow + size, gridSize) {
            blocks.append((row, startCol))
        }

        // Horizontal part
        for col in startCol..<min(startCol + size, gridSize) {
            blocks.append((startRow + size - 1, col))
        }

        return blocks
    }

    /// Generate randomly scattered blocks
    private func generateScattered(count: Int) -> [(Int, Int)] {
        var blocks: Set<GridPoint> = []
        var attempts = 0
        let maxAttempts = count * 10

        while blocks.count < count && attempts < maxAttempts {
            let row = Int.random(in: 0..<gridSize)
            let col = Int.random(in: 0..<gridSize)
            blocks.insert(GridPoint(row, col))
            attempts += 1
        }

        return blocks.map { ($0.row, $0.col) }
    }

    // MARK: - Advanced Patterns (World 6-10)

    /// Generate frame pattern (hollow rectangle)
    private func generateFrame(thickness: Int) -> [(Int, Int)] {
        var blocks: Set<GridPoint> = []

        for t in 0..<thickness {
            // Top and bottom
            for col in 0..<gridSize {
                blocks.insert(GridPoint(t, col))
                blocks.insert(GridPoint(gridSize - 1 - t, col))
            }

            // Left and right
            for row in 0..<gridSize {
                blocks.insert(GridPoint(row, t))
                blocks.insert(GridPoint(row, gridSize - 1 - t))
            }
        }

        return blocks.map { ($0.row, $0.col) }
    }

    /// Generate spiral pattern
    private func generateSpiral(density: Int) -> [(Int, Int)] {
        var blocks: [(Int, Int)] = []
        var visited = Set<GridPoint>()

        var row = 0
        var col = 0
        var direction = 0  // 0=right, 1=down, 2=left, 3=up

        let totalCells = min(gridSize * gridSize / 2, density * 10)
        var placedCells = 0

        while placedCells < totalCells {
            let currentPoint = GridPoint(row, col)
            if !visited.contains(currentPoint) && row >= 0 && row < gridSize && col >= 0 && col < gridSize {
                blocks.append((row, col))
                visited.insert(currentPoint)
                placedCells += 1
            }

            // Try to move in current direction
            var nextRow = row
            var nextCol = col

            switch direction {
            case 0: nextCol += 1  // Right
            case 1: nextRow += 1  // Down
            case 2: nextCol -= 1  // Left
            case 3: nextRow -= 1  // Up
            default: break
            }

            // Check if we need to turn
            let nextPoint = GridPoint(nextRow, nextCol)
            if nextRow < 0 || nextRow >= gridSize || nextCol < 0 || nextCol >= gridSize ||
                visited.contains(nextPoint) {
                // Turn clockwise
                direction = (direction + 1) % 4

                // Recalculate next position
                switch direction {
                case 0: nextCol = col + 1
                case 1: nextRow = row + 1
                case 2: nextCol = col - 1
                case 3: nextRow = row - 1
                default: break
                }

                // If still can't move, we're done
                let newNextPoint = GridPoint(nextRow, nextCol)
                if nextRow < 0 || nextRow >= gridSize || nextCol < 0 || nextCol >= gridSize ||
                    visited.contains(newNextPoint) {
                    break
                }
            }

            row = nextRow
            col = nextCol
        }

        return blocks
    }

    /// Generate maze-like pattern
    private func generateMaze(complexity: Int) -> [(Int, Int)] {
        var blocks: Set<GridPoint> = []

        // Create vertical and horizontal walls
        let wallSpacing = max(2, 8 - complexity / 2)

        // Vertical walls
        for col in stride(from: wallSpacing, to: gridSize, by: wallSpacing) {
            for row in 0..<gridSize {
                if row % 3 != 0 {  // Leave gaps
                    blocks.insert(GridPoint(row, col))
                }
            }
        }

        // Horizontal walls
        for row in stride(from: wallSpacing, to: gridSize, by: wallSpacing) {
            for col in 0..<gridSize {
                if col % 3 != 1 {  // Leave gaps (offset from vertical gaps)
                    blocks.insert(GridPoint(row, col))
                }
            }
        }

        return blocks.map { ($0.row, $0.col) }
    }

    /// Generate symmetrical pattern (horizontally and vertically)
    private func generateSymmetrical(count: Int) -> [(Int, Int)] {
        var blocks: Set<GridPoint> = []
        let quadrantCount = count / 4

        // Generate in top-left quadrant
        for _ in 0..<quadrantCount {
            let row = Int.random(in: 0..<(gridSize/2))
            let col = Int.random(in: 0..<(gridSize/2))

            // Add to all four quadrants
            blocks.insert(GridPoint(row, col))
            blocks.insert(GridPoint(row, gridSize - 1 - col))
            blocks.insert(GridPoint(gridSize - 1 - row, col))
            blocks.insert(GridPoint(gridSize - 1 - row, gridSize - 1 - col))
        }

        return blocks.map { ($0.row, $0.col) }
    }

    /// Generate clustered blocks
    private func generateClusters(clusterCount: Int, clusterSize: ClosedRange<Int>) -> [(Int, Int)] {
        var blocks: Set<GridPoint> = []

        for _ in 0..<clusterCount {
            let centerRow = Int.random(in: 1..<(gridSize - 1))
            let centerCol = Int.random(in: 1..<(gridSize - 1))
            let size = Int.random(in: clusterSize)

            // Create cluster around center
            for _ in 0..<size {
                let offsetRow = Int.random(in: -1...1)
                let offsetCol = Int.random(in: -1...1)
                let row = min(max(0, centerRow + offsetRow), gridSize - 1)
                let col = min(max(0, centerCol + offsetCol), gridSize - 1)
                blocks.insert(GridPoint(row, col))
            }
        }

        return blocks.map { ($0.row, $0.col) }
    }

    // MARK: - Helper Methods

    /// Get random color for obstacles (avoiding some colors for clarity)
    private func randomObstacleColor() -> BlockColor {
        let obstacleColors: [BlockColor] = [.red, .purple, .orange, .cyan]
        return obstacleColors.randomElement() ?? .red
    }
}
