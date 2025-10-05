import SwiftUI

// MARK: - Theme Unlock Toast

struct ThemeUnlockToast: View {

    let themeName: String
    let onDismiss: () -> Void
    let onViewThemes: () -> Void

    @State private var offset: CGFloat = -300
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Theme Unlocked!")
                        .font(.headline)

                    Text(themeName)
                        .font(.title3.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )

            // View Themes Button
            Button(action: {
                onDismiss()
                onViewThemes()
            }) {
                Text("View Themes")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .padding(.horizontal, 20)
        .offset(y: offset)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                offset = 0
                scale = 1.0
                opacity = 1.0
            }

            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                dismissAnimation()
            }
        }
    }

    private func dismissAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = -300
            opacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }
}

// MARK: - Theme Unlock Notification Wrapper

struct ThemeUnlockNotification: ViewModifier {

    @ObservedObject var themeManager: UnlockableThemeManager
    let onViewThemes: () -> Void

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if let firstUnlock = themeManager.newlyUnlockedThemes.first {
                ThemeUnlockToast(
                    themeName: firstUnlock,
                    onDismiss: {
                        themeManager.clearNewUnlocks()
                    },
                    onViewThemes: onViewThemes
                )
                .padding(.top, 60)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1000)
            }
        }
    }
}

extension View {
    func themeUnlockNotification(
        themeManager: UnlockableThemeManager,
        onViewThemes: @escaping () -> Void
    ) -> some View {
        modifier(ThemeUnlockNotification(themeManager: themeManager, onViewThemes: onViewThemes))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(UIColor.systemBackground)
            .ignoresSafeArea()

        ThemeUnlockToast(
            themeName: "Galaxy Dream",
            onDismiss: {},
            onViewThemes: {}
        )
        .padding(.top, 60)
    }
}
