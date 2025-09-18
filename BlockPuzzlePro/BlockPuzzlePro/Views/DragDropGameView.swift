import SwiftUI
import Foundation
import CoreGraphics

// MARK: - Placement Result (Temporary)

/// Result of a block placement attempt
enum PlacementResult {
    case valid(positions: [GridPosition])
    case invalid(reason: String)
}

// MARK: - Simple Placement Engine (Temporary)

/// Simplified placement engine for immediate functionality
@MainActor
class PlacementEngine: ObservableObject {
    private weak var gameEngine: GameEngine?
    @Published private(set) var isCurrentPreviewValid: Bool = false
    @Published private(set) var previewPositions: [GridPosition] = []
    
    init(gameEngine: GameEngine) {
        self.gameEngine = gameEngine
    }
    
    func updatePreview(
        blockPattern: BlockPattern,
        blockOrigin: CGPoint,
        gridFrame: CGRect,
        cellSize: CGFloat,
        gridSpacing: CGFloat
    ) {
        guard let gameEngine = gameEngine else { return }

        // Clear existing preview
        gameEngine.clearPreviews()
        previewPositions.removeAll()

        // Convert screen position to grid position
        // The drag position represents the top-left corner of the dragged block
        let gridOriginX = gridFrame.minX + gridSpacing
        let gridOriginY = gridFrame.minY + gridSpacing

        // Adjust for the fact that blockOrigin is the drag position, not necessarily grid-aligned
        let adjustedX = blockOrigin.x - gridOriginX
        let adjustedY = blockOrigin.y - gridOriginY

        // Check if we're over the grid area
        guard adjustedX >= 0, adjustedY >= 0,
              adjustedX < gridFrame.width - 2 * gridSpacing,
              adjustedY < gridFrame.height - 2 * gridSpacing else {
            isCurrentPreviewValid = false
            return
        }

        // Calculate grid position based on cell boundaries
        let effectiveCellSpan = cellSize + gridSpacing
        let gridX = Int(adjustedX / effectiveCellSpan)
        let gridY = Int(adjustedY / effectiveCellSpan)

        // Validate grid bounds
        guard gridX >= 0,
              gridY >= 0,
              gridX < GameEngine.gridSize,
              gridY < GameEngine.gridSize,
              let gridPosition = GridPosition(row: gridY, column: gridX) else {
            isCurrentPreviewValid = false
            return
        }

        // Calculate target positions for all cells in the block pattern
        var targetPositions: [GridPosition] = []
        for cellPosition in blockPattern.occupiedPositions {
            let targetRow = gridPosition.row + Int(cellPosition.y)
            let targetCol = gridPosition.column + Int(cellPosition.x)

            // Check bounds before creating GridPosition
            guard targetRow >= 0, targetRow < GameEngine.gridSize,
                  targetCol >= 0, targetCol < GameEngine.gridSize,
                  let targetGridPos = GridPosition(row: targetRow, column: targetCol) else {
                isCurrentPreviewValid = false
                return
            }

            targetPositions.append(targetGridPos)
        }

        // Validate all target positions can be placed
        for position in targetPositions {
            guard gameEngine.canPlaceAt(position: position) else {
                isCurrentPreviewValid = false
                return
            }
        }

        previewPositions = targetPositions
        isCurrentPreviewValid = true
        gameEngine.setPreview(at: targetPositions, color: blockPattern.color)
    }
    
    func clearPreview() {
        guard let gameEngine = gameEngine else { return }
        gameEngine.clearPreviews()
        previewPositions.removeAll()
        isCurrentPreviewValid = false
    }
    
    func commitPlacement(blockPattern: BlockPattern) -> Bool {
        guard let gameEngine = gameEngine,
              isCurrentPreviewValid,
              !previewPositions.isEmpty else {
            clearPreview()  // Clear preview even if we can't place
            return false
        }

        let success = gameEngine.placeBlocks(at: previewPositions, color: blockPattern.color)
        clearPreview()  // Always clear preview after attempting placement
        if success {
            let _ = gameEngine.processCompletedLines()
        }
        return success
    }
}

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
                        let localDragPosition = CGPoint(
                            x: dragController.currentDragPosition.x - rootOrigin.x,
                            y: dragController.currentDragPosition.y - rootOrigin.y
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
        withAnimation(.easeInOut(duration: 0.3)) {
            gameEngine.startNewGame()
            blockFactory.regenerateAllBlocks()
            placementEngine.clearPreview()
            dragController.reset()
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
