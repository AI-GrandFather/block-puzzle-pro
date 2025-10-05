# Feature: Haptic & Sound Feedback Systems

**Priority:** HIGH
**Timeline:** Week 3-4 (Phase 2)
**Dependencies:** Core game actions implemented
**Performance Target:** < 5ms latency for feedback triggering

---

## Overview

Implement comprehensive multi-sensory feedback systems that enhance gameplay through:
1. **Haptic Feedback**: Physical vibrations for tactile response
2. **Sound Effects**: Audio cues for game actions
3. **Background Music**: Mood-appropriate soundtracks for each mode

Properly implemented feedback transforms gameplay from functional to deeply satisfying and engaging.

---

## Part 1: Haptic Feedback System

### Technical Foundation

**iOS Haptic Engine:**
- Use `Core Haptics` framework for advanced control
- Fallback to `UIFeedbackGenerator` for basic devices
- Support iPhone 6S and later (Taptic Engine)
- Graceful degradation on unsupported devices

**Haptic Types Available:**
```swift
// Impact feedback (collision-like)
UIImpactFeedbackGenerator.FeedbackStyle:
  - .light (subtle, fast)
  - .medium (balanced)
  - .heavy (strong, slower)
  - .soft (gentle, rounded)
  - .rigid (sharp, precise)

// Notification feedback (system events)
UINotificationFeedbackGenerator.FeedbackType:
  - .success
  - .warning
  - .error

// Selection feedback (UI interaction)
UISelectionFeedbackGenerator
```

### Haptic Patterns Specification

**1. Piece Pickup**
- **Trigger**: User taps piece in tray
- **Pattern**: Soft impact at 0.6 intensity
- **Duration**: ~10ms
- **Purpose**: Confirm piece is "grabbed"
```swift
let generator = UIImpactFeedbackGenerator(style: .soft)
generator.impactOccurred(intensity: 0.6)
```

**2. Piece Placement (Valid)**
- **Trigger**: Piece successfully placed on grid
- **Pattern**: Medium impact at 0.7 intensity
- **Duration**: ~15ms
- **Purpose**: Satisfying confirmation of successful action
```swift
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred(intensity: 0.7)
```

**3. Invalid Placement**
- **Trigger**: Attempt to place piece in invalid location
- **Pattern**: Error notification
- **Duration**: ~20ms (slightly longer, less pleasant)
- **Purpose**: Communicate mistake gently
```swift
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.error)
```

**4. Single Line Clear**
- **Trigger**: One line clears
- **Pattern**: Light impact at 0.5 intensity
- **Duration**: ~12ms
- **Purpose**: Gentle reward for basic success
```swift
let generator = UIImpactFeedbackGenerator(style: .light)
generator.impactOccurred(intensity: 0.5)
```

**5. Double Line Clear**
- **Trigger**: Two lines clear simultaneously
- **Pattern**: Medium impact at 0.8 intensity
- **Duration**: ~18ms
- **Purpose**: Stronger reward for better move
```swift
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred(intensity: 0.8)
```

**6. Triple+ Line Clear**
- **Trigger**: Three or more lines clear
- **Pattern**: Heavy impact at 1.0 intensity
- **Duration**: ~25ms
- **Purpose**: Maximum satisfaction for excellent move
```swift
let generator = UIImpactFeedbackGenerator(style: .heavy)
generator.impactOccurred(intensity: 1.0)
```

**7. Combo Achievements**
- **Trigger**: Reaching combo milestones (2x, 5x, 10x, 15x)
- **Pattern**: Custom escalating sequence

**2x Combo:**
```swift
// Pattern: tap-tap (quick double tap)
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred(intensity: 0.6)
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    generator.impactOccurred(intensity: 0.6)
}
```

**5x Combo:**
```swift
// Pattern: tap-pause-tap-tap
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred(intensity: 0.7)
DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
    generator.impactOccurred(intensity: 0.8)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        generator.impactOccurred(intensity: 0.8)
    }
}
```

