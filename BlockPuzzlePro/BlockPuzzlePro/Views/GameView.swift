import SwiftUI
import SpriteKit

// MARK: - Main Game View

/// Main game view that combines SpriteKit grid with SwiftUI block tray
struct GameView: View {
    
    // MARK: - Properties
    
    @StateObject private var gameEngine = GameEngine()
    @StateObject private var blockFactory = BlockFactory()
    
    @State private var selectedBlock: (index: Int, pattern: BlockPattern)?
    @State private var gameScene: GameScene?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Score area (top 15%)
                    scoreArea
                        .frame(height: geometry.size.height * VisualConstants.Layout.scoreAreaPercentage)
                    
                    // Game grid area (middle 70%)
                    gameGridArea(size: geometry.size)
                        .frame(height: geometry.size.height * VisualConstants.Layout.gridAreaPercentage)
                    
                    // Block tray area (bottom 15%)  
                    blockTrayArea
                        .frame(height: geometry.size.height * VisualConstants.Layout.blockTrayPercentage)
                }
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(false)
        .onAppear {
            setupGame()
        }
    }
    
    // MARK: - View Components
    
    private var scoreArea: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(gameEngine.score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Lines")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("0") // TODO: Add line counter to GameEngine
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private func gameGridArea(size: CGSize) -> some View {
        SpriteView(scene: createGameScene(size: size))
            .ignoresSafeArea(.all, edges: .horizontal)
            .clipped()
    }
    
    private var blockTrayArea: some View {
        VStack(spacing: 8) {
            // Tray header
            HStack {
                Text("Available Blocks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if blockFactory.hasAvailableBlocks {
                    Text("\(blockFactory.availableBlocks.count) blocks")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            
            // Block tray
            BlockTrayView(
                blockFactory: blockFactory,
                cellSize: 30,
                onBlockSelected: handleBlockSelection
            )
        }
    }
    
    // MARK: - Game Setup
    
    private func setupGame() {
        // Start new game
        gameEngine.startNewGame()
        
        // Generate initial blocks
        blockFactory.regenerateAllBlocks()
    }
    
    private func createGameScene(size: CGSize) -> GameScene {
        let scene = GameScene()
        
        // Configure scene
        scene.size = size
        scene.scaleMode = .aspectFill
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Inject dependencies
        scene.gameEngine = gameEngine
        scene.blockFactory = blockFactory
        
        // Store reference for communication
        self.gameScene = scene
        
        return scene
    }
    
    // MARK: - Block Handling
    
    private func handleBlockSelection(index: Int, blockPattern: BlockPattern) {
        selectedBlock = (index, blockPattern)
        
        // TODO: Implement drag and drop functionality
        // For now, just demonstrate the regeneration system
        demonstrateBlockPlacement(index: index, blockPattern: blockPattern)
    }
    
    private func demonstrateBlockPlacement(index: Int, blockPattern: BlockPattern) {
        guard let scene = gameScene else { return }
        
        // Try to place block at a random valid position (for demonstration)
        if let validPosition = findValidPlacementPosition(for: blockPattern) {
            if scene.placeBlock(blockPattern, at: validPosition) {
                // Block placed successfully - regenerate it (infinite supply)
                blockFactory.regenerateBlock(at: index)
                
                DebugLog.trace("✅ Placed \(blockPattern.type) at \(validPosition) and regenerated")
            }
        } else {
            DebugLog.trace("❌ No valid placement found for \(blockPattern.type)")
        }
    }
    
    private func findValidPlacementPosition(for blockPattern: BlockPattern) -> GridPosition? {
        guard let scene = gameScene else { return nil }
        
        // Try different positions starting from top-left
        for row in 0..<VisualConstants.Grid.size {
            for col in 0..<VisualConstants.Grid.size {
                if let position = GridPosition(row: row, column: col) {
                    if scene.canPlaceBlock(blockPattern, at: position) {
                        return position
                    }
                }
            }
        }
        
        return nil
    }
}

// MARK: - Game Coordinator

/// Coordinates between SwiftUI views and SpriteKit scene
@MainActor
class GameCoordinator: ObservableObject {
    
    // MARK: - Properties
    
    private var gameScene: GameScene?
    private var blockFactory: BlockFactory?
    
    // MARK: - Block Placement
    
    func setGameScene(_ scene: GameScene) {
        self.gameScene = scene
    }
    
    func setBlockFactory(_ factory: BlockFactory) {
        self.blockFactory = factory
    }
    
    func placeBlock(_ blockPattern: BlockPattern, at screenPoint: CGPoint) -> Bool {
        guard let scene = gameScene,
              let gridPosition = scene.gridPositionFromScreenPoint(screenPoint) else {
            return false
        }
        
        return scene.placeBlock(blockPattern, at: gridPosition)
    }
    
    func showPreview(_ blockPattern: BlockPattern, at screenPoint: CGPoint) {
        guard let scene = gameScene,
              let gridPosition = scene.gridPositionFromScreenPoint(screenPoint) else {
            return
        }
        
        scene.showBlockPreview(blockPattern, at: gridPosition)
    }
    
    func clearPreview() {
        gameScene?.clearBlockPreview()
    }
    
    func regenerateBlock(at index: Int) {
        blockFactory?.regenerateBlock(at: index)
    }
}

// MARK: - Preview

#Preview {
    GameView()
        .preferredColorScheme(.light)
}
