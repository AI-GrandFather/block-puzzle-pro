//
//  DragAndPlacementIntegrationTests.swift
//  BlockPuzzleProTests
//
//  Created on October 9, 2025
//

import XCTest
@testable import BlockPuzzlePro

@MainActor
final class DragAndPlacementIntegrationTests: XCTestCase {
    private var dragController: DragController!
    private var gameEngine: GameEngine!
    private var placementEngine: PlacementEngine!

    private let cellSize: CGFloat = 36
    private let gridSize: Int = 10
    private lazy var gridFrame: CGRect = CGRect(
        x: 0,
        y: 0,
        width: CGFloat(gridSize) * cellSize,
        height: CGFloat(gridSize) * cellSize
    )

    override func setUp() async throws {
        try await super.setUp()
        gameEngine = GameEngine(gameMode: .classic)
        dragController = DragController()
        placementEngine = PlacementEngine(gameEngine: gameEngine)
    }

    override func tearDown() async throws {
        dragController = nil
        placementEngine = nil
        gameEngine = nil
        try await super.tearDown()
    }

    func testDragTouchOffsetRemainsStable() {
        let blockPattern = BlockPattern(type: .square, color: .blue)
        let blockOrigin = CGPoint(x: 72, y: 144)
        let fingerLocation = CGPoint(
            x: blockOrigin.x + cellSize / 2,
            y: blockOrigin.y + cellSize / 2
        )
        let touchOffset = CGSize(
            width: fingerLocation.x - blockOrigin.x,
            height: fingerLocation.y - blockOrigin.y
        )

        dragController.startDrag(
            blockIndex: 0,
            blockPattern: blockPattern,
            at: fingerLocation,
            touchOffset: touchOffset
        )

        XCTAssertEqual(dragController.dragTouchOffset.width, touchOffset.width, accuracy: 0.01)
        XCTAssertEqual(dragController.dragTouchOffset.height, touchOffset.height, accuracy: 0.01)

        dragController.liftOffsetY = 0

        let updatedFingerLocation = CGPoint(x: fingerLocation.x + 120, y: fingerLocation.y + 60)
        dragController.updateDrag(to: updatedFingerLocation)

        XCTAssertEqual(dragController.dragTouchOffset.width, touchOffset.width, accuracy: 0.01)
        XCTAssertEqual(dragController.dragTouchOffset.height, touchOffset.height, accuracy: 0.01)
        XCTAssertEqual(dragController.currentTouchLocation, updatedFingerLocation)

        let expectedDragPosition = CGPoint(
            x: updatedFingerLocation.x - touchOffset.width,
            y: updatedFingerLocation.y - touchOffset.height
        )

        XCTAssertEqual(dragController.currentDragPosition.x, expectedDragPosition.x, accuracy: 0.5)
        XCTAssertEqual(dragController.currentDragPosition.y, expectedDragPosition.y, accuracy: 0.5)
    }

    func testPlacementPreviewAndCommitSucceeds() {
        let blockPattern = BlockPattern(type: .square, color: .blue)
        let basePosition = GridPosition(unsafeRow: 2, unsafeColumn: 3)
        let blockOrigin = CGPoint(
            x: gridFrame.minX + CGFloat(basePosition.column) * cellSize,
            y: gridFrame.minY + CGFloat(basePosition.row) * cellSize
        )
        let fingerLocation = CGPoint(
            x: blockOrigin.x + cellSize / 2,
            y: blockOrigin.y + cellSize / 2
        )
        let touchOffset = CGSize(width: cellSize / 2, height: cellSize / 2)

        dragController.startDrag(
            blockIndex: 0,
            blockPattern: blockPattern,
            at: fingerLocation,
            touchOffset: touchOffset
        )
        dragController.liftOffsetY = 0
        dragController.updateDrag(to: fingerLocation)

        placementEngine.updatePreview(
            blockPattern: blockPattern,
            blockOrigin: dragController.currentDragPosition,
            touchPoint: dragController.currentTouchLocation,
            touchOffset: dragController.dragTouchOffset,
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSpacing: 0
        )

        XCTAssertTrue(placementEngine.isCurrentPreviewValid)

        let success = placementEngine.commitPlacement(blockPattern: blockPattern)
        XCTAssertTrue(success)

        let expectedPositions = blockPattern.getGridPositions(placedAt: basePosition)
        for position in expectedPositions {
            let cell = gameEngine.cell(at: position)
            XCTAssertTrue(cell?.isOccupied ?? false, "Expected cell at \(position) to be occupied.")
        }
    }

    func testPlacementPreviewRejectsCollisions() {
        let occupiedPosition = GridPosition(unsafeRow: 0, unsafeColumn: 0)
        gameEngine.setCell(at: occupiedPosition, to: .occupied(color: .red))

        let blockPattern = BlockPattern(type: .square, color: .blue)
        let blockOrigin = CGPoint(
            x: gridFrame.minX,
            y: gridFrame.minY
        )
        let fingerLocation = CGPoint(
            x: blockOrigin.x + cellSize / 2,
            y: blockOrigin.y + cellSize / 2
        )
        let touchOffset = CGSize(width: cellSize / 2, height: cellSize / 2)

        dragController.startDrag(
            blockIndex: 0,
            blockPattern: blockPattern,
            at: fingerLocation,
            touchOffset: touchOffset
        )
        dragController.liftOffsetY = 0
        dragController.updateDrag(to: fingerLocation)

        placementEngine.updatePreview(
            blockPattern: blockPattern,
            blockOrigin: dragController.currentDragPosition,
            touchPoint: dragController.currentTouchLocation,
            touchOffset: dragController.dragTouchOffset,
            gridFrame: gridFrame,
            cellSize: cellSize,
            gridSpacing: 0
        )

        XCTAssertFalse(placementEngine.isCurrentPreviewValid)
        XCTAssertFalse(placementEngine.commitPlacement(blockPattern: blockPattern))
    }
}
