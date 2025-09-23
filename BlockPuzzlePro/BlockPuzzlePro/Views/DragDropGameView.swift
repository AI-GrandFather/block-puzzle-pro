import SwiftUI
import Foundation
import CoreGraphics
import Combine
import QuartzCore

// MARK: - Drag Drop Game View

/// Main game view with integrated drag and drop functionality
struct DragDropGameView: View {
    
    // MARK: - Properties
    
    @StateObject private var gameEngine: GameEngine
    @StateObject private var blockFactory = BlockFactory()
    @StateObject private var deviceManager: DeviceManager
    @StateObject private var dragController: DragController
    @StateObject private var placementEngine: PlacementEngine
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - State
    
    @State private var screenSize: CGSize = .zero
    @State private var isGameReady: Bool = false
    @State private var gridFrame: CGRect = .zero
    @State private var lineClearHighlights: Set<GridPosition> = []
    @State private var lineClearAnimationToken: UUID?
    @State private var celebrationMessage: CelebrationMessage?
    @State private var celebrationVisible: Bool = false

    // Performance optimization properties
    @State private var lastUpdateTime: TimeInterval = 0
    @State private var frameSkipCounter: Int = 0
    @State private var isProMotionDevice: Bool = false

    private let gridSpacing: CGFloat = 2
    
    // MARK: - Initialization
    
    init() {
        let gameEngine = GameEngine()
        let deviceManager = DeviceManager()
        
        _gameEngine = StateObject(wrappedValue: gameEngine)
        _deviceManager = StateObject(wrappedValue: deviceManager)
        _dragController = StateObject(wrappedValue: DragController(deviceManager: deviceManager))
        _placementEngine = StateObject(wrappedValue: PlacementEngine(gameEngine: gameEngine))
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()
                
                if isGameReady {
                    VStack(spacing: 24) {
                        gameHeader
                            .padding(.top, max(geometry.safeAreaInsets.top + 12, 40))
                            .padding(.horizontal, 24)

                        // Grid container with explicit centering and size constraints
                        gridView
                            .frame(width: boardSize, height: boardSize)
                            .frame(maxWidth: geometry.size.width - 48, alignment: .center)
                            .clipped()

                        // Tray container
                        trayView(safeArea: geometry.safeAreaInsets.bottom)
                            .frame(maxWidth: geometry.size.width - 48, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    
                    // Floating drag preview overlay
                    if let draggedPattern = dragController.draggedBlockPattern {
                        let rootOrigin = geometry.frame(in: .global).origin

                        let previewOriginGlobal = (placementEngine.isCurrentPreviewValid ? snappedPreviewOrigin() : nil) ?? dragController.currentDragPosition

                        let localDragPosition = CGPoint(
                            x: previewOriginGlobal.x - rootOrigin.x,
                            y: previewOriginGlobal.y - rootOrigin.y
                        )

                        FloatingBlockPreview(
                            blockPattern: draggedPattern,
                            cellSize: gridCellSize,
                            position: localDragPosition,
                            isValid: placementEngine.isCurrentPreviewValid
                        )
                        .allowsHitTesting(false)
                    }
                } else {
                    // Loading state
                    loadingView
                }
        }
        .overlay(celebrationOverlay, alignment: .top)
        .onAppear {
            setupGameView(screenSize: geometry.size)
        }
            .onChange(of: geometry.size) { _, newValue in
                updateScreenSize(newValue)
            }
            .onReceive(gameEngine.$activeLineClears) { clears in
                guard !clears.isEmpty else { return }

                let highlights = Set(clears.flatMap { $0.positions })
                guard !highlights.isEmpty else { return }

                let token = UUID()
                lineClearAnimationToken = token

                // Start the enhanced line clear animation with ProMotion optimization
                withAnimation(.spring(
                    response: isProMotionDevice ? 0.2 : 0.4,
                    dampingFraction: 0.7,
                    blendDuration: 0
                )) {
                    lineClearHighlights = highlights
                }

                // Optimized timing for different refresh rates
                let fadeDelay: TimeInterval = isProMotionDevice ? 0.6 : 0.8
                DispatchQueue.main.asyncAfter(deadline: .now() + fadeDelay) {
                    guard lineClearAnimationToken == token else { return }
                    withAnimation(.easeOut(duration: self.isProMotionDevice ? 0.3 : 0.4)) {
                        lineClearHighlights = []
                    }

                    // Clear the lines after animation completes
                    let clearDelay: TimeInterval = self.isProMotionDevice ? 0.3 : 0.4
                    DispatchQueue.main.asyncAfter(deadline: .now() + clearDelay) {
                        guard lineClearAnimationToken == token else { return }
                        gameEngine.clearActiveLineClears()
                    }
                }
            }
            .onChange(of: gameEngine.lastScoreEvent?.newTotal) { _, _ in
                triggerCelebration(with: gameEngine.lastScoreEvent)
            }
        }
        .environmentObject(deviceManager)
        .onAppear {
            setupPerformanceOptimizations()
        }
        // Removed .onChange(of: dragController.isDragging) due to non-existent property
    }
    
