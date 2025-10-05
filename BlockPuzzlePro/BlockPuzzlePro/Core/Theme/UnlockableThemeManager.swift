import Foundation
import SwiftUI
import Combine

// MARK: - Theme Unlock Conditions

enum UnlockCondition: Codable, Equatable {
    case score(Int)
    case totalLinesCleared(Int)
    case perfectBoards(Int)
    case dailyChallengesCompleted(Int)
    case alwaysUnlocked

    var description: String {
        switch self {
        case .score(let target):
            return "Reach \(target) points"
        case .totalLinesCleared(let target):
            return "Clear \(target) total lines"
        case .perfectBoards(let target):
            return "Clear the board completely \(target) time\(target == 1 ? "" : "s")"
        case .dailyChallengesCompleted(let target):
            return "Complete \(target) daily challenge\(target == 1 ? "" : "s")"
        case .alwaysUnlocked:
            return "Default theme"
        }
    }

    var progressTarget: Int {
        switch self {
        case .score(let target): return target
        case .totalLinesCleared(let target): return target
        case .perfectBoards(let target): return target
        case .dailyChallengesCompleted(let target): return target
        case .alwaysUnlocked: return 0
        }
    }
}

// MARK: - Unlockable Theme

struct UnlockableTheme: Identifiable, Codable {
    let id: String
    let themeName: String
    let unlockCondition: UnlockCondition
    var isUnlocked: Bool

    init(id: String, themeName: String, unlockCondition: UnlockCondition, isUnlocked: Bool = false) {
        self.id = id
        self.themeName = themeName
        self.unlockCondition = unlockCondition

        // Auto-unlock if condition is .alwaysUnlocked
        self.isUnlocked = unlockCondition == .alwaysUnlocked ? true : isUnlocked
    }
}

// MARK: - Player Progress

struct PlayerProgress: Codable {
    var highScore: Int = 0
    var totalLinesCleared: Int = 0
    var perfectBoardsCleared: Int = 0
    var dailyChallengesCompleted: Int = 0

    mutating func update(score: Int = 0, linesCleared: Int = 0, boardCleared: Bool = false, dailyChallenge: Bool = false) {
        highScore = max(highScore, score)
        totalLinesCleared += linesCleared
        if boardCleared {
            perfectBoardsCleared += 1
        }
        if dailyChallenge {
            dailyChallengesCompleted += 1
        }
    }

    func checkProgress(for condition: UnlockCondition) -> Bool {
        switch condition {
        case .score(let target):
            return highScore >= target
        case .totalLinesCleared(let target):
            return totalLinesCleared >= target
        case .perfectBoards(let target):
            return perfectBoardsCleared >= target
        case .dailyChallengesCompleted(let target):
            return dailyChallengesCompleted >= target
        case .alwaysUnlocked:
            return true
        }
    }

    func currentProgress(for condition: UnlockCondition) -> Int {
        switch condition {
        case .score(_):
            return highScore
        case .totalLinesCleared(_):
            return totalLinesCleared
        case .perfectBoards(_):
            return perfectBoardsCleared
        case .dailyChallengesCompleted(_):
            return dailyChallengesCompleted
        case .alwaysUnlocked:
            return 1
        }
    }
}

// MARK: - Unlockable Theme Manager

@MainActor
final class UnlockableThemeManager: ObservableObject {

    // MARK: - Published Properties

    @Published var themes: [UnlockableTheme] = []
    @Published var playerProgress: PlayerProgress = PlayerProgress()
    @Published var newlyUnlockedThemes: [String] = []

    // MARK: - Private Properties

    private let themesKey = "unlockable_themes"
    private let progressKey = "player_progress"

    // MARK: - Initialization

    init() {
        setupDefaultThemes()
        loadProgress()
        checkUnlocks()
    }

    // MARK: - Theme Setup

