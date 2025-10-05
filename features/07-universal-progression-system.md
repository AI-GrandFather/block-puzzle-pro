# Feature: Universal Progression System

**Priority:** HIGH
**Timeline:** Week 7-8
**Dependencies:** All game modes, achievement system, theme system
**Performance Target:** Instant XP calculation, smooth level-up animations

---

## Overview

Implement a comprehensive universal progression system where players level up (1-100+) by earning XP from all game activities. Level progression unlocks themes, features, power-ups, and content, creating a satisfying long-term engagement loop.

---

## Player Leveling System (1-100+)

### XP Sources with Specific Values

```swift
enum XPSource {
    // Score-Based
    case scorePoints(points: Int) // 1 XP per 10 score

    // Line Clearing
    case lineClear // 50 XP each
    case doubleLineClear // 125 XP
    case tripleLineClear // 250 XP
    case quadLineClear // 400 XP

    // Combos
    case combo2x // 100 XP
    case combo5x // 300 XP
    case combo10x // 800 XP
    case combo15x // 1500 XP

    // Level Mode
    case levelComplete1Star // 200 XP
    case levelComplete2Stars // 400 XP
    case levelComplete3Stars // 600 XP
    case timeBonus(seconds: Int) // 10 XP per second remaining

    // Puzzle Mode
    case puzzleFirstTry // 500 XP
    case puzzleRetry // 250 XP
    case dailyPuzzle // 300 XP bonus
    case weeklyChallenge // 500 XP

    // Perfect Clear
    case perfectClear // 500 XP

    // Daily Activities
    case dailyLogin // 50 XP
    case dailyChallenge // 100 XP

    var xpValue: Int {
        switch self {
        case .scorePoints(let points):
            return points / 10
        case .lineClear:
            return 50
        case .doubleLineClear:
            return 125
        case .tripleLineClear:
            return 250
        case .quadLineClear:
            return 400
        case .combo2x:
            return 100
        case .combo5x:
            return 300
        case .combo10x:
            return 800
        case .combo15x:
            return 1500
        case .levelComplete1Star:
            return 200
        case .levelComplete2Stars:
            return 400
        case .levelComplete3Stars:
            return 600
        case .timeBonus(let seconds):
            return seconds * 10
        case .puzzleFirstTry:
            return 500
        case .puzzleRetry:
            return 250
        case .dailyPuzzle:
            return 300
        case .weeklyChallenge:
            return 500
        case .perfectClear:
            return 500
        case .dailyLogin:
            return 50
        case .dailyChallenge:
            return 100
        }
    }
}
```

### Level Requirements

**Exponential Scaling:**

```swift
class LevelProgressionSystem {
    // Base XP for level 1→2: 100
    // Scaling factor: 1.1x per level
    // Formula: XP(level) = 100 * (1.1 ^ (level - 1))

    func xpRequiredForLevel(_ level: Int) -> Int {
        if level <= 1 { return 0 }

        let baseXP = 100.0
        let scalingFactor = 1.1
        let requiredXP = baseXP * pow(scalingFactor, Double(level - 1))

        return Int(requiredXP.rounded())
    }

    func totalXPForLevel(_ level: Int) -> Int {
        // Cumulative XP required to reach this level
        if level <= 1 { return 0 }

        var total = 0
        for lvl in 2...level {
            total += xpRequiredForLevel(lvl)
        }
        return total
    }
}
```

**Level Progression Table (Sample):**
| Level | XP Required | Cumulative XP |
|-------|-------------|---------------|
| 1     | 0           | 0             |
| 2     | 100         | 100           |
| 3     | 110         | 210           |
| 4     | 121         | 331           |
| 5     | 133         | 464           |
| 10    | 236         | 1,594         |
| 20    | 673         | 6,726         |
| 30    | 1,917       | 20,644        |
| 50    | 11,739      | 152,085       |
| 100   | 1,379,896   | 15,110,279    |

### Level-Up Celebration

**Animation Sequence:**

