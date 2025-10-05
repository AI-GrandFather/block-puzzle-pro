# Feature: Zen Mode (Relaxation Experience)

**Priority:** MEDIUM
**Timeline:** Week 5-6
**Dependencies:** Core game engine, theme system, audio system
**Performance Target:** 60fps, smooth animations, low battery usage

---

## Overview

Implement a Zen Mode focused on relaxation, mindfulness, and stress-free gameplay. This mode removes all competitive elements, pressure, and failure states, creating a meditative experience where players can enjoy block placement at their own pace.

---

## Core Zen Principles

### No Pressure, No Failure

**Key Design Pillars:**
1. **No Game Over:** Board never fills to the point of unplayability
2. **No Timer:** Play at your own pace, no time limits
3. **No Scoring:** Focus on experience, not points
4. **No Competition:** No leaderboards or comparisons
5. **Infinite Undo:** Reverse any move, unlimited times
6. **Assistance:** Gentle help when board gets too full

```swift
struct ZenModeConfiguration {
    let enableGameOver: Bool = false
    let enableTimer: Bool = false
    let enableScoring: Bool = false // Score tracked but not shown prominently
    let enableLeaderboards: Bool = false
    let unlimitedUndo: Bool = true
    let boardAssistance: Bool = true // Auto-clear oldest blocks when full
    let piecePreview: Bool = true // Show next 3 pieces
    let breathingGuide: Bool = true // Optional breathing exercise overlay
}
```

---

## Zen Features

### 1. Unlimited Undo

**Implementation:**
```swift
class ZenUndoManager {
    private var history: [GridState] = []
    private let maxHistorySize = 100 // Keep last 100 moves

    func recordState(_ state: GridState) {
        history.append(state)

        // Limit history to prevent memory issues
        if history.count > maxHistorySize {
            history.removeFirst()
        }
    }

    func undo() -> GridState? {
        guard history.count > 1 else { return nil }

        // Remove current state
        history.removeLast()

        // Return previous state
        return history.last
    }

    func canUndo() -> Bool {
        return history.count > 1
    }
}
```

**UI:**
- Undo button always visible (top-left corner)
- Shows number of moves that can be undone
- Smooth reverse animation (0.3s)
- Haptic feedback on undo
- No cost, no limit

```
┌───────────────┐
│ ↩️ Undo (45) │
└───────────────┘
```

### 2. Piece Preview System

**Show Next 3 Pieces:**
```swift
class PiecePreviewSystem {
    private var upcomingPieces: [Piece] = []

    func generatePreview(count: Int = 3) {
        // Generate next N pieces deterministically
        upcomingPieces = (0..<count).map { _ in
            PieceGenerator.generateRandomPiece()
        }
    }

    func getPreview() -> [Piece] {
        return upcomingPieces
    }

    func consumeNextPiece() -> Piece {
        let piece = upcomingPieces.removeFirst()
        upcomingPieces.append(PieceGenerator.generateRandomPiece())
        return piece
    }
}
```

**UI Display:**
```
┌─────────────────────────────┐
│  Next Pieces:               │
│  ┌───┐ ┌───┐ ┌───┐          │
│  │ ▪️ │ │▪️▪️│ │▪️  │          │
│  │   │ │   │ │▪️▪️│          │
│  └───┘ └───┘ └───┘          │
│   #1    #2    #3            │
└─────────────────────────────┘
```

**Benefits:**
- Plan ahead without pressure
- Strategic placement
- Reduces anxiety of unknown pieces
- Encourages thoughtful play

### 3. Auto-Clear Assistance

**Prevents Board Deadlock:**

```swift
class ZenBoardAssistance {
    func checkBoardFullness(_ gridState: GridState) -> AssistanceAction? {
        let fullness = calculateFullness(gridState)

        if fullness > 0.85 { // 85% full
            return .suggestClear(cells: findOldestBlocks(gridState, count: 8))
        } else if fullness > 0.95 { // 95% full
            return .autoClear(cells: findOldestBlocks(gridState, count: 12))
        }

        return nil
    }

    private func calculateFullness(_ gridState: GridState) -> Double {
        let totalCells = gridState.rows * gridState.cols
        let filledCells = gridState.countFilledCells()
        return Double(filledCells) / Double(totalCells)
    }

    private func findOldestBlocks(_ gridState: GridState, count: Int) -> [GridCell] {
        // Return cells placed longest ago
        return gridState.allCells()
            .filter { !$0.isEmpty }
            .sorted { $0.placementTime < $1.placementTime }
            .prefix(count)
            .map { $0 }
    }
}
```

