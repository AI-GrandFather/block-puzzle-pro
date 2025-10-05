# Feature: Puzzle Mode (Daily Challenges)

**Priority:** HIGH
**Timeline:** Week 5-6
**Dependencies:** Core game engine, level system, leaderboard integration
**Performance Target:** 60fps minimum, quick puzzle loading (<0.3s)

---

## Overview

Implement a Puzzle Mode featuring daily puzzles that challenge players with unique brain-teasing scenarios. Each puzzle has a specific objective and optimal solution, encouraging strategic thinking and providing fresh content every day.

---

## Daily Puzzle System

### Puzzle Generation

**Timing:**
- New puzzle generated every day at midnight local time
- Same puzzle globally for all players (synchronized via server)
- Puzzle remains available for 24 hours
- Previous puzzles archived and accessible for 7 days

**Puzzle Identifier:**
```swift
struct PuzzleID {
    let date: Date
    let seed: Int // Derived from date for consistency

    var string: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}
```

**Difficulty Rating:**
```swift
enum PuzzleDifficulty: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }

    var targetSolveTime: Int {
        switch self {
        case .easy: return 60 // 1 minute
        case .medium: return 180 // 3 minutes
        case .hard: return 300 // 5 minutes
        case .expert: return 600 // 10 minutes
        }
    }
}
```

### Puzzle Structure

```swift
struct Puzzle: Identifiable, Codable {
    let id: PuzzleID
    let category: PuzzleCategory
    let difficulty: PuzzleDifficulty
    let title: String
    let description: String

    // Grid Setup
    let gridSize: Int // Usually 8x8
    let prefillPattern: [[GridCell]]?
    let lockedCells: [GridPosition]? // Cells that cannot be cleared

    // Objective
    let objective: PuzzleObjective
    let targetValue: Int

    // Constraints
    let availablePieces: [Piece]? // Specific pieces provided
    let moveLimit: Int?
    let timeLimit: Int // 5 minutes for daily, 10 for weekly

    // Solution
    let optimalSolution: PuzzleSolution?
    let parMoves: Int // Optimal number of moves
    let parTime: Int // Expected solve time in seconds

    // Rewards
    let xpReward: Int
    let coinReward: Int
    let streakBonus: Int // Bonus for consecutive days solved
}
```

---

## Puzzle Categories

### 1. Clear In One Move

**Concept:** Board has pieces placed; player gets one specific piece that clears everything perfectly.

**Example:**
```
Prefill:
┌─────────────────┐
│ ■ ■ ■ □ □ ■ ■ ■ │
│ ■ ■ ■ □ □ ■ ■ ■ │
│ ■ ■ ■ □ □ ■ ■ ■ │
│ □ □ □ □ □ □ □ □ │
│ □ □ □ □ □ □ □ □ │
│ ■ ■ ■ □ □ ■ ■ ■ │
│ ■ ■ ■ □ □ ■ ■ ■ │
│ ■ ■ ■ □ □ ■ ■ ■ │
└─────────────────┘

Provided Piece: Vertical 3-line
Solution: Place in column 3-5 to complete rows
```

**Objective:** Place the single provided piece to clear all rows/columns
**Difficulty:** Easy-Medium
**Moves:** 1
**Reward:** 200 XP, 100 coins

### 2. Perfect Fit

**Concept:** Given a set of specific pieces that must ALL be used to fill the board exactly.

**Example:**
```
Empty 8x8 grid
Provided Pieces:
- Four 2x2 squares
- Eight 2-length lines
- Four L-shapes
- Four T-shapes

Objective: Use ALL pieces to completely fill the grid
```

**Objective:** Place all provided pieces with no gaps
**Difficulty:** Medium-Hard
**Moves:** Count of pieces (unlimited attempts to arrange)
**Reward:** 300 XP, 150 coins

### 3. Chain Reaction

**Concept:** Placement creates cascading line clears (domino effect).

