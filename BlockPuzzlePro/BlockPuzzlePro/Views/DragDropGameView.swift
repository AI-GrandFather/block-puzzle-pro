import SwiftUI
import Foundation
import CoreGraphics
import Combine
import QuartzCore
import UIKit

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
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var cloudSaveStore: CloudSaveStore
    
    // MARK: - State
    
    @State private var screenSize: CGSize = .zero
    @State private var isGameReady: Bool = false
    @State private var gridFrame: CGRect = .zero
    @State private var lineClearAnimationToken: UUID?
    @State private var celebrationMessage: CelebrationMessage?
    @State private var celebrationVisible: Bool = false
    @State private var isGameOver: Bool = false
    @State private var lastGameOverScore: Int = 0
    @State private var isSettingsPresented: Bool = false
    @State private var debugLoggingEnabled: Bool = false
    @State private var isGameOverThemePalettePresented: Bool = false
    @State private var isGameOverAccountPresented: Bool = false
    @State private var isScoreHighlightActive: Bool = false
    @State private var lastClearTimestamp: TimeInterval? = nil
    @State private var activeStreakCount: Int = 0
    @State private var scoreHighlightToken: UUID? = nil
    @State private var lastBoardClearScore: Int? = nil
    @State private var boardClearCelebrationActive: Bool = false
    @State private var boardClearCelebrationToken: UUID? = nil
    @State private var streakMessageToggle: Bool = false
    @State private var fragmentEffects: [FragmentEffect] = []
    @State private var fragmentCleanupQueue: Set<UUID> = []
    @State private var hasAppliedCloudSnapshot = false
    @State private var didObserveCloudSaves = false
    @State private var timerRemaining: Int = 0
    @State private var timerActive: Bool = false
    @State private var currentTheme: Theme = Theme.current
    @State private var previewColor: BlockColor? = nil

    // Visual lift applied to the floating block preview so pieces hover above the finger
    private let dragPreviewLift: CGFloat = 100.0

    // Performance optimization properties
    @State private var lastUpdateTime: TimeInterval = 0
    @State private var frameSkipCounter: Int = 0
    @State private var isProMotionDevice: Bool = false

    private let gridSpacing: CGFloat = 1
    private let gridSizingSafetyFactor: CGFloat = 0.99
    private let pieceSizeRatio: CGFloat = 0.9
    private let timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private let onReturnHome: () -> Void
    private let onReturnModeSelect: () -> Void
    
    // MARK: - Initialization
    
    init(
        gameMode: GameMode = .grid10x10,
        onReturnHome: @escaping () -> Void = {},
        onReturnModeSelect: @escaping () -> Void = {}
    ) {
        let gameEngine = GameEngine(gameMode: gameMode)
        let deviceManager = DeviceManager()
        
        _gameEngine = StateObject(wrappedValue: gameEngine)
        _deviceManager = StateObject(wrappedValue: deviceManager)
        _dragController = StateObject(wrappedValue: DragController(deviceManager: deviceManager))
        _placementEngine = StateObject(wrappedValue: PlacementEngine(gameEngine: gameEngine))
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
                
                if isGameReady {
                    VStack(spacing: 15) { // Reduced from 20 to 15 (25% reduction)
                        header(in: geometry)

                        Spacer(minLength: 0)

                        // Grid container with explicit centering and size constraints
                        gridView
                            .frame(width: boardSize, height: boardSize)
                            .clipped()
                            .frame(maxWidth: .infinity, alignment: .center)

                        Spacer(minLength: 0)

                        // Tray container
                        trayView(
                            viewWidth: geometry.size.width,
                            safeArea: geometry.safeAreaInsets.bottom
                        )
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(!isGameOver)
                    
                    // Floating drag preview - ONLY show when actually dragging (not just pressed)
                    if !isGameOver,
                       let draggedPattern = dragController.draggedBlockPattern,
                       case .dragging = dragController.dragState,
                       let previewOrigin = currentPreviewOrigin() {
                        let rootOrigin = geometry.frame(in: .global).origin

                        let cursorPosition = CGPoint(
                            x: previewOrigin.x - rootOrigin.x,
                            y: previewOrigin.y - rootOrigin.y
                        )

                        let snapScale = gridCellSize > 0 ? (gridCellSize / max(pieceCellSize, 1)) : 1
                        let previewScale = placementEngine.isCurrentPreviewValid && !placementEngine.previewPositions.isEmpty ? snapScale : dragController.dragScale

                        FloatingBlockPreview(
                            blockPattern: draggedPattern,
                            cellSize: pieceCellSize,
                            position: cursorPosition,
                            isValid: placementEngine.isCurrentPreviewValid,
                            scale: previewScale
                        )
                        .allowsHitTesting(false)
                        .opacity(1.0)
                        .zIndex(1000)
                    }
                } else {
                    // Loading state
                    loadingView
                }
        }
        .overlay(celebrationOverlay, alignment: .top)
        .overlay(gameOverOverlay)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheet(
                debugLoggingEnabled: $debugLoggingEnabled,
                onRestart: { restartFromSettings() },
                onExitToMenu: { exitToMainMenu() },
                onReturnToModeSelect: { returnToModeSelection() }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $isGameOverThemePalettePresented) {
            ThemePaletteSheet(theme: currentTheme)
        }
        .sheet(isPresented: $isGameOverAccountPresented) {
            NavigationStack {
                AccountView()
                    .navigationTitle("Account")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { isGameOverAccountPresented = false }
                        }
                    }
            }
            .presentationDetents([.large])
        }
        .onAppear {
            setupGameView(screenSize: geometry.size)
            setupPerformanceOptimizations()
            debugLoggingEnabled = DebugLog.isLoggingEnabled
            applyCloudSnapshotIfAvailable(force: true)
        }
        .onChange(of: geometry.size) { _, newValue in
                updateScreenSize(newValue)
            }
            .onReceive(gameEngine.$activeLineClears) { clears in
                guard !clears.isEmpty else { return }

                spawnFragments(from: clears)

                let token = UUID()
                lineClearAnimationToken = token

                let clearDelay: TimeInterval = isProMotionDevice ? 0.20 : 0.26
                DispatchQueue.main.asyncAfter(deadline: .now() + clearDelay) {
                    guard lineClearAnimationToken == token else { return }
                    gameEngine.clearActiveLineClears()
                }
            }
            .onChange(of: gameEngine.lastScoreEvent?.newTotal) { _, _ in
                guard let event = gameEngine.lastScoreEvent else { return }
                handleScoreHighlight(for: event)
                triggerCelebration(with: event)
            }
            .onReceive(blockFactory.$traySlots) { _ in
                evaluateGameOver()
            }
            .onChange(of: debugLoggingEnabled) { _, value in
                DebugLog.setEnabled(value)
            }
            .onReceive(cloudSaveStore.$saves) { _ in
                didObserveCloudSaves = true
                applyCloudSnapshotIfAvailable()
            }
            .onReceive(authViewModel.$session) { _ in
                didObserveCloudSaves = false
                hasAppliedCloudSnapshot = false
                applyCloudSnapshotIfAvailable()
            }
            .onReceive(timerPublisher) { _ in
                guard gameEngine.gameMode.isTimed, timerActive, gameEngine.isGameActive else { return }
                guard timerRemaining > 0 else {
                    handleTimerExpired()
                    return
                }
                timerRemaining -= 1
                if timerRemaining <= 0 {
                    handleTimerExpired()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { notification in
                if let newTheme = notification.object as? Theme {
                    currentTheme = newTheme
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                guard newPhase != .active else { return }
                saveProgressSnapshot()
            }
        }
        .onDisappear { stopTimer() }
        .environmentObject(deviceManager)
        // Removed .onChange(of: dragController.isDragging) due to non-existent property
    }
    
    // MARK: - View Components
    
    private var backgroundColor: some View {
        ZStack {
            Color(currentTheme.backgroundColor)

            RadialGradient(
                colors: [Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25), Color.clear],
                center: .center,
                startRadius: 60,
                endRadius: 420
            )
        }
    }
    
    private func header(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                HighScoreBadge(highScore: gameEngine.highScore)

                Spacer(minLength: 12)

                ScoreView(
                    score: gameEngine.score,
                    lastEvent: gameEngine.lastScoreEvent,
                    isHighlighted: isScoreHighlightActive
                )
                .frame(maxWidth: .infinity)

                Spacer(minLength: 12)

                settingsButton
            }

            if gameEngine.gameMode.isTimed {
                TimerBadge(timeRemaining: timerRemaining, isCountingDown: timerActive && gameEngine.isGameActive)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, geometry.safeAreaInsets.top + 12)
    }

    private var settingsButton: some View {
        Button {
            deviceManager.provideHapticFeedback(style: .light)
            isSettingsPresented = true
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
        .accessibilityLabel("Open settings")
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
        ZStack(alignment: .topLeading) {
            GridView(
                gameEngine: gameEngine,
                dragController: dragController,
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

            PlacementShadowOverlay(
                previewPositions: placementEngine.previewPositions,
                cellSize: gridCellSize,
                gridSpacing: gridSpacing,
                isValid: placementEngine.isCurrentPreviewValid,
                theme: currentTheme,
                color: previewColor.map { Color($0.uiColor) },
                isDragging: dragController.isDragging
            )
            .frame(width: boardSize, height: boardSize, alignment: .topLeading)
            .clipped()
            .allowsHitTesting(false)

            if boardClearCelebrationActive {
                RoundedRectangle(cornerRadius: max(16, gridCellSize * 0.5), style: .continuous)
                    .stroke(currentTheme.accentColor.opacity(0.55), lineWidth: 5)
                    .background(
                        RoundedRectangle(cornerRadius: max(16, gridCellSize * 0.5), style: .continuous)
                            .fill(currentTheme.accentColor.opacity(0.12))
                    )
                    .frame(width: boardSize, height: boardSize, alignment: .topLeading)
                    .blendMode(.screen)
                    .transition(.scale.combined(with: .opacity))
            }

            FragmentOverlayView(effects: fragmentEffects) { effectID in
                fragmentCleanupQueue.insert(effectID)
            }
            .frame(width: boardSize, height: boardSize, alignment: .topLeading)
            .allowsHitTesting(false)
        }
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

    private func trayView(viewWidth: CGFloat, safeArea: CGFloat) -> some View {
        let slotCount = max(1, CGFloat(blockFactory.getTraySlots().count))
        let horizontalInset: CGFloat = 18
        let slotSpacing = deviceManager.getOptimalTraySpacing()
        let clampedWidth = max(240, viewWidth - 64)
        let availableContentWidth = clampedWidth - horizontalInset * 2
        let totalSpacing = slotSpacing * max(slotCount - 1, 0)
        let rawSlotSize = (availableContentWidth - totalSpacing) / slotCount
        let sanitizedRaw = max(36, rawSlotSize)
        var slotSize = min(128, sanitizedRaw)
        let projectedWidth = slotSize * slotCount + totalSpacing + horizontalInset * 2
        if projectedWidth > clampedWidth {
            slotSize = max(32, rawSlotSize)
        }

        return DraggableBlockTrayView(
            blockFactory: blockFactory,
            dragController: dragController,
            cellSize: pieceCellSize,
            slotSize: slotSize,
            horizontalInset: horizontalInset,
            slotSpacing: slotSpacing
        ) { blockIndex, blockPattern in
            handleBlockDragStarted(blockIndex: blockIndex, blockPattern: blockPattern)
        }
        .padding(.bottom, max(safeArea + 12, 26))
    }

    private var celebrationOverlay: some View {
        ZStack(alignment: .top) {
            if let message = celebrationMessage, celebrationVisible {
                CelebrationToastView(message: message)
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var gameOverOverlay: some View {
        if isGameOver {
            GameOverOverlayView(
                theme: currentTheme,
                score: lastGameOverScore,
                highScore: gameEngine.highScore,
                onRestart: restartFromGameOver,
                onOpenThemes: { isGameOverThemePalettePresented = true },
                onOpenAccount: { isGameOverAccountPresented = true },
                onReturnHome: { exitToMainMenu() },
                onOpenModeSelect: { returnToModeSelection() }
            )
            .transition(.opacity.combined(with: .scale))
        }
    }
    
    private var availableGridLength: CGFloat {
        guard screenSize != .zero else { return 320 }

        // Conservative padding to ensure everything fits
        let horizontalPadding: CGFloat = 64
        let widthLimit = max(240, screenSize.width - horizontalPadding)

        // Calculate available height accounting for header and tray
        let headerHeight: CGFloat = 120 // Approximate header + spacing
        let trayHeight: CGFloat = 140    // Approximate tray height
        let verticalSpacing: CGFloat = 30 // VStack spacing
        let safeAreaEstimate: CGFloat = 100 // Top and bottom safe areas

        let availableHeight = screenSize.height - headerHeight - trayHeight - verticalSpacing - safeAreaEstimate
        let heightLimit = max(240, availableHeight)

        return min(widthLimit, heightLimit) * gridSizingSafetyFactor
    }

    private var gridCellSize: CGFloat {
        let usableSize = availableGridLength
        let totalSpacing = gridSpacing * CGFloat(gameEngine.gridSize + 1)
        let effectiveBoard = max(usableSize - totalSpacing, 10)
        // No multiplication - keep cells at optimal size to fit screen
        return effectiveBoard / CGFloat(gameEngine.gridSize)
    }

    private var boardSize: CGFloat {
        gridCellSize * CGFloat(gameEngine.gridSize) + gridSpacing * CGFloat(gameEngine.gridSize + 1)
    }

    private var pieceCellSize: CGFloat {
        max(gridCellSize * pieceSizeRatio, 1)
    }
    
    // MARK: - Performance Optimization

    private func setupPerformanceOptimizations() {
        Task { @MainActor in
            FrameRateConfigurator.configurePreferredFrameRate()
            let displayInfo = FrameRateConfigurator.currentDisplayInfo()
            isProMotionDevice = displayInfo.maxRefreshRate >= 120

            DebugLog.trace("🚀 Performance optimizations enabled")
            DebugLog.trace("📱 Device max refresh rate: \(displayInfo.maxRefreshRate)Hz")
            DebugLog.trace("🎯 Preferred frame rate: \(displayInfo.preferredRefreshRate)Hz")
            DebugLog.trace("⚡ ProMotion support: \(isProMotionDevice ? "YES" : "NO")")
        }
    }

    // MARK: - Game Logic

    private func setupGameView(screenSize: CGSize) {
        self.screenSize = screenSize

        // Clear any existing state first
        clearPlacementPreviewState()
        dragController.reset()
        isGameOver = false
        lastGameOverScore = 0
        isScoreHighlightActive = false
        lastClearTimestamp = nil
        activeStreakCount = 0
        scoreHighlightToken = nil
        lastBoardClearScore = nil
        boardClearCelebrationActive = false
        boardClearCelebrationToken = nil
        celebrationMessage = nil
        celebrationVisible = false
        streakMessageToggle = false
        isGameOverThemePalettePresented = false
        isGameOverAccountPresented = false

        // Setup drag controller callbacks
        setupDragCallbacks()

        // Start new game
        gameEngine.startNewGame()
        blockFactory.resetTray()
        initializeTimer()

        DispatchQueue.main.async {
            evaluateGameOver()
            saveProgressSnapshot()
        }

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

    // MARK: - Cloud Sync

    private func applyCloudSnapshotIfAvailable(force: Bool = false) {
        guard authViewModel.session != nil else { return }
        if force {
            hasAppliedCloudSnapshot = false
        }

        if !hasAppliedCloudSnapshot,
           let payload = cloudSaveStore.saves[gameEngine.gameMode] {
            restoreGameState(from: payload)
            hasAppliedCloudSnapshot = true
        } else if didObserveCloudSaves && !hasAppliedCloudSnapshot {
            hasAppliedCloudSnapshot = true
            saveProgressSnapshot()
        }
    }

    private func restoreGameState(from payload: GameSavePayload) {
        if gameEngine.gameMode.isTimed {
            gameEngine.restoreScore(total: 0, best: payload.highScore)
            blockFactory.resetTray()
            initializeTimer()
            isGameOver = false
            isGameReady = true
            return
        }

        stopTimer()
        gameEngine.restoreGrid(from: payload.grid)
        gameEngine.restoreScore(total: payload.score, best: payload.highScore)
        gameEngine.markActiveState(payload.isGameActive)
        blockFactory.restoreTray(from: payload.tray)
        isGameOver = !payload.isGameActive
        isGameReady = true
    }

    private func makeSavePayload() -> GameSavePayload {
        GameSavePayload(
            version: 1,
            timestamp: Date(),
            score: gameEngine.score,
            highScore: gameEngine.highScore,
            isGameActive: !isGameOver && gameEngine.isGameActive,
            grid: gameEngine.exportGrid(),
            tray: blockFactory.exportTray()
        )
    }

    private func saveProgressSnapshot() {
        guard authViewModel.session != nil else { return }
        let payload = makeSavePayload()
        Task {
            await cloudSaveStore.save(payload: payload, mode: gameEngine.gameMode)
        }
    }

    private func initializeTimer() {
        if gameEngine.gameMode.isTimed {
            timerRemaining = Int(gameEngine.gameMode.timerDuration ?? 0)
            timerActive = true
        } else {
            stopTimer()
        }
    }

    private func stopTimer() {
        timerActive = false
        timerRemaining = 0
    }

    private func handleTimerExpired() {
        guard gameEngine.gameMode.isTimed else { return }
        guard !isGameOver else { return }
        timerActive = false
        timerRemaining = 0
        deviceManager.provideNotificationFeedback(type: .warning)
        updateGameOverState(true)
        saveProgressSnapshot()
    }

    private func setupDragCallbacks() {
        // Drag began callback
        dragController.onDragBegan = { blockIndex, blockPattern, position in
            handleDragBegan(blockIndex: blockIndex, blockPattern: blockPattern, position: position)
            DebugLog.trace("🎯 onDragBegan blockIndex=\(blockIndex) position=\(position) pattern=\(blockPattern.type)")
        }
        
        // Drag changed callback
        dragController.onDragChanged = { blockIndex, blockPattern, position in
            // Update placement preview using the visual origin shown on screen
            let previewOrigin = self.currentPreviewOrigin() ?? self.dragController.currentDragPosition
            DebugLog.trace("🔄 onDragChanged blockIndex=\(blockIndex) reportedPosition=\(position) previewOrigin=\(previewOrigin)")
            self.updatePlacementPreview(blockPattern: blockPattern, blockOrigin: previewOrigin)
        }

        // Drag ended callback
        dragController.onDragEnded = { blockIndex, blockPattern, position in
            DebugLog.trace("🛑 onDragEnded blockIndex=\(blockIndex) position=\(position) state=\(self.dragController.dragState)")

            guard self.gridFrame != .zero else {
                self.handleInvalidPlacement(blockIndex: blockIndex, blockPattern: blockPattern, position: position)
                return
            }

            var placementSuccess = false

            if self.placementEngine.isCurrentPreviewValid,
               self.placementEngine.commitPlacement(blockPattern: blockPattern) {
                placementSuccess = true
            } else {
                let previewOrigin = self.currentPreviewOrigin() ?? self.dragController.currentDragPosition
                let adjustedTouchPoint = self.previewTouchPoint()

                DebugLog.trace("📍 DIRECT PLACEMENT: touch=\(self.dragController.currentTouchLocation) adjustedTouch=\(adjustedTouchPoint) origin=\(previewOrigin)")

                placementSuccess = self.placementEngine.placeBlockDirectly(
                    blockPattern: blockPattern,
                    blockOrigin: previewOrigin,
                    touchPoint: adjustedTouchPoint,
                    touchOffset: self.scaledTouchOffset(),
                    gridFrame: self.gridFrame,
                    cellSize: self.gridCellSize,
                    gridSpacing: self.gridSpacing
                )
            }

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
        performRestart(triggerHaptics: true)
    }

    private func restartFromSettings() {
        isSettingsPresented = false
        performRestart(triggerHaptics: true)
    }

    private func exitToMainMenu() {
        isSettingsPresented = false
        stopTimer()
        saveProgressSnapshot()
        deviceManager.provideHapticFeedback(style: .medium)
        clearPlacementPreviewState()
        onReturnHome()
    }

    private func returnToModeSelection() {
        isSettingsPresented = false
        stopTimer()
        saveProgressSnapshot()
        deviceManager.provideNotificationFeedback(type: .warning)
        clearPlacementPreviewState()
        onReturnModeSelect()
    }

    private func restartFromGameOver() {
        performRestart(triggerHaptics: true)
    }

    private func performRestart(triggerHaptics: Bool) {
        if triggerHaptics {
            deviceManager.provideHapticFeedback(style: .medium)
        }

        clearPlacementPreviewState()
        dragController.reset()
        blockFactory.resetTray()

        withAnimation(.easeInOut(duration: 0.3)) {
            isGameOver = false
            gameEngine.startNewGame()
        }

        lastGameOverScore = 0
        initializeTimer()

        DispatchQueue.main.async {
            evaluateGameOver()
            saveProgressSnapshot()
        }
    }
    
    // MARK: - Drag Event Handlers
    
    private func handleBlockDragStarted(blockIndex: Int, blockPattern: BlockPattern) {
    }
    
    private func handleDragBegan(blockIndex: Int, blockPattern: BlockPattern, position: CGPoint) {
        // Clear any existing preview state when a new drag begins
        clearPlacementPreviewState()
        previewColor = blockPattern.color
    }
    
    private func handleDragEnded() {
        clearPlacementPreviewState()
        cancelDragIfNeeded()
    }
    
    private func cancelDragIfNeeded() {
        // Currently nothing additional needed; placeholder for future logic if needed.
    }

    private func clearPlacementPreviewState() {
        placementEngine.clearPreview()
        previewColor = nil
    }

    // MARK: - Placement Engine Integration
    
    private func updatePlacementPreview(blockPattern: BlockPattern, blockOrigin: CGPoint) {
        guard gridFrame != .zero else { return }

        previewColor = blockPattern.color

        placementEngine.updatePreview(
            blockPattern: blockPattern,
            blockOrigin: blockOrigin,
            touchPoint: previewTouchPoint(),
            touchOffset: scaledTouchOffset(),
            gridFrame: gridFrame,
            cellSize: gridCellSize,
            gridSpacing: gridSpacing
        )
    }

    private func currentPreviewOrigin() -> CGPoint? {
        guard dragController.draggedBlockPattern != nil else { return nil }

        let touchLocation = dragController.currentTouchLocation
        let touchOffset = scaledTouchOffset()

        guard touchLocation != .zero || touchOffset != .zero else { return nil }

        let originX = touchLocation.x - touchOffset.width
        let originY = touchLocation.y - touchOffset.height - dragPreviewLift

        return CGPoint(x: originX, y: originY)
    }

    private func previewTouchPoint() -> CGPoint {
        CGPoint(
            x: dragController.currentTouchLocation.x,
            y: dragController.currentTouchLocation.y - dragPreviewLift
        )
    }

    private func scaledTouchOffset() -> CGSize {
        let offset = dragController.dragTouchOffset
        let sourceCellSize = dragController.dragSourceCellSize
        guard sourceCellSize > 0, gridCellSize > 0 else { return offset }

        let scale = gridCellSize / sourceCellSize
        return CGSize(width: offset.width * scale, height: offset.height * scale)
    }
    
    private func handleValidPlacement(blockIndex: Int, blockPattern: BlockPattern, position: CGPoint) {
        DebugLog.trace("✅ PLACEMENT SUCCESS: Block \(blockIndex) placed successfully")

        deviceManager.provideNotificationFeedback(type: .success)
        UIAccessibility.post(notification: .announcement, argument: "Placed block successfully")

        UIAccessibility.post(notification: .announcement, argument: "Lines cleared if any")

        // Regenerate the placed block (infinite supply design)
        blockFactory.consumeBlock(at: blockIndex)

        // Clear preview (drag controller handles its own cleanup)
        clearPlacementPreviewState()

        DispatchQueue.main.async {
            evaluateGameOver()
        }

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
              let topLeft = GridPosition(row: minRow, column: minCol, gridSize: gameEngine.gridSize) else {
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
        deviceManager.provideNotificationFeedback(type: .error)
        UIAccessibility.post(notification: .announcement, argument: "Invalid placement")

        // Clear preview (drag controller handles its own cleanup)
        clearPlacementPreviewState()
    }

    private func spawnFragments(from clears: [LineClear]) {
        guard !clears.isEmpty else { return }

        let cellSpan = gridCellSize + gridSpacing
        let fragmentSize = gridCellSize / 2.4
        let offsets: [CGPoint] = [
            CGPoint(x: 0.3, y: 0.3),
            CGPoint(x: 0.7, y: 0.3),
            CGPoint(x: 0.3, y: 0.7),
            CGPoint(x: 0.7, y: 0.7)
        ]

        var newEffects: [FragmentEffect] = []

        let fragments = clears.flatMap { $0.fragments }
        for fragment in fragments {
            let baseX = gridSpacing + CGFloat(fragment.position.column) * cellSpan
            let baseY = gridSpacing + CGFloat(fragment.position.row) * cellSpan

            for offsetPoint in offsets {
                let startPoint = CGPoint(
                    x: baseX + offsetPoint.x * gridCellSize,
                    y: baseY + offsetPoint.y * gridCellSize
                )

                let driftX = CGFloat.random(in: -22...22)
                let driftY = CGFloat.random(in: 80...140)
                let delay = Double.random(in: 0.0...0.08)
                let rotation = Double.random(in: -35...35)

                newEffects.append(
                    FragmentEffect(
                        color: Color(fragment.color.uiColor),
                        startPoint: startPoint,
                        targetOffset: CGSize(width: driftX, height: driftY),
                        size: fragmentSize * CGFloat.random(in: 0.75...1.05),
                        delay: delay,
                        duration: 0.55,
                        rotation: rotation
                    )
                )
            }
        }

        let maxNewEffects = 64
        if newEffects.count > maxNewEffects {
            fragmentEffects.append(contentsOf: newEffects.prefix(maxNewEffects))
        } else {
            fragmentEffects.append(contentsOf: newEffects)
        }

        let totalLimit = 120
        if fragmentEffects.count > totalLimit {
            fragmentEffects.removeFirst(fragmentEffects.count - totalLimit)
        }

        if !fragmentCleanupQueue.isEmpty {
            fragmentEffects.removeAll { fragmentCleanupQueue.contains($0.id) }
            fragmentCleanupQueue.removeAll()
        }
    }

    private func evaluateGameOver() {
        guard gameEngine.isGameActive else { return }

        guard blockFactory.hasAvailableBlocks else {
            updateGameOverState(false)
            return
        }

        let blocks = blockFactory.availableBlocks
        guard !blocks.isEmpty else {
            updateGameOverState(false)
            return
        }

        let hasMove = gameEngine.hasAnyValidMove(using: blocks)
        updateGameOverState(!hasMove)
    }

    private func updateGameOverState(_ shouldShow: Bool) {
        if shouldShow {
            guard !isGameOver else { return }
            lastGameOverScore = gameEngine.score
            if gameEngine.gameMode.isTimed {
                stopTimer()
            }
            gameEngine.endGame()
            clearPlacementPreviewState()
            dragController.reset()

            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                isGameOver = true
            }
        } else {
            guard isGameOver else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                isGameOver = false
            }
        }
    }
    
    // MARK: - Accessibility
    
    private func triggerCelebration(with event: ScoreEvent) {
        let boardCleared = gameEngine.isBoardCompletelyEmpty()
        let responseMultiplier: Double = isProMotionDevice ? 0.7 : 1.0

        let message: CelebrationMessage?
        if boardCleared, lastBoardClearScore != event.newTotal {
            message = CelebrationMessage(
                kind: .boardClear,
                primaryText: "Unstoppable!",
                secondaryText: "Board cleared!",
                accentColor: currentTheme.accentColor
            )
            lastBoardClearScore = event.newTotal
            activateBoardClearCelebration()
        } else {
            message = makeStreakMessage(from: event)
        }

        guard let message = message else { return }

        celebrationMessage = message

        withAnimation(.easeOut(duration: 0.25 * responseMultiplier)) {
            celebrationVisible = true
        }

        let token = message.id
        let displayDuration: TimeInterval
        switch message.kind {
        case .boardClear:
            displayDuration = isProMotionDevice ? 1.6 : 1.8
        case .streak:
            displayDuration = isProMotionDevice ? 1.2 : 1.4
        }

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

    private func makeStreakMessage(from event: ScoreEvent) -> CelebrationMessage? {
        guard event.linesCleared >= 2 else { return nil }

        let primary: String
        switch event.linesCleared {
        case 2:
            primary = "Fantastic!"
        case 3:
            primary = streakMessageToggle ? "Amazing!" : "Incredible!"
            streakMessageToggle.toggle()
        default:
            primary = "Unbelievable!"
        }

        let secondary = "\(event.linesCleared) lines cleared!"
        return CelebrationMessage(
            kind: .streak(level: event.linesCleared),
            primaryText: primary,
            secondaryText: secondary,
            accentColor: currentTheme.accentColor
        )
    }

    private func handleScoreHighlight(for event: ScoreEvent) {
        guard event.linesCleared > 0 else {
            activeStreakCount = 0
            return
        }

        let now = CACurrentMediaTime()
        if let last = lastClearTimestamp, now - last <= 2.5 {
            activeStreakCount += 1
        } else {
            activeStreakCount = 1
        }
        lastClearTimestamp = now

        if activeStreakCount >= 2 {
            activateScoreHighlight()
        }
    }

    private func activateScoreHighlight() {
        let token = UUID()
        scoreHighlightToken = token
        isScoreHighlightActive = true

        let duration: TimeInterval = isProMotionDevice ? 1.0 : 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.scoreHighlightToken == token {
                self.isScoreHighlightActive = false
            }
        }
    }

    private func activateBoardClearCelebration() {
        let token = UUID()
        boardClearCelebrationToken = token

        withAnimation(.easeOut(duration: 0.3)) {
            boardClearCelebrationActive = true
        }

        spawnBoardClearConfetti()

        let duration: TimeInterval = isProMotionDevice ? 1.4 : 1.6
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.boardClearCelebrationToken == token {
                withAnimation(.easeOut(duration: 0.35)) {
                    self.boardClearCelebrationActive = false
                }
            }
        }
    }

    private func spawnBoardClearConfetti() {
        guard gridFrame != .zero else { return }

        let cellSpan = gridCellSize + gridSpacing
        let strideValue = max(1, gameEngine.gridSize / 4)
        var newEffects: [FragmentEffect] = []

        for row in stride(from: 0, to: gameEngine.gridSize, by: strideValue) {
            for column in stride(from: 0, to: gameEngine.gridSize, by: strideValue) {
                let startPoint = CGPoint(
                    x: gridSpacing + CGFloat(column) * cellSpan + gridCellSize / 2,
                    y: gridSpacing + CGFloat(row) * cellSpan + gridCellSize / 2
                )

                let driftX = CGFloat.random(in: -28...28)
                let driftY = CGFloat.random(in: -90 ... -48)
                let delay = Double.random(in: 0...0.12)
                let duration = Double.random(in: 0.45...0.65)
                let size = gridCellSize / CGFloat.random(in: 2.8...3.4)
                let rotation = Double.random(in: -45...45)

                newEffects.append(
                    FragmentEffect(
                        color: currentTheme.accentColor,
                        startPoint: startPoint,
                        targetOffset: CGSize(width: driftX, height: driftY),
                        size: size,
                        delay: delay,
                        duration: duration,
                        rotation: rotation
                    )
                )
            }
        }

        fragmentEffects.append(contentsOf: newEffects)

        let totalLimit = 180
        if fragmentEffects.count > totalLimit {
            fragmentEffects.removeFirst(fragmentEffects.count - totalLimit)
        }

        if !fragmentCleanupQueue.isEmpty {
            fragmentEffects.removeAll { fragmentCleanupQueue.contains($0.id) }
            fragmentCleanupQueue.removeAll()
        }
    }

    private func announceGameState() {
        let announcement = "Game ready. \(blockFactory.getAvailableBlocks().count) blocks available. Score: \(gameEngine.score)"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }
}

// MARK: - Celebration Models

struct CelebrationMessage: Identifiable {
    enum Kind: Equatable {
        case streak(level: Int)
        case boardClear
    }

    let id = UUID()
    let kind: Kind
    let primaryText: String
    let secondaryText: String?
    let accentColor: Color
}

private struct CelebrationToastView: View {
    let message: CelebrationMessage

    @State private var animateContent = false

    var body: some View {
        VStack(spacing: 6) {
            Text(message.primaryText)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: message.accentColor.opacity(0.45), radius: 12, x: 0, y: 0)

            if let secondary = message.secondaryText {
                Text(secondary)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.92))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            message.accentColor.opacity(0.88),
                            message.accentColor.opacity(0.72)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: message.accentColor.opacity(0.35), radius: 26, x: 0, y: 18)
        .scaleEffect(animateContent ? 1.0 : 0.92)
        .opacity(animateContent ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if let secondary = message.secondaryText {
            return "\(message.primaryText). \(secondary)"
        }
        return message.primaryText
    }
}

private struct GameOverOverlayView: View {
    let theme: Theme
    let score: Int
    let highScore: Int
    let onRestart: () -> Void
    let onOpenThemes: () -> Void
    let onOpenAccount: () -> Void
    let onReturnHome: () -> Void
    let onOpenModeSelect: () -> Void

    @State private var animateContent = false

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private var isNewHighScore: Bool {
        score >= highScore && highScore > 0
    }

    private var formattedScore: String {
        GameOverOverlayView.numberFormatter.string(from: NSNumber(value: score)) ?? "\(score)"
    }

    private var formattedHighScore: String {
        GameOverOverlayView.numberFormatter.string(from: NSNumber(value: highScore)) ?? "\(highScore)"
    }

    private var gapMessage: String {
        guard !isNewHighScore else {
            return "Legendary run — you pushed the record higher!"
        }

        let gap = max(highScore - score, 0)
        guard gap > 0 else {
            return "One more move and the record is yours."
        }

        let gapString = GameOverOverlayView.numberFormatter.string(from: NSNumber(value: gap)) ?? "\(gap)"
        return "Only \(gapString) points away from the top score."
    }

    var body: some View {
        ZStack {
            background

            VStack(spacing: 28) {
                Spacer(minLength: 52)

                BlockClusterLogo(theme: theme)
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateContent ? 1.0 : 0.92)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.75), value: animateContent)

                header
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 16)
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: animateContent)

                scoreCard
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: animateContent)

                buttonStack
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 26)
                    .animation(.spring(response: 0.5, dampingFraction: 0.82), value: animateContent)

                secondaryActions
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 32)
                    .animation(.spring(response: 0.55, dampingFraction: 0.85), value: animateContent)

                Spacer(minLength: 36)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color.black.opacity(0.45))
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game over. Final score: \(score). High score: \(highScore)")
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                animateContent = true
            }
        }
    }

    private var background: some View {
        ZStack {
            theme.menuBackgroundGradient
                .overlay(
                    RadialGradient(
                        colors: [
                            theme.accentColor.opacity(0.3),
                            theme.accentColor.opacity(0.05)
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 420
                    )
                    .blendMode(.plusLighter)
                )
                .ignoresSafeArea()

            BlockGridBackground(color: theme.gridOverlayColor)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Game Over")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.primaryText)
                .multilineTextAlignment(.center)

            Text(isNewHighScore ? "New personal best. Keep the streak going!" : gapMessage)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }

    private var scoreCard: some View {
        VStack(spacing: 20) {
            Text("FINAL SCORE")
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.secondaryText)

            Text(formattedScore)
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.primaryText)

            if isNewHighScore {
                newHighBadge
            }

            Divider()
                .background(theme.surfaceHighlight.opacity(0.35))

            scorePill(title: "Best", value: formattedHighScore, systemIcon: "crown.fill")
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(theme.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                )
        )
        .shadow(color: theme.accentColor.opacity(0.24), radius: 28, x: 0, y: 20)
    }

    private var buttonStack: some View {
        VStack(spacing: 18) {
            MenuBlockButton(
                title: "Play Again",
                iconName: "play.fill",
                tint: theme.accentColor,
                theme: theme,
                action: onRestart
            )

            MenuBlockButton(
                title: "Themes",
                iconName: "paintpalette.fill",
                tint: theme.surfaceHighlight,
                theme: theme,
                action: onOpenThemes
            )

            MenuBlockButton(
                title: "Account",
                iconName: "person.crop.square",
                tint: theme.surfaceHighlight.opacity(0.85),
                theme: theme,
                action: onOpenAccount
            )
        }
    }

    private var secondaryActions: some View {
        HStack(spacing: 14) {
            SecondaryActionButton(
                title: "Main Menu",
                icon: "house.fill",
                theme: theme,
                action: onReturnHome
            )

            SecondaryActionButton(
                title: "Mode Select",
                icon: "square.grid.2x2",
                theme: theme,
                action: onOpenModeSelect
            )
        }
    }

    private var newHighBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 15, weight: .bold))

            Text("New High Score")
                .font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(theme.accentColor.opacity(0.18))
                .overlay(
                    Capsule()
                        .stroke(theme.accentColor.opacity(0.35), lineWidth: 1)
                )
        )
        .foregroundStyle(theme.accentColor)
    }

    private func scorePill(title: String, value: String, systemIcon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.primaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.surfaceBackground.opacity(theme.isDarkTheme ? 0.65 : 0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.surfaceHighlight.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private struct SecondaryActionButton: View {
        let title: String
        let icon: String
        let theme: Theme
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule(style: .continuous)
                        .fill(theme.surfaceBackground.opacity(theme.isDarkTheme ? 0.9 : 0.92))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .foregroundStyle(theme.primaryText)
            .shadow(color: theme.accentColor.opacity(0.12), radius: 12, x: 0, y: 6)
        }
    }
}

