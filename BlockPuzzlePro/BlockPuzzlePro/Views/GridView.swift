import SwiftUI

// MARK: - Grid View (Simplified)

/// SwiftUI view that displays the 10x10 game grid
struct GridView: View {
    
    // MARK: - Properties
    
    @ObservedObject var gameEngine: GameEngine
    @ObservedObject var dragController: DragController
    
    let cellSize: CGFloat
    let gridSpacing: CGFloat
    let highlightedPositions: Set<GridPosition>
    
    // MARK: - Initialization
    
    init(
        gameEngine: GameEngine,
        dragController: DragController,
        cellSize: CGFloat,
        gridSpacing: CGFloat = 1,
        highlightedPositions: Set<GridPosition> = []
    ) {
        self.gameEngine = gameEngine
        self.dragController = dragController
        self.cellSize = cellSize
        self.gridSpacing = gridSpacing
        self.highlightedPositions = highlightedPositions
    }
    
    // MARK: - Body
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellSize), spacing: gridSpacing), count: 10), spacing: gridSpacing) {
            ForEach(0..<100, id: \.self) { index in
                let row = index / 10
                let col = index % 10
                let position = GridPosition(unsafeRow: row, unsafeColumn: col)
                
                GridCellView(
                    position: position,
                    cell: gameEngine.cell(at: position) ?? .empty,
                    cellSize: cellSize,
                    isHighlighted: highlightedPositions.contains(position)
                )
            }
        }
        .padding(gridSpacing)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Grid Cell View

struct GridCellView: View {
    let position: GridPosition
    let cell: GridCell
    let cellSize: CGFloat
    let isHighlighted: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(cellColor)
                .frame(width: cellSize, height: cellSize)
                .overlay(
                    Rectangle()
                        .stroke(Color(UIColor.systemGray5), lineWidth: 0.5)
                )
            
            if isHighlighted {
                LineClearEffectView(cellSize: cellSize)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity),
                        removal: .scale(scale: 1.2).combined(with: .opacity)
                    ))
            }
        }
        .scaleEffect(isHighlighted ? 1.08 : 1.0)
        .animation(.spring(
            response: UIScreen.main.maximumFramesPerSecond >= 120 ? 0.2 : 0.4,
            dampingFraction: 0.7
        ), value: isHighlighted)
    }
    
    private var cellColor: Color {
        switch cell {
        case .empty:
            return Color(UIColor.systemBackground)
        case .occupied(let blockColor):
            return Color(blockColor.uiColor)
        case .preview(let blockColor):
            return Color(blockColor.uiColor).opacity(0.5)
        }
    }
}

// MARK: - Particle Burst Effect

struct ParticleBurstView: View {
    let cellSize: CGFloat
    @State private var particleStates: [ParticleState] = []

    struct ParticleState: Identifiable {
        let id = UUID()
        var position: CGPoint = .zero
        var velocity: CGPoint = .zero
        var opacity: Double = 1.0
        var scale: Double = 1.0
        var rotation: Double = 0.0
    }

    var body: some View {
        ZStack {
            ForEach(particleStates) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white, Color.accentColor.opacity(0.8)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 2
                        )
                    )
                    .frame(width: 4, height: 4)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(particle.position)
                    .shadow(color: Color.accentColor, radius: 1, x: 0, y: 0)
            }
        }
        .onAppear {
            createParticleBurst()
        }
    }

    private func createParticleBurst() {
        let particleCount = 8
        particleStates = (0..<particleCount).map { index in
            let angle = Double(index) * (2 * Double.pi / Double(particleCount))
            let speed: Double = Double.random(in: 20...40)

            return ParticleState(
                position: CGPoint(x: cellSize/2, y: cellSize/2),
                velocity: CGPoint(
                    x: cos(angle) * speed,
                    y: sin(angle) * speed
                ),
                opacity: Double.random(in: 0.8...1.0),
                scale: Double.random(in: 0.5...1.2),
                rotation: Double.random(in: 0...360)
            )
        }

        // Animate particles outward with ProMotion optimization
        let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120
        let duration = isProMotion ? 0.5 : 0.6

        withAnimation(.easeOut(duration: duration)) {
            for i in particleStates.indices {
                particleStates[i].position.x += particleStates[i].velocity.x
                particleStates[i].position.y += particleStates[i].velocity.y
                particleStates[i].opacity = 0.0
                particleStates[i].scale = 0.2
                particleStates[i].rotation += 180
            }
        }
    }
}

// MARK: - Line Clear Effect View

struct LineClearEffectView: View {
    let cellSize: CGFloat

    @State private var glowIntensity: Double = 0.0
    @State private var sparkleOpacity: Double = 0.0
    @State private var sparkleRotation: Double = 0.0
    @State private var shimmerOffset: CGFloat = -50

    var body: some View {
        ZStack {
            // Main glow effect
            RoundedRectangle(cornerRadius: cellSize * 0.25)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color.accentColor.opacity(0.8),
                            Color.accentColor.opacity(0.4)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: cellSize * 0.6
                    )
                )
                .frame(width: cellSize * 0.92, height: cellSize * 0.92)
                .overlay(
                    RoundedRectangle(cornerRadius: cellSize * 0.25)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.accentColor,
                                    Color.white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: Color.accentColor.opacity(glowIntensity), radius: 15, x: 0, y: 0)
                .shadow(color: Color.white.opacity(glowIntensity * 0.5), radius: 8, x: 0, y: 0)

            // Shimmer effect
            RoundedRectangle(cornerRadius: cellSize * 0.25)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: cellSize * 0.92, height: cellSize * 0.92)
                .offset(x: shimmerOffset)
                .clipped()

            // Sparkle particles
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 3, height: 3)
                    .offset(
                        x: CGFloat(cos(Double(index) * .pi / 2)) * cellSize * 0.4,
                        y: CGFloat(sin(Double(index) * .pi / 2)) * cellSize * 0.4
                    )
                    .opacity(sparkleOpacity)
                    .rotationEffect(.degrees(sparkleRotation))
                    .shadow(color: Color.accentColor, radius: 2, x: 0, y: 0)
            }

            // Particle burst effect
            ParticleBurstView(cellSize: cellSize)
        }
        .onAppear {
            let isProMotion = UIScreen.main.maximumFramesPerSecond >= 120
            let speedMultiplier: Double = isProMotion ? 0.7 : 1.0

            // Sequence of animations optimized for refresh rate
            withAnimation(.easeOut(duration: 0.1 * speedMultiplier)) {
                glowIntensity = 1.0
                sparkleOpacity = 1.0
            }

            // Shimmer sweep - faster on ProMotion
            withAnimation(.easeInOut(duration: 0.25 * speedMultiplier).delay(0.05 * speedMultiplier)) {
                shimmerOffset = cellSize + 50
            }

            // Sparkle rotation - smoother on 120Hz
            withAnimation(.linear(duration: 0.4 * speedMultiplier).repeatCount(2, autoreverses: false)) {
                sparkleRotation = 360
            }

            // Glow pulse - more responsive on ProMotion
            withAnimation(.easeInOut(duration: 0.15 * speedMultiplier).delay(0.08 * speedMultiplier).repeatCount(2, autoreverses: true)) {
                glowIntensity = 0.7
            }

            // Final fade out preparation happens in parent
        }
    }
}

// MARK: - Preview

#Preview {
    GridView(
        gameEngine: GameEngine(),
        dragController: DragController(),
        cellSize: 30,
        gridSpacing: 2
    )
}
