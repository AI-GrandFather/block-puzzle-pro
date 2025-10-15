// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// This file documents the required Swift Package Manager dependencies for BlockPuzzlePro
// When implementing in a real Xcode project, add these packages through:
// File -> Add Package Dependencies in Xcode

let package = Package(
    name: "BlockPuzzlePro",
    platforms: [
        .iOS(.v17) // Minimum iOS 17.0 as per architecture requirements
    ],
    products: [
        .library(
            name: "BlockPuzzlePro",
            targets: ["BlockPuzzlePro"]
        ),
    ],
    dependencies: [
        // MARK: - AdMob SDK Integration
        // Add this package dependency in Xcode:
        // Repository URL: https://github.com/googleads/swift-package-manager-google-mobile-ads
        // Version: 11.2.0 or later (latest 2025 version)
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads",
            from: "11.2.0"
        ),
    ],
    targets: [
        .target(
            name: "BlockPuzzlePro",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
            ],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BlockPuzzleProTests",
            dependencies: ["BlockPuzzlePro"]
        ),
    ]
)

/*
 SETUP INSTRUCTIONS FOR REAL XCODE PROJECT:
 
 1. Open BlockPuzzlePro.xcodeproj in Xcode
 2. Select the project in the navigator
 3. Go to Package Dependencies tab
 4. Click the + button to add package dependency
 5. Enter URL: https://github.com/googleads/swift-package-manager-google-mobile-ads
 6. Select version 11.2.0 or later
 7. Add GoogleMobileAds to the BlockPuzzlePro target
 
 This will automatically handle:
 - Framework linking
 - Header search paths
 - Required system frameworks (AdSupport, AppTrackingTransparency, etc.)
 - Build settings configuration
 
 The AdMob SDK includes these frameworks automatically:
 - GoogleMobileAds (core ads functionality)
 - GoogleAppMeasurement (analytics)
 - GoogleUserMessagingPlatform (consent management)
 - nanopb (protocol buffers)
 - Other required dependencies
*/