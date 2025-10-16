import SwiftUI

// MARK: - Game View V2 - Completely Rewritten

/// Clean, simplified game view with pixel-perfect drag & drop
struct GameViewV2: View {

    // MARK: - State Objects

    @StateObject private var gameEngine: GameEngine
    @StateObject private var blockFactory: BlockFactory
    @StateObject private var dragController = DragControllerV2()
    @StateObject private var placementEngine: PlacementEngineV2
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var holdPieceManager = HoldPieceManager()
    @StateObject private var powerUpManager = PowerUpManager()
    @StateObject private var dailyChallengeManager = DailyChallengeManager()
    @StateObject private var themeManager = UnlockableThemeManager()
    @StateObject private var gameCenterManager = GameCenterManager.shared

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var cloudSaveStore: CloudSaveStore

    // MARK: - State

    @State private var gridFrame: CGRect = .zero
    @State private var screenSize: CGSize = .zero
    @State private var isGameOver: Bool = false
    @State private var showSettings: Bool = false
    @State private var showDailyChallenges: Bool = false
    @State private var currentTheme: Theme = Theme.current

    // MARK: - Constants

    private let gridSpacing: CGFloat = 1
    private let pieceSizeRatio: CGFloat = 0.9

    // Callbacks
    private let feedbackCoordinator = FeedbackCoordinator.shared
    private let onReturnHome: () -> Void
    private let onReturnModeSelect: () -> Void

    // MARK: - Initialization

    init(
        gameMode: GameMode = .classic,
        onReturnHome: @escaping () -> Void = {},
        onReturnModeSelect: @escaping () -> Void = {}
    ) {
        let engine = GameEngine(gameMode: gameMode)
        let factory = BlockFactory()
        factory.attach(gameEngine: engine)
        _gameEngine = StateObject(wrappedValue: engine)
        _blockFactory = StateObject(wrappedValue: factory)
        _placementEngine = StateObject(wrappedValue: PlacementEngineV2(gameEngine: engine))
        self.onReturnHome = onReturnHome
        self.onReturnModeSelect = onReturnModeSelect
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Header
                    header(safeArea: geometry.safeAreaInsets)

                    Spacer(minLength: 0)

                    // Grid
                    gridView
                        .frame(width: boardSize, height: boardSize)

                    Spacer(minLength: 0)

                    // Hold Piece & Power-Ups Row
                    HStack(spacing: 12) {
                        HoldPieceSlot(
                            manager: holdPieceManager,
                            cellSize: pieceCellSize,
                            onSwap: handleHoldPieceSwap
                        )

                        Spacer()

                        PowerUpInventory(
                            manager: powerUpManager,
                            onActivate: handlePowerUpActivation
                        )
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 80)

                    // Tray
                    SimplifiedBlockTray(
                        blockFactory: blockFactory,
                        dragController: dragController,
                        cellSize: pieceCellSize,
                        slotSize: 90,
                        spacing: 12
                    )
                    .padding(.bottom, max(geometry.safeAreaInsets.bottom, 16))
                }

                // Floating drag preview
                if let pattern = dragController.draggedPattern,
                   case .active = dragController.dragState {
                    FloatingDragPreview(
                        pattern: pattern,
                        dragController: dragController,
                        gridCellSize: gridCellSize,
                        isValid: placementEngine.isPreviewValid
                    )
                }

