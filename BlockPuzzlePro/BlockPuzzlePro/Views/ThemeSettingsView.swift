// FILE: ThemeSettingsView.swift
import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
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
                                isSelected: themeManager.currentTheme == theme
                            ) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    themeManager.currentTheme = theme
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
                                    .fill(Color(getCellColor(row: row, col: col)))
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
                .padding(8)
                .background(Color(theme.gridBackgroundColor))
                .cornerRadius(8)

                Text(theme.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemBackground))
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
    }

    private func getCellColor(row: Int, col: Int) -> UIColor {
        // Create a mini preview pattern
        let isBlockCell = (row == 1 && col >= 1 && col <= 2) ||
                         (row == 2 && col >= 1 && col <= 2)

        if isBlockCell {
            return theme.blockColors[0]
        } else {
            return theme.emptyCellColor
        }
    }
}

#Preview {
    ThemeSettingsView()
}