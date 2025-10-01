import SwiftUI
import UIKit

// MARK: - View Extensions

extension View {
    /// Conditionally applies a transformation to a view
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - UIKit Touch Detection

/// UIKit-based touch detection for precise vicinity selection
struct UITouchBlockTrayView: UIViewRepresentable {
    @ObservedObject var blockFactory: BlockFactory
    @ObservedObject var dragController: DragController

    let cellSize: CGFloat
    let slotSize: CGFloat
    let horizontalInset: CGFloat
    let slotSpacing: CGFloat
    let vicinityRadius: CGFloat
    let onBlockDragged: (Int, BlockPattern) -> Void

    func makeUIView(context: Context) -> TouchBlockTrayUIView {
        let view = TouchBlockTrayUIView()
        view.coordinator = context.coordinator
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false
        return view
    }

    func updateUIView(_ uiView: TouchBlockTrayUIView, context: Context) {
        context.coordinator.updateBlockData(
            blocks: blockFactory.getTraySlots(),
            slotSize: slotSize,
            slotSpacing: slotSpacing,
            horizontalInset: horizontalInset,
            vicinityRadius: vicinityRadius
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(dragController: dragController, onBlockDragged: onBlockDragged)
    }

    class Coordinator: NSObject {
        let dragController: DragController
        let onBlockDragged: (Int, BlockPattern) -> Void

        private var blockFrames: [Int: CGRect] = [:]
        private var blockPatterns: [Int: BlockPattern] = [:]
        private var vicinityRadius: CGFloat = 80.0

        private var activeTouch: UITouch?
        private var activeDragBlockIndex: Int?

        init(dragController: DragController, onBlockDragged: @escaping (Int, BlockPattern) -> Void) {
            self.dragController = dragController
            self.onBlockDragged = onBlockDragged
        }

        func updateBlockData(blocks: [BlockPattern?], slotSize: CGFloat, slotSpacing: CGFloat, horizontalInset: CGFloat, vicinityRadius: CGFloat) {
            self.vicinityRadius = vicinityRadius
            blockFrames.removeAll()
            blockPatterns.removeAll()

            let startX = horizontalInset
            for (index, blockPattern) in blocks.enumerated() {
                guard let pattern = blockPattern else { continue }
                let x = startX + CGFloat(index) * (slotSize + slotSpacing)
                blockFrames[index] = CGRect(x: x, y: 14, width: slotSize, height: slotSize)
                blockPatterns[index] = pattern
            }
        }

        @MainActor func handleTouchBegan(_ touch: UITouch, in view: UIView) {
            let location = touch.location(in: view)
            DebugLog.trace("🎯 UITouch: Touch began at \(location), view bounds: \(view.bounds)")
            DebugLog.trace("🎯 UITouch: Block frames: \(blockFrames)")

            if let blockIndex = findBlockNearTouch(at: location) {
                guard let blockPattern = blockPatterns[blockIndex],
                      let blockFrame = blockFrames[blockIndex],
                      dragController.dragState == .idle else {
                    DebugLog.trace("❌ UITouch: Guard failed - dragState: \(dragController.dragState)")
                    return
                }

                activeTouch = touch
                activeDragBlockIndex = blockIndex

                let touchOffset = CGSize(
                    width: location.x - blockFrame.minX,
                    height: location.y - blockFrame.minY
                )

                let globalLocation = view.convert(location, to: nil)
                onBlockDragged(blockIndex, blockPattern)
                dragController.startDrag(blockIndex: blockIndex, blockPattern: blockPattern, at: globalLocation, touchOffset: touchOffset)
                DebugLog.trace("✅ UITouch: Started drag block \(blockIndex) at global: \(globalLocation)")
            } else {
                DebugLog.trace("❌ UITouch: No block found near touch \(location)")
            }
        }

        @MainActor func handleTouchMoved(_ touch: UITouch, in view: UIView) {
            guard touch == activeTouch, let blockIndex = activeDragBlockIndex, dragController.isBlockDragged(blockIndex) else { return }
            let globalLocation = view.convert(touch.location(in: view), to: nil)
            dragController.updateDrag(to: globalLocation)
        }

        @MainActor func handleTouchEnded(_ touch: UITouch, in view: UIView) {
            guard touch == activeTouch else { return }
            let globalLocation = view.convert(touch.location(in: view), to: nil)
            if let blockIndex = activeDragBlockIndex, dragController.isBlockDragged(blockIndex) {
                dragController.endDrag(at: globalLocation)
            }
            activeTouch = nil
            activeDragBlockIndex = nil
        }

        private func findBlockNearTouch(at point: CGPoint) -> Int? {
            for (index, frame) in blockFrames.sorted(by: { $0.key < $1.key }) {
                let distance = hypot(point.x - frame.midX, point.y - frame.midY)
                if distance <= vicinityRadius {
                    return index
                }
            }
            return nil
        }
    }
}

class TouchBlockTrayUIView: UIView {
    weak var coordinator: UITouchBlockTrayView.Coordinator?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touches.first.map { coordinator?.handleTouchBegan($0, in: self) }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        touches.first.map { coordinator?.handleTouchMoved($0, in: self) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touches.first.map { coordinator?.handleTouchEnded($0, in: self) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touches.first.map { coordinator?.handleTouchEnded($0, in: self) }
    }
}

// MARK: - Draggable Block View

/// SwiftUI view that makes blocks draggable with smooth animations
struct DraggableBlockView: View {

