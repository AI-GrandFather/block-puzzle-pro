# Feature: Daily & Weekly Challenge Systems

**Priority:** MEDIUM
**Timeline:** Week 11-12
**Dependencies:** All game modes, progression system

---

## Daily Login Rewards

### 7-Day Streak System

**Rewards:**
- Day 1: 50 coins
- Day 2: 75 coins
- Day 3: 100 coins + 1 Undo power-up
- Day 4: 125 coins
- Day 5: 150 coins + 1 Rotation power-up
- Day 6: 200 coins + 1 Bomb power-up
- Day 7: 300 coins + Random theme unlock OR 500 coins

**Extended Streaks:**
- Day 14: 500 coins + Power-up bundle
- Day 30: 1000 coins + Exclusive badge
- Streak continues with increasing rewards

**Streak Saver:**
- Missed day breaks streak
- Can save streak once with 200 coins
- Shown as "Streak Insurance" offer

---

## Daily Challenge Mode

### Structure

**New Challenge Every Day:**
- Generated at midnight local time
- Unique rule set each day
- Available for 24 hours
- Unlimited retries, best score counts

**Challenge Types:**
- High Score Challenge (beat target score)
- Piece Restriction (use only certain pieces)
- Time Attack (60 seconds)
- Limited Moves (clear board in X moves)
- Perfect Clear Challenge
- Combo Challenge (achieve 5x combo)
- Survival Challenge

**Rewards:**
- Completion: 200 XP + 150 coins
- Top 10% globally: Bonus 300 coins
- Daily challenge streak tracking

---

## Weekly Tournament

### Competition Structure

**Weekly Event:**
- Starts Monday 00:00 UTC
- Runs through Sunday 23:59 UTC
- Special rule set announced at start
- Unlimited attempts, best score counts

**Leaderboard Tiers:**
- **Top 10:** 1000 coins + Weekly Champion badge
- **Top 100:** 500 coins + Elite badge
- **Top 1000:** 250 coins + Achiever badge
- **All Participants:** 50 coins for trying

**Tournament Features:**
- Global leaderboard
- Live rank updates
- Replay top performers' games
- Tournament history

---

## Implementation

```swift
struct DailyLoginReward {
    let day: Int
    let coins: Int
    let powerUps: [PowerUpType]?
    let specialReward: SpecialReward?
}

class ChallengeManager {
    func generateDailyChallenge() -> Challenge {
        // Seed-based generation for consistency
        let seed = Calendar.current.startOfDay(for: Date())
        // Generate challenge with seed
    }

    func checkStreak() -> Int {
        // Calculate consecutive days
    }

    func awardLoginReward(day: Int) {
        // Grant rewards
    }
}
```

---

## Success Criteria

✅ Daily login rate >30%
✅ Daily challenge completion rate >25%
✅ Weekly tournament participation >15%
✅ 7-day streak completion >10% of players
✅ 30-day streak completion >2% of players
