# Feature: Statistics Dashboard

**Priority:** MEDIUM
**Timeline:** Week 7-8
**Dependencies:** All game modes, progression system
**Performance Target:** Instant data loading, smooth chart animations

---

## Overview

Implement a comprehensive statistics dashboard that tracks player performance across all game modes, displays historical data, and provides insights for improvement.

---

## Global Statistics

```swift
struct GlobalStatistics: Codable {
    // Overview
    var totalGamesPlayed: Int = 0
    var totalPlayTime: TimeInterval = 0
    var totalPiecesPlaced: Int = 0
    var totalLinesCleared: Int = 0
    var totalPerfectClears: Int = 0

    // Records
    var highestCombo: Int = 0
    var totalXPEarned: Int = 0
    var currentLevel: Int = 1
    var totalCoinsEarned: Int = 0
    var totalCoinsSpent: Int = 0

    // Achievements
    var achievementsUnlocked: Int = 0
    var totalAchievements: Int = 120

    var achievementCompletionRate: Double {
        return Double(achievementsUnlocked) / Double(totalAchievements)
    }
}
```

### Statistics Screen

```
┌─────────────────────────────────┐
│   📊 Statistics                 │
│                                 │
│   Games Played: 487             │
│   Total Play Time: 24h 32m      │
│                                 │
│   Pieces Placed: 15,847         │
│   Lines Cleared: 3,203          │
│   Perfect Clears: 87            │
│   Highest Combo: 15x            │
│                                 │
│   Level: 47 (152,085 XP)        │
│   Coins: 3,450 (earned: 8,720)  │
│                                 │
│   Achievements: 85/120 (71%)    │
│   ████████████░░░░ 71%          │
│                                 │
│   [ VIEW BY MODE ]              │
└─────────────────────────────────┘
```

---

## Per-Mode Statistics

```swift
struct ModeStatistics: Codable {
    let mode: GameMode

    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalScore: Int = 0
    var bestScore: Int = 0
    var recentBest: Int = 0 // Last 30 days
    var averageScore: Double = 0.0
    var averageGameDuration: TimeInterval = 0

    // Piece usage
    var pieceUsage: [PieceType: Int] = [:]

    // Line clears
    var singleClears: Int = 0
    var doubleClears: Int = 0
    var tripleClears: Int = 0
    var quadClears: Int = 0

    var perfectClears: Int = 0
    var bestCombo: Int = 0
    var averageCombo: Double = 0.0

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
}
```

### Mode Detail View

```
┌─────────────────────────────────┐
│   📊 Endless Mode Stats         │
│                                 │
│   Games: 234  Win Rate: 45%     │
│   ████████░░░░░░░░░░ 45%        │
│                                 │
│   Best Score: 45,230 (All-Time) │
│   Recent Best: 38,450 (30 days) │
│   Average: 12,847               │
│                                 │
│   Avg Duration: 8m 32s          │
│                                 │
│   Line Clear Distribution:      │
│   Singles: 45% ████████░░       │
│   Doubles: 35% ███████░░░       │
│   Triples: 15% ███░░░░░░░       │
│   Quads:    5% █░░░░░░░░░       │
│                                 │
│   Perfect Clears: 43            │
│   Best Combo: 12x               │
│                                 │
│   [ VIEW CHARTS ]               │
└─────────────────────────────────┘
```

---

## Historical Data

### Score Trend Graph

```swift
struct ScoreTrend: Codable {
    var dataPoints: [ScoreDataPoint] = []

    struct ScoreDataPoint: Codable {
        let date: Date
        let score: Int
        let mode: GameMode
    }

    func last30Days() -> [ScoreDataPoint] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return dataPoints.filter { $0.date >= thirtyDaysAgo }
    }
}
```