**Example:**
```
Prefill with strategic gaps:
┌─────────────────┐
│ ■ ■ ■ ■ ■ ■ ■ □ │ Row 0: 1 gap
│ ■ ■ ■ ■ ■ ■ □ ■ │ Row 1: 1 gap (offset)
│ ■ ■ ■ ■ ■ □ ■ ■ │ Row 2: 1 gap (offset)
│ ■ ■ ■ ■ □ ■ ■ ■ │ Row 3: 1 gap (offset)
│ ■ ■ ■ □ ■ ■ ■ ■ │ Row 4: 1 gap (offset)
│ ■ ■ □ ■ ■ ■ ■ ■ │ Row 5: 1 gap (offset)
│ ■ □ ■ ■ ■ ■ ■ ■ │ Row 6: 1 gap (offset)
│ □ ■ ■ ■ ■ ■ ■ ■ │ Row 7: 1 gap (offset)
└─────────────────┘

Provided Piece: Diagonal 8-piece line
Solution: Place diagonally to fill all gaps → clears all rows sequentially
```

**Objective:** Trigger cascading clears with minimum moves
**Difficulty:** Medium
**Moves:** 1-3
**Reward:** 250 XP, 125 coins

### 4. Restricted Pieces

**Concept:** Only certain piece types are available for solving.

**Example:**
```
Empty grid or partially filled
Only L-shapes and reverse L-shapes allowed

Objective: Clear 10 lines using only L-shaped pieces
```

**Objective:** Complete objective with limited piece variety
**Difficulty:** Medium-Hard
**Moves:** 15-20
**Reward:** 300 XP, 150 coins

### 5. Color Match

**Concept:** Clear all blocks of a specific color; other colors are obstacles.

**Example:**
```
Prefill with mixed colors:
┌─────────────────┐
│ R B R B R B R B │
│ B R B R B R B R │
│ R B R B R B R B │
│ B R B R B R B R │
│ R B R B R B R B │
│ B R B R B R B R │
│ R B R B R B R B │
│ B R B R B R B R │
└─────────────────┘

Objective: Clear all RED blocks without clearing BLUE
```

**Objective:** Clear target color completely
**Difficulty:** Hard
**Moves:** 10-15
**Reward:** 400 XP, 200 coins

### 6. Pattern Recreation

**Concept:** Match a target pattern shown in preview.

**Example:**
```
Target Pattern:
┌─────────────────┐
│ □ □ □ □ □ □ □ □ │
│ □ ■ ■ ■ ■ ■ ■ □ │
│ □ ■ □ □ □ □ ■ □ │
│ □ ■ □ ■ ■ □ ■ □ │
│ □ ■ □ ■ ■ □ ■ □ │
│ □ ■ □ □ □ □ ■ □ │
│ □ ■ ■ ■ ■ ■ ■ □ │
│ □ □ □ □ □ □ □ □ │
└─────────────────┘

Objective: Recreate this exact pattern
```

**Objective:** Match target pattern exactly
**Difficulty:** Medium-Hard
**Moves:** 8-12
**Reward:** 350 XP, 175 coins

### 7. Minimum Moves

**Concept:** Clear the board in X moves or fewer.

**Example:**
```
Partially filled grid with strategic placement
Par Moves: 5

Objective: Achieve perfect clear in ≤5 moves
```

**Objective:** Efficiency challenge
**Difficulty:** Hard-Expert
**Moves:** Limited
**Reward:** 450 XP, 225 coins

### 8. Block Breaker

**Concept:** Break through "wall" blocks to clear special blocks behind them.

**Example:**
```
Prefill:
┌─────────────────┐
│ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐ │ Special blocks
│ 🧱 🧱 🧱 🧱 🧱 🧱 🧱 🧱 │ Wall (requires 2 clears)
│ 🧱 🧱 🧱 🧱 🧱 🧱 🧱 🧱 │
│ □ □ □ □ □ □ □ □ │
│ □ □ □ □ □ □ □ □ │
│ □ □ □ □ □ □ □ □ │
│ □ □ □ □ □ □ □ □ │
│ □ □ □ □ □ □ □ □ │
└─────────────────┘

Objective: Break through wall to clear all ⭐ blocks
```