**10x Combo:**
```swift
// Pattern: Rapid sequence (4 quick taps)
let generator = UIImpactFeedbackGenerator(style: .rigid)
for i in 0..<4 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.08) {
        generator.impactOccurred(intensity: 0.9)
    }
}
```

**8. Perfect Clear**
- **Trigger**: Board completely emptied
- **Pattern**: Success notification + celebratory rhythm
```swift
let notif = UINotificationFeedbackGenerator()
notif.notificationOccurred(.success)

let impact = UIImpactFeedbackGenerator(style: .light)
// Light impacts in rhythm: ta-da-da-dum
let pattern = [0.0, 0.15, 0.25, 0.5]
pattern.forEach { delay in
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        impact.impactOccurred(intensity: 0.7)
    }
}
```

**9. Hold Swap**
- **Trigger**: Swapping piece with hold slot
- **Pattern**: Light impact
- **Duration**: ~10ms
- **Purpose**: Confirm swap occurred
```swift
let generator = UIImpactFeedbackGenerator(style: .light)
generator.impactOccurred(intensity: 0.5)
```

**10. Power-Up Activation**
- **Trigger**: Using a power-up
- **Pattern**: Medium impact + success notification
```swift
let impact = UIImpactFeedbackGenerator(style: .medium)
impact.impactOccurred(intensity: 0.8)
let notif = UINotificationFeedbackGenerator()
notif.notificationOccurred(.success)
```

**11. Level Up**
- **Trigger**: Player reaches new level
- **Pattern**: Success notification + celebratory pattern
```swift
let notif = UINotificationFeedbackGenerator()
notif.notificationOccurred(.success)

// Ascending intensity celebration
let impact = UIImpactFeedbackGenerator(style: .medium)
for i in 0..<3 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.12) {
        impact.impactOccurred(intensity: 0.6 + (Double(i) * 0.15))
    }
}
```

**12. Game Over**
- **Trigger**: Game ends (no more moves)
- **Pattern**: Gentle failure notification + descending pattern
```swift
let notif = UINotificationFeedbackGenerator()
notif.notificationOccurred(.warning) // Not error - gentler

// Descending soft taps
let impact = UIImpactFeedbackGenerator(style: .soft)
for i in 0..<3 {
    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
        impact.impactOccurred(intensity: 0.7 - (Double(i) * 0.2))
    }
}
```

### Advanced Haptic Implementation

**Custom Core Haptics Patterns:**
For devices supporting Core Haptics (iPhone 8+), use CHHapticEngine for more precise control:

```swift
class AdvancedHapticsManager {
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine failed to start: \\(error)")
        }
    }

    func playComboHaptic(comboLevel: Int) {
        guard let engine = engine else { return }

        var events = [CHHapticEvent]()

        // Create escalating pattern based on combo level
        let intensity = min(1.0, 0.5 + (Double(comboLevel) * 0.05))
        let sharpness = min(1.0, 0.3 + (Double(comboLevel) * 0.07))

        for i in 0..<min(comboLevel, 5) {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness))
                ],
                relativeTime: TimeInterval(i) * 0.1
            )
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play combo haptic: \\(error)")
        }
    }
}
```

### Haptic Settings & User Control

**Settings Options:**
- **Haptics Enabled**: On/Off toggle (default: On)
- **Haptic Intensity**: Light/Medium/Strong (default: Medium)
  * Light: Multiply all intensities by 0.7
  * Medium: Use default intensities
  * Strong: Multiply all intensities by 1.3 (capped at 1.0)
- **Reduce Haptics**: Accessibility option for users sensitive to vibrations (essential only)

**Performance Optimization:**
- Prepare generators in advance (avoid creation latency)
- Reuse generator instances
- Respect system haptic settings
- Disable haptics in Low Power Mode automatically

---

## Part 2: Sound Effects System

### Audio Architecture