**Assistance Actions:**
- **85% Full:** Gentle suggestion - highlight oldest blocks with pulsing glow
  * "The board is getting full. Clear these blocks to make space?"
  * [ CLEAR SUGGESTED ] [ NOT NOW ]
- **95% Full:** Automatic assistance - oldest blocks slowly fade and disappear
  * "Making room for you... ✨"
  * Peaceful fade-out animation (2 seconds)
  * No penalty, no negative feedback

**Visual Feedback:**
- Suggested blocks glow softly
- Fade animation for auto-cleared blocks
- Gentle particle effect (like dust dispersing)
- Calm, reassuring UI messages

### 4. Breathing Guide

**Optional Breathing Exercise Overlay:**

```swift
struct BreathingGuide {
    enum Phase {
        case inhale(duration: TimeInterval)
        case hold(duration: TimeInterval)
        case exhale(duration: TimeInterval)
        case rest(duration: TimeInterval)
    }

    let pattern: [Phase] = [
        .inhale(duration: 4.0),
        .hold(duration: 4.0),
        .exhale(duration: 4.0),
        .rest(duration: 2.0)
    ]

    var cycleTime: TimeInterval {
        return pattern.reduce(0) { total, phase in
            switch phase {
            case .inhale(let d), .hold(let d), .exhale(let d), .rest(let d):
                return total + d
            }
        }
    }
}
```

**UI Implementation:**
```
┌─────────────────────────────┐
│                             │
│                             │
│         🌀                  │ Animated circle
│     ( Breathing )           │ Expands/contracts
│                             │
│      BREATHE IN             │ Text changes per phase
│      ●●●●○○○○○○○○           │ Progress dots
│                             │
└─────────────────────────────┘
```

**Animation:**
- Circle starts small
- **Inhale (4s):** Circle expands smoothly, text: "BREATHE IN"
- **Hold (4s):** Circle remains large, text: "HOLD"
- **Exhale (4s):** Circle contracts smoothly, text: "BREATHE OUT"
- **Rest (2s):** Circle remains small, text: "REST"
- Repeat cycle

**Features:**
- Toggle on/off in settings
- Opacity adjustable (10%-50%)
- Position adjustable (top, center, bottom)
- Haptic pulses synced to breathing (optional)
- Gentle chime at cycle transitions (optional)

### 5. Ambient Music & Sounds

**Zen Soundscape:**

```swift
enum ZenAudioTheme: String, CaseIterable {
    case rain = "Gentle Rain"
    case ocean = "Ocean Waves"
    case forest = "Forest Birds"
    case windChimes = "Wind Chimes"
    case singingBowls = "Singing Bowls"
    case whiteNoise = "White Noise"
    case silence = "Silence"

    var audioFile: String {
        return "zen_\(rawValue.lowercased().replacingOccurrences(of: " ", with: "_")).m4a"
    }

    var bpm: Int? {
        switch self {
        case .singingBowls: return 60 // Rhythmic
        default: return nil // Ambient, no beat
        }
    }
}
```

**Audio Characteristics:**
- Looping seamless audio tracks (3-5 minutes each)
- No jarring transitions
- Natural fade in/out (3 seconds)
- Volume separate from game SFX
- Mix with game sounds (blocks placing, lines clearing)

**Sound Effects (Zen Mode Variants):**
- Block placement: Soft, muted "thud" (like wood on felt)
- Line clear: Gentle chime (C major chord, soft attack)
- Perfect clear: Peaceful cascade of notes (harp glissando)
- No harsh or sudden sounds

### 6. Slowed Animations

**All Animations 30% Slower:**

```swift
struct ZenAnimationConfig {
    static let blockFallDuration: TimeInterval = 0.4 // vs 0.3 in normal mode
    static let lineClearDuration: TimeInterval = 0.5 // vs 0.35 in normal mode
    static let particleDuration: TimeInterval = 0.8 // vs 0.6 in normal mode
    static let transitionDuration: TimeInterval = 0.65 // vs 0.5 in normal mode

    static let easingCurve: AnimationCurve = .easeInOut // Gentle, no sudden movements
}
```

**Visual Pacing:**
- Slower = more calming
- Reduces visual stress
- Allows for contemplation
- Encourages mindful observation

### 7. Peaceful Color Palette

**Muted Pastels:**

