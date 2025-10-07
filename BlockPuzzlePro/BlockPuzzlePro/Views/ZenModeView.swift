import SwiftUI

/// Zen Mode - No pressure, no failure, pure relaxation
/// Child-friendly: Calm colors, unlimited undo, no game over
struct ZenModeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var gameLogic = ZenGameLogic()

    // UI state
    @State private var showSettings = false
    @State private var showBreathingGuide = false
    @State private var showSessionSummary = false
    @State private var selectedMood: ZenMood?

    // Session tracking
    @State private var sessionStartTime = Date()

    private let config = ZenModeConfiguration.default
    private let gridSize = 10

    var body: some View {
        ZStack {
            // Background with zen colors
            ZenColorPalette.backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Top bar - minimal, non-intrusive
                topBar

                Spacer()

                // Main grid
                ZenGridView(
                    grid: gameLogic.grid,
                    cellSize: cellSize,
                    gridSize: gridSize
                )
                .padding(.horizontal, 24)

                Spacer()

                // Piece preview (next 3 pieces)
                if config.showPiecePreview {
                    upcomingPiecesPreview
                        .padding(.bottom, 12)
                }

                // Current pieces tray
                ZenPieceTray(
                    pieces: gameLogic.currentPieces,
                    cellSize: cellSize * 0.8,
                    onPiecePlaced: { index, row, col in
                        gameLogic.placePiece(at: index, row: row, column: col)
                    }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Undo button (always available)
                if gameLogic.canUndo {
                    undoButton
                        .padding(.bottom, 20)
                }
            }

            // Optional breathing guide overlay
            if showBreathingGuide {
                BreathingGuideView(position: .center, useChildFriendlyText: true)
                    .transition(.scale.combined(with: .opacity))
            }

            // Session summary on exit
            if showSessionSummary {
                ZenSessionSummaryView(
                    duration: Date().timeIntervalSince(sessionStartTime),
                    blocksPlaced: gameLogic.blocksPlaced,
                    linesCleared: gameLogic.linesCleared,
                    perfectClears: gameLogic.perfectClears,
                    onContinue: { showSessionSummary = false },
                    onExit: {
                        gameLogic.saveSession(mood: selectedMood)
                        dismiss()
                    },
                    onSelectMood: { mood in selectedMood = mood }
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden()
    }

    // MARK: - UI Components

    private var topBar: some View {
        HStack {
            // Exit button
            Button(action: { showSessionSummary = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                    Text("Exit")
                }
                .foregroundStyle(ZenColorPalette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
            }

            Spacer()

            // Subtle stats (score hidden but tracked)
            VStack(alignment: .trailing, spacing: 2) {
                Text("🧘 Zen Mode")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(ZenColorPalette.textPrimary)

                Text("\(gameLogic.linesCleared) lines cleared")
                    .font(.caption)
                    .foregroundStyle(ZenColorPalette.textSecondary)
            }

            Spacer()

            // Breathing guide toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBreathingGuide.toggle()
                }
            }) {
                Image(systemName: showBreathingGuide ? "lungs.fill" : "lungs")
                    .font(.title3)
                    .foregroundStyle(ZenColorPalette.accentCalm)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var upcomingPiecesPreview: some View {
        HStack(spacing: 12) {
            Text("Next:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ZenColorPalette.textSecondary)

            HStack(spacing: 8) {
                ForEach(gameLogic.upcomingPieces.prefix(3), id: \.self) { pieceType in
                    MiniBlockPreview(blockType: pieceType, cellSize: cellSize * 0.3)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private var undoButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3 * config.animationSpeedMultiplier)) {
                gameLogic.undo()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.body.weight(.semibold))
                Text("Undo (\(gameLogic.undoCount))")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        ZenColorPalette.accentCalm,
                        ZenColorPalette.accentWarm
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .shadow(color: ZenColorPalette.accentCalm.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }

    private var cellSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let availableWidth = screenWidth - 48 // padding
        return (availableWidth / CGFloat(gridSize)) * 0.9
    }
}

// MARK: - Zen Grid View

private struct ZenGridView: View {
    let grid: [[Bool]]
    let cellSize: CGFloat
    let gridSize: Int

    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<gridSize, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<gridSize, id: \.self) { col in
                        ZenGridCell(
                            isFilled: grid[row][col],
                            cellSize: cellSize
                        )
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ZenColorPalette.gridBorder, lineWidth: 1)
                )
        )
    }
}

private struct ZenGridCell: View {
    let isFilled: Bool
    let cellSize: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cellSize * 0.15, style: .continuous)
            .fill(isFilled ? randomZenColor() : ZenColorPalette.gridCell)
            .frame(width: cellSize, height: cellSize)
    }

    private func randomZenColor() -> Color {
        ZenColorPalette.blockColors.randomElement() ?? ZenColorPalette.accentCalm
    }
}