**AVFoundation Framework:**
```swift
import AVFoundation

class SoundManager: ObservableObject {
    private var soundPlayers: [String: AVAudioPlayer] = [:]
    @Published var sfxVolume: Float = 0.7
    @Published var sfxEnabled: Bool = true

    func preloadSounds() {
        // Preload all sound files into memory
        let sounds = ["pickup", "place", "invalid", "line_clear", ...]
        sounds.forEach { preload($0) }
    }

    func preload(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "m4a") else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = sfxVolume
            soundPlayers[soundName] = player
        } catch {
            print("Failed to load sound: \\(soundName)")
        }
    }

    func play(_ soundName: String) {
        guard sfxEnabled else { return }
        soundPlayers[soundName]?.play()
    }
}
```

### Sound Effect Specifications

**1. Piece Pickup**
- **File**: `pickup.m4a`
- **Duration**: 0.1s
- **Characteristics**: Short "pop" sound, pitched C5, warm tone
- **Format**: 44.1kHz, AAC, mono
- **Purpose**: Audio confirmation of grab action

**2. Valid Placement (Place)**
- **File**: `place_valid.m4a`
- **Duration**: 0.15s
- **Characteristics**: Satisfying "click" or wooden block sound
- **Variations**: 3 slight variations to avoid repetition
- **Theme-Specific**: Wooden theme uses authentic wood sound, etc.
- **Purpose**: Rewarding confirmation

**3. Invalid Placement**
- **File**: `place_invalid.m4a`
- **Duration**: 0.2s
- **Characteristics**: Soft error tone, descending pitch, gentle (not harsh)
- **Format**: Designed to be non-abrasive
- **Purpose**: Gentle negative feedback

**4. Single Line Clear**
- **File**: `line_clear_1.m4a`
- **Duration**: 0.3s
- **Characteristics**: Pleasant chime, C note
- **Pitch**: C5 (523.25 Hz)
- **Purpose**: Reward for basic success

**5. Double Line Clear**
- **File**: `line_clear_2.m4a`
- **Duration**: 0.4s
- **Characteristics**: Harmonic chord, C-E notes
- **Pitches**: C5 + E5 (659.25 Hz)
- **Purpose**: Richer reward for double clear

**6. Triple Line Clear**
- **File**: `line_clear_3.m4a`
- **Duration**: 0.5s
- **Characteristics**: Full chord, C-E-G notes
- **Pitches**: C5 + E5 + G5 (783.99 Hz)
- **Purpose**: Even more satisfying

**7. Quad+ Line Clear**
- **File**: `line_clear_4.m4a`
- **Duration**: 0.6s
- **Characteristics**: Full chord progression with reverb, C-E-G-C'
- **Pitches**: C5 + E5 + G5 + C6 (1046.50 Hz)
- **Effect**: Reverb tail for grandeur
- **Purpose**: Maximum audio reward

**8. Combo Progression**
- **Files**: `combo_2x.m4a`, `combo_5x.m4a`, `combo_8x.m4a`, `combo_10x.m4a`
- **Characteristics**: Musical scale ascending
- **Sequence**:
  * 2x: C note (0.3s)
  * 5x: E note (0.35s)
  * 8x: G note (0.4s)
  * 10x: C' note (0.5s with harmony)
- **Purpose**: Musical progression creates excitement

**9. Perfect Clear**
- **File**: `perfect_clear.m4a`
- **Duration**: 1.5s
- **Characteristics**: Triumphant 3-note ascending melody with harmony
- **Sequence**: G5 → B5 → D6 with supporting chord
- **Effect**: Rich orchestral sound with reverb
- **Purpose**: Celebration of major achievement

**10. Game Over**
- **File**: `game_over.m4a`
- **Duration**: 1.2s
- **Characteristics**: Gentle 3-note descending melody
- **Sequence**: G5 → E5 → C5
- **Tone**: Melancholic but not harsh, piano sound
- **Purpose**: Gentle end without frustration

