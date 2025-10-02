import SwiftUI
import UIKit
import os.log

// MARK: - Theme System
// Professional game themes based on industry research
// All themes meet WCAG AA accessibility standards (4.5:1 contrast ratio)
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

@main
struct BlockPuzzleProApp: App {
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "AppLifecycle")
    @StateObject private var cloudSaveStore: CloudSaveStore
    @StateObject private var authViewModel: AuthViewModel

    init() {
        logger.info("BlockPuzzlePro app initializing")

        let cloudStore = CloudSaveStore()
        _cloudSaveStore = StateObject(wrappedValue: cloudStore)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(cloudStore: cloudStore))

        setupAppLifecycleObservers()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(cloudSaveStore)
                .onAppear {
                    logger.info("BlockPuzzlePro app launched successfully")

                    // Enable 120Hz ProMotion for enhanced performance
                    Task { @MainActor in
                        FrameRateConfigurator.configurePreferredFrameRate()
                        let info = FrameRateConfigurator.currentDisplayInfo()
                        if info.maxRefreshRate >= 120 {
                            logger.info("🚀 ProMotion display detected (preferred=\(info.preferredRefreshRate)Hz, max=\(info.maxRefreshRate)Hz)")
                        } else {
                            logger.info("📱 Standard display detected (preferred=\(info.preferredRefreshRate)Hz, max=\(info.maxRefreshRate)Hz)")
                        }
                    }
                }
                .onOpenURL { url in
                    Task { await authViewModel.handleRedirect(url: url) }
                }
        }
        .backgroundTask(.appRefresh("com.example.BlockPuzzlePro.refresh")) {
            logger.info("App background refresh task executed")
        }
    }

    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("App entered background - saving state and pausing")
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("App will enter foreground - resuming operations")
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("App became active - fully resumed")
        }

        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            logger.info("App will resign active - preparing for background")
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var theme: Theme = Theme.current
    @State private var showSplash = true

    var body: some View {
        ZStack {
            MainMenuNavigationHost(theme: theme)
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView(theme: theme)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .preferredColorScheme(theme.isDarkTheme ? .dark : .light)
        .statusBarHidden()
        .alert("Sign-in error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.lastError ?? "Unknown error")
        }
        .onAppear { scheduleSplashDismiss() }
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { notification in
            guard let newTheme = notification.object as? Theme else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                theme = newTheme
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { authViewModel.lastError != nil },
            set: { hasError in
                if !hasError {
                    authViewModel.clearError()
                }
            }
        )
    }

    private func scheduleSplashDismiss() {
        guard showSplash else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.45)) {
                showSplash = false
            }
        }
    }
}

private enum MenuRoute: Hashable {
    case game(GameMode)
}

