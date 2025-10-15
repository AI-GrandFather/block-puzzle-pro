// LineClearAnimations.swift
// Theme-specific line clear animations with particle effects
// Supports cascade physics, combos, and perfect clear celebrations

import Foundation
import SwiftUI
import Observation

// MARK: - Animation Models

struct AnimatedCell: Identifiable {
    let id = UUID()
    var gridPosition: GridPosition
    var screenPosition: CGPoint
    var scale: CGFloat = 1.0
    var opacity: Double = 1.0
    var rotation: Angle = .zero
    var color: Color
}

// NOTE: GridPosition is defined in GridCell.swift

// MARK: - Line Clear Animation Manager

@MainActor
@Observable
final class LineClearAnimationManager {

    // MARK: - Singleton

    static let shared = LineClearAnimationManager()

    // MARK: - Properties

    private let particleManager = ParticleSystemManager.shared
    private let themeManager = AdvancedThemeManager.shared

    // Active animations
    private(set) var clearingCells: [AnimatedCell] = []
    private(set) var cascadingCells: [AnimatedCell] = []
    private(set) var isAnimating = false

    // Combo tracking
    private(set) var currentCombo = 0
    private(set) var comboMultiplier: Double = 1.0

    // Perfect clear
    private(set) var isPerfectClear = false

    // MARK: - Line Clear Animation

