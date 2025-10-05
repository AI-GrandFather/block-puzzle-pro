# Feature: Premium Subscription Pass

**Priority:** HIGH
**Timeline:** Week 9-10
**Dependencies:** StoreKit 2, progression system, all game modes
**Performance Target:** Instant subscription verification, seamless benefits

---

## Overview

Implement a premium subscription service ($4.99/month or $39.99/year) that provides ad-free experience, doubled XP, unlocked content, and exclusive features for dedicated players.

---

## Subscription Tiers

### Monthly Subscription: $4.99/month
- Try it out option
- Cancel anytime
- All premium benefits
- Auto-renews monthly

### Annual Subscription: $39.99/year
- **BEST VALUE** - Save 33%
- Just $3.33/month
- All premium benefits
- Auto-renews yearly

### Lifetime: $19.99 one-time (Limited Offer)
- First 10,000 users only
- One-time payment
- Forever premium
- Never pay again
- Best value long-term

---

## Premium Benefits

```swift
struct PremiumBenefits {
    // Core Benefits
    let removeAllAds: Bool = true
    let unlimitedTimedModes: Bool = true
    let allLevelPacksUnlocked: Bool = true
    let allThemesUnlocked: Bool = true

    // Exclusive Features
    let exclusivePremiumThemes: Int = 2
    let doubleXPEarnings: Bool = true
    let earlyAccessToFeatures: Bool = true // 1 week early
    let premiumBadge: Bool = true
    let prioritySupport: Bool = true

    // Monthly Bonuses
    let monthlyCoinAllowance: Int = 500

    // Advanced Features
    let cloudSavePriority: Bool = true
    let premiumDailyChallenges: Bool = true
    let exclusiveWeeklyEvents: Bool = true
    let adFreeExperience: Bool = true // Including family sharing

    // Perks
    let familySharing: Bool = true // Up to 5 devices

    var totalMonthlyValue: Decimal {
        // Calculate equivalent value
        // Remove Ads: $4.99
        // Theme Pack: $2.99
        // Level Packs: $14.96 total
        // Coin value: $2.99 (500 coins)
        // Total: $25.93 value for $4.99!
        return 25.93
    }
}
```

---

## StoreKit 2 Subscription Implementation

```swift
import StoreKit

extension IAPProduct {
    // Subscription products
    static let premiumMonthly = "com.blockpuzzle.premium.monthly"
    static let premiumAnnual = "com.blockpuzzle.premium.annual"
    static let premiumLifetime = "com.blockpuzzle.premium.lifetime"
}

@Observable
class SubscriptionManager {
    private(set) var isPremium: Bool = false
    private(set) var subscriptionStatus: SubscriptionStatus?
    private(set) var renewalDate: Date?

    init() {
        Task {
            await updateSubscriptionStatus()
            await observeSubscriptionChanges()
        }
    }

    @MainActor
    func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            // Check if it's a premium subscription
            if [IAPProduct.premiumMonthly,
                IAPProduct.premiumAnnual,
                IAPProduct.premiumLifetime].contains(transaction.productID) {

                if transaction.revocationDate == nil {
                    isPremium = true
                    renewalDate = transaction.expirationDate
                    subscriptionStatus = .active
                    return
                }
            }
        }

        isPremium = false
        subscriptionStatus = .inactive
    }

    func subscribe(to product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw StoreError.failedVerification
            }

            await transaction.finish()
            await updateSubscriptionStatus()
            await activatePremiumBenefits()

            return transaction

        case .userCancelled, .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    private func activatePremiumBenefits() async {
        // Remove all ads
        UserDefaults.standard.set(true, forKey: "adsRemoved")

        // Unlock all themes
        ThemeManager.shared.unlockAllThemes()

        // Unlock all level packs
        LevelManager.shared.unlockAllPacks()

        // Grant monthly coins
        CoinManager.shared.addCoins(500, source: .premiumAllowance)

        // Enable premium badge
        UserDefaults.standard.set(true, forKey: "premiumBadge")

        // Sync to cloud
        CloudSyncManager.shared.syncPremiumStatus()
    }

    func observeSubscriptionChanges() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            await transaction.finish()
            await updateSubscriptionStatus()

            // Handle subscription renewal or cancellation
            if let expirationDate = transaction.expirationDate {
                if expirationDate < Date() {
                    // Subscription expired
                    await deactivatePremiumBenefits()
                }
            }
        }
    }

    private func deactivatePremiumBenefits() async {
        // Note: Don't remove unlocked content, but disable premium features
        isPremium = false
        subscriptionStatus = .expired

        // Disable double XP
        // Re-enable ads (if user hasn't purchased Remove Ads separately)
        if !StoreManager.shared.purchasedProductIDs.contains(IAPProduct.removeAds.rawValue) {
            UserDefaults.standard.set(false, forKey: "adsRemoved")
        }

        // Show resubscribe prompt
        showResubscribePrompt()
    }
}

enum SubscriptionStatus {
    case active
    case inactive
    case expired
    case inGracePeriod
    case inBillingRetry
}
```

