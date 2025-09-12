# Components

Based on the architectural patterns and tech stack, here are the major logical components:

## GameEngine Component
**Responsibility:** Core puzzle game logic - grid management, block placement validation, line clearing mechanics

**Key Interfaces:**
- `placeBlock(blockType, position) -> PlacementResult`  
- `checkForCompletedLines() -> [LineType]`
- `clearLines([LineType]) -> Int`

**Dependencies:** BlockFactory (for block validation), ScoreTracker (for scoring)

**Technology Stack:** Swift 6.1 Actor, SpriteKit for grid rendering

## ScoreTracker Component  
**Responsibility:** Score calculation, milestone tracking, high score persistence

**Key Interfaces:**
- `addPoints(Int) -> Void`
- `getCurrentScore() -> Int`
- `checkMilestone() -> Milestone?`

**Dependencies:** SwiftData for persistence, CloudKit for sync

**Technology Stack:** Swift 6.1 Actor, SwiftData local storage

## BlockFactory Component
**Responsibility:** Generate and manage available block types based on player progression

**Key Interfaces:**
- `generateNextBlocks() -> [BlockType]`
- `getAvailableBlocks() -> [BlockType]`

**Dependencies:** GameSettings (for unlocked blocks)

**Technology Stack:** Swift 6.1 Actor, in-memory caching

## GameView Component  
**Responsibility:** SwiftUI interface rendering, touch input handling, game state display

**Key Interfaces:**
- SwiftUI view rendering
- Touch gesture recognition
- Real-time score updates

**Dependencies:** All game actors for state management

**Technology Stack:** SwiftUI, SpriteKit integration

## AdManager Component
**Responsibility:** AdMob integration wrapper, rewarded video management

**Key Interfaces:**  
- `loadRewardedAd() -> Bool`
- `showContinueAd() -> Bool`
- `showPowerUpAd() -> Bool`

**Dependencies:** AdMob SDK

**Technology Stack:** Swift 6.1 Actor, Google AdMob SDK

## Component Diagrams

```mermaid
graph TB
    subgraph "UI Layer"
        GV[GameView<br/>SwiftUI]
    end
    
    subgraph "Game Logic Layer"
        GE[GameEngine<br/>Actor]
        ST[ScoreTracker<br/>Actor] 
        BF[BlockFactory<br/>Actor]
        AM[AdManager<br/>Actor]
    end
    
    subgraph "Data Layer"
        SD[SwiftData<br/>Local Storage]
        CK[CloudKit<br/>Sync]
    end
    
    subgraph "External Services"
        ADMOB[AdMob SDK]
    end
    
    GV --> GE
    GV --> ST
    GV --> BF
    GV --> AM
    
    GE --> BF
    GE --> ST
    
    ST --> SD
    SD --> CK
    AM --> ADMOB
    
    classDef ui fill:#e3f2fd
    classDef actor fill:#f3e5f5
    classDef data fill:#e8f5e8
    classDef external fill:#fff3e0
    
    class GV ui
    class GE,ST,BF,AM actor  
    class SD,CK data
    class ADMOB external
```