    // MARK: - View Components
    
    private var backgroundColor: some View {
        let aurora = LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.16, blue: 0.34),
                Color(red: 0.05, green: 0.29, blue: 0.49),
                Color(red: 0.15, green: 0.06, blue: 0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        let sunrise = LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.77, blue: 0.36).opacity(0.55),
                Color(red: 0.69, green: 0.51, blue: 0.91).opacity(0.7),
                Color(UIColor.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottomTrailing
        )

        return ZStack {
            (colorScheme == .dark ? aurora : sunrise)

            RadialGradient(
                colors: [Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25), Color.clear],
                center: .center,
                startRadius: 60,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
    
    private var gameHeader: some View {
        HStack(alignment: .center, spacing: 20) {
            ScoreView(
                score: gameEngine.score,
                highScore: gameEngine.highScore,
                lastEvent: gameEngine.lastScoreEvent
            )

            Spacer(minLength: 16)

            Button(action: startNewGame) {
                Label("Restart", systemImage: "arrow.counterclockwise")
                    .font(.caption.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white)
            .background(
                Capsule()
                    .fill(Color.accentColor)
            )
            .shadow(color: Color.accentColor.opacity(0.28), radius: 10, x: 0, y: 6)

            Button {
                // TODO: Present settings sheet
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Color.secondary)
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground).opacity(0.7))
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Game...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private var gridView: some View {
        GridView(
            gameEngine: gameEngine,
            dragController: dragController,
            cellSize: gridCellSize,
            gridSpacing: gridSpacing,
            highlightedPositions: lineClearHighlights
        )
        .background(
            GeometryReader { gridGeometry in
                Color.clear
                    .onAppear {
                        gridFrame = gridGeometry.frame(in: .global)
                    }
                    .onChange(of: gridGeometry.frame(in: .global)) { _, newValue in
                        gridFrame = newValue
                    }
            }
        )
        .onDrop(of: ["public.text"], isTargeted: nil) { _, location in
            guard
                let pattern = dragController.draggedBlockPattern,
                let index = dragController.currentBlockIndex
            else { return false }

            let globalPoint = CGPoint(
                x: gridFrame.minX + location.x,
                y: gridFrame.minY + location.y
            )

            updatePlacementPreview(
                blockPattern: pattern,
                blockOrigin: dragController.currentDragPosition
            )

            if placementEngine.isCurrentPreviewValid {
                handleValidPlacement(blockIndex: index, blockPattern: pattern, position: globalPoint)
                return true
            } else {
                handleInvalidPlacement(blockIndex: index, blockPattern: pattern, position: globalPoint)
                return false
            }
        }
    }

    private func trayView(safeArea: CGFloat) -> some View {
        DraggableBlockTrayView(
            blockFactory: blockFactory,
            dragController: dragController,
            cellSize: gridCellSize
        ) { blockIndex, blockPattern in
            handleBlockDragStarted(blockIndex: blockIndex, blockPattern: blockPattern)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, max(safeArea + 16, 32))
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        if let message = celebrationMessage, celebrationVisible {
            VStack {
                CelebrationToastView(message: message)
                    .padding(.top, 72)
                    .padding(.horizontal, 24)

                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }
    
    private var availableGridLength: CGFloat {
        guard screenSize != .zero else { return 320 }

        // Use more conservative padding to ensure grid fits properly
        let horizontalPadding: CGFloat = 64  // Increased from 48 to give more margin
        let widthLimit = max(240, screenSize.width - horizontalPadding)

        // Height calculation with more conservative ratio
        let heightLimit = max(240, screenSize.height * 0.5)  // Reduced from 0.55

        return min(widthLimit, heightLimit)
    }

    private var gridCellSize: CGFloat {
        let usableSize = availableGridLength
        let totalSpacing = gridSpacing * CGFloat(GameEngine.gridSize + 1)
        let effectiveBoard = max(usableSize - totalSpacing, 10)
        return effectiveBoard / CGFloat(GameEngine.gridSize)
    }

    private var boardSize: CGFloat {
        gridCellSize * CGFloat(GameEngine.gridSize) + gridSpacing * CGFloat(GameEngine.gridSize + 1)
    }
    
    // MARK: - Performance Optimization

    private func setupPerformanceOptimizations() {
        // Detect ProMotion capability
        isProMotionDevice = UIScreen.main.maximumFramesPerSecond >= 120

        DebugLog.trace("🚀 Performance optimizations enabled")
        DebugLog.trace("📱 Device max refresh rate: \(UIScreen.main.maximumFramesPerSecond)Hz")
        DebugLog.trace("⚡ ProMotion support: \(isProMotionDevice ? "YES" : "NO")")
    }

    // MARK: - Game Logic

    private func setupGameView(screenSize: CGSize) {
        self.screenSize = screenSize

        // Clear any existing state first
        placementEngine.clearPreview()
        dragController.reset()

        // Setup drag controller callbacks
        setupDragCallbacks()

        // Start new game
        gameEngine.startNewGame()

        // Mark as ready respecting Reduce Motion accessibility setting
        if UIAccessibility.isReduceMotionEnabled {
            isGameReady = true
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                isGameReady = true
            }
        }
    }
    
    private func updateScreenSize(_ newSize: CGSize) {
        screenSize = newSize
    }
    
    private func setupDragCallbacks() {
        // Drag began callback
        dragController.onDragBegan = { blockIndex, blockPattern, position in
            handleDragBegan(blockIndex: blockIndex, blockPattern: blockPattern, position: position)
            DebugLog.trace("🎯 onDragBegan blockIndex=\(blockIndex) position=\(position) pattern=\(blockPattern.type)")
        }
        
        // Drag changed callback
        dragController.onDragChanged = { blockIndex, blockPattern, position in
            // Update placement preview using the controller's computed origin
            DebugLog.trace("🔄 onDragChanged blockIndex=\(blockIndex) reportedPosition=\(position) currentDragPosition=\(self.dragController.currentDragPosition)")
            self.updatePlacementPreview(blockPattern: blockPattern, blockOrigin: self.dragController.currentDragPosition)
        }

        // Drag ended callback
        dragController.onDragEnded = { blockIndex, blockPattern, position in
            DebugLog.trace("🛑 onDragEnded blockIndex=\(blockIndex) position=\(position) state=\(self.dragController.dragState)")
            // Commit placement and handle result
            let placementSuccess = self.placementEngine.commitPlacement(blockPattern: blockPattern)

            if placementSuccess {
                self.handleValidPlacement(blockIndex: blockIndex, blockPattern: blockPattern, position: position)
            } else {
                self.handleInvalidPlacement(blockIndex: blockIndex, blockPattern: blockPattern, position: position)
            }

            // CRITICAL: Ensure drag controller completes its state machine
            // The drag controller's endDrag() should handle state transitions automatically,
            // but we need to ensure it gets called properly
        }
        
        // Removed onValidDrop and onInvalidDrop assignments
    }
    
    private func startNewGame() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Clear all state immediately before animation
        placementEngine.clearPreview()
        dragController.reset()

        withAnimation(.easeInOut(duration: 0.3)) {
            gameEngine.startNewGame()
            blockFactory.regenerateAllBlocks()
        }
    }
    
    // MARK: - Drag Event Handlers
    
    private func handleBlockDragStarted(blockIndex: Int, blockPattern: BlockPattern) {
    }
    
    private func handleDragBegan(blockIndex: Int, blockPattern: BlockPattern, position: CGPoint) {
        // Clear any existing preview state when a new drag begins
        placementEngine.clearPreview()
    }
    
    private func handleDragEnded() {
        placementEngine.clearPreview()
        cancelDragIfNeeded()
    }
    
    private func cancelDragIfNeeded() {
        // Currently nothing additional needed; placeholder for future logic if needed.
    }
    
    // MARK: - Placement Engine Integration
    
    private func updatePlacementPreview(blockPattern: BlockPattern, blockOrigin: CGPoint) {
        // Use the actual grid frame from GeometryReader
        guard gridFrame != .zero else { return }

        placementEngine.updatePreview(
            blockPattern: blockPattern,
            blockOrigin: blockOrigin,
            touchPoint: dragController.currentTouchLocation,
            touchOffset: dragController.dragTouchOffset,
            gridFrame: gridFrame,
            cellSize: gridCellSize,
            gridSpacing: gridSpacing
        )
        DebugLog.trace("🧮 updatePlacementPreview blockIndex=\(dragController.currentBlockIndex ?? -1) origin=\(blockOrigin) touch=\(dragController.currentTouchLocation) touchOffset=\(dragController.dragTouchOffset) gridFrame=\(gridFrame)")
        
        // Removed the following line as per instructions:
        // dragController.setDropValidity(placementEngine.isCurrentPreviewValid)
    }
    
    private func handleValidPlacement(blockIndex: Int, blockPattern: BlockPattern, position: CGPoint) {
        DebugLog.trace("✅ PLACEMENT SUCCESS: Block \(blockIndex) placed successfully")

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIAccessibility.post(notification: .announcement, argument: "Placed block successfully")

        UIAccessibility.post(notification: .announcement, argument: "Lines cleared if any")

        // Regenerate the placed block (infinite supply design)
        blockFactory.consumeBlock(at: blockIndex)

        // Clear preview (drag controller handles its own cleanup)
        placementEngine.clearPreview()

        // CRITICAL: Force reset drag controller if gesture doesn't complete properly
        // This prevents the controller from getting stuck in dragging state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.dragController.dragState != .idle {
                DebugLog.trace("🚨 FORCE RESET: Drag controller stuck in \(self.dragController.dragState) state after placement")
                self.dragController.reset()
            }
        }
    }
    
