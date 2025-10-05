import Foundation
import AVFoundation
import os.log

/// Manages game audio including sound effects and background music
@MainActor
final class AudioManager: ObservableObject {

    // MARK: - Properties

    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
            if !isSoundEnabled {
                stopAllSounds()
            }
        }
    }

    @Published var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "musicEnabled")
            if isMusicEnabled {
                playBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }

    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "AudioManager")

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Initialization

    private init() {
        // Load saved preferences
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.isMusicEnabled = UserDefaults.standard.object(forKey: "musicEnabled") as? Bool ?? false

        // Configure audio session
        configureAudioSession()

        // Preload sound effects
        preloadSoundEffects()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            logger.info("Audio session configured successfully")
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Sound Effect Preloading

    private func preloadSoundEffects() {
        Task {
            for effect in SoundEffect.allCases {
                guard let url = effect.url else { continue }

                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = effect.volume
                    audioPlayers[effect] = player
                } catch {
                    logger.warning("Failed to preload sound: \(effect.rawValue) - \(error.localizedDescription)")
                }
            }
            logger.info("Preloaded \(self.audioPlayers.count) sound effects")
        }
    }

    // MARK: - Sound Playback

    func playSound(_ effect: SoundEffect) {
        guard isSoundEnabled else { return }

        if let player = audioPlayers[effect] {
            // Stop if already playing to allow overlapping sounds
            if player.isPlaying {
                player.currentTime = 0
            }
            player.play()
        } else {
            logger.warning("Sound effect not loaded: \(effect.rawValue)")
        }
    }

    func playSoundAsync(_ effect: SoundEffect) {
        Task { @MainActor in
            playSound(effect)
        }
    }

    // MARK: - Background Music

    private func playBackgroundMusic() {
        guard isMusicEnabled else { return }

        // For now, we'll skip background music implementation
        // Can be added later with actual music files
        logger.info("Background music playback requested (not implemented)")
    }

    private func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }

    // MARK: - Control Methods

    func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
    }

    func pause() {
        for player in audioPlayers.values where player.isPlaying {
            player.pause()
        }
        backgroundMusicPlayer?.pause()
    }

    func resume() {
        guard isSoundEnabled else { return }
        backgroundMusicPlayer?.play()
    }
}

// MARK: - Sound Effect Enum

enum SoundEffect: String, CaseIterable {
    case piecePickup = "piece_pickup"
    case pieceDrop = "piece_drop"
    case piecePlace = "piece_place"
    case lineCleSingle = "line_clear_single"
    case lineClearCombo = "line_clear_combo"
    case powerUpActivate = "powerup_activate"
    case buttonClick = "button_click"
    case gameOver = "game_over"
    case invalidPlacement = "invalid_placement"
    case achievement = "achievement"

    var volume: Float {
        switch self {
        case .piecePickup:
            return 0.3
        case .pieceDrop, .piecePlace:
            return 0.5
        case .lineCleSingle:
            return 0.6
        case .lineClearCombo:
            return 0.7
        case .powerUpActivate:
            return 0.8
        case .buttonClick:
            return 0.4
        case .gameOver:
            return 0.6
        case .invalidPlacement:
            return 0.4
        case .achievement:
            return 0.7
        }
    }

    var url: URL? {
        // Generate simple procedural sounds using system sounds for now
        // In production, these would be actual audio files from the bundle
        return generateProceduralSound()
    }

    private func generateProceduralSound() -> URL? {
        // For MVP, we'll use system sounds
        // TODO: Replace with actual audio files
        return nil
    }
}
