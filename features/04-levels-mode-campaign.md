✅ COMPLETED - October 5, 2025
# Feature: Levels Mode (Campaign System)

**Priority:** HIGH
**Timeline:** Week 5-6
**Dependencies:** Core game engine, scoring system, piece generation
**Performance Target:** 60fps minimum, smooth progression UI

---

## Overview

Implement a comprehensive campaign-style Levels Mode with 50 handcrafted levels divided into 5 themed packs of 10 levels each. Each level has unique objectives, constraints, and a 3-star rating system to encourage replayability and mastery.

---

## Level Pack Structure

### Initial Release: 50 Levels in 5 Packs

1. **Tutorial Pack (Levels 1-10)**
   - Purpose: Teach basic mechanics, piece types, strategies
   - Difficulty: Easy (green)
   - Objectives: Simple score targets, basic line clears
   - Introduce: Grid mechanics, piece placement, line clearing, combos

2. **Pattern Pack (Levels 11-20)**
   - Purpose: Create specific shapes, clear designated areas
   - Difficulty: Easy-Medium (yellow)
   - Objectives: Form patterns (2x2 squares, fill corners, clear center)
   - Introduce: Strategic thinking, pattern recognition

3. **Survival Pack (Levels 21-30)**
   - Purpose: Limited moves or pieces
   - Difficulty: Medium (orange)
   - Objectives: Clear X lines with Y moves, survive with specific pieces only
   - Introduce: Resource management, efficiency

4. **Puzzle Pack (Levels 31-40)**
   - Purpose: Pre-filled grids requiring specific solutions
   - Difficulty: Medium-Hard (orange-red)
   - Objectives: Clear pre-placed blocks, solve board states
   - Introduce: Puzzle-solving, reverse engineering

5. **Master Pack (Levels 41-50)**
   - Purpose: Combination challenges with multiple objectives
   - Difficulty: Hard-Expert (red)
   - Objectives: Multi-requirement challenges
   - Introduce: Mastery of all mechanics

---

## Level Design Specifications

### Level Data Structure

```swift
struct Level: Identifiable, Codable {
    let id: Int
    let packID: Int // 1-5
    let title: String
    let description: String

    // Objective
    let objectiveType: LevelObjective
    let targetValue: Int // Score target, line count, move limit, etc.

    // Constraints
    let moveLimit: Int? // nil = unlimited
    let timeLimit: Int? // seconds, nil = untimed
    let allowedPieces: [PieceType]? // nil = all pieces

    // Pre-filled Grid
    let prefillPattern: [[GridCell]]? // nil = empty grid

    // Star Requirements
    let oneStarRequirement: StarRequirement
    let twoStarRequirement: StarRequirement
    let threeStarRequirement: StarRequirement

    // Rewards
    let xpReward: Int
    let coinReward: Int
    let unlockReward: UnlockType? // Theme, power-up, etc.

    // Metadata
    let difficulty: DifficultyLevel
    let unlockRequirement: UnlockRequirement
}
```

### Objective Types

```swift
enum LevelObjective {
    case reachScore(target: Int)
    case clearLines(count: Int)
    case createPattern(pattern: PatternType)
    case surviveTime(seconds: Int)
    case clearAllBlocks
    case clearSpecificColor(color: BlockColor)
    case achieveCombo(multiplier: Int)
    case perfectClear
    case useOnlyPieces([PieceType])
    case clearWithMoves(moves: Int)
}
```

### Star Requirements

```swift
struct StarRequirement {
    let type: RequirementType
    let value: Int

    enum RequirementType {
        case score
        case movesRemaining
        case timeRemaining
        case noHoldsUsed
        case noUndosUsed
        case perfectClears
        case comboAchieved
        case specificObjective
    }
}
```

