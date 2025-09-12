# Production Configuration Checklist

## When Apple Developer Account & AdMob Account Are Ready

### Files to Update with Production IDs

#### 1. AdMobConfig.swift
**Location**: `BlockPuzzlePro/Core/Services/AdMobConfig.swift`

**Current (Test IDs)**:
```swift
private static let productionAppID = "REPLACE_WITH_ADMOB_APP_ID_FROM_GOOGLE_ADMOB_CONSOLE"
private static let productionRewardedAdUnitID = "REPLACE_WITH_REWARDED_AD_UNIT_ID_FROM_GOOGLE_ADMOB_CONSOLE"
```

**Update to (Your Production IDs)**:
```swift
private static let productionAppID = "ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"
private static let productionRewardedAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
```

#### 2. Info.plist
**Location**: `BlockPuzzlePro/Info.plist`

**Current (Test ID)**:
```xml
<!-- TODO: Replace with production AdMob App ID when Apple Developer account is ready -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

**Update to (Your Production ID)**:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

### Account Setup Order

1. **Apple Developer Account** ($99/year)
   - Create Bundle ID: `com.yourcompany.blockpuzzlepro`
   - Set up App Store Connect record

2. **Google AdMob Account** (Free)
   - Add iOS app with your Bundle ID
   - Create "Rewarded Video" ad unit
   - Get App ID and Ad Unit ID

3. **Update Code**
   - Replace placeholders in AdMobConfig.swift
   - Update Info.plist GADApplicationIdentifier
   - Remove TODO comments

4. **Test & Deploy**
   - Test production ads on device
   - Validate ATT compliance
   - Submit to App Store

### Current Status
✅ **All AdMob integration code complete with 56 tests**  
🔄 **Only production ID replacement needed when accounts ready**