# API Specification

**API Style: Direct Method Calls** (No networking needed - single player game)

Based on research of successful iOS puzzle games (2048, Monument Valley, Threes!), single-player puzzle games use **direct method calls** between components, not REST APIs or GraphQL. This is the industry standard approach.

## Actor Communication Patterns

Our actors communicate through simple Swift method calls:

```swift
// GameEngine Actor Methods
actor GameEngine {
    func placeBlock(_ blockType: BlockType, at position: GridPosition) async -> PlacementResult
    func checkForCompletedLines() async -> [LineType] 
    func clearLines(_ lines: [LineType]) async -> Int
    func isGameOver() async -> Bool
}

// ScoreTracker Actor Methods  
actor ScoreTracker {
    func addPoints(_ points: Int) async
    func getCurrentScore() async -> Int
    func checkMilestone() async -> Milestone?
    func saveHighScore() async
}

// BlockFactory Actor Methods
actor BlockFactory {
    func generateNextBlocks() async -> [BlockType]
    func getAvailableBlocks() async -> [BlockType]
}

// AdManager Actor Methods
actor AdManager {
    func loadRewardedAd() async -> Bool
    func showContinueAd() async -> Bool
    func showPowerUpAd() async -> Bool
}
```

**Research Finding:** Top puzzle games like Candy Crush ($1.24B revenue) and 2048 use this exact pattern - local method calls with cloud sync for scores only.
