# Feature: Rewarded Ads & Ad Implementation

**Priority:** HIGH
**Timeline:** Week 9-10
**Dependencies:** Google AdMob SDK, monetization balance
**Performance Target:** <3s ad load, smooth transitions

---

## Overview

Implement rewarded and interstitial ads using Google AdMob, providing players with optional video ads for bonuses while maintaining respectful, non-intrusive advertising for free users.

---

## AdMob SDK Setup

```swift
import GoogleMobileAds

class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()

    @Published var isAdLoaded: [AdType: Bool] = [:]
    @Published var adsRemoved: Bool = false

    private var rewardedAd: GADRewardedAd?
    private var interstitialAd: GADInterstitialAd?

    private var lastInterstitialShown: Date?
    private let interstitialMinInterval: TimeInterval = 180 // 3 minutes

    override init() {
        super.init()
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadAdsRemoved Status()
        preloadAds()
    }

    private func loadAdsRemovedStatus() {
        adsRemoved = UserDefaults.standard.bool(forKey: "adsRemoved")
    }
}

enum AdType {
    case rewarded
    case interstitial
}
```

---

## Rewarded Ads Implementation

### Ad Loading

```swift
extension AdManager {
    func loadRewardedAd() {
        let request = GADRequest()

        GADRewardedAd.load(
            withAdUnitID: "ca-app-pub-XXXXX/rewarded", // Replace with real ID
            request: request
        ) { [weak self] ad, error in
            if let error = error {
                print("Failed to load rewarded ad: \(error.localizedDescription)")
                self?.isAdLoaded[.rewarded] = false
                return
            }

            self?.rewardedAd = ad
            self?.isAdLoaded[.rewarded] = true
            self?.rewardedAd?.fullScreenContentDelegate = self
        }
    }

    func showRewardedAd(
        from viewController: UIViewController,
        for reward: AdReward,
        completion: @escaping (Bool) -> Void
    ) {
        guard let rewardedAd = rewardedAd else {
            completion(false)
            return
        }

        rewardedAd.present(fromRootViewController: viewController) {
            let rewardAmount = rewardedAd.adReward.amount
            print("User earned reward: \(rewardAmount)")

            // Grant reward
            self.grantReward(reward)
            completion(true)

            // Preload next ad
            self.loadRewardedAd()
        }
    }

    private func grantReward(_ reward: AdReward) {
        switch reward {
        case .continueGame:
            // Already handled by game state
            break
        case .unlockLevelTemporary:
            // Grant temporary access
            break
        case .hint:
            // Grant hint
            break
        case .extraTime(let seconds):
            // Add time to game
            GameManager.shared.addTime(seconds)
        case .undo:
            // Grant one undo
            PowerUpManager.shared.grantUndo(1)
        case .doubleScore:
            // Activate 2x multiplier
            GameManager.shared.activateDoubleScore()
        case .dailyCoins:
            // Grant 25 coins
            CoinManager.shared.addCoins(25, source: .rewardedAd)
        case .unlockThemeTemporary:
            // Grant 3-game theme access
            break
        case .powerUp:
            // Grant random power-up
            PowerUpManager.shared.grantRandom()
        }
    }
}

enum AdReward {
    case continueGame
    case unlockLevelTemporary
    case hint
    case extraTime(seconds: Int)
    case undo
    case doubleScore
    case dailyCoins
    case unlockThemeTemporary
    case powerUp
}
```

---

## Rewarded Ad Opportunities

### 1. Continue After Game Over

**Trigger:** Endless mode game over
**Reward:** Continue with current score
**Frequency:** Once per game

```
┌─────────────────────────────────┐
│        GAME OVER                │
│                                 │
│   Final Score: 12,450           │
│                                 │
│   Continue playing and keep     │
│   your score?                   │
│                                 │
│   Watch a 30-second ad to:      │
│   ✓ Keep your 12,450 points     │
│   ✓ Continue from where you     │
│     left off                    │
│                                 │
│   [  WATCH AD TO CONTINUE  ]    │
│   [ No Thanks - End Game ]      │
└─────────────────────────────────┘
```

### 2. Unlock Level Temporarily

**Trigger:** Player attempts to play locked level
**Reward:** 3 attempts at the level
**Frequency:** Once per level per day

