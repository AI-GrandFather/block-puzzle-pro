# Feature: In-App Purchases (IAP)

**Priority:** HIGH
**Timeline:** Week 9-10
**Dependencies:** StoreKit 2, progression system, theme system
**Performance Target:** Instant purchase flow, <2s transaction completion

---

## Overview

Implement a comprehensive IAP system with StoreKit 2 for removing ads, unlocking premium content, purchasing power-ups, and buying coins. All purchases are one-time unless specified as subscriptions.

---

## StoreKit 2 Setup

### Product Configuration

```swift
import StoreKit

enum IAPProduct: String, CaseIterable {
    // Remove Ads
    case removeAds = "com.blockpuzzle.removeads"

    // Theme Pack
    case premiumThemes = "com.blockpuzzle.premiumthemes"

    // Level Packs
    case levelPack2 = "com.blockpuzzle.levelpack2"
    case levelPack3 = "com.blockpuzzle.levelpack3"
    case levelPack4 = "com.blockpuzzle.levelpack4"
    case levelPack5 = "com.blockpuzzle.levelpack5"
    case levelPackBundle = "com.blockpuzzle.levelpackbundle"

    // Power-Up Bundles
    case powerUpStarter = "com.blockpuzzle.powerup.starter"
    case powerUpPro = "com.blockpuzzle.powerup.pro"
    case powerUpUltimate = "com.blockpuzzle.powerup.ultimate"

    // Coin Packs
    case coinsHandful = "com.blockpuzzle.coins.handful"
    case coinsBag = "com.blockpuzzle.coins.bag"
    case coinsChest = "com.blockpuzzle.coins.chest"
    case coinsVault = "com.blockpuzzle.coins.vault"

    var displayName: String {
        switch self {
        case .removeAds: return "Remove Ads"
        case .premiumThemes: return "Premium Theme Pack"
        case .levelPack2: return "Level Pack 2"
        case .levelPack3: return "Level Pack 3"
        case .levelPack4: return "Level Pack 4"
        case .levelPack5: return "Level Pack 5"
        case .levelPackBundle: return "Complete Level Bundle"
        case .powerUpStarter: return "Starter Power-Up Pack"
        case .powerUpPro: return "Pro Power-Up Pack"
        case .powerUpUltimate: return "Ultimate Power-Up Pack"
        case .coinsHandful: return "Handful of Coins"
        case .coinsBag: return "Bag of Coins"
        case .coinsChest: return "Chest of Coins"
        case .coinsVault: return "Vault of Coins"
        }
    }
}
```

---

## Store Manager Implementation

```swift
@Observable
class StoreManager {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []

    var hasRemovedAds: Bool {
        purchasedProductIDs.contains(IAPProduct.removeAds.rawValue)
    }

    var hasPremiumThemes: Bool {
        purchasedProductIDs.contains(IAPProduct.premiumThemes.rawValue)
    }

    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
            await observeTransactions()
        }
    }

    @MainActor
    func loadProducts() async {
        do {
            products = try await Product.products(for: IAPProduct.allCases.map { $0.rawValue })
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    @MainActor
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }

            if transaction.revocationDate == nil {
                purchasedProductIDs.insert(transaction.productID)
            } else {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw StoreError.failedVerification
            }

            await transaction.finish()
            await updatePurchasedProducts()

            // Grant purchase benefits
            await grantPurchaseBenefits(for: transaction.productID)

            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    func observeTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }

            await transaction.finish()
            await updatePurchasedProducts()
            await grantPurchaseBenefits(for: transaction.productID)
        }
    }

    private func grantPurchaseBenefits(for productID: String) async {
        guard let product = IAPProduct(rawValue: productID) else { return }

        switch product {
        case .removeAds:
            // Disable all ads
            UserDefaults.standard.set(true, forKey: "adsRemoved")

        case .premiumThemes:
            // Unlock all themes
            ThemeManager.shared.unlockAllThemes()

        case .levelPack2, .levelPack3, .levelPack4, .levelPack5, .levelPackBundle:
            // Unlock level packs
            LevelManager.shared.unlockPack(for: product)

        case .powerUpStarter:
            PowerUpManager.shared.grant(undo: 5, rotation: 5, bomb: 5)

        case .powerUpPro:
            PowerUpManager.shared.grant(undo: 15, rotation: 15, bomb: 15)

        case .powerUpUltimate:
            PowerUpManager.shared.grant(undo: 40, rotation: 40, bomb: 40)

        case .coinsHandful:
            CoinManager.shared.addCoins(100, source: .iap)

        case .coinsBag:
            CoinManager.shared.addCoins(350, source: .iap)

        case .coinsChest:
            CoinManager.shared.addCoins(750, source: .iap)

        case .coinsVault:
            CoinManager.shared.addCoins(2000, source: .iap)
        }
    }
}

enum StoreError: Error {
    case failedVerification
    case productNotFound
    case purchaseFailed
}
```

