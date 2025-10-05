// FILE: ThemeManager.swift
// Legacy theme manager - DEPRECATED: Use AdvancedThemeManager instead
import Foundation
import SwiftUI
import SpriteKit
import UIKit

// NOTE: GameTheme enum moved to GameTheme.swift
// This file kept for backward compatibility only

@available(*, deprecated, message: "Use AdvancedThemeManager instead")
final class ThemeManager: ObservableObject {
    @MainActor static let shared = ThemeManager()

    @Published var currentTheme: GameTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedGameTheme")
            NotificationCenter.default.post(name: .gameThemeDidChange, object: currentTheme)
        }
    }

    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedGameTheme")
        self.currentTheme = GameTheme(rawValue: savedTheme ?? "") ?? .classicLight
    }

    func getBlockColor(index: Int = 0) -> Color {
        let colorScheme = currentTheme.blockColors[index % currentTheme.blockColors.count]
        return colorScheme.baseColor
    }
}

extension Notification.Name {
    static let gameThemeDidChange = Notification.Name("gameThemeDidChange")
}