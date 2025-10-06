import SwiftUI

struct PuzzlePlayContainerView: View {
    @Environment(\.dismiss) private var dismiss

    let puzzle: Puzzle
    let manager: DailyPuzzleManager

    init(puzzle: Puzzle, manager: DailyPuzzleManager = .shared) {
        self.puzzle = puzzle
        self.manager = manager
    }

    var body: some View {
        let level = manager.asLevel(for: puzzle)

        return DragDropGameView(
            gameMode: .classic,
            levelConfiguration: LevelSessionConfiguration(
                level: level,
                onComplete: { [manager, puzzle] result in
                    let elapsed: TimeInterval?
                    if let timeLimit = puzzle.timeLimit, let remaining = result.summary.timeRemaining {
                        elapsed = max(0, timeLimit - TimeInterval(remaining))
                    } else {
                        elapsed = nil
                    }
                    manager.markSolved(puzzle: puzzle, time: elapsed)
                },
                onFailure: { _ in },
                onExitRequested: { dismiss() }
            ),
            onReturnHome: { dismiss() },
            onReturnModeSelect: { dismiss() }
        )
        .onAppear {
            manager.recordAttempt(puzzle: puzzle)
        }
    }
}
