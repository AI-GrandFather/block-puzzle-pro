// EnhancedUIComponents.swift
// Enhanced UI components with theme support and smooth animations
// Includes piece tray, hold slot, power-up bar, and mode indicators

import SwiftUI
import Observation

// MARK: - Enhanced Piece Tray

struct EnhancedPieceTray: View {
    @State private var themeManager = AdvancedThemeManager.shared
    let pieces: [GamePiece?]
    let onPieceSelected: (Int) -> Void

    private let slotCount = 3

    var body: some View {
        HStack(spacing: 16) {
            ForEach(0..<slotCount, id: \.self) { index in
                PieceSlot(
                    piece: index < pieces.count ? pieces[index] : nil,
                    index: index,
                    theme: themeManager.currentTheme,
                    onTap: {
                        onPieceSelected(index)
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(themeManager.currentTheme.gridCellColor.opacity(0.5))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

struct PieceSlot: View {
    let piece: GamePiece?
    let index: Int
    let theme: GameTheme
    let onTap: () -> Void

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Slot background
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    theme.gridBorderColor,
                    style: StrokeStyle(lineWidth: 2, dash: piece == nil ? [5, 5] : [])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.gridCellColor.opacity(piece == nil ? 0.3 : 0.6))
                )
                .frame(width: 80, height: 80)
                .opacity(piece == nil ? 0.5 : 1.0)

            // Piece preview
            if let piece = piece {
                PiecePreview(piece: piece, colorScheme: theme.blockColors[index % theme.blockColors.count])
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isPulsing)
            }
        }
        .onTapGesture(perform: onTap)
        .onAppear {
            if piece != nil {
                isPulsing = true
            }
        }
    }
}

struct PiecePreview: View {
    let piece: GamePiece
    let colorScheme: BlockColorScheme

    var body: some View {
        // Simple block grid preview
        let grid = piece.shape
        let cellSize: CGFloat = 15

        VStack(spacing: 2) {
            ForEach(0..<grid.count, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        if grid[row][col] {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(colorScheme.baseColor)
                                .frame(width: cellSize, height: cellSize)
                                .shadow(color: colorScheme.glowColor ?? .clear, radius: colorScheme.glowRadius / 2)
                        } else {
                            Color.clear
                                .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }
}

// Temporary GamePiece model for preview
struct GamePiece {
    let shape: [[Bool]]
}

// MARK: - Enhanced Hold Slot

struct EnhancedHoldSlot: View {
    @State private var themeManager = AdvancedThemeManager.shared
    let heldPiece: GamePiece?
    let isAvailable: Bool
    let cooldownProgress: Double
    let onSwap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Hold label
            HStack {
                Image(systemName: "arrow.2.squarepath")
                    .font(.caption)
                Text("HOLD")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(themeManager.currentTheme.textSecondary)

            // Hold slot
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(themeManager.currentTheme.gridBorderColor, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.currentTheme.gridCellColor.opacity(0.6))
                    )
                    .frame(width: 80, height: 80)

                // Held piece
                if let piece = heldPiece {
                    PiecePreview(
                        piece: piece,
                        colorScheme: themeManager.currentTheme.blockColors[0]
                    )
                    .opacity(isAvailable ? 1.0 : 0.5)
                }

                // Cooldown overlay
                if !isAvailable {
                    Circle()
                        .trim(from: 0, to: cooldownProgress)
                        .stroke(
                            themeManager.currentTheme.textPrimary.opacity(0.5),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                }
            }
            .opacity(isAvailable ? 1.0 : 0.6)
            .onTapGesture {
                if isAvailable {
                    onSwap()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.currentTheme.gridCellColor.opacity(0.5))
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Power-Up Bar

struct PowerUpBar: View {
    @State private var themeManager = AdvancedThemeManager.shared
    let powerUps: [LegacyPowerUp]
    let onActivate: (LegacyPowerUp) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(powerUps) { powerUp in
                PowerUpButton(
                    powerUp: powerUp,
                    theme: themeManager.currentTheme,
                    onActivate: { onActivate(powerUp) }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(themeManager.currentTheme.gridCellColor.opacity(0.5))
                .shadow(color: .black.opacity(0.2), radius: 8)
        )
    }
}

struct PowerUpButton: View {
    let powerUp: LegacyPowerUp
    let theme: GameTheme
    let onActivate: () -> Void

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(theme.gridCellColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .strokeBorder(
                            powerUp.isAvailable ? theme.gridBorderColor : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                )

            // Icon
            Image(systemName: powerUp.iconName)
                .font(.title3)
                .foregroundStyle(powerUp.isAvailable ? theme.textPrimary : Color.gray.opacity(0.5))

            // Count badge
            if powerUp.count > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(powerUp.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Circle().fill(Color.red))
                            .offset(x: 8, y: 8)
                    }
                }
                .frame(width: 50, height: 50)
            }
        }
        .scaleEffect(powerUp.isAvailable && isPulsing ? 1.1 : 1.0)
        .animation(
            powerUp.isAvailable ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
            value: isPulsing
        )
        .opacity(powerUp.isAvailable ? 1.0 : 0.5)
        .onTapGesture {
            if powerUp.isAvailable {
                onActivate()
            }
        }
        .onAppear {
            if powerUp.isAvailable {
                isPulsing = true
            }
        }
    }
}

struct LegacyPowerUp: Identifiable {
    let id = UUID()
    let type: LegacyPowerUpType
    var count: Int
    var isAvailable: Bool

