// AdvancedThemeManager.swift
// Comprehensive theme management with unlock progression and smooth transitions
// Uses Swift 6 Observation framework for reactive state management

import Foundation
import SwiftUI
import Observation

// MARK: - Theme Manager

@MainActor
@Observable
final class AdvancedThemeManager {

    // MARK: - Singleton

    static let shared = AdvancedThemeManager()

    // MARK: - Published Properties

    var currentTheme: GameTheme {
        didSet {
            saveCurrentTheme()
            NotificationCenter.default.post(
                name: .advancedThemeDidChange,
                object: currentTheme
            )
        }
    }

    var isTransitioning: Bool = false
    var transitionProgress: Double = 0.0

    // User's current level for unlock progression
    var userLevel: Int

    // Premium status
    var hasPremiumAccess: Bool

    // Unlocked themes
    private(set) var unlockedThemes: Set<GameTheme> = []

    // MARK: - Private Properties

    private let defaults = UserDefaults.standard
    private let currentThemeKey = "advanced_current_theme"
    private let unlockedThemesKey = "advanced_unlocked_themes"
    private let userLevelKey = "user_level"
    private let premiumStatusKey = "has_premium_access"

    // MARK: - Initialization

    private init() {
        // Load saved theme
        if let savedThemeRaw = defaults.string(forKey: currentThemeKey),
           let savedTheme = GameTheme(rawValue: savedThemeRaw) {
            self.currentTheme = savedTheme
        } else {
            self.currentTheme = .classicLight
        }

        // Load user level
        let savedLevel = defaults.integer(forKey: userLevelKey)
        self.userLevel = max(savedLevel, 1)

        // Load premium status
        self.hasPremiumAccess = defaults.bool(forKey: premiumStatusKey)

        // Load unlocked themes
        if let savedUnlocked = defaults.array(forKey: unlockedThemesKey) as? [String] {
            self.unlockedThemes = Set(savedUnlocked.compactMap { GameTheme(rawValue: $0) })
        }

        // Ensure at least classic light is unlocked
        if self.unlockedThemes.isEmpty {
            self.unlockedThemes.insert(.classicLight)
        }

        // Unlock themes based on current level
        updateUnlockedThemes()
    }

    // MARK: - Theme Management

    /// Check if a theme is unlocked
    func isUnlocked(_ theme: GameTheme) -> Bool {
        // Premium themes require premium access
        if theme.isPremium {
            return hasPremiumAccess
        }

        // Check if level is sufficient
        if userLevel >= theme.unlockLevel {
            return true
        }

        // Check if manually unlocked
        return unlockedThemes.contains(theme)
    }

    /// Switch to a new theme with animated transition
    func switchTheme(to newTheme: GameTheme, animated: Bool = true) {
        guard isUnlocked(newTheme) else {
            print("⚠️ Theme '\(newTheme.name)' is locked")
            return
        }

        guard currentTheme != newTheme else { return }

        if animated {
            performAnimatedTransition(to: newTheme)
        } else {
            currentTheme = newTheme
        }
    }

    /// Perform animated theme transition with cross-fade
    private func performAnimatedTransition(to newTheme: GameTheme) {
        isTransitioning = true
        transitionProgress = 0.0

        withAnimation(.easeInOut(duration: 0.5)) {
            transitionProgress = 1.0
        }

        // Change theme halfway through transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.currentTheme = newTheme
        }