**Objective:** Strategic clearing with obstacles
**Difficulty:** Hard-Expert
**Moves:** 10-15
**Reward:** 500 XP, 250 coins

---

## Puzzle Interface

### Puzzle Start Screen

```
┌─────────────────────────────────────┐
│   📅 Daily Puzzle                   │
│   December 25, 2025                 │
│                                     │
│   Category: Chain Reaction          │
│   Difficulty: ⚠️ Hard               │
│   Time Limit: 5:00                  │
│                                     │
│   Objective:                        │
│   Create cascading clears to        │
│   clear the entire board            │
│                                     │
│   Best: Unsolved                    │
│   Global Average: 2:34              │
│   Your Streak: 🔥 7 days            │
│                                     │
│  [      START PUZZLE      ]         │
│  [    PREVIEW SOLUTION    ]         │
│     (Costs 100 coins)               │
└─────────────────────────────────────┘
```

### In-Puzzle UI

```
┌─────────────────────────────────────┐
│  ⏱️ 03:45  |  Moves: 2 / 5          │
│  [?HINT]  [↩RESET]  [📊LEADERBOARD] │
├─────────────────────────────────────┤
│                                     │
│        [8x8 GRID DISPLAY]           │
│                                     │
│  Objective: Clear all rows          │
│  Progress: ░░░░░░░░ 0/8             │
│                                     │
├─────────────────────────────────────┤
│                                     │
│     Available Pieces:               │
│     [Piece1] [Piece2] [Piece3]      │
│                                     │
└─────────────────────────────────────┘
```

### Buttons

**Hint Button (💡):**
- Costs 100 coins OR watch 30s ad
- Shows one optimal move
- Highlights piece and placement position
- Displays expected outcome
- Can be used multiple times (each costs coins/ad)

**Reset Button (↩):**
- Returns grid to starting state
- Resets timer
- Resets move counter
- Confirms before resetting ("Are you sure?")
- No penalty for reset

**Leaderboard Button (📊):**
- Opens daily puzzle leaderboard
- Shows fastest solve times
- Highlights your position
- Displays friend rankings

---

## Puzzle Completion

### Success Screen

```
┌─────────────────────────────────────┐
│        PUZZLE SOLVED! 🎉            │
│                                     │
│  Your Time: 02:15 ⚡ NEW BEST!      │
│  Moves Used: 3                      │
│  Par Time: 03:00                    │
│  Par Moves: 5                       │
│                                     │
│  Performance:                       │
│  ⭐⭐⭐ PERFECT!                      │
│                                     │
│  Rewards:                           │
│  • +250 XP                          │
│  • +150 Coins                       │
│  • Streak Bonus: +50 Coins (🔥8)    │
│                                     │
│  Leaderboard: #47 / 12,543          │
│                                     │
│  [ VIEW SOLUTION ]  [ SHARE ]  [ X ]│
└─────────────────────────────────────┘
```

**Star Rating:**
- ⭐ (1 star): Solved
- ⭐⭐ (2 stars): Solved in ≤par moves OR ≤par time
- ⭐⭐⭐ (3 stars): Solved in ≤par moves AND ≤par time

**First-Try Bonus:**
- Additional +100 XP if solved on first attempt (no resets)
- Badge: "First Try!" appears

### Failure Conditions

**Time Ran Out:**
```
┌─────────────────────────────────────┐
│        TIME'S UP!                   │
│                                     │
│  You ran out of time!               │
│  Progress: 6 / 8 rows cleared       │
│                                     │
│  [ RETRY ]  [ HINT ]  [ GIVE UP ]   │
└─────────────────────────────────────┘
```

