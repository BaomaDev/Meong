import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    var player: PlayerEntity?
    var chaser: ChaserEntity?
    var backgrounds: [SKSpriteNode] = []
    
    var swipeUpRecognizer: UISwipeGestureRecognizer?
    var swipeDownRecognizer: UISwipeGestureRecognizer?
    
    // Timers to implement cooldown
    var lastUpdateTime: TimeInterval = 0
    
    // Score label
    var scoreLabel: SKLabelNode!
    private var scoreTimer: Timer?
    private var internalScore: Int = 0
    var coinCount = 0
    var health = 9
    
    var scoreUpdateHandler: ((Int) -> Void)?
    var coinUpdateHandler: ((Int) -> Void)?
    var healthUpdateHandler: ((Int) -> Void)?
    
    private var lastDistanceBonusScore = 0
    
    // MARK: - Scene Lifecycle (Initializers)
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: Constants.gravity)
        physicsWorld.contactDelegate = self
        
        // Setup backgrounds
        for i in 0..<2 {
            let background = SKSpriteNode(imageNamed: "background")
            background.name = "background"
            background.zPosition = -1
            background.size = size
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i) * size.width, y: 0)
            backgrounds.append(background)
            addChild(background)
        }

        createGround()
        startScoreTimer()
        createPlayer()
        setupSwipeRecognizers()
        startSpawningPlatforms()
        startSpawningProjectiles()
        startSpawningObstacles()
        startSpawningCoinsAndPowerUps()
    }
    
    func startScoreTimer() {
        scoreTimer?.invalidate()
        internalScore = 0
        
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.internalScore += 1
            self.scoreUpdateHandler?(self.internalScore)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        self.lastUpdateTime = currentTime
        
        // Scroll background
        for bg in backgrounds {
            bg.position.x -= 3.3
            if bg.position.x <= -bg.size.width {
                bg.position.x += bg.size.width * 2
            }
        }
        
        // Update player state
        if let player = player {
            let currentSurface = getSurfaceType()
            let velocity = player.physicsBody?.velocity ?? CGVector.zero
            player.updateState(surfaceType: currentSurface, velocity: velocity)
        }
        
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
        
        self.enumerateChildNodes(withName: "Stepable") { (node, stop) in
            if node.position.x < -50 {
                node.removeFromParent()
            }
        }
        
        self.enumerateChildNodes(withName: "Moving") { (node, stop) in
            if node.position.x < -50 {
                node.removeFromParent()
            }
        }
        
        self.enumerateChildNodes(withName: "Duckable") { (node, stop) in
            if node.position.x < -50 {
                node.removeFromParent()
            }
        }
    }

    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
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
            
            coinCount += 1
            coinUpdateHandler?(coinCount)
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
        print("Matek")
        scoreTimer?.invalidate()
        internalScore = 0
        coinCount = 0
        health = 9
        
        scoreUpdateHandler?(internalScore)
        coinUpdateHandler?(coinCount)
        healthUpdateHandler?(health)

        let newScene = GameScene(size: self.size)
        newScene.scaleMode = self.scaleMode
        
        newScene.scoreUpdateHandler = self.scoreUpdateHandler
        newScene.coinUpdateHandler = self.coinUpdateHandler
        newScene.healthUpdateHandler = self.healthUpdateHandler

        let transition = SKTransition.fade(withDuration: 0.5)
        self.view?.presentScene(newScene, transition: transition)
    }
    
    func didEnd(_ contact: SKPhysicsContact) { }
    
    // MARK: - Player Creation
    func createPlayer() {
        let spawnPoint = CGPoint(x: 150, y: 80)
        player = PlayerEntity(position: spawnPoint)
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