```swift
struct ZenColorPalette {
    // Background
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "F0F4F8"), // Soft blue-gray
            Color(hex: "E6F1F5")  // Lighter blue-gray
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Grid
    static let gridCell = Color(hex: "FFFFFF").opacity(0.6)
    static let gridBorder = Color(hex: "D0E0E8")

    // Block Colors (desaturated, soft)
    static let blockColors: [Color] = [
        Color(hex: "C9E4CA"), // Soft mint
        Color(hex: "C1D3FE"), // Soft periwinkle
        Color(hex: "FFE6CC"), // Soft peach
        Color(hex: "E8C4D4"), // Soft rose
        Color(hex: "D4E4BC"), // Soft sage
        Color(hex: "F0E2D4")  // Soft beige
    ]

    // UI Text
    static let textPrimary = Color(hex: "5A6C7D")
    static let textSecondary = Color(hex: "8A9BAD")

    // No harsh contrasts
    // No saturated colors
    // No neon or bright colors
}
```

**Visual Principles:**
- Low contrast for reduced eye strain
- Soft, rounded corners everywhere (16px radius)
- Subtle shadows, no harsh edges
- Gentle gradients
- Minimal UI elements

### 8. Optional Grid Display

**Hide Grid Lines:**

```swift
class ZenVisualSettings {
    @AppStorage("zenMode_showGrid") var showGrid: Bool = true
    @AppStorage("zenMode_showUI") var showUI: Bool = true
    @AppStorage("zenMode_showStats") var showStats: Bool = false

    func applySettings(to view: ZenGameView) {
        view.gridVisible = showGrid
        view.uiVisible = showUI
        view.statsVisible = showStats
    }
}
```

**Benefits of Hiding Grid:**
- Cleaner visual field
- Focus on shapes and patterns
- Less "game-like", more artistic
- Meditative aesthetic

**Toggle in Settings:**
```
Zen Mode Settings:
├─ Show Grid Lines: [ON] / OFF
├─ Show UI Elements: [ON] / OFF
├─ Show Statistics: ON / [OFF]
└─ Breathing Guide: ON / [OFF]
```

### 9. Meditation Timer

**Optional Session Length:**

```swift
enum MeditationDuration: Int, CaseIterable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case twenty = 20
    case thirty = 30
    case infinite = 0 // No timer

    var displayName: String {
        switch self {
        case .infinite: return "No Limit"
        default: return "\(rawValue) Minutes"
        }
    }

    var seconds: Int {
        return rawValue * 60
    }
}
```

**Timer UI:**
```
┌───────────────────────────┐
│   Session: 15 minutes     │
│   Elapsed: 08:32          │
│   Remaining: 06:28        │
│   ⏸️ Pause  |  ⏹️ End     │
└───────────────────────────┘
```

**Session Flow:**
1. **Pre-Session (Optional):**
   - Brief breathing exercise (1 minute)
   - "Set your intention for this session"
   - Fade in ambient music

2. **Active Session:**
   - Timer counts up (elapsed) and down (remaining)
   - Gentle notification at halfway point (optional)
   - Visual: Soft circular progress indicator

3. **Session End:**
   - Gentle chime (3-tone descending)
   - Fade out music (10 seconds)
   - Summary screen

**End of Session Summary:**
```
┌─────────────────────────────────┐
│   Session Complete 🙏           │
│                                 │
│   Duration: 15:00               │
│   Blocks Placed: 127            │
│   Lines Cleared: 34             │
│   Perfect Clears: 3             │
│                                 │
│   "You created beautiful        │
│    patterns today. Well done."  │
│                                 │
│   [  NEW SESSION  ] [  EXIT  ]  │
└─────────────────────────────────┘
```

---

## Zen Statistics (Non-Competitive)

### Personal Insights Only

**No Comparisons, No Rankings:**

```swift
struct ZenStatistics: Codable {
    // Session Stats
    var totalSessions: Int = 0
    var totalPlayTime: TimeInterval = 0
    var longestSession: TimeInterval = 0
    var averageSessionLength: TimeInterval = 0

    // Gameplay Stats
    var totalBlocksPlaced: Int = 0
    var totalLinesCleared: Int = 0
    var totalPerfectClears: Int = 0

    // Patterns
    var favoritePieces: [PieceType: Int] = [:] // Usage count
    var mostCommonClearPattern: ClearPattern?

    // Streaks
    var currentDailyStreak: Int = 0
    var longestDailyStreak: Int = 0

    // Calendar
    var playHistory: [Date: SessionSummary] = [:]
}
```

