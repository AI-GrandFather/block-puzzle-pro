# External Services Setup Guide

This document provides step-by-step instructions for setting up all external services required for Block Puzzle Pro development and deployment.

## 📱 Apple Developer Program Setup

### Prerequisites
- Apple ID (personal or business)
- Credit card or payment method
- Valid phone number for verification

### Steps
1. **Enroll in Apple Developer Program**
   - Visit [developer.apple.com/programs](https://developer.apple.com/programs/)
   - Click "Enroll" and sign in with your Apple ID
   - Select Individual or Organization enrollment ($99/year)
   - Complete payment and verification process
   - Wait 24-48 hours for approval

2. **Configure Development Certificates**
   - Open Xcode → Preferences → Accounts
   - Add your Apple ID and download development certificates
   - Enable "Automatically manage signing" in project settings

3. **Create App Identifier**
   - Visit [developer.apple.com/account](https://developer.apple.com/account/)
   - Go to Certificates, Identifiers & Profiles
   - Create new App ID: `com.yourcompany.blockpuzzlepro`
   - Enable required capabilities: Game Center, In-App Purchase, CloudKit

4. **Set up App Store Connect**
   - Visit [appstoreconnect.apple.com](https://appstoreconnect.apple.com/)
   - Create new app with same bundle identifier
   - Fill basic app information (name, category, etc.)
   - Set up TestFlight for beta testing

## 📊 AdMob Integration Setup

### Prerequisites  
- Google account
- Apple Developer Program enrollment (above)

### Steps
1. **Create AdMob Account**
   - Visit [admob.google.com](https://admob.google.com/)
   - Sign in with Google account and accept terms
   - Verify identity and payment information
   - Complete tax information (required for payments)

2. **Create iOS App in AdMob**
   - Click "Apps" → "Add App" → "iOS"
   - Select "No" for "Is your app listed on a supported app store?"
   - Enter app name: "Block Puzzle Pro"
   - Add app and note the App ID (ca-app-pub-XXXXXXXX~XXXXXXXXXX)

3. **Create Ad Units**
   - Navigate to your app → "Ad units"
   - Create **Rewarded Video** ad unit for "Continue Game" feature
     - Name: "Continue Game Reward"
     - Note the Ad Unit ID (ca-app-pub-XXXXXXXX/XXXXXXXXXX)
   - Create **Rewarded Video** ad unit for "Power-up Boost" feature
     - Name: "Power-up Reward"  
     - Note the Ad Unit ID (ca-app-pub-XXXXXXXX/XXXXXXXXXX)

4. **Configure Test Devices**
   - Go to Settings → Test devices
   - Add your iOS device IDFA for testing
   - Use test ad unit IDs during development:
     - Test Rewarded Video: `ca-app-pub-3940256099942544/1712485313`

5. **App Tracking Transparency Setup**
   - In AdMob → Privacy & messaging
   - Configure IDFA consent message
   - Set up GDPR compliance if targeting EU users
   - Note: iOS 18.6.2 requires ATT prompt before ad personalization

## ☁️ CloudKit Configuration

### Prerequisites
- Apple Developer Program enrollment
- Xcode project with CloudKit capability enabled

### Steps
1. **Enable CloudKit Capability**
   - In Xcode project → Signing & Capabilities
   - Add CloudKit capability
   - Select "Use Core Data with CloudKit" in your SwiftData model

2. **Configure CloudKit Console**
   - Visit [icloud.developer.apple.com](https://icloud.developer.apple.com/)
   - Select your app container
   - Review auto-generated schema from SwiftData
   - Deploy to Production environment when ready

3. **Test CloudKit Sync**
   - Use two devices with same Apple ID
   - Verify score synchronization works
   - Test conflict resolution scenarios

## 🔐 Credentials Storage

### Development Phase
Store in Xcode project configuration:
```swift
// In Config.swift or Constants.swift
struct AdMobConfig {
    #if DEBUG
    static let appID = "ca-app-pub-3940256099942544~1458002511" // Test App ID
    static let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else  
    static let appID = "YOUR_PRODUCTION_APP_ID"
    static let rewardedAdUnitID = "YOUR_PRODUCTION_REWARDED_UNIT_ID"
    #endif
}
```

### Production Phase
- Store production keys in Xcode build configurations
- Never commit production keys to git repository
- Use Xcode Cloud environment variables for CI/CD

## ⚠️ Important Notes

1. **Timeline**: Allow 3-5 business days for Apple Developer approval
2. **Testing**: Always test with AdMob test IDs before switching to production
3. **Compliance**: Review Apple App Store Guidelines and Google AdMob policies
4. **Revenue Sharing**: AdMob takes 32% of ad revenue, factor into financial projections
5. **Privacy**: Ensure ATT compliance and privacy policy covers data collection

## 📋 Setup Checklist

- [ ] Apple Developer Program enrollment completed
- [ ] Xcode signing certificates configured  
- [ ] App Store Connect app created
- [ ] AdMob account verified and configured
- [ ] Production and test ad units created
- [ ] CloudKit capability enabled and tested
- [ ] ATT compliance message configured
- [ ] Test devices registered for development
- [ ] Privacy policy drafted (required for App Store)

## 🚨 Blockers Resolution

If you encounter issues:

1. **Apple Developer Enrollment Delays**: Contact Apple Developer Support
2. **AdMob Account Verification**: Ensure tax info and identity verification complete
3. **CloudKit Sync Failures**: Check network connectivity and Apple ID signed into device
4. **ATT Prompt Issues**: Verify iOS version 14.5+ and proper Info.plist configuration

---

**Next Steps**: Once all services are configured, proceed with Epic 1.2 (AdMob SDK Integration) and Epic 2.1 (SwiftData + CloudKit setup).