    var iconName: String {
        switch type {
        case .hammer: return "hammer.fill"
        case .bomb: return "burst.fill"
        case .shuffle: return "shuffle"
        case .undo: return "arrow.uturn.backward"
        }
    }
}

enum LegacyPowerUpType {
    case hammer
    case bomb
    case shuffle
    case undo
}

// MARK: - Mode Indicator Badge

struct ModeIndicatorBadge: View {
    let mode: GameModeType
    @State private var themeManager = AdvancedThemeManager.shared

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: mode.iconName)
                .font(.caption)

            Text(mode.displayName)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(mode.color)
                .shadow(color: mode.color.opacity(0.5), radius: 8)
        )
    }
}

enum GameModeType {
    case endless
    case timed
    case levels
    case puzzle
    case zen

    var displayName: String {
        switch self {
        case .endless: return "Endless"
        case .timed: return "Timed"
        case .levels: return "Levels"
        case .puzzle: return "Puzzle"
        case .zen: return "Zen"
        }
    }

    var iconName: String {
        switch self {
        case .endless: return "infinity"
        case .timed: return "clock.fill"
        case .levels: return "star.fill"
        case .puzzle: return "puzzlepiece.fill"
        case .zen: return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .endless: return Color(hex: "007AFF")
        case .timed: return Color(hex: "FF9500")
        case .levels: return Color(hex: "34C759")
        case .puzzle: return Color(hex: "AF52DE")
        case .zen: return Color(hex: "AC8EC1")
        }
    }
}

// MARK: - Theme Switcher Button

struct ThemeSwitcherButton: View {
    @State private var themeManager = AdvancedThemeManager.shared
    @State private var showingThemeSelector = false

    var body: some View {
        Button(action: { showingThemeSelector = true }) {
            HStack(spacing: 6) {
                Image(systemName: "paintpalette.fill")
                    .font(.caption)
                Text("Theme")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(themeManager.currentTheme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(themeManager.currentTheme.gridCellColor.opacity(0.8))
                    .shadow(color: .black.opacity(0.2), radius: 4)
            )
        }
        .sheet(isPresented: $showingThemeSelector) {
            ThemeSelectorView()
        }
    }
}

// MARK: - Theme Selector View

struct ThemeSelectorView: View {
    @State private var themeManager = AdvancedThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(GameTheme.allCases) { theme in
                        ThemeCard(theme: theme, isSelected: theme == themeManager.currentTheme)
                            .onTapGesture {
                                if themeManager.isUnlocked(theme) {
                                    themeManager.switchTheme(to: theme)
                                    dismiss()
                                }
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ThemeCard: View {
    let theme: GameTheme
    let isSelected: Bool
    @State private var themeManager = AdvancedThemeManager.shared

    var body: some View {
        VStack(spacing: 8) {
            // Preview
            themeManager.getThemePreview(theme)
                .frame(height: 150)

            // Lock indicator
            if !themeManager.isUnlocked(theme) {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                    Text(theme.isPremium ? "Premium" : "Level \(theme.unlockLevel)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 3)
        )
    }
}
