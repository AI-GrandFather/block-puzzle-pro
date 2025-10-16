import SwiftUI

// MARK: - Draggable Block View

/// SwiftUI view that makes blocks draggable with smooth animations
struct DraggableBlockView: View {

    // MARK: - Properties

    let blockPattern: BlockPattern
    let blockIndex: Int
    let cellSize: CGFloat
    let restingScale: CGFloat
    let containerSize: CGFloat

    @ObservedObject var dragController: DragController
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var isPressed: Bool = false
    @State private var didSendDragBegan: Bool = false
    @State private var blockFrame: CGRect = .zero
    @State private var containerFrame: CGRect = .zero
    @State private var dragGestureID: UUID = UUID()

    // MARK: - Computed Properties

    private var isDragged: Bool {
        dragController.isBlockDragged(blockIndex)
    }

    private var dragOffset: CGSize {
        isDragged ? dragController.dragOffset : .zero
    }

    private var blockScale: CGFloat {
        if isDragged {
            return dragController.dragScale
        }

        let baseScale = restingScale
        return isPressed ? baseScale * 0.95 : baseScale
    }

    private var dragRotation: Double {
        isDragged ? dragController.dragRotation : 0.0
    }

    private var shadowOffset: CGSize {
        isDragged ? dragController.shadowOffset : (isPressed ? CGSize(width: 1, height: 2) : .zero)
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

    private var baseBlockSize: CGSize {
        CGSize(
            width: CGFloat(blockPattern.size.width) * cellSize,
            height: CGFloat(blockPattern.size.height) * cellSize
        )
    }

    private var displaySize: CGSize {
        CGSize(
            width: baseBlockSize.width * blockScale,
            height: baseBlockSize.height * blockScale
        )
    }

    /// Vicinity touch expansion - extends hit area around block for easier tapping
    /// Research: 12-16pt expansion is standard for touch targets on mobile
    private var vicinityTouchExpansion: CGFloat {
        // Adaptive expansion based on block size
        // Smaller blocks get more help, larger blocks less
        let blockArea = baseBlockSize.width * baseBlockSize.height
        let normalizedArea = blockArea / (cellSize * cellSize) // Blocks relative to single cell

        if normalizedArea < 4 {
            // Small blocks (1-3 cells): 16pt expansion
            return 16
        } else if normalizedArea < 9 {
            // Medium blocks (4-8 cells): 14pt expansion
            return 14
        } else {
            // Large blocks (9+ cells): 12pt expansion
            return 12
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            blockContent

            if isDragged {
                dragOverlay
            }
        }
        .frame(width: containerSize, height: containerSize)
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: shadowOffset.width,
            y: shadowOffset.height
        )
        .offset(dragOffset)
        .offset(y: isDragged ? dragController.liftOffsetY : 0)  // Apply visual lift
        .zIndex(isDragged ? 1000 : 0)
        .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
        .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.85, blendDuration: 0), value: blockScale)
        .animation(.linear(duration: 0.016), value: dragRotation)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8, blendDuration: 0), value: dragController.liftOffsetY)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Drag to place this block on the game board")
        .accessibilityAddTraits(.allowsDirectInteraction)
        .onChange(of: dragController.dragScale) { _, _ in
            refreshBlockFrame()
        }
        .onChange(of: isPressed) { _, _ in
            refreshBlockFrame()
        }
        .onChange(of: dragController.dragState) { _, _ in
            refreshBlockFrame()
        }
    }

    // MARK: - Building Blocks

    private var blockContent: some View {
        BlockView(
            blockPattern: blockPattern,
            cellSize: cellSize,
            isInteractive: true
        )
        .frame(width: baseBlockSize.width, height: baseBlockSize.height, alignment: .topLeading)
        .scaleEffect(blockScale, anchor: .center)
        .rotationEffect(.degrees(dragRotation))
        .frame(width: containerSize, height: containerSize, alignment: .center)
        .background(containerGeometry)
        // VICINITY TOUCH: Expand hit area around piece for easier selection
        .contentShape(
            Rectangle()
                .inset(by: -vicinityTouchExpansion)
        )
        .onLongPressGesture(minimumDuration: 0.2) { isPressing in
            let animationDuration: Double = 0.15
            withAnimation(.easeInOut(duration: animationDuration)) {
                isPressed = isPressing
            }
        } perform: {}
        .modifier(DragGestureModifier(
            blockIndex: blockIndex,
            blockPattern: blockPattern,
            blockFrame: blockFrame,
            baseBlockSize: baseBlockSize,
            dragController: dragController,
            didSendDragBegan: $didSendDragBegan,
            dragGestureID: $dragGestureID,
            isPressed: $isPressed
        ))
    }

    private var containerGeometry: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    containerFrame = proxy.frame(in: .global)
                    refreshBlockFrame()
                }
                .onChange(of: proxy.frame(in: .global)) { _, newValue in
                    containerFrame = newValue
                    refreshBlockFrame()
                }
        }
    }

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
                width: displaySize.width + 8,
                height: displaySize.height + 8
            )
            .position(x: containerSize / 2, y: containerSize / 2)
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

    private var accessibilityLabel: String {
        let typeDescription = blockPattern.type.displayName
        let colorDescription = blockPattern.color.accessibilityDescription
        let sizeDescription = "\(blockPattern.cellCount) cell\(blockPattern.cellCount > 1 ? "s" : "")"
        let dragState = isDragged ? "being dragged" : "available"

        return "\(colorDescription) \(typeDescription), \(sizeDescription), \(dragState)"
    }

    // MARK: - Helpers

    private func refreshBlockFrame() {
        guard containerFrame != .zero else { return }

        let offsetX = (containerSize - displaySize.width) / 2
        let offsetY = (containerSize - displaySize.height) / 2
        let origin = CGPoint(
            x: containerFrame.origin.x + offsetX,
            y: containerFrame.origin.y + offsetY
        )

        blockFrame = CGRect(origin: origin, size: displaySize)
    }
}

