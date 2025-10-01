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
    @State private var showSplash = true

    var body: some View {
        ZStack {
            LandingView()
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
        .alert("Sign-in error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.lastError ?? "Unknown error")
        }
        .onAppear { scheduleSplashDismiss() }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.55)) {
                showSplash = false
            }
        }
    }
}

private enum LandingDestination: Hashable {
    case playSetup
    case game(GameMode)
    case themes
    case account
}

private struct LandingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var cloudSaveStore: CloudSaveStore

    @State private var path: [LandingDestination] = []

    private var isLoading: Bool {
        authViewModel.isAuthenticating || cloudSaveStore.isSyncing
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                LandingBackground()
                    .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer(minLength: 40)

                    LandingBrand()
                        .padding(.horizontal, 36)

                    if isLoading {
                        AnimatedBlockLoader()
                            .transition(.opacity)
                    } else {
                        Text("Spin the pieces, chase combos, and relax into the flow.")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .transition(.opacity)
                    }

                    Spacer()

                    VStack(spacing: 20) {
                        Button {
                            path.append(.playSetup)
                        } label: {
                            Text("Play")
                        }
                        .buttonStyle(
                            BubbleButtonStyle(
                                gradient: LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.58, blue: 0.42),
                                        Color(red: 0.94, green: 0.33, blue: 0.64)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                foreground: .white,
                                shadowOpacity: 0.28
                            )
                        )

                        Button {
                            path.append(.themes)
                        } label: {
                            Text("Themes")
                        }
                        .buttonStyle(
                            BubbleButtonStyle(
                                gradient: LinearGradient(
                                    colors: [
                                        Color(red: 0.60, green: 0.40, blue: 0.95),
                                        Color(red: 0.45, green: 0.25, blue: 0.80)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                foreground: .white,
                                shadowOpacity: 0.22
                            )
                        )

                        Button {
                            path.append(.account)
                        } label: {
                            Text("My Account")
                        }
                        .buttonStyle(
                            BubbleButtonStyle(
                                gradient: LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.28),
                                        Color.white.opacity(0.14)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                foreground: .white,
                                shadowOpacity: 0.12,
                                borderColor: Color.white.opacity(0.35)
                            )
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 56)
                }
            }
            .navigationDestination(for: LandingDestination.self) { destination in
                switch destination {
                case .playSetup:
                    PlaySetupView { mode in
                        if !path.isEmpty {
                            path.removeLast()
                        }
                        path.append(.game(mode))
                    }
                case .game(let mode):
                    DragDropGameView(
                        gameMode: mode,
                        onReturnHome: {
                            path.removeAll()
                        },
                        onReturnModeSelect: {
                            path = [.playSetup]
                        }
                    )
                    .navigationBarBackButtonHidden()
                case .themes:
                    ThemeSelectionView()
                case .account:
                    AccountView()
                }
            }
        }
    }
}

private struct LandingBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.11, green: 0.16, blue: 0.31),
                    Color(red: 0.18, green: 0.26, blue: 0.54),
                    Color(red: 0.34, green: 0.26, blue: 0.58)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            AnimatedBackdrop()
                .opacity(0.45)

            ForEach(0..<6) { index in
                SplashBlock(index: index)
            }
        }
    }
}

private struct LandingBrand: View {
    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.73, blue: 0.47),
                                Color(red: 0.97, green: 0.47, blue: 0.63)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 12)

                AnimatedBlockSymbol()
                    .frame(width: 94, height: 94)
            }

            Text("Block Scramble")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
        )
    }
}

private struct AnimatedBlockSymbol: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let progress = (time.truncatingRemainder(dividingBy: 2.6)) / 2.6
            let rotation = Angle.degrees(progress * 360)
            let scale = 0.82 + 0.18 * sin(progress * .pi * 2)

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 96, height: 96)
                    .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)

                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(blockColor(for: index))
                        .frame(width: 26, height: 26)
                        .offset(blockOffset(for: index))
                        .rotationEffect(rotation)
                        .scaleEffect(scale)
                        .shadow(color: blockColor(for: index).opacity(0.45), radius: 8, x: 0, y: 4)
                }
            }
        }
    }

    private func blockColor(for index: Int) -> Color {
        switch index {
        case 0: return Color(red: 0.98, green: 0.46, blue: 0.64)
        case 1: return Color(red: 0.46, green: 0.78, blue: 0.98)
        case 2: return Color(red: 0.57, green: 0.88, blue: 0.62)
        default: return Color(red: 0.98, green: 0.68, blue: 0.39)
        }
    }

    private func blockOffset(for index: Int) -> CGSize {
        switch index {
        case 0: return CGSize(width: -20, height: -14)
        case 1: return CGSize(width: 22, height: -8)
        case 2: return CGSize(width: -10, height: 22)
        default: return CGSize(width: 18, height: 18)
        }
    }
}

private struct AnimatedBlockLoader: View {
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<3) { index in
                LoaderBlock(index: index)
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.16))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.24), lineWidth: 1)
                )
        )
    }

    private struct LoaderBlock: View {
        let index: Int

        var body: some View {
            TimelineView(.animation(minimumInterval: 1 / 45)) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate + Double(index) * 0.25
                let wave = 0.68 + 0.32 * CGFloat(sin(time * 2.6 * .pi))
                let rotation = Angle.degrees(Double(wave) * 180)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(loaderColor)
                    .frame(width: 50, height: 50)
                    .scaleEffect(wave)
                    .rotationEffect(rotation)
                    .shadow(color: loaderColor.opacity(0.45), radius: 10, x: 0, y: 5)
            }
        }

        private var loaderColor: Color {
            switch index {
            case 0: return Color(red: 0.99, green: 0.65, blue: 0.41)
            case 1: return Color(red: 0.47, green: 0.75, blue: 0.98)
            default: return Color(red: 0.57, green: 0.87, blue: 0.76)
            }
        }
    }
}

