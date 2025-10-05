import SwiftUI
import UIKit

// MARK: - Simplified Block Tray

/// Clean, simple block tray with perfect drag handling
struct SimplifiedBlockTray: View {

    // MARK: - Properties

    @ObservedObject var blockFactory: BlockFactory
    @ObservedObject var dragController: DragControllerV2

    let cellSize: CGFloat
    let slotSize: CGFloat
    let spacing: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(Array(blockFactory.getTraySlots().enumerated()), id: \.offset) { index, pattern in
                if let blockPattern = pattern {
                    TraySlot(
                        pattern: blockPattern,
                        index: index,
                        cellSize: cellSize,
                        slotSize: slotSize,
                        dragController: dragController,
                        isDragged: dragController.isBlockDragged(index)
                    )
                } else {
                    EmptySlot(size: slotSize)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Tray Slot

private struct TraySlot: View {

    let pattern: BlockPattern
    let index: Int
    let cellSize: CGFloat
    let slotSize: CGFloat

    @ObservedObject var dragController: DragControllerV2
    let isDragged: Bool

    @State private var blockFrame: CGRect = .zero
    @State private var isPressed: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // The actual block
                BlockView(
                    blockPattern: pattern,
                    cellSize: cellSize,
                    isInteractive: true
                )
                .frame(width: blockWidth, height: blockHeight)
                .scaleEffect(displayScale)
                .frame(width: slotSize, height: slotSize)
                .opacity(isDragged ? 0.0 : 1.0)  // Hide when dragging
                .scaleEffect(isPressed ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isPressed)
                .animation(.easeOut(duration: 0.15), value: isDragged)
            }
            .frame(width: slotSize, height: slotSize)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear {
                updateBlockFrame(in: geometry)
            }
            .onChange(of: geometry.frame(in: .global)) { _, _ in
                updateBlockFrame(in: geometry)
            }
        }
        .frame(width: slotSize, height: slotSize)
    }

    // MARK: - Computed Properties

    private var blockWidth: CGFloat {
        CGFloat(pattern.size.width) * cellSize
    }

    private var blockHeight: CGFloat {
        CGFloat(pattern.size.height) * cellSize
    }

    private var displayScale: CGFloat {
        let maxDimension = max(blockWidth, blockHeight)
        guard maxDimension > 0 else { return 1.0 }
        let availableSpace = slotSize * 0.85
        return min(1.0, availableSpace / maxDimension)
    }

    private var actualDisplayWidth: CGFloat {
        blockWidth * displayScale
    }

    private var actualDisplayHeight: CGFloat {
        blockHeight * displayScale
    }

    // MARK: - Drag Gesture

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                // Press state
                if !isPressed {
                    isPressed = true
                }

                // Start drag on first change
                if case .idle = dragController.dragState {
                    // Calculate the block's actual screen position
                    let blockOrigin = CGPoint(
                        x: blockFrame.midX - actualDisplayWidth / 2,
                        y: blockFrame.midY - actualDisplayHeight / 2
                    )

                    // The cell size in the tray (scaled)
                    let trayCellSize = cellSize * displayScale

                    dragController.startDrag(
                        blockIndex: index,
                        pattern: pattern,
                        touchLocation: value.location,
                        blockOrigin: blockOrigin,
                        trayCellSize: trayCellSize
                    )
                } else {
                    // Update drag
                    dragController.updateDrag(to: value.location)
                }
            }
            .onEnded { value in
                isPressed = false
                dragController.endDrag(at: value.location)
            }
    }

    // MARK: - Helpers

    private func updateBlockFrame(in geometry: GeometryProxy) {
        blockFrame = geometry.frame(in: .global)
    }
}

// MARK: - Empty Slot

private struct EmptySlot: View {

    let size: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                Color.white.opacity(colorScheme == .dark ? 0.2 : 0.3),
                style: StrokeStyle(lineWidth: 1, dash: [4, 6])
            )
            .frame(width: size * 0.7, height: size * 0.7)
            .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview {
    let factory = BlockFactory()
    let controller = DragControllerV2()

    return VStack {
        Spacer()
        SimplifiedBlockTray(
            blockFactory: factory,
            dragController: controller,
            cellSize: 32,
            slotSize: 90,
            spacing: 12
        )
        Spacer()
    }
    .background(Color(UIColor.systemBackground))
}