```
┌─────────────────────────────────┐
│   Level 25 is Locked            │
│                                 │
│   Unlock Requirement:           │
│   Complete Level 20 OR          │
│   Player Level 25               │
│                                 │
│   Try this level now!           │
│                                 │
│   Watch an ad to unlock for:    │
│   • 3 attempts                  │
│   • Stars earned don't count    │
│   • Good for practice!          │
│                                 │
│   [  WATCH AD TO TRY  ]         │
│   [   Skip (500 coins)   ]      │
│   [       Cancel        ]       │
└─────────────────────────────────┘
```

### 3. Hint in Puzzle Mode

**Trigger:** Player taps hint button
**Reward:** Reveal optimal next move
**Frequency:** Unlimited (different puzzles)

```
┌─────────────────────────────────┐
│   Need a Hint?                  │
│                                 │
│   Watch a short ad to reveal    │
│   the optimal next move for     │
│   this puzzle.                  │
│                                 │
│   Hint will show:               │
│   ✓ Which piece to use          │
│   ✓ Where to place it           │
│   ✓ Expected result             │
│                                 │
│   [  WATCH AD FOR HINT  ]       │
│   [  Pay 100 Coins  ]           │
│   [      Cancel      ]          │
└─────────────────────────────────┘
```

### 4. Extra Time in Timed Mode

**Trigger:** Player opts to add time before game ends
**Reward:** +30 seconds
**Frequency:** Once per game

```
┌─────────────────────────────────┐
│   Time Running Low!             │
│                                 │
│   Time Remaining: 0:15          │
│   Current Score: 8,450          │
│                                 │
│   Add 30 seconds to keep        │
│   playing and increase your     │
│   score!                        │
│                                 │
│   [  WATCH AD (+30s)  ]         │
│   [   No Thanks    ]            │
└─────────────────────────────────┘
```

### 5. Undo Move (When Out of Free Undos)

**Trigger:** Player attempts undo without free uses
**Reward:** One undo use
**Frequency:** Unlimited

### 6. Daily 2x Score Multiplier

**Trigger:** Pre-game boost option
**Reward:** 2x score for entire next game
**Frequency:** Once per day

### 7. Daily Coin Bonus

**Trigger:** Daily bonus collection
**Reward:** 25 coins
**Frequency:** Once per day

### 8. Unlock Theme for 3 Games

**Trigger:** Player tries premium theme
**Reward:** Temporary access (3 games)
**Frequency:** Once per theme per day

### 9. Power-up Boost

**Trigger:** Daily bonus or special prompt
**Reward:** Random power-up
**Frequency:** Once per day

---

## Interstitial Ads (Free Version)

### Interstitial Rules

```swift
extension AdManager {
    func shouldShowInterstitial() -> Bool {
        // Never show if ads removed
        guard !adsRemoved else { return false }

        // Check minimum interval (3 minutes)
        if let lastShown = lastInterstitialShown {
            let elapsed = Date().timeIntervalSince(lastShown)
            guard elapsed >= interstitialMinInterval else {
                return false
            }
        }

        // Check game count (1 ad per 3 games)
        let gamesPlayed = UserDefaults.standard.integer(forKey: "gamesSinceLastAd")
        guard gamesPlayed >= 3 else {
            return false
        }

        // Don't show if just watched rewarded ad
        if let lastRewarded = lastRewardedAdShown {
            let elapsed = Date().timeIntervalSince(lastRewarded)
            guard elapsed >= 300 else { // 5 minutes
                return false
            }
        }

        return true
    }

    func showInterstitial(from viewController: UIViewController) {
        guard shouldShowInterstitial(), let interstitialAd = interstitialAd else {
            return
        }

        interstitialAd.present(fromRootViewController: viewController)
        lastInterstitialShown = Date()
        UserDefaults.standard.set(0, forKey: "gamesSinceLastAd")

        // Preload next ad
        loadInterstitialAd()
    }
}
```

**Interstitial Timing:**
- **Trigger:** After game over in Endless mode
- **Frequency Cap:** Maximum 1 ad per 3 games
- **Time Limit:** Minimum 3 minutes between ads
- **Exclusion:** Not shown if player just watched rewarded ad
- **Skippable:** 5-second delay before skip button

### Post-Ad "Remove Ads" Prompt

```
┌─────────────────────────────────┐
│   Enjoying the Game?            │
│                                 │
│   Remove ads forever for just   │
│   $4.99!                        │
│                                 │
│   ✓ No more interruptions       │
│   ✓ Clean, ad-free menus        │
│   ✓ Keep rewarded ad bonuses    │
│   ✓ One-time purchase           │
│                                 │
│   [  REMOVE ADS - $4.99  ]      │
│   [    Maybe Later    ]         │
└─────────────────────────────────┘
```

