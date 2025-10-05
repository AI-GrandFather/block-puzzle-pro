// FILE: ThemeSettingsView.swift
import SwiftUI

struct ThemeSettingsView: View {
    @State private var themeManager = AdvancedThemeManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Choose Your Theme")
                        .font(.title2.weight(.bold))
                        .padding(.top)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(GameTheme.allCases, id: \.self) { theme in
                            ThemePreviewCard(
                                theme: theme,
                                isSelected: themeManager.currentTheme == theme,
                                isUnlocked: themeManager.isUnlocked(theme)
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    themeManager.switchTheme(to: theme)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ThemePreviewCard: View {
    let theme: GameTheme
    let isSelected: Bool
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Mini grid preview
                VStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { col in
                                Rectangle()
                                    .fill(getCellColor(row: row, col: col))
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
                .padding(8)
                .background(theme.gridCellColor)
                .cornerRadius(8)

                // Theme name and unlock status
                VStack(spacing: 4) {
                    Text(theme.name)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.primary)

                    if !isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                            Text(theme.isPremium ? "Premium" : "Level \(theme.unlockLevel)")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
            .opacity(isUnlocked ? 1.0 : 0.6)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.blue : Color.clear,
                        lineWidth: 3
                    )
            )
            .cornerRadius(12)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(
                color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isUnlocked)
    }

    private func getCellColor(row: Int, col: Int) -> Color {
        // Create a mini preview pattern
        let isBlockCell = (row == 1 && col >= 1 && col <= 2) ||
                         (row == 2 && col >= 1 && col <= 2)

        if isBlockCell {
            return theme.blockColors[0].baseColor
        } else {
            return theme.gridCellColor.opacity(0.5)
        }
    }
}

#Preview {
    ThemeSettingsView()
}