private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var debugLoggingEnabled: Bool
    @State private var currentTheme: Theme = Theme.current
    @State private var showThemes = false
    @State private var deferredAction: (() -> Void)?

    let onRestart: () -> Void
    let onExitToMenu: () -> Void
    let onReturnToModeSelect: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SettingsHero(theme: currentTheme)

                    GameSettingsOptionButton(
                        title: "Themes",
                        subtitle: "Recolor the board",
                        iconName: "paintpalette.fill",
                        theme: currentTheme
                    ) {
                        showThemes = true
                    }

                    GameSettingsOptionButton(
                        title: "Return to Main",
                        subtitle: "Exit this puzzle",
                        iconName: "house.fill",
                        theme: currentTheme
                    ) {
                        schedule(action: onExitToMenu)
                    }

                    GameSettingsOptionButton(
                        title: "Choose Game Mode",
                        subtitle: "Switch difficulty",
                        iconName: "square.grid.2x2",
                        theme: currentTheme
                    ) {
                        schedule(action: onReturnToModeSelect)
                    }

                    GameSettingsOptionButton(
                        title: "Restart",
                        subtitle: "Reset this run",
                        iconName: "arrow.counterclockwise",
                        theme: currentTheme
                    ) {
                        schedule(action: onRestart)
                    }

                    #if DEBUG
                    SettingsToggleRow(
                        title: "Verbose logging",
                        subtitle: "Enable tracing output",
                        isOn: $debugLoggingEnabled,
                        theme: currentTheme
                    )
                    #endif
                }
                .padding(24)
            }
            .background(currentTheme.backgroundColorSwift.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .tint(currentTheme.accentColor)
                }
            }
        }
        .sheet(isPresented: $showThemes) {
            ThemePaletteSheet(theme: currentTheme)
        }
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { notification in
            guard let newTheme = notification.object as? Theme else { return }
            currentTheme = newTheme
        }
        .onDisappear {
            if let action = deferredAction {
                deferredAction = nil
                action()
            }
        }
    }

    private func schedule(action: @escaping () -> Void) {
        deferredAction = action
        dismiss()
    }
}