// MARK: - Zen Piece Tray

private struct ZenPieceTray: View {
    let pieces: [BlockType?]
    let cellSize: CGFloat
    let onPiecePlaced: (Int, Int, Int) -> Void

    var body: some View {
        HStack(spacing: 20) {
            ForEach(Array(pieces.enumerated()), id: \.offset) { index, piece in
                if let piece = piece {
                    ZenDraggableBlock(
                        blockType: piece,
                        cellSize: cellSize,
                        index: index,
                        onPlaced: { row, col in
                            onPiecePlaced(index, row, col)
                        }
                    )
                } else {
                    // Empty slot
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(ZenColorPalette.gridBorder, style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        .frame(width: cellSize * 3, height: cellSize * 3)
                        .opacity(0.3)
                }
            }
        }
    }
}

// MARK: - Zen Draggable Block (Simplified)

private struct ZenDraggableBlock: View {
    let blockType: BlockType
    let cellSize: CGFloat
    let index: Int
    let onPlaced: (Int, Int) -> Void

    @State private var isDragging = false

    var body: some View {
        BlockShapeView(
            blockType: blockType,
            cellSize: cellSize,
            color: randomZenColor()
        )
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isDragging)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    isDragging = true
                }
                .onEnded { _ in
                    isDragging = false
                    // Simplified: trigger placement
                    onPlaced(0, 0)
                }
        )
    }

    private func randomZenColor() -> Color {
        ZenColorPalette.blockColors.randomElement() ?? ZenColorPalette.accentCalm
    }
}

// MARK: - Mini Block Preview

private struct MiniBlockPreview: View {
    let blockType: BlockType
    let cellSize: CGFloat

    var body: some View {
        BlockShapeView(
            blockType: blockType,
            cellSize: cellSize,
            color: ZenColorPalette.accentCalm.opacity(0.6)
        )
    }
}

// MARK: - Session Summary

private struct ZenSessionSummaryView: View {
    let duration: TimeInterval
    let blocksPlaced: Int
    let linesCleared: Int
    let perfectClears: Int
    let onContinue: () -> Void
    let onExit: () -> Void
    let onSelectMood: (ZenMood) -> Void

    @State private var selectedMood: ZenMood?

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { /* prevent dismissal */ }

