// FILE: ThemeManager.swift
import Foundation
import SpriteKit
import UIKit

enum GameTheme: String, CaseIterable {
    case classic = "classic"
    case diablo = "diablo"
    case ocean = "ocean"
    case sunset = "sunset"

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .diablo: return "Diablo"
        case .ocean: return "Ocean"
        case .sunset: return "Sunset"
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .classic:
            return UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        case .diablo:
            return UIColor(red: 0.42, green: 0.06, blue: 0.10, alpha: 1.0) // #6B0F1A
        case .ocean:
            return UIColor(red: 0.1, green: 0.3, blue: 0.5, alpha: 1.0)
        case .sunset:
            return UIColor(red: 0.4, green: 0.2, blue: 0.5, alpha: 1.0)
        }
    }

    var gridBackgroundColor: UIColor {
        switch self {
        case .classic:
            return UIColor(red: 0.2, green: 0.2, blue: 0.25, alpha: 1.0)
        case .diablo:
            return UIColor(red: 0.1, green: 0.05, blue: 0.05, alpha: 1.0)
        case .ocean:
            return UIColor(red: 0.05, green: 0.2, blue: 0.35, alpha: 1.0)
        case .sunset:
            return UIColor(red: 0.3, green: 0.15, blue: 0.4, alpha: 1.0)
        }
    }

    var emptyCellColor: UIColor {
        switch self {
        case .classic:
            return UIColor(red: 0.25, green: 0.25, blue: 0.3, alpha: 1.0)
        case .diablo:
            return UIColor(red: 0.15, green: 0.1, blue: 0.1, alpha: 1.0)
        case .ocean:
            return UIColor(red: 0.1, green: 0.25, blue: 0.4, alpha: 1.0)
        case .sunset:
            return UIColor(red: 0.35, green: 0.2, blue: 0.45, alpha: 1.0)
        }
    }

    var blockColors: [UIColor] {
        switch self {
        case .classic:
            return [
                UIColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1.0), // Red
                UIColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0), // Blue
                UIColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1.0), // Green
                UIColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1.0), // Yellow
                UIColor(red: 0.7, green: 0.3, blue: 0.9, alpha: 1.0), // Purple
                UIColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1.0)  // Orange
            ]
        case .diablo:
            // Single maroon color for all blocks as requested
            return [UIColor(red: 0.42, green: 0.06, blue: 0.10, alpha: 1.0)]
        case .ocean:
            return [
                UIColor(red: 0.2, green: 0.8, blue: 0.8, alpha: 1.0), // Cyan
                UIColor(red: 0.1, green: 0.6, blue: 0.9, alpha: 1.0), // Blue
                UIColor(red: 0.3, green: 0.9, blue: 0.6, alpha: 1.0), // Turquoise
                UIColor(red: 0.0, green: 0.7, blue: 0.8, alpha: 1.0), // Teal
                UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)  // Light Blue
            ]
        case .sunset:
            return [
                UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0), // Orange
                UIColor(red: 0.9, green: 0.3, blue: 0.4, alpha: 1.0), // Pink
                UIColor(red: 0.8, green: 0.2, blue: 0.6, alpha: 1.0), // Magenta
                UIColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0), // Gold
                UIColor(red: 0.7, green: 0.4, blue: 0.8, alpha: 1.0)  // Lavender
            ]
        }
    }

    var gridLineColor: UIColor {
        switch self {
        case .classic:
            return UIColor(white: 0.4, alpha: 0.8)
        case .diablo:
            return UIColor(red: 0.3, green: 0.1, blue: 0.1, alpha: 0.8)
        case .ocean:
            return UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        case .sunset:
            return UIColor(red: 0.5, green: 0.3, blue: 0.6, alpha: 0.8)
        }
    }

    var previewValidColor: UIColor {
        switch self {
        case .classic:
            return UIColor(red: 0.0, green: 0.7, blue: 0.0, alpha: 0.7)
        case .diablo:
            return UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 0.7)
        case .ocean:
            return UIColor(red: 0.0, green: 0.8, blue: 0.8, alpha: 0.7)
        case .sunset:
            return UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.7)
        }
    }

    var previewInvalidColor: UIColor {
        return UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 0.7)
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: GameTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedGameTheme")
            NotificationCenter.default.post(name: .gameThemeDidChange, object: currentTheme)
        }
    }

    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedGameTheme")
        self.currentTheme = GameTheme(rawValue: savedTheme ?? "") ?? .classic
    }

    func getBlockColor(index: Int = 0) -> UIColor {
        let colors = currentTheme.blockColors
        if colors.count == 1 {
            return colors[0] // For Diablo theme - single color
        }
        return colors[index % colors.count]
    }
}

extension Notification.Name {
    static let gameThemeDidChange = Notification.Name("gameThemeDidChange")
}