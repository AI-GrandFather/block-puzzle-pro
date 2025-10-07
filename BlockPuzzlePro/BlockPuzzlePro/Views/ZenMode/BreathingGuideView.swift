import SwiftUI

// MARK: - Breathing Phase

enum BreathingPhase {
    case inhale
    case hold
    case exhale
    case rest

    var duration: Double {
        switch self {
        case .inhale: return 4.0
        case .hold: return 4.0
        case .exhale: return 4.0
        case .rest: return 2.0
        }
    }

    var displayText: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        case .rest: return "Rest"
        }
    }

    var childFriendlyText: String {
        switch self {
        case .inhale: return "🌬️ Breathe In"
        case .hold: return "⏸️ Hold It"
        case .exhale: return "💨 Breathe Out"
        case .rest: return "😌 Relax"
        }
    }

    var next: BreathingPhase {
        switch self {
        case .inhale: return .hold
        case .hold: return .exhale
        case .exhale: return .rest
        case .rest: return .inhale
        }
    }
}

// MARK: - Breathing Guide View

/// Animated breathing guide overlay for meditation
/// Research-based: Apple Watch breathing animation style
struct BreathingGuideView: View {
    @State private var currentPhase: BreathingPhase = .inhale
    @State private var progress: Double = 0.0
    @State private var circleScale: CGFloat = 0.3
    @State private var petalRotation: Double = 0
    @State private var opacity: Double = 0.8

    let position: BreathingPosition
    let useChildFriendlyText: Bool

    enum BreathingPosition {
        case top, center, bottom
    }

    var body: some View {
        VStack(spacing: 20) {
            // Animated breathing circle
            ZStack {
                // Outer petals (6 petals rotating)
                ForEach(0..<6) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    ZenColorPalette.accentCalm.opacity(0.6),
                                    ZenColorPalette.accentWarm.opacity(0.4)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60 * circleScale, height: 60 * circleScale)
                        .offset(y: -40 * circleScale)
                        .rotationEffect(.degrees(Double(index) * 60 + petalRotation))
                }

                // Center circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ZenColorPalette.accentCalm,
                                ZenColorPalette.accentWarm
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120 * circleScale, height: 120 * circleScale)
                    .shadow(color: ZenColorPalette.accentCalm.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .frame(width: 200, height: 200)

            // Phase text
            Text(useChildFriendlyText ? currentPhase.childFriendlyText : currentPhase.displayText)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundStyle(ZenColorPalette.textPrimary)

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(progress >= Double(index + 1) / 4.0 ? ZenColorPalette.accentCalm : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(opacity)
        .onAppear {
            startBreathingCycle()
        }
    }

    // MARK: - Animation Logic

    private func startBreathingCycle() {
        animateCurrentPhase()
    }

    private func animateCurrentPhase() {
        let duration = currentPhase.duration
        progress = 0.0

        // Animate based on current phase
        switch currentPhase {
        case .inhale:
            withAnimation(.easeInOut(duration: duration)) {
                circleScale = 1.0
                petalRotation = 60
                progress = 0.25
            }
        case .hold:
            withAnimation(.easeInOut(duration: duration)) {
                petalRotation = 120
                progress = 0.5
            }
        case .exhale:
            withAnimation(.easeInOut(duration: duration)) {
                circleScale = 0.3
                petalRotation = 180
                progress = 0.75
            }
        case .rest:
            withAnimation(.easeInOut(duration: duration)) {
                petalRotation = 240
                progress = 1.0
            }
        }

        // Move to next phase after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            currentPhase = currentPhase.next
            animateCurrentPhase()
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        ZenColorPalette.backgroundGradient
            .ignoresSafeArea()

        BreathingGuideView(position: .center, useChildFriendlyText: true)
    }
}