```swift
struct LevelUpAnimation {
    let newLevel: Int
    let unlockedRewards: [Reward]

    func play() {
        // 1. Screen flash (white, 0.2s)
        flashScreen(color: .white, duration: 0.2)

        // 2. Level badge zooms in (0.5s)
        showLevelBadge(level: newLevel, animation: .zoomIn(duration: 0.5))

        // 3. Confetti particle burst (1.5s)
        emitParticles(type: .confetti, count: 200, duration: 1.5)

        // 4. Unlocked rewards reveal (1.0s, cascading 0.2s delays)
        for (index, reward) in unlockedRewards.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(index) * 0.2)) {
                showRewardCard(reward: reward)
            }
        }

        // 5. Sound effect
        playSound(.levelUp) // Triumphant ascending arpeggio

        // 6. Haptic feedback
        triggerHaptic(.success)
    }
}
```

**Visual:**
```
┌─────────────────────────────────┐
│                                 │
│         ✨ LEVEL UP! ✨         │
│                                 │
│            Level 15             │
│           ▲▲▲▲▲▲▲              │
│                                 │
│   Unlocked:                     │
│   🎨 Rotation Power-Up          │
│   🎯 Daily Challenges           │
│                                 │
│   [ AWESOME! ]                  │
└─────────────────────────────────┘
```

**Theme-Appropriate Effect:**
- Classic Light: Rainbow shimmer
- Dark Mode: Electric surge
- Cyberpunk: Digital matrix cascade
- Wooden: Woodchip explosion
- Crystal Ice: Ice crystal burst
- Beach: Firework explosion
- Space: Supernova

---

## Unlockables by Player Level

### Complete Unlock Schedule

```swift
struct LevelUnlock {
    let level: Int
    let reward: Reward
    let description: String
}

enum Reward {
    case feature(FeatureType)
    case theme(ThemeID)
    case powerUp(PowerUpType, count: Int)
    case levelPack(packID: Int)
    case currency(coins: Int)
    case badge(BadgeID)
    case title(TitleID)
}

let unlockSchedule: [LevelUnlock] = [
    // Early Unlocks (1-10)
    LevelUnlock(level: 3, reward: .feature(.holdSlot), description: "Hold Slot feature unlocked!"),
    LevelUnlock(level: 5, reward: .theme(.darkMode), description: "Dark Mode theme unlocked!"),
    LevelUnlock(level: 8, reward: .feature(.dailyChallenge), description: "Daily Challenges unlocked!"),
    LevelUnlock(level: 10, reward: .theme(.neonCyberpunk), description: "Neon Cyberpunk theme unlocked!"),

    // Mid-Tier Unlocks (11-30)
    LevelUnlock(level: 12, reward: .powerUp(.undo, count: 5), description: "5 Undo power-ups granted!"),
    LevelUnlock(level: 15, reward: .powerUp(.rotation, count: 5), description: "Rotation power-up unlocked!"),
    LevelUnlock(level: 18, reward: .feature(.puzzleMode), description: "Puzzle Mode unlocked!"),
    LevelUnlock(level: 20, reward: .theme(.woodenClassic), description: "Wooden Classic theme unlocked!"),
    LevelUnlock(level: 25, reward: .levelPack(packID: 2), description: "Level Pack 2 (Levels 11-20) unlocked!"),
    LevelUnlock(level: 30, reward: .theme(.crystalIce), description: "Crystal Ice theme unlocked!"),

    // High-Tier Unlocks (31-60)
    LevelUnlock(level: 35, reward: .powerUp(.bomb, count: 5), description: "Bomb power-up unlocked!"),
    LevelUnlock(level: 40, reward: .theme(.sunsetBeach), description: "Sunset Beach theme unlocked!"),
    LevelUnlock(level: 45, reward: .levelPack(packID: 3), description: "Level Pack 3 (Levels 21-30) unlocked!"),
    LevelUnlock(level: 50, reward: .theme(.spaceOdyssey), description: "Space Odyssey theme unlocked!"),

    // Expert Unlocks (61-100)
    LevelUnlock(level: 60, reward: .levelPack(packID: 4), description: "Level Pack 4 (Levels 31-40) unlocked!"),
    LevelUnlock(level: 70, reward: .badge(.expertBadge), description: "Expert badge earned!"),
    LevelUnlock(level: 70, reward: .feature(.profileBorder), description: "Exclusive animated profile border!"),
    LevelUnlock(level: 80, reward: .levelPack(packID: 5), description: "Level Pack 5 (Levels 41-50) unlocked!"),
    LevelUnlock(level: 90, reward: .badge(.masterBadge), description: "Master badge earned!"),
    LevelUnlock(level: 90, reward: .title(.master), description: "Title 'Master' unlocked!"),
    LevelUnlock(level: 100, reward: .theme(.legendary), description: "Legendary theme with particle trails!"),
    LevelUnlock(level: 100, reward: .badge(.centuryBadge), description: "Century badge earned!"),
    LevelUnlock(level: 100, reward: .currency(coins: 5000), description: "5000 bonus coins!"),
]
```

