import SpriteKit
import GameplayKit
import os.log
import Foundation

// MARK: - Game Scene with Full Block Puzzle Functionality

/// Main SpriteKit scene for the block puzzle game
class GameScene: SKScene {
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "GameScene")
    
    // MARK: - Properties
    
    /// Game engine dependency - will be injected from SwiftUI
    var gameEngine: GameEngine?
    
    /// Block factory dependency - will be injected from SwiftUI  
    var blockFactory: BlockFactory?
    
    // Game state tracking
    private var lastUpdateTime: TimeInterval = 0
    private var targetFrameRate: Int = 60
    private var isProMotionEnabled: Bool = false
    
    // Grid visualization
    private var gridNodes: [[SKShapeNode]] = []
    private var gridContainer: SKNode?
    private var previewNodes: [SKNode] = []
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        logger.info("GameScene did move to view")
        detectDisplayCapabilities(view: view)
        setupScene()
        createGrid()
    }
    
    private func detectDisplayCapabilities(view: SKView) {
        // Detect ProMotion capability
        if #available(iOS 15.0, *) {
            let maxRefreshRate = UIScreen.main.maximumFramesPerSecond
            isProMotionEnabled = maxRefreshRate >= VisualConstants.Performance.proMotionMinimumRefreshRate
            targetFrameRate = VisualConstants.getTargetFrameRate(isProMotion: isProMotionEnabled)
            
            // Configure SpriteKit view
            view.preferredFramesPerSecond = self.targetFrameRate
            view.ignoresSiblingOrder = true
            
            logger.info("Display - ProMotion: \(self.isProMotionEnabled), Target FPS: \(self.targetFrameRate)")
        } else {
            targetFrameRate = VisualConstants.Performance.standardTargetFPS
            isProMotionEnabled = false
            logger.info("Standard Display - Target FPS: \(self.targetFrameRate)")
        }
    }
    
    private func setupScene() {
        // Basic scene configuration
        backgroundColor = VisualConstants.Colors.gridBackground
        
        // Create main container
        gridContainer = SKNode()
        gridContainer?.name = "GridContainer"
        if let container = gridContainer {
            addChild(container)
        }
        
        logger.info("Scene setup completed")
    }
    
    // MARK: - Grid Creation and Management
    
    private func createGrid() {
        guard let container = gridContainer else { return }
        
        let _ = VisualConstants.getDeviceCategory(for: size)
        let cellSize = VisualConstants.calculateCellSize(for: size)
        let gridPosition = VisualConstants.calculateGridPosition(for: size, cellSize: cellSize)
        
        // Position grid container
        container.position = gridPosition
        
        // Initialize grid nodes array
        gridNodes = Array(repeating: Array(repeating: SKShapeNode(), count: VisualConstants.Grid.size), count: VisualConstants.Grid.size)
        
        // Create grid cells
        for row in 0..<VisualConstants.Grid.size {
            for col in 0..<VisualConstants.Grid.size {
                let cellNode = createGridCell(row: row, column: col, cellSize: cellSize)
                gridNodes[row][col] = cellNode
                container.addChild(cellNode)
            }
        }
        
        logger.info("Grid created with \(VisualConstants.Grid.size)x\(VisualConstants.Grid.size) cells, cellSize: \(cellSize)")
    }
    
    private func createGridCell(row: Int, column: Int, cellSize: CGFloat) -> SKShapeNode {
        let cellRect = CGRect(x: CGFloat(column) * cellSize, y: CGFloat(row) * cellSize, width: cellSize, height: cellSize)
        let cellNode = SKShapeNode(rect: cellRect)
        
        // Configure cell appearance
        cellNode.fillColor = VisualConstants.Colors.emptyCellBackground
        cellNode.strokeColor = VisualConstants.Colors.cellBorder
        cellNode.lineWidth = VisualConstants.Grid.lineWidth
        cellNode.name = "GridCell_\(row)_\(column)"
        
        return cellNode
    }
    
    // MARK: - Block Placement
    
    /// Place a block pattern at the specified grid position
    func placeBlock(_ blockPattern: BlockPattern, at gridPosition: GridPosition) -> Bool {
        guard let engine = gameEngine else {
            logger.warning("GameEngine not available for block placement")
            return false
        }
        
        // Get all positions this block would occupy
        let targetPositions = blockPattern.getGridPositions(placedAt: gridPosition)
        
        // Validate placement
        for position in targetPositions {
            if !engine.canPlaceAt(position: position) {
                logger.warning("Cannot place block at position \(String(describing: position))")
                return false
            }
        }
        
        // Place blocks in game engine
        if engine.placeBlocks(at: targetPositions, color: blockPattern.color) {
            // Update visual representation
            updateGridVisuals()
            
            // Process completed lines
            let lineClearResult = engine.processCompletedLines()
            if !lineClearResult.isEmpty {
                logger.info("Completed lines: rows=\(lineClearResult.rows) columns=\(lineClearResult.columns)")
                // TODO: Add line clearing animation
            }
            
            return true
        }
        
        return false
    }
    
    /// Check if a block can be placed at the specified position
    func canPlaceBlock(_ blockPattern: BlockPattern, at gridPosition: GridPosition) -> Bool {
        guard let engine = gameEngine else { return false }
        
        let targetPositions = blockPattern.getGridPositions(placedAt: gridPosition)
        
        for position in targetPositions {
            if !engine.canPlaceAt(position: position) {
                return false
            }
        }
        
        return true
    }
    
    /// Convert screen point to grid position
    func gridPositionFromScreenPoint(_ screenPoint: CGPoint) -> GridPosition? {
        guard let container = gridContainer else { return nil }
        
        // Convert screen point to container space
        let localPoint = convert(screenPoint, to: container)
        
        let cellSize = VisualConstants.calculateCellSize(for: size)
        let column = Int(localPoint.x / cellSize)
        let row = Int(localPoint.y / cellSize)
        
        return GridPosition(row: row, column: column)
    }
    
    // MARK: - Preview System
    
    /// Show preview of block placement
    func showBlockPreview(_ blockPattern: BlockPattern, at gridPosition: GridPosition) {
        clearBlockPreview()
        
        guard canPlaceBlock(blockPattern, at: gridPosition) else { return }
        
        let targetPositions = blockPattern.getGridPositions(placedAt: gridPosition)
        let cellSize = VisualConstants.calculateCellSize(for: size)
        
        // Create preview nodes
        for position in targetPositions {
            if position.isValid {
                let previewNode = createPreviewNode(at: position, color: blockPattern.color, cellSize: cellSize)
                gridContainer?.addChild(previewNode)
                previewNodes.append(previewNode)
            }
        }
    }
    
    private func createPreviewNode(at position: GridPosition, color: BlockColor, cellSize: CGFloat) -> SKShapeNode {
        let cellRect = CGRect(
            x: CGFloat(position.column) * cellSize,
            y: CGFloat(position.row) * cellSize,
            width: cellSize,
            height: cellSize
        )
        
        let previewNode = SKShapeNode(rect: cellRect)
        previewNode.fillColor = color.previewColor
        previewNode.strokeColor = color.skColor
        previewNode.lineWidth = VisualConstants.Grid.lineWidth * 2
        previewNode.name = "PreviewNode"
        previewNode.zPosition = 10
        
        return previewNode
    }
    
    /// Clear all preview nodes
    func clearBlockPreview() {
        for node in previewNodes {
            node.removeFromParent()
        }
        previewNodes.removeAll()
    }
    
    // MARK: - Visual Updates
    
    private func updateGridVisuals() {
        guard let engine = gameEngine else { return }
        
        // Update each grid cell based on game engine state
        for row in 0..<VisualConstants.Grid.size {
            for col in 0..<VisualConstants.Grid.size {
                let position = GridPosition(unsafeRow: row, unsafeColumn: col)
                if let cell = engine.cell(at: position) {
                    updateCellVisual(at: position, cell: cell)
                }
            }
        }
    }
    
    private func updateCellVisual(at position: GridPosition, cell: GridCell) {
        let cellNode = gridNodes[position.row][position.column]
        
        switch cell {
        case .empty:
            cellNode.fillColor = VisualConstants.Colors.emptyCellBackground
            
        case .occupied(let color):
            cellNode.fillColor = color.skColor
            
        case .preview(let color):
            cellNode.fillColor = color.previewColor
        }
    }
    
    // MARK: - Update Loop
    
    override func update(_ currentTime: TimeInterval) {
        // Performance monitoring
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
            return
        }
        
        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Monitor performance
        if deltaTime > 0 {
            let currentFPS = 1.0 / deltaTime
            if currentFPS < Double(self.targetFrameRate) * 0.8 {
                logger.warning("Performance warning - FPS: \(String(format: "%.1f", currentFPS)), Target: \(self.targetFrameRate)")
            }
        }
    }
    
    // MARK: - Touch Handling (Delegated to SwiftUI)
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        logger.debug("Touch began - delegated to SwiftUI")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        logger.debug("Touch moved - delegated to SwiftUI")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        logger.debug("Touch ended - delegated to SwiftUI")
    }
}

// MARK: - Extensions

extension GameScene {
    
    /// Debug function to highlight grid positions
    func highlightGridPosition(_ position: GridPosition, color: SKColor = .red) {
        guard position.isValid else { return }
        
        let cellSize = VisualConstants.calculateCellSize(for: size)
        let highlightRect = CGRect(
            x: CGFloat(position.column) * cellSize,
            y: CGFloat(position.row) * cellSize,
            width: cellSize,
            height: cellSize
        )
        
        let highlight = SKShapeNode(rect: highlightRect)
        highlight.fillColor = color.withAlphaComponent(0.5)
        highlight.strokeColor = color
        highlight.lineWidth = 3
        highlight.name = "Highlight"
        highlight.zPosition = 20
        
        gridContainer?.addChild(highlight)
        
        // Auto-remove after 1 second
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        highlight.run(sequence)
    }
}
