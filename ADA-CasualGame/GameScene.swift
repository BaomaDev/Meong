import SpriteKit
import GameplayKit

enum GamePhase {
    case tutorial
    case playing
    case gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    var player: PlayerEntity?
    var chaser: ChaserEntity?
    
    // This class will now handle all the spawning logic
    var worldGenerator: WorldGenerator?

    var backgrounds: [SKSpriteNode] = []
    
    var swipeUpRecognizer: UISwipeGestureRecognizer?
    var swipeDownRecognizer: UISwipeGestureRecognizer?
    var panStartPoint: CGPoint?
    
    // Timers to implement cooldown
    var lastUpdateTime: TimeInterval = 0
    
    var scoreUpdateHandler: ((Int) -> Void)?
    var coinUpdateHandler: ((Int) -> Void)?
    var healthUpdateHandler: ((Int) -> Void)?
    var distanceUpdateHandler: ((Int) -> Void)?

    private var scoreTimer: Timer?
    private var internalScore: Int = 0
    
    private var isGamePaused: Bool = false  // 👈 new flag
    
    private var lastDistanceBonusScore = 0
    private var lastSpeedFactor: Double = 1.0
    
    private var tutorialManager: TutorialManager?
    private(set) var gamePhase: GamePhase = .tutorial
    private static var isFirstLaunch = true
    
    // MARK: - Scene Lifecycle (Initializers)
    override func didMove(to view: SKView) {
        setupGame()
    }
    
    private func setupGame() {
        // Reset properties
        internalScore = 0
        lastDistanceBonusScore = 0
        gameSpeed = baseGameSpeed
        
        // Basic scene setup
        backgroundColor = SKColor(white: 0.2, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: customGravity)
        physicsWorld.contactDelegate = self
        
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        self.addChild(cameraNode)
        self.camera = cameraNode
        
        EffectsFactory.shared.initialize(with: self)
        
        worldGenerator = WorldGenerator(scene: self)
        worldGenerator?.setupEnvironment() // This creates the ground and starts spawning
        
        createPlayer()
        createChaser()
        setupSwipeRecognizers()
        
        // 4. ADD THIS LOGIC TO START THE TUTORIAL OR THE GAME
        if GameScene.isFirstLaunch {
            gamePhase = .tutorial
            worldGenerator?.stopAllSpawning() // <-- STOPS spawning during tutorial
            GameScene.isFirstLaunch = false // Ensure tutorial only runs once
            
            tutorialManager = TutorialManager(scene: self)
            // The tutorial manager will call endTutorial when it's done
            tutorialManager?.start { [weak self] in
                self?.endTutorial()
            }
        } else {
            // If not the first launch, start the game directly
            gamePhase = .playing
            endTutorial() // This function now also starts the main game
        }
    }
    
    func endTutorial() {
        gamePhase = .playing
        worldGenerator?.startProceduralSpawning()
        startScoreTimer()
    }
    