**Example Star Requirements:**
- ⭐ (1 star): Complete basic objective (e.g., reach 1000 points)
- ⭐⭐ (2 stars): Complete with bonus (e.g., reach 1000 points in under 50 moves)
- ⭐⭐⭐ (3 stars): Perfect completion (e.g., reach 1500 points + 1 perfect clear + no holds used)

---

## Level Examples

### Level 1: First Steps (Tutorial Pack)
```swift
Level(
    id: 1,
    packID: 1,
    title: "First Steps",
    description: "Place 5 pieces anywhere on the grid",
    objectiveType: .clearLines(count: 2),
    targetValue: 2,
    moveLimit: 10,
    timeLimit: nil,
    allowedPieces: nil, // All pieces available
    prefillPattern: nil, // Empty grid
    oneStarRequirement: StarRequirement(type: .clearLines, value: 2),
    twoStarRequirement: StarRequirement(type: .score, value: 500),
    threeStarRequirement: StarRequirement(type: .movesRemaining, value: 5),
    xpReward: 200,
    coinReward: 50,
    unlockReward: nil,
    difficulty: .easy,
    unlockRequirement: .always
)
```

### Level 15: Corner Master (Pattern Pack)
```swift
Level(
    id: 15,
    packID: 2,
    title: "Corner Master",
    description: "Fill all four corners of the grid",
    objectiveType: .createPattern(pattern: .fillCorners),
    targetValue: 4,
    moveLimit: 20,
    timeLimit: nil,
    allowedPieces: nil,
    prefillPattern: nil,
    oneStarRequirement: StarRequirement(type: .specificObjective, value: 4),
    twoStarRequirement: StarRequirement(type: .movesRemaining, value: 8),
    threeStarRequirement: StarRequirement(type: .perfectClears, value: 1),
    xpReward: 400,
    coinReward: 100,
    unlockReward: nil,
    difficulty: .medium,
    unlockRequirement: .levelCompleted(14)
)
```

### Level 25: Limited Resources (Survival Pack)
```swift
Level(
    id: 25,
    packID: 3,
    title: "Limited Resources",
    description: "Clear 8 lines using only L-shaped pieces",
    objectiveType: .clearLines(count: 8),
    targetValue: 8,
    moveLimit: 30,
    timeLimit: nil,
    allowedPieces: [.lShape, .reverseLShape],
    prefillPattern: nil,
    oneStarRequirement: StarRequirement(type: .clearLines, value: 8),
    twoStarRequirement: StarRequirement(type: .score, value: 2000),
    threeStarRequirement: StarRequirement(type: .comboAchieved, value: 5),
    xpReward: 600,
    coinReward: 150,
    unlockReward: .powerUp(.undo, count: 3),
    difficulty: .hard,
    unlockRequirement: .levelCompleted(24)
)
```

### Level 40: Puzzle Master (Puzzle Pack)
```swift
// Pre-filled grid pattern with strategic blocks requiring specific clearing order
let prefillPattern: [[GridCell]] = [
    // 8x8 grid with pre-placed blocks forming a puzzle
    // Player must clear specific blocks to achieve objective
]

Level(
    id: 40,
    packID: 4,
    title: "Puzzle Master",
    description: "Clear the pre-filled board completely",
    objectiveType: .clearAllBlocks,
    targetValue: 0, // Not applicable
    moveLimit: 15,
    timeLimit: nil,
    allowedPieces: nil, // Specific pieces provided
    prefillPattern: prefillPattern,
    oneStarRequirement: StarRequirement(type: .specificObjective, value: 1),
    twoStarRequirement: StarRequirement(type: .movesRemaining, value: 5),
    threeStarRequirement: StarRequirement(type: .perfectClears, value: 2),
    xpReward: 600,
    coinReward: 200,
    unlockReward: .theme(.crystalIce),
    difficulty: .expert,
    unlockRequirement: .levelCompleted(39)
)
```

---

## 3-Star Rating System

### Rating Logic