### Unlock Notification

**In-Game Popup:**
```
┌─────────────────────────────┐
│   🎁 NEW UNLOCK!            │
│                             │
│   Level 15 Reward:          │
│                             │
│   [Icon: Rotation]          │
│   Rotation Power-Up         │
│                             │
│   You can now rotate pieces │
│   to fit tricky spaces!     │
│                             │
│   5 free uses granted       │
│                             │
│   [ TRY IT NOW ] [ LATER ]  │
└─────────────────────────────┘
```

**Post-Game Summary:**
```
┌─────────────────────────────┐
│   GAME OVER                 │
│   Score: 12,450             │
│                             │
│   +850 XP                   │
│                             │
│   Level Progress:           │
│   ████████████░░ 14 → 15    │
│   🎉 LEVEL UP!              │
│                             │
│   Unlocked:                 │
│   • Rotation Power-Up       │
│                             │
│   [ VIEW REWARDS ]          │
└─────────────────────────────┘
```

---

## Coin Currency System

### Earning Coins

```swift
enum CoinSource {
    // Level Mode
    case levelComplete1Star // 50 coins
    case levelComplete2Stars // 100 coins
    case levelComplete3Stars // 150 coins
    case levelBonusStars // +50 coins per star

    // Daily Activities
    case dailyLogin(streak: Int) // 50 base, +10 per consecutive day (max 200)
    case dailyChallenge // 100 coins

    // Achievements
    case achievementUnlocked(rarity: AchievementRarity)
    // Common: 100, Rare: 200, Epic: 400, Legendary: 1000

    // Special Events
    case perfectClear // 100 coins
    case weeklyPuzzleWin // 150 coins
    case weeklyTournamentTop10 // 1000 coins
    case weeklyTournamentTop100 // 500 coins
    case weeklyTournamentTop1000 // 250 coins

    // Monetization
    case rewardedAd // 25 coins
    case iapPurchase(amount: Int)
    case premiumMonthlyAllowance // 500 coins

    var coinValue: Int {
        switch self {
        case .levelComplete1Star: return 50
        case .levelComplete2Stars: return 100
        case .levelComplete3Stars: return 150
        case .levelBonusStars: return 50
        case .dailyLogin(let streak):
            return min(50 + (streak * 10), 200)
        case .dailyChallenge: return 100
        case .achievementUnlocked(let rarity):
            switch rarity {
            case .common: return 100
            case .rare: return 200
            case .epic: return 400
            case .legendary: return 1000
            }
        case .perfectClear: return 100
        case .weeklyPuzzleWin: return 150
        case .weeklyTournamentTop10: return 1000
        case .weeklyTournamentTop100: return 500
        case .weeklyTournamentTop1000: return 250
        case .rewardedAd: return 25
        case .iapPurchase(let amount): return amount
        case .premiumMonthlyAllowance: return 500
        }
    }
}
```

### Spending Coins

```swift
enum CoinPurchase {
    case hint // 100 coins
    case continueGame // 200 coins
    case undoMove // 50 coins (when out of free)
    case skipLevel // 500 coins
    case unlockThemeEarly(themeID: ThemeID) // 1000 coins
    case powerUpPack(type: PowerUpType, count: Int) // 300 coins for 5
    case unlockLevelPack(packID: Int) // 300-1000 coins (escalating)

    var cost: Int {
        switch self {
        case .hint: return 100
        case .continueGame: return 200
        case .undoMove: return 50
        case .skipLevel: return 500
        case .unlockThemeEarly: return 1000
        case .powerUpPack: return 300
        case .unlockLevelPack(let packID):
            return 300 + (packID * 200) // Pack 2: 500, Pack 3: 700, etc.
        }
    }
}
```

### Coin Balance UI

**Persistent Display:**
- Top-right corner of all screens
- Format: `💰 1,234`
- Tappable to view coin history
- Animates when balance changes