**Shown After:** Every 3rd interstitial ad

---

## Ad Display Guidelines

### Respectful Advertising Principles

```swift
struct AdGuidelines {
    // Frequency limits
    static let maxAdsPerHour = 3
    static let minTimeBetweenAds: TimeInterval = 180 // 3 minutes
    static let maxAdsPerSession = 5

    // Never show ads during:
    static let noAdDuring: [GameState] = [
        .playing,           // Active gameplay
        .paused,            // Paused state
        .levelTransition,   // Between levels
        .tutorial           // Tutorial screens
    ]

    // Disable ads for first 3 games (tutorial period)
    static let tutorialGameCount = 3
}
```

**Rules:**
1. **Never Interrupt Gameplay:** Ads only at natural decision points
2. **Clear Benefit Statement:** Always show what player gets before ad
3. **Always Optional:** Cancel button always available
4. **Fallback Handling:** If ad fails to load, still grant benefit OR offer coin alternative
5. **Time Limit:** 30-second maximum ad length
6. **No Tricks:** No fake X buttons, clear skip timing

### Ad Loading Indicator

```
┌─────────────────────────────────┐
│   Loading Ad...                 │
│                                 │
│   ⏳ Please wait                │
│   ████████░░░░ 75%              │
│                                 │
│   This will only take a moment  │
│                                 │
│   [ Cancel ]                    │
└─────────────────────────────────┘
```

**If Ad Fails to Load:**
```
┌─────────────────────────────────┐
│   Ad Unavailable                │
│                                 │
│   We couldn't load an ad right  │
│   now. Would you like to:       │
│                                 │
│   Option 1: Try again           │
│   Option 2: Use 50 coins        │
│   Option 3: Skip for now        │
│                                 │
│   [Try Again] [50¢] [Cancel]    │
└─────────────────────────────────┘
```

---

## Ad Analytics

```swift
class AdAnalytics {
    func trackAdImpression(type: AdType, placement: String) {
        Analytics.logEvent("ad_impression", parameters: [
            "ad_type": type.rawValue,
            "placement": placement,
            "timestamp": Date()
        ])
    }

    func trackAdClick(type: AdType, placement: String) {
        Analytics.logEvent("ad_click", parameters: [
            "ad_type": type.rawValue,
            "placement": placement,
            "timestamp": Date()
        ])
    }

    func trackAdReward(type: AdType, reward: AdReward, completed: Bool) {
        Analytics.logEvent("ad_reward", parameters: [
            "ad_type": type.rawValue,
            "reward": String(describing: reward),
            "completed": completed,
            "timestamp": Date()
        ])
    }

    func trackAdRevenue(value: Double, currency: String) {
        Analytics.logEvent("ad_revenue", parameters: [
            "value": value,
            "currency": currency,
            "timestamp": Date()
        ])
    }
}
```

**Tracked Metrics:**
- Impressions per session
- Click-through rate
- Reward completion rate
- Ad revenue (estimated)
- User conversion after ads
- "Remove Ads" purchase rate

---

## Implementation Checklist

- [ ] Integrate Google AdMob SDK
- [ ] Configure ad unit IDs in AdMob dashboard
- [ ] Implement AdManager class
- [ ] Build rewarded ad loading system
- [ ] Create rewarded ad UI for all opportunities
- [ ] Implement interstitial ad system
- [ ] Build frequency capping logic
- [ ] Create ad loading indicators
- [ ] Implement fallback for failed ads
- [ ] Add post-ad "Remove Ads" prompt
- [ ] Build ad analytics tracking
- [ ] Test all rewarded ad scenarios
- [ ] Test interstitial ad timing
- [ ] Test ad removal purchase flow
- [ ] Verify GDPR/CCPA compliance
- [ ] Test with AdMob test IDs
- [ ] Submit for AdMob approval

---

## Success Criteria

✅ Rewarded ads load reliably (>90%)
✅ Ad display is non-intrusive
✅ Interstitials respect frequency caps
✅ Fallback works when ads fail
✅ Benefits granted correctly after ads
✅ "Remove Ads" prompt converts >10%
✅ Ad revenue targets met (eCPM $8-15)
✅ User retention not negatively impacted
✅ Complies with privacy regulations
✅ Passes App Store review