```swift
class LevelRatingSystem {
    func calculateStars(for level: Level, performance: LevelPerformance) -> Int {
        var stars = 0

        // 1 Star: Basic objective completed
        if performance.objectiveCompleted {
            stars = 1
        }

        // 2 Stars: Meet bonus requirement
        if meetsRequirement(level.twoStarRequirement, performance: performance) {
            stars = 2
        }

        // 3 Stars: Meet perfect requirement
        if meetsRequirement(level.threeStarRequirement, performance: performance) {
            stars = 3
        }

        return stars
    }

    private func meetsRequirement(_ requirement: StarRequirement,
                                   performance: LevelPerformance) -> Bool {
        switch requirement.type {
        case .score:
            return performance.finalScore >= requirement.value
        case .movesRemaining:
            return performance.movesRemaining >= requirement.value
        case .timeRemaining:
            return performance.timeRemaining >= requirement.value
        case .noHoldsUsed:
            return performance.holdsUsed == 0
        case .noUndosUsed:
            return performance.undosUsed == 0
        case .perfectClears:
            return performance.perfectClears >= requirement.value
        case .comboAchieved:
            return performance.maxCombo >= requirement.value
        case .specificObjective:
            return performance.objectiveCompleted
        }
    }
}
```

### Star Display

**Visual Representation:**
- Empty stars (outlined) for unearned stars
- Filled stars (solid) for earned stars
- Animation: Stars reveal one by one with 0.3s delay between each
- Sound: Pleasant chime for each star earned

**Star Tracking:**
- Stars are cumulative across all levels
- Total stars displayed in level pack header
- Star milestones unlock rewards:
  * 30 stars: Unlock Wooden Classic theme
  * 60 stars: Unlock power-up bundle (5 each)
  * 90 stars: Unlock Crystal Ice theme
  * 120 stars: Unlock exclusive "Level Master" badge
  * 150 stars (all 3-star): Unlock "Perfectionist" achievement + 1000 coins

---

## Level Select Screen

### UI Layout

```
┌─────────────────────────────────────┐
│   Level Pack 1: Tutorial            │
│   ★★★★★☆☆☆☆☆ (5/30 stars)         │
│   Progress: ████░░░░░░ 50%          │
├─────────────────────────────────────┤
│                                     │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│  │ 1 │ │ 2 │ │ 3 │ │ 4 │ │ 5 │   │
│  │⭐⭐⭐│ │⭐⭐☆│ │⭐☆☆│ │☆☆☆│ │🔒│   │
│  └───┘ └───┘ └───┘ └───┘ └───┘   │
│                                     │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐ ┌───┐   │
│  │ 6 │ │ 7 │ │ 8 │ │ 9 │ │10 │   │
│  │🔒│ │🔒│ │🔒│ │🔒│ │🔒│   │
│  └───┘ └───┘ └───┘ └───┘ └───┘   │
│                                     │
└─────────────────────────────────────┘
```

### Features

**Level Indicators:**
- Level number prominently displayed
- Stars earned shown directly on level button
- Lock icon for unavailable levels
- Glow animation on current unlocked level
- Completed levels have checkmark badge

**Navigation:**
- Scroll vertically through level packs
- Tap level to view details or start
- Swipe between packs horizontally
- Quick navigation to first uncompleted level

**Level Details Preview:**
```
┌─────────────────────────────────────┐
│  Level 15: Corner Master            │
│                                     │
│  Objective: Fill all four corners   │
│  Move Limit: 20 moves               │
│  Difficulty: ⚠️ Medium              │
│                                     │
│  Star Requirements:                 │
│  ⭐ Complete objective              │
│  ⭐⭐ 8+ moves remaining             │
│  ⭐⭐⭐ 1 perfect clear              │
│                                     │
│  Rewards:                           │
│  • 400 XP                           │
│  • 100 Coins                        │
│                                     │
│  Best: ⭐⭐☆ (1500 points)           │
│                                     │
│  [    PLAY    ] [  SKIP (500¢)  ]  │
└─────────────────────────────────────┘
```