**Moves Exhausted (if move limit exists):**
```
┌─────────────────────────────────────┐
│      NO MOVES LEFT!                 │
│                                     │
│  You've used all available moves.   │
│  Objective not completed.           │
│                                     │
│  [ RETRY ]  [ HINT ]  [ GIVE UP ]   │
└─────────────────────────────────────┘
```

---

## Weekly Challenge

### Structure

**Timing:**
- Releases every Monday at 00:00 UTC
- Available for full 7 days
- More difficult than daily puzzles
- Global leaderboard competition

**Characteristics:**
```swift
struct WeeklyChallenge: Puzzle {
    let weekNumber: Int // Week of year
    let difficulty: PuzzleDifficulty = .expert
    let timeLimit: Int = 600 // 10 minutes
    let category: PuzzleCategory = .combination // Multiple objectives

    // Enhanced rewards
    let baseXP: Int = 500
    let baseCoin: Int = 300
    let topRewards: [LeaderboardReward]
}
```

**Leaderboard Tiers:**
```swift
enum LeaderboardReward {
    case top10(coins: 1000, badge: "Weekly Champion")
    case top100(coins: 500, badge: "Weekly Elite")
    case top1000(coins: 250, badge: "Weekly Achiever")
    case participant(coins: 50)
}
```

### Weekly Challenge UI

```
┌─────────────────────────────────────┐
│   🏆 Weekly Challenge                │
│   Week 51 - December 18-24          │
│                                     │
│   "The Grand Puzzle"                │
│   Difficulty: 🔥 EXPERT             │
│                                     │
│   Objectives:                       │
│   • Clear 20 lines                  │
│   • Achieve 3x 5-combo              │
│   • Perfect clear finale            │
│                                     │
│   Your Best: 07:42 (#247)           │
│   Leader: ProPuzzler (03:15)        │
│                                     │
│   Rewards:                          │
│   Top 10: 1000 coins + Champion     │
│   Top 100: 500 coins + Elite badge  │
│   Top 1000: 250 coins + badge       │
│   All: 50 coins for trying          │
│                                     │
│   Time Remaining: 2d 14h 32m        │
│                                     │
│  [    START CHALLENGE    ]          │
│  [  VIEW LEADERBOARD  ]             │
└─────────────────────────────────────┘
```

---

## Leaderboard System

### Daily Puzzle Leaderboard

**Sorting:** Fastest solve time (ascending)
**Tie-breaker:** Fewest moves used
**Display:**

```
┌─────────────────────────────────────┐
│   📊 Today's Puzzle                 │
│   December 25, 2025                 │
│                                     │
│  Rank  Player         Time   Moves  │
│  ─────────────────────────────────  │
│   🥇1  SpeedMaster   01:15    3     │
│   🥈2  QuickSolve    01:18    3     │
│   🥉3  PuzzlePro     01:22    4     │
│   4    FastFingers   01:25    3     │
│   5    GridGenius    01:28    4     │
│   ...                               │
│   47   YOU ⬅         02:15    3     │
│   ...                               │
│   12,543 players solved today       │
│                                     │
│  [ FRIENDS ]  [ GLOBAL ]  [ X ]     │
└─────────────────────────────────────┘
```

**Friend Filter:**
- Shows only Game Center friends
- Highlights your position among friends
- Encourages friendly competition

### Weekly Challenge Leaderboard

**Similar structure with tier highlights:**
```
┌─────────────────────────────────────┐
│   🏆 Week 51 Leaderboard            │
│                                     │
│  Top 10 (Champion Tier) 👑          │
│   1  ProPuzzler     03:15  ⭐⭐⭐   │
│   2  MasterMind     03:18  ⭐⭐⭐   │
│   ...                               │
│                                     │
│  Top 100 (Elite Tier) ⚡            │
│   11  QuickThink    04:02  ⭐⭐     │
│   ...                               │
│   47  YOU ⬅         07:42  ⭐⭐     │
│   ...                               │
│                                     │
│  Your Potential Reward: 500 coins   │
│  Time to improve: 2d 14h            │
└─────────────────────────────────────┘
```