    /// Trigger line clear animation
    func animateLineClear(
        cells: [(row: Int, col: Int, color: Color, position: CGPoint)],
        isCombo: Bool = false,
        isPerfect: Bool = false
    ) {
        isAnimating = true
        isPerfectClear = isPerfect

        // Update combo
        if isCombo {
            currentCombo += 1
        } else {
            currentCombo = 0
        }
        comboMultiplier = 1.0 + (Double(currentCombo) * 0.2)

        // Create animated cells
        clearingCells = cells.map { cell in
            AnimatedCell(
                gridPosition: GridPosition(unsafeRow: cell.row, unsafeColumn: cell.col),
                screenPosition: cell.position,
                color: cell.color
            )
        }

        // Perform theme-specific animation
        performLineClearEffect()

        // Complete after animation duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.clearingCells.removeAll()
            self?.isAnimating = false
        }
    }

    private func performLineClearEffect() {
        let theme = themeManager.currentTheme

        switch theme.lineClearEffect {
        case .flashPulse(let color, let duration):
            performFlashPulse(color: color, duration: duration)

        case .electricArc:
            performElectricArc()

        case .woodChips:
            performWoodChips()

        case .crystalShatter:
            performCrystalShatter()

        case .waterSplash:
            performWaterSplash()

        case .supernova:
            performSupernova()
        }

        // Emit particles
        for cell in clearingCells {
            particleManager.emit(theme.particleType, at: cell.screenPosition)
        }
    }

    // MARK: - Effect Implementations

    private func performFlashPulse(color: Color, duration: Double) {
        for i in 0..<clearingCells.count {
            withAnimation(.easeOut(duration: duration)) {
                clearingCells[i].scale = 1.3
                clearingCells[i].opacity = 0.0
            }
        }
    }

    private func performElectricArc() {
        for i in 0..<clearingCells.count {
            let delay = Double(i) * 0.05

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }

                withAnimation(.interpolatingSpring(stiffness: 300, damping: 15)) {
                    self.clearingCells[i].scale = 1.5
                }

                withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                    self.clearingCells[i].opacity = 0.0
                }

                // Extra particles for electric effect
                let particleConfig = ParticleEmitterConfig.forEffect(.electricSparks)
                var config = particleConfig
                config.emissionPoint = self.clearingCells[i].screenPosition
                config.particleCount = 40
                self.particleManager.emit(config: config)
            }
        }
    }

    private func performWoodChips() {
        for i in 0..<clearingCells.count {
            withAnimation(.easeIn(duration: 0.3)) {
                clearingCells[i].rotation = .degrees(Double.random(in: -45...45))
                clearingCells[i].scale = 0.8
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                clearingCells[i].opacity = 0.0
            }
        }
    }

    private func performCrystalShatter() {
        for i in 0..<clearingCells.count {
            // Shatter into pieces
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 10)) {
                clearingCells[i].scale = 1.2
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                clearingCells[i].opacity = 0.0
                clearingCells[i].rotation = .degrees(Double.random(in: -90...90))
            }

            // Extra ice particles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                var config = ParticleEmitterConfig.forEffect(.iceCrystals)
                config.emissionPoint = self.clearingCells[i].screenPosition
                config.particleCount = 50
                self.particleManager.emit(config: config)
            }
        }
    }

    private func performWaterSplash() {
        for i in 0..<clearingCells.count {
            withAnimation(.interpolatingSpring(stiffness: 250, damping: 12)) {
                clearingCells[i].scale = 1.4
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                clearingCells[i].opacity = 0.0
            }
        }
    }

    private func performSupernova() {
        for i in 0..<clearingCells.count {
            let delay = Double(i) * 0.03

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }

                // Expand rapidly
                withAnimation(.interpolatingSpring(stiffness: 400, damping: 10)) {
                    self.clearingCells[i].scale = 2.0
                }

                // Fade with glow
                withAnimation(.easeOut(duration: 0.8)) {
                    self.clearingCells[i].opacity = 0.0
                }

                // Massive particle burst
                var config = ParticleEmitterConfig.forEffect(.stardust)
                config.emissionPoint = self.clearingCells[i].screenPosition
                config.particleCount = 80
                self.particleManager.emit(config: config)
            }
        }
    }

    // MARK: - Cascade Animation

    /// Trigger cascade animation for falling blocks
    func animateCascade(
        fallingBlocks: [(from: (row: Int, col: Int), to: (row: Int, col: Int), color: Color, startPos: CGPoint, endPos: CGPoint)]
    ) {
        cascadingCells = fallingBlocks.map { block in
            AnimatedCell(
                gridPosition: GridPosition(unsafeRow: block.from.row, unsafeColumn: block.from.col),
                screenPosition: block.startPos,
                color: block.color
            )
        }

        // Animate fall with physics
        for i in 0..<cascadingCells.count {
            let endPosition = fallingBlocks[i].endPos
            let distance = abs(endPosition.y - fallingBlocks[i].startPos.y)
            let fallDuration = sqrt(distance / 980) // Simulate gravity

            withAnimation(.timingCurve(0.25, 0.1, 0.25, 1.0, duration: min(fallDuration, 0.5))) {
                cascadingCells[i].screenPosition = endPosition
            }

            // Small bounce on landing
            DispatchQueue.main.asyncAfter(deadline: .now() + min(fallDuration, 0.5)) { [weak self] in
                guard let self = self else { return }

                withAnimation(.interpolatingSpring(stiffness: 600, damping: 20)) {
                    self.cascadingCells[i].scale = 1.1
                }

                withAnimation(.interpolatingSpring(stiffness: 600, damping: 20).delay(0.05)) {
                    self.cascadingCells[i].scale = 1.0
                }
            }
        }

        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.cascadingCells.removeAll()
        }
    }

    // MARK: - Combo Celebration

    /// Trigger combo celebration effect
    func triggerComboCelebration(at position: CGPoint, comboCount: Int) {
        let particleCount: Int
        let duration: Double
        let scale: Double

        // Scale effect based on combo size
        switch comboCount {
        case 2...4:
            particleCount = 30
            duration = 0.4
            scale = 1.2
        case 5...9:
            particleCount = 80
            duration = 0.7
            scale = 1.5
        default: // 10+
            particleCount = 200
            duration = 1.2
            scale = 2.0
        }

        // Create custom particle config
        let theme = themeManager.currentTheme
        var config = ParticleEmitterConfig.forEffect(theme.particleType)
        config.emissionPoint = position
        config.particleCount = particleCount
        config.lifetime = duration
        config.velocityRange = 100...(200 * scale)

        particleManager.emit(config: config)

        // Screen shake for large combos
        if comboCount >= 10 {
            triggerScreenShake(intensity: min(Double(comboCount) / 20.0, 1.0))
        }
    }

    // MARK: - Perfect Clear Animation

    /// Trigger perfect clear celebration
    func triggerPerfectClear(screenSize: CGSize) {
        isPerfectClear = true

        let theme = themeManager.currentTheme

        // Full-screen particle explosion
        let centerPoint = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)

        var config = ParticleEmitterConfig.forEffect(theme.particleType)
        config.emissionPoint = centerPoint
        config.particleCount = 300
        config.emissionRadius = screenSize.width / 2
        config.lifetime = 2.0
        config.velocityRange = 100...400

        particleManager.emit(config: config)

        // Screen shake
        triggerScreenShake(intensity: 1.5)

        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isPerfectClear = false
        }
    }

    // MARK: - Block Placement Ripple

    /// Create ripple effect on block placement
    func createPlacementRipple(at position: CGPoint, color: Color) {
        // Use small particle burst for ripple effect
        let config = ParticleEmitterConfig(
            particleCount: 20,
            emissionPoint: position,
            emissionRadius: 5,
            colors: [color, color.opacity(0.5)],
            sizeRange: 2...6,
            velocityRange: 80...150,
            angleRange: Angle.degrees(0)...Angle.degrees(360),
            lifetime: 0.4,
            gravity: 50
        )

        particleManager.emit(config: config)
    }

    // MARK: - Screen Shake

    private func triggerScreenShake(intensity: Double) {
        // Post notification for view to handle shake
        NotificationCenter.default.post(
            name: .screenShake,
            object: nil,
            userInfo: ["intensity": intensity]
        )
    }

    // MARK: - Utility

    func reset() {
        clearingCells.removeAll()
        cascadingCells.removeAll()
        currentCombo = 0
        comboMultiplier = 1.0
        isPerfectClear = false
        isAnimating = false
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let screenShake = Notification.Name("screenShake")
}