---

## Premium UI

### Subscription Offer Screen

```
┌─────────────────────────────────┐
│   ✨ Go Premium!                │
│                                 │
│   Unlock the ultimate           │
│   Block Puzzle experience       │
│                                 │
│   ✓ Remove all ads forever      │
│   ✓ 2x XP on everything         │
│   ✓ All themes unlocked         │
│   ✓ All level packs unlocked    │
│   ✓ 500 coins every month       │
│   ✓ Exclusive premium themes    │
│   ✓ Early access to features    │
│   ✓ Priority support            │
│   ✓ Premium badge & profile     │
│                                 │
│   [  Monthly: $4.99/month  ]    │
│                                 │
│   [  Annual: $39.99/year  ]     │
│   💰 SAVE 33% - BEST VALUE      │
│                                 │
│   [  Lifetime: $19.99  ]        │
│   🔥 LIMITED TIME OFFER         │
│                                 │
│   7-Day Free Trial              │
│   Cancel anytime, no commitment │
│                                 │
│   [ Restore Purchases ]         │
│   [ Maybe Later ]               │
└─────────────────────────────────┘
```

### Premium Badge Display

```
Profile View:
┌─────────────────────────────────┐
│   [Avatar with Gold Border]     │
│                                 │
│   PlayerName  👑 PREMIUM         │
│   Level 47                      │
│                                 │
│   Member since: Jan 2025        │
│   Subscription: Annual          │
│   Renews: Dec 15, 2025          │
└─────────────────────────────────┘
```

---

## Free Trial Implementation

```swift
extension SubscriptionManager {
    var isEligibleForFreeTrial: Bool {
        // Check if user has never subscribed before
        let hasSubscribed = UserDefaults.standard.bool(forKey: "hasEverSubscribed")
        return !hasSubscribed
    }

    func startFreeTrial() async throws {
        // StoreKit 2 automatically handles free trials
        // configured in App Store Connect

        guard isEligibleForFreeTrial else {
            throw SubscriptionError.notEligibleForTrial
        }

        // Subscribe to product (with trial)
        // Trial period handled automatically by App Store
    }

    func showTrialReminder(daysLeft: Int) {
        // Show reminder 24 hours before trial ends
        if daysLeft == 1 {
            showBanner(
                title: "Trial Ending Soon",
                message: "Your 7-day free trial ends tomorrow. Subscribe to keep premium benefits!",
                action: "Subscribe Now"
            )
        }
    }
}

enum SubscriptionError: Error {
    case notEligibleForTrial
    case subscriptionExpired
    case renewalFailed
}
```

---

## Subscription Management

### Manage Subscription Screen

```
┌─────────────────────────────────┐
│   Manage Subscription           │
│                                 │
│   Status: ✅ Active             │
│   Plan: Annual Premium          │
│   Price: $39.99/year            │
│                                 │
│   Next Billing: Dec 15, 2025    │
│   Amount: $39.99                │
│                                 │
│   Active Benefits:              │
│   ✓ Ad-free experience          │
│   ✓ 2x XP earnings              │
│   ✓ All themes unlocked         │
│   ✓ All levels unlocked         │
│   ✓ 500 monthly coins           │
│   ✓ Premium badge               │
│                                 │
│   [ Upgrade to Lifetime ]       │
│   [ Change Plan ]               │
│   [ Cancel Subscription ]       │
│                                 │
│   Questions? Premium Support    │
│   [ Contact Support ]           │
└─────────────────────────────────┘
```

### Cancel Flow

```
┌─────────────────────────────────┐
│   Cancel Subscription?          │
│                                 │
│   We'd hate to see you go! 😢   │
│                                 │
│   You'll lose:                  │
│   • Ad-free experience          │
│   • 2x XP earnings              │
│   • Monthly 500 coins           │
│   • Exclusive themes            │
│   • Priority support            │
│                                 │
│   Your subscription remains     │
│   active until: Dec 15, 2025    │
│                                 │
│   Special Offer:                │
│   Get 50% off next month if     │
│   you stay subscribed!          │
│                                 │
│   [ Keep Subscription (50% OFF)]│
│   [ Cancel Anyway ]             │
│   [ Never Mind ]                │
└─────────────────────────────────┘
```

---

