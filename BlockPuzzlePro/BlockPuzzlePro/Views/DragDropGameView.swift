import SwiftUI
import Foundation
import CoreGraphics

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
                    // Main game content
                    VStack(spacing: 24) {
                        gameHeader
                            .padding(.top, max(geometry.safeAreaInsets.top + 16, 60))

                        GridView(
                            gameEngine: gameEngine,
                            dragController: dragController,
                            cellSize: gridCellSize,
                            gridSpacing: gridSpacing
                        )
                        .frame(width: boardSize, height: boardSize)
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
                            guard let pattern = dragController.draggedBlockPattern else { return false }
                            let globalPoint = CGPoint(x: gridFrame.minX + location.x, y: gridFrame.minY + location.y)
                            self.updatePlacementPreview(blockPattern: pattern, blockOrigin: dragController.currentDragPosition)
                            if self.placementEngine.isCurrentPreviewValid {
                                let idx = 0
                                self.handleValidPlacement(blockIndex: idx, blockPattern: pattern, position: globalPoint)
                                return true
                            } else {
                                let idx = 0
                                self.handleInvalidPlacement(blockIndex: idx, blockPattern: pattern, position: globalPoint)
                                return false
                            }
                        }

                        Spacer(minLength: 0)

                        DraggableBlockTrayView(
                            blockFactory: blockFactory,
                            dragController: dragController,
                            cellSize: gridCellSize
                        ) { blockIndex, blockPattern in
                            handleBlockDragStarted(blockIndex: blockIndex, blockPattern: blockPattern)
                        }
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 24)
                    
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
            .onAppear {
                setupGameView(screenSize: geometry.size)
            }
            .onChange(of: geometry.size) { _, newValue in
                updateScreenSize(newValue)
            }
        }
        .environmentObject(deviceManager)
        // Removed .onChange(of: dragController.isDragging) due to non-existent property
    }
    
    // MARK: - View Components
    
    private var backgroundColor: some View {
        let lightGradient = LinearGradient(
            colors: [
                Color(UIColor.systemTeal.withAlphaComponent(0.18)),
                Color(UIColor.systemIndigo.withAlphaComponent(0.08)),
                Color(UIColor.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        let darkGradient = LinearGradient(
            colors: [
                Color(UIColor.systemGray5.withAlphaComponent(0.3)),
                Color(UIColor.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        return colorScheme == .dark ? AnyView(darkGradient) : AnyView(lightGradient)
    }
    
    private var gameHeader: some View {
        let headerFill = LinearGradient(
            colors: [Color(UIColor.systemBackground), Color(UIColor.secondarySystemBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Block Puzzle Pro")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Score: \(gameEngine.score)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: startNewGame) {
                Label("New Game", systemImage: "arrow.clockwise")
                    .font(.subheadline.bold())
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(headerFill)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
        )
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
    
    private var availableGridLength: CGFloat {
        guard screenSize != .zero else { return 320 }

        let widthLimit = max(240, screenSize.width - 48)
        let heightLimit = max(240, screenSize.height * 0.55)

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
        }
        
        // Drag changed callback
        dragController.onDragChanged = { _, blockPattern, _ in
            // Update placement preview using the controller's computed origin
            self.updatePlacementPreview(blockPattern: blockPattern, blockOrigin: self.dragController.currentDragPosition)
        }

        // Drag ended callback
        dragController.onDragEnded = { blockIndex, blockPattern, position in
            self.updatePlacementPreview(blockPattern: blockPattern, blockOrigin: self.dragController.currentDragPosition)
            if self.placementEngine.commitPlacement(blockPattern: blockPattern) {
                self.handleValidPlacement(blockIndex: blockIndex, blockPattern: blockPattern, position: position)
            } else {
                self.handleInvalidPlacement(blockIndex: blockIndex, blockPattern: blockPattern, position: position)
            }
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
            gridFrame: gridFrame,
            cellSize: gridCellSize,
            gridSpacing: gridSpacing
        )
        
        // Removed the following line as per instructions:
        // dragController.setDropValidity(placementEngine.isCurrentPreviewValid)
    }
    
    private func handleValidPlacement(blockIndex: Int, blockPattern: BlockPattern, position: CGPoint) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        UIAccessibility.post(notification: .announcement, argument: "Placed block successfully")

        UIAccessibility.post(notification: .announcement, argument: "Lines cleared if any")

        // Regenerate the placed block (infinite supply design)
        blockFactory.regenerateBlock(at: blockIndex)

        // Clear preview regardless
        placementEngine.clearPreview()
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
        placementEngine.clearPreview()
    }
    
    // MARK: - Accessibility
    
    private func announceGameState() {
        let announcement = "Game ready. \(blockFactory.getAvailableBlocks().count) blocks available. Score: \(gameEngine.score)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
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
