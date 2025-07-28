import SpriteKit
import GameplayKit

enum GamePhase {
    case tutorial
    case homeScreen
    case playing
    case gameOver
    case none
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    var player: PlayerEntity?
    var chaser: ChaserEntity?
    
    // This class will now handle all the spawning logic
    var worldGenerator: WorldGenerator?
    
    var backgrounds: [SKSpriteNode] = []
    private var backgroundView: BackgroundView?
    
    var swipeUpRecognizer: UISwipeGestureRecognizer?
    var swipeDownRecognizer: UISwipeGestureRecognizer?
    var panStartPoint: CGPoint?
    
    // Timers to implement cooldown
    var lastUpdateTime: TimeInterval = 0
    
    
    // MARK: - Handler
    var scoreUpdateHandler: ((Int) -> Void)?
    var highscoreUpdateHandler: ((Int) -> Void)?
    var coinUpdateHandler: ((Int) -> Void)?
    var healthUpdateHandler: ((Int) -> Void)?
    var distanceUpdateHandler: ((Int) -> Void)?
    var gameStateUpdateHandler: ((GamePhase) -> Void)?
    var costumePurchasedHandler:  (([String]) -> Void)?
    var selectedCostumeHandler:  ((String) -> Void)?
    
    private var scoreTimer: Timer?
    private var internalScore: Int = 0
    
    private static var isGamePaused: Bool = false
    
