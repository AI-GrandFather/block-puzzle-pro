import SwiftUI

// MARK: - Settings View V2

struct SettingsViewV2: View {

    @ObservedObject var audioManager: AudioManager

    let onRestart: () -> Void
    let onReturnHome: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Audio Settings
                        SettingsSection(title: "Audio") {
                            Toggle("Sound Effects", isOn: $audioManager.isSoundEnabled)
                            Toggle("Background Music", isOn: $audioManager.isMusicEnabled)
                        }

                        // Game Actions
                        SettingsSection(title: "Game") {
                            Button(action: {
                                dismiss()
                                onRestart()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Restart Game")
                                    Spacer()
                                }
                                .foregroundColor(.blue)
                            }

                            Button(action: {
                                dismiss()
                                onReturnHome()
                            }) {
                                HStack {
                                    Image(systemName: "house")
                                    Text("Main Menu")
                                    Spacer()
                                }
                                .foregroundColor(.blue)
                            }
                        }

                        // About
                        SettingsSection(title: "About") {
                            HStack {
                                Text("Version")
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(.secondary)
                            }

                            HStack {
                                Text("Developer")
                                Spacer()
                                Text("Block Scramble Team")
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var backgroundColor: some View {
        Color(UIColor.systemGroupedBackground)
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {

    let title: String
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                content
            }
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(sectionBackground)
            )
        }
    }

    private var sectionBackground: Color {
        if colorScheme == .dark {
            return Color(UIColor.systemGray6)
        } else {
            return Color.white
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsViewV2(
        audioManager: AudioManager.shared,
        onRestart: {},
        onReturnHome: {}
    )
}