**Coin Animation:**
```swift
struct CoinEarnAnimation {
    func play(amount: Int, from position: CGPoint, to: CGPoint) {
        // 1. Coin icon(s) spawn at source position
        let coinCount = min(amount / 10, 20) // Max 20 visual coins

        for i in 0..<coinCount {
            let coin = createCoinSprite()
            coin.position = position

            // 2. Arc trajectory to coin counter
            let delay = Double(i) * 0.05
            let duration = 0.6

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateCoinToCounter(coin, duration: duration, target: to)
            }
        }

        // 3. Counter increments with rolling digits
        animateCounterIncrement(by: amount, duration: 0.8)

        // 4. Sound: Coin collect jingle
        playSound(.coinCollect)

        // 5. Haptic: Light impact per coin
        triggerHaptic(.light)
    }
}
```

### Coin Purchase Confirmation

```swift
struct CoinPurchaseConfirmation: View {
    let purchase: CoinPurchase
    let currentBalance: Int

    var body: some View {
        VStack {
            Text("Confirm Purchase")
            Text(purchase.description)
            Text("Cost: \(purchase.cost) coins")
            Text("Balance after: \(currentBalance - purchase.cost) coins")

            HStack {
                Button("Cancel") { dismiss() }
                Button("Confirm") { makePurchase() }
            }
        }
    }
}
```

---

## Premium XP Multiplier

### Premium Benefits

```swift
class PremiumBenefits {
    let isActive: Bool

    var xpMultiplier: Double {
        return isActive ? 2.0 : 1.0
    }

    func calculateXP(_ baseXP: Int) -> Int {
        return Int(Double(baseXP) * xpMultiplier)
    }
}
```

**Visual Indicator:**
```
┌─────────────────────────┐
│ +850 XP  [2x Premium!] │ Premium badge
│ ████████████░░ 14 → 15  │
└─────────────────────────┘
```

**Benefits Summary:**
- 2x XP on all activities
- Level up twice as fast
- Unlock themes and features sooner
- Reach max level with half the playtime

---

## XP Calculation System

### Real-Time XP Tracking

```swift
class XPManager: ObservableObject {
    @Published var currentXP: Int = 0
    @Published var currentLevel: Int = 1

    private let progression = LevelProgressionSystem()

    func awardXP(_ source: XPSource, isPremium: Bool = false) {
        var xp = source.xpValue

        // Apply premium multiplier
        if isPremium {
            xp *= 2
        }

        currentXP += xp

        // Check for level up
        checkLevelUp()

        // Show XP gain notification
        showXPGainNotification(amount: xp, source: source)
    }

    private func checkLevelUp() {
        let requiredXP = progression.xpRequiredForLevel(currentLevel + 1)

        while currentXP >= requiredXP {
            currentXP -= requiredXP
            currentLevel += 1

            // Trigger level-up celebration
            triggerLevelUp()
        }
    }

    private func triggerLevelUp() {
        let unlocks = getUnlocksForLevel(currentLevel)

        // Play animation
        LevelUpAnimation(newLevel: currentLevel, unlockedRewards: unlocks).play()

        // Save to persistent storage
        saveProgress()
    }
}
```

### XP Gain Notification

**Floating Text:**
```swift
struct XPGainNotification: View {
    let amount: Int
    let isPremium: Bool

    var body: some View {
        Text("+\(amount) XP")
            .font(.headline)
            .foregroundColor(isPremium ? .gold : .blue)
            .overlay(
                isPremium ? Text("2x").font(.caption).offset(x: 30) : nil
            )
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring())
    }
}
```

**Placement:**
- Floats up from action location (line clear, level complete, etc.)
- Fades out after 1.5 seconds
- Multiple XP gains stack vertically

---

## Profile Display

### Player Profile Screen

```
┌─────────────────────────────────┐
│   [Avatar Border (Animated)]    │
│                                 │
│        PlayerName               │
│        Level 47                 │
│   🏆 Master Player              │
│                                 │
│   XP: 152,085 / 171,824         │
│   ████████████████░░ 88%        │
│                                 │
│   Total Coins: 💰 3,450         │
│                                 │
│   Unlocked:                     │
│   • 6 / 7 Themes                │
│   • 42 / 50 Levels              │
│   • 85 / 120 Achievements       │
│                                 │
│   Play Time: 24h 32m            │
│   Games Played: 487             │
│   High Score: 45,230            │
│                                 │
│   [ EDIT PROFILE ]              │
└─────────────────────────────────┘
```

