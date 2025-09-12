# Epic 3: Timer Modes

**Epic Goal:** Introduce customizable timer challenges that provide gameplay variety while maintaining the core puzzle experience. This epic adds the strategic time-pressure element that differentiates casual quick sessions from longer engagement periods, directly addressing the project's goal of flexible session lengths.

## Story 3.1: Timer Mode Unlock System at 1000 Points
As a player,
I want timer modes to unlock when I reach 1000 points in endless mode,
so that I earn access to new challenges through skill demonstration.

### Acceptance Criteria
1. Timer mode option appears in main menu when player reaches 1000 points in any endless game
2. Unlock notification celebrates the achievement with clear explanation of new feature
3. Timer mode access persists across app sessions once unlocked
4. Visual indication shows timer modes as unlocked vs locked in main interface
5. Unlock milestone integrates smoothly with existing 1000-point T-block unlock
6. Clear messaging explains difference between endless and timer gameplay

## Story 3.2: Timer Mode Selection Interface
As a player,
I want to choose between 3, 5, or 7-minute timer challenges,
so that I can match my gameplay to my available time and mood.

### Acceptance Criteria
1. Clean modal interface presents three timer options (3, 5, 7 minutes) with clear labels
2. Each timer option includes brief description of recommended use case
3. Selection interface allows easy switching between endless and timer modes
4. Timer selection persists as user preference for quick access
5. Interface design maintains consistent visual style with main game
6. Option to return to endless mode clearly available from timer selection

## Story 3.3: Timer Challenge Modes (3/5/7 minutes)
As a player,
I want to play timed challenges in 3, 5, or 7-minute durations,
so that I can match my gameplay to my available time and desired intensity level.

### Acceptance Criteria
1. All three timer durations (3, 5, 7 minutes) implemented with consistent gameplay mechanics
2. Timer displays prominently during gameplay with clear countdown for all modes
3. Time warnings provided at appropriate intervals (30-second and 10-second marks)
4. Game continues until timer expires, then shows final score achievement
5. Scoring calibration optimized for each duration - achievable milestones within time limits
6. Visual timer design adapts appropriately for different durations
7. All unlocked block types available in timer modes
8. Smooth transition back to mode selection or restart options
9. Performance tracking and high score comparison specific to each timer duration

## Story 3.4: Timer Mode Score Integration and Comparison
As a player,
I want to see how my timer mode scores compare to my endless mode achievements,
so that I can understand my performance across different gameplay styles.

### Acceptance Criteria
1. Separate high score tracking for each timer mode (3, 5, 7 minutes) and endless mode
2. Score comparison interface shows best performance for each mode type
3. Overall statistics show total games played, average scores per mode
4. Personal achievement recognition for improvements in any mode
5. Score data integration with existing SwiftData persistence system
6. Optional sharing of timer challenge achievements