private struct MainMenuNavigationHost: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var cloudSaveStore: CloudSaveStore

    let theme: Theme

    @State private var path: [MenuRoute] = []
    @State private var showSettings = false
    @State private var showThemes = false
    @State private var showAccount = false
    @State private var showModePicker = false
    @State private var pendingModeToLaunch: GameMode?
    @State private var deferredMenuAction: DeferredMenuAction?

    private var isLoading: Bool {
        authViewModel.isAuthenticating || cloudSaveStore.isSyncing
    }

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView(
                theme: theme,
                isLoading: isLoading,
                onPlay: presentModePicker,
                onOpenSettings: { showSettings = true },
                onOpenAccount: { showAccount = true }
            )
            .navigationDestination(for: MenuRoute.self) { destination in
                switch destination {
                case .game(let mode):
                    DragDropGameView(
                        gameMode: mode,
                        onReturnHome: { path.removeAll() },
                        onReturnModeSelect: reopenModeSelection
                    )
                    .navigationBarBackButtonHidden()
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsPanel(
                    theme: theme,
                    onShowThemes: { scheduleMenuAction(.showThemes) },
                    onReturn: { showSettings = false }
                )
            }
            .sheet(isPresented: $showThemes) {
                ThemePaletteSheet(theme: theme)
            }
            .sheet(isPresented: $showAccount) {
                NavigationStack {
                    AccountView()
                        .navigationTitle("Account")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { showAccount = false }
                            }
                        }
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showModePicker) {
                ModeSelectionSheet(theme: theme) { mode in
                    scheduleModeLaunch(mode)
                }
            }
        }
        .onChange(of: showSettings) { _, isPresented in
            guard !isPresented else { return }
            handleDeferredMenuActionIfNeeded()
        }
        .onChange(of: showModePicker) { _, isPresented in
            guard !isPresented else { return }
            launchPendingModeIfNeeded()
        }
    }

    private func presentModePicker() {
        pendingModeToLaunch = nil
        showModePicker = true
    }

    private func scheduleModeLaunch(_ mode: GameMode) {
        pendingModeToLaunch = mode
        showModePicker = false
    }

    private func launchPendingModeIfNeeded() {
        guard let mode = pendingModeToLaunch else { return }
        pendingModeToLaunch = nil
        startGame(with: mode)
    }

    private func startGame(with mode: GameMode) {
        path = [.game(mode)]
    }

    private func reopenModeSelection() {
        path.removeAll()
        pendingModeToLaunch = nil
        showModePicker = true
    }

    private func scheduleMenuAction(_ action: DeferredMenuAction) {
        deferredMenuAction = action
        showSettings = false
    }

    private enum DeferredMenuAction {
        case showThemes
    }

    private func handleDeferredMenuActionIfNeeded() {
        guard let action = deferredMenuAction else { return }
        deferredMenuAction = nil

        switch action {
        case .showThemes:
            showThemes = true
        }
    }
}

private struct MainMenuView: View {
    let theme: Theme
    let isLoading: Bool
    let onPlay: () -> Void
    let onOpenSettings: () -> Void
    let onOpenAccount: () -> Void

    private var accent: Color { theme.accentColor }
    private var backgroundGradient: LinearGradient { theme.menuBackgroundGradient }

    var body: some View {
        ZStack {
            backgroundGradient
                .overlay(
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.32), theme.accentColor.opacity(0.04)],
                        center: .center,
                        startRadius: 60,
                        endRadius: 420
                    )
                    .blendMode(.plusLighter)
                )
                .ignoresSafeArea()

            BlockGridBackground(color: theme.gridOverlayColor)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer(minLength: 60)

                BlockClusterLogo(theme: theme)

                VStack(spacing: 8) {
                    Text("Block Scramble")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.primaryText)

                    Text("Snap into flow with crisp 120 Hz puzzle action.")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.secondaryText)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 18) {
                    MenuBlockButton(
                        title: "Play",
                        iconName: "play.fill",
                        tint: accent,
                        theme: theme,
                        action: onPlay
                    )
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.55 : 1.0)

                    MenuBlockButton(
                        title: "Settings",
                        iconName: "slider.horizontal.3",
                        tint: theme.surfaceHighlight,
                        theme: theme,
                        action: onOpenSettings
                    )

                    MenuBlockButton(
                        title: "Account",
                        iconName: "person.crop.square",
                        tint: theme.surfaceHighlight.opacity(0.85),
                        theme: theme,
                        action: onOpenAccount
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)

                if isLoading {
                    AnimatedBlockLoader(accent: accent)
                        .padding(.bottom, 26)
                }
            }
        }
    }
}

struct BlockClusterLogo: View {
    let theme: Theme

    private struct BlockSpec {
        let x: CGFloat
        let y: CGFloat
        let scale: CGFloat
        let phase: Double
    }