    // MARK: - Properties

    let blockPattern: BlockPattern
    let blockIndex: Int
    let cellSize: CGFloat
    let restingScale: CGFloat
    let containerSize: CGFloat
    let useUIKitTouch: Bool  // If true, disable SwiftUI gestures for UIKit touch handling

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
        // When dragged, block position is controlled by dragController
        // No offset needed - block moves with FloatingBlockPreview
        return .zero
    }

    private var blockScale: CGFloat {
        if isDragged {
            return dragController.dragScale
        }

        let baseScale = restingScale

        // When using UIKit touch, don't scale on press (tray blocks stay at base scale)
        if useUIKitTouch {
            return baseScale
        }

        // Enlarge to 2.0x when pressed for better visibility (SwiftUI gesture only)
        return isPressed ? baseScale * 2.0 : baseScale
    }

    private var dragRotation: Double {
        isDragged ? dragController.dragRotation : 0.0
    }

    private var shadowOffset: CGSize {
        if isDragged {
            return dragController.shadowOffset
        }
        // No shadow when using UIKit touch (tray blocks)
        if useUIKitTouch {
            return .zero
        }
        return isPressed ? CGSize(width: 1, height: 2) : .zero
    }

    private var shadowRadius: CGFloat {
        if isDragged {
            return 8
        }
        // No shadow when using UIKit touch (tray blocks)
        if useUIKitTouch {
            return 0
        }
        return isPressed ? 4 : 0
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

    // MARK: - Body

    var body: some View {
        ZStack {
            blockContent

            if isDragged {
                dragOverlay
            }
        }
        .frame(width: containerSize, height: containerSize)
        .if(!useUIKitTouch) { view in
            view.contentShape(Rectangle())  // Make entire container area tappable (SwiftUI gesture only)
        }
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            x: shadowOffset.width,
            y: shadowOffset.height
        )
        .offset(dragOffset)
        .zIndex(isDragged ? 1000 : 0)
        .if(!useUIKitTouch) { view in
            view
                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.8, blendDuration: 0), value: isPressed)
                .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.85, blendDuration: 0), value: blockScale)
                .animation(.linear(duration: 0.016), value: dragRotation)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Drag to place this block on the game board")
        .accessibilityAddTraits(.allowsDirectInteraction)
        .if(!useUIKitTouch) { view in
            view
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
        .allowsHitTesting(!useUIKitTouch)  // Disable hit testing when using UIKit touch
        .if(!useUIKitTouch) { view in
            view.gesture(dragGesture)  // Only add SwiftUI gesture if not using UIKit touch
        }
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

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                // Set pressed state immediately on touch
                if !isPressed {
                    withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.8)) {
                        isPressed = true
                    }
                }

                if !didSendDragBegan && dragController.dragState == .idle {
                    DebugLog.trace("🎮 Block \(blockIndex): Starting drag, controller state: \(dragController.dragState)")
                    didSendDragBegan = true
                    dragGestureID = UUID()

                    // VICINITY SELECTION: Check if touch is within large radius (half centimeter ≈ 60pt)
                    let touchOffset: CGSize

                    if blockFrame != .zero {
                        let vicinityRadius: CGFloat = 80.0  // Increased to 80pt for better detection
                        let blockCenter = CGPoint(
                            x: blockFrame.midX,
                            y: blockFrame.midY
                        )
                        let touchDistance = hypot(
                            value.startLocation.x - blockCenter.x,
                            value.startLocation.y - blockCenter.y
                        )

                        DebugLog.trace("📍 Block \(blockIndex): Touch at \(value.startLocation), block center \(blockCenter), distance \(touchDistance)pt")

                        // Accept touch if within vicinity radius (very generous detection)
                        if touchDistance <= vicinityRadius {
                            // Use center of block as reference for clean dragging
                            touchOffset = CGSize(
                                width: blockCenter.x - blockFrame.minX,
                                height: blockCenter.y - blockFrame.minY
                            )
                            DebugLog.trace("✅ Block \(blockIndex): Vicinity touch accepted at distance \(touchDistance)pt (max: \(vicinityRadius)pt)")
                        } else {
                            // Touch too far away - don't start drag
                            touchOffset = .zero
                            DebugLog.trace("❌ Block \(blockIndex): Touch rejected - distance \(touchDistance)pt exceeds \(vicinityRadius)pt")
                        }
                    } else {
                        touchOffset = .zero
                    }

                    DebugLog.trace("🧭 Block \(blockIndex): startLocation=\(value.startLocation) blockFrame.origin=\(blockFrame.origin) touchOffset=\(touchOffset)")

                    dragController.startDrag(
                        blockIndex: blockIndex,
                        blockPattern: blockPattern,
                        at: value.startLocation,
                        touchOffset: touchOffset
                    )

                } else if !didSendDragBegan {
                    DebugLog.trace("🚫 Block \(blockIndex): Cannot start drag, controller state: \(dragController.dragState)")
                }

                if dragController.isBlockDragged(blockIndex) {
                    dragController.updateDrag(to: value.location)
                    DebugLog.trace("📍 Block \(blockIndex): updateDrag location=\(value.location) currentDragPosition=\(dragController.currentDragPosition) touch=\(dragController.currentTouchLocation)")
                }
            }
            .onEnded { value in
                DebugLog.trace("🏁 Block \(blockIndex): Gesture ended, isBlockDragged: \(dragController.isBlockDragged(blockIndex))")

                if dragController.isBlockDragged(blockIndex) {
                    DebugLog.trace("📍 Block \(blockIndex): Calling endDrag")
                    dragController.endDrag(at: value.location)
                } else {
                    DebugLog.trace("⏭️ Block \(blockIndex): Skipping endDrag - not actively dragged")
                }

                didSendDragBegan = false
                dragGestureID = UUID()

                withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                    isPressed = false
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
        .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
        .position(
            x: position.x + blockWidth / 2,
            y: position.y + blockHeight / 2
        )
        .allowsHitTesting(false)
        .zIndex(999)
    }

    // MARK: - View Components

    private var shadowColor: Color {
        return Color.black.opacity(colorScheme == .dark ? 0.5 : 0.3)
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
        ZStack {
            // Visual layer: SwiftUI blocks for rendering
            VStack(spacing: 0) {
                HStack(spacing: slotSpacing) {
                    ForEach(Array(blockFactory.getTraySlots().enumerated()), id: \.offset) { index, blockPattern in
                        traySlot(for: blockPattern, index: index)
                    }
                }
                .padding(.horizontal, horizontalInset)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
            }
            .allowsHitTesting(false)  // Disable SwiftUI gestures

            // Touch layer: UIKit touch detection with vicinity radius
            UITouchBlockTrayView(
                blockFactory: blockFactory,
                dragController: dragController,
                cellSize: cellSize,
                slotSize: slotSize,
                horizontalInset: horizontalInset,
                slotSpacing: slotSpacing,
                vicinityRadius: 80.0,  // 80pt radius for generous touch detection
                onBlockDragged: onBlockDragged
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())  // Make entire area touchable
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
                    useUIKitTouch: true,  // Enable UIKit touch detection, disable SwiftUI gestures
                    dragController: dragController
                )
                .opacity(isDragged ? 0.0 : 1.0)  // COMPLETELY invisible when dragging
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