    func startScoreTimer(resetScore: Bool = false) {
        scoreTimer?.invalidate()  // always clean up existing timer

        if resetScore {
            internalScore = 0
            lastDistanceBonusScore = 0
        }

        scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.isGamePaused, let player = self.player else { return }

            self.internalScore += 1
            self.scoreUpdateHandler?(self.internalScore)

            if self.internalScore % 50 == 0 && self.internalScore > self.lastDistanceBonusScore {
                player.updateDistance(player.distance + 1)
                self.lastDistanceBonusScore = self.internalScore
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let player = player else { return }
        self.lastUpdateTime = currentTime
        
        // Update player state
        let currentSurface = getSurfaceType()
        player.updateState(currentSurface: currentSurface)
        
        guard gamePhase == .playing else { return }
        
        // Remove projectiles that are off screen
        self.enumerateChildNodes(withName: "Projectile") { (node, stop) in
            if node.position.x < -50 || node.position.y < -50 {
                node.removeFromParent()
            }
        }
        
        self.enumerateChildNodes(withName: "NoTouch") { (node, stop) in
            if node.position.x < -50 {
                node.removeFromParent()
            }
        }
        
        let speedIncrement = 40.0
        let calculatedGameSpeed = baseGameSpeed + speedIncrement * max(Double(internalScore) / speedScalingFactor, 1.0)
        gameSpeed = min(calculatedGameSpeed, maxGameSpeed)
        updateSpawningIfNeeded()
        
        if let chaser = chaser {
            chaser.updateFollowPosition()
        }
        
//        for background in backgrounds {
//            background.position.x -= CGFloat(gameSpeed * 0.016)  // adjust multiplier to your scroll speed
//
//            if background.position.x <= -background.size.width {
//                background.position.x += background.size.width * 2
//            }
//        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
//        worldMoveDistance = self.size.width * 2
        guard gamePhase == .playing else { return }
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        // Order the bodies by their category bitmask for consistent checks
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Check for collision between player and projectile
        if firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.projectile {
            player?.handleProjectileHit()
            secondBody.node?.removeFromParent()
            checkGameOver()
        }
        
        // Check for collision between player and obstacle
        if firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.obstacle {
            // Check what type of obstacle zone was hit
            if let obstacleNode = secondBody.node {
                if obstacleNode.name == "damageZone" {
                    // This is a damage zone from stepable obstacle
                    if let parentStepable = obstacleNode.parent as? Stepable {
                        player?.handleObstacleHit()
                        parentStepable.removeFromParent() // Remove the entire stepable obstacle
                        
                        // ✅ Notify UI about health change
                        if let updatedHealth = player?.hearts {
                            print("Health decreased to: \(updatedHealth)")
                            healthUpdateHandler?(updatedHealth)
                        }

                        checkGameOver()
                    }
                } else if obstacleNode.name == "collisionZone" {
                    // This is a collision zone from duckable obstacle
                    if let parentDuckable = obstacleNode.parent as? Duckable {
                        player?.handleObstacleHit()
                        parentDuckable.removeFromParent() // Remove the entire duckable obstacle
                        
                        // ✅ Notify UI about health change
                        if let updatedHealth = player?.hearts {
                            print("Health decreased to: \(updatedHealth)")
                            healthUpdateHandler?(updatedHealth)
                        }

                        checkGameOver()
                    }
                } else {
                    // This is a regular obstacle (like NoTouch)
                    player?.handleObstacleHit()
                    secondBody.node?.removeFromParent()
                    
                    // ✅ Notify UI about health change
                    if let updatedHealth = player?.hearts {
                        print("Health decreased to: \(updatedHealth)")
                        healthUpdateHandler?(updatedHealth)
                    }
                    checkGameOver()
                }
            }
        }
        
        // MARK: - Character and Coin Contact
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.coin) ||
            (firstBody.categoryBitMask == PhysicsCategory.coin && secondBody.categoryBitMask == PhysicsCategory.player) {
            
            let coinBody = firstBody.categoryBitMask == PhysicsCategory.coin ? firstBody : secondBody
            coinBody.node?.removeFromParent()
            
            player?.coins += 1
            coinUpdateHandler?(player?.coins ?? 0)
        }
        
        // MARK: - Character and Power-Up Contact
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.powerUp) ||
            (firstBody.categoryBitMask == PhysicsCategory.powerUp && secondBody.categoryBitMask == PhysicsCategory.player) {
            let powerUpNode = firstBody.categoryBitMask == PhysicsCategory.powerUp ? firstBody.node : secondBody.node
            powerUpNode?.removeFromParent()
            
            player?.applyPowerUp()
        }
        