private struct SettingsHero: View {
    let theme: Theme

    var body: some View {
        VStack(spacing: 12) {
            Text("Personalize")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.primaryText)
            Text("Adjust colors, restart or hop back to the menu.")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.secondaryText)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let theme: Theme

    var body: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(theme.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

private struct GameSettingsOptionButton: View {
    let title: String
    let subtitle: String
    let iconName: String
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accentColor.opacity(0.85))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(theme.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.secondaryText.opacity(0.85))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PlacementShadowOverlay: View {
    let previewPositions: [GridPosition]
    let cellSize: CGFloat
    let gridSpacing: CGFloat
    let isValid: Bool
    let theme: Theme
    let color: Color?
    let isDragging: Bool

    // Mirrors GameConfig.previewAlpha without pulling in that dependency here.
    private let baseOpacity: Double = 0.2

    private var shouldShowShadow: Bool {
        isDragging && isValid && !previewPositions.isEmpty
    }

    private var tint: Color {
        (color ?? theme.accentColor).opacity(baseOpacity)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if shouldShowShadow {
                ForEach(previewPositions, id: \.self) { position in
                    RoundedRectangle(cornerRadius: max(6, cellSize * 0.28))
                        .fill(tint)
                        .frame(width: cellSize, height: cellSize)
                        .offset(x: offset(for: position.column), y: offset(for: position.row))
                }
            }
        }
        .animation(.easeOut(duration: 0.12), value: previewPositions)
        .animation(.easeOut(duration: 0.12), value: shouldShowShadow)
    }

    private func offset(for index: Int) -> CGFloat {
        gridSpacing + CGFloat(index) * (cellSize + gridSpacing)
    }
}

private struct TimerBadge: View {
    let timeRemaining: Int
    let isCountingDown: Bool

