import Foundation
import SpriteKit
import SwiftUI
import Observation
import UIKit

// MARK: - FX Context & Event Models

struct FXContext {
    let reduceMotion: Bool
    let comboCount: Int      // 0 for single; 1 for double; etc.
    let streakLevel: Int
    let boardSize: CGSize
}

struct BoardGeometry: Equatable {
    let gridSize: Int
    let cellSize: CGFloat
    let spacing: CGFloat
    let boardSize: CGSize

    var cellSpan: CGFloat {
        cellSize + spacing
    }

    var halfCell: CGFloat {
        cellSize / 2
    }
}

struct ClearedCell {
    let row: Int
    let column: Int
    let color: UIColor
}

enum EffectsEvent {
    case lineClear(rows: [Int], cols: [Int], clearedCells: [ClearedCell], origin: CGPoint, timestamp: TimeInterval)
    case streakChanged(level: Int, isActive: Bool, timestamp: TimeInterval)
    case perfectClear(origin: CGPoint, timestamp: TimeInterval)
}

// MARK: - Effects Engine

@MainActor
@Observable
final class EffectsEngine {

    static let shared = EffectsEngine()

    private(set) var comboLevel: Int = 0
    private(set) var streakLevel: Int = 0
    private(set) var isPerfectClearActive: Bool = false

    var reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled {
        didSet {
            scene?.reduceMotion = reduceMotion
        }
    }

    private weak var scene: EffectsScene?
    private var boardGeometry: BoardGeometry? {
        didSet {
            scene?.boardGeometry = boardGeometry
        }
    }

    private let feedback = FeedbackCoordinator.shared
    private var comboResetWorkItem: DispatchWorkItem?
    private var perfectClearResetWorkItem: DispatchWorkItem?

    private init() {}

    fileprivate func configure(scene: EffectsScene, geometry: BoardGeometry) {
        self.scene = scene
        self.boardGeometry = geometry
        scene.boardGeometry = geometry
        scene.reduceMotion = reduceMotion
        scene.size = geometry.boardSize
    }

    func updateBoardGeometry(_ geometry: BoardGeometry) {
        boardGeometry = geometry
        scene?.boardGeometry = geometry
        scene?.size = geometry.boardSize
    }

    func trigger(_ event: EffectsEvent, ctx: FXContext) {
        reduceMotion = ctx.reduceMotion

        switch event {
        case let .lineClear(rows, cols, clearedCells, origin, timestamp):
            comboLevel = ctx.comboCount
            scheduleComboReset(ifNeededFor: ctx.comboCount)

            let totalLines = rows.count + cols.count
            feedback.trigger(.lineClear(count: max(totalLines, 1)))
            if ctx.comboCount > 0 {
                feedback.trigger(.combo(level: ctx.comboCount + 1))
            }
            if totalLines >= 3 && !reduceMotion {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
                    self.feedback.haptics.trigger(.piecePlacement)
                }
            }

            scene?.playLineClear(
                rows: rows,
                cols: cols,
                clearedCells: clearedCells,
                context: ctx,
                origin: origin,
                timestamp: timestamp
            )

        case let .streakChanged(level, isActive, timestamp):
            streakLevel = isActive ? level : 0
            scene?.playStreak(level: level, isActive: isActive, context: ctx, timestamp: timestamp)

        case let .perfectClear(origin, timestamp):
            isPerfectClearActive = true
            feedback.trigger(.perfectClear)
            schedulePerfectClearReset()

            scene?.playPerfectClear(origin: origin, context: ctx, timestamp: timestamp)
        }
    }

    private func scheduleComboReset(ifNeededFor combo: Int) {
        comboResetWorkItem?.cancel()
        guard combo > 0 else {
            comboLevel = 0
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.comboLevel = 0
        }
        comboResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: workItem)
    }

    private func schedulePerfectClearReset() {
        perfectClearResetWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.isPerfectClearActive = false
        }
        perfectClearResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }
}

typealias LineClearAnimationManager = EffectsEngine

// MARK: - SpriteKit Overlay View

struct LineClearOverlayView: View {
    let geometry: BoardGeometry

    @State private var scene = EffectsScene(size: .zero)
    @State private var reduceMotion = UIAccessibility.isReduceMotionEnabled
    @State private var reduceMotionObserver: NSObjectProtocol?

    var body: some View {
        SpriteView(scene: scene, options: [.allowsTransparency])
            .ignoresSafeArea()
            .background(Color.clear)
            .onAppear {
                configureScene()
                observeReduceMotion()
            }
            .onDisappear {
                if let observer = reduceMotionObserver {
                    NotificationCenter.default.removeObserver(observer)
                    reduceMotionObserver = nil
                }
            }
            .onChange(of: geometry) { _, newValue in
                EffectsEngine.shared.updateBoardGeometry(newValue)
            }
            .onChange(of: reduceMotion) { _, newValue in
                EffectsEngine.shared.reduceMotion = newValue
            }
    }

