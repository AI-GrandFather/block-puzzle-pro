// FILE: SpatialIndex.swift
import Foundation
import SpriteKit

final class SpatialIndex {
    private struct GridBucket {
        var nodes: Set<SKNode> = []

        mutating func insert(_ node: SKNode) {
            nodes.insert(node)
        }

        mutating func remove(_ node: SKNode) {
            nodes.remove(node)
        }
    }

    private let bucketSize: CGFloat
    private let bounds: CGRect
    private let bucketsPerRow: Int
    private let bucketsPerColumn: Int
    private var buckets: [[GridBucket]]
    private var nodeToPositions: [ObjectIdentifier: Set<Int>] = [:]

    init(bounds: CGRect, bucketSize: CGFloat = 64.0) {
        self.bounds = bounds
        self.bucketSize = bucketSize
        self.bucketsPerRow = max(1, Int(ceil(bounds.width / bucketSize)))
        self.bucketsPerColumn = max(1, Int(ceil(bounds.height / bucketSize)))

        self.buckets = Array(repeating: Array(repeating: GridBucket(), count: bucketsPerRow), count: bucketsPerColumn)
    }

    func insert(_ node: SKNode, at position: CGPoint) {
        let nodeId = ObjectIdentifier(node)
        remove(node) // Remove from previous positions

        let bucketIndices = getBucketIndices(for: position)
        var positions: Set<Int> = []

        for (row, col) in bucketIndices {
            if isValidBucket(row: row, col: col) {
                buckets[row][col].insert(node)
                positions.insert(row * bucketsPerRow + col)
            }
        }

        nodeToPositions[nodeId] = positions
    }

    func remove(_ node: SKNode) {
        let nodeId = ObjectIdentifier(node)
        guard let positions = nodeToPositions[nodeId] else { return }

        for position in positions {
            let row = position / bucketsPerRow
            let col = position % bucketsPerRow
            if isValidBucket(row: row, col: col) {
                buckets[row][col].remove(node)
            }
        }

        nodeToPositions.removeValue(forKey: nodeId)
    }

    func query(at position: CGPoint, radius: CGFloat = 0) -> [SKNode] {
        let searchArea = CGRect(
            x: position.x - radius,
            y: position.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        let bucketIndices = getBucketIndices(for: searchArea)
        var results: Set<SKNode> = []

        for (row, col) in bucketIndices {
            if isValidBucket(row: row, col: col) {
                for node in buckets[row][col].nodes {
                    let distance = node.position.distance(to: position)
                    if distance <= radius {
                        results.insert(node)
                    }
                }
            }
        }

        return Array(results)
    }

    func clear() {
        for row in 0..<bucketsPerColumn {
            for col in 0..<bucketsPerRow {
                buckets[row][col].nodes.removeAll()
            }
        }
        nodeToPositions.removeAll()
    }

    private func getBucketIndices(for position: CGPoint) -> [(Int, Int)] {
        let relativeX = position.x - bounds.minX
        let relativeY = position.y - bounds.minY

        let col = max(0, min(bucketsPerRow - 1, Int(floor(relativeX / bucketSize))))
        let row = max(0, min(bucketsPerColumn - 1, Int(floor(relativeY / bucketSize))))

        return [(row, col)]
    }

    private func getBucketIndices(for rect: CGRect) -> [(Int, Int)] {
        let minX = max(bounds.minX, rect.minX)
        let maxX = min(bounds.maxX, rect.maxX)
        let minY = max(bounds.minY, rect.minY)
        let maxY = min(bounds.maxY, rect.maxY)

        let startCol = max(0, Int(floor((minX - bounds.minX) / bucketSize)))
        let endCol = min(bucketsPerRow - 1, Int(floor((maxX - bounds.minX) / bucketSize)))
        let startRow = max(0, Int(floor((minY - bounds.minY) / bucketSize)))
        let endRow = min(bucketsPerColumn - 1, Int(floor((maxY - bounds.minY) / bucketSize)))

        var indices: [(Int, Int)] = []
        for row in startRow...endRow {
            for col in startCol...endCol {
                indices.append((row, col))
            }
        }

        return indices
    }

    private func isValidBucket(row: Int, col: Int) -> Bool {
        return row >= 0 && row < bucketsPerColumn && col >= 0 && col < bucketsPerRow
    }
}

extension SpatialIndex {
    func findNearestNode(to position: CGPoint, within radius: CGFloat) -> SKNode? {
        let candidates = query(at: position, radius: radius)

        var nearest: SKNode?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude

        for node in candidates {
            let distance = node.position.distance(to: position)
            if distance < nearestDistance {
                nearestDistance = distance
                nearest = node
            }
        }

        return nearest
    }

    func countNodes(in area: CGRect) -> Int {
        let bucketIndices = getBucketIndices(for: area)
        var nodeSet: Set<SKNode> = []

        for (row, col) in bucketIndices {
            if isValidBucket(row: row, col: col) {
                nodeSet.formUnion(buckets[row][col].nodes)
            }
        }

        return nodeSet.count
    }
}