        // Complete transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isTransitioning = false
            self?.transitionProgress = 0.0
        }
    }

    /// Unlock a specific theme (for IAP or rewards)
    func unlockTheme(_ theme: GameTheme) {
        unlockedThemes.insert(theme)
        saveUnlockedThemes()

        NotificationCenter.default.post(
            name: .advancedThemeUnlocked,
            object: theme
        )
    }

    /// Update unlocked themes based on user level
    private func updateUnlockedThemes() {
        let previousCount = unlockedThemes.count

        for theme in GameTheme.allCases where !theme.isPremium {
            if userLevel >= theme.unlockLevel {
                unlockedThemes.insert(theme)
            }
        }

        // If premium unlocked, add premium themes
        if hasPremiumAccess {
            for theme in GameTheme.allCases where theme.isPremium {
                unlockedThemes.insert(theme)
            }
        }

        if unlockedThemes.count > previousCount {
            saveUnlockedThemes()
        }
    }

    /// Check for newly unlocked themes and notify
    private func checkForNewlyUnlockedThemes() {
        let previouslyUnlocked = unlockedThemes
        updateUnlockedThemes()

        let newlyUnlocked = unlockedThemes.subtracting(previouslyUnlocked)
        for theme in newlyUnlocked {
            NotificationCenter.default.post(
                name: .advancedThemeUnlocked,
                object: theme
            )
        }
    }

    /// Get list of all available themes with unlock status
    func getAllThemes() -> [(theme: GameTheme, unlocked: Bool)] {
        GameTheme.allCases.map { theme in
            (theme: theme, unlocked: isUnlocked(theme))
        }
    }

    /// Get preview for a theme (even if locked)
    func getThemePreview(_ theme: GameTheme) -> some View {
        ThemePreviewView(theme: theme)
    }

    // MARK: - Premium Management

    /// Unlock all themes via premium purchase
    func unlockPremium() {
        hasPremiumAccess = true
        updateUnlockedThemes()
        savePremiumStatus()

        NotificationCenter.default.post(name: .advancedPremiumUnlocked, object: nil)
    }

    // MARK: - Persistence

    private func saveCurrentTheme() {
        defaults.set(currentTheme.rawValue, forKey: currentThemeKey)
    }

    private func saveUnlockedThemes() {
        let rawValues = unlockedThemes.map { $0.rawValue }
        defaults.set(rawValues, forKey: unlockedThemesKey)
    }

    private func saveUserLevel() {
        defaults.set(userLevel, forKey: userLevelKey)
    }

    private func savePremiumStatus() {
        defaults.set(hasPremiumAccess, forKey: premiumStatusKey)
    }

    // MARK: - Theme Properties Convenience

    /// Get a block color for a specific index in current theme
    func getBlockColor(at index: Int) -> BlockColorScheme {
        let colors = currentTheme.blockColors
        return colors[index % colors.count]
    }

    /// Get background gradient for current theme
    var backgroundGradient: LinearGradient {
        currentTheme.backgroundColor
    }

    /// Get grid colors for current theme
    var gridColors: (cell: Color, border: Color) {
        (currentTheme.gridCellColor, currentTheme.gridBorderColor)
    }

    /// Get text colors for current theme
    var textColors: (primary: Color, secondary: Color) {
        (currentTheme.textPrimary, currentTheme.textSecondary)
    }
}

// MARK: - Theme Preview View

struct ThemePreviewView: View {
    let theme: GameTheme

    var body: some View {
        ZStack {
            // Background
            theme.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Theme name
                Text(theme.name)
                    .font(.title2.bold())
                    .foregroundStyle(theme.textPrimary)

                // Sample grid
                HStack(spacing: 8) {
                    ForEach(0..<3) { col in
                        VStack(spacing: 8) {
                            ForEach(0..<3) { row in
                                let colorIndex = (col + row) % theme.blockColors.count
                                let colorScheme = theme.blockColors[colorIndex]

                                RoundedRectangle(cornerRadius: 8)
                                    .fill(colorScheme.baseColor)
                                    .frame(width: 40, height: 40)
                                    .shadow(
                                        color: colorScheme.glowColor ?? .clear,
                                        radius: colorScheme.glowRadius
                                    )
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.gridCellColor.opacity(0.3))
                        .stroke(theme.gridBorderColor, lineWidth: 2)
                )

                // Unlock info
                if theme.isPremium {
                    Text("Premium Theme")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                } else {
                    Text("Unlocks at Level \(theme.unlockLevel)")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .padding()
        }
        .frame(width: 200, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let advancedThemeDidChange = Notification.Name("advancedThemeDidChange")
    static let advancedThemeUnlocked = Notification.Name("advancedThemeUnlocked")
    static let advancedPremiumUnlocked = Notification.Name("advancedPremiumUnlocked")
}
