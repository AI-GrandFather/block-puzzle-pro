// AudioManager.swift
// Manages sound effects and background music for the game
// Provides global audio settings and playback control

import Foundation
import AVFoundation
import Combine

// MARK: - Audio Manager

final class AudioManager: ObservableObject {

    // MARK: - Singleton

    @MainActor static let shared = AudioManager()

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
                playBackgroundMusic()
            } else {
                stopBackgroundMusic()
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

    // MARK: - Private Properties

    private var soundPlayers: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession = .sharedInstance()

    // MARK: - Initialization

    private init() {
        // Load saved settings
        isSoundEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
        isMusicEnabled = UserDefaults.standard.object(forKey: "music_enabled") as? Bool ?? true
        soundVolume = UserDefaults.standard.object(forKey: "sound_volume") as? Float ?? 0.7
        musicVolume = UserDefaults.standard.object(forKey: "music_volume") as? Float ?? 0.5

        setupAudioSession()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Sound Effects

    func playSound(_ soundName: String) {
        guard isSoundEnabled else { return }

        // Check if player already exists
        if let player = soundPlayers[soundName] {
            player.currentTime = 0
            player.play()
            return
        }

        // Create new player
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "wav") ??
                       Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Sound file not found: \(soundName)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = soundVolume
            player.prepareToPlay()
            player.play()
            soundPlayers[soundName] = player
        } catch {
            print("Failed to play sound \(soundName): \(error)")
        }
    }

    /// Play predefined game sounds
    func playBlockPlace() {
        playSound("block_place")
    }

    func playLineClear() {
        playSound("line_clear")
    }

    func playGameOver() {
        playSound("game_over")
    }

    func playCombo(_ comboCount: Int) {
        if comboCount <= 3 {
            playSound("combo_small")
        } else if comboCount <= 6 {
            playSound("combo_medium")
        } else {
            playSound("combo_large")
        }
    }

    func playPowerUpActivate() {
        playSound("powerup_activate")
    }

    func playPowerUpCollect() {
        playSound("powerup_collect")
    }

    func playButtonClick() {
        playSound("button_click")
    }

    // MARK: - Background Music

    func playBackgroundMusic(_ musicName: String = "background_music") {
        guard isMusicEnabled else { return }

        guard let url = Bundle.main.url(forResource: musicName, withExtension: "mp3") ??
                       Bundle.main.url(forResource: musicName, withExtension: "wav") else {
            print("Music file not found: \(musicName)")
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1 // Loop indefinitely
            musicPlayer?.volume = musicVolume
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()
        } catch {
            print("Failed to play background music: \(error)")
        }
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func pauseBackgroundMusic() {
        musicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        musicPlayer?.play()
    }

    // MARK: - Volume Control

    private func updateSoundVolumes() {
        for player in soundPlayers.values {
            player.volume = soundVolume
        }
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
    }
}

// MARK: - Sound Names

extension AudioManager {
    enum SoundEffect: String {
        case blockPlace = "block_place"
        case lineClear = "line_clear"
        case gameOver = "game_over"
        case comboSmall = "combo_small"
        case comboMedium = "combo_medium"
        case comboLarge = "combo_large"
        case powerUpActivate = "powerup_activate"
        case powerUpCollect = "powerup_collect"
        case buttonClick = "button_click"

        var fileName: String {
            rawValue
        }
    }
}
