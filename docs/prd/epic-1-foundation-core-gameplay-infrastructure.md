# Epic 1: Foundation & Core Gameplay Infrastructure

**Epic Goal:** Establish the fundamental game architecture and deliver a fully playable block puzzle experience with core mechanics and complete scoring system. This epic creates the foundation for all subsequent features while ensuring players can immediately understand and enjoy the basic gameplay loop of placing blocks and clearing lines.

## Story 1.1: Project Setup and Basic SpriteKit Integration
As a developer,
I want to create the iOS project structure with SpriteKit framework,
so that I have a solid foundation for game development.

### Acceptance Criteria
1. Xcode project created with Swift 6.1 and iOS 17+ minimum deployment target
2. SpriteKit game scene configured with portrait orientation lock
3. Basic app lifecycle management implemented (launch, background, foreground)
4. Project compiles and runs successfully on both iPhone and iPad simulators
5. Git repository initialized with proper .gitignore for iOS development

## Story 1.2: AdMob SDK Integration and Configuration
As a developer,
I want to integrate Google AdMob SDK with proper configuration,
so that I can serve rewarded video ads to players when they choose.

### Acceptance Criteria
1. AdMob SDK (2025 version) integrated with proper iOS permissions and configuration
2. Test ad units configured for development and testing phases
3. Production ad units ready for App Store deployment
4. Ad loading happens in background without blocking gameplay
5. Error handling for network failures and ad unavailability
6. Compliance with iOS 18.6.2 App Tracking Transparency requirements

## Story 1.3: Game Grid and Visual Foundation
As a player,
I want to see a clean 10x10 game grid,
so that I understand the playing field immediately.

### Acceptance Criteria
1. 10x10 grid rendered with clear cell boundaries and consistent spacing
2. Grid scales appropriately across all iOS device screen sizes in portrait mode
3. Visual design uses clean geometric style with subtle grid lines
4. Grid positioning allows space for score display at top and block tray at bottom
5. Grid cells provide visual feedback for potential block placement areas

## Story 1.4: Basic Block Creation and Display
As a player,
I want to see the three starting block types (L-shape, 1x1, 1x2) in the bottom tray,
so that I can begin placing blocks on the grid.

### Acceptance Criteria
1. Three block types (L-shape, 1x1, 1x2) display in bottom interface tray
2. Blocks use vibrant, distinct colors that are easily distinguishable
3. Block shapes render with clean geometric design matching overall aesthetic
4. Bottom tray layout provides adequate spacing for comfortable touch interaction
5. Blocks automatically regenerate in tray after placement (infinite supply)

## Story 1.5: Drag-and-Drop Block Placement
As a player,
I want to drag blocks from the tray and place them on the grid,
so that I can start playing the core puzzle game.

### Acceptance Criteria
1. Blocks can be dragged from bottom tray with smooth touch response
2. Dragged blocks follow finger movement with appropriate visual feedback
3. Valid placement positions highlight on grid during drag operations
4. Invalid placements are clearly indicated and prevent block placement
5. Successfully placed blocks snap to grid positions with satisfying animation
6. Placed blocks become part of the grid and cannot be moved

## Story 1.6: Line and Column Clearing Mechanics
As a player,
I want complete rows and columns to clear automatically,
so that I can make space for more blocks and feel progression.

### Acceptance Criteria
1. Complete horizontal rows (10 blocks) automatically clear with celebration animation
2. Complete vertical columns (10 blocks) automatically clear with celebration animation
3. Multiple simultaneous line/column clears are handled properly
4. Clearing animation provides satisfying visual feedback (brief highlight/fade)
5. Cleared spaces become immediately available for new block placement
6. No partial clears - only complete lines/columns trigger clearing

## Story 1.7: Basic Scoring System
As a player,
I want to see my score increase when I clear lines and place blocks,
so that I can track my progress and feel achievement.

### Acceptance Criteria
1. Score display prominently positioned at top of screen
2. Points awarded for each block placed (base points per block)
3. Bonus points awarded for line/column clearing (higher value than placement)
4. Multiple simultaneous clears provide cumulative bonus scoring
5. Score persists throughout game session and updates in real-time
6. Score resets to zero when starting a new game

## Story 1.8: Line Clear Bonus Scoring
As a player,
I want to receive bonus points for clearing multiple lines simultaneously,
so that I'm rewarded for strategic planning and optimal block placement.

### Acceptance Criteria
1. Single line/column clear provides base bonus (e.g., 100 points)
2. Double simultaneous clears provide escalated bonus (e.g., 300 points total)
3. Triple simultaneous clears provide major bonus (e.g., 600 points total)
4. Scoring formula rewards simultaneous clears exponentially, not linearly
5. Combo scoring displays briefly during clearing animation
6. Score calculation is transparent and feels fair to players

## Story 1.9: Block Placement Scoring Refinement
As a player,
I want to earn points based on block size and placement difficulty,
so that strategic placement feels rewarded beyond just line clearing.

### Acceptance Criteria
1. Different block types award points based on complexity (1x1 = 1pt, L-shape = 3pts, etc.)
2. Placement in constrained spaces provides small bonus multiplier
3. Consecutive placements without clearing provide incremental bonus
4. Scoring feedback appears briefly at placement location
5. Total session points continuously update in real-time
6. Point values feel balanced - placement valuable but clearing more rewarding

## Story 1.10: Game Over Detection
As a player,
I want the game to detect when no more moves are possible,
so that I know when my current session has ended.

### Acceptance Criteria
1. Game automatically detects when no available blocks can fit on remaining grid space
2. Game over detection accounts for all three block types in bottom tray
3. Game over state displays final score clearly
4. Game over detection is accurate and doesn't trigger false positives
5. Game over state provides clear visual indication of session end

## Story 1.11: Basic Restart Functionality
As a player,
I want to restart the game after game over,
so that I can play multiple rounds.

### Acceptance Criteria
1. Simple restart button appears on game over screen
2. Restart clears grid completely and resets score to zero
3. New set of three blocks appears in tray after restart
4. Restart functionality works immediately without app restart
5. All game state properly resets for fresh session
