// AdvancedParticleSystem.swift
// High-performance particle system with object pooling
// Supports 120fps on ProMotion displays with theme-specific effects

import Foundation
import SwiftUI
import Observation

// MARK: - Particle

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var acceleration: CGVector
    var color: Color
    var size: CGFloat
    var opacity: Double
    var rotation: Angle
    var rotationSpeed: Angle
    var lifetime: TimeInterval
    var age: TimeInterval

    var isAlive: Bool {
        age < lifetime
    }

    mutating func update(deltaTime: TimeInterval) {
        age += deltaTime
        velocity.dx += acceleration.dx * deltaTime
        velocity.dy += acceleration.dy * deltaTime
        position.x += velocity.dx * deltaTime
        position.y += velocity.dy * deltaTime
        rotation += rotationSpeed * deltaTime

        // Fade out over lifetime
        let lifetimeProgress = age / lifetime
        opacity = 1.0 - lifetimeProgress
    }
}

// MARK: - Particle Emitter Configuration

struct ParticleEmitterConfig {
    var particleCount: Int
    var emissionPoint: CGPoint
    var emissionRadius: CGFloat
    var colors: [Color]
    var sizeRange: ClosedRange<CGFloat>
    var velocityRange: ClosedRange<CGFloat>
    var angleRange: ClosedRange<Angle>
    var lifetime: TimeInterval
    var gravity: CGFloat

    static func forEffect(_ effect: ParticleEffectType) -> ParticleEmitterConfig {
        switch effect {
        case .sparkles:
            return ParticleEmitterConfig(
                particleCount: 30,
                emissionPoint: .zero,
                emissionRadius: 20,
                colors: [.white, .yellow, .orange],
                sizeRange: 2...6,
                velocityRange: 50...150,
                angleRange: Angle.degrees(0)...Angle.degrees(360),
                lifetime: 0.5,
                gravity: 100
            )

        case .electricSparks:
            return ParticleEmitterConfig(
                particleCount: 80,
                emissionPoint: .zero,
                emissionRadius: 10,
                colors: [Color(hex: "00FFFF"), Color(hex: "0080FF"), .white],
                sizeRange: 3...8,
                velocityRange: 100...300,
                angleRange: Angle.degrees(0)...Angle.degrees(360),
                lifetime: 0.6,
                gravity: 50
            )

        case .woodChips:
            return ParticleEmitterConfig(
                particleCount: 50,
                emissionPoint: .zero,
                emissionRadius: 15,
                colors: [Color(hex: "8B4513"), Color(hex: "A0522D"), Color(hex: "D2691E")],
                sizeRange: 4...10,
                velocityRange: 80...200,
                angleRange: Angle.degrees(0)...Angle.degrees(360),
                lifetime: 0.7,
                gravity: 200
            )

        case .iceCrystals:
            return ParticleEmitterConfig(
                particleCount: 60,
                emissionPoint: .zero,
                emissionRadius: 25,
                colors: [.white, Color(hex: "E3F2FD"), Color(hex: "81D4FA")],
                sizeRange: 3...12,
                velocityRange: 60...180,
                angleRange: Angle.degrees(0)...Angle.degrees(360),
                lifetime: 0.8,
                gravity: 30
            )

        case .waterDroplets:
            return ParticleEmitterConfig(
                particleCount: 70,
                emissionPoint: .zero,
                emissionRadius: 30,
                colors: [Color(hex: "1E90FF"), Color(hex: "00CED1"), .white],
                sizeRange: 2...8,
                velocityRange: 100...250,
                angleRange: Angle.degrees(0)...Angle.degrees(360),
                lifetime: 0.6,
                gravity: 300
            )

        case .stardust:
            return ParticleEmitterConfig(
                particleCount: 100,
                emissionPoint: .zero,
                emissionRadius: 40,
                colors: [.white, Color(hex: "FFD700"), Color(hex: "00FFFF"), Color(hex: "FF00FF")],
                sizeRange: 1...6,
                velocityRange: 50...200,
                angleRange: Angle.degrees(0)...Angle.degrees(360),
                lifetime: 1.0,
                gravity: 10
            )
        }
    }
}

// MARK: - Particle Pool

@Observable
class ParticlePool {
    private var availableParticles: [Particle] = []
    private var activeParticles: [Particle] = []
    private let poolSize: Int

    init(poolSize: Int = 500) {
        self.poolSize = poolSize
        preallocateParticles()
    }

    private func preallocateParticles() {
        availableParticles = (0..<poolSize).map { _ in
            Particle(
                position: .zero,
                velocity: .zero,
                acceleration: .zero,
                color: .white,
                size: 4,
                opacity: 1,
                rotation: .zero,
                rotationSpeed: .zero,
                lifetime: 1,
                age: 0
            )
        }
    }