// MARK: - Line Clear View Overlay

struct LineClearOverlayView: View {
    @State private var animationManager = LineClearAnimationManager.shared

    var body: some View {
        ZStack {
            // Clearing cells
            ForEach(animationManager.clearingCells) { cell in
                RoundedRectangle(cornerRadius: 8)
                    .fill(cell.color)
                    .frame(width: 40, height: 40)
                    .scaleEffect(cell.scale)
                    .opacity(cell.opacity)
                    .rotationEffect(cell.rotation)
                    .position(cell.screenPosition)
                    .shadow(color: cell.color.opacity(0.5), radius: cell.scale * 10)
            }

            // Cascading cells
            ForEach(animationManager.cascadingCells) { cell in
                RoundedRectangle(cornerRadius: 8)
                    .fill(cell.color)
                    .frame(width: 40, height: 40)
                    .scaleEffect(cell.scale)
                    .position(cell.screenPosition)
            }

            // Combo indicator
            if animationManager.currentCombo > 1 {
                VStack {
                    Spacer()
                    Text("\(animationManager.currentCombo)x COMBO!")
                        .font(.system(size: 40 + CGFloat(animationManager.currentCombo) * 2, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .transition(.scale.combined(with: .opacity))
                    Spacer()
                }
                .padding()
            }

            // Perfect clear indicator
            if animationManager.isPerfectClear {
                VStack {
                    Spacer()
                    Text("PERFECT!")
                        .font(.system(size: 60, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .yellow, .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.8), radius: 20)
                        .transition(.scale(scale: 2.0).combined(with: .opacity))
                    Spacer()
                }
                .padding()
            }
        }
        .allowsHitTesting(false)
    }
}
