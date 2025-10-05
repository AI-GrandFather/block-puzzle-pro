import SwiftUI

// MARK: - Daily Challenges View

struct DailyChallengesView: View {

    @ObservedObject var manager: DailyChallengeManager
    @ObservedObject var powerUpManager: PowerUpManager

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        header

                        // Challenges
                        ForEach(manager.dailyChallenges) { challenge in
                            ChallengeCard(
                                challenge: challenge,
                                onClaim: {
                                    claimReward(for: challenge)
                                }
                            )
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - View Components

    private var backgroundColor: some View {
        LinearGradient(
            colors: [
                Color(UIColor.systemBackground),
                Color(UIColor.systemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Daily Challenges")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text("Complete challenges to earn rewards")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Time remaining
            if let nextRefresh = nextRefreshTime() {
                Text("Refreshes in \(nextRefresh)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Helpers

    private func nextRefreshTime() -> String? {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else { return nil }
        guard let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else { return nil }

        let components = calendar.dateComponents([.hour, .minute], from: Date(), to: midnight)
        guard let hours = components.hour, let minutes = components.minute else { return nil }

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func claimReward(for challenge: DailyChallenge) {
        var score = 0
        if let reward = manager.claimReward(for: challenge.id, powerUpManager: powerUpManager, scoreTracker: &score) {
            // TODO: Show reward animation
            print("Claimed: \(reward.powerUps) power-ups, \(reward.points) points")
        }
    }
}

// MARK: - Challenge Card

private struct ChallengeCard: View {

    let challenge: DailyChallenge
    let onClaim: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: challenge.type.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(difficultyColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(difficultyColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(challenge.type.displayName)
                        .font(.headline)

                    Text(difficultyText)
                        .font(.caption)
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(difficultyColor.opacity(0.15))
                        )
                }

                Spacer()

                if challenge.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }

            // Description
            Text(challenge.description)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(challenge.currentProgress) / \(challenge.targetValue)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(challenge.progressPercentage * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(difficultyColor)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))

                        Capsule()
                            .fill(difficultyGradient)
                            .frame(width: geometry.size.width * challenge.progressPercentage)
                    }
                }
                .frame(height: 8)
            }

            // Rewards
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rewards")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        // Power-ups
                        ForEach(Array(challenge.reward.powerUps.keys), id: \.self) { powerUp in
                            if let count = challenge.reward.powerUps[powerUp] {
                                HStack(spacing: 4) {
                                    Image(systemName: powerUp.iconName)
                                    Text("×\(count)")
                                        .font(.caption.bold())
                                }
                                .foregroundColor(.blue)
                            }
                        }

                        // Points
                        if challenge.reward.points > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                Text("\(challenge.reward.points)")
                                    .font(.caption.bold())
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }

                Spacer()

                if challenge.isCompleted {
                    Button(action: onClaim) {
                        Text("Claim")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBackground)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Helpers

    private var difficultyColor: Color {
        switch challenge.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    private var difficultyGradient: LinearGradient {
        LinearGradient(
            colors: [difficultyColor, difficultyColor.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var difficultyText: String {
        challenge.difficulty.rawValue.capitalized
    }

    private var cardBackground: Color {
        if colorScheme == .dark {
            return Color(UIColor.systemGray6)
        } else {
            return Color.white
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var manager = DailyChallengeManager()
    @Previewable @State var powerUpManager = PowerUpManager()

    DailyChallengesView(
        manager: manager,
        powerUpManager: powerUpManager
    )
}