**Line Chart Display:**
```
┌─────────────────────────────────┐
│   Score Trend (Last 30 Days)    │
│                                 │
│ 50k ┤              ╭─╮           │
│     │            ╭─╯ ╰╮          │
│ 40k ┤          ╭─╯    ╰╮         │
│     │        ╭─╯       ╰─╮       │
│ 30k ┤      ╭─╯           ╰╮      │
│     │    ╭─╯              ╰─╮    │
│ 20k ┤  ╭─╯                  ╰─╮  │
│     │╭─╯                      ╰─│
│ 10k ┼────────────────────────────│
│     Dec1    Dec10   Dec20  Dec30│
│                                 │
│   Trend: ↗ Improving (+12%)     │
└─────────────────────────────────┘
```

### Play Time by Day of Week

```
┌─────────────────────────────────┐
│   Play Time by Day of Week      │
│                                 │
│ Mon ████████████░░ 2h 15m       │
│ Tue ██████████░░░░ 1h 50m       │
│ Wed ████████░░░░░░ 1h 30m       │
│ Thu ██████░░░░░░░░ 1h 10m       │
│ Fri ████████████████ 3h 20m     │
│ Sat ████████████████████ 4h 5m  │
│ Sun ██████████████░░ 2h 45m     │
│                                 │
│   Most Active: Saturday         │
│   Least Active: Thursday        │
└─────────────────────────────────┘
```

### Play Time Heat Map

```
┌─────────────────────────────────┐
│   Play Time Heat Map (Hours)    │
│                                 │
│     0  4  8  12 16 20           │
│ Mon ░░ ░░ ██ ░░ ░░ ███          │
│ Tue ░░ ░░ ░░ ██ ░░ ██           │
│ Wed ░░ ░░ ░░ ░░ ███ ░░          │
│ Thu ░░ ░░ ██ ░░ ░░ ██           │
│ Fri ░░ ░░ ░░ ░░ ░░ ████         │
│ Sat ░░ ░░ ██ ███ ██ ███         │
│ Sun ░░ ░░ ███ ██ ░░ ██          │
│                                 │
│   Peak: Friday 8-10 PM          │
└─────────────────────────────────┘
```

---

## Comparative Statistics

```swift
struct ComparativeStats {
    let myStats: ModeStatistics
    let friendsAverage: ModeStatistics?
    let globalAverage: ModeStatistics?

    func percentileRank() -> Int {
        // Calculate player's rank among all players (0-100)
        // Higher is better
        return 75 // Example: Top 25%
    }
}
```

### Comparison View

```
┌─────────────────────────────────┐
│   You vs Friends vs Global      │
│                                 │
│   High Score (Endless Mode)     │
│   You:    45,230  ████████████  │
│   Friends: 38,500 ██████████░░  │
│   Global: 52,100  ██████████████│
│                                 │
│   Your Rank: Top 25% globally   │
│   ⭐⭐⭐⭐⭐⭐⭐░░░░              │
│                                 │
│   Average Game Duration         │
│   You:     8m 32s ████████████  │
│   Friends: 7m 15s ██████████░░  │
│   Global:  6m 45s █████████░░░  │
│                                 │
│   [ VIEW MORE COMPARISONS ]     │
└─────────────────────────────────┘
```

---

## Implementation Checklist

- [ ] Create GlobalStatistics data model
- [ ] Implement ModeStatistics per game mode
- [ ] Build StatisticsManager for tracking
- [ ] Create Statistics Dashboard UI
- [ ] Implement per-mode detail views
- [ ] Build score trend chart
- [ ] Create play time visualizations
- [ ] Implement heat map display
- [ ] Build comparative statistics
- [ ] Add data persistence
- [ ] Test data accuracy
- [ ] Performance test with large datasets

---

## Success Criteria

✅ All statistics tracked accurately
✅ Historical data preserved
✅ Charts render smoothly
✅ Comparisons calculate correctly
✅ UI is clear and informative
✅ Data persists across sessions
✅ Performance is instant (<0.1s load)
