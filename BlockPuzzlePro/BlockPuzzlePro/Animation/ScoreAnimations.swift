// ScoreAnimations.swift
// Animated score numbers and counter with visual feedback
// Features flying score numbers, rolling digits, and streak indicators

import Foundation
import SwiftUI
import Observation

// MARK: - Flying Score Number

struct FlyingScoreNumber: Identifiable {
    let id = UUID()
    let value: Int
    var position: CGPoint
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
    var color: Color

    var formattedValue: String {
        "+\(value)"
    }
}

// MARK: - Score Animation Manager

@MainActor
@Observable
final class ScoreAnimationManager {

    // MARK: - Singleton

    static let shared = ScoreAnimationManager()

    // MARK: - Properties

    private(set) var flyingNumbers: [FlyingScoreNumber] = []
    private(set) var currentScore: Int = 0
    private(set) var displayedScore: Int = 0
    private(set) var highScore: Int = 0

    // Streak tracking
    private(set) var currentStreak: Int = 0
    private(set) var streakEnergy: Double = 0.0
    private var streakTimer: Timer?

    // Ghost score (previous high score indicator)
    private(set) var showGhostScore: Bool = true

    // Animation state
    private var scoreRollTimer: Timer?
    private let rollDuration: TimeInterval = 0.3
    private var scoreRollStep: Int = 0

    // Persistence
    private let defaults = UserDefaults.standard
    private let highScoreKey = "high_score"

    // MARK: - Initialization

    private init() {
        // Load high score
        highScore = defaults.integer(forKey: highScoreKey)
    }

    // MARK: - Score Management

    /// Add score with flying number animation
    func addScore(_ points: Int, at position: CGPoint) {
        let previousScore = currentScore
        currentScore += points

        // Update high score
        if currentScore > highScore {
            highScore = currentScore
            saveHighScore()
        }

        // Create flying score number
        createFlyingNumber(points: points, at: position)

        // Animate score roll
        rollScore(from: previousScore, to: currentScore)

        // Update streak
        updateStreak()
    }

    private func createFlyingNumber(points: Int, at position: CGPoint) {
        // Color based on point value
        let color: Color
        switch points {
        case 0..<100:
            color = .white
        case 100..<500:
            color = Color(hex: "FFE66D") // Yellow
        case 500..<1000:
            color = Color(hex: "FFA07A") // Orange
        default:
            color = Color(hex: "FFD700") // Gold
        }

        let flyingNumber = FlyingScoreNumber(
            value: points,
            position: position,
            color: color
        )

        flyingNumbers.append(flyingNumber)

        // Animate flying number
        animateFlyingNumber(flyingNumber)
    }

    private func animateFlyingNumber(_ number: FlyingScoreNumber) {
        guard let index = flyingNumbers.firstIndex(where: { $0.id == number.id }) else { return }

        // Scale up then down
        withAnimation(.interpolatingSpring(stiffness: 400, damping: 15)) {
            flyingNumbers[index].scale = 1.5
        }

        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            flyingNumbers[index].scale = 1.0
        }

        // Move upward and fade
        withAnimation(.easeOut(duration: 0.6)) {
            flyingNumbers[index].position.y -= 80
            flyingNumbers[index].opacity = 0.0
        }

        // Remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.flyingNumbers.removeAll { $0.id == number.id }
        }
    }

    private func rollScore(from start: Int, to end: Int) {
        scoreRollTimer?.invalidate()

        let steps = 10
        let increment = (end - start) / steps
        scoreRollStep = 0

        scoreRollTimer = Timer.scheduledTimer(withTimeInterval: rollDuration / Double(steps), repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self else {
                    return
                }

                self.scoreRollStep += 1

                if self.scoreRollStep >= steps {
                    self.displayedScore = end
                    self.scoreRollTimer?.invalidate()
                } else {
                    self.displayedScore = start + (increment * self.scoreRollStep)
                }
            }
        }
    }

    // MARK: - Streak Management

    private func updateStreak() {
        currentStreak += 1
        streakEnergy = min(Double(currentStreak) / 10.0, 1.0)

        // Reset streak timer
        streakTimer?.invalidate()
        streakTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.resetStreak()
            }
        }
    }

    private func resetStreak() {
        withAnimation(.easeOut(duration: 0.5)) {
            currentStreak = 0
            streakEnergy = 0.0
        }
    }

    // MARK: - Persistence

    private func saveHighScore() {
        defaults.set(highScore, forKey: highScoreKey)
    }

    // MARK: - Utility

    func reset() {
        currentScore = 0
        displayedScore = 0
        flyingNumbers.removeAll()
        resetStreak()
        scoreRollTimer?.invalidate()
        streakTimer?.invalidate()
    }

    func setScore(_ score: Int) {
        currentScore = score
        displayedScore = score
    }
}