**11. Hold Swap**
- **File**: `hold_swap.m4a`
- **Duration**: 0.2s
- **Characteristics**: Whoosh sound with pitch shift (down to up)
- **Purpose**: Communicate movement/exchange

**12. Power-Up Activation**
- **File**: `powerup.m4a`
- **Duration**: 0.4s
- **Characteristics**: Energetic "power up" sound, rising pitch
- **Effect**: Slight distortion for energy feel
- **Purpose**: Excitement for special ability use

**13. Menu Navigation**
- **File**: `menu_tap.m4a`
- **Duration**: 0.05s
- **Characteristics**: Soft tap/click, high frequency
- **Purpose**: Responsive UI feedback

**14. Button Press**
- **File**: `button_press.m4a`
- **Duration**: 0.1s
- **Characteristics**: Satisfying click with slight bass
- **Purpose**: Tactile button feel

**15. Level Complete**
- **File**: `level_complete.m4a`
- **Duration**: 2s
- **Characteristics**: Victory jingle, celebratory melody
- **Composition**: Upbeat major key progression
- **Purpose**: Reward for completing level

**16. Achievement Unlock**
- **File**: `achievement.m4a`
- **Duration**: 0.8s
- **Characteristics**: Notification chime with sparkle effect
- **Effect**: High-frequency shimmer
- **Purpose**: Special moment recognition

### Audio File Optimization

