import SwiftUI

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var rotation: Double
    var velocity: CGSize
}

// MARK: - Confetti Effect

struct ConfettiEffect: View {

    let trigger: Bool
    let origin: CGPoint

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
            }
        }
        .onChange(of: trigger) { _, _ in
            explode()
        }
    }

    private func explode() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        var newParticles: [ConfettiParticle] = []

        for _ in 0..<30 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 100...300)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed

            newParticles.append(ConfettiParticle(
                x: origin.x,
                y: origin.y,
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 4...12),
                rotation: Double.random(in: 0...360),
                velocity: CGSize(width: vx, height: vy)
            ))
        }

        particles = newParticles

        // Animate particles
        withAnimation(.easeOut(duration: 1.5)) {
            particles = particles.map { particle in
                var updated = particle
                updated.x += particle.velocity.width / 60.0
                updated.y += particle.velocity.height / 60.0 + 200 // gravity
                updated.rotation += 360
                return updated
            }
        }

        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particles.removeAll()
        }
    }
}

// MARK: - Sparkle Effect

struct SparkleEffect: View {

    let position: CGPoint
    let trigger: Bool

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, .yellow.opacity(0.7), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 20
                        )
                    )
                    .frame(width: 8, height: 8)
                    .offset(x: cos(Double(index) * .pi / 2 + rotation) * 30,
                            y: sin(Double(index) * .pi / 2 + rotation) * 30)
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .position(position)
        .onChange(of: trigger) { _, _ in
            animate()
        }
    }

    private func animate() {
        opacity = 1.0
        scale = 0.3
        rotation = 0

        withAnimation(.easeOut(duration: 0.6)) {
            scale = 1.5
            rotation = 360
            opacity = 0
        }
    }
}

// MARK: - Score Pop Animation

struct ScorePop: View {

    let text: String
    let position: CGPoint
    let trigger: Bool

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Text(text)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.yellow, .orange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: offset)
            .position(position)
            .onChange(of: trigger) { _, _ in
                animate()
            }
    }

    private func animate() {
        offset = 0
        opacity = 1
        scale = 0.5

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.2
        }

        withAnimation(.easeOut(duration: 0.8)) {
            offset = -60
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            opacity = 0
        }
    }
}

// MARK: - Combo Streak Effect

struct ComboStreakEffect: View {

    let comboCount: Int
    let position: CGPoint
    let trigger: Bool

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = -15

    var body: some View {
        VStack(spacing: 4) {
            Text("COMBO!")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .tracking(2)

            Text("×\(comboCount)")
                .font(.system(size: 32, weight: .black, design: .rounded))
        }
        .foregroundStyle(
            LinearGradient(
                colors: [.purple, .pink, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .opacity(opacity)
        .position(position)
        .onChange(of: trigger) { _, _ in
            animate()
        }
    }

    private func animate() {
        opacity = 1
        scale = 0.3
        rotation = -15

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.0
            rotation = 0
        }

        withAnimation(.easeOut(duration: 0.4).delay(1.0)) {
            opacity = 0
            scale = 1.5
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            ConfettiEffect(trigger: true, origin: CGPoint(x: 200, y: 200))

            SparkleEffect(position: CGPoint(x: 200, y: 400), trigger: true)

            ScorePop(text: "+100", position: CGPoint(x: 200, y: 500), trigger: true)

            ComboStreakEffect(comboCount: 3, position: CGPoint(x: 200, y: 300), trigger: true)
        }
    }
}