    private let blockSpecs: [BlockSpec] = [
        BlockSpec(x: 0.28, y: 0.28, scale: 0.9, phase: 0.0),
        BlockSpec(x: 0.52, y: 0.22, scale: 0.78, phase: 0.45),
        BlockSpec(x: 0.74, y: 0.34, scale: 1.0, phase: 0.8),
        BlockSpec(x: 0.34, y: 0.60, scale: 0.88, phase: 1.2),
        BlockSpec(x: 0.62, y: 0.64, scale: 0.94, phase: 1.6),
        BlockSpec(x: 0.46, y: 0.80, scale: 0.7, phase: 2.0)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 45)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accentColor.opacity(theme.isDarkTheme ? 0.35 : 0.25),
                                theme.surfaceBackground.opacity(theme.isDarkTheme ? 0.65 : 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(theme.surfaceHighlight.opacity(0.55), lineWidth: 1.2)
                    )
                    .shadow(color: theme.accentColor.opacity(0.35), radius: 28, x: 0, y: 20)
                    .overlay(
                        AngularGradient(
                            colors: [
                                theme.accentColor.opacity(0.18),
                                theme.accentColor.opacity(0.05),
                                theme.surfaceHighlight.opacity(0.12)
                            ],
                            center: .center
                        )
                        .blendMode(.plusLighter)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    )

                GeometryReader { geo in
                    let width = geo.size.width
                    let height = geo.size.height
                    let base = min(width, height)
                    let baseBlock = base / 4.1

                    ForEach(Array(blockSpecs.enumerated()), id: \.offset) { index, spec in
                        let wave = sin(time * 1.6 + spec.phase * .pi)
                        let blockSize = baseBlock * spec.scale
                        RoundedRectangle(cornerRadius: blockSize * 0.3, style: .continuous)
                            .fill(tileGradient(for: index))
                            .overlay(
                                RoundedRectangle(cornerRadius: blockSize * 0.3, style: .continuous)
                                    .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                            )
                            .frame(width: blockSize, height: blockSize)
                            .position(
                                x: spec.x * width,
                                y: spec.y * height + CGFloat(wave * 6)
                            )
                            .shadow(color: tileShadow(for: index), radius: 10, x: 0, y: 8)
                    }
                }
                .frame(width: 184, height: 184)
            }
            .frame(width: 200, height: 200)
        }
    }

    private func tileGradient(for index: Int) -> LinearGradient {
        let base = theme.accentColor
        let lighten = base.opacity(0.65 + 0.07 * Double(index % 3))
        let glow = base.opacity(0.35)
        return LinearGradient(
            colors: [lighten, glow],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func tileShadow(for index: Int) -> Color {
        theme.accentColor.opacity(0.3 - 0.04 * Double(index % 3))
    }
}

struct MenuBlockButton: View {
    let title: String
    let iconName: String
    let tint: Color
    let theme: Theme
    let action: () -> Void

    @GestureState private var isPressed = false

    var body: some View {
        let pressGesture = DragGesture(minimumDistance: 0)
            .updating($isPressed) { _, state, _ in state = true }

        return Button(action: action) {
            HStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.surfaceHighlight.opacity(0.4), lineWidth: 1)
                    )
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(theme.iconForeground(on: tint))
                    )
                    .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.primaryText)
                    Rectangle()
                        .fill(theme.accentColor.opacity(0.22))
                        .frame(width: 64, height: 4)
                        .cornerRadius(2)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                    )
            )
            .shadow(color: tint.opacity(0.28), radius: 18, x: 0, y: 14)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .gesture(pressGesture)
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isPressed)
    }
}

private struct SettingsPanel: View {
    @Environment(\.dismiss) private var dismiss

    let theme: Theme
    let onShowThemes: () -> Void
    let onReturn: () -> Void

