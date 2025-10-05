import SwiftUI

/// Displays the player's current score with smooth count-up animation.
struct ScoreView: View {
    let score: Int
    let lastEvent: ScoreEvent?
    let isHighlighted: Bool

    @State private var displayedScore: Int = 0
    @State private var scale: CGFloat = 1.0
    @State private var deltaOpacity: Double = 0.0
    @State private var deltaOffset: CGFloat = 4.0
    @State private var highlightScale: CGFloat = 1.0
    @State private var highlightGlow: Double = 0.0

    var body: some View {
        scoreStack
            .onAppear {
                scale = 1.0
                displayedScore = score
            }
            .onChange(of: score) { oldValue, newValue in
                animateScore()
                animateCountUp(from: oldValue, to: newValue)
            }
            .onChange(of: lastEvent?.newTotal) { _, _ in animateDeltaIfNeeded() }
            .onChange(of: isHighlighted) { _, newValue in
                if newValue {
                    animateHighlight()
                }
            }
    }

    private var scoreStack: some View {
        ZStack(alignment: .topTrailing) {
            Text("\(displayedScore)")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .scaleEffect(scale * highlightScale)
                .shadow(color: Color.accentColor.opacity(highlightGlow), radius: highlightGlow * 36, x: 0, y: 0)
                .accessibilityLabel("Current score \(score)")
                .contentTransition(.numericText())

            if let deltaText = deltaText {
                Text(deltaText)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(accentGradient(opacity: 0.18))
                            .overlay(
                                Capsule()
                                    .stroke(accentGradient(opacity: 0.4), lineWidth: 1)
                            )
                    )
                    .foregroundStyle(Color.accentColor)
                    .opacity(deltaOpacity)
                    .offset(y: deltaOffset)
            }
        }
        .frame(minWidth: 140)
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

    private func animateScore() {
        let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120
        let responseMultiplier: Double = isProMotion ? 0.7 : 1.0

        withAnimation(.spring(response: 0.35 * responseMultiplier, dampingFraction: 0.6)) {
            scale = 1.12
        }
        withAnimation(.spring(response: 0.5 * responseMultiplier, dampingFraction: 0.8).delay(0.12 * responseMultiplier)) {
            scale = 1.0
        }
    }

    private func animateCountUp(from oldValue: Int, to newValue: Int) {
        guard newValue != oldValue else { return }

        let difference = abs(newValue - oldValue)
        let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120

        // Calculate animation duration based on score difference
        let baseDuration: Double = min(0.5, Double(difference) / 1000.0)
        let duration = isProMotion ? baseDuration * 0.8 : baseDuration

        // Animate the count-up
        withAnimation(.easeOut(duration: duration)) {
            displayedScore = newValue
        }
    }

    private func animateDeltaIfNeeded() {
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

    private func animateHighlight() {
        let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120
        let response = isProMotion ? 0.24 : 0.3
        let recovery = isProMotion ? 0.42 : 0.5

        withAnimation(.spring(response: response, dampingFraction: 0.55)) {
            highlightScale = 1.18
            highlightGlow = 0.65
        }

        withAnimation(.spring(response: recovery, dampingFraction: 0.8).delay(response * 0.8)) {
            highlightScale = 1.0
            highlightGlow = 0.0
        }
    }
}

struct HighScoreBadge: View {
    let highScore: Int

    private let badgeGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.76, blue: 0.38),
            Color(red: 1.0, green: 0.53, blue: 0.24)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(badgeGradient)

            Text("\(highScore)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 1.0, green: 0.58, blue: 0.25))
        }
    }
}

#Preview("Score View") {
    VStack(spacing: 20) {
        HighScoreBadge(highScore: 2000)
        ScoreView(score: 1280, lastEvent: ScoreEvent(
            placedCells: 5,
            linesCleared: 1,
            placementPoints: 5,
            lineClearBonus: 100,
            totalDelta: 105,
            newTotal: 1280,
            highScore: 2000,
            isNewHighScore: false
        ), isHighlighted: true)
        .preferredColorScheme(.dark)
    }
    .padding()
    .background(Color.black.opacity(0.8))
}