**Statistics Screen:**
```
┌─────────────────────────────────┐
│   Your Zen Journey 🧘           │
│                                 │
│   Total Play Time:              │
│   ████████████░░░░ 24h 32m      │
│                                 │
│   Sessions Completed: 47        │
│   Average Length: 31 minutes    │
│   Longest Session: 1h 15m       │
│                                 │
│   Blocks Placed: 5,847          │
│   Lines Cleared: 1,203          │
│   Perfect Clears: 87            │
│                                 │
│   Daily Streak: 🔥 12 days      │
│   Longest Streak: 🔥 18 days    │
│                                 │
│   Favorite Piece: L-Shape (23%) │
│                                 │
│   📅 [View Calendar]            │
└─────────────────────────────────┘
```

**Calendar View:**
```
┌─────────────────────────────────┐
│   December 2025                 │
│                                 │
│   Mon Tue Wed Thu Fri Sat Sun   │
│    1   2   3   4   5   6   7    │
│   ●   ●   ○   ●   ●   ○   ●    │
│    8   9  10  11  12  13  14    │
│   ●   ●   ●   ●   ●   ●   ●    │
│   15  16  17  18  19  20  21    │
│   ●   ●   ●   ●   ●   ●   ●    │
│   22  23  24  25  26  27  28    │
│   ●   ○   ○   ●   ●   ●   ●    │
│   29  30  31                    │
│   ●   ●   ○                     │
│                                 │
│   ● Played  ○ Missed            │
│   Tap any day for details       │
└─────────────────────────────────┘
```

**Daily Detail:**
```
┌─────────────────────────────────┐
│   December 15, 2025             │
│                                 │
│   Sessions: 2                   │
│   Total Time: 45 minutes        │
│                                 │
│   Morning Session (9:15 AM)     │
│   • Duration: 20 minutes        │
│   • Blocks: 78                  │
│   • Lines: 19                   │
│                                 │
│   Evening Session (8:30 PM)     │
│   • Duration: 25 minutes        │
│   • Blocks: 94                  │
│   • Lines: 23                   │
│                                 │
│   Insights:                     │
│   "You played during calm       │
│   hours. Great for relaxation!" │
└─────────────────────────────────┘
```

---

## Zen UI Design

### Minimal Interface

**Hidden Controls (Swipe to Reveal):**

```
┌─────────────────────────────────┐
│                                 │ Swipe down from top:
│                                 │   ↓ Settings
│                                 │
│        [8x8 GRID]               │ Swipe up from bottom:
│     (Full screen)               │   ↑ Statistics
│                                 │
│                                 │ Swipe right from left:
│                                 │   → Pause Menu
│                                 │
└─────────────────────────────────┘
```

**Default View (Clean):**
- Only grid visible
- Small undo button (top-left, 30% opacity, fades if unused)
- Piece preview (bottom, translucent)
- Everything else hidden

**Revealed UI (Swipe gesture):**
- Settings overlay slides in
- Translucent background (80% opacity)
- Soft blur effect
- Tap outside to dismiss

### Focus Mode

**Hide All UI:**

```swift
class FocusMode {
    @Published var isActive: Bool = false

    func activate() {
        isActive = true
        // Hide all UI except grid and pieces
        // Disable gestures except piece placement
        // Optional: Dim screen slightly
        // Optional: Enable "Do Not Disturb" suggestion
    }

    func deactivate() {
        isActive = false
        // Restore UI
    }
}
```

**Visual:**
- Grid occupies 95% of screen
- No buttons, no text
- Only piece tray and grid
- Pure, minimalist aesthetic

**Toggle:**
```
Settings → Zen Mode → Focus Mode: ON / [OFF]
```

### Dimmed Ambient Lighting

**Evening Play:**

```swift
enum AmbientLighting {
    case auto // Based on time of day
    case day // Brighter
    case evening // Dimmed
    case night // Very dim

    var brightness: Double {
        switch self {
        case .auto:
            let hour = Calendar.current.component(.hour, from: Date())
            if hour >= 6 && hour < 18 {
                return 1.0 // Day
            } else if hour >= 18 && hour < 22 {
                return 0.7 // Evening
            } else {
                return 0.5 // Night
            }
        case .day: return 1.0
        case .evening: return 0.7
        case .night: return 0.5
        }
    }

    var colorTemperature: Color {
        switch self {
        case .auto, .day:
            return .white
        case .evening:
            return Color(hex: "FFF8E1") // Warm white
        case .night:
            return Color(hex: "FFE8CC") // Warmer, amber tint
        }
    }
}
```

**Benefits:**
- Reduces blue light exposure
- Easier on eyes in dark environments
- Promotes relaxation before sleep
- Respects circadian rhythm

---

## Zen Session Flow

### 1. Session Start

