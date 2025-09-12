import UIKit
import SpriteKit
import GameplayKit
import os.log

class GameViewController: UIViewController {
    private let logger = Logger(subsystem: "com.example.BlockPuzzlePro", category: "GameViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logger.info("GameViewController loading")
        
        if let view = self.view as! SKView? {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                
                // Present the scene
                view.presentScene(scene)
            }
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
        
        setupPortraitOrientation()
        setupAppLifecycleObservers()
    }
    
    private func setupPortraitOrientation() {
        // Force portrait orientation
        if #available(iOS 16.0, *) {
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        logger.info("GameViewController will appear")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        logger.info("GameViewController did appear")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        logger.info("GameViewController will disappear - pausing game")
        
        // Pause the SpriteKit scene when going to background
        pauseGame()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        logger.info("GameViewController did disappear")
    }
    
    // MARK: - Game State Management
    
    private func pauseGame() {
        if let view = self.view as? SKView {
            view.isPaused = true
            logger.info("Game paused - SpriteKit view paused")
        }
    }
    
    private func resumeGame() {
        if let view = self.view as? SKView {
            view.isPaused = false
            logger.info("Game resumed - SpriteKit view resumed")
        }
    }
    
    // MARK: - App Lifecycle Integration
    
    private func setupAppLifecycleObservers() {
        // Listen for app background/foreground events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        logger.info("GameViewController responding to app entering background")
        pauseGame()
    }
    
    @objc private func appWillEnterForeground() {
        logger.info("GameViewController responding to app entering foreground")
        // Note: Don't resume yet, wait for didBecomeActive
    }
    
    @objc private func appDidBecomeActive() {
        logger.info("GameViewController responding to app becoming active")
        resumeGame()
    }
    
    @objc private func appWillResignActive() {
        logger.info("GameViewController responding to app resigning active")
        pauseGame()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        logger.info("GameViewController deinitialized")
    }
}