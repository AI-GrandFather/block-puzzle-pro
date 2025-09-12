# Epic 2: Progressive Block System

**Epic Goal:** Implement the core retention mechanic through score-based block progression and milestone systems. This epic transforms the basic puzzle into an engaging progression experience where players unlock new challenges and feel continuous advancement through their gameplay achievements.

## Story 2.1: Score Persistence and Session Tracking
As a player,
I want my scores to be saved locally on my device,
so that I can track my best performances across multiple play sessions.

### Acceptance Criteria  
1. SwiftData integration with VersionedSchema V1 stores high scores locally with automatic persistence
2. Schema migration plan supports future model evolution with lightweight migration for common changes
3. High score display shows personal best prominently with real-time updates during gameplay
4. Score data persists across app launches with <2 second restoration time on app startup
5. CloudKit sync enables cross-device score sharing with conflict resolution for concurrent updates
6. Local backup export creates JSON files with schema version metadata for manual restoration scenarios
7. Data integrity validation runs automatically with corruption detection and recovery mechanisms
8. Migration testing covers upgrade paths from initial release through all subsequent versions

## Story 2.2: 2x1 Block Unlock at 500 Points
As a player,
I want to unlock the 2x1 block when I reach 500 points,
so that I experience meaningful progression and new strategic options.

### Acceptance Criteria
1. 2x1 rectangular block unlocks automatically at exactly 500 points milestone
2. Visual celebration animation announces the new block unlock
3. 2x1 block appears in bottom tray alongside existing L-shape, 1x1, and 1x2 blocks
4. Block unlock persists across game sessions - once unlocked, always available
5. Clear visual indication shows which blocks are unlocked vs locked
6. Achievement milestone (500 points) displays as accomplished in player progress

## Story 2.2: T-Shape Block Unlock at 1000 Points
As a player,
I want to unlock the T-shaped block at 1000 points,
so that I have even more strategic placement options and feel significant progression.

### Acceptance Criteria
1. T-shaped block unlocks automatically at exactly 1000 points milestone
2. Celebration animation for T-block unlock feels more significant than previous unlock
3. T-block appears in bottom tray with all previously unlocked blocks
4. T-block maintains proper rotation and placement mechanics
5. Visual progression indicator shows completed milestones (500, 1000 points)
6. Block variety increases strategic depth without overwhelming casual players

## Story 2.3: Progress Milestone Indicators
As a player,
I want to see my progress toward the next block unlock,
so that I feel motivated to continue playing and reach the next milestone.

### Acceptance Criteria
1. Progress bar or indicator shows advancement toward next milestone (500, 1000 points)
2. Visual indicator updates in real-time as score increases
3. Upcoming unlock preview shows which block will be unlocked next
4. Milestone achievements remain visible in some form after completion
5. Progress indicator doesn't clutter main gameplay interface
6. Clear communication of current status and next goal
