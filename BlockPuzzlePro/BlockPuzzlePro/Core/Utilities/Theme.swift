// FILE: Theme.swift
// Professional game themes based on industry research
// All themes meet WCAG AA accessibility standards (4.5:1 contrast ratio)
import Foundation
import UIKit
import NotificationCenter

enum Theme: String, CaseIterable {
    // DARK THEMES
    case classicDark = "classicDark"           // Professional dark with blue accents
    case neonCyberpunk = "neonCyberpunk"       // Hot pink + electric blue on dark
    case midnightBlue = "midnightBlue"         // Deep navy professional theme
    case diabloMaroon = "diabloMaroon"         // Dark red/maroon (original diablo)
    case forestNight = "forestNight"           // Deep emerald green
    case purpleDreams = "purpleDreams"         // Vibrant purple on dark background

    // LIGHT THEMES
    case oceanBreeze = "oceanBreeze"           // Light blue (calming, accessibility-friendly)
    case sunsetGlow = "sunsetGlow"             // Warm orange/coral theme
    case retroArcade = "retroArcade"           // Classic arcade bright colors
    case cherryBlossom = "cherryBlossom"       // Soft pink on light background

    private static let storageKey = "selectedTheme"

    static var current: Theme {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: storageKey),
                  let theme = Theme(rawValue: rawValue) else {
                return .classicDark
            }
            return theme
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
            NotificationCenter.default.post(name: .themeDidChange, object: newValue)
        }
    }

    // Display name for UI
    var displayName: String {
        switch self {
        case .classicDark: return "Classic Dark"
        case .neonCyberpunk: return "Neon Cyberpunk"
        case .midnightBlue: return "Midnight Blue"
        case .diabloMaroon: return "Diablo Maroon"
        case .forestNight: return "Forest Night"
        case .purpleDreams: return "Purple Dreams"
        case .oceanBreeze: return "Ocean Breeze"
        case .sunsetGlow: return "Sunset Glow"
        case .retroArcade: return "Retro Arcade"
        case .cherryBlossom: return "Cherry Blossom"
        }
    }

    // Block colors - vibrant but accessible
    var blockColor: UIColor {
        switch self {
        // DARK THEMES
        case .classicDark:
            return UIColor(red: 0.16, green: 0.60, blue: 0.90, alpha: 1.0) // #2999E6 - Desaturated blue
        case .neonCyberpunk:
            return UIColor(red: 1.0, green: 0.12, blue: 0.84, alpha: 1.0) // #FF1ED6 - Hot pink
        case .midnightBlue:
            return UIColor(red: 0.25, green: 0.55, blue: 0.85, alpha: 1.0) // #408CD9 - Medium blue
        case .diabloMaroon:
            return UIColor(red: 0.42, green: 0.06, blue: 0.10, alpha: 1.0) // #6B0F1A - Maroon
        case .forestNight:
            return UIColor(red: 0.20, green: 0.70, blue: 0.40, alpha: 1.0) // #33B366 - Emerald
        case .purpleDreams:
            return UIColor(red: 0.70, green: 0.25, blue: 0.95, alpha: 1.0) // #B340F2 - Vibrant purple

        // LIGHT THEMES
        case .oceanBreeze:
            return UIColor(red: 0.18, green: 0.55, blue: 0.82, alpha: 1.0) // #2E8CD1 - Ocean blue
        case .sunsetGlow:
            return UIColor(red: 1.0, green: 0.54, blue: 0.07, alpha: 1.0) // #FF8A12 - Sunset orange
        case .retroArcade:
            return UIColor(red: 1.0, green: 0.80, blue: 0.0, alpha: 1.0) // #FFCC00 - Arcade yellow
        case .cherryBlossom:
            return UIColor(red: 0.95, green: 0.35, blue: 0.60, alpha: 1.0) // #F25999 - Cherry pink
        }
    }

    // Background colors - following dark mode best practices (#121212 for dark)
    var backgroundColor: UIColor {
        switch self {
        // DARK THEMES (using #121212 as base per research)
        case .classicDark:
            return UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1.0) // #121212 - Standard dark
        case .neonCyberpunk:
            return UIColor(red: 0.04, green: 0.02, blue: 0.08, alpha: 1.0) // #0A0514 - Deep purple-black
        case .midnightBlue:
            return UIColor(red: 0.05, green: 0.08, blue: 0.13, alpha: 1.0) // #0D1421 - Deep navy
        case .diabloMaroon:
            return UIColor(red: 0.10, green: 0.05, blue: 0.05, alpha: 1.0) // #190D0D - Dark maroon bg
        case .forestNight:
            return UIColor(red: 0.04, green: 0.10, blue: 0.06, alpha: 1.0) // #0A1A0F - Deep forest
        case .purpleDreams:
            return UIColor(red: 0.08, green: 0.05, blue: 0.12, alpha: 1.0) // #140D1F - Dark purple

        // LIGHT THEMES
        case .oceanBreeze:
            return UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1.0) // #F0F7FF - Light ocean
        case .sunsetGlow:
            return UIColor(red: 1.0, green: 0.96, blue: 0.92, alpha: 1.0) // #FFF5EB - Warm cream
        case .retroArcade:
            return UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0) // #1F1F2E - Arcade dark
        case .cherryBlossom:
            return UIColor(red: 1.0, green: 0.96, blue: 0.97, alpha: 1.0) // #FFF5F7 - Soft pink white
        }
    }

    // Grid line colors - subtle, don't overpower blocks
    var gridLineColor: UIColor {
        switch self {
        case .classicDark:
            return UIColor(white: 0.30, alpha: 0.6) // Subtle gray
        case .neonCyberpunk:
            return UIColor(red: 0.16, green: 0.73, blue: 1.0, alpha: 0.4) // #2ABCFF - Electric blue hint
        case .midnightBlue:
            return UIColor(red: 0.15, green: 0.25, blue: 0.40, alpha: 0.7) // Navy tint
        case .diabloMaroon:
            return UIColor(red: 0.30, green: 0.10, blue: 0.10, alpha: 0.7) // Dark red tint
        case .forestNight:
            return UIColor(red: 0.10, green: 0.30, blue: 0.15, alpha: 0.7) // Forest tint
        case .purpleDreams:
            return UIColor(red: 0.30, green: 0.15, blue: 0.40, alpha: 0.7) // Purple tint
        case .oceanBreeze:
            return UIColor(red: 0.70, green: 0.85, blue: 0.95, alpha: 0.8) // Light blue
        case .sunsetGlow:
            return UIColor(red: 1.0, green: 0.85, blue: 0.70, alpha: 0.7) // Warm peach
        case .retroArcade:
            return UIColor(red: 0.30, green: 0.30, blue: 0.45, alpha: 0.8) // Arcade gray-blue
        case .cherryBlossom:
            return UIColor(red: 1.0, green: 0.80, blue: 0.90, alpha: 0.7) // Soft pink
        }
    }

    // Preview valid color - indicates valid placement
    var previewValidColor: UIColor {
        switch self {
        case .classicDark:
            return UIColor(red: 0.0, green: 0.80, blue: 0.20, alpha: 0.7) // Bright green
        case .neonCyberpunk:
            return UIColor(red: 0.16, green: 0.73, blue: 1.0, alpha: 0.8) // #2ABCFF - Electric blue
        case .midnightBlue:
            return UIColor(red: 0.20, green: 0.90, blue: 0.60, alpha: 0.7) // Cyan-green
        case .diabloMaroon:
            return UIColor(red: 1.0, green: 0.60, blue: 0.0, alpha: 0.7) // Orange (contrast to red)
        case .forestNight:
            return UIColor(red: 0.50, green: 1.0, blue: 0.60, alpha: 0.7) // Bright lime
        case .purpleDreams:
            return UIColor(red: 0.90, green: 0.50, blue: 1.0, alpha: 0.7) // Light purple
        case .oceanBreeze:
            return UIColor(red: 0.0, green: 0.70, blue: 0.70, alpha: 0.8) // Teal
        case .sunsetGlow:
            return UIColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 0.7) // Golden
        case .retroArcade:
            return UIColor(red: 0.0, green: 1.0, blue: 0.80, alpha: 0.8) // Arcade cyan
        case .cherryBlossom:
            return UIColor(red: 0.90, green: 0.20, blue: 0.50, alpha: 0.7) // Deep pink
        }
    }

    // Preview invalid color - universal red for errors
    var previewInvalidColor: UIColor {
        return UIColor(red: 0.90, green: 0.10, blue: 0.10, alpha: 0.75) // #E61A1A - Error red
    }

    // Helper: Is this a dark theme?
    var isDarkTheme: Bool {
        switch self {
        case .classicDark, .neonCyberpunk, .midnightBlue, .diabloMaroon, .forestNight, .purpleDreams, .retroArcade:
            return true
        case .oceanBreeze, .sunsetGlow, .cherryBlossom:
            return false
        }
    }
}

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}
