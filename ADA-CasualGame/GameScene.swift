import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    var player: PlayerEntity?
    var chaser: SKSpriteNode?
    
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
    
    private var lastDistanceBonusScore = 0
    
    // MARK: - Scene Lifecycle (Initializers)
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.1, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: customGravity)
        physicsWorld.contactDelegate = self
        
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        self.addChild(cameraNode)
        self.camera = cameraNode
        
        EffectsFactory.shared.initialize(with: self)
        
        // Initialize and set up the world using the generator
        worldGenerator = WorldGenerator(scene: self)
        worldGenerator?.setupEnvironment()
        
        startScoreTimer()
        createPlayer()
        setupSwipeRecognizers()
        createChaser()
    }
    
    func startScoreTimer() {
        scoreTimer?.invalidate()
        internalScore = 0
        lastDistanceBonusScore = 0
        
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            
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
        
        //        print("player state: \(String(describing: player.currentState))")
        
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
//        print("current game speed: \(gameSpeed)")
        
        if let chaser = chaser {
            let followDistance = CGFloat(player.distance) * 40.0 // Adjust multiplier as needed
            let targetX = player.position.x - followDistance
            let targetY = player.position.y

            let currentPosition = chaser.position
            let lerpFactor: CGFloat = 0.05 // Smooth following
            let newX = currentPosition.x + (targetX - currentPosition.x) * lerpFactor
            let newY = currentPosition.y + (targetY - currentPosition.y) * lerpFactor

            chaser.position = CGPoint(x: newX, y: newY)
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
//        worldMoveDistance = self.size.width * 2
        
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
    }
    
    func checkGameOver() {
        guard let player = player else { return }
        if player.hearts <= 0 || player.distance <= 0 {
            gameOver()
        }
    }
    
    func gameOver() {
        //        print("Matek")
        scoreTimer?.invalidate()
        internalScore = 0
        player?.coins = 0
        player?.hearts = 9
        player?.distance = 3
        
        scoreUpdateHandler?(internalScore)
        coinUpdateHandler?(player?.coins ?? 0)
        healthUpdateHandler?(player?.hearts ?? 9)
        distanceUpdateHandler?(player?.distance ?? 3)
        
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode

        // ✅ Pass current update handlers to the new scene
        newScene.scoreUpdateHandler = self.scoreUpdateHandler
        newScene.coinUpdateHandler = self.coinUpdateHandler
        newScene.healthUpdateHandler = self.healthUpdateHandler
        newScene.distanceUpdateHandler = self.distanceUpdateHandler
        
        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(newScene, transition: transition)
    }
    
    func didEnd(_ contact: SKPhysicsContact) { }
    
    // MARK: - Player Creation
    func createPlayer() {
        let spawnPoint = CGPoint(x: 150, y: 125)
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
        let texture = SKTexture(imageNamed: "akmal")
        let chaserNode = SKSpriteNode(texture: texture)
        chaserNode.name = "Chaser"
        chaserNode.zPosition = 1
        chaserNode.size = CGSize(width: 80, height: 80) // Adjust as needed

        if let player = player {
            let initialDistance = max(CGFloat(player.distance) * 40.0, 800) // Increased multiplier and fallback
            chaserNode.position = CGPoint(x: player.position.x - initialDistance, y: player.position.y)
        }

        addChild(chaserNode)
        chaser = chaserNode
    }

}
