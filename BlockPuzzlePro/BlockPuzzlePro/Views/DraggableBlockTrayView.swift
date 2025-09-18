import SwiftUI

// MARK: - Draggable Block Tray View

/// Tray containing draggable blocks at the bottom of the screen
struct DraggableBlockTrayView: View {
    
    // MARK: - Properties
    
    let blockFactory: BlockFactory
    let dragController: DragController
    let cellSize: CGFloat
    let onBlockDragStarted: (Int, BlockPattern) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            trayHeader

            HStack(spacing: 20) {
                ForEach(Array(blockFactory.availableBlocks.enumerated()), id: \.offset) { index, blockPattern in
                    DraggableBlockView(
                        blockPattern: blockPattern,
                        blockIndex: index,
                        cellSize: cellSize,
                        dragController: dragController,
                        onDragStarted: { pattern in
                            onBlockDragStarted(index, pattern)
                        }
                    )
                    .opacity(dragController.isBlockDragged(index) ? 0.35 : 1.0)
                    .scaleEffect(dragController.isBlockDragged(index) ? 0.92 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: dragController.isBlockDragged(index))
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(trayBackground)
    }
    
    // MARK: - View Components
    
    private var trayHeader: some View {
        HStack {
            Text("Available Blocks")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Drag a block to place it")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private var trayBackground: some View {
        let fillColor = UIColor.systemBackground.withAlphaComponent(colorScheme == .dark ? 0.4 : 0.9)
        let borderColor = UIColor.separator.withAlphaComponent(0.4)

        return RoundedRectangle(cornerRadius: 16)
            .fill(Color(fillColor))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(borderColor), lineWidth: 1)
            )
    }
}

// MARK: - Draggable Block View

struct DraggableBlockView: View {
    
    // MARK: - Properties
    
    let blockPattern: BlockPattern
    let blockIndex: Int
    let cellSize: CGFloat
    let dragController: DragController
    let onDragStarted: (BlockPattern) -> Void
    
    // MARK: - State
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var blockFrame: CGRect = .zero

    private var blockPadding: CGFloat {
        cellSize * 0.35
    }

    private var contentSize: CGSize {
        CGSize(
            width: blockPattern.size.width * cellSize,
            height: blockPattern.size.height * cellSize
        )
    }

    private var containerSize: CGSize {
        CGSize(
            width: contentSize.width + blockPadding * 2,
            height: contentSize.height + blockPadding * 2
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 4) {
            // Block visualization
            blockView
                .offset(dragOffset)
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .shadow(color: .black.opacity(isDragging ? 0.25 : 0.08), radius: isDragging ? 8 : 3, x: 0, y: isDragging ? 6 : 2)
                .gesture(dragGesture)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)

            // Block type label with drag state and fallback button
            VStack {
                Text(blockPattern.type.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Block Visualization
    
    private var blockView: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)
                .frame(width: containerSize.width, height: containerSize.height)

            ForEach(Array(blockPattern.occupiedPositions.enumerated()), id: \.offset) { _, position in
                RoundedRectangle(cornerRadius: cellSize * 0.2)
                    .fill(Color(blockPattern.color.uiColor))
                    .frame(width: cellSize, height: cellSize)
                    .offset(
                        x: blockPadding + position.x * cellSize,
                        y: blockPadding + position.y * cellSize
                    )
            }
        }
        .frame(width: containerSize.width, height: containerSize.height, alignment: .topLeading)
        .contentShape(Rectangle())
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        blockFrame = proxy.frame(in: .global)
                    }
                    .onChange(of: proxy.frame(in: .global)) { _, newValue in
                        blockFrame = newValue
                    }
            }
        )
    }
    
    // MARK: - Gesture Handling

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    onDragStarted(blockPattern)
                    let touchOffset: CGSize
                    if blockFrame == .zero {
                        touchOffset = .zero
                    } else {
                        touchOffset = CGSize(
                            width: value.startLocation.x - (blockFrame.minX + blockPadding),
                            height: value.startLocation.y - (blockFrame.minY + blockPadding)
                        )
                    }
                    dragController.startDrag(
                        blockIndex: blockIndex,
                        blockPattern: blockPattern,
                        at: value.startLocation,
                        touchOffset: touchOffset
                    )
                }

                dragOffset = value.translation
                dragController.updateDrag(to: value.location)
            }
            .onEnded { value in
                dragController.endDrag(at: value.location)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isDragging = false
                    dragOffset = .zero
                }
            }
    }
}

// MARK: - Floating Block Preview

/// Floating preview of the block being dragged
struct FloatingBlockPreview: View {
    
    // MARK: - Properties
    
    let blockPattern: BlockPattern
    let cellSize: CGFloat
    let position: CGPoint
    let isValid: Bool
    
    // MARK: - Body
    
    var body: some View {
        let blockWidth = cellSize * blockPattern.size.width
        let blockHeight = cellSize * blockPattern.size.height

        ZStack(alignment: .topLeading) {
            ForEach(Array(blockPattern.occupiedPositions.enumerated()), id: \.offset) { _, cellPosition in
                RoundedRectangle(cornerRadius: cellSize * 0.18)
                    .fill(Color(blockPattern.color.uiColor))
                    .opacity(isValid ? 0.85 : 0.45)
                    .frame(width: cellSize, height: cellSize)
                    .offset(
                        x: cellPosition.x * cellSize,
                        y: cellPosition.y * cellSize
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cellSize * 0.18)
                            .stroke(isValid ? Color.green : Color.red, lineWidth: 2)
                            .opacity(0.7)
                    )
            }
        }
        .frame(width: blockWidth, height: blockHeight, alignment: .topLeading)
        .position(
            x: position.x + blockWidth / 2,
            y: position.y + blockHeight / 2
        )
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.1), value: isValid)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        DraggableBlockTrayView(
            blockFactory: BlockFactory(),
            dragController: DragController(),
            cellSize: 30
        ) { index, pattern in
            print("Drag started for block \(index): \(pattern.type)")
        }
        
        Spacer()
        
        FloatingBlockPreview(
            blockPattern: BlockPattern(type: .lShape, color: .blue),
            cellSize: 30,
            position: CGPoint(x: 200, y: 300),
            isValid: true
        )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
}
