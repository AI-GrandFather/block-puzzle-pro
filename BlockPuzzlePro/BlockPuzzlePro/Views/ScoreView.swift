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
        VStack(spacing: 16) {
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
        HStack(spacing: 10) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(goldenGradient)
                .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 2)
                .accessibilityHidden(true)

            Text("HIGH SCORE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primary.opacity(0.55))

            Text("\(highScore)")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(highScoreFill)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            Capsule()
                                .stroke(highScoreStroke, lineWidth: 1)
                        )
                )
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

            Spacer(minLength: 12)

            if lastEvent?.isNewHighScore == true {
                Text("NEW!")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(goldenGradient))
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scorePlate: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .center, spacing: 8) {
                Text("\(score)")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(scoreFill)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .scaleEffect(scale)
                    .overlay(scoreOutline)
                    .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
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
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .frame(minWidth: 200)
    }

    private var deltaText: String? {
        guard let event = lastEvent, event.totalDelta != 0 else { return nil }
        let symbol = event.totalDelta > 0 ? "+" : ""
        return "\(symbol)\(event.totalDelta)"
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

    private var highScoreFill: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.60, green: 0.80, blue: 1.0),
                Color(red: 0.46, green: 0.69, blue: 0.99)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var highScoreStroke: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.58, blue: 0.95),
                Color(red: 0.67, green: 0.85, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var scoreFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.88, green: 0.93, blue: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var scoreOutline: some View {
        let offsets: [CGSize] = [
            .init(width: 1.4, height: 1.4),
            .init(width: -1.4, height: 1.4),
            .init(width: 1.4, height: -1.4),
            .init(width: -1.4, height: -1.4)
        ]

        return ZStack {
            ForEach(offsets.indices, id: \.self) { index in
                scoreOutlineGradient
                    .mask(
                        Text("\(score)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                    )
                    .offset(x: offsets[index].width, y: offsets[index].height)
            }
        }
        .opacity(0.45)
    }

    private var scoreOutlineGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.62, green: 0.76, blue: 1.0),
                Color.white
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