                // Game Over Overlay
                if isGameOver {
                    GameOverOverlayV2(
                        score: gameEngine.score,
                        highScore: gameEngine.highScore,
                        onRestart: restartGame,
                        onReturnHome: onReturnHome
                    )
                }
            }
            .onAppear {
                setupGame(screenSize: geometry.size)
            }
            .onChange(of: geometry.size) { _, newSize in
                screenSize = newSize
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsViewV2(
                audioManager: audioManager,
                onRestart: restartGame,
                onReturnHome: onReturnHome
            )
        }
        .sheet(isPresented: $showDailyChallenges) {
            DailyChallengesView(
                manager: dailyChallengeManager,
                powerUpManager: powerUpManager
            )
        }
        .themeUnlockNotification(themeManager: themeManager) {
            // Open theme selector (TODO: implement)
            showSettings = true
        }
    }

    // MARK: - View Components

    private var backgroundColor: some View {
        ZStack {
            Color(currentTheme.backgroundColor)

            RadialGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25),
                    Color.clear
                ],
                center: .center,
                startRadius: 60,
                endRadius: 420
            )
        }
    }

    private func header(safeArea: EdgeInsets) -> some View {
        HStack(spacing: 16) {
            // High Score Badge
            HighScoreBadge(highScore: gameEngine.highScore)

            Spacer()

            // Current Score
            ScoreView(
                score: gameEngine.score,
                lastEvent: gameEngine.lastScoreEvent,
                isHighlighted: false
            )

            Spacer()

            // Settings Button
            Button {
                audioManager.playSound(.buttonClick)
                showSettings = true
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
        }
        .padding(.horizontal, 24)
        .padding(.top, safeArea.top + 12)
    }

    private var gridView: some View {
        ZStack(alignment: .topLeading) {
            // Grid cells
            GridView(
                gameEngine: gameEngine,
                dragController: DragController(),  // Dummy for compatibility
                cellSize: gridCellSize,
                gridSpacing: gridSpacing
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

            // Preview shadow
            PreviewShadow(
                positions: placementEngine.previewPositions,
                cellSize: gridCellSize,
                gridSpacing: gridSpacing,
                isValid: placementEngine.isPreviewValid,
                theme: currentTheme
            )
            .allowsHitTesting(false)
        }
    }

    // MARK: - Layout Calculations

    private var availableGridLength: CGFloat {
        guard screenSize != .zero else { return 320 }

        let horizontalPadding: CGFloat = 64
        let widthLimit = max(240, screenSize.width - horizontalPadding)

        let headerHeight: CGFloat = 120
        let holdPowerUpHeight: CGFloat = 80
        let trayHeight: CGFloat = 120
        let verticalSpacing: CGFloat = 40
        let safeAreaEstimate: CGFloat = 100

        let availableHeight = screenSize.height - headerHeight - holdPowerUpHeight - trayHeight - verticalSpacing - safeAreaEstimate
        let heightLimit = max(240, availableHeight)

        return min(widthLimit, heightLimit) * 0.95
    }

    private var gridCellSize: CGFloat {
        let totalSpacing = gridSpacing * CGFloat(gameEngine.gridSize + 1)
        let effectiveBoard = max(availableGridLength - totalSpacing, 10)
        return effectiveBoard / CGFloat(gameEngine.gridSize)
    }

    private var boardSize: CGFloat {
        gridCellSize * CGFloat(gameEngine.gridSize) + gridSpacing * CGFloat(gameEngine.gridSize + 1)
    }

    private var pieceCellSize: CGFloat {
        max(gridCellSize * pieceSizeRatio, 1)
    }

    // MARK: - Game Logic

    private func setupGame(screenSize: CGSize) {
        self.screenSize = screenSize

        // Initialize drag callbacks
        dragController.onDragBegan = { _, _, _ in
            audioManager.playSound(.piecePickup)
        }

        dragController.onDragChanged = { _, pattern, touchLocation in
            updatePlacementPreview(pattern: pattern, touchLocation: touchLocation)
        }

        dragController.onDragEnded = { index, pattern, touchLocation in
            handleDragEnd(blockIndex: index, pattern: pattern, touchLocation: touchLocation)
        }

        // Authenticate Game Center
        gameCenterManager.authenticatePlayer()

        // Start game
        blockFactory.attach(gameEngine: gameEngine)
        gameEngine.startNewGame()
        blockFactory.resetTray()

        // Refresh daily challenges
        dailyChallengeManager.refreshChallengesIfNeeded()
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            // Save game state
            cloudSaveStore.saveCurrentGame(from: gameEngine)
        case .inactive:
            audioManager.pause()
        case .active:
            audioManager.resume()
        @unknown default:
            break
        }
    }

    private func updatePlacementPreview(pattern: BlockPattern, touchLocation: CGPoint) {
        guard gridFrame != .zero else { return }

        let blockOrigin = dragController.getBlockOrigin()
        let fingerOffset = dragController.getScaledFingerOffset(gridCellSize: gridCellSize)

        placementEngine.updatePreview(
            pattern: pattern,
            blockOrigin: blockOrigin,
            fingerOffset: fingerOffset,
            gridFrame: gridFrame,
            gridCellSize: gridCellSize
        )
    }

    private func handleDragEnd(blockIndex: Int, pattern: BlockPattern, touchLocation: CGPoint) {
        if placementEngine.isPreviewValid {
            // Valid placement
            let success = placementEngine.commitPreview(pattern: pattern)

            if success {
                blockFactory.consumeBlock(at: blockIndex)

                let linesCleared = gameEngine.lastScoreEvent?.linesCleared ?? 0
                let boardCleared = gameEngine.isBoardCompletelyEmpty()

                // Play appropriate sound based on lines cleared
                if linesCleared >= 2 {
                    audioManager.playSound(.lineClearCombo)
                } else if linesCleared == 1 {
                    audioManager.playSound(.lineCleSingle)
                } else {
                    audioManager.playSound(.piecePlace)
                }

                triggerPlacementHaptics(linesCleared: linesCleared, boardCleared: boardCleared)

                // Update challenges and progression
                if linesCleared > 0 {
                    dailyChallengeManager.updateProgress(for: .lineClearCount, value: linesCleared)
                    powerUpManager.onLineClear(linesCleared: linesCleared)
                }

                if boardCleared {
                    audioManager.playSound(.achievement)
                }

                themeManager.recordProgress(
                    score: gameEngine.score,
                    linesCleared: linesCleared,
                    boardCleared: boardCleared
                )

                gameCenterManager.checkAndReportAchievements(
                    score: gameEngine.score,
                    linesCleared: linesCleared,
                    boardCleared: boardCleared
                )

                blockFactory.recordPlacement(linesCleared: linesCleared, boardCleared: boardCleared)

                // Submit score to Game Center
                gameCenterManager.submitScore(gameEngine.score)

                // Check game over
                evaluateGameOver()
            }
        } else {
            audioManager.playSound(.invalidPlacement)
            placementEngine.clearPreview()
            dragController.cancelDrag()
        }
    }

    private func triggerPlacementHaptics(linesCleared: Int, boardCleared: Bool) {
        if boardCleared {
            feedbackCoordinator.haptics.trigger(.perfectClear)
        } else if linesCleared > 0 {
            feedbackCoordinator.haptics.trigger(.lineClear(count: linesCleared))
        } else {
            feedbackCoordinator.haptics.trigger(.piecePlacement)
        }
    }

    private func evaluateGameOver() {
        guard gameEngine.isGameActive else { return }

        let blocks = blockFactory.availableBlocks
        let hasMove = gameEngine.hasAnyValidMove(using: blocks)

        if !hasMove {
            isGameOver = true
            gameEngine.endGame()
            audioManager.playSound(.gameOver)
        }
    }

    private func restartGame() {
        isGameOver = false
        gameEngine.startNewGame()
        blockFactory.resetTray()
        placementEngine.clearPreview()
        dragController.reset()
    }

    private func handleHoldPieceSwap(piece: BlockPattern) {
        // TODO: Implement hold piece swap logic
    }

    private func handlePowerUpActivation(powerUp: PowerUpType) {
        // TODO: Implement power-up activation
    }
}

