import Foundation

struct LevelSessionConfiguration {
    let level: Level
    let onComplete: (LevelSessionResult) -> Void
    let onFailure: (LevelFailureReason) -> Void
    let onExitRequested: () -> Void

    init(level: Level,
         onComplete: @escaping (LevelSessionResult) -> Void,
         onFailure: @escaping (LevelFailureReason) -> Void,
         onExitRequested: @escaping () -> Void) {
        self.level = level
        self.onComplete = onComplete
        self.onFailure = onFailure
        self.onExitRequested = onExitRequested
    }
}