## Auto-Renewal & Notifications

```swift
extension SubscriptionManager {
    func scheduleRenewalReminder() {
        guard let renewalDate = renewalDate else { return }

        // Schedule notification 24 hours before renewal
        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: renewalDate
        )!

        let content = UNMutableNotificationContent()
        content.title = "Subscription Renewing Soon"
        content.body = "Your Premium subscription renews tomorrow for $39.99."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour],
                                                         from: reminderDate),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "subscription_renewal",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func handleRenewalFailure() {
        // Billing retry period (16 days for subscriptions)
        subscriptionStatus = .inBillingRetry

        showAlert(
            title: "Renewal Failed",
            message: "We couldn't process your payment. Please update your payment method to continue Premium benefits."
        )
    }
}
```

---

## Family Sharing Support

```swift
extension SubscriptionManager {
    var supportsFamilySharing: Bool {
        // Configure in App Store Connect
        return true
    }

    func checkFamilySharingStatus() {
        // StoreKit 2 automatically handles family sharing
        // Premium benefits extend to all family members (up to 5)
    }
}
```

**Family Sharing Benefits:**
- Primary subscriber's benefits extend to family
- Ad-free on all family devices
- Shared premium themes and levels
- Individual progression/stats (not shared)
- Max 5 family members

---

## Premium Exclusive Features

### Exclusive Premium Themes (2)

1. **Cosmic Void** - Animated black hole theme with gravity particles
2. **Liquid Metal** - Futuristic mercury-like flowing blocks

### Premium Daily Challenges

```
┌─────────────────────────────────┐
│   👑 Premium Daily Challenge    │
│                                 │
│   "Elite Puzzle"                │
│   Difficulty: Expert            │
│                                 │
│   Exclusive to Premium members  │
│   Higher rewards: 500 XP        │
│   + 300 Bonus Coins             │
│                                 │
│   [ PLAY NOW ]                  │
└─────────────────────────────────┘
```

### Early Access (1 Week Before Free Users)

- New themes
- New game modes
- New features
- Beta access

---

## Conversion Strategy

### Premium Prompt Triggers

```swift
enum PremiumPromptTrigger {
    case levelComplete(level: Int)
    case highScoreAchieved
    case adShown(count: Int)
    case featureAttempt(feature: String) // Locked feature
    case dailyLogin(streak: Int)
}

class PremiumPromptManager {
    func shouldShowPrompt(for trigger: PremiumPromptTrigger) -> Bool {
        switch trigger {
        case .levelComplete(let level):
            return level == 10 || level == 25 || level == 50

        case .highScoreAchieved:
            return true // Always show after new high score

        case .adShown(let count):
            return count % 5 == 0 // Every 5th ad

        case .featureAttempt:
            return true // Always show when attempting locked feature

        case .dailyLogin(let streak):
            return streak == 7 || streak == 30
        }
    }
}
```

### Social Proof

```
┌─────────────────────────────────┐
│   Join 50,000+ Premium Members! │
│                                 │
│   ⭐⭐⭐⭐⭐ 4.9/5 Rating        │
│                                 │
│   "Best mobile game subscription│
│    I've ever had!" - Sarah M.   │
│                                 │
│   "Worth every penny for ad-free│
│    experience." - Mike T.       │
│                                 │
│   [ TRY 7 DAYS FREE ]           │
└─────────────────────────────────┘
```

---

## Implementation Checklist

- [ ] Configure subscription products in App Store Connect
- [ ] Set up auto-renewable subscription terms
- [ ] Implement SubscriptionManager with StoreKit 2
- [ ] Build subscription status checking
- [ ] Create subscription offer UI
- [ ] Implement free trial system
- [ ] Build manage subscription screen
- [ ] Implement cancel flow with retention offer
- [ ] Set up auto-renewal notifications
- [ ] Enable Family Sharing
- [ ] Create premium exclusive themes
- [ ] Build premium daily challenges
- [ ] Implement early access system
- [ ] Create premium badge display
- [ ] Build conversion prompt system
- [ ] Add social proof testimonials
- [ ] Test subscription lifecycle
- [ ] Test billing retry and grace period
- [ ] Test Family Sharing
- [ ] Submit for App Store review

---

## Success Criteria

✅ Subscription purchase flow <3 seconds
✅ Free trial activates correctly
✅ Premium benefits granted immediately
✅ Subscription status syncs accurately
✅ Auto-renewal works correctly
✅ Family Sharing functions properly
✅ Cancel flow retains >30% of cancelers
✅ Premium conversion rate >2%
✅ Renewal rate >70% month-to-month
✅ Customer satisfaction >4.5/5
✅ Passes App Store review
