import SpriteKit
import GameplayKit

enum GamePhase {
    case tutorial
    case homeScreen
    case playing
    case gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    var player: PlayerEntity?
    var chaser: ChaserEntity?
    var gerobakIkan: SKSpriteNode?
    
    // This class will now handle all the spawning logic
    var worldGenerator: WorldGenerator?
    
    var backgrounds: [SKSpriteNode] = []
    private var backgroundView: BackgroundView?
    
    var swipeUpRecognizer: UISwipeGestureRecognizer?
    var swipeDownRecognizer: UISwipeGestureRecognizer?
    var panStartPoint: CGPoint?
    
    // Timers to implement cooldown
    var lastUpdateTime: TimeInterval = 0
    
    var scoreUpdateHandler: ((Int) -> Void)?
    var highscoreUpdateHandler: ((Int) -> Void)?
    var coinUpdateHandler: ((Int) -> Void)?
    var healthUpdateHandler: ((Int) -> Void)?
    var distanceUpdateHandler: ((Int) -> Void)?
    var gameStateUpdateHandler: ((GamePhase) -> Void)?
    
    private var scoreTimer: Timer?
    private var internalScore: Int = 0
    
    private static var isGamePaused: Bool = false
    
    private var lastDistanceBonusScore = 0
    private var lastSpeedFactor: Double = 1.0
    private var lastSpeedFactor2: Double = 1.0
    
    private var tutorialManager: TutorialManager?
    private(set) var gamePhase: GamePhase = .tutorial
    private static var isFirstLaunch = true
    private var tapToStartLabel: SKLabelNode?
    private var isWaitingForTapToStart = false
    
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
        isWaitingForTapToStart = true
        tapToStartLabel = SKLabelNode(text: "Tap to Start")
        tapToStartLabel?.fontSize = 42
        tapToStartLabel?.fontName = "AvenirNext-Bold"
        tapToStartLabel?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        tapToStartLabel?.fontColor = .white
        tapToStartLabel?.zPosition = 1000
        addChild(tapToStartLabel!)
        
        gamePhase = .homeScreen
        gameStateUpdateHandler?(gamePhase)
        
        createPlayer(x: 10)
        createChaser()

