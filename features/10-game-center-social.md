# Feature: Game Center Integration & Social Features

**Priority:** HIGH
**Timeline:** Week 7-8
**Dependencies:** All game modes, achievement system, statistics
**Performance Target:** Quick leaderboard loading (<1s), instant friend updates

---

## Overview

Integrate Game Center for leaderboards, achievements, and social features. Enable players to compete with friends and globally, share accomplishments, and engage with the community.

---

## Game Center Setup

```swift
import GameKit

class GameCenterManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?

    func authenticatePlayer() {
        localPlayer = GKLocalPlayer.local

        localPlayer?.authenticateHandler = { viewController, error in
            if let viewController = viewController {
                // Present authentication view
                self.presentAuthenticationViewController(viewController)
            } else if self.localPlayer?.isAuthenticated == true {
                self.isAuthenticated = true
                self.loadGameCenterData()
            } else {
                print("Game Center authentication failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }

    func loadGameCenterData() {
        loadLeaderboards()
        loadAchievements()
        loadFriends()
    }
}
```

---

## Leaderboards

### Leaderboard Configuration

```swift
enum LeaderboardID: String {
    // Endless Mode
    case endlessHighScore = "com.blockpuzzle.endless.highscore"

    // Timed Modes
    case sprint3MinHighScore = "com.blockpuzzle.sprint3.highscore"
    case standard5MinHighScore = "com.blockpuzzle.standard5.highscore"
    case marathon7MinHighScore = "com.blockpuzzle.marathon7.highscore"

    // Levels
    case levelsTotalStars = "com.blockpuzzle.levels.totalstars"

    // Puzzles
    case puzzlesTotalSolved = "com.blockpuzzle.puzzles.totalsolved"
    case dailyPuzzleFastestTime = "com.blockpuzzle.dailypuzzle.fastesttime"
    case weeklyChallenge = "com.blockpuzzle.weekly.score"
}
```

### Score Submission

```swift
class LeaderboardManager {
    func submitScore(_ score: Int, to leaderboardID: LeaderboardID) {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID.rawValue]
                )
                print("Score submitted successfully")
            } catch {
                print("Score submission failed: \(error.localizedDescription)")
            }
        }
    }
}
```

### Leaderboard Display

```
┌─────────────────────────────────┐
│   🏆 Endless Mode Leaderboard   │
│                                 │
│   [Global] [Friends] [Regional] │
│                                 │
│  Rank  Player         Score     │
│  ────────────────────────────   │
│  🥇 1  ProPlayer     125,430    │
│  🥈 2  GridMaster    118,200    │
│  🥉 3  BlockKing     112,500    │
│   4    QuickThink    105,800    │
│   5    PuzzlePro     98,450     │
│  ...                            │
│  ➡ 47   YOU          45,230     │
│  ...                            │
│                                 │
│  12,543 players ranked          │
│                                 │
│  [ JUMP TO ME ]  [ REFRESH ]    │
└─────────────────────────────────┘
```

**Features:**
- **Filter Tabs:** Global / Friends / Regional
- **Jump to Position:** Quick scroll to player's rank
- **Refresh:** Manual update option
- **Player Highlight:** Current player shown with arrow
- **Medal Icons:** Top 3 get gold, silver, bronze
- **Profile View:** Tap any player to see their profile
- **Time Scope:** Today / Week / All-Time (where applicable)

---

## Achievement Sync

### Game Center Achievement Mapping

```swift
struct GameCenterAchievement {
    let gcID: String
    let localID: String
    let percentComplete: Double

    func submit() {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        let achievement = GKAchievement(identifier: gcID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Achievement report failed: \(error.localizedDescription)")
            }
        }
    }
}
```

