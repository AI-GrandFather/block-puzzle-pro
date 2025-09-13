import SpriteKit
import GameplayKit
import os.log

class GameScene: SKScene {
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "GameScene")
    
    private var lastUpdateTime: TimeInterval = 0
    private var targetFrameRate: Int = 60
    private var isProMotionEnabled: Bool = false
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        logger.info("GameScene did move to view")
        detectDisplayCapabilities(view: view)
        setupScene()
    }
    
    private func detectDisplayCapabilities(view: SKView) {
        // Detect current display capabilities
        if #available(iOS 15.0, *) {
            let maxRefreshRate = UIScreen.main.maximumFramesPerSecond
            targetFrameRate = maxRefreshRate >= 120 ? 120 : 60
            isProMotionEnabled = maxRefreshRate >= 120
            
            logger.info("Display capabilities detected - Target FPS: \(targetFrameRate), ProMotion: \(isProMotionEnabled)")
        } else {
            targetFrameRate = 60
            isProMotionEnabled = false
            logger.info("iOS 14 or earlier - Target FPS: 60")
        }
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
        
        // Add display info showing ProMotion status
        let displayLabel = SKLabelNode(fontNamed: "Arial")
        displayLabel.text = isProMotionEnabled ? "ProMotion 120 FPS" : "Standard 60 FPS"
        displayLabel.fontSize = 14
        displayLabel.fontColor = isProMotionEnabled ? SKColor.green : SKColor.orange
        displayLabel.position = CGPoint(x: 0, y: -130)
        addChild(displayLabel)
        
        // Add scene size info for testing different device sizes
        let sizeLabel = SKLabelNode(fontNamed: "Arial")
        sizeLabel.text = "Scene Size: \(Int(size.width))x\(Int(size.height))"
        sizeLabel.fontSize = 12
        sizeLabel.fontColor = SKColor.white
        sizeLabel.alpha = 0.7
        sizeLabel.position = CGPoint(x: 0, y: -160)
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
        
        // Use variable frame rate target based on display capabilities
        let targetFrameTime = 1.0 / Double(targetFrameRate)
        
        // Update game logic based on actual display refresh rate
        if dt >= targetFrameTime {
            // Perform frame-rate independent updates
            updateGameLogic(deltaTime: dt)
            self.lastUpdateTime = currentTime
        }
    }
    
    private func updateGameLogic(deltaTime: TimeInterval) {
        // Frame-rate independent game logic updates
        // This ensures smooth gameplay regardless of 60 FPS or 120 FPS
        
        // Example: Animation speeds should be time-based, not frame-based
        // Instead of: position += speed (frame-based)
        // Use: position += speed * deltaTime (time-based)
        
        // Performance monitoring for ProMotion displays
        if isProMotionEnabled && deltaTime > 1.0 / 110.0 {
            // If we're dropping below 110 FPS on ProMotion display, log performance issue
            logger.debug("Performance: Frame time \(String(format: "%.2f", deltaTime * 1000))ms (target: \(String(format: "%.2f", 1000.0 / Double(targetFrameRate)))ms)")
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