// MARK: - Floating Drag Preview

private struct FloatingDragPreview: View {

    let pattern: BlockPattern
    @ObservedObject var dragController: DragControllerV2
    let gridCellSize: CGFloat
    let isValid: Bool

    var body: some View {
        let blockOrigin = dragController.getBlockOrigin()
        let blockWidth = CGFloat(pattern.size.width) * gridCellSize
        let blockHeight = CGFloat(pattern.size.height) * gridCellSize

        BlockView(
            blockPattern: pattern,
            cellSize: gridCellSize,
            isInteractive: false
        )
        .frame(width: blockWidth, height: blockHeight)
        .scaleEffect(dragController.dragScale, anchor: .center)
        .shadow(color: Color.black.opacity(dragController.shadowOpacity), radius: 12, x: 0, y: 6)
        .position(
            x: blockOrigin.x + blockWidth / 2,
            y: blockOrigin.y + blockHeight / 2
        )
        .allowsHitTesting(false)
        .zIndex(1000)
    }
}

// MARK: - Preview Shadow

private struct PreviewShadow: View {

    let positions: [GridPosition]
    let cellSize: CGFloat
    let gridSpacing: CGFloat
    let isValid: Bool
    let theme: Theme

    var body: some View {
        if isValid && !positions.isEmpty {
            ForEach(positions, id: \.self) { position in
                RoundedRectangle(cornerRadius: max(6, cellSize * 0.28))
                    .fill(theme.accentColor.opacity(0.2))
                    .frame(width: cellSize, height: cellSize)
                    .position(
                        x: gridSpacing + CGFloat(position.column) * (cellSize + gridSpacing) + cellSize / 2,
                        y: gridSpacing + CGFloat(position.row) * (cellSize + gridSpacing) + cellSize / 2
                    )
            }
        }
    }
}

// MARK: - Simplified Game Over Overlay

private struct GameOverOverlayV2: View {

    let score: Int
    let highScore: Int
    let onRestart: () -> Void
    let onReturnHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Game Over")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(score)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                VStack(spacing: 12) {
                    Button {
                        onRestart()
                    } label: {
                        Text("Play Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button {
                        onReturnHome()
                    } label: {
                        Text("Main Menu")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let store = CloudSaveStore()
    return GameViewV2()
        .environmentObject(AuthViewModel(cloudStore: store))
        .environmentObject(store)
}