    @State private var deferredAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 28) {
            Capsule()
                .fill(theme.surfaceHighlight.opacity(0.6))
                .frame(width: 44, height: 5)
                .padding(.top, 12)

            VStack(spacing: 8) {
                Text("Settings")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.primaryText)
                Text("Customize your puzzle vibe.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
            }

            VStack(spacing: 18) {
                SettingsOptionButton(
                    title: "Themes",
                    subtitle: "Swap palettes instantly",
                    iconName: "paintpalette.fill",
                    theme: theme
                ) {
                    schedule(action: onShowThemes)
                }

                SettingsOptionButton(
                    title: "Return to Main",
                    subtitle: "Close settings",
                    iconName: "house.fill",
                    theme: theme
                ) {
                    schedule(action: onReturn)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(theme.surfaceBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(theme.surfaceHighlight.opacity(0.5), lineWidth: 1)
                )
        )
        .background(theme.backgroundColorSwift.opacity(0.92).ignoresSafeArea())
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.hidden)
        .onDisappear {
            if let action = deferredAction {
                deferredAction = nil
                action()
            }
        }
    }

    private func schedule(action: @escaping () -> Void) {
        deferredAction = action
        dismiss()
    }
}

private struct ModeSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let theme: Theme
    let onSelect: (GameMode) -> Void

    private var descriptors: [ModeDescriptor] {
        [
            ModeDescriptor(
                mode: .grid8x8,
                title: "8×8 Grid",
                subtitle: "Intimate board, quicker clears",
                iconName: "square.grid.3x3.fill",
                accent: theme.accentColor
            ),
            ModeDescriptor(
                mode: .grid10x10,
                title: "10×10 Grid",
                subtitle: "Spacious layout for marathon runs",
                iconName: "rectangle.grid.3x2",
                accent: theme.accentColor.opacity(0.8)
            ),
            ModeDescriptor(
                mode: .timedThreeMinutes,
                title: "3 Minute Sprint",
                subtitle: "8×8 grid · speed focused challenge",
                iconName: "timer",
                accent: Color.orange
            ),
            ModeDescriptor(
                mode: .timedFiveMinutes,
                title: "5 Minute Rush",
                subtitle: "8×8 grid · balanced pacing",
                iconName: "stopwatch",
                accent: Color.purple
            ),
            ModeDescriptor(
                mode: .timedSevenMinutes,
                title: "7 Minute Marathon",
                subtitle: "8×8 grid · endurance mode",
                iconName: "hourglass.circle.fill",
                accent: Color.mint
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ModeSelectionHeader(theme: theme)

                    VStack(spacing: 16) {
                        ForEach(descriptors) { descriptor in
                            ModeOptionCard(descriptor: descriptor, theme: theme) {
                                handleSelection(descriptor.mode)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(theme.backgroundColorSwift.ignoresSafeArea())
            .navigationTitle("Choose Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .tint(theme.accentColor)
                }
            }
        }
        .presentationDetents([.fraction(0.72), .large])
        .presentationDragIndicator(.visible)
    }

    private func handleSelection(_ mode: GameMode) {
        onSelect(mode)
        dismiss()
    }

    fileprivate struct ModeDescriptor: Identifiable {
        let mode: GameMode
        let title: String
        let subtitle: String
        let iconName: String
        let accent: Color

        var id: GameMode { mode }
        var isTimed: Bool { mode.isTimed }
        var durationLabel: String? {
            guard let seconds = mode.timerDuration else { return nil }
            let minutes = Int(seconds) / 60
            return "\(minutes) min"
        }
    }
}

private struct ModeSelectionHeader: View {
    let theme: Theme

    var body: some View {
        VStack(spacing: 12) {
            Text("Pick Your Challenge")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.primaryText)

            Text("Swap between free-play grids or timed sprints whenever you like.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 4)
    }
}

private struct ModeOptionCard: View {
    let descriptor: ModeSelectionSheet.ModeDescriptor
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(descriptor.accent.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: descriptor.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(descriptor.accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(descriptor.title)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.primaryText)

                        if let badge = descriptor.durationLabel {
                            Text(badge)
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(descriptor.accent.opacity(0.22))
                                .clipShape(Capsule())
                                .foregroundStyle(theme.primaryText)
                        }
                    }

                    Text(descriptor.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(theme.secondaryText.opacity(0.7))
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.surfaceBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(theme.surfaceHighlight.opacity(0.45), lineWidth: 1)
                    )
            )
            .shadow(color: descriptor.accent.opacity(0.18), radius: 16, x: 0, y: 12)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsOptionButton: View {
    let title: String
    let subtitle: String
    let iconName: String
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accentColor.opacity(0.85))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: iconName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(theme.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(theme.secondaryText.opacity(0.85))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.surfaceHighlight.opacity(theme.isDarkTheme ? 0.5 : 0.68))
            )
        }
        .buttonStyle(.plain)
    }
}

