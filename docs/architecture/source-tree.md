# Source Tree Structure

This document defines the canonical source code organization for the Block Game iOS application.

## Project Root Structure

```
BlockGame/
├── BlockGame/                    # Main application target
│   ├── App/                     # App lifecycle and configuration
│   │   ├── BlockGameApp.swift   # App entry point
│   │   ├── AppDelegate.swift    # App delegate if needed
│   │   └── Info.plist          # App configuration
│   │
│   ├── Core/                    # Core game logic and models
│   │   ├── Models/             # Data models
│   │   │   ├── Block.swift     # Block data model
│   │   │   ├── GameBoard.swift # Game board model
│   │   │   ├── GameState.swift # Game state enum
│   │   │   └── Player.swift    # Player data model
│   │   │
│   │   ├── Managers/           # Business logic managers
│   │   │   ├── GameManager.swift     # Main game logic
│   │   │   ├── ScoreManager.swift    # Score calculation
│   │   │   ├── StorageManager.swift  # Data persistence
│   │   │   └── SoundManager.swift    # Audio management
│   │   │
│   │   ├── Services/           # External service integrations
│   │   │   ├── CloudKitService.swift # CloudKit integration
│   │   │   └── NotificationService.swift # Local notifications
│   │   │
│   │   └── Utilities/          # Helper utilities
│   │       ├── Extensions/     # Swift extensions
│   │       │   ├── CGPoint+Extensions.swift
│   │       │   ├── Color+Extensions.swift
│   │       │   └── View+Extensions.swift
│   │       │
│   │       ├── Constants.swift # App-wide constants
│   │       ├── Logger.swift    # Logging utility
│   │       └── Haptics.swift   # Haptic feedback
│   │
│   ├── Features/               # Feature-based organization
│   │   ├── Game/              # Main game feature
│   │   │   ├── Views/         # Game-related views
│   │   │   │   ├── GameView.swift
│   │   │   │   ├── GameBoardView.swift
│   │   │   │   ├── BlockView.swift
│   │   │   │   └── GameHUDView.swift
│   │   │   │
│   │   │   ├── ViewModels/     # Game view models
│   │   │   │   ├── GameViewModel.swift
│   │   │   │   └── BlockViewModel.swift
│   │   │   │
│   │   │   └── Components/     # Reusable game components
│   │   │       ├── ControlButton.swift
│   │   │       └── ScoreDisplay.swift
│   │   │
│   │   ├── Menu/              # Menu and navigation
│   │   │   ├── Views/
│   │   │   │   ├── MainMenuView.swift
│   │   │   │   ├── SettingsView.swift
│   │   │   │   └── AboutView.swift
│   │   │   │
│   │   │   └── ViewModels/
│   │   │       └── MenuViewModel.swift
│   │   │
│   │   ├── Leaderboard/       # Leaderboard feature
│   │   │   ├── Views/
│   │   │   │   └── LeaderboardView.swift
│   │   │   │
│   │   │   └── ViewModels/
│   │   │       └── LeaderboardViewModel.swift
│   │   │
│   │   └── Settings/          # Settings and preferences
│   │       ├── Views/
│   │       │   ├── SettingsView.swift
│   │       │   └── PreferencesView.swift
│   │       │
│   │       └── ViewModels/
│   │           └── SettingsViewModel.swift
│   │
│   ├── Resources/             # Static resources
│   │   ├── Assets.xcassets   # Images and colors
│   │   ├── Sounds/           # Audio files
│   │   │   ├── block_place.wav
│   │   │   ├── line_clear.wav
│   │   │   └── game_over.wav
│   │   │
│   │   └── Localizable.strings # Localization
│   │
│   └── Preview Content/       # SwiftUI preview assets
│       └── Preview Assets.xcassets
│
├── BlockGameTests/            # Unit tests
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── BlockTests.swift
│   │   │   └── GameBoardTests.swift
│   │   │
│   │   └── Managers/
│   │       ├── GameManagerTests.swift
│   │       └── ScoreManagerTests.swift
│   │
│   ├── Features/
│   │   ├── Game/
│   │   │   └── GameViewModelTests.swift
│   │   │
│   │   └── Menu/
│   │       └── MenuViewModelTests.swift
│   │
│   └── Utilities/
│       └── ExtensionTests.swift
│
├── BlockGameUITests/          # UI tests
│   ├── GameFlowTests.swift
│   ├── MenuNavigationTests.swift
│   └── SettingsTests.swift
│
└── Project Files/            # Xcode project files
    ├── BlockGame.xcodeproj/
    ├── BlockGame.xcworkspace/
    └── Package.swift         # Swift Package Manager
```

