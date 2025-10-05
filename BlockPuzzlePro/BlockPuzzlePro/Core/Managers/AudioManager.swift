//
//  AudioManager.swift
//  BlockPuzzlePro
//
//  Enhanced comprehensive audio manager with sound effects, music, and feedback
//

import Foundation
import AVFoundation
import Combine
import os.log

// MARK: - Sound Effect Types

/// All game sound effects
enum SoundEffect: String, CaseIterable {
    // Piece interactions
    case pickup = "pickup"
    case placeValid = "place_valid"
    case placeInvalid = "place_invalid"

    // Line clears
    case lineClear1 = "line_clear_1"
    case lineClear2 = "line_clear_2"
    case lineClear3 = "line_clear_3"
    case lineClear4 = "line_clear_4"

    // Combos
    case combo2x = "combo_2x"
    case combo5x = "combo_5x"
    case combo8x = "combo_8x"
    case combo10x = "combo_10x"

    // Special events
    case perfectClear = "perfect_clear"
    case gameOver = "game_over"
    case holdSwap = "hold_swap"
    case powerUp = "powerup"
    case achievement = "achievement"

    // UI sounds
    case menuTap = "menu_tap"
    case buttonPress = "button_press"
    case levelComplete = "level_complete"

    var fileName: String { rawValue }
}

// MARK: - Music Track Types

/// Background music tracks
enum MusicTrack: String, CaseIterable {
    case endless = "music_endless"
    case timed = "music_timed"
    case timedFinale = "music_timed_finale"
    case levels = "music_levels"
    case puzzle = "music_puzzle"
    case zen = "music_zen"
    case menu = "music_menu"

    var fileName: String { rawValue }
}

// MARK: - Enhanced Audio Manager

/// Comprehensive audio manager with SFX, music, ducking, and interruption handling
@MainActor
final class AudioManager: ObservableObject {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Published Properties

