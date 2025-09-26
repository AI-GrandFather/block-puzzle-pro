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
                // Use global coordinate space so drag math lines up with grid projections
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        // CRITICAL: Check if ANY drag is already active to prevent multiple simultaneous drags
                        if !didSendDragBegan && dragController.dragState == .idle {
                            DebugLog.trace("🎮 Block \(blockIndex): Starting drag, controller state: \(dragController.dragState)")
                            didSendDragBegan = true
                            dragGestureID = UUID() // New gesture ID

                            let touchOffset: CGSize
                            if blockFrame != .zero {
                                touchOffset = CGSize(
                                    width: value.startLocation.x - blockFrame.minX,
                                    height: value.startLocation.y - blockFrame.minY
                                )
                            } else {
                                touchOffset = .zero
                            }

                            DebugLog.trace("🧭 Block \(blockIndex): startLocation=\(value.startLocation) blockFrame.origin=\(blockFrame.origin) touchOffset=\(touchOffset)")

                            // Start drag through controller - use coordinates directly from named space
                            dragController.startDrag(
                                blockIndex: blockIndex,
                                blockPattern: blockPattern,
                                at: value.startLocation,
                                touchOffset: touchOffset
                            )

                        } else if !didSendDragBegan {
                            DebugLog.trace("🚫 Block \(blockIndex): Cannot start drag, controller state: \(dragController.dragState)")
                        }

                        // Only update drag if this is the actively dragged block
                        if dragController.isBlockDragged(blockIndex) {
                            dragController.updateDrag(to: value.location)
                            DebugLog.trace("📍 Block \(blockIndex): updateDrag location=\(value.location) currentDragPosition=\(dragController.currentDragPosition) touch=\(dragController.currentTouchLocation)")
                        }
                    }
                    .onEnded { value in
                        DebugLog.trace("🏁 Block \(blockIndex): Gesture ended, isBlockDragged: \(dragController.isBlockDragged(blockIndex))")

                        // Only end drag if this is the actively dragged block
                        if dragController.isBlockDragged(blockIndex) {
                            DebugLog.trace("📍 Block \(blockIndex): Calling endDrag")
                            dragController.endDrag(at: value.location)
                        } else {
                            DebugLog.trace("⏭️ Block \(blockIndex): Skipping endDrag - not actively dragged")
                        }

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
    let paddingFactor: CGFloat
    let horizontalInset: CGFloat
    let slotSpacing: CGFloat
    let onBlockDragged: (Int, BlockPattern) -> Void

        @Environment(\.colorScheme) private var colorScheme

    init(
        blockFactory: BlockFactory,
        dragController: DragController,
        cellSize: CGFloat,
        paddingFactor: CGFloat = 0.25,
        horizontalInset: CGFloat = 16,
        slotSpacing: CGFloat = 14,
        onBlockDragged: @escaping (Int, BlockPattern) -> Void
    ) {
        _blockFactory = ObservedObject(wrappedValue: blockFactory)
        _dragController = ObservedObject(wrappedValue: dragController)
        self.cellSize = cellSize
        self.paddingFactor = paddingFactor
        self.horizontalInset = horizontalInset
        self.slotSpacing = slotSpacing
        self.onBlockDragged = onBlockDragged
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: slotSpacing) {
                ForEach(Array(blockFactory.getTraySlots().enumerated()), id: \.offset) { index, blockPattern in
                    traySlot(for: blockPattern, index: index)
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.vertical, 14)
            .background(trayBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(trayBorderColor, lineWidth: 1)
            )
            .shadow(color: trayShadowColor, radius: 10, x: 0, y: 6)
        }
        .onAppear(perform: setupDragCallbacks)
    }

    // MARK: - Slot Composition

    private func traySlot(for blockPattern: BlockPattern?, index: Int) -> some View {
        let blockSize = blockExtent(for: blockPattern)
        let padding = blockPadding(for: blockPattern)
        let slotSize = CGSize(
            width: blockSize.width + padding * 2,
            height: blockSize.height + padding * 2
        )

        let isDragged = dragController.isBlockDragged(index)

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(slotBackgroundColor(isDragged: isDragged))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(slotBorderColor(isDragged: isDragged), lineWidth: isDragged ? 2 : 1)
                )

            if let pattern = blockPattern {
                DraggableBlockView(
                    blockPattern: pattern,
                    blockIndex: index,
                    cellSize: cellSize,
                    dragController: dragController
                )
                .padding(padding)
                .opacity(isDragged ? 0.25 : 1.0)
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .padding(padding)
            }
        }
        .frame(width: slotSize.width, height: slotSize.height, alignment: .topLeading)
        .animation(.easeInOut(duration: 0.15), value: isDragged)
        .accessibilityLabel(slotAccessibilityLabel(for: blockPattern, index: index))
    }

    // MARK: - Helpers

    private func blockExtent(for blockPattern: BlockPattern?) -> CGSize {
        guard let pattern = blockPattern else {
            return CGSize(width: cellSize * 2, height: cellSize * 2)
        }

        return CGSize(
            width: CGFloat(pattern.size.width) * cellSize,
            height: CGFloat(pattern.size.height) * cellSize
        )
    }

    private func blockPadding(for blockPattern: BlockPattern?) -> CGFloat {
        // Smaller patterns get a little extra breathing room
        let basePadding = cellSize * paddingFactor
        guard let pattern = blockPattern else { return basePadding }
        let maxDimension = max(pattern.size.width, pattern.size.height)
        let scaleReducer = max(1.0, CGFloat(maxDimension))
        return max(basePadding * 0.75, basePadding / scaleReducer + 4)
    }

    private var trayBackground: Color {
        colorScheme == .dark ? Color(UIColor.systemGray5).opacity(0.65) : Color.white.opacity(0.92)
    }

    private var trayBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color(UIColor.systemGray3).opacity(0.45)
    }

    private var trayShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.12)
    }

    private func slotBackgroundColor(isDragged: Bool) -> Color {
        if isDragged {
            return Color.accentColor.opacity(0.25)
        }
        return colorScheme == .dark ? Color.white.opacity(0.16) : Color(UIColor.systemGray6)
    }

    private func slotBorderColor(isDragged: Bool) -> Color {
        if isDragged {
            return Color.accentColor.opacity(0.55)
        }
        return Color.white.opacity(colorScheme == .dark ? 0.35 : 0.28)
    }

    private func slotAccessibilityLabel(for blockPattern: BlockPattern?, index: Int) -> String {
        guard let blockPattern else {
            return "Tray slot \(index + 1), empty"
        }
        return "Tray slot \(index + 1), \(blockPattern.type.displayName)"
    }

    private func setupDragCallbacks() {
        dragController.onDragBegan = { blockIndex, blockPattern, _ in
            onBlockDragged(blockIndex, blockPattern)
        }
    }
}

// MARK: - Preview

#Preview {
    let factory = BlockFactory()
    let controller = DragController()

    return VStack {
        Spacer()

        DraggableBlockTrayView(
            blockFactory: factory,
            dragController: controller,
            cellSize: 36,
            paddingFactor: 0.25,
            horizontalInset: 16,
            slotSpacing: 14
        ) { index, pattern in
            print("Block \(index) drag started: \(pattern.type)")
        }
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
}


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
