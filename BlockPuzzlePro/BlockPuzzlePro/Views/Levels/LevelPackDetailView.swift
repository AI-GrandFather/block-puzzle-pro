import SwiftUI

struct LevelPackDetailView: View {
    let pack: LevelPack
    @ObservedObject var progressStore: LevelProgressStore
    let onSelectLevel: (Level) -> Void

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 120), spacing: 16)]
    }

    private var earnedStars: Int {
        progressStore.starsEarned(in: pack)
    }

    private var totalStars: Int {
        pack.levels.count * 3
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.22), Color(red: 0.13, green: 0.18, blue: 0.34)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    progressSummary
                    levelGrid
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle(pack.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(pack.subtitle, systemImage: pack.visual.iconName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.75))
            Text("Levels \(pack.levels.count)")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
        }
    }

    private var progressSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProgressView(value: Double(earnedStars), total: Double(totalStars))
                .progressViewStyle(.linear)
                .tint(color(from: pack.visual.primaryHex))

            HStack {
                Label("\(earnedStars)/\(totalStars) Stars", systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color(from: pack.visual.primaryHex))
                Spacer()
                Text("\(progressStore.completedLevels(in: pack))/\(pack.levels.count) Levels")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
        }
    }

    private var levelGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(pack.levels) { level in
                LevelTileView(
                    level: level,
                    progress: progressStore.progress(for: level.id),
                    isUnlocked: progressStore.isLevelUnlocked(level)
                ) {
                    onSelectLevel(level)
                }
            }
        }
    }
}

private struct LevelTileView: View {
    let level: Level
    let progress: LevelProgress
    let isUnlocked: Bool
    let action: () -> Void

    private var title: String { "Level \(level.indexInPack + 1)" }

    private var subtitle: String {
        level.objective.type.localizedSummary(target: level.objective.targetValue)
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(isUnlocked ? Color.white : Color.white.opacity(0.6))
                    Spacer()
                    if progress.bestStars > 0 {
                        starIcons
                    }
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineLimit(2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1.0 : 0.45)
    }

    private var starIcons: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < progress.bestStars ? "star.fill" : "star")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(index < progress.bestStars ? Color.yellow : Color.white.opacity(0.25))
            }
        }
    }
}

private extension LevelObjectiveType {
    func localizedSummary(target: Int) -> String {
        switch self {
        case .reachScore: return "Score \(target) points"
        case .clearLines: return "Clear \(target) lines"
        case .createPattern: return "Complete the featured pattern"
        case .surviveTime: return "Survive for \(target) seconds"
        case .clearAllBlocks: return "Clear the board"
        case .clearSpecificColor: return "Remove \(target) blocks of the target color"
        case .achieveCombo: return "Reach a \(target)x combo"
        case .perfectClear: return "Earn \(target) perfect clears"
        case .useOnlyPieces: return "Use only the provided pieces"
        case .clearWithMoves: return "Win within \(target) moves"
        }
    }
}

private func color(from hex: String) -> Color {
    Color(UIColor(hex: hex))
}
