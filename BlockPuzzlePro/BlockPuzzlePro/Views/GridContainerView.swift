import SwiftUI

// MARK: - Grid Container View

/// Container view for the game grid with drag-drop integration
struct GridContainerView: View {
    
    // MARK: - Properties
    
    let gameEngine: GameEngine
    let dragController: DragController
    let availableSize: CGSize
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var gridFrame: CGRect = .zero
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background
                gridBackground
                
                // Grid cells
                gridCells
                
            }
            .clipped()
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            gridFrame = geo.frame(in: .global)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            gridFrame = newFrame
                        }
                }
            )
        }
        .frame(width: availableSize.width, height: availableSize.height)
    }
    
    // MARK: - Grid Components
    
    private var gridBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(UIColor.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 2)
            )
    }
    
    private var gridCells: some View {
        let gridSize = gameEngine.gridSize

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: gridSize), spacing: 1) {
            ForEach(0..<(gridSize * gridSize), id: \.self) { index in
                let row = index / gridSize
                let col = index % gridSize
                let position = GridPosition(unsafeRow: row, unsafeColumn: col)
                
                GridCellView(
                    position: position,
                    cell: gameEngine.cell(at: position) ?? .empty
                )
                .aspectRatio(1, contentMode: .fit)
            }
        }
        .padding(4)
    }
    
}

// MARK: - Grid Cell View

struct GridCellView: View {
    let position: GridPosition
    let cell: GridCell
    
    var body: some View {
        Rectangle()
            .fill(cellColor)
            .overlay(
                Rectangle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
            )
    }
    
    private var cellColor: Color {
        switch cell {
        case .locked(let blockColor):
            return Color(blockColor.uiColor).opacity(0.8)
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
    GridContainerView(
        gameEngine: GameEngine(gameMode: .classic),
        dragController: DragController(deviceManager: DeviceManager()),
        availableSize: CGSize(width: 300, height: 300)
    )
}