        // Wait for next frame so layout and textures are fully applied
        run(SKAction.wait(forDuration: 0.01)) { [weak self] in
            guard let self = self, let chaser = self.chaser else { return }
            let startXChaser = self.size.width * 0.15
            let startY = self.size.height*0.2
            chaser.position = CGPoint(x: startXChaser, y: startY)
        }

    }
    
    private func startGameAfterTap() {
        guard let player = player else { return }
        guard let chaser = chaser else { return }

        isWaitingForTapToStart = false
        tapToStartLabel?.removeFromParent()
        tapToStartLabel = nil

        // Disable constraints while animating
        player.constraints = nil

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

            self.setupGame() // Starts score and spawning logic
            
            removeGerobak()
        }
        
        let runAnimation = SKAction.run {
            player.startRunningAnimation()
        }
        
        // Step 5: Sequence it all together
        let fullSequence = SKAction.sequence([runAnimation, moveToStart, .wait(forDuration: 0.1), jump, makMarah, .wait(forDuration: 1), finalizeStart])
        player.run(fullSequence)
    }
    
    private func removeGerobak(){
        let move = SKAction.moveTo(x: -100, duration: 1)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([move, remove])
        gerobakIkan?.run(sequence)
    }
    
    private func setupProperties() {
        // Basic scene setup
        backgroundView = BackgroundView(scene: self)
        backgroundView?.setupScrollingBackground(imageNamed: "Background")
        //        backgroundView?.spawnRandomClouds()
        
        // Basic scene setup
        physicsWorld.gravity = CGVector(dx: 0, dy: customGravity)
        physicsWorld.contactDelegate = self
        
        let cameraNode = SKCameraNode()
        cameraNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        self.addChild(cameraNode)
        self.camera = cameraNode
        
        EffectsFactory.shared.initialize(with: self)
        
        worldGenerator = WorldGenerator(scene: self)
        playerData = SaveManager.shared.load()
        worldGenerator?.setupEnvironment() // This creates the ground
    }
    
    private func setupGame() {
        // Reset properties
        internalScore = 0
        lastDistanceBonusScore = 0
        gameSpeed = baseGameSpeed
        
        worldGenerator?.stopAllSpawning() // <-- STOPS spawning during tutorial
        
        if player == nil {
            createPlayer()
            player?.startRunningAnimation()
        }
        if chaser == nil {
            createChaser()
            chaser?.startRunningAnimation()
        }
        
        setupSwipeRecognizers()
        
        // This logic remains the same
        if playerData.isFirstTimeInstall {
            gamePhase = .tutorial
            gameStateUpdateHandler?(gamePhase)
            tutorialManager = TutorialManager(scene: self)
            tutorialManager?.start { [weak self] in
                self?.endTutorial()
            }
        } else {
            // This path is taken for both "Tap to Start" and "Restart"
            gamePhase = .playing
            gameStateUpdateHandler?(gamePhase)
            endTutorial() // This function now also starts the main game
        }
    }
    
    override func willMove(from view: SKView) {
        super.willMove(from: view)
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func appWillResignActive() {
        guard gamePhase == .playing || gamePhase == .tutorial else { return }
        
        print("App is resigning active, pausing game.")
        GameScene.isGamePaused = true
        // 1. Pause the game's internal logic.
        self.pauseGame()
        
        // 2. Broadcast the custom notification to anyone listening (like the GameView).
        NotificationCenter.default.post(name: .gameDidAutoPause, object: nil)
    }
    
    func endTutorial() {
        playerData.isFirstTimeInstall = false
        gamePhase = .playing
        gameStateUpdateHandler?(gamePhase)
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
            
            guard let self = self, !GameScene.isGamePaused && !self.isPaused, let player = self.player else { return }
            
            // **THE FIX**: Check both the static flag AND the scene's own isPaused property.
            // This is immune to the race condition.
            //            guard let self = self else { return }
            //            guard !GameScene.isGamePaused && !self.isPaused, let player = self.player else { return }
            
            self.internalScore += 1
            self.scoreUpdateHandler?(self.internalScore)
            
            if self.internalScore % 50 == 0 && self.internalScore > self.lastDistanceBonusScore {
                player.updateDistance(player.distance + 1)
                self.lastDistanceBonusScore = self.internalScore
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if GameScene.isGamePaused {
            // Immediately pause the game.
            self.pauseGame()
            return
        }
        guard gamePhase == .playing || gamePhase == .tutorial else { return }
        guard let player = player else { return }
        self.lastUpdateTime = currentTime
        
        // Update player state
        let currentSurface = getSurfaceType()
        player.updateState(currentSurface: currentSurface)
        
        backgroundView?.updateBackgroundPosition(gameSpeed: gameSpeed)
        
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
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        //        worldMoveDistance = self.size.width * 2
        guard gamePhase != .gameOver else { return }
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        // Delegate handling to specific functions based on the collision type
        if firstBody.categoryBitMask == PhysicsCategory.player {
            switch secondBody.categoryBitMask {
            case PhysicsCategory.projectile:
                handlePlayerProjectileContact(projectileBody: secondBody)
            case PhysicsCategory.obstacle:
                handlePlayerObstacleContact(obstacleBody: secondBody)
            case PhysicsCategory.coin, PhysicsCategory.powerUp, PhysicsCategory.catnip:
                handlePlayerCollectibleContact(collectibleBody: secondBody)
            default:
                break
            }
        }
    }
    
    private func handlePlayerProjectileContact(projectileBody: SKPhysicsBody) {
        guard let projectileNode = projectileBody.node, let player = self.player else { return }
        
        if gamePhase == .tutorial {
            tutorialManager?.playerDidFail()
            projectileNode.removeFromParent()
            return
        }
        
        // The player's internal logic will decide whether to take damage or knock it away.
        player.handleProjectileHit(projectileNode: projectileNode)
        
        // If the player took damage (i.e., was NOT invincible), the projectile is removed here.
        // If the player was invincible, the projectile is left in the scene to be knocked away.
        if !player.isInvincible {
            projectileNode.removeFromParent()
        }
        
        checkGameOver()
    }
    
    private func handlePlayerObstacleContact(obstacleBody: SKPhysicsBody) {
        guard let obstacleNode = obstacleBody.node, let player = self.player else { return }
        
        if gamePhase == .tutorial {
            tutorialManager?.playerDidFail()
            
            // We remove the obstacle that was hit to clean up the scene for the retry.
            obstacleNode.parent?.removeFromParent() // Use parent for complex obstacles
            obstacleNode.removeFromParent()
            
            // Return early to prevent the player from taking damage during the tutorial.
            return
        }
        
        var nodeToHandle: SKNode = obstacleNode
        
        // Determine the correct node to handle (the parent for complex obstacles)
        if obstacleNode.name == "damageZone", let parent = obstacleNode.parent as? Stepable {
            nodeToHandle = parent
        } else if obstacleNode.name == "collisionZone", let parent = obstacleNode.parent as? Duckable {
            nodeToHandle = parent
        }
        
        // The player's internal logic will decide what to do.
        player.handleObstacleHit(obstacleNode: nodeToHandle)
        
        // Only remove the node if the player was NOT invincible when the hit occurred.
        if !player.isInvincible {
            nodeToHandle.removeFromParent()
        }
        
        // **THE FIX**: Access player.hearts directly since we know player exists.
        healthUpdateHandler?(player.hearts)
        
        checkGameOver()
    }
    
    private func handlePlayerCollectibleContact(collectibleBody: SKPhysicsBody) {
        switch collectibleBody.categoryBitMask {
        case PhysicsCategory.coin:
            player?.coins += 1
            coinUpdateHandler?(player?.coins ?? 0)
            collectibleBody.node?.removeFromParent()
        case PhysicsCategory.powerUp:
            player?.applyPowerUp()
            collectibleBody.node?.removeFromParent()
        case PhysicsCategory.catnip:
            player?.applyCatnip()
            collectibleBody.node?.removeFromParent()
        default:
            break
        }
    }
    
    func checkGameOver() {
        guard let player = player else { return }
        if player.hearts <= 0 || player.distance <= 0 {
            gameOver()
        }
    }
    
    func restart() {
        self.removeAllChildren()
        
        player = nil
        chaser = nil

        scoreTimer?.invalidate()
        internalScore = 0
        scoreUpdateHandler?(internalScore)
        healthUpdateHandler?(9)
        distanceUpdateHandler?(3)
        
        setupProperties()
        setupGame()
        
        self.isPaused = false
        GameScene.isGamePaused = false
    }
    
    func gameOver() {
        guard !GameScene.isGamePaused else { return }
        GameScene.isGamePaused = true
        isPaused = true
        scoreTimer?.invalidate()
        scoreTimer = nil
        gamePhase = .gameOver
        gameStateUpdateHandler?(gamePhase)
        playerData.highScore = internalScore > playerData.highScore ? internalScore : playerData.highScore
        playerData.coins += player?.coins ?? 0
        highscoreUpdateHandler?(playerData.highScore)
        
        print(playerData.highScore)
        
        savePlayerData()
    }
    
    func returnToHomeScreen() {
        self.removeAllChildren()
        player = nil
        chaser = nil
        scoreTimer?.invalidate()
        internalScore = 0
        
        setupProperties()
        
        showTapToStart()
        
        self.isPaused = false
        GameScene.isGamePaused = false
    }
    
    func pauseGame() {
        GameScene.isGamePaused = true
        isPaused = true
        scoreTimer?.invalidate()
        scoreTimer = nil
    }
    
    func resumeGame() {
        guard GameScene.isGamePaused else { return }
        GameScene.isGamePaused = false
        isPaused = false
        startScoreTimer(resetScore: false)
    }
    
    func didEnd(_ contact: SKPhysicsContact) { }
    
    // MARK: - Player Creation
    func createPlayer(x: CGFloat = 200, y: CGFloat = 126) {
        let spawnPoint = CGPoint(x: x, y: y)
        player = PlayerEntity.create(at: spawnPoint)
        self.addChild(player!)
        player?.zPosition = 3
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
        chaser?.zPosition = 1
        
        let gerobakIkan = SKSpriteNode(imageNamed: "TokoIkan")
        gerobakIkan.position = CGPoint(x: 126, y: 135)
        gerobakIkan.setScale(0.2)
        gerobakIkan.zPosition = 2
        addChild(gerobakIkan)
        self.gerobakIkan = gerobakIkan
    }
    
    func updateSpawningIfNeeded() {
        let newFactor = Double(gameSpeed / baseGameSpeed)
        guard abs(newFactor - lastSpeedFactor) >= 0.3 else { return }
        
        lastSpeedFactor = newFactor
        print("current game speed: \(gameSpeed)")
        
        worldGenerator?.updateAllNodeSpeedsToMatchGameSpeed()
        worldGenerator?.stopAllSpawning()
        
        scene?.run(SKAction.sequence([
            SKAction.wait(forDuration: 2),
            SKAction.run { [weak self] in
                self?.worldGenerator?.startProceduralSpawning()
            }
        ]))
    }
    
    @objc private func savePlayerData() {
        SaveManager.shared.save(playerData)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        savePlayerData()
    }
}
