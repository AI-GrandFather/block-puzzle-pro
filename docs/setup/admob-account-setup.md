# AdMob Account Setup Guide

This guide explains how to set up your Google AdMob account and Apple Developer account for the Block Puzzle Pro game's monetization strategy.

## Prerequisites

Before setting up AdMob, you need:

1. **Apple Developer Account** ($99/year)
2. **Google Account** (free)
3. **App Store Connect** access
4. **Completed and tested app** ready for submission

## Setup Timeline

The AdMob integration is **already implemented and tested** in the codebase with comprehensive test coverage. You only need to replace test ad units with production ones when your accounts are ready.

```
Current Status: ✅ COMPLETE - Production Ready with Test Ad Units
Next Step: 🔄 Replace Test IDs → Production IDs (when accounts ready)
```

## Step 1: Apple Developer Account Setup

### 1.1 Create Apple Developer Account
1. Visit [Apple Developer Program](https://developer.apple.com/programs/)
2. Sign up with your Apple ID
3. Pay the annual $99 fee
4. Complete verification process (may take 1-2 business days)

### 1.2 Create App Store Connect Record
1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in app details:
   - **Name**: Block Puzzle Pro
   - **Bundle ID**: `com.yourcompany.blockpuzzlepro` (choose your company domain)
   - **SKU**: `block-puzzle-pro-ios`
   - **Primary Language**: English

### 1.3 Generate App Store Bundle ID
Your Bundle ID will be something like: `com.yourcompany.blockpuzzlepro`

**⚠️ Important**: Save this Bundle ID - you'll need it for AdMob setup!

## Step 2: Google AdMob Account Setup

### 2.1 Create AdMob Account
1. Visit [Google AdMob](https://admob.google.com)
2. Sign in with your Google account
3. Click "Get Started"
4. Choose "Add your first app"

### 2.2 Add Your iOS App
1. Select "iOS" platform
2. Choose "No" for "Is your app already published?"
3. Enter app details:
   - **App name**: Block Puzzle Pro
   - **Bundle ID**: Use the Bundle ID from App Store Connect
   - **Category**: Games → Puzzle

### 2.3 Create Ad Units
You need to create **Rewarded Video** ad units for:

1. **Continue Game Reward**
   - Format: Rewarded
   - Name: "Continue Game"
   - Description: "Watch ad to continue gameplay"

2. **Power-Up Reward** (for future features)
   - Format: Rewarded  
   - Name: "Power-Up Reward"
   - Description: "Watch ad to get power-ups"

### 2.4 Get Your Production Ad Unit IDs
After creating ad units, AdMob will provide:
- **App ID**: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`
- **Rewarded Ad Unit ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`

## Step 3: Update Production Configuration

Once you have your production IDs, update these files:

### 3.1 Update AdMobConfig.swift
```swift
// In BlockPuzzlePro/Core/Services/AdMobConfig.swift
private static let productionAppID = "ca-app-pub-YOUR-ACTUAL-APP-ID"
private static let productionRewardedAdUnitID = "ca-app-pub-YOUR-ACTUAL-AD-UNIT-ID"
```

### 3.2 Update Info.plist
```xml
<!-- In BlockPuzzlePro/Info.plist -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-YOUR-ACTUAL-APP-ID</string>
```

### 3.3 Remove Placeholder Comments
Remove the TODO comments once you've set the production IDs.

## Step 4: Testing Production Setup

### 4.1 Test Production Ads
1. Set build configuration to Release
2. Install on physical device
3. Test ad loading and display
4. Verify ads show properly and rewards work

### 4.2 Validate ATT Compliance
1. Test on iOS 18+ device
2. Verify ATT prompt shows after first gameplay
3. Test both "Allow" and "Don't Allow" scenarios
4. Confirm ads work in both cases

## Step 5: App Store Submission

### 5.1 Prepare App Store Assets
- App icons (multiple sizes)
- Screenshots for all device types
- App description and metadata
- Privacy policy (required for ads)

### 5.2 Submit for Review
1. Upload build to App Store Connect
2. Fill in app information
3. Set pricing (Free with ads)
4. Submit for Apple review

## Current Implementation Status

✅ **COMPLETED (Ready for Production):**
- AdMob SDK integration with Swift Package Manager
- Rewarded video ad implementation
- App Tracking Transparency compliance
- Background ad loading (60fps maintained)
- Comprehensive error handling
- Complete test suite (56 tests)
- Configuration system for dev/production switching

🔄 **PENDING (Requires Your Accounts):**
- Apple Developer account creation
- Google AdMob account setup
- Production ad unit ID replacement
- App Store Connect app creation

## Cost Summary

| Service | Cost | Purpose |
|---------|------|---------|
| Apple Developer | $99/year | Required for App Store |
| Google AdMob | FREE | Ad serving and monetization |
| **Total** | **$99/year** | Complete monetization setup |

## Support and Documentation

- **AdMob Help Center**: https://support.google.com/admob/
- **Apple Developer Support**: https://developer.apple.com/support/
- **App Store Connect Help**: https://help.apple.com/app-store-connect/

## Next Steps Checklist

- [ ] Create Apple Developer account ($99/year)
- [ ] Set up App Store Connect app record
- [ ] Create Google AdMob account (free)
- [ ] Add iOS app to AdMob
- [ ] Create rewarded ad units in AdMob
- [ ] Update production ad unit IDs in code
- [ ] Test production ad configuration
- [ ] Submit app to App Store for review

**Note**: The entire AdMob integration is already implemented and thoroughly tested. You only need to replace test ad unit IDs with production ones when your accounts are ready!