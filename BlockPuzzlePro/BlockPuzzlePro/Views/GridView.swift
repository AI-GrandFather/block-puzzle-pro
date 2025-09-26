import SwiftUI

/// SwiftUI view that renders the active game grid without additional highlight effects.
struct GridView: View {
    @ObservedObject var gameEngine: GameEngine
    @ObservedObject var dragController: DragController

    let cellSize: CGFloat
    let gridSpacing: CGFloat

    init(
        gameEngine: GameEngine,
        dragController: DragController,
        cellSize: CGFloat,
        gridSpacing: CGFloat = 1
    ) {
        self.gameEngine = gameEngine
        self.dragController = dragController
        self.cellSize = cellSize
        self.gridSpacing = gridSpacing
    }

    var body: some View {
        let gridSize = gameEngine.gridSize
        let contentSide = (cellSize * CGFloat(gridSize)) + gridSpacing * CGFloat(gridSize - 1)

        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: gridSize),
            spacing: gridSpacing
        ) {
            ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                let row = index / gridSize
                let column = index % gridSize
                let position = GridPosition(unsafeRow: row, unsafeColumn: column)

                GridCellView(
                    cell: gameEngine.cell(at: position) ?? .empty,
                    cellSize: cellSize
                )
            }
        }
        .frame(width: contentSide, height: contentSide)
        .padding(gridSpacing)
    }
}

private struct GridCellView: View {
    let cell: GridCell
    let cellSize: CGFloat

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                Rectangle()
                    .stroke(cellBorder, lineWidth: 0.7)
            )
    }

    private var cellColor: Color {
        switch cell {
        case .empty:
            return Color.white.opacity(0.85)
        case .occupied(let blockColor):
            return Color(blockColor.uiColor)
        case .preview(let blockColor):
            return Color(blockColor.uiColor).opacity(0.5)
        }
    }

    private var cellBorder: Color {
        Color(white: 1.0).opacity(0.55)
    }
}

#Preview {
    GridView(
        gameEngine: GameEngine(gameMode: .grid10x10),
        dragController: DragController(),
        cellSize: 32,
        gridSpacing: 2
    )
}
