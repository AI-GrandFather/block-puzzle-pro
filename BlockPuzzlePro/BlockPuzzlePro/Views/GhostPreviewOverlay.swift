//
//  GhostPreviewOverlay.swift
//  BlockPuzzlePro
//
//  Created on October 5, 2025
//  Purpose: Visual overlay showing ghost preview with validity indicators
//

import SwiftUI

// MARK: - Ghost Preview Overlay

/// Visual overlay for ghost preview during drag operations
struct GhostPreviewOverlay: View {

    // MARK: - Properties

    let previewState: GhostPreviewState
    let cellSize: CGFloat
    let gridSpacing: CGFloat
    let gridSize: Int

    @State private var animationOpacity: Double = 0.0

    // MARK: - Body

    var body: some View {
        ZStack {
            if previewState.isVisible, let pattern = previewState.blockPattern {
                // Ghost block overlay
                ghostBlockView(pattern: pattern)

                // Line clear preview highlights
                if let lineClearPreview = previewState.linesClearPreview {
                    lineClearHighlights(preview: lineClearPreview)
                }

                // Score preview display
                if let scorePreview = previewState.scorePreview, previewState.validity.isValid {
                    scorePreviewView(scorePreview: scorePreview)
                }
            }
        }
        .opacity(animationOpacity)
        .onChange(of: previewState.isVisible) { _, newValue in
            withAnimation(.easeInOut(duration: 0.1)) {
                animationOpacity = newValue ? 1.0 : 0.0
            }
        }
        .allowsHitTesting(false) // Don't intercept touch events
    }

    // MARK: - Ghost Block View

    @ViewBuilder
    private func ghostBlockView(pattern: BlockPattern) -> some View {
        if let position = previewState.position {
            let ghostColor = getGhostColor(validity: previewState.validity)
            let outlineColor = getOutlineColor(validity: previewState.validity)

            ForEach(Array(previewState.affectedPositions.enumerated()), id: \.offset) { _, gridPos in
                ghostCell(at: gridPos, color: ghostColor, outlineColor: outlineColor)
            }
        }
    }

    @ViewBuilder
    private func ghostCell(at position: GridPosition, color: Color, outlineColor: Color) -> some View {
        let cellPosition = calculateCellPosition(gridPosition: position)

        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(
                        outlineColor,
                        style: StrokeStyle(
                            lineWidth: 2,
                            dash: [5, 3]
                        )
                    )
            )
            .frame(width: cellSize, height: cellSize)
            .position(
                x: cellPosition.x + cellSize / 2,
                y: cellPosition.y + cellSize / 2
            )
    }

    // MARK: - Line Clear Highlights

    @ViewBuilder
    private func lineClearHighlights(preview: LineClearPreview) -> some View {
        let highlightColor = Color.green.opacity(0.2)

        // Highlight rows
        ForEach(Array(preview.rows), id: \.self) { row in
            rowHighlight(row: row, color: highlightColor)
        }

        // Highlight columns
        ForEach(Array(preview.columns), id: \.self) { column in
            columnHighlight(column: column, color: highlightColor)
        }
    }

    @ViewBuilder
    private func rowHighlight(row: Int, color: Color) -> some View {
        let yPosition = CGFloat(row) * (cellSize + gridSpacing) + gridSpacing
        let width = CGFloat(gridSize) * (cellSize + gridSpacing) - gridSpacing

        Rectangle()
            .fill(color)
            .frame(width: width, height: cellSize)
            .position(
                x: width / 2,
                y: yPosition + cellSize / 2
            )
    }

    @ViewBuilder
    private func columnHighlight(column: Int, color: Color) -> some View {
        let xPosition = CGFloat(column) * (cellSize + gridSpacing) + gridSpacing
        let height = CGFloat(gridSize) * (cellSize + gridSpacing) - gridSpacing

        Rectangle()
            .fill(color)
            .frame(width: cellSize, height: height)
            .position(
                x: xPosition + cellSize / 2,
                y: height / 2
            )
    }

    // MARK: - Score Preview

    @ViewBuilder
    private func scorePreviewView(scorePreview: ScorePreview) -> some View {
        if let position = previewState.position {
            let centerPosition = calculatePreviewCenterPosition(gridPosition: position)

            Text("+\(scorePreview.totalScore)")
                .font(.system(size: scorePreview.magnitude.fontSize, weight: .bold, design: .rounded))
                .foregroundColor(scorePreview.magnitude.color)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                .position(
                    x: centerPosition.x,
                    y: centerPosition.y - cellSize * 1.5 // Above the ghost
                )
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Helper Methods

    private func calculateCellPosition(gridPosition: GridPosition) -> CGPoint {
        let x = CGFloat(gridPosition.column) * (cellSize + gridSpacing) + gridSpacing
        let y = CGFloat(gridPosition.row) * (cellSize + gridSpacing) + gridSpacing
        return CGPoint(x: x, y: y)
    }

    private func calculatePreviewCenterPosition(gridPosition: GridPosition) -> CGPoint {
        guard let pattern = previewState.blockPattern else {
            return .zero
        }

        let blockWidth = pattern.size.width * cellSize
        let blockHeight = pattern.size.height * cellSize

        let topLeft = calculateCellPosition(gridPosition: gridPosition)

        return CGPoint(
            x: topLeft.x + blockWidth / 2,
            y: topLeft.y + blockHeight / 2
        )
    }

    private func getGhostColor(validity: PlacementValidity) -> Color {
        let baseOpacity = 0.3
        switch validity {
        case .valid:
            return Color(red: 0.20, green: 0.78, blue: 0.35).opacity(baseOpacity) // Green
        case .invalid:
            return Color(red: 1.0, green: 0.23, blue: 0.19).opacity(baseOpacity) // Red
        }
    }

    private func getOutlineColor(validity: PlacementValidity) -> Color {
        switch validity {
        case .valid:
            return Color(red: 0.20, green: 0.78, blue: 0.35) // #34C759
        case .invalid:
            return Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
        }
    }
}

// MARK: - Preview

#Preview {
    let mockPattern = BlockPattern(type: .lShape, color: .blue)
    let mockPosition = GridPosition(unsafeRow: 2, unsafeColumn: 3)

    let mockState = GhostPreviewState(
        isVisible: true,
        position: mockPosition,
        validity: .valid,
        blockPattern: mockPattern,
        affectedPositions: mockPattern.getGridPositions(placedAt: mockPosition),
        linesClearPreview: LineClearPreview(rows: [2], columns: [3, 4]),
        scorePreview: ScorePreview(placementScore: 40, lineClearScore: 300, totalScore: 340)
    )

    return GhostPreviewOverlay(
        previewState: mockState,
        cellSize: 35,
        gridSpacing: 2,
        gridSize: 10
    )
    .frame(width: 370, height: 370)
    .background(Color.black.opacity(0.1))
}
