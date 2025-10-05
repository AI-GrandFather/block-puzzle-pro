// GameTheme.swift
// Comprehensive theme system with 7 distinct visual themes
// Implements exact specifications from design document
// SwiftUI 6 / iOS 26 compatible

import Foundation
import SwiftUI

// MARK: - Theme Protocol

/// Protocol defining all properties required for a game theme
protocol ThemeProtocol {
    var id: String { get }
    var name: String { get }
    var unlockLevel: Int { get }
    var isPremium: Bool { get }

    // Color schemes
    var backgroundColor: LinearGradient { get }
    var gridCellColor: Color { get }
    var gridBorderColor: Color { get }
    var blockColors: [BlockColorScheme] { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }

    // Visual effects
    var lineClearEffect: LineClearEffectType { get }
    var particleType: ParticleEffectType { get }
    var specialEffects: [SpecialEffectType] { get }
}

// MARK: - Block Color Scheme

/// Represents a complete color scheme for a block including highlights and glows
struct BlockColorScheme: Identifiable {
    let id = UUID()
    let baseColor: Color
    let highlightColor: Color?
    let glowColor: Color?
    let glowRadius: CGFloat
    let glowOpacity: Double

    init(
        baseColor: Color,
        highlightColor: Color? = nil,
        glowColor: Color? = nil,
        glowRadius: CGFloat = 0,
        glowOpacity: Double = 0
    ) {
        self.baseColor = baseColor
        self.highlightColor = highlightColor
        self.glowColor = glowColor
        self.glowRadius = glowRadius
        self.glowOpacity = glowOpacity
    }
}

// MARK: - Effect Types

enum LineClearEffectType {
    case flashPulse(color: Color, duration: Double)
    case electricArc
    case woodChips
    case crystalShatter
    case waterSplash
    case supernova
}

enum ParticleEffectType {
    case sparkles
    case electricSparks
    case woodChips
    case iceCrystals
    case waterDroplets
    case stardust
}

enum SpecialEffectType {
    case scanlines
    case gridPulse(duration: Double)
    case floatingParticles
    case backgroundAnimation
    case lightReflection
    case holographicShift
}

// MARK: - Game Theme Enum

enum GameTheme: String, CaseIterable, Identifiable {
    case classicLight = "classic_light"
    case darkMode = "dark_mode"
    case neonCyberpunk = "neon_cyberpunk"
    case woodenClassic = "wooden_classic"
    case crystalIce = "crystal_ice"
    case sunsetBeach = "sunset_beach"
    case spaceOdyssey = "space_odyssey"

    var id: String { rawValue }
}

// MARK: - Theme Implementations

extension GameTheme: ThemeProtocol {

    var name: String {
        switch self {
        case .classicLight: return "Classic Light"
        case .darkMode: return "Dark Mode"
        case .neonCyberpunk: return "Neon Cyberpunk"
        case .woodenClassic: return "Wooden Classic"
        case .crystalIce: return "Crystal Ice"
        case .sunsetBeach: return "Sunset Beach"
        case .spaceOdyssey: return "Space Odyssey"
        }
    }

    var unlockLevel: Int {
        switch self {
        case .classicLight: return 1
        case .darkMode: return 5
        case .neonCyberpunk: return 10
        case .woodenClassic: return 20
        case .crystalIce: return 30
        case .sunsetBeach: return 40
        case .spaceOdyssey: return 50
        }
    }

    var isPremium: Bool {
        self == .spaceOdyssey
    }

    // MARK: - Background Gradients