**Pack Progression:**
- Shows total stars earned in pack
- Percentage completion
- Unlock next pack when previous is 70% complete (7 levels)
- Premium users or coin purchase can unlock packs early

---

## Level Completion Screen

### Completion Flow

1. **Level Complete Detection**
   - Objective achieved
   - Pause gameplay
   - Calculate performance metrics
   - Determine star rating

2. **Results Screen (2-3 second sequence)**

```
┌─────────────────────────────────────┐
│        LEVEL COMPLETE!              │
│                                     │
│      ⭐  ⭐  ⭐                      │
│   (Animated reveal: 0.3s delay)     │
│                                     │
│  Final Score: 1,850                 │
│  ─────────────────────                │
│  Par Score:   1,000   ✅            │
│  Moves Used:  12 / 20  ✅           │
│  Perfect Clears: 1     ✅           │
│                                     │
│  Rewards Earned:                    │
│  • +400 XP                          │
│  • +100 Coins                       │
│                                     │
│  [ REPLAY ]  [ NEXT ]  [ MAP ]     │
└─────────────────────────────────────┘
```

### Star Animation Sequence

**Each Star Reveal:**
1. Star icon scales from 0.5x to 1.2x (bounce in)
2. Bright flash of light
3. Pleasant chime sound
4. Particle burst in star color (gold)
5. Star settles at 1.0x scale
6. 0.3s delay before next star

**If 3 Stars Achieved:**
- Special "Perfect!" banner appears
- Confetti particle effect
- Triumphant sound effect
- Bonus: +50 coins for perfect completion

### Level Failed Screen

**Trigger:** Ran out of moves or time without completing objective

```
┌─────────────────────────────────────┐
│        LEVEL FAILED                 │
│                                     │
│   Score: 750 / 1000 needed          │
│   So close! Try again?              │
│                                     │
│   Failed Attempts: 2 / 3            │
│   (3 fails = Skip option appears)   │
│                                     │
│  [ RETRY ]  [ HINT (100¢) ]  [ X ] │
└─────────────────────────────────────┘
```

**Skip Option (After 3 Failed Attempts):**
- Watch 30s ad to skip level, OR
- Spend 500 coins to skip
- Skipped levels grant 0 stars but unlock next level
- Can return later to earn stars

---

## Move Limit System

### Move Counter UI

**Position:** Top-right corner during level
**Display:** `Moves: 15 / 20`

**Visual States:**
- Normal (>5 moves): White text
- Warning (5 moves): Orange text, gentle pulse
- Critical (≤3 moves): Red text, faster pulse
- Out of moves: Game over

### Move Validation

```swift
class MoveLimitManager {
    private(set) var movesRemaining: Int
    private let initialMoves: Int

    func recordMove() -> Bool {
        guard movesRemaining > 0 else {
            return false // No moves left
        }

        movesRemaining -= 1

        if movesRemaining <= 3 {
            triggerCriticalWarning()
        }

        return true
    }

    func undoMove() {
        movesRemaining += 1
    }

    private func triggerCriticalWarning() {
        // Haptic feedback
        // Visual warning animation
        // Sound alert
    }
}
```

---

## Prefill Pattern System

### Grid State Initialization

```swift
struct PrefillPattern: Codable {
    let grid: [[GridCell]]
    let description: String

    static func load(for levelID: Int) -> PrefillPattern? {
        // Load from JSON or generated algorithmically
    }
}

struct GridCell: Codable {
    let row: Int
    let col: Int
    let blockColor: BlockColor?
    let isLocked: Bool // Cannot be cleared by normal means

    var isEmpty: Bool {
        return blockColor == nil
    }
}
```

### Example Patterns