**Format Requirements:**
- Container: M4A (MPEG-4 Audio)
- Codec: AAC (Advanced Audio Coding)
- Sample Rate: 44.1 kHz (CD quality)
- Bit Rate: 128 kbps (balance of quality and size)
- Channels: Mono (SFX don't need stereo, saves space)
- Normalization: Peak normalize to -3dB (consistent volume)

**File Size Targets:**
- Individual SFX: < 50KB each
- Total SFX library: < 2MB
- Fast loading from disk

---

## Part 3: Background Music System

### Music Architecture

**Audio Session Management:**
```swift
class MusicManager: ObservableObject {
    private var musicPlayer: AVAudioPlayer?
    @Published var musicVolume: Float = 0.6
    @Published var musicEnabled: Bool = true
    private var currentTrack: MusicTrack?

    func playMusic(track: MusicTrack, loop: Bool = true) {
        guard musicEnabled else { return }

        guard let url = Bundle.main.url(forResource: track.filename, withExtension: "m4a") else { return }

        do {
            musicPlayer?.stop()
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0 // -1 = infinite loop
            musicPlayer?.volume = musicVolume
            musicPlayer?.play()
            currentTrack = track
        } catch {
            print("Failed to play music: \\(track.filename)")
        }
    }

    func crossfade(to newTrack: MusicTrack, duration: TimeInterval = 2.0) {
        // Fade out current track
        fadeVolume(to: 0, duration: duration) {
            // Start new track at 0 volume
            self.playMusic(track: newTrack)
            self.musicPlayer?.volume = 0
            // Fade in new track
            self.fadeVolume(to: self.musicVolume, duration: duration)
        }
    }

    private func fadeVolume(to target: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        // Smooth volume fade implementation
        // Use CADisplayLink for smooth 60fps fade
    }
}
```

### Music Track Specifications

**1. Endless Mode Music**
- **File**: `music_endless.m4a`
- **Duration**: 2:30 (loops seamlessly)
- **Tempo**: 120 BPM
- **Style**: Relaxing ambient loop, minimal melody
- **Instruments**: Soft synth pads, gentle piano, subtle percussion
- **Mood**: Calm, focused, non-intrusive
- **Key**: C Major (happy but not overly energetic)
- **Purpose**: Allow long play sessions without fatigue

**2. Timed Modes Music**
- **File**: `music_timed.m4a`
- **Duration**: 2:00 (loops)
- **Tempo**: 140 BPM
- **Style**: Upbeat, energetic
- **Instruments**: Electronic beats, driving bass, melodic synth
- **Mood**: Exciting, urgent (without anxiety)
- **Variation**: Builds intensity in final 30 seconds (separate file: `music_timed_finale.m4a`)
- **Purpose**: Create energy and excitement for time pressure

**3. Levels Mode Music**
- **File**: `music_levels.m4a`
- **Duration**: 3:00 (loops)
- **Tempo**: 110-130 BPM (varies by level pack)
- **Style**: Adventure theme
- **Instruments**: Orchestral blend with electronic elements
- **Mood**: Adventurous, progressive
- **Variations**: Different intensity for different level packs
- **Purpose**: Sense of journey and progression

**4. Puzzle Mode Music**
- **File**: `music_puzzle.m4a`
- **Duration**: 2:45 (loops)
- **Tempo**: 90 BPM
- **Style**: Thoughtful, contemplative
- **Instruments**: Piano, strings, light woodwinds
- **Mood**: Intellectual, calm thinking
- **Purpose**: Encourage strategic thinking

**5. Zen Mode Music**
- **File**: `music_zen.m4a`
- **Duration**: 4:00 (seamless loop)
- **Tempo**: 60 BPM (or no beat, ambient)
- **Style**: Meditative ambient soundscape
- **Instruments**: Nature sounds (rain, ocean waves, forest), singing bowls, soft drones
- **Mood**: Deeply relaxing, meditative
- **Purpose**: Maximum relaxation and mindfulness

**6. Menu Music**
- **File**: `music_menu.m4a`
- **Duration**: 2:00 (loops)
- **Tempo**: 115 BPM
- **Style**: Welcoming, friendly
- **Instruments**: Upbeat pop instrumentation
- **Mood**: Inviting, fun
- **Purpose**: Positive first impression

### Dynamic Music System

**Intensity Scaling:**
```swift
func adjustMusicIntensity(basedOn gameState: GameState) {
    if gameState.currentCombo >= 5 {
        // Increase music intensity during combos
        applyLowPassFilter(cutoff: 1000) // Open up high frequencies
        increaseVolume(by: 0.1) // Slightly louder
    } else {
        // Return to normal
        removeLowPassFilter()
        resetVolume()
    }
}
```

**Adaptive Music Features:**
- Combo state increases high-frequency content (sounds brighter)
- Time running low in timed modes triggers intensity increase
- Calm moments (no recent actions) slightly decrease volume
- Perfect clear triggers brief musical flourish overlay

### Theme-Specific Music (Optional Premium Feature)

**Space Theme:**
- Sci-fi synth with cosmic ambiance
- Electronic, futuristic sound palette

**Beach Theme:**
- Tropical instrumentation (steel drums, ukulele)
- Reggae/island-inspired rhythm

**Wooden Theme:**
- Acoustic instruments only
- Folk/traditional feel

**Implementation:**
```swift
func getMusic(for mode: GameMode, theme: Theme) -> MusicTrack {
    if theme.hasPremiumMusic {
        return theme.getMusicTrack(for: mode)
    } else {
        return defaultMusicTracks[mode]
    }
}
```

### Music File Optimization

**Format Requirements:**
- Container: M4A
- Codec: AAC
- Sample Rate: 44.1 kHz
- Bit Rate: 192 kbps (higher quality than SFX, music needs it)
- Channels: Stereo (music benefits from stereo field)
- Looping: Perfectly trimmed for seamless loops
- Normalization: -14 LUFS (streaming standard, prevents fatigue)

**File Size Targets:**
- Per track: 3-6MB (2-3 minute loops)
- Total music library: < 40MB
- Consider streaming/on-demand download for optional tracks

---

## Volume Mixing & Control

### Separate Volume Controls

**User Settings:**
- **Master Volume**: 0-100% (controls both SFX and Music)
- **SFX Volume**: 0-100% (default: 70%)
- **Music Volume**: 0-100% (default: 60%)

**Mixing Logic:**
```swift
let finalSFXVolume = masterVolume * sfxVolume
let finalMusicVolume = masterVolume * musicVolume
```

### Ducking (Automatic Volume Adjustment)

**SFX Priority:**
When important SFX plays, briefly lower music volume:
```swift
func playSFX(_ sound: String, withDucking: Bool = false) {
    if withDucking && musicPlayer?.isPlaying == true {
        // Duck music to 40% for 0.5 seconds
        musicPlayer?.setVolume(musicVolume * 0.4, fadeDuration: 0.1)

        // Play SFX
        soundPlayers[sound]?.play()

        // Restore music volume
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            musicPlayer?.setVolume(musicVolume, fadeDuration: 0.3)
        }
    } else {
        soundPlayers[sound]?.play()
    }
}
```

**Apply Ducking For:**
- Achievement unlocks
- Level complete
- Perfect clear
- Game over

**Don't Duck For:**
- Piece placement
- Line clears
- Regular gameplay sounds

---

## Audio Interruption Handling

**System Interruptions:**
```swift
class AudioManager: ObservableObject {
    init() {
        // Handle phone calls, Siri, alarms, etc.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .began {
            // Pause music, keep SFX available
            musicPlayer?.pause()
        } else if type == .ended {
            // Resume music when interruption ends
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    musicPlayer?.play()
                }
            }
        }
    }
}
```

---

## Performance Requirements

**Latency Targets:**
- Haptic trigger to feedback: < 5ms
- Sound trigger to playback: < 10ms
- Music crossfade smoothness: 60fps interpolation

**Memory Usage:**
- Preloaded SFX: < 5MB RAM
- Single music track: < 10MB RAM
- Total audio system: < 20MB RAM

**CPU Usage:**
- Audio mixing: < 2% CPU
- Haptic patterns: < 1% CPU
- Total feedback system: < 3% CPU

---

## Accessibility Considerations

**Settings:**
- Disable haptics (for users sensitive to vibration)
- Disable sound effects (for deaf/hard of hearing)
- Visual sound indicators (accessibility feature link)
- Mono audio option (single ear listening)
- Reduce motion (affects audio-visual synchronization timing)

**System Integration:**
- Respect system sound settings
- Respect ringer/silent switch for SFX (not music)
- Respect headphone audio routing
- Support hearing aid compatibility

---

## Implementation Checklist

- [ ] Set up AVFoundation audio session
- [ ] Create SoundManager class
- [ ] Create MusicManager class
- [ ] Create HapticsManager class (with Core Haptics)
- [ ] Source/create all 16+ sound effect files
- [ ] Source/create 6+ background music tracks
- [ ] Optimize audio files (AAC, correct bit rate)
- [ ] Implement audio preloading system
- [ ] Implement haptic pattern for each game event
- [ ] Integrate feedback triggers with game actions
- [ ] Build volume mixing system
- [ ] Implement ducking for important sounds
- [ ] Create audio interruption handlers
- [ ] Build settings UI for audio/haptic controls
- [ ] Implement crossfade system for music transitions
- [ ] Test haptics on all supported devices
- [ ] Test audio on headphones and speakers
- [ ] Verify accessibility compliance
- [ ] Performance profiling (< 5ms latency)
- [ ] Memory profiling (< 20MB for audio system)

---

## Success Criteria

✅ All haptic patterns implemented and feel satisfying
✅ Haptic latency < 5ms from trigger
✅ All sound effects present and high quality
✅ Sound playback latency < 10ms
✅ Background music loops seamlessly
✅ Music crossfades smoothly (2s fade)
✅ Volume controls work correctly
✅ Ducking works for important sounds
✅ Audio interruptions handled gracefully
✅ Settings persist across app launches
✅ No audio glitches or crackling
✅ Works correctly with headphones and speakers
✅ Respects silent mode for SFX
✅ Memory usage < 20MB for audio system
✅ CPU usage < 3% for feedback systems
✅ Accessibility features functional