## Organization Principles

### Feature-Based Architecture
- Each major feature has its own directory under `Features/`
- Features contain their own Views, ViewModels, and Components
- Shared functionality goes in `Core/`

### Model-View-ViewModel (MVVM)
```
Feature/
├── Views/          # SwiftUI views
├── ViewModels/     # ObservableObject classes
└── Components/     # Reusable UI components
```

### Core Layer Separation
```
Core/
├── Models/         # Data structures and business objects
├── Managers/       # Business logic and coordination
├── Services/       # External integrations
└── Utilities/      # Helper functions and extensions
```

## File Naming Conventions

### Swift Files
- **Models**: Singular noun describing the entity (`Block.swift`, `Player.swift`)
- **Views**: Descriptive name + "View" suffix (`GameBoardView.swift`)
- **ViewModels**: Matching view name + "ViewModel" suffix (`GameViewModel.swift`)
- **Managers**: Purpose + "Manager" suffix (`GameManager.swift`)
- **Services**: Purpose + "Service" suffix (`CloudKitService.swift`)
- **Extensions**: Extended type + "Extensions" (`View+Extensions.swift`)

### Test Files
- Unit tests: Original file name + "Tests" suffix (`GameManager.swift` → `GameManagerTests.swift`)
- UI tests: Feature or flow + "Tests" suffix (`GameFlowTests.swift`)

### Resource Files
- Assets: Descriptive names using snake_case (`block_texture.png`)
- Sounds: Action + sound type (`block_place.wav`)

## Import Organization

```swift
// System frameworks first
import SwiftUI
import SwiftData
import CloudKit

// Third-party frameworks (if any)
// import ThirdPartyLibrary

// Internal modules
@testable import BlockGame // Only in tests
```

## Directory Creation Guidelines

### When to Create New Directories
- **New Feature**: Create under `Features/` with Views, ViewModels, Components structure
- **New Model Category**: Create under `Core/Models/` if you have 3+ related models
- **New Service Type**: Create under `Core/Services/` for external integrations
- **Utility Category**: Create under `Core/Utilities/` for related helper functions

### Directory Naming
- Use PascalCase for directories (`GameLogic/`, not `game-logic/`)
- Use descriptive, singular names where possible (`Model/`, not `Models/`)
- Exception: Plural for collections (`Views/`, `Tests/`, `Resources/`)

## Code Organization Within Files

```swift
// MARK: - Imports
import SwiftUI

// MARK: - Type Definition
struct GameView: View {
    
    // MARK: - Properties
    // @StateObject, @ObservedObject first
    @StateObject private var gameManager = GameManager()
    
    // @State properties
    @State private var selectedBlock: Block?
    
    // Computed properties
    private var isGameActive: Bool {
        gameManager.state == .playing
    }
    
    // MARK: - Body
    var body: some View {
        // Main view implementation
    }
    
    // MARK: - View Components
    private var gameBoard: some View {
        // Component implementation
    }
    
    // MARK: - Methods
    private func handleBlockTap(_ block: Block) {
        // Method implementation
    }
}

// MARK: - Preview
#Preview {
    GameView()
}
```

## Testing Structure

### Test File Organization
- Mirror the main source structure in test directories
- One test file per source file
- Group related test methods using `// MARK: -` comments

### Test Method Organization
```swift
// MARK: - Setup/Teardown
override func setUp() { }
override func tearDown() { }

// MARK: - [Feature Being Tested]
func testFeature_Condition_ExpectedResult() { }

// MARK: - Helper Methods (if needed)
private func createMockData() { }
```

## Asset Organization

### Images
```
Assets.xcassets/
├── AppIcon.appiconset/
├── Colors/
│   ├── Primary.colorset/
│   └── Secondary.colorset/
├── Game/
│   ├── block-square.imageset/
│   └── block-L.imageset/
└── UI/
    ├── button-background.imageset/
    └── menu-logo.imageset/
```

### Sounds
```
Sounds/
├── Effects/
│   ├── block_place.wav
│   └── line_clear.wav
└── Music/
    └── background_theme.mp3
```

This source tree structure ensures:
- **Scalability**: Easy to add new features and components
- **Maintainability**: Clear separation of concerns
- **Testability**: Parallel test structure
- **Team Collaboration**: Predictable file locations
- **Build Performance**: Logical dependency relationships