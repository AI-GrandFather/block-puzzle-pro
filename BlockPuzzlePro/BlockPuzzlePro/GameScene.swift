import SpriteKit
import GameplayKit
import os.log

class GameScene: SKScene {
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "GameScene")
    
    private var lastUpdateTime: TimeInterval = 0
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        logger.info("GameScene did move to view")
        setupScene()
    }
    
    private func setupScene() {
        // Set background color
        backgroundColor = SKColor.systemBlue
        
        // Configure scene for portrait orientation with proper anchor point
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        
        // Ensure scene scales properly for different device sizes
        self.scaleMode = .aspectFill
        
        // Verify portrait orientation constraints
        logger.info("Scene configured for portrait - Width: \(size.width), Height: \(size.height)")
        
        // Add a simple label to verify the scene is working
        let welcomeLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        welcomeLabel.text = "Block Puzzle Pro"
        welcomeLabel.fontSize = 32
        welcomeLabel.fontColor = SKColor.white
        welcomeLabel.position = CGPoint(x: 0, y: 100)
        addChild(welcomeLabel)
        
        // Add a subtitle
        let subtitleLabel = SKLabelNode(fontNamed: "Arial")
        subtitleLabel.text = "SpriteKit Integration Complete"
        subtitleLabel.fontSize = 18
        subtitleLabel.fontColor = SKColor.lightGray
        subtitleLabel.position = CGPoint(x: 0, y: 60)
        addChild(subtitleLabel)
        
        // Add device info label with orientation confirmation
        let deviceLabel = SKLabelNode(fontNamed: "Arial")
        deviceLabel.text = "Portrait Mode - \(UIDevice.current.name)"
        deviceLabel.fontSize = 14
        deviceLabel.fontColor = SKColor.yellow
        deviceLabel.position = CGPoint(x: 0, y: -100)
        addChild(deviceLabel)
        
        // Add scene size info for testing different device sizes
        let sizeLabel = SKLabelNode(fontNamed: "Arial")
        sizeLabel.text = "Scene Size: \(Int(size.width))x\(Int(size.height))"
        sizeLabel.fontSize = 12
        sizeLabel.fontColor = SKColor.white
        sizeLabel.alpha = 0.7
        sizeLabel.position = CGPoint(x: 0, y: -140)
        addChild(sizeLabel)
        
        logger.info("GameScene setup complete - Size: \(size), Scale Mode: \(scaleMode.rawValue)")
    }
    
    // MARK: - Touch Events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            logger.debug("Touch began at: \(location)")
            
            // Create a simple visual feedback for touches
            let touchEffect = SKShapeNode(circleOfRadius: 20)
            touchEffect.fillColor = SKColor.white
            touchEffect.alpha = 0.7
            touchEffect.position = location
            addChild(touchEffect)
            
            // Animate the touch effect
            let fadeOut = SKAction.fadeOut(withDuration: 0.5)
            let scale = SKAction.scale(to: 2.0, duration: 0.5)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([SKAction.group([fadeOut, scale]), remove])
            touchEffect.run(sequence)
        }
    }
    
    // MARK: - Game Loop
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate time since last update
        let dt = currentTime - self.lastUpdateTime
        
        // Update game logic here (60fps target)
        if dt > 1.0 / 60.0 {
            self.lastUpdateTime = currentTime
        }
    }
    
    override func didEvaluateActions() {
        // Called after actions are evaluated but before physics are simulated
    }
    
    override func didSimulatePhysics() {
        // Called after physics simulation
    }
    
    override func didFinishUpdate() {
        // Called after all update logic has been completed
    }
}