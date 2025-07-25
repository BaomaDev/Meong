import SpriteKit
import GameplayKit

<<<<<<< Updated upstream
=======
enum GamePhase {
    case tutorial
    case homeScreen
    case playing
    case gameOver
    case none
}

>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    
    // MARK: - Scene Lifecycle (Initializers)
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.1, alpha: 1.0)
=======
    private var lastSpeedFactor: Double = 1.0
    private var lastSpeedFactor2: Double = 1.0
    
    private var tutorialManager: TutorialManager?
    private(set) var gamePhase: GamePhase = .tutorial
    private static var isFirstLaunch = true
    private var tapToStartUI: SKLabelNode?
    private var titleUI: SKSpriteNode?
    private var isWaitingForTapToStart = false
    private var isWaitingForAnimationHome = true
    
    private var backgroundHome: SKSpriteNode?
    private var gerobakIkan: SKSpriteNode?
    
    private var playerData: PlayerData!
    
    // MARK: - Scene Lifecycle (Initializers)
    override func didMove(to view: SKView) {
        setupProperties()
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savePlayerData),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(savePlayerData),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 🔹 Preload background texture before setupGame
        let backgroundTexture = SKTexture(imageNamed: "Background")
        SKTexture.preload([backgroundTexture]) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if self.playerData.isFirstTimeInstall {
                    self.setupGame()
                } else {
                    self.camera?.position = CGPoint(x: self.size.width / 2, y: 1000)
                    self.backgroundColor = SKColor(
                        red: 191.0 / 255.0,
                        green: 226.0 / 255.0,
                        blue: 238.0 / 255.0,
                        alpha: 1.0
                    )
                    self.showTapToStart()
                }
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isWaitingForTapToStart {
            startGameAfterTap()
        }
    }
    
    func showTapToStart() {
        tapToStartUI = SKLabelNode(text: "Tap to Start")
        tapToStartUI?.fontSize = 38
        tapToStartUI?.fontName = "Comic Lemon"
        tapToStartUI?.position = CGPoint(x: size.width / 2, y: size.height * 0.05)
        tapToStartUI?.fontColor = .white
        tapToStartUI?.zPosition = 1000
        addChild(tapToStartUI!)
        
        titleUI = SKSpriteNode(imageNamed: "UI_Title")
        titleUI?.position = CGPoint(x: size.width / 2, y: 500)
        titleUI?.setScale(0.45)
        titleUI?.zPosition = 1000
        titleUI?.alpha = 0
        addChild(titleUI!)
        
        gamePhase = .none
        gameStateUpdateHandler?(gamePhase)
        
        let backgroundHome = SKSpriteNode(imageNamed: "Background_Home")
        backgroundHome.zPosition = -1
        backgroundHome.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(backgroundHome)
        self.backgroundHome = backgroundHome
        
        createPlayer(x: 10)
        createChaser()

        // Wait for next frame so layout and textures are fully applied
        run(SKAction.wait(forDuration: 0.01)) { [weak self] in
            guard let self = self, let chaser = self.chaser else { return }
            let startXChaser = self.size.width / 2
            let startY = self.size.height*0.2
            chaser.position = CGPoint(x: startXChaser, y: startY)
            gerobakIkan?.position.x = chaser.position.x
            player?.position.x = chaser.position.x - 120
            player?.constraints = nil
            
            if self.isWaitingForAnimationHome {
                let moveCamera = SKAction.moveTo(y: size.height / 2, duration: 3)
                self.camera?.run(moveCamera, completion: {
                    let moveTitle = SKAction.moveTo(y: self.size.height * 0.8, duration: 2)
                    let changeOpacityTitle = SKAction.fadeAlpha(to: 1.0, duration: 0.0)
                    let sequenceTitle = SKAction.sequence([changeOpacityTitle, moveTitle])
                    self.titleUI?.run(sequenceTitle)
                    self.titleUI?.run(moveTitle, completion: {
                        self.gamePhase = .homeScreen
                        self.gameStateUpdateHandler?(self.gamePhase)
                        let fadeIn = SKAction.fadeIn(withDuration: 3)
                        let fadeOut = SKAction.fadeOut(withDuration: 3)
                        let repeatAnimation = SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut]))
                        self.tapToStartUI?.run(repeatAnimation)
                        self.isWaitingForTapToStart = true
                    })
                })
            } else {
                self.gamePhase = .homeScreen
                self.gameStateUpdateHandler?(self.gamePhase)
                let fadeIn = SKAction.fadeIn(withDuration: 3)
                let fadeOut = SKAction.fadeOut(withDuration: 3)
                let repeatAnimation = SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut]))
                self.tapToStartUI?.run(repeatAnimation)
                self.titleUI?.alpha = 1.0
                self.titleUI?.position.y = self.size.height * 0.8
                self.camera?.position.y = self.size.height / 2
                self.isWaitingForTapToStart = true
            }
        }
    }
    
    private func startGameAfterTap() {
        guard let player = player else { return }
        guard let chaser = chaser else { return }

        isWaitingForTapToStart = false
        isWaitingForAnimationHome = false
        tapToStartUI?.removeFromParent()
        tapToStartUI = nil
        titleUI?.removeFromParent()
        titleUI = nil
        
        gamePhase = .none
        gameStateUpdateHandler?(gamePhase)
        
        //Move all to the far left
        let movePlayertoLeft = SKAction.moveTo(x: 10, duration: 1)
        movePlayertoLeft.timingMode = .easeInEaseOut
        let moveMaktoLeft = SKAction.moveTo(x: size.width * 0.15, duration: 1)
        moveMaktoLeft.timingMode = .easeInEaseOut
        let moveGerobaktoLeft = SKAction.moveTo(x: size.width * 0.15, duration: 1)
        moveGerobaktoLeft.timingMode = .easeInEaseOut
        let moveBackgroundtoLeft = SKAction.moveTo(x: size.width * 0.15, duration: 1)
        moveBackgroundtoLeft.timingMode = .easeInEaseOut
      
        let makMarah = SKAction.run {
            chaser.startIntroAnimation()
        }

        // Step 2: Move player slightly forward
        let moveToStart = SKAction.moveTo(x: 90, duration: 1)
        moveToStart.timingMode = .easeIn

        // Step 3: Bezier path animation (player jumping over the chaser)
        let path = UIBezierPath()
        let startPoint = CGPoint(x: 90, y: 125)
        let endPoint = CGPoint(x: 200, y: 125)
        let controlPoint = CGPoint(x: (90 + 200) / 2, y: 260)

        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)

        let jump = SKAction.follow(path.cgPath, asOffset: false, orientToPath: false, duration: 1)
        jump.timingMode = .easeInEaseOut

        // Step 4: Finalize game start
        let finalizeStart = SKAction.run { [weak self] in
            guard let self = self else { return }

            // Lock player in place to prevent drift
            let xConstraint = SKConstraint.positionX(SKRange(constantValue: 200))
            player.constraints = [xConstraint]

            // Change game state and start game logic
            self.gamePhase = .playing
            self.gameStateUpdateHandler?(self.gamePhase)

            chaser.startRunningAnimation() // Start chase animation now
            
            self.cleanupObjectHome()

            self.setupGame() // Starts score and spawning logic
        }
        
        let runAnimation = SKAction.run {
            player.startRunningAnimation()
        }

        // Step 5: Sequence it all together
        let fullSequence = SKAction.sequence([movePlayertoLeft, runAnimation, moveToStart, .wait(forDuration: 0.1), jump, makMarah, .wait(forDuration: 1), finalizeStart])
        chaser.run(moveMaktoLeft)
        backgroundHome?.run(moveBackgroundtoLeft)
        gerobakIkan?.run(moveGerobaktoLeft)
        player.run(fullSequence)
    }
    
    private func cleanupObjectHome(){
        let moveToLeft = SKAction.moveTo(x: -200, duration: 1.1)
        let moveToLeftBG = SKAction.moveTo(x: -500, duration: 2)
        let deleteObjects = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveToLeft, deleteObjects])
        let sequenceBG = SKAction.sequence([moveToLeftBG, deleteObjects])
        backgroundHome?.run(sequenceBG)
        gerobakIkan?.run(sequence)
    }
    
    private func setupProperties() {
        // Basic scene setup
        backgroundView = BackgroundView(scene: self)
        backgroundView?.setupScrollingBackground(imageNamed: "Background")
        //        backgroundView?.spawnRandomClouds()
        
        // Basic scene setup
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
=======
<<<<<<< HEAD
        
        print(player.currentState)
=======
//
//        print(player.currentState)
//        print(currentSurface)
>>>>>>> f9a713aabd4f63001ab37d230631d80ed40f21db
>>>>>>> Stashed changes
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
        player?.zPosition = 3
        self.addChild(player!)
    }
    
    // MARK: - Surface Detection
    func getSurfaceType(rayLength: CGFloat = 5) -> SurfaceType {
        guard let player = player else { return .none }
        
        let playerHeight = player.size.height
        let rayStart = player.position
        
        // The ray's end point is now calculated using the new parameter.
        let rayEnd = CGPoint(x: player.position.x, y: player.position.y - playerHeight / 2 - rayLength)
        
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
        chaser?.zPosition = 1
        
        let gerobakIkan = SKSpriteNode(imageNamed: "TokoIkan")
        gerobakIkan.setScale(0.2)
        gerobakIkan.position = chaser?.position ?? CGPoint.zero
        gerobakIkan.zPosition = 2
        self.gerobakIkan = gerobakIkan
        addChild(gerobakIkan)
    }

}
