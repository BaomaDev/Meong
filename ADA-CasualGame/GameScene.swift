import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    var player: PlayerEntity?
    var backgrounds: [SKSpriteNode] = []
    
    var swipeUpRecognizer: UISwipeGestureRecognizer?
    var swipeDownRecognizer: UISwipeGestureRecognizer?
    
    // Timers to implement cooldown
    var lastUpdateTime: TimeInterval = 0
    
    var heartLabel: SKLabelNode!
    var distanceLabel: SKLabelNode!
    var coinLabel: SKLabelNode!
    
    // Score label
    var scoreLabel: SKLabelNode!
    private var scoreTimer: Timer?
    private var internalScore: Int = 0
    
    private var lastDistanceBonusScore = 0
    
    // MARK: - Scene Lifecycle (Initializers)
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.1, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: customGravity)
        physicsWorld.contactDelegate = self
        
        createGround()
        setupHUD()
        startScoreTimer()
        createPlayer()
        setupSwipeRecognizers()
        startSpawningPlatforms()
        startSpawningProjectiles()
        startSpawningObstacles()
        startSpawningCoinsAndPowerUps()
        //        startSpawningObstacles(in: self)
    }
    
    func setupHUD() {
        heartLabel = SKLabelNode(text: "❤️: \(player?.hearts ?? 0)")
        heartLabel.fontSize = 20
        heartLabel.position = CGPoint(x: 80, y: size.height - 50)
        heartLabel.zPosition = 100
        addChild(heartLabel)
        
        distanceLabel = SKLabelNode(text: "📏: \(player?.distance ?? 0)m")
        distanceLabel.fontSize = 20
        distanceLabel.position = CGPoint(x: 250, y: size.height - 50)
        distanceLabel.zPosition = 100
        addChild(distanceLabel)
        
        coinLabel = SKLabelNode(text: "💰: \(player?.coins ?? 0)")
        coinLabel.fontSize = 20
        coinLabel.position = CGPoint(x: size.width - 300, y: size.height - 50)
        coinLabel.zPosition = 100
        addChild(coinLabel)
        
        scoreLabel = SKLabelNode(text: "🏆: 0")
        scoreLabel.fontSize = 20
        scoreLabel.position = CGPoint(x: size.width - 100, y: size.height - 50)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
    }
    
    func startScoreTimer() {
        scoreTimer?.invalidate()
        internalScore = 0
        lastDistanceBonusScore = 0
        
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.player else { return }
            
            self.internalScore += 1
            self.scoreLabel.text = "🏆: \(self.internalScore)"
            
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
        
        heartLabel?.text = "❤️ : \(player.hearts)"
        distanceLabel?.text = "📏 : \(player.distance)m"
        coinLabel?.text = "💰 : \(player.coins)"
        
        // as player gets further, scaling factor gets higher (speed increase gets more gradual)
        if gameSpeed > 400 {
            speedScalingFactor = 6.0
        } else if gameSpeed > 600 {
            speedScalingFactor = 9.0
        }
        
        let calculatedGameSpeed = 300 + 10 * Double(internalScore) / speedScalingFactor
        gameSpeed = min(calculatedGameSpeed, 800.0)
        //        print("current game speed: \(Constants.gameSpeed)")
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
                        checkGameOver()
                    }
                } else if obstacleNode.name == "collisionZone" {
                    // This is a collision zone from duckable obstacle
                    if let parentDuckable = obstacleNode.parent as? Duckable {
                        player?.handleObstacleHit()
                        parentDuckable.removeFromParent() // Remove the entire duckable obstacle
                        checkGameOver()
                    }
                } else {
                    // This is a regular obstacle (like NoTouch)
                    player?.handleObstacleHit()
                    secondBody.node?.removeFromParent()
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
        
        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        
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
}
