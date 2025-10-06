import SwiftUI

struct DailyPuzzleHubView: View {
    @ObservedObject var manager: DailyPuzzleManager
    let onPlay: (Puzzle) -> Void

    @State private var now = Date()

    init(manager: DailyPuzzleManager = .shared, onPlay: @escaping (Puzzle) -> Void) {
        self.manager = manager
        self.onPlay = onPlay
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                puzzleCard(for: manager.todayPuzzle)

                archiveSection
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            ).ignoresSafeArea()
        )
        .navigationTitle("Daily Puzzle")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { manager.refreshIfNeeded() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fresh Challenge Every Day")
                .font(.system(size: 32, weight: .heavy, design: .rounded))

            Text("Solve curated puzzles with handcrafted setups and unique constraints. New puzzle unlocks at midnight.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func puzzleCard(for puzzle: Puzzle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(puzzle.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(puzzle.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                difficultyBadge(for: puzzle.difficulty)
            }

            metadataRow(for: puzzle)

            Button(action: { onPlay(puzzle) }) {
                Label("Play Today's Puzzle", systemImage: "play.fill")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            progressFooter(for: puzzle)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 12)
    }

    private func metadataRow(for puzzle: Puzzle) -> some View {
        let progress = manager.progress(for: puzzle)

        return HStack(spacing: 16) {
            Label(puzzle.category.displayName, systemImage: "puzzlepiece.extension")
                .font(.caption.bold())

            if let moveLimit = puzzle.moveLimit {
                Label("Moves: \(moveLimit)", systemImage: "figure.walk")
                    .font(.caption.bold())
            }

            if let timeLimit = puzzle.timeLimit {
                Label("Timer: \(timeString(timeLimit))", systemImage: "timer")
                    .font(.caption.bold())
            }

            Spacer()

            if progress.isSolved {
                Label("Solved", systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color.green)
            }
        }
        .foregroundStyle(Color.secondary)
    }

    private func progressFooter(for puzzle: Puzzle) -> some View {
        let progress = manager.progress(for: puzzle)

        return HStack {
            Label("Attempts: \(progress.attempts)", systemImage: "repeat")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.secondary)

            Spacer()

            if let bestTime = progress.bestTime {
                Label("Best: \(timeString(bestTime))", systemImage: "stopwatch")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private var archiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Archive")
                .font(.headline)

            ForEach(manager.archive) { puzzle in
                Button {
                    onPlay(puzzle)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(puzzle.id.formattedDate)
                                .font(.subheadline.bold())
                            Text(puzzle.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        difficultyBadge(for: puzzle.difficulty)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func difficultyBadge(for difficulty: PuzzleDifficulty) -> some View {
        Text(difficulty.rawValue.capitalized)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(color(for: difficulty).opacity(0.18))
            )
            .foregroundStyle(color(for: difficulty))
    }

    private func color(for difficulty: PuzzleDifficulty) -> Color {
        switch difficulty {
        case .easy: return Color.green
        case .medium: return Color.yellow
        case .hard: return Color.orange
        case .expert: return Color.red
        }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
