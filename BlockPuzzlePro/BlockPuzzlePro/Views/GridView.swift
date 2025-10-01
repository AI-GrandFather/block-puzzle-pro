import SwiftUI

/// SwiftUI view that renders the active game grid without additional highlight effects.
struct GridView: View {
    @ObservedObject var gameEngine: GameEngine
    @ObservedObject var dragController: DragController

    let cellSize: CGFloat
    let gridSpacing: CGFloat

    @State private var currentTheme: Theme = Theme.current
    @Environment(\.colorScheme) private var colorScheme

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
                    cellSize: cellSize,
                    theme: currentTheme
                )
            }
        }
        .frame(width: contentSide, height: contentSide)
        .padding(gridSpacing)
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { notification in
            if let newTheme = notification.object as? Theme {
                currentTheme = newTheme
            }
        }
    }
}

private struct GridCellView: View {
    let cell: GridCell
    let cellSize: CGFloat
    let theme: Theme

    @State private var pulseAnimation: Bool = false

    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                Rectangle()
                    .stroke(cellBorder, lineWidth: isPreview ? 0 : 0.7)  // NO border on preview
            )
            .shadow(
                color: Color.clear,  // NO shadow
                radius: 0,
                x: 0,
                y: 0
            )
    }

    private var isPreview: Bool {
        if case .preview = cell {
            return true
        }
        return false
    }

    private var cellColor: Color {
        switch cell {
        case .empty, .preview:
            // Use theme-aware empty cell color (treat preview as empty)
            if theme.isDarkTheme {
                return Color(theme.backgroundColor).opacity(0.3)
            } else {
                return Color.white.opacity(0.85)
            }
        case .occupied(let blockColor):
            return Color(blockColor.uiColor)
        }
    }

    private var cellBorder: Color {
        // Theme-aware grid lines for all cells
        return Color(theme.gridLineColor)
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