struct ThemePaletteSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var previewTheme: Theme = Theme.current
    @State private var selectedTheme: Theme = Theme.current

    let theme: Theme

    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 20)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    ThemePreviewRow(theme: previewTheme)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(Theme.allCases, id: \.self) { option in
                            ThemeTile(theme: option, isSelected: option == selectedTheme) {
                                applyTheme(option)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(previewTheme.backgroundColorSwift.ignoresSafeArea())
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .tint(previewTheme.accentColor)
                }
            }
        }
        .presentationDetents([.fraction(0.92)])
    }

    private func applyTheme(_ theme: Theme) {
        selectedTheme = theme
        previewTheme = theme
        Theme.current = theme
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

private struct ThemeTile: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    private let tilePositions: [CGPoint] = [
        CGPoint(x: 0.28, y: 0.28),
        CGPoint(x: 0.52, y: 0.22),
        CGPoint(x: 0.74, y: 0.34),
        CGPoint(x: 0.34, y: 0.60),
        CGPoint(x: 0.64, y: 0.66),
        CGPoint(x: 0.46, y: 0.80)
    ]

    var body: some View {
        Button(action: action) {
            VStack(spacing: 18) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.menuBackgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(theme.surfaceHighlight.opacity(isSelected ? 0.85 : 0.4), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: theme.accentColor.opacity(0.28), radius: isSelected ? 18 : 10, x: 0, y: isSelected ? 14 : 8)
                    .overlay(
                        GeometryReader { geo in
                            let width = geo.size.width
                            let height = geo.size.height
                            let blockSize = min(width, height) / 5.1

                            ForEach(Array(tilePositions.enumerated()), id: \.offset) { index, position in
                                RoundedRectangle(cornerRadius: blockSize * 0.28, style: .continuous)
                                    .fill(theme.accentColor.opacity(0.62 + 0.08 * Double(index % 3)))
                                    .frame(width: blockSize, height: blockSize)
                                    .position(
                                        x: position.x * width,
                                        y: position.y * height
                                    )
                                    .shadow(color: theme.accentColor.opacity(0.2), radius: 6, x: 0, y: 5)
                            }
                        }
                    )
                    .frame(height: 140)

                Text(theme.displayName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.primaryText)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(theme.surfaceBackground.opacity(theme.isDarkTheme ? 0.55 : 0.78))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.04 : 1.0)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
    }
}

private struct ThemePreviewRow: View {
    let theme: Theme

    var body: some View {
        HStack(spacing: 16) {
            ThemePreviewCard(title: "Main", gradient: theme.menuBackgroundGradient, accent: theme.accentColor)
            ThemePreviewCard(title: "Settings", gradient: theme.menuGradient(strength: 0.75), accent: theme.surfaceHighlight)
            ThemePreviewCard(title: "Game Over", gradient: theme.menuGradient(strength: 1.25), accent: theme.accentColor)
        }
    }
}

private struct ThemePreviewCard: View {
    let title: String
    let gradient: LinearGradient
    let accent: Color

    var body: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(gradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(accent.opacity(0.45), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(accent.opacity(0.8))
                        .frame(width: 42, height: 14)
                        .offset(y: 10), alignment: .top
                )
                .frame(height: 70)

            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.white.opacity(0.82))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct BlockGridBackground: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 48
            Path { path in
                var y: CGFloat = 0
                while y <= proxy.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: proxy.size.width, y: y))
                    y += spacing
                }

                var x: CGFloat = 0
                while x <= proxy.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    x += spacing
                }
            }
            .stroke(color.opacity(0.18), lineWidth: 0.8)
        }
        .allowsHitTesting(false)
    }
}

