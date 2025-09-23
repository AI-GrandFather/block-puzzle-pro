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
        VStack(spacing: 12) {
            highScoreBanner
            scorePlate
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

    private var highScoreBanner: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(goldenGradient)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("HIGH SCORE")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(goldenGradient)
                Text("\(highScore)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(highScoreColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(highScoreColor.opacity(0.22), lineWidth: 1)
                            .padding(.vertical, -4)
                            .padding(.horizontal, -6)
                    )
            }

            Spacer()

            if lastEvent?.isNewHighScore == true {
                Text("NEW!")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(highScoreColor))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scorePlate: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 8) {
                Text("CURRENT SCORE")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.secondary)

                Text("\(score)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(scoreColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .scaleEffect(scale)
                    .accessibilityLabel("Current score \(score)")

                if let bonus = lastEvent?.lineClearBonus, bonus > 0 {
                    Text("Combo bonus +\(bonus)")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity)

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
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(glassGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 10)
        )
        .frame(minWidth: 200)
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

    private var highScoreColor: Color {
        Color(red: 0.97, green: 0.79, blue: 0.19)
    }

    private var scoreColor: Color {
        Color(red: 0.29, green: 0.54, blue: 0.96)
    }

    private var goldenGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.87, blue: 0.36),
                Color(red: 0.98, green: 0.76, blue: 0.18)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