---

## Solution Replay System

### Recording Solutions

```swift
struct PuzzleSolution: Codable {
    let moves: [Move]
    let finalTime: TimeInterval
    let finalScore: Int
    let playerID: String

    struct Move: Codable {
        let pieceType: PieceType
        let position: GridPosition
        let timestamp: TimeInterval // Relative to puzzle start
    }
}

class SolutionRecorder {
    private var moves: [PuzzleSolution.Move] = []
    private let startTime = Date()

    func recordMove(_ piece: Piece, at position: GridPosition) {
        let elapsed = Date().timeIntervalSince(startTime)
        let move = PuzzleSolution.Move(
            pieceType: piece.type,
            position: position,
            timestamp: elapsed
        )
        moves.append(move)
    }

    func finalizeSolution(score: Int, playerID: String) -> PuzzleSolution {
        return PuzzleSolution(
            moves: moves,
            finalTime: Date().timeIntervalSince(startTime),
            finalScore: score,
            playerID: playerID
        )
    }
}
```

### Replay Viewer

**Features:**
- Play back any solution move-by-move
- Speed controls: 0.5x, 1x, 2x, 4x
- Pause/resume
- Skip to specific move
- Compare your solution vs. optimal
- Compare vs. friend's solution

**UI:**
```
┌─────────────────────────────────────┐
│   Solution Replay                   │
│   Viewing: Optimal Solution         │
│                                     │
│        [8x8 GRID with pieces        │
│         animating into place]       │
│                                     │
│  Move 3 / 5                         │
│  ▶️  ◀️ ⏸️ ▶️▶️                      │
│  Speed: [0.5x] [1x] [2x] [4x]       │
│                                     │
│  Time: 02:15 → 03:00                │
│  Score: 1250 → 1850                 │
│                                     │
│  [ COMPARE YOURS ]  [ CLOSE ]       │
└─────────────────────────────────────┘
```

---

## Streak System

### Daily Streak Tracking

```swift
class PuzzleStreakManager {
    private(set) var currentStreak: Int
    private(set) var longestStreak: Int
    private var lastSolvedDate: Date?

    func updateStreak(solvedToday: Bool) {
        guard solvedToday else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastSolved = lastSolvedDate {
            let daysSince = calendar.dateComponents([.day],
                                                    from: lastSolved,
                                                    to: today).day ?? 0

            if daysSince == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysSince > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysSince == 0 means already solved today (no change)
        } else {
            // First puzzle solved
            currentStreak = 1
        }

        lastSolvedDate = today
        longestStreak = max(longestStreak, currentStreak)
    }

    func streakBonus() -> Int {
        // Bonus coins based on streak length
        return min(currentStreak * 10, 200) // Max 200 coins
    }
}
```

**Streak Milestones:**
- 🔥 3 days: +30 coins bonus
- 🔥 7 days: +70 coins bonus + "Week Warrior" badge
- 🔥 14 days: +140 coins bonus
- 🔥 30 days: +300 coins bonus + "Month Master" badge + exclusive theme unlock
- 🔥 100 days: +1000 coins + "Century Solver" achievement

**Streak Display:**
```
Your Streak: 🔥 12 days
Next Milestone: 🎯 14 days (2 more!)
Streak Bonus: +120 coins
```

---

## Puzzle Archive

### Past Puzzles

**Accessibility:**
- Last 7 days available for replay
- No leaderboard competition for old puzzles
- Still earn XP and coins (50% of original)
- Stars don't count toward achievements
- Good for practice and strategy learning