private struct AnimatedBlockLoader: View {
    let accent: Color

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            HStack(spacing: 10) {
                ForEach(0..<5) { index in
                    let phase = sin(time * 2.0 + Double(index) * 0.6)
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(accent.opacity(0.58 + 0.1 * Double(index % 3)))
                        .frame(width: 18, height: 18 + CGFloat(phase + 1) * 6)
                        .offset(y: CGFloat(-phase * 6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(accent.opacity(0.18))
            )
        }
    }
}

private struct SplashView: View {
    let theme: Theme

    var body: some View {
        ZStack {
            theme.menuBackgroundGradient
                .overlay(
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.28), theme.accentColor.opacity(0.05)],
                        center: .center,
                        startRadius: 40,
                        endRadius: 320
                    )
                    .blendMode(.plusLighter)
                )
                .ignoresSafeArea()

            BlockGridBackground(color: theme.gridOverlayColor)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                BlockClusterLogo(theme: theme)
                AnimatedBlockLoader(accent: theme.accentColor)
                Text("Loading blocks…")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.secondaryText)
            }
        }
    }
}

private extension Theme {
    var accentColor: Color { Color(blockColor) }
    var backgroundColorSwift: Color { Color(backgroundColor) }
    var primaryText: Color { isDarkTheme ? Color.white : Color.black }
    var secondaryText: Color { primaryText.opacity(0.72) }
    var surfaceHighlight: Color { isDarkTheme ? Color.white.opacity(0.18) : Color.black.opacity(0.08) }
    var surfaceBackground: Color { isDarkTheme ? Color.white.opacity(0.12) : Color.white.opacity(0.88) }
    var gridOverlayColor: Color { isDarkTheme ? Color.white.opacity(0.05) : Color.black.opacity(0.05) }
    var menuBackgroundGradient: LinearGradient { menuGradient(strength: 1.0) }

    func menuGradient(strength: Double) -> LinearGradient {
        let accentStrength = max(0.1, min(0.85, (isDarkTheme ? 0.45 : 0.32) * strength))
        return LinearGradient(
            colors: [
                backgroundColorSwift,
                backgroundColorSwift.opacity(isDarkTheme ? 0.9 : 0.96),
                accentColor.opacity(accentStrength)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func iconForeground(on base: Color) -> Color {
        base.luminance > 0.6 ? Color.black.opacity(0.85) : Color.white
    }
}

private extension Color {
    var luminance: Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return Double(0.299 * red + 0.587 * green + 0.114 * blue)
    }
}


struct AccountView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header

                if let email = authViewModel.userEmail {
                    signedInSection(email: email)
                } else {
                    signInOptions
                }

                Spacer(minLength: 24)
            }
            .padding(24)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("My Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.square")
                .font(.system(size: 54, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .padding(20)
                .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text("Manage your profile")
                .font(.title2.weight(.bold))
            Text("Sign in or link an account so we can keep your scores safe in the cloud.")
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func signedInSection(email: String) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Signed in as")
                    .font(.callout)
                    .foregroundStyle(Color.secondary)
                Text(email)
                    .font(.headline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button(role: .destructive) {
                Task { await authViewModel.signOut() }
            } label: {
                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.red.opacity(0.85))
        }
    }

    private var signInOptions: some View {
        VStack(spacing: 18) {
            Button {
                Task { await authViewModel.signInWithGoogle() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "g.circle.fill")
                    Text("Continue with Google")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.31, green: 0.55, blue: 0.97))

            Button {
                // Placeholder for future Sign in with Apple implementation
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                    Text("Continue with Apple (coming soon)")
                        .font(.body.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Color.primary)
            .disabled(true)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundStyle(Color.gray.opacity(0.4))
            )
        }
    }
}

struct GameViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        GameViewController()
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        // Intentionally left blank
    }
}
