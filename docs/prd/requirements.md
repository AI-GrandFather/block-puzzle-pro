# Requirements

## Functional Requirements

**FR1:** The game shall provide a 10x10 grid-based playing field with drag-and-drop block placement mechanics optimized for touch input

**FR2:** The system shall maintain a constant bottom interface displaying exactly 3 block types: L-shape, 1x1, and 1x2 blocks available for placement

**FR3:** The game shall implement line and column clearing mechanics with celebration animations when complete rows/columns are formed

**FR4:** The system shall unlock new block types at score-based milestones: 2x1 block at 500 points, T-shape at 1000 points

**FR5:** The game shall provide customizable timer modes (3/5/7 minutes) that unlock at 1000 points milestone

**FR6:** The system shall implement a learn-by-playing tutorial with visual guidance and immediate feedback within the first 30 seconds

**FR7:** The game shall integrate AdMob rewarded video ads for "continue gameplay" option after game over

**FR8:** The system shall provide optional power-up ads during gameplay that are player-initiated, never forced

**FR9:** The game shall maintain universal iPhone/iPad support with smooth 60fps animations

**FR10:** The system shall implement local score tracking and progression persistence using SwiftData

## Non-Functional Requirements

**NFR1:** The application shall launch in under 2 seconds on iOS 17+ devices to meet user expectation standards

**NFR2:** The game shall maintain 60fps performance on standard devices and 120fps on ProMotion displays

**NFR3:** The system shall achieve <80MB download size through App Thinning optimization

**NFR4:** The application shall support offline-first functionality with optional CloudKit sync for cross-device progression

**NFR5:** Ad integration shall achieve 85%+ completion rates for rewarded videos to meet revenue targets

**NFR6:** The game shall maintain data privacy compliance with iOS 18.6.2 App Tracking Transparency requirements

**NFR7:** The system shall handle memory management efficiently to prevent crashes during extended play sessions

**NFR8:** The application shall support portrait orientation only with fixed vertical layout optimized for one-handed gameplay

**NFR9:** The system shall achieve 99.9% data backup success rate with automatic local persistence and recovery capability within 30 seconds of data corruption detection

**NFR10:** The application shall support seamless data migration between app versions with <2 second migration completion for datasets up to 10MB, maintaining backward compatibility for user progression data

**NFR11:** The system shall implement CloudKit sync conflict resolution with automatic merge for score data and manual resolution prompts for conflicting user preferences, completing sync operations within 5 seconds on stable network connections