// MARK: - Flying Score Numbers View

struct FlyingScoreNumbersView: View {
    @State private var scoreManager = ScoreAnimationManager.shared

    var body: some View {
        ZStack {
            ForEach(scoreManager.flyingNumbers) { number in
                Text(number.formattedValue)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(number.color)
                    .shadow(color: number.color.opacity(0.5), radius: 8)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    .scaleEffect(number.scale)
                    .opacity(number.opacity)
                    .position(number.position)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Enhanced Score Display

struct EnhancedScoreDisplay: View {
    @State private var scoreManager = ScoreAnimationManager.shared
    @State private var themeManager = AdvancedThemeManager.shared

    let compact: Bool

    init(compact: Bool = false) {
        self.compact = compact
    }

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            // Score label
            if !compact {
                Text("SCORE")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(themeManager.currentTheme.textSecondary)
            }

            // Current score with rolling animation
            ZStack {
                // Ghost score (previous high)
                if scoreManager.showGhostScore && scoreManager.highScore > 0 {
                    Text(formatScore(scoreManager.highScore))
                        .font(compact ? .title3.monospacedDigit() : .largeTitle.monospacedDigit())
                        .fontWeight(.black)
                        .foregroundStyle(themeManager.currentTheme.textSecondary.opacity(0.3))
                        .offset(y: compact ? -15 : -25)
                }

                // Current score
                Text(formatScore(scoreManager.displayedScore))
                    .font(compact ? .title2.monospacedDigit() : .system(size: 48).monospacedDigit())
                    .fontWeight(.black)
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }

            // High score indicator
            if !compact && scoreManager.currentScore >= scoreManager.highScore && scoreManager.currentScore > 0 {
                Text("NEW RECORD!")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "FFD700"))
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(compact ? 12 : 20)
        .background(
            RoundedRectangle(cornerRadius: compact ? 12 : 16)
                .fill(themeManager.currentTheme.gridCellColor.opacity(0.8))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }

    private func formatScore(_ score: Int) -> String {
        String(format: "%06d", score)
    }
}

// MARK: - Combo Counter View

struct ComboCounterView: View {
    @State private var animationManager = LineClearAnimationManager.shared
    @State private var themeManager = AdvancedThemeManager.shared

    var body: some View {
        if animationManager.currentCombo > 1 {
            HStack(spacing: 8) {
                // Multiplier
                Text("\(animationManager.currentCombo)x")
                    .font(.system(size: 36 + CGFloat(min(animationManager.currentCombo, 20)) * 2, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: comboColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Label
                Text("COMBO")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(themeManager.currentTheme.textPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(themeManager.currentTheme.gridCellColor.opacity(0.9))
                    .shadow(color: comboGlowColor.opacity(0.6), radius: 12)
            )
            .scaleEffect(pulseScale)
            .transition(.scale.combined(with: .opacity))
            .onAppear {
                startPulseAnimation()
            }
        }
    }

    private var comboColors: [Color] {
        switch animationManager.currentCombo {
        case 2...4:
            return [.yellow, .orange]
        case 5...9:
            return [.orange, .red]
        default:
            return [.red, .purple, .blue]
        }
    }

    private var comboGlowColor: Color {
        switch animationManager.currentCombo {
        case 2...4:
            return .yellow
        case 5...9:
            return .orange
        default:
            return .red
        }
    }

    @State private var pulseScale: CGFloat = 1.0

    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }
    }
}

// MARK: - Streak Indicator View

struct StreakIndicatorView: View {
    @State private var scoreManager = ScoreAnimationManager.shared
    @State private var themeManager = AdvancedThemeManager.shared

    var body: some View {
        if scoreManager.currentStreak > 0 {
            HStack(spacing: 12) {
                // Flame icon
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(flameGradient)
                    .shadow(color: .orange.opacity(0.8), radius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(scoreManager.currentStreak) STREAK")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(themeManager.currentTheme.textPrimary)

                    // Energy bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.3))

                            Capsule()
                                .fill(flameGradient)
                                .frame(width: geometry.size.width * scoreManager.streakEnergy)
                        }
                    }
                    .frame(height: 4)
                }
                .frame(width: 100)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.gridCellColor.opacity(0.8))
                    .shadow(color: .orange.opacity(0.4), radius: 8)
            )
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    private var flameGradient: LinearGradient {
        LinearGradient(
            colors: [.red, .orange, .yellow],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
