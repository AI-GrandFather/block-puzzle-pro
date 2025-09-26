import SwiftUI
import os.log

@main
struct BlockPuzzleProApp: App {
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "AppLifecycle")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    logger.info("BlockPuzzlePro app launched successfully")
                }
        }
        .backgroundTask(.appRefresh("com.example.BlockPuzzlePro.refresh")) {
            logger.info("App background refresh task executed")
        }
    }

    init() {
        logger.info("BlockPuzzlePro app initializing")
        setupAppLifecycleObservers()
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
    var body: some View {
        GameModeSelectionView()
            .statusBarHidden()
            .preferredColorScheme(.light)
    }
}

struct GameModeSelectionView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                animatedBackground

                VStack(spacing: 32) {
                    heroCard

                    VStack(spacing: 18) {
                        ForEach(GameMode.allCases) { mode in
                            NavigationLink(value: mode) {
                                modeCard(for: mode)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 24)

                    gameFacts
                }
                .padding(.horizontal, 24)
                .padding(.top, 52)
                .padding(.bottom, 36)
            }
            .navigationDestination(for: GameMode.self) { mode in
                DragDropGameView(gameMode: mode)
                    .navigationBarBackButtonHidden()
            }
        }
    }

    private var animatedBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.87, blue: 1.0),
                    Color(red: 0.78, green: 0.9, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottomTrailing
            )

            AnimatedBackdrop()
                .blendMode(.plusLighter)
                .opacity(0.55)
        }
        .ignoresSafeArea()
    }

    private var heroCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.99, green: 0.85, blue: 0.72),
                                     Color(red: 1.0, green: 0.72, blue: 0.77)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.orange.opacity(0.25), radius: 12, x: 0, y: 8)

                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color(UIColor.systemBackground))
            }

            Text("Block Puzzle Pro")
                .font(.system(size: 34, weight: .heavy, design: .rounded))
                .foregroundColor(Color(UIColor.label))
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 12)
        )
    }

    private func modeCard(for mode: GameMode) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(mode.displayName)
                    .font(.title2.weight(.semibold))
                Spacer()
                Image(systemName: mode == .grid8x8 ? "sparkles" : "crown.fill")
                    .font(.title3.weight(.bold))
            }

            Text(mode == .grid8x8 ?
                 "Short bursts with larger tiles. Perfect for quick sessions." :
                 "Classic challenge with precision scoring and marathon combos.")
            .font(.subheadline)
            .foregroundStyle(Color.white.opacity(0.85))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Label("ProMotion Ready", systemImage: "bolt.fill")
                    Label("Dynamic Grid", systemImage: "square.grid.2x2")
                    Label("Daily Streaks", systemImage: "flame.fill")
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .symbolVariant(.fill)
            }
            .scrollDisabled(true)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: mode == .grid8x8 ?
                    [Color(red: 0.37, green: 0.64, blue: 0.99), Color(red: 0.18, green: 0.44, blue: 0.93)] :
                    [Color(red: 0.32, green: 0.78, blue: 0.56), Color(red: 0.13, green: 0.58, blue: 0.43)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
    }

    private var gameFacts: some View {
        VStack(spacing: 10) {
            Text("Ultra-low latency drag & drop • Adaptive haptics • Cloud sync ready")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Text("Optimized for iOS 26 and ProMotion up to 120Hz.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
    }
}

private struct AnimatedBackdrop: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 45)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let rotation = Angle.degrees((time.truncatingRemainder(dividingBy: 18)) / 18 * 360)

            AngularGradient(
                colors: [
                    Color.pink.opacity(0.8),
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.9),
                    Color.orange.opacity(0.75)
                ],
                center: .center,
                angle: rotation
            )
            .blur(radius: 120)
            .scaleEffect(1.3)
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
