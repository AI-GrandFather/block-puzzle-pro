# Technical Assumptions

## Repository Structure: Monorepo
Single iOS project repository using Swift Package Manager for dependency management, containing all game assets, code, and configuration files. This approach simplifies version control and deployment for the solo development timeline.

## Service Architecture
**Monolith with Actor-based Components**: Single iOS app with Swift 6.1 async/await architecture using separate actors for GameEngine, ScoreTracker, BlockFactory, and AdManager. This provides clean separation of concerns while maintaining simple deployment and debugging.

## Testing Requirements
**Unit + Integration**: Core game logic unit tests for block placement, line clearing, and scoring algorithms. Integration tests for AdMob functionality and SwiftData persistence. Manual testing for touch interactions and visual feedback on multiple device sizes.

## Additional Technical Assumptions and Requests

**Platform Foundation:**
- Swift 6.1 with enhanced concurrency safety and improved compile times
- SpriteKit for 60fps game rendering and smooth animations  
- SwiftData for local persistence with automatic CloudKit sync
- iOS 17+ minimum support (95% device coverage)

**Monetization Integration:**
- Google AdMob SDK (2025 version) for rewarded video ads
- Target $9-17 eCPM with 85%+ completion rates
- Player-controlled ad timing (continue gameplay, optional power-ups)

**Performance Targets:**
- <2 second app launch leveraging iOS 18.6.2 optimizations
- 120fps on ProMotion displays, 60fps minimum on all devices
- <80MB download size through App Thinning

**Development Constraints:**
- Solo development approach requiring self-sufficient technology choices
- 6-8 week timeline necessitating rapid iteration capabilities
- Portrait-only orientation for consistent mobile puzzle experience

**Data Persistence & Schema Evolution Strategy:**
- SwiftData VersionedSchema implementation with SchemaMigrationPlan for controlled schema evolution
- Lightweight migration support for: adding entities/attributes, renaming properties, changing relationship types
- Complex migration handling for data model restructuring with custom migration logic and data integrity validation
- Local backup export generating JSON snapshots with schema version metadata for cross-device restoration
- CloudKit integration with conflict resolution prioritizing device-local changes and user confirmation for significant conflicts
- Schema evolution testing strategy including migration path validation from each released version
