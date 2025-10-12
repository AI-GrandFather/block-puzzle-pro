# Claude Code Development Instructions

## Context7 MCP Integration
Before implementing any features, libraries, or architectures, **ALWAYS use Context7 MCP tools** to fetch the latest information:

1. **Resolve Library Documentation**:
   ```
   Use mcp__context7__resolve-library-id to find the correct library ID for any framework/library you're using
   ```

2. **Fetch Current Documentation**:
   ```
   Use mcp__context7__get-library-docs with the resolved library ID to get up-to-date documentation, examples, and best practices
   ```

3. **Key Technologies to Query**:
   - SwiftUI 6 (iOS 26): `/apple/swiftui` or latest version
   - Metal 3: `/apple/metal` or latest graphics API docs
   - Swift 6: `/apple/swift` for latest async/await and concurrency patterns
   - Core Haptics: `/apple/core-haptics`
   - GameKit: `/apple/gamekit`
   - Firebase iOS SDK: `/firebase/firebase-ios-sdk`
   - Lottie iOS: `/airbnb/lottie-ios`

   **Note**: Context7 API key must be properly configured. If you receive "Unauthorized" errors:
   - Verify your API key starts with 'ctx7sk' and is correctly set in MCP settings
   - Restart Cursor/IDE for MCP configuration changes to take effect
   - Test with: `mcp__context7__resolve-library-id` with libraryName "SwiftUI"

### Fallback: Ref MCP Server
If Context7 MCP does not work or is unavailable, use **Ref MCP server** to fetch latest documentation:

**Setup Command:**
```bash
claude mcp add --transport http Ref https://api.ref.tools/mcp --header "x-ref-api-key: ref-93f25aef1e299dae7897"
```

**Usage**: Use Ref MCP tools to search and retrieve up-to-date documentation for any library or framework when Context7 is unavailable.

## Execution Protocol

## Change Documentation Protocol
- Before starting any new gameplay fix or experiment, search the `docs/` directory (e.g. `drag_fix_attempt_*.md`) and review the existing attempt notes to avoid repeating previously failed approaches.
- After completing changes, capture the work in a new markdown file within `docs/` summarising the problem, solution, and outcome.
- Reference the relevant attempt note in updates so future iterations can pick up where the last one left off.

### Sequential Execution
1. Execute each prompt file **in numerical order** (01, 02, 03, etc.)
2. **Complete each phase fully** before moving to the next
3. Verify all success criteria before proceeding
4. **Mark the prompt file as completed** by adding "✅ COMPLETED" at the top of the file
5. Document any deviations or issues encountered
6. Always run xcodebuild before deeming the project as completed to verify that code is complete and running, if user input is needed, mark the file as 'user input needed'
7. Always use latest version of software, use mcp servers like ref or context7 to fetch the updated documentations and if these dont work than do your internet research as per current date.

### Adding Files to Xcode Project (Manual User Action Required)
When creating new Swift files, Claude Code creates them in the file system but **cannot automatically add them to the Xcode project**. This is a manual step that requires user intervention.

**IMPORTANT**: After creating new Swift files, you MUST provide the user with:

1. **Clear notification** that files were created but need manual addition to Xcode
2. **Complete list** of all files that need to be added
3. **Step-by-step instructions** for adding them to Xcode
4. **Verification steps** to confirm files were added correctly

#### Standard Instructions Template for User:

When new Swift files are created, provide these instructions:

```
⚠️ MANUAL ACTION REQUIRED: Add Files to Xcode Project

I've created [N] new Swift files that need to be added to your Xcode project.
Xcode requires manual file registration - follow these steps:

Step 1: Open Xcode
- Open BlockScramble.xcodeproj in Xcode

Step 2: Add Files to Project
Method A (Recommended - Drag & Drop):
1. Open Finder and navigate to: /Users/atharmushtaq/projects/block_scramble/BlockScramble/
2. In Xcode, locate the Project Navigator (left sidebar, folder icon)
3. Drag each file/folder from Finder into the corresponding folder in Xcode's Project Navigator
4. When the dialog appears:
   ✅ Check "Copy items if needed" (should be unchecked if files already exist)
   ✅ Check "Create groups" (not "Create folder references")
   ✅ Ensure "BlockScramble" target is checked
   ✅ Click "Finish"

Method B (Add Files Menu):
1. In Xcode, right-click the folder where files should be added
2. Select "Add Files to BlockScramble..."
3. Navigate to the file location
4. Select the files
5. Ensure "BlockScramble" target is checked
6. Click "Add"

Files to add (organized by folder):

[Provide detailed list organized by folder]

Step 3: Verify Files Were Added
1. In Xcode, select each file in Project Navigator
2. Open File Inspector (right sidebar, document icon)
3. Under "Target Membership", ensure "BlockScramble" is checked

Step 4: Build to Verify
Run this command to verify successful addition:
```bash
xcodebuild build -scheme BlockScramble -sdk iphonesimulator
```

If build succeeds, all files are properly registered! ✅
```

#### Detection and Notification
Before completing each phase, Claude should:

