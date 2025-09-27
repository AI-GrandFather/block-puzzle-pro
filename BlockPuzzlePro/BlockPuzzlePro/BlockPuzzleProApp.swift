import SwiftUI
import UIKit
import os.log

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
                    DragDropGameView(gameMode: mode)
                        .navigationBarBackButtonHidden()
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
        switch mode {
        case .grid8x8: return "8×8 Mode"
        case .grid10x10: return "10×10 Mode"
        }
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