    private var lastDistanceBonusScore = 0
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
        if isWaitingForTapToStart && !isWaitingForAnimationHome {
            startGameAfterTap()
        }
    }
    
    func showTapToStart() {
        // <<<<<<< derend3
        internalScore = 0
        lastDistanceBonusScore = 0
        scoreUpdateHandler?(internalScore)
        healthUpdateHandler?(9)
        distanceUpdateHandler?(3)
        coinUpdateHandler?(0)
        gameSpeed = baseGameSpeed
        
        EffectsFactory.shared.playBgm(named: "BGM", isMainTrack: true)
        EffectsFactory.shared.refreshBgmVolume(volume: playerData.bgmVolume)
        
        worldGenerator?.stopAllSpawning()
        isWaitingForTapToStart = true
        
        // MARK: - Tap to Start Label (Text-based)
        // Shadow label
        let shadowLabel = SKLabelNode(text: "Tap to Start")
        shadowLabel.name = "TapToStartShadowLabel"
        shadowLabel.fontSize = 32
        shadowLabel.fontName = "Comic Lemon"
        shadowLabel.fontColor = SKColor.black.withAlphaComponent(0.5)
        shadowLabel.position = CGPoint(x: size.width / 2 + 2, y: (size.height / 2) - 2)
        shadowLabel.zPosition = 999 // Behind the main label
        addChild(shadowLabel)
        
        // Main label
        let label = SKLabelNode(text: "Tap to Start")
        label.fontSize = 32
        label.fontName = "Comic Lemon"
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: (size.height / 2))
        label.zPosition = 1000
        label.name = "TapToStartLabel"
        addChild(label)
        tapToStartUI = nil
        
        // MARK: - Title UI (Still using image)
        titleUI = SKSpriteNode(imageNamed: "UI_Title")
        titleUI?.position = CGPoint(x: size.width / 2, y: size.height * 0.8)
        titleUI?.setScale(0.3)
        titleUI?.zPosition = 1000
        titleUI?.alpha = 0
        addChild(titleUI!)
        
        gamePhase = .none
        gameStateUpdateHandler?(gamePhase)
        
        let backgroundHome = SKSpriteNode(imageNamed: "Background_Home")
        backgroundHome.zPosition = -1
        backgroundHome.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundHome.size = size
        addChild(backgroundHome)
        self.backgroundHome = backgroundHome
        
        createPlayer(x: 10)
        createChaser()
        
        // MARK: - Gerobak Ikan
        let gerobakIkan = SKSpriteNode(imageNamed: "TokoIkan")
        gerobakIkan.position = CGPoint(x: 126, y: 137)
        gerobakIkan.setScale(0.18)
        gerobakIkan.zPosition = 2
        addChild(gerobakIkan)
        self.gerobakIkan = gerobakIkan
        
        // MARK: - Finalize layout after frame update
        run(SKAction.wait(forDuration: 0.01)) { [weak self] in
            guard let self = self, let chaser = self.chaser else { return }
            let startXChaser = self.size.width / 2
            let startY = self.size.height * 0.2
            chaser.position = CGPoint(x: startXChaser, y: startY)
            chaser.startIntroAnimation()
            
            gerobakIkan.position.x = chaser.position.x
            player?.position.x = chaser.position.x - 120
            player?.startIdleAnimation()
            player?.constraints = nil
            
            if self.isWaitingForAnimationHome {
                let moveCamera = SKAction.moveTo(y: size.height / 2, duration: 3)
                self.camera?.run(moveCamera, completion: {
                    let moveTitle = SKAction.moveTo(y: self.size.height * 0.8, duration: 2)
                    let changeOpacityTitle = SKAction.fadeAlpha(to: 1.0, duration: 1.0)
                    let sequenceTitle = SKAction.sequence([changeOpacityTitle, moveTitle, .wait(forDuration: 2)])
                    self.titleUI?.run(sequenceTitle)
                    self.titleUI?.run(moveTitle, completion: {
                        let fadeInOut = SKAction.sequence([
                            SKAction.fadeAlpha(to: 0.4, duration: 0.8),
                            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
                        ])
                        label.run(SKAction.repeatForever(fadeInOut))
                        let fadeIn = SKAction.fadeIn(withDuration: 3)
                        let fadeOut = SKAction.fadeOut(withDuration: 3)
                        let repeatAnimation = SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut]))
                        self.tapToStartUI?.run(repeatAnimation)
                        self.gamePhase = .homeScreen
                        self.gameStateUpdateHandler?(self.gamePhase)
                        self.run(SKAction.wait(forDuration: 1)) {
                            self.isWaitingForAnimationHome = false
                            self.isWaitingForTapToStart = true
                        }
                    })
                })
            } else {
                self.titleUI?.alpha = 1.0
                self.titleUI?.position.y = self.size.height * 0.8
                self.camera?.position.y = self.size.height / 2
                let fadeInOut = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.4, duration: 0.8),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.8)
                ])
                label.run(SKAction.repeatForever(fadeInOut))
                
                let fadeIn = SKAction.fadeIn(withDuration: 3)
                let fadeOut = SKAction.fadeOut(withDuration: 3)
                let repeatAnimation = SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut]))
                self.tapToStartUI?.run(repeatAnimation)
                self.gamePhase = .homeScreen
                self.gameStateUpdateHandler?(self.gamePhase)
                self.run(SKAction.wait(forDuration: 1)) {
                    self.isWaitingForAnimationHome = false
                    self.isWaitingForTapToStart = true
                }
            }
        }
    }
    
    private func startGameAfterTap() {
        guard let player = player else { return }
        guard let chaser = chaser else { return }
        guard gamePhase == .homeScreen else { return }
        
        gamePhase = .none
        gameStateUpdateHandler?(gamePhase)
        
        guard !isWaitingForAnimationHome && isWaitingForTapToStart else { return }
        
        isWaitingForTapToStart = false
        
        // Step 1: Intro animation before jump
        let startIntro = SKAction.run {
            player.startIntroAnimation()
            chaser.startIntroAnimation()
        }
        
        childNode(withName: "TapToStartLabel")?.removeFromParent()
        childNode(withName: "TapToStartShadowLabel")?.removeFromParent()
        
        titleUI?.removeFromParent()
        
        //Move all to the far left
        let movePlayertoLeft = SKAction.moveTo(x: 10, duration: 1)
        movePlayertoLeft.timingMode = .easeInEaseOut
        let moveMaktoLeft = SKAction.moveTo(x: size.width * 0.15, duration: 1)
        moveMaktoLeft.timingMode = .easeInEaseOut
        let moveGerobaktoLeft = SKAction.moveTo(x: size.width * 0.15, duration: 1)
        moveGerobaktoLeft.timingMode = .easeInEaseOut
        let moveBackgroundtoLeft = SKAction.moveTo(x: size.width * 0.15, duration: 1)
        moveBackgroundtoLeft.timingMode = .easeInEaseOut
        
        //After position changed to far left
        let startStealingDuringJump = SKAction.run {
            player.startStealingAnimation()
            EffectsFactory.shared.playSound(soundKey: "munch.mp3")
        }
        
        let makMarah = SKAction.run {
            chaser.startIntroAnimation()
        }
        
        // Step 2: Move player slightly forward
        let moveToStart = SKAction.moveTo(x: 90, duration: 0.5)
        moveToStart.timingMode = .easeIn
        
        // Step 3: Bezier path animation (player jumping over the chaser)
        let path = UIBezierPath()
        let startPoint = CGPoint(x: 90, y: player.position.y)
        let endPoint = CGPoint(x: 200, y: player.position.y)
        let controlPoint = CGPoint(x: (startPoint.x + endPoint.x)/2, y: player.position.y + 160)
        
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        
        let jump = SKAction.follow(path.cgPath, asOffset: false, orientToPath: false, duration: 0.7)
        jump.timingMode = .easeInEaseOut
        
        // Step 4: After intro + jump, switch to running
        let startRunning = SKAction.run {
            player.startRunningAnimation()
            chaser.startRunningAnimation()
        }
        
        let finalizeStart = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            EffectsFactory.shared.playBgm(named: "bgmtest", isMainTrack: true)
            
            // Lock player in place to prevent drift
            let xConstraint = SKConstraint.positionX(SKRange(constantValue: 200))
            player.constraints = [xConstraint]
            
            // Change game state and start game logic
            self.gamePhase = .playing
            self.gameStateUpdateHandler?(self.gamePhase)
            //             chaser.startRunningAnimation() // Start chase animation now
            
            self.cleanupObjectHome()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setupGame()
            }
        }
        
        let runAnimation = SKAction.run {
            player.startIntroAnimation()
        }
        
        // Step 5: Sequence it all together
        let fullSequence = SKAction.sequence([
            movePlayertoLeft,
            startIntro,
            .wait(forDuration: 0.001),
            runAnimation,
            moveToStart,
            .wait(forDuration: 0.001),
            startStealingDuringJump,
            jump,
            makMarah,
            .wait(forDuration: 0.001),
            startRunning,
            finalizeStart
        ])
        //         let fullSequence = SKAction.sequence([movePlayertoLeft, runAnimation, moveToStart, .wait(forDuration: 0.1), jump, makMarah, .wait(forDuration: 1), finalizeStart])
        
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
        
        EffectsFactory.shared.setBgmVolume(playerData.bgmVolume)
    }
    
    private func setupGame() {
        // Reset properties
        internalScore = 0
        lastDistanceBonusScore = 0
        scoreUpdateHandler?(internalScore)
        healthUpdateHandler?(9)
        distanceUpdateHandler?(3)
        coinUpdateHandler?(0)
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
        isWaitingForAnimationHome = false
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
        //
        //        print(player.currentState)
        //        print(currentSurface)
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
            player?.takeCoin()
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
        guard gamePhase == .playing else { return }
        
        if player.hearts <= 0 || player.distance <= 0 {
            // Trigger final catch-up animation
            startChaserCatchupSequence()
        }
    }
    
    
    func restart() {
        self.isPaused = false
        GameScene.isGamePaused = false
        for child in self.children {
            if child.name != "background_music_node" {
                child.removeFromParent()
            }
        }
        
        player = nil
        chaser = nil
        
        scoreTimer?.invalidate()
        internalScore = 0
        scoreUpdateHandler?(internalScore)
        healthUpdateHandler?(9)
        distanceUpdateHandler?(3)
        coinUpdateHandler?(0)
        
        setupProperties()
        setupGame()
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
        self.isPaused = false
        GameScene.isGamePaused = false
        for child in self.children {
            if child.name != "background_music_node" {
                child.removeFromParent()
            }
        }

        player = nil
        chaser = nil
        scoreTimer?.invalidate()
        internalScore = 0
        isWaitingForAnimationHome = false
        
        worldGenerator?.stopAllSpawning()
        
        setupProperties()
        
        showTapToStart()
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
        guard let player = player else { return }
        let chaserNode = ChaserEntity(player: player)
        addChild(chaserNode)
        chaser = chaserNode
        chaser?.zPosition = 1
        
        guard gamePhase != .tutorial else { return }
        //         let gerobakIkan = SKSpriteNode(imageNamed: "TokoIkan")
        //         gerobakIkan.setScale(0.2)
        //         gerobakIkan.position = chaser?.position ?? CGPoint.zero
        //         gerobakIkan.zPosition = 2
        //         self.gerobakIkan = gerobakIkan
        //         addChild(gerobakIkan)
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
    
    // MARK: - Shop Logic
    func buyCostume(costume: String, price coin:Int) {
        if playerData.coins < coin {
            print("Not enough coin")
            return
        }
        if playerData.unlockedCostumes.contains(costume) {
            print("Already purchased")
            return
        }
        
        playerData.coins -= coin
        playerData.unlockedCostumes.append(costume)
        coinUpdateHandler?(playerData.coins)
        costumePurchasedHandler?(playerData.unlockedCostumes)
        savePlayerData()
    }
    
    func selectCostume(_ costume: String) {
        if !playerData.unlockedCostumes.contains(costume) {
            print("Costume not purchased yet")
            return
        }
        playerData.selectedCostume = costume
        selectedCostumeHandler?(costume)
        savePlayerData()
    }
    
    private func startChaserCatchupSequence() {
        guard let chaser = chaser, let player = player else {
//            gameOver() // fallback
            return
        }
        
        guard gamePhase == .playing else { return }
        
        // 1. Stop spawning and freeze background scrolling
        worldGenerator?.stopAllSpawning()
        backgroundView?.pauseScrolling()
        
        // 🔹 STOP MOVEMENT OF ALL EXISTING OBJECTS
        self.enumerateChildNodes(withName: "//") { node, _ in
            if node.name != "background_music_node" {
                node.removeAllActions()
                node.physicsBody?.velocity = .zero
                node.physicsBody?.angularVelocity = 0
                node.physicsBody?.isDynamic = false
            }
        }
        
        // 2. Stop player's input or animation
        player.removeAllActions()
        player.startCaughtAnimation() // ⬅️ Create this animation in your PlayerEntity
        
        // 3. Move chaser to player's position over 1 second
        let moveToPlayer = SKAction.moveTo(x: player.position.x, duration: 1.0)
        moveToPlayer.timingMode = .easeInEaseOut
        
        chaser.run(moveToPlayer) {
            self.gameOver()
            print("GameOver")
        }
    }
    
    //MARK: - Setting Stuff
    
    func setBgmVolume(_ volume: Float) {
        EffectsFactory.shared.refreshBgmVolume(volume: volume)
        EffectsFactory.shared.setBgmVolume(volume)
        savePlayerData()
    }
    
    func setSfxVolume(_ volume: Float) {
        playerData.sfxVolume = volume
        savePlayerData()
    }
    
    func getBgmVolume() -> Float {
        return playerData.bgmVolume
    }
    
    func getSfxVolume() -> Float {
        return playerData.sfxVolume
    }
    
    
    // MARK: - Save Func
    @objc private func savePlayerData() {
        guard gamePhase != .tutorial || gamePhase != .playing else { return }
        SaveManager.shared.save(playerData)
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
        savePlayerData()
    }
}