    private func snappedPreviewOrigin() -> CGPoint? {
        guard placementEngine.isCurrentPreviewValid, !placementEngine.previewPositions.isEmpty, gridFrame != .zero else {
            return nil
        }

        guard let minRow = placementEngine.previewPositions.map({ $0.row }).min(),
              let minCol = placementEngine.previewPositions.map({ $0.column }).min(),
              let topLeft = GridPosition(row: minRow, column: minCol) else {
            return nil
        }

        let centre = placementEngine.gridToScreenPosition(
            gridPosition: topLeft,
            gridFrame: gridFrame,
            cellSize: gridCellSize,
            gridSpacing: gridSpacing
        )

        return CGPoint(
            x: centre.x - (gridCellSize / 2),
            y: centre.y - (gridCellSize / 2)
        )
    }
    
    private func handleInvalidPlacement(blockIndex: Int, blockPattern: BlockPattern, position: CGPoint) {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        UIAccessibility.post(notification: .announcement, argument: "Invalid placement")

        // Clear preview (drag controller handles its own cleanup)
        placementEngine.clearPreview()
    }
    
    // MARK: - Accessibility
    
    private func triggerCelebration(with event: ScoreEvent?) {
        guard let event = event, let message = makeCelebrationMessage(from: event) else {
            return
        }

        celebrationMessage = message
        let responseMultiplier: Double = isProMotionDevice ? 0.7 : 1.0

        withAnimation(.spring(response: 0.35 * responseMultiplier, dampingFraction: 0.7)) {
            celebrationVisible = true
        }

        let token = message.id
        let displayDuration: TimeInterval = isProMotionDevice ? 1.2 : 1.4
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
            guard celebrationMessage?.id == token else { return }
            withAnimation(.easeOut(duration: 0.35 * responseMultiplier)) {
                celebrationVisible = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if celebrationMessage?.id == token {
                    celebrationMessage = nil
                }
            }
        }
    }

    private func makeCelebrationMessage(from event: ScoreEvent) -> CelebrationMessage? {
        guard event.linesCleared >= 2 else { return nil }

        let title: String
        let subtitle: String
        let icon: String

        switch event.linesCleared {
        case 2:
            title = "Twin Streak!"
            subtitle = "Double clear, double cheers!"
            icon = "sparkles"
        case 3:
            title = "Triple Cascade!"
            subtitle = "Three rows swept in one swoop."
            icon = "flame.fill"
        default:
            title = "Combo Overdrive!"
            subtitle = "\(event.linesCleared) lines evaporated in style."
            icon = "burst.fill"
        }

        return CelebrationMessage(title: title, subtitle: subtitle, icon: icon, points: event.totalDelta)
    }

