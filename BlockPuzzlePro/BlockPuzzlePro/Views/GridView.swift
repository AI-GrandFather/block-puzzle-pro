import SwiftUI

// MARK: - Grid View (Simplified)

/// SwiftUI view that displays the 10x10 game grid
struct GridView: View {
    
    // MARK: - Properties
    
    @ObservedObject var gameEngine: GameEngine
    @ObservedObject var dragController: DragController
    
    let cellSize: CGFloat
    let gridSpacing: CGFloat
    
    // MARK: - Initialization
    
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
    
    // MARK: - Body
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 10), spacing: gridSpacing) {
            ForEach(0..<100, id: \.self) { index in
                let row = index / 10
                let col = index % 10
                let position = GridPosition(unsafeRow: row, unsafeColumn: col)
                
                GridCellView(
                    position: position,
                    cell: gameEngine.cell(at: position) ?? .empty,
                    cellSize: cellSize
                )
            }
        }
        .padding(gridSpacing)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Grid Cell View

struct GridCellView: View {
    let position: GridPosition
    let cell: GridCell
    let cellSize: CGFloat
    
    var body: some View {
        Rectangle()
            .fill(cellColor)
            .frame(width: cellSize, height: cellSize)
            .overlay(
                Rectangle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
            )
    }
    
    private var cellColor: Color {
        switch cell {
        case .empty:
            return Color(UIColor.systemBackground)
        case .occupied(let blockColor):
            return Color(blockColor.uiColor)
        case .preview(let blockColor):
            return Color(blockColor.uiColor).opacity(0.5)
        }
    }
}

// MARK: - Preview

#Preview {
    GridView(
        gameEngine: GameEngine(),
        dragController: DragController(),
        cellSize: 30,
        gridSpacing: 2
    )
}