**Achievement ID Mapping:**
```swift
let achievementMapping: [String: String] = [
    // Local ID : Game Center ID
    "first_steps": "com.blockpuzzle.achievement.firststeps",
    "high_scorer": "com.blockpuzzle.achievement.highscorer",
    "combo_master": "com.blockpuzzle.achievement.combomaster",
    "level_conqueror": "com.blockpuzzle.achievement.levelconqueror",
    // ... (all 50+ achievements)
]
```

**Game Center Banner:**
- Automatic display when achievement unlocks
- Shows achievement title and icon
- Disappears after 5 seconds
- Doesn't interfere with gameplay

---

## Friend System

### Friend List

```swift
class FriendManager: ObservableObject {
    @Published var friends: [GKPlayer] = []

    func loadFriends() {
        guard GKLocalPlayer.local.isAuthenticated else { return }

        Task {
            do {
                let friends = try await GKLocalPlayer.local.loadFriends()
                await MainActor.run {
                    self.friends = friends
                }
            } catch {
                print("Failed to load friends: \(error.localizedDescription)")
            }
        }
    }

    func loadFriendsScores(leaderboardID: LeaderboardID) async -> [GKLeaderboard.Entry] {
        // Load scores for all friends
        // Used for friend-only leaderboard views
    }
}
```

### Friend Activity Feed

```
┌─────────────────────────────────┐
│   👥 Friends Activity           │
│                                 │
│   Sarah123                      │
│   🏆 New high score: 52,100     │
│   5 minutes ago                 │
│   [ CHALLENGE ]                 │
│                                 │
│   Mike_Gamer                    │
│   ⭐ Unlocked: Combo Master     │
│   2 hours ago                   │
│                                 │
│   Alex_Puzzle                   │
│   🎯 Completed Level Pack 3     │
│   Yesterday                     │
│   [ VIEW STATS ]                │
│                                 │
│   ProPlayer22                   │
│   💎 Reached Level 50           │
│   2 days ago                    │
│                                 │
└─────────────────────────────────┘
```

### Friend Challenge

```swift
struct FriendChallenge {
    let challenger: GKPlayer
    let challenged: GKPlayer
    let mode: GameMode
    let targetScore: Int
    let expiresAt: Date

    func send() {
        // Send Game Center notification
        // "PlayerName challenges you to beat their score of X!"
    }
}
```

**Challenge Flow:**
1. Player taps "Challenge" on friend's score
2. Notification sent via Game Center
3. Friend receives challenge
4. Friend plays game trying to beat score
5. If beaten, original player gets notified
6. Can counter-challenge

---

## Social Sharing

### Share Options

```swift
struct SocialShare {
    let type: ShareType
    let content: ShareContent

    enum ShareType {
        case achievement
        case highScore
        case levelCompletion
        case puzzle Solved
    }

    struct ShareContent {
        let title: String
        let message: String
        let image: UIImage?
        let url: URL?
    }

    func present(from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [content.message, content.image].compactMap { $0 },
            applicationActivities: nil
        )
        viewController.present(activityVC, animated: true)
    }
}
```

**Share Templates:**
```
Achievement Unlock:
"🏆 Just unlocked 'Combo Master' in Block Puzzle!
Can you beat my 10x combo?
#BlockPuzzle"

High Score:
"🎮 New personal best: 45,230 points in Block Puzzle!
Think you can beat it?
#BlockPuzzle #HighScore"

Level Completion:
"⭐⭐⭐ Perfect score on Level 50!
#BlockPuzzle #MasterLevel"

Puzzle Solved:
"🧩 Solved today's puzzle in 2:15!
Can you do better?
#DailyPuzzle #BlockPuzzle"
```

**Share Destinations:**
- Twitter
- Facebook
- Instagram Stories
- Messages
- Mail
- Copy Link

---

## Profile Viewing

### Friend Profile