    func spawn(config: ParticleEmitterConfig) {
        for _ in 0..<min(config.particleCount, availableParticles.count) {
            guard var particle = availableParticles.popLast() else { break }

            // Random angle
            let angle = Double.random(
                in: config.angleRange.lowerBound.radians...config.angleRange.upperBound.radians
            )

            // Random velocity magnitude
            let speed = CGFloat.random(in: config.velocityRange)

            // Random offset from emission point
            let offsetAngle = Double.random(in: 0...(2 * .pi))
            let offsetDistance = CGFloat.random(in: 0...config.emissionRadius)

            // Configure particle
            particle.position = CGPoint(
                x: config.emissionPoint.x + cos(offsetAngle) * offsetDistance,
                y: config.emissionPoint.y + sin(offsetAngle) * offsetDistance
            )
            particle.velocity = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed
            )
            particle.acceleration = CGVector(dx: 0, dy: config.gravity)
            particle.color = config.colors.randomElement() ?? .white
            particle.size = CGFloat.random(in: config.sizeRange)
            particle.opacity = 1.0
            particle.rotation = Angle.degrees(Double.random(in: 0...360))
            particle.rotationSpeed = Angle.degrees(Double.random(in: -180...180))
            particle.lifetime = config.lifetime
            particle.age = 0

            activeParticles.append(particle)
        }
    }

    func update(deltaTime: TimeInterval) {
        var deadParticles: [Particle] = []

        for i in 0..<activeParticles.count {
            activeParticles[i].update(deltaTime: deltaTime)

            if !activeParticles[i].isAlive {
                deadParticles.append(activeParticles[i])
            }
        }

        // Remove dead particles and return to pool
        activeParticles.removeAll { particle in
            if !particle.isAlive {
                var recycled = particle
                recycled.age = 0
                availableParticles.append(recycled)
                return true
            }
            return false
        }
    }

    func getActiveParticles() -> [Particle] {
        activeParticles
    }

    func clear() {
        availableParticles.append(contentsOf: activeParticles)
        activeParticles.removeAll()
    }

    var activeCount: Int {
        activeParticles.count
    }

    var availableCount: Int {
        availableParticles.count
    }
}

// MARK: - Particle System Manager

@Observable
final class ParticleSystemManager {
    nonisolated(unsafe) static let shared = ParticleSystemManager()

    private var pool: ParticlePool
    private var lastUpdateTime: Date?

    private init() {
        self.pool = ParticlePool(poolSize: 500)
    }

    /// Emit particles for a specific effect type at a location
    func emit(_ effectType: ParticleEffectType, at point: CGPoint) {
        var config = ParticleEmitterConfig.forEffect(effectType)
        config.emissionPoint = point
        pool.spawn(config: config)
    }

    /// Emit particles with custom configuration
    func emit(config: ParticleEmitterConfig) {
        pool.spawn(config: config)
    }

    /// Update all active particles
    func update() {
        let now = Date()
        let deltaTime: TimeInterval

        if let lastUpdate = lastUpdateTime {
            deltaTime = now.timeIntervalSince(lastUpdate)
        } else {
            deltaTime = 1.0 / 60.0 // Default to 60fps
        }

        lastUpdateTime = now

        // Cap delta time to prevent huge jumps
        let cappedDelta = min(deltaTime, 1.0 / 30.0)
        pool.update(deltaTime: cappedDelta)
    }

    /// Get all currently active particles for rendering
    func getActiveParticles() -> [Particle] {
        pool.getActiveParticles()
    }

    /// Clear all particles
    func clearAll() {
        pool.clear()
        lastUpdateTime = nil
    }

    /// Get pool statistics
    var stats: (active: Int, available: Int) {
        (pool.activeCount, pool.availableCount)
    }
}

// MARK: - Particle View

struct ParticleView: View {
    let particle: Particle

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .opacity(particle.opacity)
            .rotationEffect(particle.rotation)
            .position(particle.position)
    }
}

// MARK: - Particle Layer View

struct ParticleLayerView: View {
    @State private var particles: [Particle] = []
    @State private var updateTimer: Timer?

    let particleManager = ParticleSystemManager.shared

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x - particle.size / 2,
                    y: particle.position.y - particle.size / 2,
                    width: particle.size,
                    height: particle.size
                )

                context.opacity = particle.opacity
                context.fill(
                    Circle().path(in: rect),
                    with: .color(particle.color)
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            startUpdateLoop()
        }
        .onDisappear {
            stopUpdateLoop()
        }
    }

    private func startUpdateLoop() {
        // Use CADisplayLink frequency for smooth updates
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { _ in
            particleManager.update()
            particles = particleManager.getActiveParticles()
        }
    }

    private func stopUpdateLoop() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
}
