# Feature: Achievement System

**Priority:** HIGH
**Timeline:** Week 7-8
**Dependencies:** All game modes, progression system, statistics tracking
**Performance Target:** Instant unlock detection, smooth notification animations

---

## Overview

Implement a comprehensive achievement system with 50+ achievements across multiple categories, providing additional goals and rewards for players. Achievements unlock badges, coins, and special recognition.

---

## Achievement Structure

```swift
struct Achievement: Identifiable, Codable {
    let id: String
    let category: AchievementCategory
    let rarity: AchievementRarity
    let title: String
    let description: String
    let icon: String
    
    // Requirements
    let requirement: AchievementRequirement
    let targetValue: Int
    
    // Rewards
    let xpReward: Int
    let coinReward: Int
    let badgeUnlock: BadgeID?
    
    // Progress
    var currentProgress: Int = 0
    var isUnlocked: Bool = false
    var unlockedDate: Date?
}

enum AchievementCategory: String {
    case gettingStarted
    case scoring
    case combos
    case lineClearling
    case modes
    case specialMoves
    case consistency
}

enum AchievementRarity: String {
    case common    // Bronze, 100 coins
    case rare      // Silver, 200 coins
    case epic      // Gold, 400 coins
    case legendary // Platinum, 1000 coins
}
```

---

## Achievement Categories (50+ Achievements)

### Getting Started (5 achievements)
- **First Steps**: Complete the tutorial (Common, 100 XP, 50 coins)
- **Piece Placer**: Place 100 pieces (Common, 150 XP, 100 coins)
- **Line Clearer**: Clear first line (Common, 100 XP, 50 coins)
- **Quick Learner**: Reach level 5 (Common, 200 XP, 100 coins)
- **Dedicated Player**: Play 3 days in a row (Rare, 300 XP, 200 coins)

### Scoring Masters (8 achievements)
- **High Scorer**: Reach 1,000 points in Endless (Common, 200 XP, 100 coins)
- **Five Figure Club**: Reach 10,000 points (Rare, 400 XP, 200 coins)
- **Elite Scorer**: Reach 50,000 points (Epic, 800 XP, 400 coins)
- **Legendary Score**: Reach 100,000 points (Legendary, 1500 XP, 1000 coins)
- **Speed Scorer**: Score 5,000 in Sprint mode (Rare, 400 XP, 200 coins)
- **Marathon Runner**: Score 15,000 in Marathon mode (Epic, 600 XP, 400 coins)
- **Perfect Game**: Get 3 perfect clears in one game (Epic, 800 XP, 400 coins)
- **Flawless Victory**: Complete level with maximum stars and no mistakes (Rare, 500 XP, 250 coins)

### Combo Specialist (7 achievements)
- **Combo Starter**: Achieve 2x combo (Common, 100 XP, 50 coins)
- **Combo Addict**: Achieve 5x combo (Rare, 300 XP, 200 coins)
- **Combo Master**: Achieve 10x combo (Epic, 600 XP, 400 coins)
- **Combo Legend**: Achieve 15x combo (Legendary, 1200 XP, 1000 coins)
- **Chain Reaction**: Clear 5 lines in one placement (Epic, 700 XP, 400 coins)
- **Cascade King**: Trigger 3 cascades in one game (Rare, 400 XP, 200 coins)
- **Combo Streak**: Maintain combo through entire game (20+ moves) (Epic, 800 XP, 400 coins)

### Line Clearing (6 achievements)
- **Line Veteran**: Clear 100 lines total (Common, 200 XP, 100 coins)
- **Line Expert**: Clear 1,000 lines total (Rare, 500 XP, 200 coins)
- **Line Master**: Clear 10,000 lines total (Epic, 1000 XP, 400 coins)
- **Double Trouble**: Clear 2 lines simultaneously 25 times (Rare, 400 XP, 200 coins)
- **Triple Threat**: Clear 3 lines simultaneously 10 times (Epic, 600 XP, 400 coins)
- **Quad Squad**: Clear 4 lines simultaneously (Epic, 800 XP, 400 coins)

### Mode Mastery (10 achievements)
- **Endless Warrior**: Play 50 Endless games (Common, 300 XP, 150 coins)
- **Endless Legend**: Reach 25,000 in Endless (Epic, 800 XP, 400 coins)
- **Level Conqueror**: Complete all 50 levels (Legendary, 2000 XP, 1000 coins)
- **Three Star General**: Get 3 stars on 30 levels (Epic, 1000 XP, 400 coins)
- **Perfect Campaigner**: 3-star all levels in one pack (Rare, 600 XP, 300 coins)
- **Puzzle Solver**: Complete 25 daily puzzles (Rare, 500 XP, 250 coins)
- **Puzzle Genius**: Solve 100 puzzles total (Epic, 1000 XP, 500 coins)
- **Time Trial Master**: Beat all time trial personal bests in one session (Epic, 800 XP, 400 coins)
- **Zen Master**: Play 10 hours in Zen mode (Rare, 600 XP, 300 coins)
- **Mode Explorer**: Play at least once in all modes (Common, 300 XP, 150 coins)

