import SwiftUI

struct LevelPlayContainerView: View {
    @Environment(\.dismiss) private var dismiss

    private let levelID: Int
    private let repository: LevelsRepository
    private let progressStore: LevelProgressStore

    @State private var level: Level?
    @State private var loadFailed = false
    @State private var latestResult: LevelSessionResult?

    init(levelID: Int,
         repository: LevelsRepository = .shared,
         progressStore: LevelProgressStore = .shared) {
        self.levelID = levelID
        self.repository = repository
        self.progressStore = progressStore
    }

    var body: some View {
        ZStack {
            if let level {
                DragDropGameView(
                    gameMode: .classic,
                    levelConfiguration: LevelSessionConfiguration(
                        level: level,
                        onComplete: { result in latestResult = result },
                        onFailure: { _ in latestResult = nil },
                        onExitRequested: { dismiss() }
                    ),
                    onReturnHome: { dismiss() },
                    onReturnModeSelect: { dismiss() }
                )
            } else if loadFailed {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)

                    Text("Level unavailable")
                        .font(.headline)

                    Button("Back") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView("Loading level…")
                    .progressViewStyle(.circular)
            }
        }
        .onAppear(perform: loadLevel)
    }

    private func loadLevel() {
        guard level == nil else { return }
        if let loaded = repository.level(with: levelID) {
            level = loaded
        } else {
            loadFailed = true
        }
    }
}
