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

// MARK: - Procedural Audio Fallbacks

/// Generates lightweight procedural audio so the app has built-in sounds even when
/// dedicated asset files are unavailable. The generated clips are cached in-memory
/// and exported as PCM wave data for use with `AVAudioPlayer`.
fileprivate struct ProceduralAudioFactory {

    // MARK: Nested Types

    private struct ProceduralPattern {
        let segments: [ProceduralSegment]
        let sampleRate: Double
    }

    private struct ProceduralSegment {
        let frequencies: [Double]
        let duration: Double
        let amplitude: Double
        let envelope: ProceduralEnvelope
        let waveform: Waveform

        static func tone(
            frequencies: [Double],
            duration: Double,
            amplitude: Double,
            waveform: Waveform = .sine,
            envelope: ProceduralEnvelope = .snappy
        ) -> ProceduralSegment {
            ProceduralSegment(
                frequencies: frequencies,
                duration: duration,
                amplitude: amplitude,
                envelope: envelope,
                waveform: waveform
            )
        }

        static func silence(_ duration: Double) -> ProceduralSegment {
            ProceduralSegment(
                frequencies: [],
                duration: duration,
                amplitude: 0,
                envelope: .snappy,
                waveform: .sine
            )
        }
    }

    private struct ProceduralEnvelope {
        let attack: Double
        let release: Double

        static let snappy = ProceduralEnvelope(attack: 0.05, release: 0.25)
        static let tight = ProceduralEnvelope(attack: 0.03, release: 0.2)
        static let punchy = ProceduralEnvelope(attack: 0.02, release: 0.18)
        static let pad = ProceduralEnvelope(attack: 0.25, release: 0.35)
        static let padLight = ProceduralEnvelope(attack: 0.18, release: 0.3)
        static let swell = ProceduralEnvelope(attack: 0.4, release: 0.45)
    }

    private enum Waveform {
        case sine
        case triangle
        case square
        case saw
    }

    // MARK: Storage

    private var soundCache: [SoundEffect: Data] = [:]
    private var musicCache: [MusicTrack: Data] = [:]
    private let sampleRate: Double = 44_100

    // MARK: Public API

    mutating func soundEffectData(for effect: SoundEffect) -> Data? {
        if let cached = soundCache[effect] {
            return cached
        }

        guard let pattern = soundPattern(for: effect) else {
            return nil
        }

        let data = render(pattern: pattern)
        soundCache[effect] = data
        return data
    }

    mutating func musicData(for track: MusicTrack) -> Data? {
        if let cached = musicCache[track] {
            return cached
        }

        let pattern = musicPattern(for: track)
        let data = render(pattern: pattern)
        musicCache[track] = data
        return data
    }

    // MARK: Pattern Definitions

    private func soundPattern(for effect: SoundEffect) -> ProceduralPattern? {
        switch effect {
        case .pickup:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(83), note(90)],
                        duration: 0.12,
                        amplitude: 0.34,
                        waveform: .sine,
                        envelope: .snappy
                    )
                ],
                sampleRate: sampleRate
            )

        case .placeValid:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(78), note(83)],
                        duration: 0.16,
                        amplitude: 0.38,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(90)],
                        duration: 0.08,
                        amplitude: 0.27,
                        waveform: .triangle,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .placeInvalid:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(46), note(50)],
                        duration: 0.18,
                        amplitude: 0.42,
                        waveform: .square,
                        envelope: .punchy
                    ),
                    .tone(
                        frequencies: [note(38)],
                        duration: 0.18,
                        amplitude: 0.36,
                        waveform: .saw,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .lineClear1:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(70), note(74)],
                        duration: 0.18,
                        amplitude: 0.32,
                        waveform: .sine,
                        envelope: .snappy
                    )
                ],
                sampleRate: sampleRate
            )

        case .lineClear2:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(72), note(76)],
                        duration: 0.16,
                        amplitude: 0.34,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(79)],
                        duration: 0.12,
                        amplitude: 0.32,
                        waveform: .triangle,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .lineClear3:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(74), note(79)],
                        duration: 0.14,
                        amplitude: 0.34,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(83)],
                        duration: 0.14,
                        amplitude: 0.34,
                        waveform: .triangle,
                        envelope: .tight
                    ),
                    .tone(
                        frequencies: [note(88)],
                        duration: 0.14,
                        amplitude: 0.32,
                        waveform: .sine,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .lineClear4:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(76), note(83)],
                        duration: 0.14,
                        amplitude: 0.35,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(88)],
                        duration: 0.12,
                        amplitude: 0.34,
                        waveform: .triangle,
                        envelope: .tight
                    ),
                    .tone(
                        frequencies: [note(93)],
                        duration: 0.12,
                        amplitude: 0.32,
                        waveform: .sine,
                        envelope: .tight
                    ),
                    .tone(
                        frequencies: [note(100)],
                        duration: 0.12,
                        amplitude: 0.3,
                        waveform: .triangle,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .combo2x:
            var segments: [ProceduralSegment] = []
            for _ in 0..<2 {
                segments.append(
                    .tone(
                        frequencies: [note(79), note(83)],
                        duration: 0.12,
                        amplitude: 0.35,
                        waveform: .sine,
                        envelope: .snappy
                    )
                )
                segments.append(.silence(0.05))
            }
            return ProceduralPattern(segments: segments, sampleRate: sampleRate)

        case .combo5x:
            var segments: [ProceduralSegment] = []
            for _ in 0..<3 {
                segments.append(
                    .tone(
                        frequencies: [note(81), note(86)],
                        duration: 0.12,
                        amplitude: 0.36,
                        waveform: .sine,
                        envelope: .snappy
                    )
                )
                segments.append(.silence(0.04))
            }
            segments.append(
                .tone(
                    frequencies: [note(93)],
                    duration: 0.16,
                    amplitude: 0.34,
                    waveform: .triangle,
                    envelope: .tight
                )
            )
            return ProceduralPattern(segments: segments, sampleRate: sampleRate)

        case .combo8x:
            var segments: [ProceduralSegment] = []
            for index in 0..<4 {
                let base = 83 + index * 2
                segments.append(
                    .tone(
                        frequencies: [note(base), note(base + 4)],
                        duration: 0.11,
                        amplitude: 0.36,
                        waveform: .sine,
                        envelope: .snappy
                    )
                )
                segments.append(.silence(0.04))
            }
            segments.append(
                .tone(
                    frequencies: [note(101)],
                    duration: 0.18,
                    amplitude: 0.35,
                    waveform: .triangle,
                    envelope: .tight
                )
            )
            return ProceduralPattern(segments: segments, sampleRate: sampleRate)

        case .combo10x:
            var segments: [ProceduralSegment] = []
            for index in 0..<5 {
                let base = 84 + index * 2
                segments.append(
                    .tone(
                        frequencies: [note(base)],
                        duration: 0.1,
                        amplitude: 0.35,
                        waveform: .sine,
                        envelope: .snappy
                    )
                )
                segments.append(.silence(0.035))
            }
            segments.append(
                .tone(
                    frequencies: [note(108)],
                    duration: 0.2,
                    amplitude: 0.36,
                    waveform: .triangle,
                    envelope: .tight
                )
            )
            segments.append(
                .tone(
                    frequencies: [note(112)],
                    duration: 0.12,
                    amplitude: 0.32,
                    waveform: .sine,
                    envelope: .tight
                )
            )
            return ProceduralPattern(segments: segments, sampleRate: sampleRate)

        case .perfectClear:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(76), note(88)],
                        duration: 0.16,
                        amplitude: 0.34,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(88), note(95)],
                        duration: 0.18,
                        amplitude: 0.35,
                        waveform: .triangle,
                        envelope: .tight
                    ),
                    .tone(
                        frequencies: [note(100), note(107)],
                        duration: 0.22,
                        amplitude: 0.36,
                        waveform: .sine,
                        envelope: .swell
                    )
                ],
                sampleRate: sampleRate
            )

        case .gameOver:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(64)],
                        duration: 0.24,
                        amplitude: 0.36,
                        waveform: .saw,
                        envelope: .punchy
                    ),
                    .tone(
                        frequencies: [note(57)],
                        duration: 0.22,
                        amplitude: 0.34,
                        waveform: .square,
                        envelope: .tight
                    ),
                    .tone(
                        frequencies: [note(52)],
                        duration: 0.25,
                        amplitude: 0.32,
                        waveform: .sine,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .holdSwap:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(70), note(74)],
                        duration: 0.14,
                        amplitude: 0.32,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(79)],
                        duration: 0.14,
                        amplitude: 0.32,
                        waveform: .triangle,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .powerUp:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(74), note(81)],
                        duration: 0.14,
                        amplitude: 0.34,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(86)],
                        duration: 0.14,
                        amplitude: 0.34,
                        waveform: .triangle,
                        envelope: .tight
                    ),
                    .tone(
                        frequencies: [note(93), note(98)],
                        duration: 0.18,
                        amplitude: 0.36,
                        waveform: .sine,
                        envelope: .swell
                    )
                ],
                sampleRate: sampleRate
            )

        case .achievement:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(95)],
                        duration: 0.12,
                        amplitude: 0.33,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(100), note(107)],
                        duration: 0.18,
                        amplitude: 0.34,
                        waveform: .triangle,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .menuTap:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(68)],
                        duration: 0.09,
                        amplitude: 0.28,
                        waveform: .sine,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .buttonPress:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(73)],
                        duration: 0.1,
                        amplitude: 0.3,
                        waveform: .sine,
                        envelope: .tight
                    )
                ],
                sampleRate: sampleRate
            )

        case .levelComplete:
            return ProceduralPattern(
                segments: [
                    .tone(
                        frequencies: [note(76), note(83)],
                        duration: 0.14,
                        amplitude: 0.33,
                        waveform: .sine,
                        envelope: .snappy
                    ),
                    .tone(
                        frequencies: [note(88)],
                        duration: 0.14,
                        amplitude: 0.34,
                        waveform: .triangle,
                        envelope: .tight
                    ),
                    .tone(
                        frequencies: [note(95)],
                        duration: 0.2,
                        amplitude: 0.35,
                        waveform: .sine,
                        envelope: .swell
                    )
                ],
                sampleRate: sampleRate
            )
        }
    }

    private func musicPattern(for track: MusicTrack) -> ProceduralPattern {
        let chords: [[Int]]
        let duration: Double
        let amplitude: Double
        let highOctaveScale: Double
        let accentScale: Double
        var segments: [ProceduralSegment]

        switch track {
        case .menu:
            chords = [[60, 64, 67], [57, 62, 69], [65, 69, 72], [62, 65, 69]]
            duration = 2.0
            amplitude = 0.22
            highOctaveScale = 0.45
            accentScale = 0.2
            segments = ambientSegments(
                chords: chords,
                segmentDuration: duration,
                amplitude: amplitude,
                highOctaveScale: highOctaveScale,
                accentScale: accentScale
            )
            segments.append(.silence(0.2))

        case .endless:
            chords = [[57, 60, 64], [55, 59, 62], [62, 65, 69], [60, 64, 67]]
            duration = 1.5
            amplitude = 0.24
            highOctaveScale = 0.5
            accentScale = 0.28
            segments = ambientSegments(
                chords: chords,
                segmentDuration: duration,
                amplitude: amplitude,
                highOctaveScale: highOctaveScale,
                accentScale: accentScale
            )
            segments.append(.tone(
                frequencies: [note(88)],
                duration: 0.5,
                amplitude: 0.26,
                waveform: .triangle,
                envelope: .padLight
            ))
            segments.append(.silence(0.18))

        case .timed:
            chords = [[69, 72, 76], [71, 74, 78], [72, 76, 79], [71, 74, 78]]
            duration = 1.1
            amplitude = 0.25
            highOctaveScale = 0.4
            accentScale = 0.32
            segments = ambientSegments(
                chords: chords,
                segmentDuration: duration,
                amplitude: amplitude,
                highOctaveScale: highOctaveScale,
                accentScale: accentScale
            )
            segments.append(.silence(0.15))

        case .timedFinale:
            chords = [[72, 75, 79], [74, 77, 81], [76, 79, 83], [77, 81, 84]]
            duration = 0.9
            amplitude = 0.27
            highOctaveScale = 0.5
            accentScale = 0.36
            segments = ambientSegments(
                chords: chords,
                segmentDuration: duration,
                amplitude: amplitude,
                highOctaveScale: highOctaveScale,
                accentScale: accentScale
            )
            segments.append(.tone(
                frequencies: [note(95)],
                duration: 0.6,
                amplitude: 0.31,
                waveform: .sine,
                envelope: .swell
            ))
            segments.append(.silence(0.1))

        case .levels:
            chords = [[60, 64, 67], [62, 65, 69], [64, 67, 71], [65, 69, 72]]
            duration = 1.7
            amplitude = 0.23
            highOctaveScale = 0.5
            accentScale = 0.24
            segments = ambientSegments(
                chords: chords,
                segmentDuration: duration,
                amplitude: amplitude,
                highOctaveScale: highOctaveScale,
                accentScale: accentScale
            )
            segments.append(.silence(0.2))

        case .puzzle:
            chords = [[65, 69, 72], [64, 67, 71], [62, 65, 69], [60, 64, 67]]
            duration = 2.2
            amplitude = 0.2
            highOctaveScale = 0.35
            accentScale = 0
            segments = ambientSegments(
                chords: chords,
                segmentDuration: duration,
                amplitude: amplitude,
                highOctaveScale: highOctaveScale,
                accentScale: accentScale
            )
            segments.append(.tone(
                frequencies: [note(86)],
                duration: 0.5,
                amplitude: 0.22,
                waveform: .triangle,
                envelope: .padLight
            ))
            segments.append(.silence(0.3))

        case .zen:
            chords = [[57, 60, 64], [55, 59, 62], [52, 55, 59], [50, 53, 57]]
            duration = 2.8
            amplitude = 0.18
            highOctaveScale = 0.3
            accentScale = 0
            segments = ambientSegments(
                chords: chords,
                segmentDuration: duration,
                amplitude: amplitude,
                highOctaveScale: highOctaveScale,
                accentScale: accentScale
            )
            segments.append(.tone(
                frequencies: [note(69)],
                duration: 0.6,
                amplitude: 0.2,
                waveform: .sine,
                envelope: .swell
            ))
            segments.append(.silence(0.4))
        }

        return ProceduralPattern(segments: segments, sampleRate: sampleRate)
    }

    // MARK: Rendering

    private func render(pattern: ProceduralPattern) -> Data {
        var samples: [Int16] = []
        samples.reserveCapacity(Int(pattern.sampleRate * max(0.1, pattern.segments.reduce(0) { $0 + $1.duration })))

        for segment in pattern.segments {
            samples.append(contentsOf: render(segment: segment, sampleRate: pattern.sampleRate))
        }

        return makeWaveData(from: samples, sampleRate: pattern.sampleRate)
    }

    private func render(segment: ProceduralSegment, sampleRate: Double) -> [Int16] {
        let totalSamples = max(1, Int(segment.duration * sampleRate))

        if segment.frequencies.isEmpty || segment.amplitude == 0 {
            return Array(repeating: 0, count: totalSamples)
        }

        var attackSamples = Int(Double(totalSamples) * segment.envelope.attack)
        var releaseSamples = Int(Double(totalSamples) * segment.envelope.release)

        if attackSamples + releaseSamples > totalSamples {
            let overflow = attackSamples + releaseSamples - totalSamples
            if releaseSamples > attackSamples {
                releaseSamples = max(0, releaseSamples - overflow)
            } else {
                attackSamples = max(0, attackSamples - overflow)
            }
        }

        let releaseStart = max(attackSamples, totalSamples - releaseSamples)

        var rendered: [Int16] = []
        rendered.reserveCapacity(totalSamples)

        for sampleIndex in 0..<totalSamples {
            let time = Double(sampleIndex) / sampleRate
            var combined: Double = 0

            for frequency in segment.frequencies {
                combined += waveformSample(
                    segment.waveform,
                    cyclePosition: frequency * time
                )
            }

            combined /= Double(segment.frequencies.count)

            var amplitude = segment.amplitude
            if attackSamples > 0 && sampleIndex < attackSamples {
                amplitude *= Double(sampleIndex) / Double(attackSamples)
            } else if releaseSamples > 0 && sampleIndex >= releaseStart {
                let remaining = releaseStart + releaseSamples - sampleIndex
                amplitude *= Double(max(0, remaining)) / Double(max(1, releaseSamples))
            }

            let clamped = max(-1.0, min(1.0, combined * amplitude))
            rendered.append(Int16(clamped * Double(Int16.max)))
        }

        return rendered
    }

    private func waveformSample(_ waveform: Waveform, cyclePosition: Double) -> Double {
        let normalized = cyclePosition - floor(cyclePosition)

        switch waveform {
        case .sine:
            return sin(2.0 * .pi * normalized)
        case .triangle:
            return 4.0 * abs(normalized - 0.5) - 1.0
        case .square:
            return normalized < 0.5 ? 1.0 : -1.0
        case .saw:
            return (2.0 * normalized) - 1.0
        }
    }

    private func makeWaveData(from samples: [Int16], sampleRate: Double) -> Data {
        var data = Data()
        let subchunk2Size = UInt32(samples.count * MemoryLayout<Int16>.size)
        let chunkSize = UInt32(36) + subchunk2Size
        let byteRate = UInt32(sampleRate.rounded()) * UInt32(MemoryLayout<Int16>.size)
        let blockAlign = UInt16(MemoryLayout<Int16>.size)

        data.reserveCapacity(Int(subchunk2Size) + 44)

        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.appendLittleEndian(chunkSize)
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6d, 0x74, 0x20]) // "fmt "
        data.appendLittleEndian(UInt32(16))
        data.appendLittleEndian(UInt16(1)) // PCM format
        data.appendLittleEndian(UInt16(1)) // Mono channel
        data.appendLittleEndian(UInt32(sampleRate.rounded()))
        data.appendLittleEndian(byteRate)
        data.appendLittleEndian(blockAlign)
        data.appendLittleEndian(UInt16(16)) // Bits per sample
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.appendLittleEndian(subchunk2Size)

        var littleEndianSamples = samples.map { $0.littleEndian }
        littleEndianSamples.withUnsafeBytes { buffer in
            data.append(contentsOf: buffer)
        }

        return data
    }

    // MARK: Helpers

    private func note(_ midi: Int) -> Double {
        440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }

    private func ambientSegments(
        chords: [[Int]],
        segmentDuration: Double,
        amplitude: Double,
        highOctaveScale: Double,
        accentScale: Double
    ) -> [ProceduralSegment] {
        var segments: [ProceduralSegment] = []

        for chord in chords {
            let baseFrequencies = chord.map(note)
            segments.append(
                .tone(
                    frequencies: baseFrequencies,
                    duration: segmentDuration,
                    amplitude: amplitude,
                    waveform: .sine,
                    envelope: .pad
                )
            )

            if highOctaveScale > 0 {
                let upper = chord.map { note($0 + 12) }
                segments.append(
                    .tone(
                        frequencies: upper,
                        duration: segmentDuration * 0.85,
                        amplitude: amplitude * highOctaveScale,
                        waveform: .triangle,
                        envelope: .padLight
                    )
                )
            }

            if accentScale > 0 {
                let accentNote = (chord.max() ?? chord[0]) + 12
                segments.append(
                    .tone(
                        frequencies: [note(accentNote)],
                        duration: segmentDuration * 0.35,
                        amplitude: amplitude * accentScale,
                        waveform: .sine,
                        envelope: .tight
                    )
                )
                segments.append(.silence(segmentDuration * 0.15))
            }
        }

        return segments
    }
}

