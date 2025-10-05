# Feature: Save State & Cloud Sync

**Priority:** HIGH
**Timeline:** Week 11-12
**Dependencies:** iCloud entitlement, all game modes

---

## Automatic Save System

### Local Save

**Auto-Save Frequency:**
- Every move in active game
- Every 30 seconds during idle
- On app backgrounding
- On app termination
- After significant events (level up, purchase, etc.)

**Save Data Structure:**

```swift
struct GameSaveData: Codable {
    // Active Game State
    var currentGridState: GridState?
    var availablePieces: [Piece]
    var heldPiece: Piece?
    var currentScore: Int
    var moveHistory: [Move] // For undo
    var gameMode: GameMode
    var timeElapsed: TimeInterval

    // Progression Data
    var playerLevel: Int
    var currentXP: Int
    var coinBalance: Int
    var unlockedThemes: [ThemeID]
    var levelProgress: [Int: LevelProgress]
    var achievements: [String: AchievementProgress]
    var statistics: PlayerStatistics

    // Settings
    var selectedTheme: ThemeID
    var audioEnabled: Bool
    var hapticEnabled: Bool

    // Timestamps
    var lastSaved: Date
    var lastPlayed: Date
}
```

### Save Implementation

```swift
class SaveManager {
    func save() {
        let data = GameSaveData.current

        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: "gameSave")

            // Trigger cloud sync
            CloudSyncManager.shared.uploadSaveData(data)
        } catch {
            print("Save failed: \(error)")
        }
    }

    func load() -> GameSaveData? {
        guard let data = UserDefaults.standard.data(forKey: "gameSave") else {
            return nil
        }

        return try? JSONDecoder().decode(GameSaveData.self, from: data)
    }
}
```

---

## iCloud Sync

### CloudKit Setup

**Synced Data:**
- Player level & XP
- Coin balance
- Unlocked themes & content
- Level progress & stars
- High scores (all modes)
- Achievement progress
- Statistics
- Power-up counts
- Premium subscription status

**Not Synced:**
- Active game state (local only)
- Settings (device-specific)
- Cache data

### Sync Implementation

```swift
class CloudSyncManager {
    func uploadSaveData(_ data: GameSaveData) async {
        guard let ubiquityContainer = FileManager.default.ubiquityIdentityToken else {
            print("iCloud not available")
            return
        }

        // Upload to iCloud
        let record = CKRecord(recordType: "PlayerData")
        record["playerLevel"] = data.playerLevel
        record["xp"] = data.currentXP
        record["coins"] = data.coinBalance
        // ... set other fields

        do {
            try await CKContainer.default().publicCloudDatabase.save(record)
            print("Synced to iCloud")
        } catch {
            print("Sync failed: \(error)")
        }
    }

    func downloadSaveData() async -> GameSaveData? {
        // Download from iCloud
        // Merge with local data
    }
}
```

### Conflict Resolution

**Merge Strategy:**
- Most recent data wins for timestamps
- Highest value wins for progression (level, XP, coins)
- Union for unlocks (combine both sets)
- User choice for major conflicts

```swift
func resolveConflict(local: GameSaveData, cloud: GameSaveData) -> GameSaveData {
    var merged = GameSaveData()

    // Take highest progression
    merged.playerLevel = max(local.playerLevel, cloud.playerLevel)
    merged.currentXP = max(local.currentXP, cloud.currentXP)
    merged.coinBalance = max(local.coinBalance, cloud.coinBalance)

    // Combine unlocks
    merged.unlockedThemes = Set(local.unlockedThemes).union(cloud.unlockedThemes).sorted()

    // Most recent for timestamps
    merged.lastPlayed = max(local.lastPlayed, cloud.lastPlayed)

    return merged
}
```

---

## Restore from iCloud

**New Device Setup:**
1. User signs in with Apple ID
2. App detects iCloud account
3. Prompt: "Restore progress from iCloud?"
4. Download and restore data
5. Show summary of restored progress

**Manual Sync:**
- Settings → iCloud Sync → Sync Now
- Shows last sync time
- Manual trigger available

---

## Local Backup

**Automatic Backups:**
- Daily backup created at midnight
- Keep last 7 days of backups
- Stored locally, not synced to iCloud

**Manual Export/Import:**
- Export save file to Files app
- Import save file from Files app
- Use for device transfer without iCloud

---

## Success Criteria

✅ Auto-save works reliably (no progress loss)
✅ iCloud sync completes within 5 seconds
✅ Conflict resolution merges data correctly
✅ New device restore works seamlessly
✅ Manual backup/restore functions properly
✅ No data corruption or loss
