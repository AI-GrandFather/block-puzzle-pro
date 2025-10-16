import XCTest
@testable import BlockPuzzlePro

final class BlockTypeTests: XCTestCase {

    func testAllCasesContainsExpectedShapes() {
        let expected: Set<BlockType> = [
            .single,
            .domino,
            .triLine,
            .triCorner,
            .tetLine,
            .tetSquare,
            .tetL,
            .tetT,
            .tetSkew,
            .almostSquare,
            .pentaLine,
            .pentaL,
            .pentaP,
            .pentaU,
            .pentaV,
            .pentaW
        ]

        XCTAssertEqual(Set(BlockType.allCases), expected)
        XCTAssertEqual(BlockType.allCases.count, expected.count)
    }

    func testDisplayNamesAreReadable() {
        XCTAssertEqual(BlockType.single.displayName, "Single Block")
        XCTAssertEqual(BlockType.domino.displayName, "Domino")
        XCTAssertEqual(BlockType.triCorner.displayName, "Corner Trio")
        XCTAssertEqual(BlockType.tetL.displayName, "L Tetromino")
        XCTAssertEqual(BlockType.tetSkew.displayName, "Skew Tetromino")
        XCTAssertEqual(BlockType.almostSquare.displayName, "Missing Corner Block")
        XCTAssertEqual(BlockType.pentaU.displayName, "U Pentomino")
    }

    func testBasePatternsMatchDefinitions() {
        XCTAssertEqual(BlockType.domino.pattern, [[true, true]])

        XCTAssertEqual(
            BlockType.triCorner.pattern,
            [
                [true, false],
                [true, true]
            ]
        )

        XCTAssertEqual(
            BlockType.tetL.pattern,
            [
                [true, false, false],
                [true, true, true]
            ]
        )

        XCTAssertEqual(
            BlockType.pentaU.pattern,
            [
                [true, false, true],
                [true, true, true]
            ]
        )
    }

    func testLegacyRawValuesMapToNewShapes() {
        XCTAssertEqual(BlockType(rawValue: "horizontal"), .domino)
        XCTAssertEqual(BlockType(rawValue: "vertical"), .domino)
        XCTAssertEqual(BlockType(rawValue: "lineThreeVertical"), .triLine)
        XCTAssertEqual(BlockType(rawValue: "lShape"), .triCorner)
        XCTAssertEqual(BlockType(rawValue: "tShape"), .tetT)
        XCTAssertEqual(BlockType(rawValue: "zigZag"), .tetSkew)
        XCTAssertEqual(BlockType(rawValue: "rectangleTwoByThree"), .tetL)
        XCTAssertEqual(BlockType(rawValue: "square"), .tetSquare)
        XCTAssertEqual(BlockType(rawValue: "squareThree"), .almostSquare)
    }

    func testVariationsIncludeRotationsAndMirrorsWhenNeeded() {
        XCTAssertEqual(BlockType.single.variations.count, 1)
        XCTAssertGreaterThanOrEqual(BlockType.domino.variations.count, 2)
        XCTAssertGreaterThanOrEqual(BlockType.triCorner.variations.count, 4)
        XCTAssertGreaterThanOrEqual(BlockType.tetL.variations.count, 8)
        XCTAssertEqual(BlockType.almostSquare.variations.count, 4)
        XCTAssertGreaterThanOrEqual(BlockType.tetSkew.variations.count, 4)
    }

    func testOccupiedPositionsAlignWithPattern() {
        let positions = BlockType.pentaP.occupiedPositions
        XCTAssertEqual(positions.count, 5)
        XCTAssertTrue(positions.contains(CGPoint(x: 1, y: 0)))
        XCTAssertTrue(positions.contains(CGPoint(x: 0, y: 2)))
    }
}