    var backgroundColor: LinearGradient {
        switch self {
        case .classicLight:
            return LinearGradient(
                colors: [
                    Color(hex: "F5F7FA"),
                    Color(hex: "E8EEF3")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .darkMode:
            return LinearGradient(
                colors: [
                    Color(hex: "0F0F0F"),
                    Color(hex: "1A1A1D")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .neonCyberpunk:
            return LinearGradient(
                colors: [
                    Color(hex: "0D0221"),
                    Color(hex: "1B0340"),
                    Color(hex: "2D0B5F")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .woodenClassic:
            return LinearGradient(
                colors: [
                    Color(hex: "E8D5C4"),
                    Color(hex: "D4B59E")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .crystalIce:
            return LinearGradient(
                colors: [
                    Color(hex: "E3F2FD"),
                    Color(hex: "BBDEFB")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .sunsetBeach:
            return LinearGradient(
                colors: [
                    Color(hex: "FF6B9D"),
                    Color(hex: "FFA07A"),
                    Color(hex: "FFE66D")
                ],
                startPoint: .top,
                endPoint: .bottom
            )

        case .spaceOdyssey:
            return LinearGradient(
                colors: [
                    Color(hex: "000000"),
                    Color(hex: "0A0A2E"),
                    Color(hex: "000000")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Grid Colors

    var gridCellColor: Color {
        switch self {
        case .classicLight: return Color(hex: "FFFFFF")
        case .darkMode: return Color(hex: "2C2C2E")
        case .neonCyberpunk: return Color(hex: "1A0B2E")
        case .woodenClassic: return Color(hex: "8B6F47")
        case .crystalIce: return Color(hex: "F0F8FF")
        case .sunsetBeach: return Color(hex: "FFE4B5")
        case .spaceOdyssey: return Color(hex: "0D0D1F")
        }
    }

    var gridBorderColor: Color {
        switch self {
        case .classicLight: return Color(hex: "D1D9E0")
        case .darkMode: return Color(hex: "3A3A3C")
        case .neonCyberpunk: return Color(hex: "00FFFF")
        case .woodenClassic: return Color(hex: "654321")
        case .crystalIce: return Color(hex: "81D4FA")
        case .sunsetBeach: return Color(hex: "20B2AA")
        case .spaceOdyssey: return Color(hex: "00FFFF")
        }
    }

    // MARK: - Block Colors

    var blockColors: [BlockColorScheme] {
        switch self {
        case .classicLight:
            return [
                BlockColorScheme(baseColor: Color(hex: "FF6B6B")),
                BlockColorScheme(baseColor: Color(hex: "4ECDC4")),
                BlockColorScheme(baseColor: Color(hex: "FFE66D")),
                BlockColorScheme(baseColor: Color(hex: "95E1D3")),
                BlockColorScheme(baseColor: Color(hex: "C3ABE1")),
                BlockColorScheme(baseColor: Color(hex: "FFA07A"))
            ]

        case .darkMode:
            return [
                BlockColorScheme(
                    baseColor: Color(hex: "FF3B3B"),
                    glowColor: Color(hex: "FF3B3B"),
                    glowRadius: 12,
                    glowOpacity: 0.6
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "00D9FF"),
                    glowColor: Color(hex: "00D9FF"),
                    glowRadius: 12,
                    glowOpacity: 0.6
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "FFD93D"),
                    glowColor: Color(hex: "FFD93D"),
                    glowRadius: 12,
                    glowOpacity: 0.6
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "6BCF7F"),
                    glowColor: Color(hex: "6BCF7F"),
                    glowRadius: 12,
                    glowOpacity: 0.6
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "B565D8"),
                    glowColor: Color(hex: "B565D8"),
                    glowRadius: 12,
                    glowOpacity: 0.6
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "FF8C42"),
                    glowColor: Color(hex: "FF8C42"),
                    glowRadius: 12,
                    glowOpacity: 0.6
                )
            ]

        case .neonCyberpunk:
            return [
                BlockColorScheme(
                    baseColor: Color(hex: "FF0080"),
                    glowColor: Color(hex: "FF0080"),
                    glowRadius: 16,
                    glowOpacity: 0.8
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "00F0FF"),
                    glowColor: Color(hex: "00F0FF"),
                    glowRadius: 16,
                    glowOpacity: 0.8
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "B026FF"),
                    glowColor: Color(hex: "B026FF"),
                    glowRadius: 16,
                    glowOpacity: 0.8
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "00FF88"),
                    glowColor: Color(hex: "00FF88"),
                    glowRadius: 16,
                    glowOpacity: 0.8
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "FFD700"),
                    glowColor: Color(hex: "FFD700"),
                    glowRadius: 16,
                    glowOpacity: 0.8
                )
            ]

        case .woodenClassic:
            return [
                BlockColorScheme(baseColor: Color(hex: "704214")), // Mahogany
                BlockColorScheme(baseColor: Color(hex: "D4A76A")), // Maple
                BlockColorScheme(baseColor: Color(hex: "5A3825")), // Walnut
                BlockColorScheme(baseColor: Color(hex: "C9795B")), // Cedar
                BlockColorScheme(baseColor: Color(hex: "9A2A2A")), // Cherry
                BlockColorScheme(baseColor: Color(hex: "E6B87D"))  // Pine
            ]

        case .crystalIce:
            return [
                BlockColorScheme(
                    baseColor: Color(hex: "FFFFFF"),
                    glowColor: Color(hex: "FFFFFF"),
                    glowRadius: 20,
                    glowOpacity: 0.8
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "2196F3"),
                    glowColor: Color(hex: "2196F3"),
                    glowRadius: 16,
                    glowOpacity: 0.7
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "00BCD4"),
                    glowColor: Color(hex: "00BCD4"),
                    glowRadius: 16,
                    glowOpacity: 0.7
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "9C27B0"),
                    glowColor: Color(hex: "9C27B0"),
                    glowRadius: 16,
                    glowOpacity: 0.7
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "009688"),
                    glowColor: Color(hex: "009688"),
                    glowRadius: 16,
                    glowOpacity: 0.7
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "FFC107"),
                    glowColor: Color(hex: "FFC107"),
                    glowRadius: 16,
                    glowOpacity: 0.7
                )
            ]

        case .sunsetBeach:
            return [
                BlockColorScheme(
                    baseColor: Color(hex: "FF7F50"),
                    glowColor: Color(hex: "FF7F50"),
                    glowRadius: 12,
                    glowOpacity: 0.5
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "1E90FF"),
                    glowColor: Color(hex: "1E90FF"),
                    glowRadius: 12,
                    glowOpacity: 0.5
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "32CD32"),
                    glowColor: Color(hex: "32CD32"),
                    glowRadius: 12,
                    glowOpacity: 0.5
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "FFD700"),
                    glowColor: Color(hex: "FFD700"),
                    glowRadius: 14,
                    glowOpacity: 0.6
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "FF1493"),
                    glowColor: Color(hex: "FF1493"),
                    glowRadius: 12,
                    glowOpacity: 0.5
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "F4A460"),
                    glowColor: Color(hex: "F4A460"),
                    glowRadius: 10,
                    glowOpacity: 0.4
                )
            ]

        case .spaceOdyssey:
            return [
                BlockColorScheme(
                    baseColor: Color(hex: "FF0000"),
                    glowColor: Color(hex: "FF0000"),
                    glowRadius: 18,
                    glowOpacity: 0.9
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "4169E1"),
                    glowColor: Color(hex: "4169E1"),
                    glowRadius: 18,
                    glowOpacity: 0.9
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "00FF00"),
                    glowColor: Color(hex: "00FF00"),
                    glowRadius: 18,
                    glowOpacity: 0.9
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "FFD700"),
                    glowColor: Color(hex: "FFD700"),
                    glowRadius: 20,
                    glowOpacity: 1.0
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "8A2BE2"),
                    glowColor: Color(hex: "8A2BE2"),
                    glowRadius: 16,
                    glowOpacity: 0.9
                ),
                BlockColorScheme(
                    baseColor: Color(hex: "696969"),
                    glowColor: Color(hex: "696969"),
                    glowRadius: 12,
                    glowOpacity: 0.7
                )
            ]
        }
    }

    // MARK: - Text Colors

    var textPrimary: Color {
        switch self {
        case .classicLight: return Color(hex: "2C3E50")
        case .darkMode: return Color(hex: "FFFFFF")
        case .neonCyberpunk: return Color(hex: "00FFFF")
        case .woodenClassic: return Color(hex: "3E2723")
        case .crystalIce: return Color(hex: "01579B")
        case .sunsetBeach: return Color(hex: "8B4513")
        case .spaceOdyssey: return Color(hex: "00FFFF")
        }
    }

    var textSecondary: Color {
        switch self {
        case .classicLight: return Color(hex: "7F8C8D")
        case .darkMode: return Color(hex: "A0A0A0")
        case .neonCyberpunk: return Color(hex: "B026FF")
        case .woodenClassic: return Color(hex: "6D4C41")
        case .crystalIce: return Color(hex: "0277BD")
        case .sunsetBeach: return Color(hex: "CD853F")
        case .spaceOdyssey: return Color(hex: "FF00FF")
        }
    }

    // MARK: - Visual Effects

    var lineClearEffect: LineClearEffectType {
        switch self {
        case .classicLight:
            return .flashPulse(color: .white, duration: 0.3)
        case .darkMode:
            return .flashPulse(color: Color(hex: "00D9FF"), duration: 0.3)
        case .neonCyberpunk:
            return .electricArc
        case .woodenClassic:
            return .woodChips
        case .crystalIce:
            return .crystalShatter
        case .sunsetBeach:
            return .waterSplash
        case .spaceOdyssey:
            return .supernova
        }
    }

    var particleType: ParticleEffectType {
        switch self {
        case .classicLight, .darkMode:
            return .sparkles
        case .neonCyberpunk:
            return .electricSparks
        case .woodenClassic:
            return .woodChips
        case .crystalIce:
            return .iceCrystals
        case .sunsetBeach:
            return .waterDroplets
        case .spaceOdyssey:
            return .stardust
        }
    }

    var specialEffects: [SpecialEffectType] {
        switch self {
        case .classicLight:
            return []
        case .darkMode:
            return [.gridPulse(duration: 3.0)]
        case .neonCyberpunk:
            return [
                .scanlines,
                .floatingParticles,
                .gridPulse(duration: 2.0),
                .holographicShift
            ]
        case .woodenClassic:
            return [.lightReflection]
        case .crystalIce:
            return [
                .floatingParticles,
                .lightReflection
            ]
        case .sunsetBeach:
            return [
                .backgroundAnimation,
                .lightReflection
            ]
        case .spaceOdyssey:
            return [
                .floatingParticles,
                .backgroundAnimation
            ]
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
