//
//  DragDebugOverlay.swift
//  BlockPuzzlePro
//
//  Created on October 3, 2025
//  Purpose: Visual debugging overlay for drag & drop coordinate system
//

import SwiftUI

/// Debug overlay showing real-time coordinate information
struct DragDebugOverlay: View {

    @ObservedObject var dragController: SimplifiedDragController
    @ObservedObject var placementEngine: SimplifiedPlacementEngine

    let gridFrame: CGRect
    let cellSize: CGFloat

    var body: some View {
        ZStack {
            if dragController.isDragging {
                // Finger position indicator (red dot)
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .position(dragController.currentTouchLocation)
                    .overlay(
                        Text("Touch")
                            .font(.caption2)
                            .foregroundColor(.red)
                            .offset(x: 30, y: 0)
                            .position(dragController.currentTouchLocation)
                    )

                // Block origin indicator (blue square)
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .position(
                        x: dragController.currentBlockOrigin.x + 10,
                        y: dragController.currentBlockOrigin.y + 10
                    )
                    .overlay(
                        Text("Origin")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .offset(x: 35, y: 0)
                            .position(
                                x: dragController.currentBlockOrigin.x + 10,
                                y: dragController.currentBlockOrigin.y + 10
                            )
                    )

                // Finger offset line (green)
                Path { path in
                    path.move(to: dragController.currentTouchLocation)
                    path.addLine(to: dragController.currentBlockOrigin)
                }
                .stroke(Color.green, lineWidth: 2)
                .overlay(
                    Text("Offset: (\(Int(dragController.fingerOffset.width)), \(Int(dragController.fingerOffset.height)))")
                        .font(.caption2)
                        .foregroundColor(.green)
                        .background(Color.black.opacity(0.7))
                        .padding(4)
                        .position(midpoint)
                )

                // Grid cell highlight (yellow)
                if let cell = dragController.getGridCell(
                    touchLocation: dragController.currentTouchLocation,
                    gridFrame: gridFrame,
                    cellSize: cellSize
                ) {
                    let cellOrigin = dragController.gridCellToScreen(
                        row: cell.row,
                        column: cell.column,
                        gridFrame: gridFrame,
                        cellSize: cellSize
                    )

                    Rectangle()
                        .stroke(
                            placementEngine.isCurrentPreviewValid ? Color.yellow : Color.red,
                            lineWidth: 3
                        )
                        .frame(width: cellSize, height: cellSize)
                        .position(
                            x: cellOrigin.x + cellSize / 2,
                            y: cellOrigin.y + cellSize / 2
                        )
                        .overlay(
                            Text("Cell (\(cell.row), \(cell.column))")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                                .background(Color.black.opacity(0.7))
                                .padding(4)
                                .position(
                                    x: cellOrigin.x + cellSize / 2,
                                    y: cellOrigin.y - 10
                                )
                        )
                }

                // Info panel at top
                infoPanel
                    .position(x: UIScreen.main.bounds.width / 2, y: 50)
            }
        }
        .allowsHitTesting(false)  // Don't interfere with drag gestures
    }

    private var midpoint: CGPoint {
        CGPoint(
            x: (dragController.currentTouchLocation.x + dragController.currentBlockOrigin.x) / 2,
            y: (dragController.currentTouchLocation.y + dragController.currentBlockOrigin.y) / 2
        )
    }

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🔍 Debug Info")
                .font(.headline)

            if let cell = dragController.getGridCell(
                touchLocation: dragController.currentTouchLocation,
                gridFrame: gridFrame,
                cellSize: cellSize
            ) {
                Text("Grid Cell: (\(cell.row), \(cell.column))")
                Text("Preview Valid: \(placementEngine.isCurrentPreviewValid ? "✅" : "❌")")
                Text("Preview Positions: \(placementEngine.previewPositions.count)")
            } else {
                Text("Grid Cell: Outside")
            }

            Text("Touch: (\(Int(dragController.currentTouchLocation.x)), \(Int(dragController.currentTouchLocation.y)))")
            Text("Origin: (\(Int(dragController.currentBlockOrigin.x)), \(Int(dragController.currentBlockOrigin.y)))")
            Text("Offset: (\(Int(dragController.fingerOffset.width)), \(Int(dragController.fingerOffset.height)))")

            // Verification
            let calculatedOrigin = CGPoint(
                x: dragController.currentTouchLocation.x - dragController.fingerOffset.width,
                y: dragController.currentTouchLocation.y - dragController.fingerOffset.height
            )
            let matches = abs(calculatedOrigin.x - dragController.currentBlockOrigin.x) < 0.1 &&
                         abs(calculatedOrigin.y - dragController.currentBlockOrigin.y) < 0.1

            Text("Math Check: \(matches ? "✅ PASS" : "❌ FAIL")")
                .foregroundColor(matches ? .green : .red)
                .fontWeight(.bold)
        }
        .font(.system(size: 11, weight: .medium, design: .monospaced))
        .padding(8)
        .background(Color.black.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}

// MARK: - Vicinity Touch Overlay

/// Visual overlay showing vicinity touch radius
struct VicinityTouchOverlay: View {

    let blockFrame: CGRect
    let vicinityRadius: CGFloat

    var body: some View {
        Circle()
            .stroke(Color.purple.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
            .frame(width: vicinityRadius * 2, height: vicinityRadius * 2)
            .position(
                x: blockFrame.midX,
                y: blockFrame.midY
            )
            .overlay(
                Text("Vicinity: \(Int(vicinityRadius))pt")
                    .font(.caption2)
                    .foregroundColor(.purple)
                    .background(Color.black.opacity(0.7))
                    .padding(4)
                    .position(
                        x: blockFrame.midX,
                        y: blockFrame.minY - 20
                    )
            )
            .allowsHitTesting(false)
    }
}

// MARK: - Grid Overlay

/// Grid coordinate overlay showing cell indices
struct GridCoordinateOverlay: View {

    let gridFrame: CGRect
    let cellSize: CGFloat
    let gridSize: Int

    var body: some View {
        ZStack {
            // Draw grid lines
            ForEach(0..<gridSize + 1, id: \.self) { index in
                // Horizontal lines
                Path { path in
                    let y = gridFrame.minY + (CGFloat(index) * cellSize)
                    path.move(to: CGPoint(x: gridFrame.minX, y: y))
                    path.addLine(to: CGPoint(x: gridFrame.maxX, y: y))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)

                // Vertical lines
                Path { path in
                    let x = gridFrame.minX + (CGFloat(index) * cellSize)
                    path.move(to: CGPoint(x: x, y: gridFrame.minY))
                    path.addLine(to: CGPoint(x: x, y: gridFrame.maxY))
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            }

            // Label some cells
            ForEach(0..<min(gridSize, 10), id: \.self) { row in
                ForEach(0..<min(gridSize, 10), id: \.self) { col in
                    if row % 2 == 0 && col % 2 == 0 {
                        let x = gridFrame.minX + (CGFloat(col) * cellSize) + (cellSize / 2)
                        let y = gridFrame.minY + (CGFloat(row) * cellSize) + (cellSize / 2)

                        Text("(\(row),\(col))")
                            .font(.system(size: 8))
                            .foregroundColor(.gray.opacity(0.5))
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// Preview intentionally omitted; requires runtime dependencies not available in the static build context.