    private func setupDefaultThemes() {
        themes = [
            UnlockableTheme(id: "default", themeName: "Classic", unlockCondition: .alwaysUnlocked, isUnlocked: true),
            UnlockableTheme(id: "ocean", themeName: "Ocean Breeze", unlockCondition: .score(1000)),
            UnlockableTheme(id: "sunset", themeName: "Sunset Glow", unlockCondition: .score(2500)),
            UnlockableTheme(id: "forest", themeName: "Forest Green", unlockCondition: .totalLinesCleared(50)),
            UnlockableTheme(id: "neon", themeName: "Neon Nights", unlockCondition: .totalLinesCleared(100)),
            UnlockableTheme(id: "royal", themeName: "Royal Purple", unlockCondition: .score(5000)),
            UnlockableTheme(id: "fire", themeName: "Fire Ember", unlockCondition: .perfectBoards(1)),
            UnlockableTheme(id: "ice", themeName: "Ice Crystal", unlockCondition: .perfectBoards(3)),
            UnlockableTheme(id: "gold", themeName: "Golden Hour", unlockCondition: .score(10000)),
            UnlockableTheme(id: "galaxy", themeName: "Galaxy Dream", unlockCondition: .dailyChallengesCompleted(5))
        ]

        loadThemeStates()
    }

    // MARK: - Progress Tracking

    func recordProgress(score: Int = 0, linesCleared: Int = 0, boardCleared: Bool = false, dailyChallenge: Bool = false) {
        playerProgress.update(
            score: score,
            linesCleared: linesCleared,
            boardCleared: boardCleared,
            dailyChallenge: dailyChallenge
        )

        saveProgress()
        checkUnlocks()
    }

    // MARK: - Unlock Checking

    private func checkUnlocks() {
        var newUnlocks: [String] = []

        for index in themes.indices {
            if !themes[index].isUnlocked {
                let condition = themes[index].unlockCondition
                if playerProgress.checkProgress(for: condition) {
                    themes[index].isUnlocked = true
                    newUnlocks.append(themes[index].themeName)
                }
            }
        }

        if !newUnlocks.isEmpty {
            newlyUnlockedThemes = newUnlocks
            saveThemeStates()
        }
    }

    func clearNewUnlocks() {
        newlyUnlockedThemes.removeAll()
    }

    // MARK: - Query Methods

    func isUnlocked(themeID: String) -> Bool {
        themes.first(where: { $0.id == themeID })?.isUnlocked ?? false
    }

    func progress(for themeID: String) -> (current: Int, target: Int) {
        guard let theme = themes.first(where: { $0.id == themeID }) else {
            return (0, 0)
        }

        let current = playerProgress.currentProgress(for: theme.unlockCondition)
        let target = theme.unlockCondition.progressTarget

        return (current, target)
    }

    var unlockedCount: Int {
        themes.filter { $0.isUnlocked }.count
    }

    var totalThemes: Int {
        themes.count
    }

    // MARK: - Persistence

    private func saveThemeStates() {
        do {
            let data = try JSONEncoder().encode(themes)
            UserDefaults.standard.set(data, forKey: themesKey)
        } catch {
            print("Failed to save theme states: \(error)")
        }
    }

    private func loadThemeStates() {
        guard let data = UserDefaults.standard.data(forKey: themesKey) else { return }

        do {
            let savedThemes = try JSONDecoder().decode([UnlockableTheme].self, from: data)

            // Merge saved states with default themes
            for savedTheme in savedThemes {
                if let index = themes.firstIndex(where: { $0.id == savedTheme.id }) {
                    themes[index].isUnlocked = savedTheme.isUnlocked
                }
            }
        } catch {
            print("Failed to load theme states: \(error)")
        }
    }

    private func saveProgress() {
        do {
            let data = try JSONEncoder().encode(playerProgress)
            UserDefaults.standard.set(data, forKey: progressKey)
        } catch {
            print("Failed to save player progress: \(error)")
        }
    }

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: progressKey) else { return }

        do {
            playerProgress = try JSONDecoder().decode(PlayerProgress.self, from: data)
        } catch {
            print("Failed to load player progress: \(error)")
        }
    }

    // MARK: - Reset

    func reset() {
        setupDefaultThemes()
        playerProgress = PlayerProgress()
        newlyUnlockedThemes.removeAll()
        saveThemeStates()
        saveProgress()
    }
}
