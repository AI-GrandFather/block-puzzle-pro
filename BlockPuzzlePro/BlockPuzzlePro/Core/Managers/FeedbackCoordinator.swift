//
//  FeedbackCoordinator.swift
//  BlockPuzzlePro
//
//  Created on October 5, 2025
//  Purpose: Unified coordinator for haptic and audio feedback
//

import Foundation
import os.log

// MARK: - Game Feedback Events

/// Complete feedback events combining haptics and audio
enum GameFeedbackEvent {
    case piecePickup
    case piecePlaced(valid: Bool)
    case lineClear(count: Int)
    case combo(level: Int)
    case perfectClear
    case holdSwap
    case powerUpActivation
    case levelUp
    case levelComplete
    case achievement
    case gameOver
    case menuTap
    case buttonPress
}

// MARK: - Feedback Coordinator

/// Coordinates haptic and audio feedback for game events
@MainActor
final class FeedbackCoordinator: ObservableObject {

    // MARK: - Singleton

    static let shared = FeedbackCoordinator()

    // MARK: - Managers

    private let hapticManager: HapticManager
    private let audioManager: AudioManager

    private let logger = Logger(subsystem: "com.blockpuzzlepro", category: "FeedbackCoordinator")

    // MARK: - Initialization

    private init() {
        self.hapticManager = HapticManager()
        self.audioManager = AudioManager.shared

        logger.info("FeedbackCoordinator initialized")
    }

    // MARK: - Public API

    /// Trigger complete feedback (haptic + audio) for game event
    func trigger(_ event: GameFeedbackEvent) {
        triggerHaptic(for: event)
        triggerAudio(for: event)
    }

    /// Access haptic manager for custom control
    var haptics: HapticManager {
        return hapticManager
    }

    /// Access audio manager for custom control
    var audio: AudioManager {
        return audioManager
    }

    // MARK: - Event Routing

    private func triggerHaptic(for event: GameFeedbackEvent) {
        switch event {
        case .piecePickup:
            hapticManager.trigger(.piecePickup)

        case .piecePlaced(let valid):
            if valid {
                hapticManager.trigger(.piecePlacement)
            } else {
                hapticManager.trigger(.invalidPlacement)
            }

        case .lineClear(let count):
            hapticManager.trigger(.lineClear(count: count))

        case .combo(let level):
            hapticManager.trigger(.combo(level: level))

        case .perfectClear:
            hapticManager.trigger(.perfectClear)

        case .holdSwap:
            hapticManager.trigger(.holdSwap)

        case .powerUpActivation:
            hapticManager.trigger(.powerUpActivation)

        case .levelUp:
            hapticManager.trigger(.levelUp)

        case .levelComplete:
            hapticManager.trigger(.levelUp) // Same as level up

        case .achievement:
            hapticManager.trigger(.powerUpActivation) // Similar pattern

        case .gameOver:
            hapticManager.trigger(.gameOver)

        case .menuTap, .buttonPress:
            hapticManager.selectionChanged()
        }
    }

    private func triggerAudio(for event: GameFeedbackEvent) {
        switch event {
        case .piecePickup:
            audioManager.playPickup()

        case .piecePlaced(let valid):
            audioManager.playPlacement(valid: valid)

        case .lineClear(let count):
            audioManager.playLineClear(count: count)

        case .combo(let level):
            audioManager.playCombo(level: level)

        case .perfectClear:
            audioManager.playPerfectClear()

        case .holdSwap:
            audioManager.playHoldSwap()

        case .powerUpActivation:
            audioManager.playPowerUp()

        case .levelUp:
            audioManager.playLevelComplete()

        case .levelComplete:
            audioManager.playLevelComplete()

        case .achievement:
            audioManager.playAchievement()

        case .gameOver:
            audioManager.playGameOver()

        case .menuTap:
            audioManager.playMenuTap()

        case .buttonPress:
            audioManager.playButtonPress()
        }
    }

    // MARK: - Music Control

    func playMusic(_ track: MusicTrack, loop: Bool = true) {
        audioManager.playMusic(track, loop: loop)
    }

    func crossfadeMusic(to track: MusicTrack, duration: TimeInterval = 2.0) {
        audioManager.crossfadeMusic(to: track, duration: duration)
    }

    func stopMusic() {
        audioManager.stopBackgroundMusic()
    }

    func pauseMusic() {
        audioManager.pauseBackgroundMusic()
    }

    func resumeMusic() {
        audioManager.resumeBackgroundMusic()
    }

    // MARK: - Settings Access

    var isHapticsEnabled: Bool {
        get { hapticManager.isEnabled }
        set { hapticManager.isEnabled = newValue }
    }

    var isSoundEnabled: Bool {
        get { audioManager.isSoundEnabled }
        set { audioManager.isSoundEnabled = newValue }
    }

    var isMusicEnabled: Bool {
        get { audioManager.isMusicEnabled }
        set { audioManager.isMusicEnabled = newValue }
    }

    var hapticIntensity: HapticIntensity {
        get { hapticManager.intensity }
        set { hapticManager.intensity = newValue }
    }

    var soundVolume: Float {
        get { audioManager.soundVolume }
        set { audioManager.soundVolume = newValue }
    }

    var musicVolume: Float {
        get { audioManager.musicVolume }
        set { audioManager.musicVolume = newValue }
    }

    var masterVolume: Float {
        get { audioManager.masterVolume }
        set { audioManager.masterVolume = newValue }
    }

    // MARK: - Cleanup

    func cleanup() {
        hapticManager.stopAllHaptics()
        audioManager.cleanup()
    }
}

// MARK: - Convenience Extensions

extension FeedbackCoordinator {

    /// Quick feedback for successful action
    func success() {
        hapticManager.notification(type: .success)
        audioManager.playButtonPress()
    }

    /// Quick feedback for error/warning
    func error() {
        hapticManager.notification(type: .error)
        audioManager.playPlacement(valid: false)
    }

    /// Quick feedback for selection change
    func selectionChanged() {
        hapticManager.selectionChanged()
    }
}