1. **Detect missing files**: Compare created files vs registered files in project.pbxproj
2. **Notify user immediately**: Don't wait until build failure
3. **Provide complete instructions**: Use the template above
4. **Wait for confirmation**: Ask user to confirm files are added before proceeding

### Code Quality Standards
- Follow Swift 6 best practices and naming conventions
- Use modern SwiftUI 6 patterns (iOS 26 / iOS 18+)
- Leverage new iOS 26 "Liquid Glass" design language where appropriate
- Implement proper error handling with Swift 6 typed throws
- Add comprehensive inline documentation
- Write unit tests for all business logic
- Ensure thread safety with Swift 6 concurrency (async/await, actors)

### Performance Requirements
- Target 120fps on ProMotion displays (iPhone 15/16/17 Pro)
- Minimum 60fps on all supported devices
- Keep memory usage under 150MB during gameplay
- Optimize Metal rendering pipeline
- Profile regularly with Instruments

### Architecture Principles
- MVVM pattern with SwiftUI 6
- Reactive programming with Combine and Swift 6 Observation framework
- Single source of truth for state management using @Observable macro
- Modular, reusable components
- Separation of concerns (Views, ViewModels, Services, Models)
- Use Swift 6 strict concurrency checking

### Testing Requirements
- Write unit tests for:
  - Game logic (scoring, line detection, piece generation)
  - Grid operations (validation, placement, clearing)
  - State management
- Create UI tests for:
  - Critical user flows
  - Drag and drop interactions
  - Navigation
- Test on multiple device sizes (iPhone SE, iPhone 15 Pro, iPad Pro)