**Welcome Screen:**
```
┌─────────────────────────────────┐
│   Welcome to Zen Mode 🧘        │
│                                 │
│   Take a moment to breathe      │
│   and set your intention.       │
│                                 │
│   Session Length:               │
│   [ 5 ] [ 10 ] [ 15 ] [ 20 ]   │
│   [ 30 ] [ No Limit ]           │
│                                 │
│   Breathing Guide: ON / [OFF]   │
│                                 │
│   [ BEGIN SESSION ]             │
│   [ Skip to Game ]              │
└─────────────────────────────────┘
```

### 2. Optional Guided Intro (First Time)

**For New Users:**
```
┌─────────────────────────────────┐
│   Welcome! Let's start with a   │
│   brief breathing exercise.     │
│                                 │
│         🌀                      │
│                                 │
│      Follow the circle...       │
│                                 │
│   [  CONTINUE  ]  [  SKIP  ]    │
└─────────────────────────────────┘
```

**Sequence (30 seconds):**
1. Circle breathing animation (3 cycles)
2. "Great! Now, let's play mindfully."
3. Quick tutorial: "Place pieces at your own pace. There's no rush, no game over."
4. Fade to game

### 3. Active Session

**Gameplay:**
- Place pieces freely
- Clear lines naturally
- Use undo as needed
- Observe patterns forming
- Enjoy ambient music
- Breathe with guide (if enabled)

**Unobtrusive Reminders:**
- Every 15 minutes: "Remember to breathe" (gentle fade-in text, 5 seconds)
- Halfway through session (if timed): Soft chime, no text

### 4. Session End

**Gentle Fade-Out:**
1. Timer reaches 0:00
2. Gentle 3-tone chime (C-G-E, descending)
3. Music fades out over 10 seconds
4. Grid slowly fades to 50% opacity
5. Summary screen fades in

**Session Summary:**
```
┌─────────────────────────────────┐
│   Session Complete 🙏           │
│                                 │
│   Duration: 20:00               │
│   Blocks Placed: 84             │
│   Lines Cleared: 21             │
│                                 │
│   "You created harmony today.   │
│    Return whenever you need     │
│    a moment of peace."          │
│                                 │
│   💭 Optional Reflection:       │
│   "How do you feel?"            │
│   [ Calm ] [ Focused ]          │
│   [ Relaxed ] [ Energized ]     │
│                                 │
│   [  NEW SESSION  ] [  EXIT  ]  │
└─────────────────────────────────┘
```

**Mood Tracking (Optional):**
- Simple emotional check-in
- Saved for personal insights
- Shows trends over time
- Never shared

---

## Implementation Checklist

- [ ] Create ZenModeConfiguration with no-pressure settings
- [ ] Implement ZenUndoManager with unlimited undo
- [ ] Build PiecePreviewSystem showing next 3 pieces
- [ ] Create ZenBoardAssistance for auto-clear
- [ ] Implement BreathingGuide with animated circle
- [ ] Build ZenAudioTheme with ambient soundscapes
- [ ] Adjust animation speeds to 30% slower
- [ ] Create ZenColorPalette with muted pastels
- [ ] Implement optional grid hiding
- [ ] Build MeditationTimer with session management
- [ ] Create ZenStatistics tracking (non-competitive)
- [ ] Implement calendar view for play history
- [ ] Build minimal UI with swipe-to-reveal
- [ ] Create FocusMode hiding all UI
- [ ] Implement dimmed ambient lighting
- [ ] Build session start/end flow
- [ ] Create guided intro for first-time users
- [ ] Implement mood tracking (optional)
- [ ] Test relaxation and stress reduction
- [ ] Performance test for battery efficiency

---

## Success Criteria

✅ No game over state exists in Zen Mode
✅ Unlimited undo works flawlessly
✅ Piece preview shows next 3 pieces accurately
✅ Auto-clear assistance prevents board deadlock
✅ Breathing guide animates smoothly and accurately
✅ Ambient music loops seamlessly
✅ All animations are 30% slower than normal mode
✅ Color palette is calming and low-contrast
✅ Grid hiding works correctly
✅ Meditation timer tracks sessions accurately
✅ Statistics provide meaningful personal insights
✅ Calendar view displays play history clearly
✅ UI can be hidden for focus mode
✅ Dimmed lighting adjusts based on time
✅ Session flow feels peaceful and unhurried
✅ Users report feeling relaxed after sessions
✅ Battery usage is optimized for long sessions
✅ 60fps maintained throughout
✅ No jarring sounds or visuals
✅ Overall experience is calming and meditative