---

## Product Details

### 1. Remove Ads ($4.99 one-time)

**Benefits:**
- Removes all interstitial ads permanently
- Removes all banner ads from menus
- Keeps rewarded ad option (player choice)
- Adds "Ad-Free" badge to profile
- Most popular purchase

**Store Listing:**
```
Title: Remove Ads Forever
Price: $4.99
Description:
"Enjoy uninterrupted gameplay! Remove all ads permanently while keeping the option to watch rewarded ads for bonuses."

Features:
• No more interstitial ads
• Clean, ad-free menus
• Keep rewarded ad bonuses
• One-time purchase
• Exclusive "Ad-Free" badge
```

---

### 2. Premium Theme Pack ($2.99)

**Benefits:**
- Unlocks all current themes immediately (7 themes)
- Includes all future themes automatically
- Exclusive "Theme Collector" badge
- Theme preview feature

**Store Listing:**
```
Title: Premium Theme Pack
Price: $2.99
Description:
"Unlock all beautiful themes instantly! Get immediate access to all 7 stunning themes plus any future themes we release."

Includes:
• Dark Mode
• Neon Cyberpunk
• Wooden Classic
• Crystal Ice
• Sunset Beach
• Space Odyssey
• All future themes FREE
• Exclusive badge
```

---

### 3. Level Pack Bundles

**Individual Packs:**
- **Level Pack 2** (Levels 11-20): $2.99 or unlock via progression
- **Level Pack 3** (Levels 21-30): $2.99 or unlock via progression
- **Level Pack 4** (Levels 31-40): $4.99 or unlock via progression
- **Level Pack 5** (Levels 41-50): $4.99 or unlock via progression

**Complete Bundle:** All level packs for $9.99 (save $2.97)

**Store Listing (Bundle):**
```
Title: Complete Level Bundle
Price: $9.99 (SAVE 25%)
Description:
"Get all 40 bonus levels at once! Skip the grind and enjoy the complete campaign immediately."

Includes:
• Level Pack 2 (Levels 11-20)
• Level Pack 3 (Levels 21-30)
• Level Pack 4 (Levels 31-40)
• Level Pack 5 (Levels 41-50)
• 40 challenging levels
• Save $2.97 vs buying individually
```

---

### 4. Power-Up Bundles

**Starter Bundle ($1.99):**
- 5 Undo power-ups
- 5 Rotation power-ups
- 5 Bomb power-ups
- Total: 15 power-ups

**Pro Bundle ($4.99):**
- 15 Undo power-ups
- 15 Rotation power-ups
- 15 Bomb power-ups
- Total: 45 power-ups
- **BEST VALUE per power-up**

**Ultimate Bundle ($9.99):**
- 40 Undo power-ups
- 40 Rotation power-ups
- 40 Bomb power-ups
- Total: 120 power-ups
- Save 50% vs Starter

**Store Listing (Pro Bundle):**
```
Title: Pro Power-Up Pack
Price: $4.99 (BEST VALUE)
Description:
"Master tough levels with powerful tools! Get 45 power-ups to overcome any challenge."

Includes:
• 15 Undo moves
• 15 Piece rotations
• 15 Bombs (clear any block)
• Never expires
• Best value per power-up
```

