import SwiftUI

// MARK: - Hold Piece Slot View

/// Enhanced hold slot view with swap animations and mode indicators
struct HoldPieceSlot: View {

    // MARK: - Properties

    let manager: HoldPieceManager
    let cellSize: CGFloat
    let onTap: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    @State private var isPulsing: Bool = false

    // MARK: - Initialization

    init(
        manager: HoldPieceManager,
        cellSize: CGFloat,
        onTap: (() -> Void)? = nil
    ) {
        self.manager = manager
        self.cellSize = cellSize
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 6) {
            // Header with label
            headerView

            // Main slot container
            ZStack {
                // Background slot
                slotBackgroundView

                // Held piece or empty state
                if let piece = manager.heldPiece {
                    heldPieceView(piece: piece)
                } else {
                    emptyStateView
                }

                // Cooldown overlay
                if manager.isOnCooldown {
                    cooldownOverlay
                }

                // Swap animation border
                if manager.isSwapping {
                    swapAnimationBorder
                }

                // Badge for limited uses mode
                if manager.shouldShowBadge {
                    usageBadge
                }
            }
            .frame(width: 90, height: 90)
            .onTapGesture {
                onTap?()
            }
        }
        .frame(width: 90)
        .onAppear {
            startPulsingAnimation()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 4) {
            Text("HOLD")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.0)

            // Circular arrows icon
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }

    @ViewBuilder
    private var slotBackgroundView: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(slotBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(slotBorder, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private func heldPieceView(piece: BlockPattern) -> some View {
        BlockView(
            blockPattern: piece,
            cellSize: cellSize,
            isInteractive: false
        )
        .scaleEffect(displayScale(for: piece) * manager.swapScale)
        .rotationEffect(.degrees(manager.swapRotation))
        .opacity(canSwapOpacity)
        .animation(.easeInOut(duration: 0.3), value: manager.swapRotation)
        .animation(.easeInOut(duration: 0.3), value: manager.swapScale)
        .scaleEffect(isPulsing && manager.canSwapPiece() ? 1.05 : 1.0)
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 4) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundColor(.secondary.opacity(0.3))

            Text("Empty")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.4))
        }
    }

    @ViewBuilder
    private var cooldownOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)

            VStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                Text("Cooldown")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .transition(.opacity)
    }

    @ViewBuilder
    private var swapAnimationBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [.blue, .cyan, .blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 4
            )
            .scaleEffect(1.15)
            .opacity(0.9)
            .transition(.scale.combined(with: .opacity))
    }

    @ViewBuilder
    private var usageBadge: some View {
        VStack {
            HStack {
                Spacer()

                ZStack {
                    Circle()
                        .fill(manager.getBadgeColor())
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Text("\(manager.remainingHolds)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .offset(x: 8, y: -8)
            }

            Spacer()
        }
    }

    // MARK: - Computed Properties

    private var slotBackground: Color {
        if manager.heldPiece != nil && manager.canSwapPiece() {
            // Slight glow when ready to swap
            return colorScheme == .dark
                ? Color(UIColor.systemGray4).opacity(0.7)
                : Color.white.opacity(0.9)
        } else {
            return colorScheme == .dark
                ? Color(UIColor.systemGray5).opacity(0.5)
                : Color.white.opacity(0.7)
        }
    }

    private var slotBorder: Color {
        if manager.isSwapping {
            return .blue
        } else if manager.heldPiece != nil && manager.canSwapPiece() {
            return Color.blue.opacity(0.8)
        } else if manager.isOnCooldown {
            return Color.orange.opacity(0.6)
        } else {
            return Color.secondary.opacity(0.3)
        }
    }

    private var canSwapOpacity: Double {
        if manager.isOnCooldown {
            return 0.4
        } else if !manager.canSwapPiece() {
            return 0.5
        } else {
            return 1.0
        }
    }

    // MARK: - Helper Methods

    private func displayScale(for pattern: BlockPattern) -> CGFloat {
        let width = CGFloat(pattern.size.width) * cellSize
        let height = CGFloat(pattern.size.height) * cellSize
        let maxDimension = max(width, height)
        guard maxDimension > 0 else { return 1.0 }
        return min(1.0, 70.0 / maxDimension) // Slightly larger for better visibility
    }

    private func startPulsingAnimation() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            isPulsing = true
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        // With held piece - can swap
        HoldPieceSlot(
            manager: {
                let mgr = HoldPieceManager(swapMode: .unlimited)
                mgr.heldPiece = BlockPattern(type: .lShape, color: .blue)
                return mgr
            }(),
            cellSize: 18
        )

        // With held piece - cooldown
        HoldPieceSlot(
            manager: {
                let mgr = HoldPieceManager(swapMode: .oncePerTurn)
                mgr.heldPiece = BlockPattern(type: .square, color: .red)
                mgr.isOnCooldown = true
                return mgr
            }(),
            cellSize: 18
        )

        // Empty slot
        HoldPieceSlot(
            manager: HoldPieceManager(),
            cellSize: 18
        )

        // Limited uses mode
        HoldPieceSlot(
            manager: {
                let mgr = HoldPieceManager(swapMode: .limitedUses(3))
                mgr.heldPiece = BlockPattern(type: .plus, color: .green)
                return mgr
            }(),
            cellSize: 18
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
