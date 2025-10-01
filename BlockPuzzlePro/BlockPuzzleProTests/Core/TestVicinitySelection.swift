// FILE: TestVicinitySelection.swift
import XCTest
import SpriteKit
@testable import BlockPuzzlePro

final class VicinityTests: XCTestCase {
    var spatialIndex: SpatialIndex!
    var testBounds: CGRect!

    override func setUp() {
        super.setUp()
        testBounds = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        spatialIndex = SpatialIndex(bounds: testBounds, bucketSize: 64)
    }

    override func tearDown() {
        spatialIndex = nil
        testBounds = nil
        super.tearDown()
    }

    func testVicinityDetectionExactMatch() {
        let node = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        let position = CGPoint(x: 100, y: 100)
        node.position = position

        spatialIndex.insert(node, at: position)

        let results = spatialIndex.query(at: position, radius: GameConfig.vicinityRadius)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, node)
    }

    func testVicinityDetectionWithinRadius() {
        let node = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        let nodePosition = CGPoint(x: 100, y: 100)
        node.position = nodePosition

        spatialIndex.insert(node, at: nodePosition)

        // Test point within radius
        let testPosition = CGPoint(x: 110, y: 110) // Distance = 14.14, within 32pt radius
        let results = spatialIndex.query(at: testPosition, radius: GameConfig.vicinityRadius)
        XCTAssertEqual(results.count, 1)
    }

    func testVicinityDetectionOutsideRadius() {
        let node = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        let nodePosition = CGPoint(x: 100, y: 100)
        node.position = nodePosition

        spatialIndex.insert(node, at: nodePosition)

        // Test point outside radius
        let testPosition = CGPoint(x: 150, y: 150) // Distance = 70.71, outside 32pt radius
        let results = spatialIndex.query(at: testPosition, radius: GameConfig.vicinityRadius)
        XCTAssertEqual(results.count, 0)
    }

    func testMultipleNodesVicinityPriority() {
        let node1 = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        let node2 = SKSpriteNode(color: .blue, size: CGSize(width: 50, height: 50))

        let position1 = CGPoint(x: 100, y: 100)
        let position2 = CGPoint(x: 120, y: 120)

        node1.position = position1
        node2.position = position2

        spatialIndex.insert(node1, at: position1)
        spatialIndex.insert(node2, at: position2)

        // Test point closer to node1
        let testPosition = CGPoint(x: 105, y: 105)
        let nearest = spatialIndex.findNearestNode(to: testPosition, within: GameConfig.vicinityRadius)
        XCTAssertEqual(nearest, node1)
    }

    func testBoundaryConditions() {
        let node = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
        let position = CGPoint(x: 0, y: 0) // Edge of bounds
        node.position = position

        spatialIndex.insert(node, at: position)

        let results = spatialIndex.query(at: position, radius: GameConfig.vicinityRadius)
        XCTAssertEqual(results.count, 1)
    }

    func testEmptyResultsWhenNothingNearby() {
        let testPosition = CGPoint(x: 500, y: 500)
        let results = spatialIndex.query(at: testPosition, radius: GameConfig.vicinityRadius)
        XCTAssertEqual(results.count, 0)
    }

    func testDragThresholdValidation() {
        let startPosition = CGPoint(x: 100, y: 100)
        let movePosition1 = CGPoint(x: 102, y: 102) // Distance = 2.83, below threshold
        let movePosition2 = CGPoint(x: 110, y: 110) // Distance = 14.14, above threshold

        let distance1 = startPosition.distance(to: movePosition1)
        let distance2 = startPosition.distance(to: movePosition2)

        XCTAssertLessThan(distance1, GameConfig.dragThreshold)
        XCTAssertGreaterThan(distance2, GameConfig.dragThreshold)
    }

    func testPerformanceWithManyNodes() {
        // Insert 1000 nodes
        var nodes: [SKSpriteNode] = []
        for i in 0..<1000 {
            let node = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 10))
            let position = CGPoint(
                x: CGFloat(i % 100) * 10,
                y: CGFloat(i / 100) * 10
            )
            node.position = position
            nodes.append(node)
            spatialIndex.insert(node, at: position)
        }

        // Measure query performance
        let testPosition = CGPoint(x: 250, y: 250)
        let startTime = CFAbsoluteTimeGetCurrent()

        for _ in 0..<100 {
            _ = spatialIndex.query(at: testPosition, radius: GameConfig.vicinityRadius)
        }

        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        XCTAssertLessThan(elapsedTime, 0.1) // Should complete 100 queries in under 100ms
    }
}