**Archive UI:**
```
┌─────────────────────────────────────┐
│   📚 Puzzle Archive                 │
│                                     │
│  This Week:                         │
│                                     │
│  Mon Dec 25  Chain Reaction  ⭐⭐⭐  │
│  Tue Dec 24  Perfect Fit     ⭐⭐☆  │
│  Wed Dec 23  Minimum Moves   ⭐☆☆  │
│  Thu Dec 22  Color Match     ⭐⭐⭐  │
│  Fri Dec 21  Clear In One    ⭐⭐⭐  │
│  Sat Dec 20  Block Breaker   ⭐⭐☆  │
│  Sun Dec 19  Pattern Match   Unsolved│
│                                     │
│  [Tap any puzzle to replay]         │
│                                     │
│  Note: Archive puzzles earn 50% XP  │
└─────────────────────────────────────┘
```

---

## Hint System

### Hint Mechanics

```swift
class PuzzleHintSystem {
    func generateHint(puzzle: Puzzle,
                      currentState: GridState) -> Hint {
        // Analyze current grid state
        // Calculate optimal next move
        // Consider objective progress

        return Hint(
            suggestedPiece: bestPiece,
            suggestedPosition: optimalPosition,
            reasoning: "This move will clear 2 rows and set up a combo",
            expectedOutcome: HintOutcome(
                linesCleared: 2,
                scoreGain: 150,
                comboSetup: true
            )
        )
    }
}
```

**Hint Display:**
- Highlights suggested piece with glow
- Shows ghost preview at suggested position
- Text bubble explains reasoning
- Expected outcome displayed
- Fades after 8 seconds or on user action

**Hint Costs:**
- First hint: Free
- Second hint: 50 coins OR watch ad
- Third+ hints: 100 coins OR watch ad
- Premium users: Unlimited free hints

---

## Future: Community Puzzles

### User-Created Puzzle System (Post-Launch)

**Puzzle Editor:**
- Visual grid editor
- Place blocks, set objectives
- Test puzzle for solvability
- Submit for community review

**Moderation:**
- Automated solvability check
- Community voting (thumbs up/down)
- Report system for inappropriate content
- Featured puzzles curated by developers

**Creator Recognition:**
- Creator name displayed on puzzle
- Leaderboard for most-played puzzles
- Creator rewards: Bonus coins, exclusive badges
- "Puzzle Creator" achievement

**Discovery:**
- Browse by category, difficulty, popularity
- Search by creator name
- Weekly featured community puzzle
- "Hidden Gems" section for underrated puzzles

---

## Implementation Checklist

- [ ] Create Puzzle data model with all properties
- [ ] Implement PuzzleCategory enum with 8 types
- [ ] Build puzzle generation system (server-synced)
- [ ] Create daily puzzle delivery mechanism
- [ ] Implement puzzle prefill pattern loader
- [ ] Build Puzzle Start screen UI
- [ ] Create in-puzzle UI with timer and move counter
- [ ] Implement Hint system with AI move calculation
- [ ] Build Reset functionality
- [ ] Create Puzzle Completion screen with star rating
- [ ] Implement Leaderboard integration
- [ ] Build Weekly Challenge system
- [ ] Create leaderboard tier rewards
- [ ] Implement Solution Recorder
- [ ] Build Solution Replay viewer
- [ ] Create Streak tracking system
- [ ] Implement streak milestone rewards
- [ ] Build Puzzle Archive (7-day history)
- [ ] Create puzzle sharing functionality
- [ ] Test puzzle solvability validation
- [ ] Performance test with complex patterns
- [ ] Server sync for global daily puzzles

---

## Success Criteria

✅ Daily puzzles generate reliably at midnight
✅ All 8 puzzle categories implemented and tested
✅ Puzzle UI is intuitive and informative
✅ Timer and move counter work correctly
✅ Hint system provides useful suggestions
✅ Reset functionality works without issues
✅ Puzzle Completion screen celebrates success
✅ Leaderboards rank correctly and update in real-time
✅ Weekly Challenge is more challenging and rewarding
✅ Solution Replay works smoothly at all speeds
✅ Streak system tracks and rewards correctly
✅ Puzzle Archive accessible for past 7 days
✅ Puzzles are balanced and solvable
✅ No impossible puzzles slip through
✅ Performance maintains 60fps with complex puzzles
✅ Server synchronization works across time zones