    private var formatted: String {
        let clamped = max(0, timeRemaining)
        let minutes = clamped / 60
        let seconds = clamped % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isCountingDown ? "timer" : "timer.square")
                .font(.headline.weight(.semibold))
            Text(formatted)
                .font(.headline.monospacedDigit())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundStyle(Color.white)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.16))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 12, x: 0, y: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Timer")
        .accessibilityValue(formatted)
    }
}

// MARK: - Fragment Effects

private struct FragmentEffect: Identifiable {
    let id = UUID()
    let color: Color
    let startPoint: CGPoint
    let targetOffset: CGSize
    let size: CGFloat
    let delay: Double
    let duration: Double
    let rotation: Double
}

private struct FragmentOverlayView: View {
    let effects: [FragmentEffect]
    let onEffectFinished: (UUID) -> Void

    var body: some View {
        ZStack {
            ForEach(effects) { effect in
                FallingFragmentView(effect: effect) {
                    onEffectFinished(effect.id)
                }
            }
        }
    }
}

private struct FallingFragmentView: View {
    let effect: FragmentEffect
    let onComplete: () -> Void

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var rotation: Double = 0.0

    var body: some View {
        Rectangle()
            .fill(effect.color)
            .frame(width: effect.size, height: effect.size)
            .position(x: effect.startPoint.x, y: effect.startPoint.y)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: effect.duration).delay(effect.delay)) {
                    offset = effect.targetOffset
                    opacity = 0.0
                    rotation = effect.rotation
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + effect.delay + effect.duration + 0.05) {
                    onComplete()
                }
            }
    }
}

private extension Theme {
    var accentColor: Color { Color(blockColor) }
    var primaryText: Color { isDarkTheme ? Color.white : Color.black }
    var secondaryText: Color { primaryText.opacity(0.72) }
    var surfaceHighlight: Color { isDarkTheme ? Color.white.opacity(0.18) : Color.black.opacity(0.08) }
    var surfaceBackground: Color { isDarkTheme ? Color.white.opacity(0.12) : Color.white.opacity(0.9) }
    var gridOverlayColor: Color { isDarkTheme ? Color.white.opacity(0.05) : Color.black.opacity(0.05) }
    var backgroundColorSwift: Color { Color(backgroundColor) }
    var menuBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                backgroundColorSwift,
                backgroundColorSwift.opacity(isDarkTheme ? 0.88 : 0.95),
                accentColor.opacity(isDarkTheme ? 0.45 : 0.32)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
