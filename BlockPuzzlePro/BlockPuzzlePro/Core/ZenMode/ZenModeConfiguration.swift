import Foundation
import SwiftUI

// MARK: - Zen Mode Configuration

/// Configuration for Zen Mode - No pressure, no failure, pure relaxation
struct ZenModeConfiguration {
    // Core zen principles
    let enableGameOver: Bool = false
    let enableTimer: Bool = false
    let showScore: Bool = false  // Score tracked but not prominently displayed
    let enableLeaderboards: Bool = false
    let unlimitedUndo: Bool = true
    let boardAssistance: Bool = true  // Auto-clear when board gets too full
    let showPiecePreview: Bool = true  // Show next 3 pieces
    let breathingGuide: Bool = false   // Optional breathing exercise overlay

    // Animation settings - 30% slower for calmness
    let animationSpeedMultiplier: Double = 1.3

    // Visual settings
    let useZenColorPalette: Bool = true
    let showGridLines: Bool = true
    let dimmedLighting: Bool = false  // Auto-adjust based on time of day

    // Audio settings
    let ambientMusicEnabled: Bool = true
    let zenSoundEffects: Bool = true  // Softer, more calming sounds

    // Session settings
    let meditationTimerEnabled: Bool = false
    let sessionDurationMinutes: Int = 0  // 0 = infinite

    static let `default` = ZenModeConfiguration()
}

// MARK: - Zen Color Palette

/// Calming color palette for Zen Mode
/// Research-based: Soft blues, pastels, earthy tones for relaxation
struct ZenColorPalette {
    // Background gradients - soft blue-gray tones
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.94, green: 0.96, blue: 0.97),  // #F0F4F8 - Soft blue-gray
            Color(red: 0.90, green: 0.95, blue: 0.96)   // #E6F1F5 - Lighter blue-gray
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Grid colors - subtle, low contrast
    static let gridCell = Color.white.opacity(0.6)
    static let gridBorder = Color(red: 0.82, green: 0.88, blue: 0.91)  // #D0E0E8

    // Block colors - desaturated, soft, muted pastels
    // Based on meditation app research: peach, lavender, mint, sage
    static let blockColors: [Color] = [
        Color(red: 0.79, green: 0.89, blue: 0.79),  // #C9E4CA - Soft mint
        Color(red: 0.76, green: 0.83, blue: 1.0),   // #C1D3FE - Soft periwinkle
        Color(red: 1.0, green: 0.90, blue: 0.80),   // #FFE6CC - Soft peach
        Color(red: 0.91, green: 0.77, blue: 0.83),  // #E8C4D4 - Soft rose
        Color(red: 0.83, green: 0.89, blue: 0.74),  // #D4E4BC - Soft sage
        Color(red: 0.94, green: 0.89, blue: 0.83)   // #F0E2D4 - Soft beige
    ]

    // UI Text - gentle, readable
    static let textPrimary = Color(red: 0.35, green: 0.42, blue: 0.49)    // #5A6C7D
    static let textSecondary = Color(red: 0.54, green: 0.61, blue: 0.68)  // #8A9BAD

    // Accent colors for interactive elements
    static let accentCalm = Color(red: 0.53, green: 0.76, blue: 0.89)  // #87C2E3 - Calm blue
    static let accentWarm = Color(red: 0.96, green: 0.87, blue: 0.70)  // #F5DEB3 - Warm beige
}

// MARK: - Meditation Duration

enum MeditationDuration: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case twenty = 20
    case thirty = 30
    case infinite = 0  // No time limit

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .infinite: return "No Time Limit"
        default: return "\(rawValue) Minutes"
        }
    }

    var childFriendlyName: String {
        switch self {
        case .five: return "Quick Relax (5 min)"
        case .ten: return "Short Break (10 min)"
        case .fifteen: return "Nice Rest (15 min)"
        case .twenty: return "Long Chill (20 min)"
        case .thirty: return "Deep Calm (30 min)"
        case .infinite: return "Play Forever!"
        }
    }

    var seconds: TimeInterval {
        return TimeInterval(rawValue * 60)
    }
}

// MARK: - Zen Audio Theme

enum ZenAudioTheme: String, CaseIterable, Identifiable {
    case rain = "gentle_rain"
    case ocean = "ocean_waves"
    case forest = "forest_birds"
    case windChimes = "wind_chimes"
    case singingBowls = "singing_bowls"
    case whiteNoise = "white_noise"
    case silence = "silence"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rain: return "🌧️ Gentle Rain"
        case .ocean: return "🌊 Ocean Waves"
        case .forest: return "🌲 Forest Birds"
        case .windChimes: return "🎐 Wind Chimes"
        case .singingBowls: return "🔔 Singing Bowls"
        case .whiteNoise: return "💭 White Noise"
        case .silence: return "🤫 Silence"
        }
    }

    var audioFileName: String? {
        return self == .silence ? nil : "zen_\(rawValue)"
    }
}

// MARK: - Ambient Lighting

enum AmbientLighting: String, CaseIterable, Identifiable {
    case auto = "auto"
    case day = "day"
    case evening = "evening"
    case night = "night"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto (Based on time)"
        case .day: return "☀️ Bright (Day)"
        case .evening: return "🌅 Dimmed (Evening)"
        case .night: return "🌙 Very Dim (Night)"
        }
    }

    var brightness: Double {
        switch self {
        case .auto:
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 6 && hour < 18 {
                return 1.0  // Day
            } else if hour >= 18 && hour < 22 {
                return 0.7  // Evening
            } else {
                return 0.5  // Night
            }
        case .day: return 1.0
        case .evening: return 0.7
        case .night: return 0.5
        }
    }

    var colorTemperature: Color {
        switch self {
        case .auto, .day:
            return .white
        case .evening:
            return Color(red: 1.0, green: 0.97, blue: 0.88)  // #FFF8E1 - Warm white
        case .night:
            return Color(red: 1.0, green: 0.91, blue: 0.80)  // #FFE8CC - Warmer, amber tint
        }
    }
}
