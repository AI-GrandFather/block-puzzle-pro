# Coding Standards

This document defines the coding standards and best practices for the Block Game iOS application.

## Swift Coding Standards

### File Organization
- One class/struct/protocol per file (unless tightly coupled)
- Use meaningful file names that reflect the primary type
- Group related files in appropriate directories
- Follow the source tree structure defined in `source-tree.md`

### Naming Conventions
```swift
// Types: PascalCase
struct GameBoard { }
class BlockManager { }
enum GameState { }

// Properties and methods: camelCase
var currentScore: Int
func moveBlock(to position: CGPoint)

// Constants: camelCase or SCREAMING_SNAKE_CASE for global constants
let maxBlocks = 10
let GAME_VERSION = "1.0.0"

// Private properties: leading underscore optional but consistent
private var _internalState: GameState
```

### Code Structure
```swift
// MARK: - Type Definition
class GameViewController: UIViewController {
    
    // MARK: - Properties
    // Public properties first
    var gameState: GameState = .playing
    
    // Private properties
    private var gameBoard: GameBoard
    private var blockManager: BlockManager
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
    }
    
    // MARK: - Public Methods
    func startNewGame() {
        // Implementation
    }
    
    // MARK: - Private Methods
    private func setupGame() {
        // Implementation
    }
}
```

### SwiftUI Standards
```swift
// View naming: descriptive and specific
struct GameBoardView: View {
    // MARK: - Properties
    @StateObject private var gameManager = GameManager()
    @State private var selectedBlock: Block?
    
    // MARK: - Body
    var body: some View {
        VStack {
            gameHeader
            gameBoard
            gameControls
        }
    }
    
    // MARK: - View Components
    private var gameHeader: some View {
        // Header implementation
    }
    
    private var gameBoard: some View {
        // Board implementation
    }
    
    private var gameControls: some View {
        // Controls implementation
    }
}
```

### Error Handling
```swift
// Use Result types for operations that can fail
func saveGame() -> Result<Void, GameError> {
    do {
        try gameData.save()
        return .success(())
    } catch {
        return .failure(.saveFailed(error))
    }
}

// Custom error types
enum GameError: LocalizedError {
    case saveFailed(Error)
    case invalidMove
    case gameNotInitialized
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save game: \(error.localizedDescription)"
        case .invalidMove:
            return "Invalid move attempted"
        case .gameNotInitialized:
            return "Game not properly initialized"
        }
    }
}
```

### Documentation Standards
```swift
/// Manages the core game logic for the block puzzle game
/// 
/// The GameManager handles:
/// - Game state transitions
/// - Block movement validation
/// - Score calculation
/// - Persistence operations
class GameManager: ObservableObject {
    
    /// The current game state
    @Published var gameState: GameState = .menu
    
    /// Attempts to move a block to the specified position
    /// - Parameters:
    ///   - block: The block to move
    ///   - position: Target position on the game board
    /// - Returns: True if the move was successful, false otherwise
    func moveBlock(_ block: Block, to position: BoardPosition) -> Bool {
        // Implementation
    }
}
```

## Testing Standards

### Unit Test Structure
```swift
import XCTest
@testable import BlockGame

final class GameManagerTests: XCTestCase {
    
    // MARK: - Properties
    private var sut: GameManager!
    
    // MARK: - Lifecycle
    override func setUp() {
        super.setUp()
        sut = GameManager()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testMoveBlock_ValidMove_ReturnsTrue() {
        // Given
        let block = Block(type: .square)
        let position = BoardPosition(x: 0, y: 0)
        
        // When
        let result = sut.moveBlock(block, to: position)
        
        // Then
        XCTAssertTrue(result)
    }
}
```

### Test Naming
- Use descriptive test names: `test[Method]_[Condition]_[ExpectedResult]`
- Group related tests using `// MARK: - Test Group Name`

## Performance Guidelines

### Memory Management
- Use weak references for delegates and closures to avoid retain cycles
- Prefer value types (structs) over reference types (classes) when possible
- Use `@StateObject` for data that should persist across view updates
- Use `@ObservedObject` for data passed from parent views

### SwiftUI Performance
```swift
// Good: Efficient list rendering
LazyVStack {
    ForEach(blocks) { block in
        BlockView(block: block)
    }
}

// Good: Minimize recomputation
struct ExpensiveView: View {
    let data: [GameData]
    
    private var processedData: [ProcessedData] {
        // Expensive computation
        data.map { process($0) }
    }
    
    var body: some View {
        List(processedData, id: \.id) { item in
            ItemView(item: item)
        }
    }
}
```

## Code Quality

### Static Analysis
- Use SwiftLint for consistent code style
- Address all compiler warnings
- Use `// swiftlint:disable` sparingly and with justification

### Code Reviews
- All code must be reviewed before merging
- Focus on logic, performance, and maintainability
- Ensure tests cover new functionality
- Verify documentation is updated

### Refactoring Guidelines
- Extract complex logic into separate methods/types
- Use protocols for testability and flexibility
- Favor composition over inheritance
- Keep functions small and focused (max 20-30 lines)

## Git Standards

### Commit Messages
```
feat: add block rotation functionality
fix: resolve memory leak in GameManager
docs: update API documentation for BlockView
test: add unit tests for game logic
refactor: extract board validation logic
```

### Branch Naming
- `feature/block-rotation`
- `fix/memory-leak-game-manager`
- `docs/update-architecture`

## Security Considerations

- Never commit API keys or sensitive data
- Use Keychain for persistent sensitive data
- Validate all user inputs
- Use secure coding practices for data persistence