        if (firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.catnip) ||
            (firstBody.categoryBitMask == PhysicsCategory.catnip && secondBody.categoryBitMask == PhysicsCategory.player) {
            let catnipNode = firstBody.categoryBitMask == PhysicsCategory.catnip ? firstBody.node : secondBody.node
            catnipNode?.removeFromParent()
            
            player?.applyCatnip()
        }
    }
    
    func checkGameOver() {
        guard let player = player else { return }
        if player.hearts <= 0 || player.distance <= 0 {
            gameOver()
        }
    }
    
    func gameOver() {
        gamePhase = .gameOver
        
        // 1. Clear all nodes from the previous game (player, platforms, etc.).
        self.removeAllChildren()
        
        // 2. Reset the score and update the HUD.
        scoreTimer?.invalidate()
        internalScore = 0
        // You might not need to reset these if createPlayer() does it, but it's safe to do so.
        player?.coins = 0
        player?.hearts = 9
        player?.distance = 3
        
        scoreUpdateHandler?(internalScore)
        coinUpdateHandler?(player?.coins ?? 0)
        healthUpdateHandler?(player?.hearts ?? 9)
        distanceUpdateHandler?(player?.distance ?? 3)
        
        // 3. Call the setup function to rebuild and restart the game.
        setupGame()
        
        // 4. Ensure the game is unpaused.
        self.isPaused = false
        self.isGamePaused = false
    }
    
    func pauseGame() {
        guard !isGamePaused else { return }
        isGamePaused = true
        isPaused = true
        scoreTimer?.invalidate()
        scoreTimer = nil
    }

    func resumeGame() {
        guard isGamePaused else { return }
        isGamePaused = false
        isPaused = false
        startScoreTimer(resetScore: false)
    }
    
    func didEnd(_ contact: SKPhysicsContact) { }
    
    // MARK: - Player Creation
    func createPlayer() {
        let spawnPoint = CGPoint(x: 200, y: 125)
        player = PlayerEntity.create(at: spawnPoint)
        self.addChild(player!)
    }
    
    // MARK: - Surface Detection
    func getSurfaceType() -> SurfaceType {
        guard let player = player else { return .none }
        
        let playerHeight = player.size.height
        let rayStart = player.position
        let rayEnd = CGPoint(x: player.position.x, y: player.position.y - playerHeight / 2 - 5)
        
        var surfaceType: SurfaceType = .none
        physicsWorld.enumerateBodies(alongRayStart: rayStart, end: rayEnd) { (body, point, normal, stop) in
            let category = body.categoryBitMask
            if category == PhysicsCategory.ground {
                surfaceType = .ground
                stop.pointee = true
            } else if category == PhysicsCategory.semiSolidPlatform {
                surfaceType = .semiSolidPlatform
                stop.pointee = true
            } else if category == PhysicsCategory.solidPlatform {
                surfaceType = .solidPlatform
                stop.pointee = true
            }
        }
        return surfaceType
    }
    func createChaser() {
        guard let player = player else { return }
        let chaserNode = ChaserEntity(player: player)
        addChild(chaserNode)
        chaser = chaserNode
    }

    func updateSpawningIfNeeded() {
        let newFactor = Double(gameSpeed / baseGameSpeed)
        guard abs(newFactor - lastSpeedFactor) >= 0.3 else { return }
        
        lastSpeedFactor = newFactor
        print("current game speed: \(gameSpeed)")
        
        worldGenerator?.stopAllSpawning()
        worldGenerator?.updateAllNodeSpeedsToMatchGameSpeed()
        
        scene?.run(SKAction.sequence([
            SKAction.wait(forDuration: 1.5),
                SKAction.run { [weak self] in
                    self?.worldGenerator?.startProceduralSpawning()
                }
            ]))
    }
    
//    func setupScrollingBackground(imageNamed: String) {
//        let texture = SKTexture(imageNamed: imageNamed)
//
//        for i in 0..<2 {
//            let background = SKSpriteNode(texture: texture)
//            background.anchorPoint = .zero
//
//            // Scale the height proportionally to scene height
//            let scale = self.size.height / texture.size().height
//            background.size = CGSize(
//                width: texture.size().width * scale,
//                height: self.size.height
//            )
//
//            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
//            background.zPosition = -1
//            background.name = "scrollingBackground"
//            addChild(background)
//            backgrounds.append(background)
//        }
//    }
}
