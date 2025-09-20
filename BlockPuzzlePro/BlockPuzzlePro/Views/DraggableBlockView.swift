import SwiftUI

// MARK: - Draggable Block View

/// SwiftUI view that makes blocks draggable with smooth animations
struct DraggableBlockView: View {
    
    // MARK: - Properties
    
    let blockPattern: BlockPattern
    let blockIndex: Int
    let cellSize: CGFloat
    
    @ObservedObject var dragController: DragController
    @Environment(\.colorScheme) private var colorScheme
    // Removed: @Environment(\.deviceManager) private var deviceManager
    
    // MARK: - State

    @State private var isPressed: Bool = false
    @State private var didSendDragBegan: Bool = false
    @State private var blockFrame: CGRect = .zero
    @State private var dragGestureID: UUID = UUID() // Unique ID for each gesture to prevent conflicts
    
    // MARK: - Computed Properties
    
    private var isDragged: Bool {
        dragController.isBlockDragged(blockIndex)
    }
    
    private var dragOffset: CGSize {
        isDragged ? dragController.dragOffset : .zero
    }
    
    private var dragScale: CGFloat {
        isDragged ? dragController.dragScale : (isPressed ? 0.95 : 1.0)
    }
    
    private var dragRotation: Double {
        isDragged ? dragController.dragRotation : 0.0
    }
    
    private var shadowOffset: CGSize {
        isDragged ? dragController.shadowOffset : (isPressed ? CGSize(width: 1, height: 2) : .zero)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main block view
            BlockView(
                blockPattern: blockPattern,
                cellSize: cellSize,
                isInteractive: true
            )
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
            .scaleEffect(dragScale)
            .rotationEffect(.degrees(dragRotation))
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
            .offset(dragOffset)
            .zIndex(isDragged ? 1000 : 0) // Bring to front when dragging
            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
            .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.85, blendDuration: 0), value: dragScale)
            .animation(.linear(duration: 0.016), value: dragRotation) // ~1 frame at 60Hz
            .onLongPressGesture(minimumDuration: 0.2) { isPressing in
                // Handle press feedback with device-optimized animation
                let animationDuration: Double = 0.15
                withAnimation(.easeInOut(duration: animationDuration)) {
                    isPressed = isPressing
                }
            } perform: {
                // Long press not needed for drag, handled by drag gesture
            }
            .gesture(
                // Optimized drag gesture with better state management
                DragGesture(minimumDistance: 2, coordinateSpace: .global) // Small minimum distance to prevent accidental drags
                    .onChanged { value in
                        // Ensure drag begins exactly once per gesture
                        if !didSendDragBegan {
                            didSendDragBegan = true
                            dragGestureID = UUID() // New gesture ID

                            let touchOffset: CGSize
                            if blockFrame != .zero {
                                touchOffset = CGSize(
                                    width: value.startLocation.x - blockFrame.minX,
                                    height: value.startLocation.y - blockFrame.minY
                                )
                            } else {
                                // Fallback when frame is not available
                                touchOffset = .zero
                            }

                            // Start drag through controller - this handles state transitions
                            dragController.startDrag(
                                blockIndex: blockIndex,
                                blockPattern: blockPattern,
                                at: value.startLocation,
                                touchOffset: touchOffset
                            )
                        }

                        // Always update drag position for smooth tracking
                        dragController.updateDrag(to: value.location)
                    }
                    .onEnded { value in
                        // End drag through controller
                        dragController.endDrag(at: value.location)

                        // Reset gesture state
                        didSendDragBegan = false
                        dragGestureID = UUID()

                        // Reset visual state
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                            isPressed = false
                        }
                    }
            )
            
            // Dragged state overlay
            if isDragged {
                dragOverlay
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Drag to place this block on the game board")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }
    
    // MARK: - View Components
    
    private var dragOverlay: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 2
            )
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
            )
            .frame(
                width: blockPattern.size.width * cellSize + 8,
                height: blockPattern.size.height * cellSize + 8
            )
    }
    
    private var shadowColor: Color {
        if isDragged {
            return Color.black.opacity(0.3)
        } else if isPressed {
            return Color.gray.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDragged {
            return 8
        } else if isPressed {
            return 4
        } else {
            return 0
        }
    }
    
    // Removed the unused dragGesture property
    
    // MARK: - Accessibility
    
    private var accessibilityLabel: String {
        let typeDescription = blockPattern.type.displayName
        let colorDescription = blockPattern.color.accessibilityDescription
        let sizeDescription = "\(blockPattern.cellCount) cell\(blockPattern.cellCount > 1 ? "s" : "")"
        let dragState = isDragged ? "being dragged" : "available"
        
        return "\(colorDescription) \(typeDescription), \(sizeDescription), \(dragState)"
    }
}

// MARK: - Floating Drag Preview

/// A floating preview of the block during drag operations
struct FloatingBlockPreview: View {
    
    // MARK: - Properties
    
    let blockPattern: BlockPattern
    let cellSize: CGFloat
    let position: CGPoint
    let isValid: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        let blockWidth = blockPattern.size.width * cellSize
        let blockHeight = blockPattern.size.height * cellSize

