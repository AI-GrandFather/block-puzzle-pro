# External APIs

For this single-player block puzzle game, we have minimal external API requirements:

## AdMob API
- **Purpose:** Rewarded video ads for continue gameplay and power-ups
- **Documentation:** https://developers.google.com/admob/ios
- **Base URL(s):** SDK handles all network calls internally
- **Authentication:** AdMob App ID and Ad Unit IDs 
- **Rate Limits:** Standard AdMob quotas (unlimited for most usage)

**Key Endpoints Used:**
- Rewarded video ad requests (handled by SDK)
- Ad impression tracking (automatic)

**Integration Notes:** AdMob SDK handles all API communication. We only configure App ID and call show/load methods.

## CloudKit API  
- **Purpose:** Cross-device score and settings sync
- **Documentation:** Apple CloudKit documentation
- **Base URL(s):** Automatic (handled by iOS)
- **Authentication:** iCloud account (automatic)
- **Rate Limits:** Apple's generous free tier limits

**Key Endpoints Used:**
- Automatic SwiftData sync (no manual API calls needed)
- Background sync operations

**Integration Notes:** SwiftData + CloudKit integration is automatic. No manual API calls required.

**No other external APIs needed** - keeping it simple as recommended by successful puzzle game patterns.
