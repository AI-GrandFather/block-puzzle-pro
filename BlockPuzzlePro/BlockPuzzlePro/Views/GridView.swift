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

                GridCellRenderView(
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

private struct GridCellRenderView: View {
    let cell: GridCell
    let cellSize: CGFloat
    let theme: Theme

    @State private var pulseAnimation: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cellCornerRadius)
            .fill(cellFill)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                RoundedRectangle(cornerRadius: cellCornerRadius)
                    .stroke(cellBorder, lineWidth: isPreview ? 0 : 0.7)
            )
            .overlay(highlightOverlay)
    }

    private var isPreview: Bool {
        if case .preview = cell {
            return true
        }
        return false
    }

    private var cellFill: Color {
        switch cell {
        case .locked(let blockColor):
            return Color(blockColor.uiColor).opacity(0.8)
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

    private var cellCornerRadius: CGFloat {
        max(4, cellSize * 0.2)
    }

    @ViewBuilder
    private var highlightOverlay: some View {
        if case .occupied = cell {
            RoundedRectangle(cornerRadius: cellCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.clear,
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            EmptyView()
        }
    }
}

#Preview {
    GridView(
        gameEngine: GameEngine(gameMode: .classic),
        dragController: DragController(),
        cellSize: 32,
        gridSpacing: 2
    )
}