### Special Moves (8 achievements)
- **Perfectionist**: Get 10 perfect clears (Rare, 500 XP, 250 coins)
- **Perfect Precision**: 5 perfect clears in one game (Epic, 800 XP, 400 coins)
- **Hold Expert**: Use hold slot 100 times (Common, 300 XP, 150 coins)
- **Hold Master**: Win game using hold perfectly each turn (Epic, 700 XP, 400 coins)
- **Power User**: Use 50 power-ups (Rare, 400 XP, 200 coins)
- **Strategic Genius**: Complete level using only 3 holds (Rare, 500 XP, 250 coins)
- **Minimalist**: Complete level without using hold (Rare, 500 XP, 250 coins)
- **Rotation Expert**: Use rotation power-up effectively 25 times (Rare, 400 XP, 200 coins)

### Consistency (6 achievements)
- **Week Warrior**: Play 7 days in a row (Rare, 400 XP, 200 coins)
- **Month Master**: Play 30 days in a row (Epic, 1000 XP, 500 coins)
- **Dedicated Fan**: Play 100 days total (Epic, 1200 XP, 600 coins)
- **Daily Challenger**: Complete 10 daily puzzles in a row (Rare, 500 XP, 250 coins)
- **Streak Master**: Maintain 30-day streak (Legendary, 1500 XP, 1000 coins)
- **Always Improving**: Reach new personal best 10 games in a row (Rare, 600 XP, 300 coins)

---

## Achievement Tracking System

```swift
class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: [Achievement] = []
    
    func checkProgress(event: GameEvent) {
        for i in 0..<achievements.count {
            guard !achievements[i].isUnlocked else { continue }
            
            if achievements[i].shouldUpdate(for: event) {
                achievements[i].currentProgress += event.value
                
                if achievements[i].currentProgress >= achievements[i].targetValue {
                    unlockAchievement(&achievements[i])
                }
            }
        }
    }
    
    private func unlockAchievement(_ achievement: inout Achievement) {
        achievement.isUnlocked = true
        achievement.unlockedDate = Date()
        
        // Award rewards
        awardXP(achievement.xpReward)
        awardCoins(achievement.coinReward)
        
        if let badge = achievement.badgeUnlock {
            unlockBadge(badge)
        }
        
        // Show notification
        showAchievementNotification(achievement)
        
        // Save progress
        saveAchievements()
    }
}
```

---

## Achievement UI

### Achievement Menu

```
┌─────────────────────────────────┐
│   🏆 Achievements               │
│   45 / 120 Unlocked (38%)       │
│                                 │
│   ▼ Getting Started (5/5) ✅    │
│   ▼ Scoring Masters (3/8)       │
│     ✅ High Scorer              │
│     ✅ Five Figure Club         │
│     ✅ Elite Scorer             │
│     🔒 Legendary Score          │
│        Progress: 65,000/100,000 │
│     🔒 Speed Scorer             │
│     🔒 Marathon Runner          │
│     🔒 Perfect Game             │
│     🔒 Flawless Victory         │
│                                 │
│   [Filter: All | Locked | 🆕]  │
└─────────────────────────────────┘
```

### Achievement Detail View

```
┌─────────────────────────────────┐
│   🏆 Legendary Score            │
│   Legendary Achievement         │
│                                 │
│   "Reach 100,000 points in a   │
│    single Endless game"         │
│                                 │
│   Progress:                     │
│   ███████████░░░ 65,000/100,000 │
│   65% Complete                  │
│                                 │
│   Rewards:                      │
│   • 1500 XP                     │
│   • 1000 Coins                  │
│   • Legendary Badge             │
│                                 │
│   Rarity: 0.5% of players       │
│                                 │
│   [ CLOSE ]                     │
└─────────────────────────────────┘
```

### Achievement Unlock Notification

**Banner (slides from top, 3 seconds):**
```
┌─────────────────────────────────┐
│  🎉 Achievement Unlocked!       │
│                                 │
│  🏆 Combo Master                │
│  "Achieve 10x combo"            │
│                                 │
│  +600 XP  +400 Coins            │
└─────────────────────────────────┘
```

**Animation:**
- Slides down from top edge
- Gold shimmer effect (rarity-based color)
- Particle burst
- Chime sound effect
- Haptic success feedback
- Auto-dismisses after 3 seconds or tap

---

## Implementation Checklist

- [ ] Create Achievement data model
- [ ] Implement AchievementManager for tracking
- [ ] Build all 50+ achievements with requirements
- [ ] Create progress tracking system
- [ ] Implement unlock detection
- [ ] Build Achievement Menu UI
- [ ] Create Achievement Detail View
- [ ] Implement unlock notification banner
- [ ] Add reward distribution
- [ ] Create achievement persistence
- [ ] Implement filter/search functionality
- [ ] Build showcase system (pin favorites)
- [ ] Test all achievement unlocks
- [ ] Balance achievement difficulty
- [ ] Performance test tracking system

---

## Success Criteria

✅ All 50+ achievements implemented
✅ Progress tracked accurately across sessions
✅ Unlocks detected instantly
✅ Notifications appear correctly
✅ Rewards distributed properly
✅ UI is intuitive and informative
✅ Achievement progress persists
✅ Showcase system works
✅ Performance is smooth
✅ Achievements feel rewarding and fair