### Profile Customization

**Unlockable Elements:**
- **Avatar Borders:**
  * Level 10: Bronze border
  * Level 30: Silver border
  * Level 50: Gold border
  * Level 70: Animated rainbow border
  * Level 100: Legendary particle trail border

- **Titles:**
  * Level 25: "Puzzle Enthusiast"
  * Level 50: "Block Master"
  * Level 75: "Grid Legend"
  * Level 90: "Master Player"
  * Level 100: "Grand Master"

- **Badges:**
  * Achievement-based
  * Event-based (weekly tournaments)
  * Milestone-based (1000 games played)

**Profile Badge Display:**
```
┌─────────────────────────────────┐
│   Showcase Badges (Max 3)       │
│   ┌─────┐ ┌─────┐ ┌─────┐       │
│   │ 🏆  │ │ ⭐  │ │ 🎯  │       │
│   │Week │ │Level│ │100  │       │
│   │Champ│ │ 100 │ │Days │       │
│   └─────┘ └─────┘ └─────┘       │
│                                 │
│   All Badges: 23 / 50           │
│   [ VIEW ALL ]                  │
└─────────────────────────────────┘
```

---

## Persistent Storage

### Data Model

```swift
struct PlayerData: Codable {
    var playerID: String
    var username: String
    var currentXP: Int
    var currentLevel: Int
    var totalXPEarned: Int
    var coinBalance: Int
    var totalCoinsEarned: Int
    var totalCoinsSpent: Int

    // Unlocks
    var unlockedThemes: [ThemeID]
    var unlockedLevelPacks: [Int]
    var unlockedPowerUps: [PowerUpType]
    var unlockedBadges: [BadgeID]
    var unlockedTitles: [TitleID]

    // Customization
    var selectedTitle: TitleID?
    var selectedBorder: BorderID?
    var showcaseBadges: [BadgeID]

    // Statistics
    var totalPlayTime: TimeInterval
    var gamesPlayed: Int
    var highScore: Int
    var levelsCompleted: Int
    var achievementsUnlocked: Int

    // Timestamps
    var accountCreated: Date
    var lastLogin: Date
    var lastXPGain: Date
}
```

### Auto-Save

```swift
class ProgressionManager {
    func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(playerData) {
            UserDefaults.standard.set(data, forKey: "playerData")
        }
    }

    func load() -> PlayerData? {
        guard let data = UserDefaults.standard.data(forKey: "playerData") else {
            return nil
        }

        let decoder = JSONDecoder()
        return try? decoder.decode(PlayerData.self, from: data)
    }

    func autoSave() {
        // Save every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.save()
        }
    }
}
```

---

## Implementation Checklist

- [ ] Create XPSource enum with all sources and values
- [ ] Implement LevelProgressionSystem with exponential scaling
- [ ] Build XPManager for real-time XP tracking
- [ ] Create level-up detection and celebration animation
- [ ] Implement unlock schedule for all 100 levels
- [ ] Build coin earning system
- [ ] Create coin spending system with confirmations
- [ ] Implement coin balance UI and animations
- [ ] Build premium XP multiplier (2x)
- [ ] Create XP gain notifications
- [ ] Design and implement Player Profile screen
- [ ] Build profile customization (borders, titles, badges)
- [ ] Implement persistent storage (PlayerData model)
- [ ] Create auto-save system
- [ ] Build unlock notification system
- [ ] Test level progression balance
- [ ] Test coin economy balance
- [ ] Verify all unlocks trigger correctly
- [ ] Performance test XP calculations
- [ ] Test data persistence across app kills

---

## Success Criteria

✅ XP is awarded correctly from all sources
✅ Level progression uses exponential scaling
✅ Level-up animations are celebratory and satisfying
✅ All unlocks trigger at correct levels
✅ Coin earning and spending work correctly
✅ Coin balance updates in real-time
✅ Premium 2x XP multiplier functions properly
✅ XP gain notifications appear correctly
✅ Player profile displays all relevant information
✅ Profile customization works (borders, titles, badges)
✅ Data persists correctly across sessions
✅ Auto-save prevents progress loss
✅ Unlock notifications inform players clearly
✅ Progression feels rewarding and balanced
✅ Economy is balanced (coins earned vs. spent)
✅ Reaching level 100 feels achievable but challenging
✅ Performance is smooth with real-time XP tracking
