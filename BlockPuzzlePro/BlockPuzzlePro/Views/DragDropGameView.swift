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
    @Environment(\.dismiss) private var dismissView
    
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
    @State private var fragmentEffects: [FragmentEffect] = []
    @State private var fragmentCleanupQueue: Set<UUID> = []

    // Performance optimization properties
    @State private var lastUpdateTime: TimeInterval = 0
    @State private var frameSkipCounter: Int = 0
    @State private var isProMotionDevice: Bool = false

    private let gridSpacing: CGFloat = 2
    
    // MARK: - Initialization
    
    init(gameMode: GameMode = .grid10x10) {
        let gameEngine = GameEngine(gameMode: gameMode)
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
                    VStack(spacing: 20) {
                        header(in: geometry)

                        // Grid container with explicit centering and size constraints
                        gridView
                            .frame(width: boardSize, height: boardSize)
                            .frame(maxWidth: geometry.size.width - 48, alignment: .center)
                            .clipped()

                        // Tray container
                        trayView(
                            viewWidth: geometry.size.width,
                            safeArea: geometry.safeAreaInsets.bottom
                        )
                            .frame(maxWidth: geometry.size.width - 48, alignment: .center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(!isGameOver)
                    
                    // Floating drag preview overlay
                    if !isGameOver, let draggedPattern = dragController.draggedBlockPattern {
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
        .overlay(gameOverOverlay)
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheet(
                debugLoggingEnabled: $debugLoggingEnabled,
                onRestart: { restartFromSettings() },
                onExitToMenu: { exitToMainMenu() }
            )
            .presentationDetents([.medium])
        }
        .onAppear {
            setupGameView(screenSize: geometry.size)
            setupPerformanceOptimizations()
            debugLoggingEnabled = DebugLog.isLoggingEnabled
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
                triggerCelebration(with: gameEngine.lastScoreEvent)
            }
            .onReceive(blockFactory.$traySlots) { _ in
                evaluateGameOver()
            }
            .onChange(of: debugLoggingEnabled) { _, value in
                DebugLog.setEnabled(value)
            }
        }
        .environmentObject(deviceManager)
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
    
    private func header(in geometry: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: 16) {
            HighScoreBadge(highScore: gameEngine.highScore)

            Spacer(minLength: 12)

            ScoreView(
                score: gameEngine.score,
                lastEvent: gameEngine.lastScoreEvent
            )
            .frame(maxWidth: .infinity)

            Spacer(minLength: 12)

            settingsButton
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
        let clampedWidth = max(240, viewWidth - 48)
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
            cellSize: gridCellSize,
            slotSize: slotSize,
            horizontalInset: horizontalInset,
            slotSpacing: slotSpacing
        ) { blockIndex, blockPattern in
            handleBlockDragStarted(blockIndex: blockIndex, blockPattern: blockPattern)
        }
        .padding(.bottom, max(safeArea + 12, 26))
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        if let message = celebrationMessage, celebrationVisible {
            CelebrationBannerView(message: message)
                .padding(.horizontal, 24)
                .padding(.top, 16)
            .transition(.move(edge: .top).combined(with: .opacity))
            .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var gameOverOverlay: some View {
        if isGameOver {
            GameOverOverlayView(
                score: lastGameOverScore,
                highScore: gameEngine.highScore,
                onRestart: restartFromGameOver,
                onOpenSettings: { isSettingsPresented = true }
            )
            .transition(.opacity.combined(with: .scale))
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
        let totalSpacing = gridSpacing * CGFloat(gameEngine.gridSize + 1)
        let effectiveBoard = max(usableSize - totalSpacing, 10)
        return effectiveBoard / CGFloat(gameEngine.gridSize)
    }

    private var boardSize: CGFloat {
        gridCellSize * CGFloat(gameEngine.gridSize) + gridSpacing * CGFloat(gameEngine.gridSize + 1)
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
        isGameOver = false
        lastGameOverScore = 0

        // Setup drag controller callbacks
        setupDragCallbacks()

        // Start new game
        gameEngine.startNewGame()
        blockFactory.resetTray()

        DispatchQueue.main.async {
            evaluateGameOver()
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
        performRestart(triggerHaptics: true)
    }

    private func restartFromSettings() {
        isSettingsPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            performRestart(triggerHaptics: true)
        }
    }

    private func exitToMainMenu() {
        isSettingsPresented = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            deviceManager.provideHapticFeedback(style: .medium)
            dismissView()
        }
    }

    private func restartFromGameOver() {
        performRestart(triggerHaptics: true)
    }

    private func performRestart(triggerHaptics: Bool) {
        if triggerHaptics {
            deviceManager.provideHapticFeedback(style: .medium)
        }

        placementEngine.clearPreview()
        dragController.reset()
        blockFactory.resetTray()

        withAnimation(.easeInOut(duration: 0.3)) {
            isGameOver = false
            gameEngine.startNewGame()
        }

        lastGameOverScore = 0

        DispatchQueue.main.async {
            evaluateGameOver()
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

        deviceManager.provideNotificationFeedback(type: .success)
        UIAccessibility.post(notification: .announcement, argument: "Placed block successfully")

        UIAccessibility.post(notification: .announcement, argument: "Lines cleared if any")

        // Regenerate the placed block (infinite supply design)
        blockFactory.consumeBlock(at: blockIndex)

        // Clear preview (drag controller handles its own cleanup)
        placementEngine.clearPreview()

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
        placementEngine.clearPreview()
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
            gameEngine.endGame()
            placementEngine.clearPreview()
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

private struct GameOverOverlayView: View {
    let score: Int
    let highScore: Int
    let onRestart: () -> Void
    let onOpenSettings: () -> Void

    @State private var showContent = false

    private var isNewHighScore: Bool {
        score >= highScore && highScore > 0
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)

                    Text("Game Over")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)

                    if isNewHighScore {
                        Text("New high score!")
                            .font(.headline)
                            .foregroundStyle(Color.yellow)
                    }
                }

                VStack(spacing: 10) {
                    scoreRow(label: "Final Score", value: score, color: Color.white)
                    scoreRow(label: "Best", value: highScore, color: Color.yellow)
                }

                VStack(spacing: 16) {
                    Button(action: onRestart) {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.accentColor))
                    }

                    Button(action: onOpenSettings) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .font(.headline)
                            .foregroundStyle(Color.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.accentColor.opacity(0.5), lineWidth: 1.2)
                            )
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 30, x: 0, y: 18)
            .scaleEffect(showContent ? 1.0 : 0.92)
            .opacity(showContent ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showContent = true
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Game over. Final score: \(score). High score: \(highScore)")
    }

    private func scoreRow(label: String, value: Int, color: Color) -> some View {
        HStack {
            Text(label.uppercased())
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.7))

            Spacer()

            Text("\(value)")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var debugLoggingEnabled: Bool
    let onRestart: () -> Void
    let onExitToMenu: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("Session") {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            onExitToMenu()
                        }
                    } label: {
                        Label("Return to Main Menu", systemImage: "house.fill")
                            .font(.headline)
                    }

                    Button {
                        onRestart()
                        dismiss()
                    } label: {
                        Label("Restart Game", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                    }
                }

                #if DEBUG
                Section("Debug") {
                    Toggle(isOn: $debugLoggingEnabled) {
                        Label("Verbose debug logging", systemImage: "waveform")
                    }
                }
                #endif
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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


private struct CelebrationBannerView: View {
    let message: CelebrationMessage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: message.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(10)
                .background(
                    Circle().fill(Color.accentColor.opacity(0.85))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.headline.bold())
                    .foregroundStyle(Color.white)
                Text(message.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            if message.points > 0 {
                Spacer(minLength: 12)
                Text("+\(message.points)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.white.opacity(0.2))
                    )
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