fileprivate extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { buffer in
            append(contentsOf: buffer)
        }
    }
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

    private var proceduralFactory = ProceduralAudioFactory()

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
        _ = ensureSoundPlayer(for: sound)
    }

    // MARK: - Sound Effect Playback

    func playSound(_ sound: SoundEffect, withDucking: Bool = false) {
        guard isSoundEnabled else { return }

        if withDucking {
            duckMusic()
        }

        guard let player = ensureSoundPlayer(for: sound) else { return }

        player.currentTime = 0
        player.volume = finalSFXVolume
        player.play()
    }

    @discardableResult
    private func ensureSoundPlayer(for sound: SoundEffect) -> AVAudioPlayer? {
        if let cached = soundPlayers[sound.fileName] {
            return cached
        }

        if let filePlayer = createFileBackedPlayer(for: sound) {
            soundPlayers[sound.fileName] = filePlayer
            return filePlayer
        }

        if let fallbackPlayer = createProceduralPlayer(for: sound) {
            soundPlayers[sound.fileName] = fallbackPlayer
            logger.info("Using procedural fallback for sound effect: \(sound.fileName)")
            return fallbackPlayer
        }

        logger.warning("Sound file and fallback unavailable: \(sound.fileName)")
        return nil
    }

    private func createFileBackedPlayer(for sound: SoundEffect) -> AVAudioPlayer? {
        let extensions = ["m4a", "wav", "mp3"]

        for ext in extensions {
            if let url = Bundle.main.url(forResource: sound.fileName, withExtension: ext) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.volume = finalSFXVolume
                    player.prepareToPlay()
                    return player
                } catch {
                    logger.error("Failed to load sound \(sound.fileName).\(ext): \(error.localizedDescription)")
                }
            }
        }

        return nil
    }

    private func createProceduralPlayer(for sound: SoundEffect) -> AVAudioPlayer? {
        guard let data = proceduralFactory.soundEffectData(for: sound) else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
            player.volume = finalSFXVolume
            player.prepareToPlay()
            return player
        } catch {
            logger.error("Failed to create procedural sound for \(sound.fileName): \(error.localizedDescription)")
            return nil
        }
    }

    private func loadMusicPlayer(for track: MusicTrack, loop: Bool) -> AVAudioPlayer? {
        if let filePlayer = createFileBackedMusicPlayer(for: track) {
            filePlayer.numberOfLoops = loop ? -1 : 0
            return filePlayer
        }

        guard let fallbackPlayer = createProceduralMusicPlayer(for: track) else {
            return nil
        }

        fallbackPlayer.numberOfLoops = loop ? -1 : 0
        logger.info("Using procedural fallback for music track: \(track.fileName)")
        return fallbackPlayer
    }

    private func createFileBackedMusicPlayer(for track: MusicTrack) -> AVAudioPlayer? {
        let extensions = ["m4a", "mp3", "wav"]

        for ext in extensions {
            if let url = Bundle.main.url(forResource: track.fileName, withExtension: ext) {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.volume = finalMusicVolume
                    player.prepareToPlay()
                    return player
                } catch {
                    logger.error("Failed to load music \(track.fileName).\(ext): \(error.localizedDescription)")
                }
            }
        }

        return nil
    }

    private func createProceduralMusicPlayer(for track: MusicTrack) -> AVAudioPlayer? {
        guard let data = proceduralFactory.musicData(for: track) else {
            return nil
        }

        do {
            let player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
            player.volume = finalMusicVolume
            player.prepareToPlay()
            return player
        } catch {
            logger.error("Failed to create procedural music for \(track.fileName): \(error.localizedDescription)")
            return nil
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

        guard let player = loadMusicPlayer(for: track, loop: loop) else {
            logger.warning("Music file and fallback unavailable: \(track.fileName)")
            return
        }

        musicPlayer?.stop()
        musicPlayer = player
        musicPlayer?.numberOfLoops = loop ? -1 : 0
        musicPlayer?.volume = finalMusicVolume
        musicPlayer?.prepareToPlay()
        musicPlayer?.play()
        currentTrack = track
        logger.info("Playing music: \(track.fileName)")
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
