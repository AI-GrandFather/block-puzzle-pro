//
//  SimplifiedGameView.swift
//  BlockPuzzlePro
//
//  Created on October 3, 2025
//  Purpose: Integrated game view using simplified drag & drop system
//

import SwiftUI

/// Main game view with simplified drag & drop system
struct SimplifiedGameView: View {

    // MARK: - State Objects

    @StateObject private var gameEngine = GameEngine(gameMode: .grid10x10)
    @StateObject private var blockFactory = BlockFactory()
    @StateObject private var dragController: SimplifiedDragController
    @StateObject private var placementEngine: SimplifiedPlacementEngine
    @StateObject private var deviceManager = DeviceManager()

    // MARK: - State

    @State private var gridFrame: CGRect = .zero
    @State private var isGameOver: Bool = false

    // MARK: - Constants

    private let gridSize = 10
    private let gridCellSize: CGFloat = 36.0
    private let gridSpacing: CGFloat = 0.0
    private let trayCellSize: CGFloat = 32.0
    private let traySlotSize: CGFloat = 90.0
    private let vicinityRadius: CGFloat = 80.0

    // MARK: - Initialization

    init() {
        let deviceMgr = DeviceManager()
        let engine = GameEngine(gameMode: .grid10x10)

        _dragController = StateObject(wrappedValue: SimplifiedDragController(deviceManager: deviceMgr))
        _placementEngine = StateObject(wrappedValue: SimplifiedPlacementEngine(
            gameEngine: engine,
            gridSize: 10
        ))
        _deviceManager = StateObject(wrappedValue: deviceMgr)
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header with score
                    ScoreView(
                        score: gameEngine.score,
                        highScore: gameEngine.highScore
                    )
                    .padding(.top, geometry.safeAreaInsets.top + 10)

                    Spacer()

                    // Game grid
                    GridView(
                        gameEngine: gameEngine,
                        cellSize: gridCellSize,
                        spacing: gridSpacing,
                        previewPositions: placementEngine.previewPositions,
                        isPreviewValid: placementEngine.isCurrentPreviewValid
                    )
                    .background(
                        GeometryReader { gridGeo in
                            Color.clear.onAppear {
                                gridFrame = gridGeo.frame(in: .global)
                            }
                            .onChange(of: gridGeo.frame(in: .global)) { _, newFrame in
                                gridFrame = newFrame
                            }
                        }
                    )

                    Spacer()

                    // Block tray
                    blockTrayView
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }

                // Floating block during drag
                if dragController.isDragging,
                   let pattern = dragController.draggedBlockPattern {
                    FloatingBlock(
                        pattern: pattern,
                        cellSize: trayCellSize,
                        origin: dragController.currentBlockOrigin,
                        scale: dragController.dragScale,
                        shadowOpacity: dragController.shadowOpacity,
                        shadowRadius: dragController.shadowRadius,
                        shadowOffset: dragController.shadowOffset
                    )
                }
            }
        }
        .onAppear {
            startNewGame()
        }
    }

    // MARK: - Block Tray

    private var blockTrayView: some View {
        HStack(spacing: 16) {
            ForEach(Array(blockFactory.getTraySlots().enumerated()), id: \.offset) { index, pattern in
                if let blockPattern = pattern {
                    TrayBlockSlot(
                        pattern: blockPattern,
                        index: index,
                        cellSize: trayCellSize,
                        slotSize: traySlotSize,
                        isDragged: dragController.draggedBlockIndex == index,
                        onDragStart: { touchLocation, blockFrame in
                            handleDragStart(
                                index: index,
                                pattern: blockPattern,
                                touchLocation: touchLocation,
                                blockFrame: blockFrame
                            )
                        },
                        onDragUpdate: { touchLocation in
                            handleDragUpdate(touchLocation: touchLocation)
                        },
                        onDragEnd: { touchLocation in
                            handleDragEnd(touchLocation: touchLocation)
                        }
                    )
                } else {
                    EmptyTraySlot(size: traySlotSize)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Drag Handlers

    private func handleDragStart(
        index: Int,
        pattern: BlockPattern,
        touchLocation: CGPoint,
        blockFrame: CGRect
    ) {
        // Use vicinity touch - check if touch is near block center
        let blockCenter = CGPoint(x: blockFrame.midX, y: blockFrame.midY)

        guard dragController.shouldSelectBlock(
            touchLocation: touchLocation,
            blockCenter: blockCenter,
            vicinityRadius: vicinityRadius
        ) else {
            return
        }

        // Calculate block origin (top-left)
        let blockOrigin = CGPoint(
            x: blockFrame.minX,
            y: blockFrame.minY
        )

        // Start drag
        dragController.startDrag(
            blockIndex: index,
            pattern: pattern,
            touchLocation: touchLocation,
            blockOrigin: blockOrigin
        )
    }

    private func handleDragUpdate(touchLocation: CGPoint) {
        guard dragController.isDragging else { return }

        // Update drag position
        dragController.updateDrag(to: touchLocation)

        // Update preview
        if let pattern = dragController.draggedBlockPattern {
            placementEngine.updatePreview(
                blockPattern: pattern,
                touchLocation: touchLocation,
                gridFrame: gridFrame,
                cellSize: gridCellSize
            )
        }
    }

    private func handleDragEnd(touchLocation: CGPoint) {
        guard dragController.isDragging,
              let pattern = dragController.draggedBlockPattern,
              let blockIndex = dragController.draggedBlockIndex else {
            return
        }

        dragController.endDrag(at: touchLocation)

        // Check if we have valid preview
        if placementEngine.isCurrentPreviewValid, !placementEngine.previewPositions.isEmpty {
            // Calculate snap position (top-left of grid cell)
            if let firstPosition = placementEngine.previewPositions.first {
                let snapPosition = placementEngine.gridToScreenPosition(
                    gridPosition: firstPosition,
                    gridFrame: gridFrame,
                    cellSize: gridCellSize,
                    gridSpacing: gridSpacing
                )

                // Place block
                if placementEngine.placeAtPreview(blockPattern: pattern) {
                    // Success - animate to snap position
                    dragController.completePlacement(snapToPosition: snapPosition)

                    // Regenerate block in tray
                    blockFactory.consumeBlock(at: blockIndex)

                    // Check game over
                    evaluateGameOver()
                } else {
                    // Failed to place
                    dragController.returnToTray()
                }
            } else {
                dragController.returnToTray()
            }
        } else {
            // Invalid placement
            dragController.returnToTray()
        }

        // Clear preview
        placementEngine.clearPreview()
    }

    // MARK: - Game Logic

    private func startNewGame() {
        gameEngine.startNewGame()
        blockFactory.resetTray()
        isGameOver = false
    }

    private func evaluateGameOver() {
        let availableBlocks = blockFactory.getTraySlots().compactMap { $0 }

        if !gameEngine.hasAnyValidMove(using: availableBlocks) {
            isGameOver = true
            gameEngine.endGame()
        }
    }
}

// MARK: - Tray Block Slot

private struct TrayBlockSlot: View {

    let pattern: BlockPattern
    let index: Int
    let cellSize: CGFloat
    let slotSize: CGFloat
    let isDragged: Bool

    let onDragStart: (CGPoint, CGRect) -> Void
    let onDragUpdate: (CGPoint) -> Void
    let onDragEnd: (CGPoint) -> Void

    @State private var blockFrame: CGRect = .zero
    @State private var isPressed: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BlockView(
                    blockPattern: pattern,
                    cellSize: cellSize,
                    isInteractive: true,
                    showShadow: false  // NO shadow in tray
                )
                .frame(width: blockWidth, height: blockHeight)
                .scaleEffect(displayScale)
                .frame(width: slotSize, height: slotSize)
                .opacity(isDragged ? 0.0 : 1.0)
                .scaleEffect(isPressed ? 1.05 : 1.0)
                .animation(.easeOut(duration: 0.1), value: isPressed)
                .animation(.easeOut(duration: 0.15), value: isDragged)
            }
            .frame(width: slotSize, height: slotSize)
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onAppear {
                updateBlockFrame(in: geometry)
            }
            .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                blockFrame = newFrame
            }
        }
        .frame(width: slotSize, height: slotSize)
    }

    private var blockWidth: CGFloat {
        CGFloat(pattern.size.width) * cellSize
    }

    private var blockHeight: CGFloat {
        CGFloat(pattern.size.height) * cellSize
    }

    private var displayScale: CGFloat {
        let maxDimension = max(blockWidth, blockHeight)
        guard maxDimension > 0 else { return 1.0 }
        let availableSpace = slotSize * 0.85
        return min(1.0, availableSpace / maxDimension)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !isPressed {
                    isPressed = true
                    onDragStart(value.location, blockFrame)
                } else {
                    onDragUpdate(value.location)
                }
            }
            .onEnded { value in
                isPressed = false
                onDragEnd(value.location)
            }
    }

    private func updateBlockFrame(in geometry: GeometryProxy) {
        blockFrame = geometry.frame(in: .global)
    }
}

// MARK: - Empty Tray Slot

private struct EmptyTraySlot: View {

    let size: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(
                Color.white.opacity(0.2),
                style: StrokeStyle(lineWidth: 1, dash: [4, 6])
            )
            .frame(width: size * 0.7, height: size * 0.7)
            .frame(width: size, height: size)
    }
}

// MARK: - Floating Block

private struct FloatingBlock: View {

    let pattern: BlockPattern
    let cellSize: CGFloat
    let origin: CGPoint
    let scale: CGFloat
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    let shadowOffset: CGSize

    var body: some View {
        BlockView(
            blockPattern: pattern,
            cellSize: cellSize,
            isInteractive: true,
            showShadow: false  // No inner shadow, we apply outer shadow below
        )
        .frame(
            width: CGFloat(pattern.size.width) * cellSize,
            height: CGFloat(pattern.size.height) * cellSize
        )
        .scaleEffect(scale)
        // Prominent shadow for dragged block over grid
        .shadow(
            color: Color.black.opacity(max(shadowOpacity, 0.35)),  // Minimum 35% opacity for visibility
            radius: max(shadowRadius, 12),  // Minimum 12pt radius for prominence
            x: shadowOffset.width,
            y: max(shadowOffset.height, 6)  // Minimum 6pt offset for depth
        )
        .position(
            x: origin.x + (CGFloat(pattern.size.width) * cellSize * scale) / 2,
            y: origin.y + (CGFloat(pattern.size.height) * cellSize * scale) / 2
        )
        .allowsHitTesting(false)
        .zIndex(1000)  // Ensure it's above everything else
    }
}

// MARK: - Preview

#Preview {
    SimplifiedGameView()
}