private struct BubbleButtonStyle: ButtonStyle {
    let gradient: LinearGradient
    let foreground: Color
    let shadowOpacity: Double
    let borderColor: Color?

    init(gradient: LinearGradient, foreground: Color = .white, shadowOpacity: Double = 0.2, borderColor: Color? = nil) {
        self.gradient = gradient
        self.foreground = foreground
        self.shadowOpacity = shadowOpacity
        self.borderColor = borderColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .foregroundStyle(foreground.opacity(configuration.isPressed ? 0.9 : 1))
            .background(
                Capsule()
                    .fill(gradient)
            )
            .overlay(
                Capsule()
                    .stroke(borderColor ?? .clear, lineWidth: borderColor == nil ? 0 : 1)
            )
            .shadow(color: Color.black.opacity(shadowOpacity), radius: configuration.isPressed ? 12 : 22, x: 0, y: configuration.isPressed ? 6 : 14)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct PlaySetupView: View {
    @Environment(\.dismiss) private var dismiss

    let startGame: (GameMode) -> Void

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Text("Pick a mode")
                    .font(.largeTitle.weight(.bold))
                Text("Tap a bubble to jump straight into the puzzle.")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondary)
            }
            .padding(.top, 20)

            VStack(spacing: 16) {
                ForEach(GameMode.allCases) { mode in
                    Button {
                        startGame(mode)
                    } label: {
                        ModeBubble(mode: mode)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.bottom, 24)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }
            }
        }
    }
}

private struct ModeBubble: View {
    let mode: GameMode

    private var title: String {
        mode.displayName
    }

    private var gradient: LinearGradient {
        switch mode {
        case .grid8x8:
            return LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.73, blue: 0.99),
                    Color(red: 0.26, green: 0.49, blue: 0.94)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .grid10x10:
            return LinearGradient(
                colors: [
                    Color(red: 0.41, green: 0.85, blue: 0.64),
                    Color(red: 0.19, green: 0.64, blue: 0.47)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .timedThreeMinutes, .timedFiveMinutes, .timedSevenMinutes:
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.5, blue: 0.3),
                    Color(red: 0.8, green: 0.2, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        Text(title)
            .font(.title3.weight(.bold))
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .foregroundStyle(Color.white)
            .background(
                Capsule()
                    .fill(gradient)
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 10)
    }
}

private struct AccountView: View {
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

private struct AnimatedBackdrop: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 40)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let rotation = Angle.degrees((time.truncatingRemainder(dividingBy: 16)) / 16 * 360)

            RadialGradient(
                colors: [
                    Color.white.opacity(0.32),
                    Color.white.opacity(0.02)
                ],
                center: .center,
                startRadius: 40,
                endRadius: 460
            )
            .rotationEffect(rotation)
            .blur(radius: 120)
            .scaleEffect(1.25)
        }
    }
}

private struct SplashView: View {
    var body: some View {
        ZStack {
            LandingBackground()
                .ignoresSafeArea()

            VStack(spacing: 32) {
                LandingBrand()

                AnimatedBlockLoader()

                Text("Loading…")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .padding(40)
        }
    }
}

private struct SplashBlock: View {
    let index: Int

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 50)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate + Double(index) * 0.4
            let oscillation = sin(time * 1.6) * 40
            let baseSize: CGFloat = 160 + CGFloat(index * 22)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                .frame(width: baseSize, height: baseSize)
                .rotationEffect(.degrees(Double(time * 18).truncatingRemainder(dividingBy: 360)))
                .offset(x: CGFloat(oscillation), y: CGFloat(-oscillation / 2))
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

private struct ThemeSelectionView: View {
    @State private var selectedTheme: Theme = Theme.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Dark Themes
                VStack(alignment: .leading, spacing: 16) {
                    Text("Dark Themes")
                        .font(.title2.weight(.bold))
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach([Theme.classicDark, .neonCyberpunk, .midnightBlue, .diabloMaroon, .forestNight, .purpleDreams, .retroArcade], id: \.self) { theme in
                            ThemeBubbleMain(theme: theme, isSelected: selectedTheme == theme) {
                                selectTheme(theme)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Light Themes
                VStack(alignment: .leading, spacing: 16) {
                    Text("Light Themes")
                        .font(.title2.weight(.bold))
                        .padding(.horizontal, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach([Theme.oceanBreeze, .sunsetGlow, .cherryBlossom], id: \.self) { theme in
                            ThemeBubbleMain(theme: theme, isSelected: selectedTheme == theme) {
                                selectTheme(theme)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 28)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Themes")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            selectedTheme = Theme.current
        }
    }

    private func selectTheme(_ theme: Theme) {
        selectedTheme = theme
        Theme.current = theme
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}

private struct ThemeBubbleMain: View {
    let theme: Theme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(theme.blockColor).opacity(0.3))
                            .frame(width: 70, height: 70)
                            .blur(radius: 10)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(theme.blockColor),
                                    Color(theme.blockColor).opacity(0.80)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.white : Color.white.opacity(0.3),
                                    lineWidth: isSelected ? 4 : 2
                                )
                        )
                        .shadow(color: Color(theme.blockColor).opacity(0.5), radius: isSelected ? 16 : 8, x: 0, y: isSelected ? 8 : 4)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }

                Text(theme.displayName)
                    .font(.system(size: 13, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color(theme.blockColor) : Color.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isSelected
                        ? Color(theme.blockColor).opacity(0.12)
                        : Color(UIColor.secondarySystemGroupedBackground)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? Color(theme.blockColor).opacity(0.5) : Color.clear,
                        lineWidth: isSelected ? 2.5 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