---

### 5. Coin Packs

**Pricing & Value:**
- **Handful:** $0.99 = 100 coins (1.00 coins/cent)
- **Bag:** $2.99 = 350 coins (1.17 coins/cent) +17%
- **Chest:** $4.99 = 750 coins (1.50 coins/cent) +50%
- **Vault:** $9.99 = 2000 coins (2.00 coins/cent) +100% **BEST VALUE**

**Store Listing (Vault):**
```
Title: Vault of Coins
Price: $9.99 (BEST VALUE)
Description:
"Stock up on coins! Get 2000 coins to unlock themes, buy hints, and continue games."

Includes:
• 2000 coins
• Double value vs Handful
• Never expires
• Use for hints, continues, unlocks
• Most popular coin pack
```

---

## Store UI

### In-Game Store Screen

```
┌─────────────────────────────────┐
│   💎 Store                      │
│                                 │
│   [Most Popular] [Themes] [...]│
│                                 │
│   🔥 MOST POPULAR               │
│   ┌───────────────────────────┐ │
│   │ Remove Ads Forever        │ │
│   │ No more interruptions!    │ │
│   │ $4.99  [BUY NOW]          │ │
│   └───────────────────────────┘ │
│                                 │
│   🎨 Themes                     │
│   ┌───────────────────────────┐ │
│   │ Premium Theme Pack        │ │
│   │ All themes + future ones  │ │
│   │ $2.99  [BUY NOW]          │ │
│   └───────────────────────────┘ │
│                                 │
│   ⚡ Power-Ups                  │
│   ┌───────────────────────────┐ │
│   │ Pro Bundle  [BEST VALUE]  │ │
│   │ 45 power-ups total        │ │
│   │ $4.99  [BUY NOW]          │ │
│   └───────────────────────────┘ │
│                                 │
│   💰 Coins                      │
│   ┌───────────────────────────┐ │
│   │ Vault  [BEST VALUE]       │ │
│   │ 2000 coins (2x bonus!)    │ │
│   │ $9.99  [BUY NOW]          │ │
│   └───────────────────────────┘ │
│                                 │
│   [Restore Purchases]           │
└─────────────────────────────────┘
```

### Product Detail Sheet

```
┌─────────────────────────────────┐
│   Remove Ads Forever            │
│                                 │
│   [Preview Image/Icon]          │
│                                 │
│   Enjoy uninterrupted gameplay! │
│   Remove all ads permanently.   │
│                                 │
│   ✓ No interstitial ads         │
│   ✓ Clean, ad-free menus        │
│   ✓ Keep rewarded ad bonuses    │
│   ✓ One-time purchase           │
│   ✓ "Ad-Free" profile badge     │
│                                 │
│   Current Balance: 💰 1,250     │
│                                 │
│   ┌───────────────────────────┐ │
│   │   BUY NOW - $4.99         │ │
│   └───────────────────────────┘ │
│                                 │
│   [ CANCEL ]                    │
└─────────────────────────────────┘
```

---

## Purchase Flow

### Purchase Sequence

```swift
struct PurchaseFlow: View {
    @Environment(StoreManager.self) var store
    @State private var isPurchasing = false
    @State private var purchaseResult: PurchaseResult?

    let product: Product

    var body: some View {
        VStack {
            // Product details
            ProductDetailView(product: product)

            Button("Buy Now - \(product.displayPrice)") {
                Task {
                    await purchase()
                }
            }
            .disabled(isPurchasing)
            .overlay {
                if isPurchasing {
                    ProgressView()
                }
            }
        }
        .alert(item: $purchaseResult) { result in
            Alert(
                title: Text(result.title),
                message: Text(result.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func purchase() async {
        isPurchasing = true

        do {
            if let transaction = try await store.purchase(product) {
                purchaseResult = PurchaseResult.success(product: product)

                // Celebrate purchase
                celebratePurchase(product)
            }
        } catch {
            purchaseResult = PurchaseResult.failure(error: error)
        }

        isPurchasing = false
    }
}

enum PurchaseResult: Identifiable {
    case success(product: Product)
    case failure(error: Error)

    var id: String {
        switch self {
        case .success(let product): return "success_\(product.id)"
        case .failure(let error): return "failure_\(error.localizedDescription)"
        }
    }

    var title: String {
        switch self {
        case .success: return "Purchase Successful! 🎉"
        case .failure: return "Purchase Failed"
        }
    }

    var message: String {
        switch self {
        case .success(let product):
            return "\(product.displayName) has been added to your account!"
        case .failure(let error):
            return error.localizedDescription
        }
    }
}
```