        BlockView(
            blockPattern: blockPattern,
            cellSize: cellSize,
            isInteractive: false
        )
        .frame(width: blockWidth, height: blockHeight, alignment: .topLeading)
        .opacity(previewOpacity)
        .overlay(validationOverlay)
        .shadow(color: shadowColor, radius: 8, x: 2, y: 4)
        .position(
            x: position.x + blockWidth / 2,
            y: position.y + blockHeight / 2
        )
        .allowsHitTesting(false)
        .zIndex(999)
    }

    // MARK: - View Components

    private var previewOpacity: Double {
        isValid ? 0.85 : 0.45
    }

    private var validationOverlay: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(isValid ? Color.green : Color.red, lineWidth: 2)
            .opacity(isValid ? 0.35 : 0.6)
            .animation(.easeInOut(duration: 0.1), value: isValid)
    }

    private var shadowColor: Color {
        let base = isValid ? Color.green : Color.red
        return base.opacity(colorScheme == .dark ? 0.35 : 0.25)
    }
}

// MARK: - Enhanced Block Tray with Drag Support

/// Block tray with integrated drag and drop support
struct DraggableBlockTrayView: View {
    
    // MARK: - Properties
    
    @ObservedObject var blockFactory: BlockFactory
    @ObservedObject var dragController: DragController
    
    let cellSize: CGFloat
    let onBlockDragged: (Int, BlockPattern) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Tray header
            trayHeader
            
            // Main tray container with draggable blocks
            HStack(spacing: 0) {
                ForEach(Array(blockFactory.getAvailableBlocks().enumerated()), id: \.offset) { index, blockPattern in
                    draggableBlockSlot(for: blockPattern, at: index)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(trayBackground)
            .cornerRadius(12)
            .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        }
        .onAppear {
            setupDragCallbacks()
        }
    }
    
    // MARK: - View Components
    
    private var trayHeader: some View {
        HStack {
            Text("Available Blocks")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(blockFactory.getAvailableBlocks().count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    private func draggableBlockSlot(for blockPattern: BlockPattern, at index: Int) -> some View {
        let blockSize = calculateBlockSlotSize()
        let isDragged = dragController.isBlockDragged(index)
        
        return VStack(spacing: 8) {
            // Block slot container
            ZStack {
                // Slot background (remains visible when block is dragged)
                RoundedRectangle(cornerRadius: 8)
                    .fill(slotBackgroundColor(isDragged: isDragged))
                    .frame(width: blockSize.width, height: blockSize.height)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                slotBorderColor(isDragged: isDragged),
                                lineWidth: isDragged ? 2 : 1
                            )
                    )
                
                // Draggable block (invisible when being dragged)
                if !isDragged {
                    DraggableBlockView(
                        blockPattern: blockPattern,
                        blockIndex: index,
                        cellSize: cellSize,
                        dragController: dragController
                    )
                }
            }
            .frame(width: blockSize.width, height: blockSize.height)
            .contentShape(Rectangle())
            
            // Block type indicator
            Text(blockTypeIndicator(for: blockPattern.type))
                .font(.caption2)
                .foregroundColor(.secondary)
                .opacity(isDragged ? 0.5 : 0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
    
    private var trayBackground: Color {
        colorScheme == .dark ?
            Color(UIColor.systemGray6) :
            Color(UIColor.systemGray5)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ?
            Color.black.opacity(0.3) :
            Color.gray.opacity(0.2)
    }
    
    private func slotBackgroundColor(isDragged: Bool) -> Color {
        if isDragged {
            return colorScheme == .dark ?
                Color(UIColor.systemGray5) :
                Color(UIColor.systemGray4)
        } else {
            return Color.clear
        }
    }
    
    private func slotBorderColor(isDragged: Bool) -> Color {
        if isDragged {
            return Color.blue.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateBlockSlotSize() -> CGSize {
        let maxBlockWidth: CGFloat = 2 * cellSize + 2
        let maxBlockHeight: CGFloat = 2 * cellSize + 2
        let padding: CGFloat = 16
        
        return CGSize(
            width: maxBlockWidth + padding,
            height: maxBlockHeight + padding
        )
    }
    
    private func blockTypeIndicator(for blockType: BlockType) -> String {
        switch blockType {
        case .single: return "•"
        case .horizontal: return "••"
        case .lShape: return "L"
        }
    }
    
    private func setupDragCallbacks() {
        dragController.onDragBegan = { (blockIndex: Int, blockPattern: BlockPattern, position: CGPoint) in
            onBlockDragged(blockIndex, blockPattern)
        }
    }
}

// MARK: - Preview

#Preview {
    let _ = BlockFactory() // Unused for now until preview is fully implemented
    // let dragController = DragController() // Commented out until DragController is added to project
    
    VStack {
        Spacer()
        
        // Preview temporarily disabled until DragController is added to project
        Text("DraggableBlockTrayView Preview")
        
        // DraggableBlockTrayView(
        //     blockFactory: mockBlockFactory,
        //     dragController: dragController,
        //     cellSize: 35
        // ) { index, blockPattern in
        //     print("Block \(index) started dragging: \(blockPattern.type)")
        // }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
}