    @Published var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "sound_enabled")
            if !isSoundEnabled {
                stopAllSounds()
            }
        }
    }

    @Published var isMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isMusicEnabled, forKey: "music_enabled")
            if isMusicEnabled {
                resumeBackgroundMusic()
            } else {
                pauseBackgroundMusic()
            }
        }
    }

    @Published var soundVolume: Float {
        didSet {
            UserDefaults.standard.set(soundVolume, forKey: "sound_volume")
            updateSoundVolumes()
        }
    }

    @Published var musicVolume: Float {
        didSet {
            UserDefaults.standard.set(musicVolume, forKey: "music_volume")
            musicPlayer?.volume = musicVolume
        }
    }

    @Published var masterVolume: Float {
        didSet {
            UserDefaults.standard.set(masterVolume, forKey: "master_volume")
            updateAllVolumes()
        }
    }

    // MARK: - Private Properties

    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var currentTrack: MusicTrack?
    private var audioSession: AVAudioSession = .sharedInstance()

    // Ducking state
    private var isDucking: Bool = false
    private var originalMusicVolume: Float = 0.0

    private let logger = Logger(subsystem: "com.blockpuzzlepro", category: "AudioManager")

    // MARK: - Initialization

    private init() {
        // Load saved settings
        isSoundEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
        isMusicEnabled = UserDefaults.standard.object(forKey: "music_enabled") as? Bool ?? true
        soundVolume = UserDefaults.standard.object(forKey: "sound_volume") as? Float ?? 0.7
        musicVolume = UserDefaults.standard.object(forKey: "music_volume") as? Float ?? 0.6
        masterVolume = UserDefaults.standard.object(forKey: "master_volume") as? Float ?? 1.0

        setupAudioSession()
        setupInterruptionHandling()
        preloadSounds()

        logger.info("AudioManager initialized (Sound: \(self.isSoundEnabled), Music: \(self.isMusicEnabled))")
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            // Use .ambient to allow mixing with other audio
            // Respects silent switch for SFX
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
            logger.info("Audio session configured")
        } catch {
            logger.error("Failed to set up audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruptionNotification),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruptionNotification(_ notification: Notification) {
        Task { @MainActor in
            handleInterruption(notification: notification)
        }
    }

    private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            // Pause music during interruption
            musicPlayer?.pause()
            logger.info("Audio interrupted - pausing music")
        } else if type == .ended {
            // Resume music if appropriate
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume), isMusicEnabled {
                    musicPlayer?.play()
                    logger.info("Interruption ended - resuming music")
                }
            }
        }
    }

    // MARK: - Sound Effects Preloading

    private func preloadSounds() {
        // Preload commonly used sounds for instant playback
        let prioritySounds: [SoundEffect] = [
            .pickup, .placeValid, .placeInvalid,
            .lineClear1, .lineClear2,
            .menuTap, .buttonPress
        ]

        for sound in prioritySounds {
            preloadSound(sound)
        }

        logger.info("Preloaded \(prioritySounds.count) priority sound effects")
    }

    private func preloadSound(_ sound: SoundEffect) {
        guard soundPlayers[sound.fileName] == nil else { return }

        // Try multiple file extensions
        let extensions = ["m4a", "wav", "mp3"]
        var loadedURL: URL?

        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext) {
                loadedURL = url
                break
            }
        }

        guard let url = loadedURL else {
            logger.warning("Sound file not found: \(sound.fileName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = finalSFXVolume
            player.prepareToPlay()
            soundPlayers[sound.fileName] = player
        } catch {
            logger.error("Failed to preload sound \(sound.fileName): \(error.localizedDescription)")
        }
    }

    // MARK: - Sound Effect Playback

    func playSound(_ sound: SoundEffect, withDucking: Bool = false) {
        guard isSoundEnabled else { return }

        // Apply ducking if requested
        if withDucking {
            duckMusic()
        }

        // Check if player exists
        if let player = soundPlayers[sound.fileName] {
            player.currentTime = 0
            player.volume = finalSFXVolume
            player.play()
            return
        }

        // Load and play on demand
        let extensions = ["m4a", "wav", "mp3"]
        var loadedURL: URL?

        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext) {
                loadedURL = url
                break
            }
        }

        guard let url = loadedURL else {
            logger.warning("Sound file not found: \(sound.fileName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = finalSFXVolume
            player.prepareToPlay()
            player.play()
            soundPlayers[sound.fileName] = player
        } catch {
            logger.error("Failed to play sound \(sound.fileName): \(error.localizedDescription)")
        }
    }

    // MARK: - Convenience SFX Methods

    func playPickup() {
        playSound(.pickup)
    }

    func playPlacement(valid: Bool) {
        playSound(valid ? .placeValid : .placeInvalid)
    }

    func playLineClear(count: Int) {
        let sound: SoundEffect
        switch count {
        case 1: sound = .lineClear1
        case 2: sound = .lineClear2
        case 3: sound = .lineClear3
        default: sound = .lineClear4
        }
        playSound(sound)
    }

    func playCombo(level: Int) {
        let sound: SoundEffect
        switch level {
        case 2: sound = .combo2x
        case 5: sound = .combo5x
        case 8: sound = .combo8x
        case 10...: sound = .combo10x
        default: return
        }
        playSound(sound)
    }

    func playPerfectClear() {
        playSound(.perfectClear, withDucking: true)
    }

    func playGameOver() {
        playSound(.gameOver, withDucking: true)
    }

    func playHoldSwap() {
        playSound(.holdSwap)
    }

    func playPowerUp() {
        playSound(.powerUp, withDucking: true)
    }

    func playAchievement() {
        playSound(.achievement, withDucking: true)
    }

    func playMenuTap() {
        playSound(.menuTap)
    }

    func playButtonPress() {
        playSound(.buttonPress)
    }

    func playLevelComplete() {
        playSound(.levelComplete, withDucking: true)
    }

    // MARK: - Background Music

    func playMusic(_ track: MusicTrack, loop: Bool = true) {
        guard isMusicEnabled else { return }

        // Don't restart if already playing this track
        if currentTrack == track, musicPlayer?.isPlaying == true {
            return
        }

        let extensions = ["m4a", "mp3", "wav"]
        var loadedURL: URL?

        for ext in extensions {
            if let url = Bundle.main.url(forResource: track.fileName, withExtension: ext) {
                loadedURL = url
                break
            }
        }

        guard let url = loadedURL else {
            logger.warning("Music file not found: \(track.fileName)")
            return
        }

        do {
            musicPlayer?.stop()
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0
            musicPlayer?.volume = finalMusicVolume
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
            currentTrack = track
            logger.info("Playing music: \(track.fileName)")
        } catch {
            logger.error("Failed to play music \(track.fileName): \(error.localizedDescription)")
        }
    }

    func crossfadeMusic(to newTrack: MusicTrack, duration: TimeInterval = 2.0) {
        guard isMusicEnabled else { return }

        // Fade out current track
        fadeVolume(to: 0, duration: duration) {
            // Start new track
            self.playMusic(newTrack)
            self.musicPlayer?.volume = 0

            // Fade in new track
            self.fadeVolume(to: self.finalMusicVolume, duration: duration)
        }
    }

    private func fadeVolume(to targetVolume: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player = musicPlayer else {
            completion?()
            return
        }

        let startVolume = player.volume
        let steps = 60 // 60fps
        let stepDuration = duration / Double(steps)
        let volumeChange = (targetVolume - startVolume) / Float(steps)

        var currentStep = 0

        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            player.volume += volumeChange

            if currentStep >= steps {
                timer.invalidate()
                player.volume = targetVolume
                completion?()
            }
        }
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentTrack = nil
    }

    func pauseBackgroundMusic() {
        musicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        musicPlayer?.play()
    }

    // MARK: - Ducking

    private func duckMusic() {
        guard let player = musicPlayer, player.isPlaying, !isDucking else { return }

        isDucking = true
        originalMusicVolume = player.volume

        // Duck to 40%
        player.setVolume(originalMusicVolume * 0.4, fadeDuration: 0.1)

        // Restore after 0.5 seconds
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            await restoreMusic()
        }
    }

    private func restoreMusic() async {
        guard isDucking, let player = musicPlayer else { return }

        player.setVolume(originalMusicVolume, fadeDuration: 0.3)
        isDucking = false
    }

    // MARK: - Volume Control

    private var finalSFXVolume: Float {
        return masterVolume * soundVolume
    }

    private var finalMusicVolume: Float {
        return masterVolume * musicVolume
    }

    private func updateSoundVolumes() {
        for player in soundPlayers.values {
            player.volume = finalSFXVolume
        }
    }

    private func updateAllVolumes() {
        updateSoundVolumes()
        musicPlayer?.volume = finalMusicVolume
    }

    func stopAllSounds() {
        for player in soundPlayers.values {
            player.stop()
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        stopAllSounds()
        stopBackgroundMusic()
        soundPlayers.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
}
