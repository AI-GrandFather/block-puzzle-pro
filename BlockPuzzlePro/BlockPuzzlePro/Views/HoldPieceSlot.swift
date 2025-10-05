import SwiftUI

// MARK: - Hold Piece Slot View

struct HoldPieceSlot: View {

    @ObservedObject var manager: HoldPieceManager

    let cellSize: CGFloat
    let onSwap: (BlockPattern) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            Text("HOLD")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(0.5)

            ZStack {
                // Background slot
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(slotBackground)
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(slotBorder, lineWidth: 2)
                    )

                // Held piece or empty state
                if let piece = manager.heldPiece {
                    BlockView(
                        blockPattern: piece,
                        cellSize: cellSize,
                        isInteractive: false
                    )
                    .scaleEffect(displayScale(for: piece))
                    .opacity(manager.canSwap ? 1.0 : 0.5)
                } else {
                    Image(systemName: "square.stack")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(.secondary.opacity(0.4))
                }

                // Cooldown overlay
                if !manager.canSwap {
                    ZStack {
                        Color.black.opacity(0.5)
                        ProgressView()
                            .tint(.white)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                // Swapping animation
                if manager.isSwapping {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .scaleEffect(1.1)
                        .opacity(0.8)
                        .animation(.easeOut(duration: 0.3), value: manager.isSwapping)
                }
            }
        }
        .frame(width: 80)
    }

    // MARK: - Helpers

    private var slotBackground: Color {
        if colorScheme == .dark {
            return Color(UIColor.systemGray5).opacity(0.5)
        } else {
            return Color.white.opacity(0.7)
        }
    }

    private var slotBorder: Color {
        if manager.heldPiece != nil {
            return Color.blue.opacity(0.6)
        } else {
            return Color.secondary.opacity(0.3)
        }
    }

    private func displayScale(for pattern: BlockPattern) -> CGFloat {
        let width = CGFloat(pattern.size.width) * cellSize
        let height = CGFloat(pattern.size.height) * cellSize
        let maxDimension = max(width, height)
        guard maxDimension > 0 else { return 1.0 }
        return min(1.0, 60.0 / maxDimension)
    }
}