```
┌─────────────────────────────────┐
│   [Avatar: Sarah123]            │
│                                 │
│   Sarah123                      │
│   Level 42 • Online             │
│                                 │
│   Best Scores:                  │
│   Endless: 52,100  (🥇#12)      │
│   Sprint:  8,450   (🥈#25)      │
│   Levels:  ⭐⭐⭐ 135/150        │
│                                 │
│   Recent Achievements:          │
│   🏆 Combo Master               │
│   🏆 Perfect Campaigner         │
│   🏆 Week Warrior               │
│                                 │
│   Playing Time: 32h 15m         │
│   Games Played: 589             │
│                                 │
│   [ CHALLENGE ]  [ MESSAGE ]    │
└─────────────────────────────────┘
```

---

## Weekly Rotating Leaderboard

### Special Weekly Competition

```swift
struct WeeklyLeaderboardEvent {
    let weekNumber: Int
    let mode: GameMode
    let specialRule: String?
    let startDate: Date
    let endDate: Date

    let rewards: [LeaderboardReward]
}

struct LeaderboardReward {
    let rankRange: ClosedRange<Int>
    let xp: Int
    let coins: Int
    let badge: BadgeID?
}
```

**Weekly Event Example:**
```
┌─────────────────────────────────┐
│   🏆 Weekly Event #51           │
│   "Speed Challenge"             │
│                                 │
│   Mode: 3-Minute Sprint         │
│   Special: 2x Combo Multiplier  │
│                                 │
│   Time Remaining: 2d 14h 32m    │
│                                 │
│   Top 10: 1000 coins + Badge    │
│   Top 100: 500 coins            │
│   Top 1000: 250 coins           │
│                                 │
│   Your Rank: #247               │
│   Your Score: 12,450            │
│                                 │
│   Leader: ProPlayer (18,230)    │
│                                 │
│   [ PLAY NOW ]  [ LEADERBOARD ] │
└─────────────────────────────────┘
```

---

## Notifications

### Push Notification Types

```swift
enum GameCenterNotification {
    case friendBeatYourScore(friend: GKPlayer, score: Int)
    case friendChallengeYou(friend: GKPlayer, challenge: FriendChallenge)
    case weeklyEventStarted(event: WeeklyLeaderboardEvent)
    case weeklyEventEnding(event: WeeklyLeaderboardEvent, hoursLeft: Int)
    case climbedRankings(newRank: Int, oldRank: Int)
}
```

**Notification Content:**
- "Sarah123 just beat your score of 45,230 with 52,100!"
- "Mike_Gamer challenges you to beat their score!"
- "New Weekly Event started: Speed Challenge!"
- "Only 6 hours left in this week's event!"
- "You climbed to #35 in the global rankings! (+12)"

**User Control:**
- Settings toggle for each notification type
- Quiet hours support
- Frequency limits (max 3 per day)

---

## Implementation Checklist

- [ ] Set up Game Center in App Store Connect
- [ ] Create all leaderboard IDs
- [ ] Create all achievement IDs
- [ ] Implement GameCenterManager authentication
- [ ] Build LeaderboardManager for score submission
- [ ] Create Leaderboard UI (Global/Friends/Regional)
- [ ] Implement achievement sync to Game Center
- [ ] Build FriendManager for friend list
- [ ] Create Friend Activity Feed UI
- [ ] Implement Friend Challenge system
- [ ] Build Social Sharing functionality
- [ ] Create Friend Profile view
- [ ] Implement Weekly Rotating Leaderboard
- [ ] Set up push notifications
- [ ] Test Game Center integration thoroughly
- [ ] Test offline graceful degradation
- [ ] Performance test leaderboard loading

---

## Success Criteria

✅ Game Center authenticates correctly
✅ All leaderboards update in real-time
✅ Achievements sync to Game Center
✅ Friend list loads successfully
✅ Friend activity feed updates
✅ Challenges send and receive correctly
✅ Social sharing works on all platforms
✅ Profile viewing displays accurate data
✅ Weekly events create engagement
✅ Notifications are timely and relevant
✅ Offline mode gracefully degrades
✅ Performance is smooth (<1s leaderboard load)