    private func configureScene() {
        scene.scaleMode = .resizeFill
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.backgroundColor = .clear
        scene.isPaused = false
        scene.size = geometry.boardSize
        scene.boardGeometry = geometry
        scene.reduceMotion = reduceMotion
        scene.view?.allowsTransparency = true
        scene.view?.backgroundColor = .clear
        EffectsEngine.shared.configure(scene: scene, geometry: geometry)
    }

    private func observeReduceMotion() {
        reduceMotionObserver = NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                reduceMotion = UIAccessibility.isReduceMotionEnabled
            }
        }
    }
}

// MARK: - SpriteKit Scene Implementation

fileprivate final class EffectsScene: SKScene {

    var boardGeometry: BoardGeometry?
    var reduceMotion: Bool = false

    private let effectRoot = SKNode()
    private let borderNode = SKShapeNode()
    private let neonDashPalette: [UIColor] = [
        UIColor(red: 0.56, green: 0.95, blue: 1.0, alpha: 1.0),
        UIColor(red: 1.0, green: 0.36, blue: 0.92, alpha: 1.0),
        UIColor(red: 0.59, green: 0.78, blue: 1.0, alpha: 1.0)
    ]
    private enum LineClearStyle {
        case prism
        case afterglow
        case neon
    }
    private lazy var cameraNode: SKCameraNode = {
        let camera = SKCameraNode()
        camera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(camera)
        self.camera = camera
        return camera
    }()

    override init(size: CGSize) {
        super.init(size: size)
        setupScene()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupScene()
    }

    private func setupScene() {
        backgroundColor = .clear
        effectRoot.zPosition = 10
        addChild(effectRoot)

        borderNode.lineWidth = 4
        borderNode.strokeColor = UIColor.white.withAlphaComponent(0.25)
        borderNode.fillColor = .clear
        borderNode.zPosition = 5
        borderNode.alpha = 0
        effectRoot.addChild(borderNode)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        updateBorderPath()
    }

    func playLineClear(rows: [Int], cols: [Int], clearedCells: [ClearedCell], context: FXContext, origin: CGPoint, timestamp: TimeInterval) {
        guard let geometry = boardGeometry else { return }

        updateBorderPath()

        let totalLines = max(rows.count + cols.count, 1)
        let sweepPalette = sweepColors(for: totalLines)

        for cell in clearedCells {
            spawnPopShrink(for: cell, geometry: geometry, context: context)
            spawnSparkle(for: cell, geometry: geometry, context: context)
            if totalLines == 1 {
                spawnGlowHalo(for: cell, geometry: geometry)
            }
        }

        guard totalLines >= 2 else {
            return
        }

        let travelDuration: TimeInterval = totalLines == 2 ? 0.34 : 0.36
        let sweepAlpha: CGFloat = totalLines == 2 ? 0.55 : 0.62
        let primaryColor = sweepPalette.first ?? UIColor.white

        let style: LineClearStyle
        if context.streakLevel > 0 {
            style = .neon
        } else if totalLines >= 3 {
            style = .afterglow
        } else {
            style = .prism
        }

        let sortedRows = rows.sorted()
        let sortedColumns = cols.sorted()

        switch style {
        case .prism:
            for (index, row) in sortedRows.enumerated() {
                spawnPrismBladeRow(
                    row: row,
                    color: primaryColor,
                    geometry: geometry,
                    alpha: sweepAlpha,
                    travelDuration: travelDuration,
                    delay: Double(index) * 0.04
                )
            }

            for (index, column) in sortedColumns.enumerated() {
                spawnPrismBladeColumn(
                    column: column,
                    color: primaryColor,
                    geometry: geometry,
                    alpha: sweepAlpha,
                    travelDuration: travelDuration,
                    delay: Double(index) * 0.04
                )
            }

        case .afterglow:
            for (index, row) in sortedRows.enumerated() {
                spawnAfterglowPulseRow(
                    row: row,
                    color: primaryColor,
                    geometry: geometry,
                    travelDuration: travelDuration,
                    delay: Double(index) * 0.05
                )
            }

            for (index, column) in sortedColumns.enumerated() {
                spawnAfterglowPulseColumn(
                    column: column,
                    color: primaryColor,
                    geometry: geometry,
                    travelDuration: travelDuration,
                    delay: Double(index) * 0.05
                )
            }

        case .neon:
            for (index, row) in sortedRows.enumerated() {
                spawnNeonStitchRow(
                    row: row,
                    geometry: geometry,
                    delay: Double(index) * 0.05
                )
            }

            for (index, column) in sortedColumns.enumerated() {
                spawnNeonStitchColumn(
                    column: column,
                    geometry: geometry,
                    delay: Double(index) * 0.05
                )
            }
        }

        if style != .neon {
            spawnStarbursts(
                rows: rows,
                cols: cols,
                geometry: geometry,
                context: context,
                totalLines: totalLines
            )
        }

        if totalLines >= 2 && !reduceMotion {
            triggerCameraShake()
        }
    }

    func playStreak(level: Int, isActive: Bool, context: FXContext, timestamp: TimeInterval) {
        guard boardGeometry != nil else { return }
        updateBorderPath()

        guard isActive else {
            borderNode.removeAllActions()
            let fadeOut = SKAction.fadeOut(withDuration: 0.2)
            borderNode.run(fadeOut)
            return
        }

        let targetAlpha = min(0.1 + CGFloat(level) * 0.05, 0.3)
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: targetAlpha, duration: 0.18),
            SKAction.fadeAlpha(to: targetAlpha * 0.6, duration: 0.18)
        ])
        borderNode.removeAllActions()
        borderNode.run(SKAction.repeatForever(pulse))

        if !reduceMotion {
            let scale = 1.02 + CGFloat(level) * 0.01
            let scaleUp = SKAction.scale(to: scale, duration: 0.2)
            scaleUp.timingMode = .easeOut
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.25)
            scaleDown.timingMode = .easeIn
            let sequence = SKAction.sequence([scaleUp, scaleDown])
            effectRoot.removeAction(forKey: "borderPulse")
            effectRoot.run(sequence, withKey: "borderPulse")
        }
    }

    func playPerfectClear(origin: CGPoint, context: FXContext, timestamp: TimeInterval) {
        guard let geometry = boardGeometry else { return }

        let center = CGPoint(x: geometry.boardSize.width / 2, y: geometry.boardSize.height / 2)
        spawnGridWaveFlash(center: center, geometry: geometry, context: context)
        spawnVacuumCollapse(center: center, geometry: geometry, context: context)
        spawnConfetti(center: center, geometry: geometry, context: context)
    }

    // MARK: - Helpers

    private func position(for cell: ClearedCell, geometry: BoardGeometry) -> CGPoint {
        let x = geometry.spacing + geometry.halfCell + CGFloat(cell.column) * geometry.cellSpan
        let yTop = geometry.spacing + geometry.halfCell + CGFloat(cell.row) * geometry.cellSpan
        let y = geometry.boardSize.height - yTop
        return CGPoint(x: x, y: y)
    }

    private func center(forRow row: Int, geometry: BoardGeometry) -> CGPoint {
        let x = geometry.boardSize.width / 2
        let yTop = geometry.spacing + geometry.halfCell + CGFloat(row) * geometry.cellSpan
        let y = geometry.boardSize.height - yTop
        return CGPoint(x: x, y: y)
    }

    private func center(forColumn column: Int, geometry: BoardGeometry) -> CGPoint {
        let x = geometry.spacing + geometry.halfCell + CGFloat(column) * geometry.cellSpan
        let y = geometry.boardSize.height / 2
        return CGPoint(x: x, y: y)
    }

    private func spawnPopShrink(for cell: ClearedCell, geometry: BoardGeometry, context: FXContext) {
        let size = CGSize(width: geometry.cellSize, height: geometry.cellSize)
        let node = SKShapeNode(rectOf: size, cornerRadius: geometry.cellSize * 0.22)
        node.fillColor = cell.color
        node.strokeColor = UIColor.white.withAlphaComponent(0.15)
        node.lineWidth = 1.2
        node.position = position(for: cell, geometry: geometry)
        node.zPosition = 20
        node.alpha = reduceMotion ? 0.9 : 1.0
        node.setScale(reduceMotion ? 1.0 : 0.9)
        effectRoot.addChild(node)

        if reduceMotion {
            let fadeOut = SKAction.sequence([
                SKAction.wait(forDuration: 0.1),
                SKAction.fadeAlpha(to: 0.0, duration: 0.25),
                SKAction.removeFromParent()
            ])
            node.run(fadeOut)
            return
        }

        let expand = SKAction.scale(to: 1.1, duration: 0.08)
        expand.timingMode = .easeOut

        let collapse = SKAction.scale(to: 0.0, duration: 0.08)
        collapse.timingMode = .easeIn

        let fade = SKAction.fadeOut(withDuration: 0.08)

        let sequence = SKAction.sequence([
            expand,
            SKAction.group([collapse, fade]),
            SKAction.removeFromParent()
        ])
        node.run(sequence)
    }

    private func spawnSparkle(for cell: ClearedCell, geometry: BoardGeometry, context: FXContext) {
        guard let texture = sparkleTexture() else { return }

        let emitter = SKEmitterNode()
        emitter.particleTexture = texture
        emitter.particleColor = UIColor.white
        emitter.particleColorBlendFactor = 1.0
        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.numParticlesToEmit = reduceMotion ? Int.random(in: 3...4) : Int.random(in: 6...10)
        emitter.particleBirthRate = 240
        emitter.particleLifetime = reduceMotion ? 0.18 : 0.25
        emitter.particleLifetimeRange = 0.08
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = reduceMotion ? 60 : 110
        emitter.particleSpeedRange = 40
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -3.5
        emitter.particleScale = reduceMotion ? 0.5 : 0.8
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -1.8
        emitter.particlePosition = position(for: cell, geometry: geometry)
        emitter.zPosition = 25
        effectRoot.addChild(emitter)

        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(emitter.particleLifetime + 0.2)),
            SKAction.removeFromParent()
        ])
        emitter.run(cleanup)
    }

    private func spawnGlowHalo(for cell: ClearedCell, geometry: BoardGeometry) {
        guard !reduceMotion else { return }

        let size = CGSize(
            width: geometry.cellSize + geometry.spacing * 0.4,
            height: geometry.cellSize + geometry.spacing * 0.4
        )
        let node = SKShapeNode(rectOf: size, cornerRadius: geometry.cellSize * 0.3)
        node.fillColor = cell.color.withAlphaComponent(0.18)
        node.strokeColor = cell.color.withAlphaComponent(0.35)
        node.lineWidth = 1.0
        node.position = position(for: cell, geometry: geometry)
        node.zPosition = 15
        node.alpha = 0
        node.setScale(0.85)
        effectRoot.addChild(node)

        let fadeIn = SKAction.group([
            SKAction.fadeAlpha(to: 0.6, duration: 0.08),
            SKAction.scale(to: 1.05, duration: 0.08)
        ])
        fadeIn.timingMode = .easeOut

        let fadeOut = SKAction.group([
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.scale(to: 1.2, duration: 0.18)
        ])
        fadeOut.timingMode = .easeIn

        let sequence = SKAction.sequence([fadeIn, fadeOut, SKAction.removeFromParent()])
        node.run(sequence)
    }

    private func spawnPrismBladeRow(
        row: Int,
        color: UIColor,
        geometry: BoardGeometry,
        alpha: CGFloat,
        travelDuration: TimeInterval,
        delay: TimeInterval
    ) {
        if reduceMotion {
            spawnStaticHighlightRow(row: row, geometry: geometry, baseColor: color)
            return
        }

        let height = geometry.cellSize * 0.35
        let length = geometry.cellSize * 1.18
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -length * 0.5, y: -height / 2))
        path.addLine(to: CGPoint(x: length * 0.5, y: 0))
        path.addLine(to: CGPoint(x: -length * 0.5, y: height / 2))
        path.close()

        let blade = SKShapeNode(path: path.cgPath)
        blade.fillColor = color
        blade.strokeColor = UIColor.clear
        blade.glowWidth = 6
        blade.alpha = alpha
        blade.zPosition = 18
        blade.blendMode = .add

        let centerPoint = center(forRow: row, geometry: geometry)
        blade.position = CGPoint(x: -geometry.cellSize, y: centerPoint.y)
        effectRoot.addChild(blade)

        let head = SKShapeNode(circleOfRadius: geometry.cellSize * 0.18)
        head.fillColor = UIColor.white.withAlphaComponent(0.9)
        head.strokeColor = UIColor.clear
        head.glowWidth = 8
        head.position = CGPoint(x: length * 0.5, y: 0)
        head.blendMode = .add
        blade.addChild(head)

        let endX = geometry.boardSize.width + geometry.cellSize
        let travel = SKAction.moveTo(x: endX, duration: travelDuration)
        travel.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.18)
        fadeOut.timingMode = .easeIn
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([
                travel,
                SKAction.sequence([
                    SKAction.wait(forDuration: travelDuration * 0.72),
                    fadeOut
                ])
            ]),
            SKAction.removeFromParent()
        ])
        blade.run(sequence)
    }

    private func spawnPrismBladeColumn(
        column: Int,
        color: UIColor,
        geometry: BoardGeometry,
        alpha: CGFloat,
        travelDuration: TimeInterval,
        delay: TimeInterval
    ) {
        if reduceMotion {
            spawnStaticHighlightColumn(column: column, geometry: geometry, baseColor: color)
            return
        }

        let width = geometry.cellSize * 0.35
        let length = geometry.cellSize * 1.18
        let path = UIBezierPath()
        path.move(to: CGPoint(x: -length * 0.5, y: -width / 2))
        path.addLine(to: CGPoint(x: length * 0.5, y: 0))
        path.addLine(to: CGPoint(x: -length * 0.5, y: width / 2))
        path.close()

        let blade = SKShapeNode(path: path.cgPath)
        blade.fillColor = color
        blade.strokeColor = UIColor.clear
        blade.glowWidth = 6
        blade.alpha = alpha
        blade.zPosition = 18
        blade.blendMode = .add
        blade.zRotation = .pi / 2

        let centerPoint = center(forColumn: column, geometry: geometry)
        blade.position = CGPoint(x: centerPoint.x, y: -geometry.cellSize)
        effectRoot.addChild(blade)

        let head = SKShapeNode(circleOfRadius: geometry.cellSize * 0.18)
        head.fillColor = UIColor.white.withAlphaComponent(0.9)
        head.strokeColor = UIColor.clear
        head.glowWidth = 8
        head.position = CGPoint(x: length * 0.5, y: 0)
        head.blendMode = .add
        blade.addChild(head)

        let endY = geometry.boardSize.height + geometry.cellSize
        let travel = SKAction.moveTo(y: endY, duration: travelDuration)
        travel.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.18)
        fadeOut.timingMode = .easeIn
        let sequence = SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([
                travel,
                SKAction.sequence([
                    SKAction.wait(forDuration: travelDuration * 0.72),
                    fadeOut
                ])
            ]),
            SKAction.removeFromParent()
        ])
        blade.run(sequence)
    }

    private func spawnStaticHighlightRow(row: Int, geometry: BoardGeometry, baseColor: UIColor) {
        let width = geometry.boardSize.width
        let height = geometry.cellSize * 0.9
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: geometry.cellSize * 0.25)
        node.fillColor = baseColor.withAlphaComponent(0.2)
        node.strokeColor = baseColor.withAlphaComponent(0.3)
        node.alpha = 0
        node.position = center(forRow: row, geometry: geometry)
        node.zPosition = 15
        effectRoot.addChild(node)

        let sequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.28, duration: 0.08),
            SKAction.wait(forDuration: 0.12),
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.removeFromParent()
        ])
        node.run(sequence)
    }

    private func spawnStaticHighlightColumn(column: Int, geometry: BoardGeometry, baseColor: UIColor) {
        let width = geometry.cellSize * 0.9
        let height = geometry.boardSize.height
        let node = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: geometry.cellSize * 0.25)
        node.fillColor = baseColor.withAlphaComponent(0.2)
        node.strokeColor = baseColor.withAlphaComponent(0.3)
        node.alpha = 0
        node.position = center(forColumn: column, geometry: geometry)
        node.zPosition = 15
        effectRoot.addChild(node)

        let sequence = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.28, duration: 0.08),
            SKAction.wait(forDuration: 0.12),
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.removeFromParent()
        ])
        node.run(sequence)
    }

    private func spawnAfterglowPulseRow(row: Int, color: UIColor, geometry: BoardGeometry, travelDuration: TimeInterval, delay: TimeInterval) {
        if reduceMotion {
            spawnStaticHighlightRow(row: row, geometry: geometry, baseColor: color)
            return
        }

        let beam = SKShapeNode(rectOf: CGSize(width: geometry.cellSize * 0.24, height: geometry.cellSize * 0.88), cornerRadius: geometry.cellSize * 0.3)
        beam.fillColor = color.withAlphaComponent(0.95)
        beam.strokeColor = UIColor.clear
        beam.glowWidth = 5
        beam.blendMode = .add
        let centerPoint = center(forRow: row, geometry: geometry)
        beam.position = CGPoint(x: -geometry.cellSize, y: centerPoint.y)
        beam.zPosition = 18
        effectRoot.addChild(beam)

        let travel = SKAction.moveTo(x: geometry.boardSize.width + geometry.cellSize, duration: travelDuration)
        travel.timingMode = .easeOut
        let fade = SKAction.sequence([
            SKAction.wait(forDuration: travelDuration * 0.65),
            SKAction.fadeOut(withDuration: 0.24)
        ])
        beam.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([travel, fade]),
            SKAction.removeFromParent()
        ]))

        let overlay = SKShapeNode(rectOf: CGSize(width: geometry.boardSize.width, height: geometry.cellSize * 0.5), cornerRadius: geometry.cellSize * 0.25)
        overlay.fillColor = color.withAlphaComponent(0.18)
        overlay.strokeColor = color.withAlphaComponent(0.28)
        overlay.alpha = 0
        overlay.position = CGPoint(x: geometry.boardSize.width / 2, y: centerPoint.y)
        overlay.zPosition = 16
        effectRoot.addChild(overlay)

        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: delay + travelDuration * 0.5),
            SKAction.fadeAlpha(to: 0.32, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.24),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnAfterglowPulseColumn(column: Int, color: UIColor, geometry: BoardGeometry, travelDuration: TimeInterval, delay: TimeInterval) {
        if reduceMotion {
            spawnStaticHighlightColumn(column: column, geometry: geometry, baseColor: color)
            return
        }

        let beam = SKShapeNode(rectOf: CGSize(width: geometry.cellSize * 0.88, height: geometry.cellSize * 0.24), cornerRadius: geometry.cellSize * 0.3)
        beam.fillColor = color.withAlphaComponent(0.95)
        beam.strokeColor = UIColor.clear
        beam.glowWidth = 5
        beam.blendMode = .add
        let centerPoint = center(forColumn: column, geometry: geometry)
        beam.position = CGPoint(x: centerPoint.x, y: -geometry.cellSize)
        beam.zPosition = 18
        effectRoot.addChild(beam)

        let travel = SKAction.moveTo(y: geometry.boardSize.height + geometry.cellSize, duration: travelDuration)
        travel.timingMode = .easeOut
        let fade = SKAction.sequence([
            SKAction.wait(forDuration: travelDuration * 0.65),
            SKAction.fadeOut(withDuration: 0.24)
        ])
        beam.run(SKAction.sequence([
            SKAction.wait(forDuration: delay),
            SKAction.group([travel, fade]),
            SKAction.removeFromParent()
        ]))

        let overlay = SKShapeNode(rectOf: CGSize(width: geometry.cellSize * 0.5, height: geometry.boardSize.height), cornerRadius: geometry.cellSize * 0.25)
        overlay.fillColor = color.withAlphaComponent(0.18)
        overlay.strokeColor = color.withAlphaComponent(0.28)
        overlay.alpha = 0
        overlay.position = CGPoint(x: centerPoint.x, y: geometry.boardSize.height / 2)
        overlay.zPosition = 16
        effectRoot.addChild(overlay)

        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: delay + travelDuration * 0.5),
            SKAction.fadeAlpha(to: 0.32, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.24),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnNeonStitchRow(row: Int, geometry: BoardGeometry, delay: TimeInterval) {
        if reduceMotion {
            spawnStaticHighlightRow(row: row, geometry: geometry, baseColor: UIColor.white)
            return
        }

        let dashCount = 6
        let centerPoint = center(forRow: row, geometry: geometry)
        let startX = -geometry.cellSize
        let endX = geometry.boardSize.width + geometry.cellSize

        for i in 0..<dashCount {
            let dash = SKShapeNode(rectOf: CGSize(width: geometry.cellSize * 0.32, height: geometry.cellSize * 0.18), cornerRadius: geometry.cellSize * 0.09)
            let color = neonDashPalette[i % neonDashPalette.count]
            dash.fillColor = color
            dash.strokeColor = color
            dash.glowWidth = 6
            dash.alpha = 0
            dash.blendMode = .add
            dash.position = CGPoint(x: startX - CGFloat(i) * 12, y: centerPoint.y)
            effectRoot.addChild(dash)

            let wait = SKAction.wait(forDuration: delay + Double(i) * 0.05)
            let move = SKAction.moveTo(x: endX, duration: 0.28)
            move.timingMode = .easeOut
            let fadeSequence = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.05),
                SKAction.wait(forDuration: 0.14),
                SKAction.fadeOut(withDuration: 0.1)
            ])
            dash.run(SKAction.sequence([wait, SKAction.group([move, fadeSequence]), SKAction.removeFromParent()]))
        }

        spawnStaticHighlightRow(row: row, geometry: geometry, baseColor: UIColor.white)
    }

    private func spawnNeonStitchColumn(column: Int, geometry: BoardGeometry, delay: TimeInterval) {
        if reduceMotion {
            spawnStaticHighlightColumn(column: column, geometry: geometry, baseColor: UIColor.white)
            return
        }

        let dashCount = 6
        let centerPoint = center(forColumn: column, geometry: geometry)
        let startY = -geometry.cellSize
        let endY = geometry.boardSize.height + geometry.cellSize

        for i in 0..<dashCount {
            let dash = SKShapeNode(rectOf: CGSize(width: geometry.cellSize * 0.18, height: geometry.cellSize * 0.32), cornerRadius: geometry.cellSize * 0.09)
            let color = neonDashPalette[i % neonDashPalette.count]
            dash.fillColor = color
            dash.strokeColor = color
            dash.glowWidth = 6
            dash.alpha = 0
            dash.blendMode = .add
            dash.position = CGPoint(x: centerPoint.x, y: startY - CGFloat(i) * 12)
            effectRoot.addChild(dash)

            let wait = SKAction.wait(forDuration: delay + Double(i) * 0.05)
            let move = SKAction.moveTo(y: endY, duration: 0.28)
            move.timingMode = .easeOut
            let fadeSequence = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.05),
                SKAction.wait(forDuration: 0.14),
                SKAction.fadeOut(withDuration: 0.1)
            ])
            dash.run(SKAction.sequence([wait, SKAction.group([move, fadeSequence]), SKAction.removeFromParent()]))
        }

        spawnStaticHighlightColumn(column: column, geometry: geometry, baseColor: UIColor.white)
    }

    private func spawnStarbursts(
        rows: [Int],
        cols: [Int],
        geometry: BoardGeometry,
        context: FXContext,
        totalLines: Int
    ) {
        guard !rows.isEmpty, !cols.isEmpty else { return }

        let maxBursts = 6
        var bursts: [CGPoint] = []

        for row in rows {
            for column in cols {
                let point = CGPoint(
                    x: geometry.spacing + geometry.halfCell + CGFloat(column) * geometry.cellSpan,
                    y: geometry.boardSize.height - (geometry.spacing + geometry.halfCell + CGFloat(row) * geometry.cellSpan)
                )
                bursts.append(point)
            }
        }

        if bursts.count > maxBursts {
            bursts = Array(bursts.prefix(maxBursts))
        }

        for point in bursts {
            spawnStarburst(at: point, intensity: totalLines)
        }
    }

    private func spawnStarburst(at position: CGPoint, intensity: Int) {
        let rays = reduceMotion ? 6 : 12
        let radius: CGFloat = reduceMotion ? 26 : (intensity >= 3 ? 46 : 40)
        let path = UIBezierPath()

        for index in 0..<rays {
            let angle = CGFloat(index) / CGFloat(rays) * CGFloat.pi * 2
            path.move(to: .zero)
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            path.addLine(to: point)
        }

        let node = SKShapeNode(path: path.cgPath)
        node.strokeColor = UIColor.white.withAlphaComponent(intensity >= 3 ? 0.7 : 0.6)
        node.lineWidth = 1.6
        node.position = position
        node.zPosition = 26
        node.alpha = 0
        effectRoot.addChild(node)

        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.06)
        fadeIn.timingMode = .easeOut
        let fadeOut = SKAction.fadeOut(withDuration: 0.22)
        fadeOut.timingMode = .easeIn
        let sequence = SKAction.sequence([fadeIn, fadeOut, SKAction.removeFromParent()])
        node.run(sequence)
    }

    private func triggerCameraShake() {
        effectRoot.removeAction(forKey: "microShake")
        let amplitude: CGFloat = 2.0
        let duration: TimeInterval = 0.18
        let shakes = 6
        var actions: [SKAction] = []

        for i in 0..<shakes {
            let progress = CGFloat(i) / CGFloat(shakes)
            let decay = (1.0 - progress)
            let dx = CGFloat.random(in: -amplitude...amplitude) * decay
            let dy = CGFloat.random(in: -amplitude...amplitude) * decay
            let move = SKAction.moveBy(x: dx, y: dy, duration: duration / Double(shakes))
            move.timingMode = .easeInEaseOut
            actions.append(move)
        }

        actions.append(SKAction.moveTo(x: 0, duration: 0.02))
        actions.append(SKAction.moveTo(y: 0, duration: 0.02))
        let sequence = SKAction.sequence(actions)
        effectRoot.run(sequence, withKey: "microShake")
    }

    private func spawnGridWaveFlash(center: CGPoint, geometry: BoardGeometry, context: FXContext) {
        let maxRadius = max(geometry.boardSize.width, geometry.boardSize.height) * 0.75
        let node = SKShapeNode(circleOfRadius: 4)
        node.fillColor = UIColor.white.withAlphaComponent(0.35)
        node.strokeColor = UIColor.white.withAlphaComponent(0.25)
        node.lineWidth = 3
        node.position = center
        node.zPosition = 22
        effectRoot.addChild(node)

        if reduceMotion {
            let fade = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.7, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.25),
                SKAction.removeFromParent()
            ])
            node.run(fade)
            return
        }

        let scale = SKAction.scale(to: maxRadius / 4, duration: 0.38)
        scale.timingMode = .easeOut
        let fade = SKAction.fadeOut(withDuration: 0.25)
        fade.timingMode = .easeIn
        node.run(SKAction.sequence([scale, fade, SKAction.removeFromParent()]))
    }

    private func spawnVacuumCollapse(center: CGPoint, geometry: BoardGeometry, context: FXContext) {
        let size = CGSize(width: geometry.boardSize.width * 0.9, height: geometry.boardSize.height * 0.9)
        let node = SKShapeNode(rectOf: size, cornerRadius: 24)
        node.fillColor = UIColor.white.withAlphaComponent(0.12)
        node.strokeColor = UIColor.white.withAlphaComponent(0.2)
        node.lineWidth = 2
        node.position = center
        node.zPosition = 19
        effectRoot.addChild(node)

        if reduceMotion {
            node.alpha = 0.0
            let fade = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.15, duration: 0.1),
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.removeFromParent()
            ])
            node.run(fade)
            return
        }

        node.alpha = 0.22
        let collapse = SKAction.scale(to: 0.24, duration: 0.38)
        collapse.timingMode = .easeIn
        let fade = SKAction.fadeOut(withDuration: 0.12)
        let sequence = SKAction.sequence([collapse, fade, SKAction.removeFromParent()])
        node.run(sequence)
    }

    private func spawnConfetti(center: CGPoint, geometry: BoardGeometry, context: FXContext) {
        let emitter = SKEmitterNode()
        emitter.particleTexture = sparkleTexture()
        emitter.particleColorBlendFactor = 1
        let colors = confettiColors()
        let times = colors.indices.map { index in
            NSNumber(value: Double(index) / Double(max(colors.count - 1, 1)))
        }
        emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: colors, times: times)
        emitter.numParticlesToEmit = context.reduceMotion ? Int.random(in: 40...60) : Int.random(in: 160...220)
        emitter.particleBirthRate = 600
        emitter.particleLifetime = context.reduceMotion ? 0.4 : 0.8
        emitter.particleLifetimeRange = context.reduceMotion ? 0.1 : 0.3
        emitter.particleSpeed = context.reduceMotion ? 140 : 220
        emitter.particleSpeedRange = context.reduceMotion ? 60 : 120
        emitter.emissionAngleRange = .pi
        emitter.emissionAngle = .pi / 2
        emitter.particleAlpha = 0.95
        emitter.particleAlphaRange = 0.2
        emitter.particleAlphaSpeed = -1.8
        emitter.particleScale = context.reduceMotion ? 0.4 : 0.6
        emitter.particleScaleRange = 0.3
        emitter.particleScaleSpeed = -0.5
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi
        emitter.particleRotationSpeed = .pi * 1.5
        emitter.position = center
        emitter.particlePositionRange = CGVector(dx: geometry.boardSize.width * 0.3, dy: 20)
        emitter.zPosition = 28
        effectRoot.addChild(emitter)

        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(emitter.particleLifetime + 0.5)),
            SKAction.removeFromParent()
        ])
        emitter.run(cleanup)
    }

    private func sweepColors(for totalLines: Int) -> [UIColor] {
        switch totalLines {
        case 1:
            return [UIColor(hex: "#77E6FF"), UIColor(hex: "#A7F3FF")]
        case 2:
            return [UIColor(hex: "#5DF097"), UIColor(hex: "#ABF5C6")]
        default:
            return [UIColor(hex: "#FFD166"), UIColor(hex: "#FFE599")]
        }
    }

    private func gradientNode(size: CGSize, colors: [UIColor], horizontal: Bool) -> SKSpriteNode {
        let texture = gradientTexture(size: size, colors: colors, horizontal: horizontal)
        let node = SKSpriteNode(texture: texture)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.alpha = 0.9
        return node
    }

    private func gradientTexture(size: CGSize, colors: [UIColor], horizontal: Bool) -> SKTexture? {
        guard size.width > 0, size.height > 0 else { return nil }

        let layer = CAGradientLayer()
        layer.frame = CGRect(origin: .zero, size: size)
        layer.colors = colors.map { $0.cgColor }
        layer.startPoint = CGPoint(x: horizontal ? 0.0 : 0.5, y: horizontal ? 0.5 : 0.0)
        layer.endPoint = CGPoint(x: horizontal ? 1.0 : 0.5, y: horizontal ? 0.5 : 1.0)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        return SKTexture(cgImage: cgImage)
    }

    private func sparkleTexture() -> SKTexture? {
        let size = CGSize(width: 12, height: 12)

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.white.cgColor)
        context.addEllipse(in: CGRect(origin: .zero, size: size))
        context.fillPath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        return SKTexture(cgImage: cgImage)
    }

    private func confettiColors() -> [UIColor] {
        [
            UIColor.systemPink,
            UIColor.systemBlue,
            UIColor.systemYellow,
            UIColor.systemTeal,
            UIColor.systemPurple,
            UIColor.systemGreen
        ]
    }

    private func updateBorderPath() {
        guard let geometry = boardGeometry else { return }
        let rect = CGRect(
            x: geometry.spacing / 2,
            y: geometry.spacing / 2,
            width: geometry.boardSize.width - geometry.spacing,
            height: geometry.boardSize.height - geometry.spacing
        )
        borderNode.path = UIBezierPath(roundedRect: rect, cornerRadius: 12).cgPath
    }
}

// MARK: - UIColor Convenience