**Checkerboard (Medium):**
```
┌─────────────────┐
│ ■ □ ■ □ ■ □ ■ □ │
│ □ ■ □ ■ □ ■ □ ■ │
│ ■ □ ■ □ ■ □ ■ □ │
│ □ ■ □ ■ □ ■ □ ■ │
│ ■ □ ■ □ ■ □ ■ □ │
│ □ ■ □ ■ □ ■ □ ■ │
│ ■ □ ■ □ ■ □ ■ □ │
│ □ ■ □ ■ □ ■ □ ■ │
└─────────────────┘
Objective: Clear all filled cells
```

**Border Wall (Hard):**
```
┌─────────────────┐
│ ■ ■ ■ ■ ■ ■ ■ ■ │
│ ■ □ □ □ □ □ □ ■ │
│ ■ □ □ □ □ □ □ ■ │
│ ■ □ □ ■ ■ □ □ ■ │
│ ■ □ □ ■ ■ □ □ ■ │
│ ■ □ □ □ □ □ □ ■ │
│ ■ □ □ □ □ □ □ ■ │
│ ■ ■ ■ ■ ■ ■ ■ ■ │
└─────────────────┘
Objective: Fill interior completely without clearing border
```

---

## Piece Restrictions

### Allowed Pieces System

```swift
enum PieceType: String, CaseIterable, Codable {
    case single
    case line2
    case line3
    case line4
    case line5
    case square2x2
    case square3x3
    case lShape
    case reverseLShape
    case tShape
    case corner
}

class PieceGenerator {
    private let allowedPieces: [PieceType]?

    func generateNextPiece() -> Piece {
        if let allowed = allowedPieces {
            // Generate only from allowed types
            return Piece(type: allowed.randomElement()!)
        } else {
            // Generate any piece
            return Piece(type: PieceType.allCases.randomElement()!)
        }
    }
}
```

**Example Restrictions:**
- Level 22: Only single blocks and 2-length lines (teaches precision)
- Level 28: Only L-shapes and T-shapes (teaches pattern forming)
- Level 35: Only large pieces (3x3, 4-length, 5-length) (teaches big picture)

---

## Level Progression & Unlock System

### Unlock Requirements

```swift
enum UnlockRequirement {
    case always // Level 1
    case levelCompleted(Int) // Complete level X
    case starsEarned(Int) // Earn X total stars
    case playerLevel(Int) // Reach player level X
    case packCompleted(Int) // Complete pack X
    case premium // Premium subscription required
    case coinPurchase(Int) // Buy for X coins
}
```

### Level Unlocking Logic

```swift
class LevelUnlockManager {
    func isLevelUnlocked(_ level: Level,
                         userData: UserData) -> Bool {
        switch level.unlockRequirement {
        case .always:
            return true
        case .levelCompleted(let levelID):
            return userData.isLevelCompleted(levelID)
        case .starsEarned(let count):
            return userData.totalStars >= count
        case .playerLevel(let level):
            return userData.playerLevel >= level
        case .packCompleted(let packID):
            return userData.isPackCompleted(packID)
        case .premium:
            return userData.isPremium
        case .coinPurchase:
            return userData.hasPurchasedLevel(level.id)
        }
    }
}
```

### Pack Unlocking

**Progressive Unlocking:**
- Pack 1 (Levels 1-10): Always unlocked
- Pack 2 (Levels 11-20): Complete 7 levels in Pack 1 OR Player Level 25 OR 300 coins
- Pack 3 (Levels 21-30): Complete 7 levels in Pack 2 OR Player Level 45 OR 500 coins
- Pack 4 (Levels 31-40): Complete 7 levels in Pack 3 OR Player Level 60 OR 700 coins
- Pack 5 (Levels 41-50): Complete 7 levels in Pack 4 OR Player Level 80 OR 1000 coins

**Premium Fast Track:**
- Premium subscribers unlock all packs immediately
- Can still earn stars for progression and rewards

