// FILE: ForecastOverlay.swift
import Foundation
import SpriteKit

final class ForecastOverlay {
    private let gridBounds: CGRect
    private let cellSize: CGFloat
    private let gridSpacing: CGFloat
    private let nodePool: NodePool
    private var activeNodes: [SKSpriteNode] = []
    private var clipNode: SKCropNode?

    init(gridBounds: CGRect, cellSize: CGFloat, gridSpacing: CGFloat) {
        self.gridBounds = gridBounds
        self.cellSize = cellSize
        self.gridSpacing = gridSpacing
        self.nodePool = NodePool(initialSize: GameConfig.nodePoolInitialSize)
        setupClipNode()
    }

    private func setupClipNode() {
        clipNode = SKCropNode()
        let maskNode = SKSpriteNode(color: .white, size: gridBounds.size)
        maskNode.position = CGPoint(x: gridBounds.midX, y: gridBounds.midY)
        clipNode?.maskNode = maskNode
    }

    func showPreview(for block: Block, at position: Grid.Point, isValid: Bool, parentNode: SKNode) {
        clearPreview()

        guard isValid else { return }
        guard let clipNode = clipNode else { return }
        parentNode.addChild(clipNode)

        let clippedCells = getClippedCells(for: block, at: position)
        guard !clippedCells.isEmpty else { return }

        let nodes = nodePool.acquireNodes(count: clippedCells.count)
        let baseColor = block.color.skColor

        for (index, cell) in clippedCells.enumerated() {
            guard index < nodes.count else { break }

            let node = nodes[index]
            configurePreviewNode(node, for: cell, color: baseColor)
            clipNode.addChild(node)
            activeNodes.append(node)
        }
    }

    func clearPreview() {
        clipNode?.removeFromParent()

        for node in activeNodes {
            node.removeFromParent()
            nodePool.returnNode(node)
        }
        activeNodes.removeAll()
    }

    private func getClippedCells(for block: Block, at position: Grid.Point) -> [Grid.Point] {
        let placedPoints = block.placedPoints(at: position)
        return placedPoints.filter { point in
            point.x >= 0 && point.x < GameConfig.gridSize &&
            point.y >= 0 && point.y < GameConfig.gridSize
        }
    }

    private func configurePreviewNode(_ node: SKSpriteNode, for gridPoint: Grid.Point, color: SKColor) {
        let screenPosition = gridToScreenPosition(gridPoint)

        node.position = screenPosition
        node.size = CGSize(width: cellSize, height: cellSize)
        node.color = color
        node.alpha = GameConfig.previewAlpha
        node.zPosition = 10

        // Reset any previous transformations
        node.setScale(1.0)
        node.zRotation = 0
    }

    private func gridToScreenPosition(_ gridPoint: Grid.Point) -> CGPoint {
        let cellSpan = cellSize + gridSpacing
        return CGPoint(
            x: gridBounds.minX + gridSpacing + (CGFloat(gridPoint.x) * cellSpan) + (cellSize / 2),
            y: gridBounds.minY + gridSpacing + (CGFloat(gridPoint.y) * cellSpan) + (cellSize / 2)
        )
    }

    func updateGridBounds(_ newBounds: CGRect) {
        // Update internal bounds and re-setup clip node
        // This method would be called when device rotates or grid resizes
        // For now, keeping it simple - full recreation would be needed for rotation support
    }
}

// MARK: - Node Pool for Performance
final class NodePool {
    private var availableNodes: [SKSpriteNode] = []
    private var allNodes: Set<SKSpriteNode> = []
    private let maxPoolSize: Int

    init(initialSize: Int, maxSize: Int = 200) {
        self.maxPoolSize = maxSize
        preallocateNodes(count: initialSize)
    }

    private func preallocateNodes(count: Int) {
        for _ in 0..<count {
            let node = createNode()
            availableNodes.append(node)
            allNodes.insert(node)
        }
    }

    private func createNode() -> SKSpriteNode {
        let node = SKSpriteNode(color: .white, size: CGSize(width: 32, height: 32))
        node.name = "pooledPreviewNode"
        return node
    }

    func acquireNodes(count: Int) -> [SKSpriteNode] {
        var nodes: [SKSpriteNode] = []

        for _ in 0..<count {
            let node: SKSpriteNode
            if !availableNodes.isEmpty {
                node = availableNodes.removeLast()
            } else if allNodes.count < maxPoolSize {
                node = createNode()
                allNodes.insert(node)
            } else {
                // Pool exhausted, reuse oldest node
                node = allNodes.randomElement() ?? createNode()
            }
            nodes.append(node)
        }

        return nodes
    }

    func returnNode(_ node: SKSpriteNode) {
        guard allNodes.contains(node) else { return }

        node.removeFromParent()
        node.removeAllActions()

        if availableNodes.count < maxPoolSize {
            availableNodes.append(node)
        }
    }

    func returnNodes(_ nodes: [SKSpriteNode]) {
        for node in nodes {
            returnNode(node)
        }
    }

    func clear() {
        for node in allNodes {
            node.removeFromParent()
        }
        availableNodes.removeAll()
        allNodes.removeAll()
    }

    var stats: (available: Int, total: Int) {
        return (availableNodes.count, allNodes.count)
    }
}