// MARK: - Drag Gesture Modifier (Option D: ProMotion-Optimized)

/// ViewModifier that applies the appropriate drag gesture based on iOS version
struct DragGestureModifier: ViewModifier {
    let blockIndex: Int
    let blockPattern: BlockPattern
    let blockFrame: CGRect
    let baseBlockSize: CGSize
    @ObservedObject var dragController: DragController
    @Binding var didSendDragBegan: Bool
    @Binding var dragGestureID: UUID
    @Binding var isPressed: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(
                ProMotionDragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onBegan { location, startLocation in
                        handleDragBegan(location: location, startLocation: startLocation)
                    }
                    .onChanged { location, translation, startLocation in
                        handleDragChanged(location: location)
                    }
                    .onEnded { location, translation, startLocation in
                        handleDragEnded(location: location)
                    }
                    .onCancelled {
                        handleDragCancelled()
                    }
            )
        } else {
            content.gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if !didSendDragBegan {
                            handleDragBegan(location: value.location, startLocation: value.startLocation)
                        }
                        handleDragChanged(location: value.location)
                    }
                    .onEnded { value in
                        handleDragEnded(location: value.location)
                    }
            )
        }
    }

    // MARK: - Gesture Handlers

    private func handleDragBegan(location: CGPoint, startLocation: CGPoint) {
        guard !didSendDragBegan && dragController.dragState == .idle else {
            DebugLog.trace("🚫 Block \(blockIndex): Cannot start drag, already began or controller busy")
            return
        }

        DebugLog.trace("🎮 Block \(blockIndex): Starting drag, controller state: \(dragController.dragState)")
        didSendDragBegan = true
        dragGestureID = UUID()

        let touchOffset: CGSize = resolvedFullScaleOffset(startLocation: startLocation)

        DebugLog.trace("🧭 Block \(blockIndex): startLocation=\(startLocation) blockFrame.origin=\(blockFrame.origin) touchOffset=\(touchOffset)")

        dragController.startDrag(
            blockIndex: blockIndex,
            blockPattern: blockPattern,
            at: startLocation,
            touchOffset: touchOffset
        )

        // Prime controller state so the first frame already reflects the correct position
        dragController.updateDrag(to: startLocation)
    }

    private func handleDragChanged(location: CGPoint) {
        guard didSendDragBegan, dragController.isBlockDragged(blockIndex) else {
            return
        }

        dragController.updateDrag(to: location)
        DebugLog.trace("📍 Block \(blockIndex): updateDrag location=\(location) currentDragPosition=\(dragController.currentDragPosition)")
    }

    private func handleDragEnded(location: CGPoint) {
        DebugLog.trace("🏁 Block \(blockIndex): Gesture ended, isBlockDragged: \(dragController.isBlockDragged(blockIndex))")

        if dragController.isBlockDragged(blockIndex) {
            DebugLog.trace("📍 Block \(blockIndex): Calling endDrag")
            dragController.endDrag(at: location)
        } else {
            DebugLog.trace("⏭️ Block \(blockIndex): Skipping endDrag - not actively dragged")
        }

        didSendDragBegan = false
        dragGestureID = UUID()

        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
            isPressed = false
        }
    }

    private func handleDragCancelled() {
        DebugLog.trace("❌ Block \(blockIndex): Gesture cancelled")

        if dragController.isBlockDragged(blockIndex) {
            dragController.cancelDrag()
        }

        didSendDragBegan = false
        dragGestureID = UUID()

        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
            isPressed = false
        }
    }

    private func resolvedFullScaleOffset(startLocation: CGPoint) -> CGSize {
        guard blockFrame.width > 0, blockFrame.height > 0,
              baseBlockSize.width > 0, baseBlockSize.height > 0 else {
            // Fallback: center offset so piece appears under the finger
            return CGSize(width: baseBlockSize.width / 2, height: baseBlockSize.height / 2)
        }

        let normalizedX = (startLocation.x - blockFrame.minX) / blockFrame.width
        let normalizedY = (startLocation.y - blockFrame.minY) / blockFrame.height
        let relativeX = max(0, min(1, normalizedX))
        let relativeY = max(0, min(1, normalizedY))

        return CGSize(
            width: relativeX * baseBlockSize.width,
            height: relativeY * baseBlockSize.height
        )
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

    private var shadowColor: Color {
        let baseColor = Color(blockPattern.color.uiColor)
        let opacity = isValid ? 0.35 : 0.25
        return baseColor.opacity(colorScheme == .dark ? opacity : opacity * 0.9)
    }
}