### Purchase Celebration

```swift
func celebratePurchase(_ product: Product) {
    // 1. Confetti animation
    emitConfetti(count: 100, duration: 2.0)

    // 2. Success haptic
    triggerHaptic(.success)

    // 3. Success sound
    playSound(.purchaseSuccess)

    // 4. Show success banner
    showBanner(
        title: "Thank You! 🎉",
        message: "\(product.displayName) unlocked!",
        duration: 3.0
    )

    // 5. Immediately grant benefits
    // (Already handled in grantPurchaseBenefits)
}
```

---

## Restore Purchases

```swift
extension StoreManager {
    @MainActor
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()

        // Show confirmation
        showBanner(
            title: "Purchases Restored",
            message: "All purchases have been restored to your account.",
            duration: 2.0
        )
    }
}
```

**Restore Button:**
- Always visible at bottom of store
- Required by App Store Review Guidelines
- Shows confirmation message after restore

---

## Special Offers

### Time-Limited Offers

```swift
struct SpecialOffer {
    let product: IAPProduct
    let discountPercent: Int
    let originalPrice: Decimal
    let salePrice: Decimal
    let expiresAt: Date
    let reason: OfferReason

    enum OfferReason {
        case firstLaunch        // 50% off first 24 hours
        case weekendDeal        // Weekend specials
        case holidayPromo       // Holiday sales
        case levelMilestone     // Reached level 25
    }

    var isActive: Bool {
        return Date() < expiresAt
    }

    var timeRemaining: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
}
```

**Offer Examples:**
- **Starter Pack:** First 24 hours, everything 50% off
- **Weekend Deals:** Rotating special bundles Fri-Sun
- **Holiday Bundles:** Themed bundles for holidays
- **Level Milestone Offers:** Reach level 25, get special offer

**Offer Display:**
```
┌─────────────────────────────────┐
│   🔥 LIMITED TIME OFFER          │
│   First Day Special!            │
│                                 │
│   Remove Ads                    │
│   ~~$4.99~~ → $2.49 (50% OFF)   │
│                                 │
│   ⏰ Expires in: 18h 23m         │
│                                 │
│   [  CLAIM OFFER NOW  ]         │
└─────────────────────────────────┘
```

---

## Implementation Checklist

- [ ] Configure products in App Store Connect
- [ ] Implement StoreManager with StoreKit 2
- [ ] Build product loading system
- [ ] Create purchase flow UI
- [ ] Implement transaction verification
- [ ] Build benefits granting system
- [ ] Create Store screen UI
- [ ] Implement product detail sheets
- [ ] Add purchase celebration animations
- [ ] Build restore purchases functionality
- [ ] Implement special offers system
- [ ] Add purchase analytics tracking
- [ ] Test all purchase scenarios
- [ ] Test restore on multiple devices
- [ ] Test Family Sharing (if supported)
- [ ] Submit for App Store review

---

## Success Criteria

✅ All products load correctly from App Store
✅ Purchase flow completes in <2 seconds
✅ Benefits granted immediately after purchase
✅ Transactions verified properly
✅ Restore purchases works correctly
✅ Store UI is clear and attractive
✅ Special offers display correctly
✅ Analytics track all purchases
✅ Family Sharing works (if enabled)
✅ Passes App Store review
✅ Conversion rate >3%