private func announceGameState() {
        let announcement = "Game ready. \(blockFactory.getAvailableBlocks().count) blocks available. Score: \(gameEngine.score)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
}

// MARK: - Celebration Models

struct CelebrationMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let points: Int
}

private struct CelebrationToastView: View {
    let message: CelebrationMessage

    @State private var animateContent = false
    private let accentGradient = LinearGradient(
        colors: [
            Color(red: 0.72, green: 0.45, blue: 0.98),
            Color(red: 0.44, green: 0.53, blue: 0.99)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(accentGradient)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 6)

                Image(systemName: message.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .scaleEffect(animateContent ? 1.0 : 0.82)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.primary)

                Text(message.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }

            Spacer(minLength: 8)

            if message.points > 0 {
                Text("+\(message.points)")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.18))
                    )
                    .foregroundStyle(Color.accentColor)
                    .scaleEffect(animateContent ? 1.0 : 0.9)
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 12)
        .frame(maxWidth: 360)
        .scaleEffect(animateContent ? 1.0 : 0.94)
        .opacity(animateContent ? 1.0 : 0.75)
        .onAppear {
            let response = UIScreen.main.maximumFramesPerSecond >= 120 ? 0.26 : 0.3
            withAnimation(.spring(response: response, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(message.title). \(message.subtitle)")
        .accessibilityValue(message.points > 0 ? "+\(message.points) points" : "")
    }
}

// MARK: - Conditional View Extension

extension View {
    @ViewBuilder
    var erased: some View {
        AnyView(self)
    }
}

// MARK: - Preview

#Preview("Game - Light") {
    DragDropGameView()
        .preferredColorScheme(.light)
}

#Preview("Game - Dark") {
    DragDropGameView()
        .preferredColorScheme(.dark)
}
