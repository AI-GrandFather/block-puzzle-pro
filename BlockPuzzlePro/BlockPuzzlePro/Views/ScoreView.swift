import SwiftUI

/// Displays the player's current score with subtle animation on updates.
struct ScoreView: View {
    let score: Int
    let highScore: Int
    let lastEvent: ScoreEvent?

    @State private var scale: CGFloat = 1.0
    @State private var deltaOpacity: Double = 0.0
    @State private var deltaOffset: CGFloat = 4.0

    var body: some View {
        ZStack(alignment: .topTrailing) {
            scorePlate

            if let deltaText = deltaText {
                Text(deltaText)
                    .font(.caption.bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentGradient(opacity: 0.22))
                            .overlay(
                                Capsule()
                                    .stroke(accentGradient(opacity: 0.65), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(Color.accentColor)
                    .opacity(deltaOpacity)
                    .offset(y: deltaOffset)
            }
        }
        .onAppear {
            scale = 1.0
        }
        .onChange(of: score) { _, _ in
            let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120
            let responseMultiplier: Double = isProMotion ? 0.7 : 1.0

            withAnimation(.spring(response: 0.35 * responseMultiplier, dampingFraction: 0.6)) {
                scale = 1.12
            }
            withAnimation(.spring(response: 0.5 * responseMultiplier, dampingFraction: 0.8).delay(0.12 * responseMultiplier)) {
                scale = 1.0
            }
        }
        .onChange(of: lastEvent?.newTotal) { _, _ in
            guard let event = lastEvent, event.totalDelta != 0 else { return }
            let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120
            let speedMultiplier: Double = isProMotion ? 0.8 : 1.0

            deltaOpacity = 1.0
            deltaOffset = -8.0
            withAnimation(.easeOut(duration: 0.45 * speedMultiplier)) {
                deltaOffset = -26.0
            }
            withAnimation(.easeOut(duration: 0.4 * speedMultiplier).delay(0.25 * speedMultiplier)) {
                deltaOpacity = 0.0
            }
        }
    }

    private var scorePlate: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Score")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(score)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .scaleEffect(scale)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Best")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(highScore)")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(lastEvent?.isNewHighScore == true ? Color.accentColor : Color.primary)
                }
            }

            if let bonus = lastEvent?.lineClearBonus, bonus > 0 {
                Text("Combo bonus +\(bonus)")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(glassGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
        )
        .frame(minWidth: 150, alignment: .leading)
    }

    private var deltaText: String? {
        guard let event = lastEvent, event.totalDelta != 0 else { return nil }
        let symbol = event.totalDelta > 0 ? "+" : ""
        return "\(symbol)\(event.totalDelta)"
    }

    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(UIColor.systemBackground).opacity(0.92),
                Color(UIColor.secondarySystemBackground).opacity(0.65)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func accentGradient(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(opacity),
                Color.accentColor.opacity(opacity * 0.4)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

#Preview("Score View") {
    VStack(spacing: 20) {
        ScoreView(score: 1280, highScore: 2000, lastEvent: ScoreEvent(
            placedCells: 5,
            linesCleared: 1,
            placementPoints: 5,
            lineClearBonus: 100,
            totalDelta: 105,
            newTotal: 1280,
            highScore: 2000,
            isNewHighScore: false
        ))
        .preferredColorScheme(.dark)
    }
    .padding()
    .background(Color.black.opacity(0.8))
}
