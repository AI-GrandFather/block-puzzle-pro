import SwiftUI

// MARK: - Simple Grid View

/// Simplified grid view without placement engine dependencies
struct SimpleGridView: View {
    
    // MARK: - Properties
    
    @ObservedObject var gameEngine: GameEngine
    @ObservedObject var dragController: DragController
    
    let cellSize: CGFloat
    let gridSpacing: CGFloat
    
    // MARK: - Body
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 10), spacing: gridSpacing) {
            ForEach(0..<100, id: \.self) { index in
                let row = index / 10
                let col = index % 10
                let position = GridPosition(unsafeRow: row, unsafeColumn: col)
                
                SimpleGridCellView(
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

// MARK: - Simple Grid Cell View

struct SimpleGridCellView: View {
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
    SimpleGridView(
        gameEngine: GameEngine(),
        dragController: DragController(),
        cellSize: 30,
        gridSpacing: 2
    )
}