            VStack(spacing: 24) {
                Text("🧘 Session Complete")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                VStack(spacing: 16) {
                    StatRow(icon: "⏱️", label: "Time", value: formattedDuration)
                    StatRow(icon: "📦", label: "Blocks placed", value: "\(blocksPlaced)")
                    StatRow(icon: "✨", label: "Lines cleared", value: "\(linesCleared)")
                    if perfectClears > 0 {
                        StatRow(icon: "🌟", label: "Perfect clears", value: "\(perfectClears)")
                    }
                }

                VStack(spacing: 12) {
                    Text("How are you feeling?")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    HStack(spacing: 12) {
                        ForEach(ZenMood.allCases, id: \.self) { mood in
                            Button(action: {
                                selectedMood = mood
                                onSelectMood(mood)
                            }) {
                                Text(mood.emoji)
                                    .font(.largeTitle)
                                    .padding(12)
                                    .background(
                                        selectedMood == mood
                                        ? ZenColorPalette.accentCalm.opacity(0.3)
                                        : Color.white.opacity(0.1),
                                        in: Circle()
                                    )
                            }
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button(action: onContinue) {
                        Text("Keep Playing")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                ZenColorPalette.accentCalm,
                                in: Capsule()
                            )
                    }

                    Button(action: onExit) {
                        Text("Exit")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color.white.opacity(0.2),
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal, 24)
        }
    }

    private var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

private struct StatRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(icon)
                .font(.title2)
            Text(label)
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Text(value)
                .font(.body.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.white.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}

// MARK: - Zen Game Logic

@MainActor
private class ZenGameLogic: ObservableObject {
    @Published private(set) var grid: [[Bool]]
    @Published private(set) var currentPieces: [BlockType?]
    @Published private(set) var upcomingPieces: [BlockType]
    @Published private(set) var blocksPlaced = 0
    @Published private(set) var linesCleared = 0
    @Published private(set) var perfectClears = 0
    @Published private(set) var score = 0

    private let undoManager = ZenUndoManager()
    private let statistics = ZenStatistics.load()
    private let gridSize = 10

    var canUndo: Bool { undoManager.canUndo }
    var undoCount: Int { undoManager.undoCount }

    init() {
        // Initialize empty grid
        self.grid = Array(repeating: Array(repeating: false, count: gridSize), count: gridSize)

        // Generate initial pieces
        self.currentPieces = [
            BlockType.allCases.randomElement(),
            BlockType.allCases.randomElement(),
            BlockType.allCases.randomElement()
        ]

        // Generate upcoming pieces
        self.upcomingPieces = (0..<6).map { _ in BlockType.allCases.randomElement()! }

        // Record initial state
        recordState()
    }

    func placePiece(at index: Int, row: Int, column: Int) {
        // Simplified placement logic
        // In real implementation, validate placement and update grid

        // Remove placed piece
        currentPieces[index] = nil
        blocksPlaced += 1

        // Check if all pieces used
        if currentPieces.allSatisfy({ $0 == nil }) {
            refillPieces()
        }

        // Record state for undo
        recordState()

        // Check for line clears (simplified)
        checkLineClears()
    }

    func undo() {
        guard let previousState = undoManager.undo() else { return }

        // Restore grid state
        grid = previousState.filledCells
        score = previousState.score
        blocksPlaced = max(0, previousState.moveCount)
    }

    func saveSession(mood: ZenMood?) {
        let sessionDuration = TimeInterval(300) // placeholder
        statistics.recordSession(
            duration: sessionDuration,
            blocksPlaced: blocksPlaced,
            linesCleared: linesCleared,
            perfectClears: perfectClears,
            mood: mood
        )
    }

    private func recordState() {
        undoManager.recordState(grid: grid, score: score, moveCount: blocksPlaced)
    }

    private func refillPieces() {
        // Move upcoming pieces to current
        currentPieces = [
            upcomingPieces[0],
            upcomingPieces[1],
            upcomingPieces[2]
        ]

        // Remove used upcoming and generate new ones
        upcomingPieces.removeFirst(3)
        upcomingPieces.append(contentsOf: (0..<3).map { _ in BlockType.allCases.randomElement()! })
    }

    private func checkLineClears() {
        // Simplified line clear detection
        var clearedCount = 0

        // Check rows
        for row in 0..<gridSize {
            if grid[row].allSatisfy({ $0 }) {
                clearedCount += 1
            }
        }

        linesCleared += clearedCount

        // Check if entire board cleared
        if grid.allSatisfy({ $0.allSatisfy({ $0 == false }) }) {
            perfectClears += 1
        }
    }
}

// MARK: - Block Shape View (Simplified)

private struct BlockShapeView: View {
    let blockType: BlockType
    let cellSize: CGFloat
    let color: Color

    var body: some View {
        // Simplified block rendering
        RoundedRectangle(cornerRadius: cellSize * 0.2, style: .continuous)
            .fill(color)
            .frame(width: cellSize * 2, height: cellSize * 2)
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}
