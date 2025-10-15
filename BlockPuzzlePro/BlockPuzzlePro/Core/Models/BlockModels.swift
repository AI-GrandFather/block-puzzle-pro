// FILE: BlockModels.swift
import Foundation
import SpriteKit

struct Grid {
    struct Point: Codable, Hashable, Equatable {
        let x: Int
        let y: Int

        init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }

        func isValid(gridSize: Int) -> Bool {
            return x >= 0 && x < gridSize && y >= 0 && y < gridSize
        }

        static func +(lhs: Grid.Point, rhs: Grid.Point) -> Grid.Point {
            return Grid.Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
        }
    }
}

struct Block: Codable, Hashable {
    let id: UUID
    let type: BlockType
    let points: [Grid.Point]
    let color: BlockColor

    init(type: BlockType, color: BlockColor) {
        self.id = UUID()
        self.type = type
        self.color = color
        self.points = type.occupiedPositions.map { Grid.Point(x: Int($0.x), y: Int($0.y)) }
    }

    func canPlace(at position: Grid.Point, gridSize: Int) -> Bool {
        return points.allSatisfy { point in
            let targetPoint = position + point
            return targetPoint.isValid(gridSize: gridSize)
        }
    }

    func placedPoints(at position: Grid.Point) -> [Grid.Point] {
        return points.map { position + $0 }
    }
}

struct BlockShape: Codable, Hashable {
    let width: Int
    let height: Int
    let pattern: [[Bool]]

    init(pattern: [[Bool]]) {
        self.pattern = pattern
        self.height = pattern.count
        self.width = pattern.max(by: { $0.count < $1.count })?.count ?? 0
    }

    var occupiedPoints: [Grid.Point] {
        var points: [Grid.Point] = []
        for (y, row) in pattern.enumerated() {
            for (x, isOccupied) in row.enumerated() {
                if isOccupied {
                    points.append(Grid.Point(x: x, y: y))
                }
            }
        }
        return points
    }

    var cellCount: Int {
        return occupiedPoints.count
    }

    func isValid(gridSize: Int) -> Bool {
        return width <= gridSize && height <= gridSize
    }
}

enum BlockColor: String, CaseIterable, Codable {
    case red = "red"
    case blue = "blue"
    case green = "green"
    case yellow = "yellow"
    case purple = "purple"
    case orange = "orange"
    case cyan = "cyan"
    case pink = "pink"

    var uiColor: UIColor {
        switch self {
        case .red: return UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
        case .blue: return UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0)
        case .green: return UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0)
        case .yellow: return UIColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1.0)
        case .purple: return UIColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1.0)
        case .orange: return UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)
        case .cyan: return UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0)
        case .pink: return UIColor(red: 0.9, green: 0.4, blue: 0.7, alpha: 1.0)
        }
    }

    var skColor: SKColor {
        return uiColor
    }

    /// Accessibility description for VoiceOver
    var accessibilityDescription: String {
        switch self {
        case .red: return "Red block"
        case .blue: return "Blue block"
        case .green: return "Green block"
        case .yellow: return "Yellow block"
        case .purple: return "Purple block"
        case .orange: return "Orange block"
        case .cyan: return "Cyan block"
        case .pink: return "Pink block"
        }
    }

    /// Get pattern identifier for colorblind accessibility
    var accessibilityPattern: String {
        switch self {
        case .red: return "solid"
        case .blue: return "dots"
        case .green: return "stripes"
        case .yellow: return "grid"
        case .purple: return "diagonal"
        case .orange: return "cross"
        case .cyan: return "waves"
        case .pink: return "checker"
        }
    }
}

enum DragState: Equatable {
    case idle
    case candidateVicinity(block: BlockRef, startTouch: CGPoint)
    case dragging(block: BlockRef, offset: CGVector, lastUpdate: TimeInterval)
    case dropAttempt(block: BlockRef, targetPos: Grid.Point)

    var isDragging: Bool {
        switch self {
        case .dragging, .dropAttempt: return true
        default: return false
        }
    }

    var currentBlock: BlockRef? {
        switch self {
        case .candidateVicinity(let block, _),
             .dragging(let block, _, _),
             .dropAttempt(let block, _):
            return block
        case .idle:
            return nil
        }
    }
}

struct BlockRef: Equatable {
    let id: UUID
    let trayIndex: Int

    static func ==(lhs: BlockRef, rhs: BlockRef) -> Bool {
        return lhs.id == rhs.id && lhs.trayIndex == rhs.trayIndex
    }
}