### Build Testing
When testing build success or running tests, use `xcodebuild`:
```bash
# Clean build
xcodebuild clean -scheme BlockScramble

# Build for testing
xcodebuild build -scheme BlockScramble -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run tests
xcodebuild test -scheme BlockScramble -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Git Integration

### Commit Strategy
After completing each prompt file:

1. **Stage All Changes**:
   ```bash
   git add .
   ```

2. **Create Descriptive Commit**:
   ```bash
   git commit -m "Phase [N]: [Phase Title]

   Implemented:
   - [Feature 1]
   - [Feature 2]
   - [Feature 3]

   Tested:
   - [Test scenario 1]
   - [Test scenario 2]

   Success criteria: [X/Y] completed

   🤖 Generated with Claude Code"
   ```

3. **Push to Remote**:
   ```bash
   git push origin main
   ```

### Commit After Each Phase
**Important**: Create a commit after fully completing each phase, not after individual files or small changes.

### Branch Strategy (Optional)
- Consider creating feature branches for major phases
- Merge to main after phase completion and testing
- Tag releases after major milestones

## Progress Tracking

### Success Criteria Verification
For each prompt file:
- [ ] All requirements implemented
- [ ] All success criteria met
- [ ] Tests written and passing
- [ ] Code reviewed for quality
- [ ] Performance targets met
- [ ] Documentation updated
- [ ] Committed and pushed to GitHub

### Issue Reporting
If you encounter blockers:
1. Document the specific issue
2. Note which success criteria cannot be met
3. Propose alternative solutions
4. Do not proceed to next phase until resolved

## Context7 Usage Examples

### Example 1: SwiftUI Feature Implementation
```
Before implementing drag gestures:
1. resolve-library-id: "SwiftUI"
2. get-library-docs: "/apple/swiftui" with topic: "gestures"
3. Review latest DragGesture API and best practices
4. Implement using current patterns
```

### Example 2: Metal Rendering
```
Before setting up Metal pipeline:
1. resolve-library-id: "Metal"
2. get-library-docs: "/apple/metal" with topic: "rendering pipeline"
3. Check for iOS 18+ optimizations
4. Implement with latest performance techniques
```

### Example 3: Firebase Integration
```
Before adding analytics:
1. resolve-library-id: "firebase-ios-sdk"
2. get-library-docs: "/firebase/firebase-ios-sdk" with topic: "analytics"
3. Review current initialization and tracking patterns
4. Implement according to latest docs
```

## File Organization

### Prompt Files Location
All prompt files are in: `/Users/atharmushtaq/projects/block_scramble/`

### Execution Order
1. `01_project_setup.md`
2. `02_grid_system.md`
3. `03_drag_drop_interaction.md`
4. `04_line_clearing_scoring.md`
5. `05_hold_system_haptics.md`
6. `06_sound_system.md`
7. `07_endless_mode.md`
8. `08_levels_mode.md`
9. `09_timed_puzzle_zen_modes.md`
10. `10_menu_navigation.md`
11. `11_game_center.md`
12. `12_themes_progression.md`
13. `13_monetization.md`
14. `14_animations_particles.md`
15. `15_accessibility_localization.md`
16. `16_polish_optimization_launch.md`

### Marking Files as Complete
After successfully completing a phase:
1. Add "✅ COMPLETED - [Date]" at the very top of the prompt file
2. This helps track progress and avoid re-implementing completed phases
3. Example: `✅ COMPLETED - October 3, 2025`

## Development Notes

### Code Review Checklist (Before Committing)
- [ ] No force unwraps (!) unless absolutely necessary
- [ ] Proper error handling with do-catch or Result types
- [ ] Memory leaks checked (especially with closures and delegates)
- [ ] Accessibility labels added to UI elements
- [ ] Dark mode appearance verified
- [ ] iPad layout tested and responsive
- [ ] Landscape orientation supported where applicable

### Performance Checklist
- [ ] No retain cycles in closures ([weak self])
- [ ] Efficient data structures for grid operations
- [ ] Minimal view hierarchy depth
- [ ] Proper use of @State, @Bindable, @Observable (Swift 6 Observation)
- [ ] Migrate from @ObservedObject/@StateObject to @Observable where appropriate
- [ ] Animations optimized for Metal acceleration
- [ ] Asset catalogs optimized for size
- [ ] Leverage SwiftUI 6 performance improvements (improved diffing, rendering)

### Documentation Requirements
Each major component should have:
- Purpose and responsibility description
- Usage examples
- Parameter documentation
- Return value documentation
- Complexity notes (for algorithms)

## Collaboration Notes

### If You Need Help
1. Review the original game design document
2. Check Context7 docs for the relevant technology
3. Review previous phase implementations for patterns
4. Consult iOS Human Interface Guidelines for UX questions
5. Test on device, not just simulator

### Quality Over Speed
- Take time to implement correctly the first time
- Don't skip testing phases
- Refactor as you discover better patterns
- Keep code readable and maintainable
- Always question and evaluate your work and reimplement anything if seems off.
- do not assume anything on yourown, instead do your internet research or ask ref mcp server.
- There should be no syntax errors
  

## Critical Implementation Rules

### Connect Features to User Flow
**IMPORTANT**: When implementing features across multiple phases, ensure they are **connected and functional** as you build them:

1. **Navigation Integration**:
   - If Phase 1 creates a menu and Phase 2 creates a game view, **connect them immediately** after Phase 2
   - Don't leave placeholder navigation that doesn't work
   - Users should be able to access all implemented features through the UI
   - Tell user if 2 phases are connected and needs to be tested only after both phases are complete

2. **Functional Completeness**:
   - "Placeholder" means minimal implementation, NOT non-functional
   - Buttons and UI elements should perform their basic function, even if features are incomplete
   - Example: A "Play" button should navigate to the game, even if the game is basic

3. **After Each Phase**:
   - Test the **entire user flow** from app launch to the newly implemented feature
   - Verify all previously implemented features still work
   - Connect new features to existing navigation/UI

4. **Integration Over Isolation**:
   - Don't build features in isolation that can't be accessed
   - Wire up navigation, state management, and data flow as you go
   - Each phase should result in a **usable app**, not just isolated components

### Example: Phases 1-3 Integration
- Phase 1: Creates MainMenuView with "Play" button
- Phase 2: Creates GameBoardView
- **After Phase 2**: Connect the Play button to navigate to GameBoardView
- Phase 3: Adds drag-drop to GameBoardView
- **After Phase 3**: Verify full flow: Menu → Game → Drag pieces → Place on grid

## Final Reminders

1. **Always query Context7 first** - Documentation changes frequently
2. **Commit after each phase** - Keep git history clean and logical
3. **Test thoroughly** - Each phase builds on previous ones
4. **Document deviations** - If you need to diverge from prompts, note why
5. **Verify success criteria** - Don't move forward with incomplete phases
6. **Push regularly** - Keep remote repository up to date
7. **Profile performance** - Don't wait until the end to optimize
8. **Connect features immediately** - Don't leave navigation/integration for later phases

## SwiftUI 6 & iOS 26 Specific Guidelines

### New Features to Leverage
1. **Liquid Glass Design Language** (iOS 26):
   - Use translucent, rounded elements with optical glass properties
   - Implement refraction effects for depth and visual hierarchy
   - Consider light reflection for interactive elements

2. **Swift 6 Observation Framework**:
   - Replace @ObservedObject/@StateObject with @Observable macro
   - Use @Bindable for two-way bindings
   - Simpler, more performant state management

3. **Enhanced Animations**:
   - Use improved SwiftUI 6 animation APIs
   - Leverage Metal-accelerated rendering for 120fps
   - Implement smooth transitions with new easing functions

4. **Improved Toolbar & Navigation**:
   - Use ToolbarSpacer for better toolbar layouts
   - Implement modern navigation patterns with NavigationStack

5. **3D & Spatial Support** (Optional):
   - Consider RealityKit integration for special effects
   - Use Swift Charts with 3D visualization where applicable

### Migration Guidelines
When updating existing code:
- Gradually migrate from ObservableObject to @Observable
- Update property wrappers: @StateObject → @State, @ObservedObject → @Bindable
- Enable Swift 6 language mode for strict concurrency checking
- Test performance improvements with updated SwiftUI 6 rendering

---

**Current Status**: Documentation updated for SwiftUI 6 / iOS 26
**Platform Versions**: iOS 26, SwiftUI 6.2, Swift 6.2
**Last Updated**: October 4, 2025