---

## Hint System

### Hint Button

**Availability:**
- Appears on level start
- Shows optimal next move
- Costs 100 coins per use
- Alternative: Watch 30s ad for free hint

### Hint Display

**Visual:**
- Highlights suggested piece
- Shows ghost preview of optimal placement
- Displays expected result (lines cleared, points gained)
- Auto-fades after 5 seconds

```swift
class HintSystem {
    func calculateOptimalMove(gridState: GridState,
                             availablePieces: [Piece]) -> Hint? {
        // AI algorithm to determine best move
        // Considers: line clears, score, future moves

        return Hint(
            piece: bestPiece,
            position: optimalPosition,
            expectedScore: projectedScore,
            linesCleared: projectedLines
        )
    }
}
```

---

## Rewards System

### XP Rewards

**Base XP by Pack:**
- Pack 1: 200 XP per level
- Pack 2: 400 XP per level
- Pack 3: 600 XP per level
- Pack 4: 800 XP per level
- Pack 5: 1000 XP per level

**Star Bonuses:**
- 2 stars: +50% XP
- 3 stars: +100% XP

**First-Time Completion:**
- Additional 100 XP for first completion

### Coin Rewards

**Base Coins by Pack:**
- Pack 1: 50 coins per level
- Pack 2: 100 coins per level
- Pack 3: 150 coins per level
- Pack 4: 200 coins per level
- Pack 5: 250 coins per level

**Star Bonuses:**
- 2 stars: +50 coins
- 3 stars: +100 coins

### Special Rewards

**Level-Specific Unlocks:**
- Level 10: Hold Slot tutorial
- Level 20: Power-Up tutorial + 3 free Undos
- Level 30: Rotation Power-Up unlocked
- Level 40: Bomb Power-Up unlocked
- Level 50: Exclusive "Level Master" theme variant

**Pack Completion Rewards:**
- Pack 1: 500 bonus coins + "Tutorial Graduate" badge
- Pack 2: 750 bonus coins + Wooden Classic theme
- Pack 3: 1000 bonus coins + Power-up bundle (10 each)
- Pack 4: 1500 bonus coins + Crystal Ice theme
- Pack 5: 2000 bonus coins + "Master" title + exclusive avatar border

---

## Implementation Checklist

- [ ] Create Level data model with all properties
- [ ] Implement LevelObjective enum with all types
- [ ] Build StarRequirement system
- [ ] Design and implement 50 unique levels (JSON storage)
- [ ] Create prefill pattern generator/loader
- [ ] Implement LevelRatingSystem
- [ ] Build Level Select Screen UI
- [ ] Create Level Details preview screen
- [ ] Implement Level Completion screen with star animation
- [ ] Build Level Failed screen with retry/skip options
- [ ] Create Move Limit system and counter UI
- [ ] Implement Piece Restriction system
- [ ] Build Level Unlock manager
- [ ] Create Pack progression system
- [ ] Implement Hint System with AI move calculation
- [ ] Build Rewards distribution system
- [ ] Create level progress persistence
- [ ] Implement star milestone tracking
- [ ] Add level navigation and flow
- [ ] Test all 50 levels for balance and fun
- [ ] Performance test with complex prefill patterns

---

## Success Criteria

✅ All 50 levels implemented with unique objectives
✅ 5 level packs with thematic coherence
✅ 3-star rating system functional and fair
✅ Level Select screen intuitive and informative
✅ Level Completion screen celebrates achievements
✅ Move limit system enforced correctly
✅ Prefill patterns load and display correctly
✅ Piece restrictions work as designed
✅ Unlock progression feels rewarding
✅ Hint system provides useful guidance
✅ Rewards distributed correctly
✅ Star milestones unlock bonuses
✅ All levels are balanced and beatable
✅ Levels are fun and varied
✅ Performance maintains 60fps with complex patterns
✅ Level progress persists across sessions