// MARK: - Enhanced Block Tray with Drag Support

/// Block tray with integrated drag and drop support
struct DraggableBlockTrayView: View {
    // MARK: - Properties
    @ObservedObject var blockFactory: BlockFactory
    @ObservedObject var dragController: DragController

    let cellSize: CGFloat
    let slotSize: CGFloat
    let horizontalInset: CGFloat
    let slotSpacing: CGFloat
    let onBlockDragged: (Int, BlockPattern) -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(
        blockFactory: BlockFactory,
        dragController: DragController,
        cellSize: CGFloat,
        slotSize: CGFloat,
        horizontalInset: CGFloat,
        slotSpacing: CGFloat,
        onBlockDragged: @escaping (Int, BlockPattern) -> Void
    ) {
        _blockFactory = ObservedObject(wrappedValue: blockFactory)
        _dragController = ObservedObject(wrappedValue: dragController)
        self.cellSize = cellSize
        self.slotSize = slotSize
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
            .frame(maxWidth: .infinity)
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
        let isDragged = dragController.isBlockDragged(index)
        let restingScale = displayScale(for: blockPattern)

        return ZStack {
            if let pattern = blockPattern {
                DraggableBlockView(
                    blockPattern: pattern,
                    blockIndex: index,
                    cellSize: cellSize,
                    restingScale: restingScale,
                    containerSize: slotSize,
                    dragController: dragController
                )
                .opacity(isDragged ? 0.25 : 1.0)
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.28), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                    .frame(width: slotSize * 0.72, height: slotSize * 0.72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.08))
                    )
            }
        }
        .frame(width: slotSize, height: slotSize)
        .animation(.easeInOut(duration: 0.15), value: isDragged)
        .accessibilityLabel(slotAccessibilityLabel(for: blockPattern, index: index))
    }

    // MARK: - Helpers

    private func displayScale(for blockPattern: BlockPattern?) -> CGFloat {
        guard let pattern = blockPattern else { return 1.0 }
        return displayScale(for: pattern)
    }

    private func displayScale(for blockPattern: BlockPattern) -> CGFloat {
        let width = CGFloat(blockPattern.size.width) * cellSize
        let height = CGFloat(blockPattern.size.height) * cellSize
        let maxDimension = max(width, height)
        guard maxDimension > 0 else { return 1.0 }
        let availableSpan = slotSize * 0.88
        return min(1.0, availableSpan / maxDimension)
    }

    private var trayBackground: Color {
        colorScheme == .dark ? Color(UIColor.systemGray5).opacity(0.65) : Color.white.opacity(0.92)
    }

    private var trayBorderColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.18) : Color(UIColor.systemGray3).opacity(0.35)
    }

    private var trayShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.12)
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
            slotSize: 88,
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
