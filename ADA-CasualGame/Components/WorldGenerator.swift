//
//  WorldGenerator.swift
//  ADA-CasualGame
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/07/25.
//

import SpriteKit

enum NoiseLayer: Int {
    case obstacleChance = 0 //perlin
    case coinChance //ridged
    case powerUpChance //ridged
    case catnipChance //ridged
    case platformChance //perlin
    case projectileChance //perlin
}

private enum SpawnKey {
    static let platform = "spawnPlatform"
    static let obstacle = "spawnObstacle"
    static let projectile = "spawnProjectile"
    static let collectible = "spawnCollectible"
}

class WorldGenerator {
    private weak var scene: SKScene?
    private let obstacleNoiseMap = WorldNoiseMap(seed: Int32.random(in: 0..<Int32.max), chunkCount: 1000, layerCount: 1, noiseType: "Perlin")
    private let platformNoiseMap = WorldNoiseMap(seed: Int32.random(in: 0..<Int32.max), chunkCount: 1000, layerCount: 1, noiseType: "Perlin")
    private let projectileNoiseMap = WorldNoiseMap(seed: Int32.random(in: 0..<Int32.max), chunkCount: 1000, layerCount: 1, noiseType: "Perlin")
    private let coinChanceNoiseMap = WorldNoiseMap(seed: Int32.random(in: 0..<Int32.max), chunkCount: 1000, layerCount: 1, noiseType: "Perlin")
    private let powerUpChanceNoiseMap = WorldNoiseMap(seed: Int32.random(in: 0..<Int32.max), chunkCount: 1000, layerCount: 1, noiseType: "Perlin")
    private let catnipChanceNoiseMap = WorldNoiseMap(seed: Int32.random(in: 0..<Int32.max), chunkCount: 1000, layerCount: 1, noiseType: "Perlin")

    private var currentStepPlatform = 0
    private var currentStepObstacle = 0
    private var currentStepProjectile = 0
    private var currentStepCollectible = 0
    
    private var powerUpBonus: Float = 0
    private var catnipBonus: Float = 0
    private var powerUpCoolDown: Int = 0
    private var catnipCoolDown: Int = 0
    
    private var grounds: [SKSpriteNode] = []
    private var isGroundScrollingPaused = false

    init(scene: SKScene) {
        self.scene = scene
    }
    
    private func scheduleRepeatingSpawn(
        key: String,
        delay: Double,
        range: Double,
        action: @escaping () -> Void
    ) {
        guard let scene = scene else { return }
        scene.removeAction(forKey: key) // Stop previous loop

        let run = SKAction.run(action)
        let wait = SKAction.wait(forDuration: delay, withRange: range)
        let sequence = SKAction.sequence([run, wait])
        scene.run(SKAction.repeatForever(sequence), withKey: key)
    }
    
    func updateAllNodeSpeedsToMatchGameSpeed() {
        guard let scene = scene else { return }

        let targetX: CGFloat = -100  // Offscreen left edge

        let speed = gameSpeed // pixels per second

        for node in scene.children {
            guard node.hasActions() else { continue }
            guard let category = node.physicsBody?.categoryBitMask else { continue }
            
            var actionKey: String
            switch category {
            case PhysicsCategory.solidPlatform | PhysicsCategory.semiSolidPlatform:
                actionKey = MoveKey.platform
            case PhysicsCategory.obstacle:
                actionKey = MoveKey.obstacle
            case PhysicsCategory.projectile:
                actionKey = MoveKey.projectile
            case PhysicsCategory.coin | PhysicsCategory.powerUp | PhysicsCategory.catnip:
                actionKey = MoveKey.collectible
            default:
                continue
            }
            
            print(node.name, actionKey, speed, category, node.hasActions())
            
            let currentX = node.position.x
            let remainingDistance = currentX - targetX
            guard remainingDistance > 0 else { continue }

            node.removeAction(forKey: actionKey)
            let move = SpawnFactory.createMovementAction(distance: remainingDistance, speed: speed)
            node.run(move, withKey: actionKey)
        }
    }

    func setupEnvironment() {
        createGround()
    }
    
    func stopAllSpawning() {
        scene?.removeAction(forKey: SpawnKey.platform)
        scene?.removeAction(forKey: SpawnKey.obstacle)
        scene?.removeAction(forKey: SpawnKey.projectile)
        scene?.removeAction(forKey: SpawnKey.collectible)
    }
    
    private func adaptiveThreshold(forStep step: Int, base: Float, decayRate: Float = 0.001, min: Float = 0.05) -> Float {
        return max(min, base - Float(step) * decayRate)
    }

    private func createGround() {
        guard let scene = scene else { return }

        for ground in grounds {
            ground.removeFromParent()
        }
        grounds.removeAll()

        let texture = SKTexture(imageNamed: "Ground")
        let groundSize = CGSize(width: scene.size.width, height: groundHeight)

        for i in 0..<2 {
            let ground = SKSpriteNode(texture: texture)
            ground.anchorPoint = .zero
            ground.size = groundSize
            ground.position = CGPoint(x: CGFloat(i) * ground.size.width, y: 0)
            ground.zPosition = 1

            ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size, center: CGPoint(x: ground.size.width / 2, y: ground.size.height / 2))
            ground.physicsBody?.isDynamic = false
            ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
            ground.physicsBody?.collisionBitMask = PhysicsCategory.player
            ground.physicsBody?.restitution = 0
            ground.physicsBody?.friction = 1.0
            
            scene.addChild(ground)
            grounds.append(ground)
        }
    }

    // MARK: - Ground Scrolling Methods
    func pauseGroundScrolling() {
        isGroundScrollingPaused = true
    }
    
    func updateGroundPosition(gameSpeed: CGFloat) {
        guard !isGroundScrollingPaused else { return }
        guard gameSpeed > 0 else { return }

        let deltaTime: CGFloat = 1 / 60.0
        let distanceToMove = gameSpeed * deltaTime

        for ground in grounds {
            ground.position.x -= distanceToMove

            if ground.position.x <= -ground.size.width {
                ground.position.x += ground.size.width * 2
            }
        }
    }

    func startProceduralSpawning() {
        stopAllSpawning()
        startSpawningPlatforms()
        startSpawningObstacles()
//        startSpawningProjectiles()
        startSpawningCoinsAndPowerUps()
    }

    private func startSpawningPlatforms() {
        let speedFactor = Double(gameSpeed / baseGameSpeed)
        let baseDelay = 4.5 / speedFactor
        let rawDelay = baseDelay * pow(0.98, Double(currentStepPlatform))
        let delay = max(minPlatformDelay, rawDelay) // <-- cap how low it can go
        let range = min(delay * 0.3, 0.5)

        
        scheduleRepeatingSpawn(
                key: SpawnKey.platform,
                delay: delay,
                range: range
            ) { [weak self] in self?.spawnPlatform() }
    }

    private func spawnPlatform() {
        guard let scene = scene else { return }
        defer { currentStepPlatform += 1 }

        let chance = platformNoiseMap.valueAt(atChunk: currentStepPlatform, layer: 0)
//        print("Platform chance at \(currentStepPlatform):", chance)
        let threshold = adaptiveThreshold(forStep: currentStepPlatform, base: 0.5)
        guard chance > threshold else { return }

        let platformSize = CGSize(width: 500, height: platformThickness)
        let platformY: CGFloat = platformHeight
        let position = CGPoint(x: scene.size.width + platformSize.width, y: platformY)
        
        let platform: SKSpriteNode
        if Bool.random() {
            platform = SpawnFactory.createSemiSolidPlatform(at: position, size: platformSize)
        } else {
            platform = SpawnFactory.createSolidPlatform(at: position, size: CGSize(width: 320, height: platformThickness))
        }
        scene.addChild(platform)
    }

    private func startSpawningObstacles() {
//        let speedFactor = Double(gameSpeed / baseGameSpeed)
//        let baseDelay = 4.0 / speedFactor
//        let delay = max(0.5, baseDelay * pow(0.98, Double(currentStepObstacle)))
//        let range = min(delay * 0.3, 0.5)
        
        let speedFactor = Double(gameSpeed / baseGameSpeed)
        let baseDelay = 4.5 / speedFactor
        let rawDelay = baseDelay * pow(0.98, Double(currentStepObstacle))
        let delay = max(minObstacleDelay, rawDelay) // <-- cap how low it can go
        let range = min(delay * 0.3, 0.5)
        
        scheduleRepeatingSpawn(
                key: SpawnKey.obstacle,
                delay: delay,
                range: range
            ) { [weak self] in self?.spawnObstacle() }
    }

    private func spawnObstacle() {
        guard let scene = scene else { return }

        defer { currentStepObstacle += 1 }

        let chance = obstacleNoiseMap.valueAt(
            atChunk: currentStepObstacle,
            layer: 0
        )
//        print("Obstacle chance at \(currentStepObstacle):", chance)

        let threshold = adaptiveThreshold(
            forStep: currentStepObstacle,
            base: 0.3
        )
        guard chance > threshold else { return }

//        let type = noiseMap.typeIndex(
//            atChunk: currentStepObstacle,
//            layer: NoiseLayer.obstacleType.rawValue,
//            maxTypes: 4 // NoTouch, Stepable, Duckable, Moving
//        )

        let position = CGPoint(x: scene.size.width + 50, y: groundHeight + 40)

//        let obstacle: SKSpriteNode?
//        switch type {
//        case 0:
//            obstacle = SpawnFactory.createNoTouch(at: position)
//        case 1:
//            obstacle = SpawnFactory.createStepable(at: position)
//        case 2:
//            obstacle = SpawnFactory.createDuckable(at: position)
//        case 3:
//            let moveY = groundHeight + 30
//            obstacle = SpawnFactory.createMoving(at: CGPoint(x: position.x, y: moveY))
//        default:
//            obstacle = nil
//        }
//
//        if let o = obstacle {
//            scene.addChild(o)
//        }
        let randomChoice = Int.random(in: 0...3)
        var obstacle: SKSpriteNode?

        switch randomChoice {
        case 0:
            obstacle = SpawnFactory.createNoTouch(at: position)
        case 1:
            obstacle = SpawnFactory.createStepable(at: CGPoint(x: scene.size.width + 50, y: groundHeight + 28))
        case 2:
            obstacle = SpawnFactory.createDuckable(at: CGPoint(x: scene.size.width + 50, y: groundHeight + 45))
        case 3:
            let movingPosition = CGPoint(x: scene.size.width + 50, y: groundHeight + 22)

            SpawnFactory.createMovingAlert(at: movingPosition, in: scene)
            
            scene.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.run {
                    let moving = SpawnFactory.createMoving(at: movingPosition)
                    scene.addChild(moving)
                }
            ]))
            
            if let obstacleName = obstacle?.name {
                switch obstacleName {
                case "bajaj":
                    EffectsFactory.shared.playSound(soundKey: "bajaj_sound.mp3")
                case "gojek":
                    EffectsFactory.shared.playSound(soundKey: "trimmed_gojek.m4a")
                    EffectsFactory.shared.playSound(soundKey: "gojek_horn.m4a")
                default:
                    break
                }
            }
            
        default:
            break
        }
        
        if let obstacle = obstacle {
            scene.addChild(obstacle)
        }
        
        // BAGIAN SENG SINI TAK TAMBAHI
        
        let projectileChance = projectileNoiseMap.valueAt(atChunk: currentStepObstacle, layer: 0)
        
        let projectileThreshold: Float = 0.4
        
        if projectileChance > projectileThreshold {
            
            let (projectile, startPoint) = SpawnFactory.createProjectile(in: scene)

            SpawnFactory.createMovingAlert(at: startPoint, in: scene)
            let delay = SKAction.wait(forDuration: 0.7)
            let spawn = SKAction.run {
                scene.addChild(projectile)
            }
            scene.run(SKAction.sequence([delay, spawn]))
        }
        
        currentStepProjectile += 1
    }

    private func startSpawningProjectiles() {
//        let speedFactor = Double(gameSpeed / baseGameSpeed)
//        let baseDelay = 6.0 / speedFactor
//        let delay = max(0.8, baseDelay * pow(0.98, Double(currentStepProjectile)))
//        let range = min(delay * 0.3, 0.5)
        
        let speedFactor = Double(gameSpeed / baseGameSpeed)
        let baseDelay = 4.5 / speedFactor
        let rawDelay = baseDelay * pow(0.98, Double(currentStepProjectile))
        let delay = max(minProjectileDelay, rawDelay) // <-- cap how low it can go
        let range = min(delay * 0.3, 0.5)
        
        scheduleRepeatingSpawn(
                key: SpawnKey.projectile,
                delay: delay,
                range: range
            ) { [weak self] in self?.spawnProjectile() }
    }

    private func spawnProjectile() {
        guard let scene = scene else { return }
        defer { currentStepProjectile += 1 }

        let chance = projectileNoiseMap.valueAt(atChunk: currentStepProjectile, layer: 0)
        let threshold = adaptiveThreshold(forStep: currentStepProjectile, base: 0.3)
        guard chance > threshold else { return }

        let (projectile, startPoint) = SpawnFactory.createProjectile(in: scene)

        // Show alert
        SpawnFactory.createMovingAlert(at: startPoint, in: scene)

        // Delay the projectile spawn after the alert
        let delay = SKAction.wait(forDuration: 0.7)
        let spawn = SKAction.run {
            scene.addChild(projectile)
        }

        scene.run(SKAction.sequence([delay, spawn]))
    }

    private func startSpawningCoinsAndPowerUps() {
//        let speedFactor = Double(gameSpeed / baseGameSpeed)
//        let baseDelay = 5.0 / speedFactor
//        let delay = max(0.7, baseDelay * pow(0.98, Double(currentStepCollectible)))
//        let range = min(delay * 0.3, 0.5)
        
        let speedFactor = Double(gameSpeed / baseGameSpeed)
        let baseDelay = 4.5 / speedFactor
        let rawDelay = baseDelay * pow(0.98, Double(currentStepCollectible))
        let delay = max(minCollectibleDelay, rawDelay) // <-- cap how low it can go
        let range = min(delay * 0.3, 0.5)
        
        scheduleRepeatingSpawn(
                key: SpawnKey.collectible,
                delay: delay,
                range: range
            ) { [weak self] in self?.spawnCoinsAndPowerUps() }
    }

    private func spawnCoinsAndPowerUps() {
        guard let scene = scene else { return }

        // Collect obstacle rects to avoid overlap
        let obstacles = scene.children.compactMap {
            $0.physicsBody?.categoryBitMask == PhysicsCategory.obstacle ? $0 as? SKSpriteNode : nil
        }
        let obstacleRects = obstacles.map { $0.calculateAccumulatedFrame() }

        let coinChance = coinChanceNoiseMap.adjustNoiseValue(Double(coinChanceNoiseMap.valueAt(atChunk: currentStepCollectible, layer: 0)), method: .squared(1))
        let powerUpChance = powerUpChanceNoiseMap.adjustNoiseValue(Double(powerUpChanceNoiseMap.valueAt(atChunk: currentStepCollectible, layer: 0)), method: .squared(2))
        let catnipChance = catnipChanceNoiseMap.adjustNoiseValue(Double(catnipChanceNoiseMap.valueAt(atChunk: currentStepCollectible, layer: 0)), method: .squared(2))
        print("Coin chance at \(currentStepCollectible) (squared):", coinChance)
        print("PowerUp chance at \(currentStepCollectible) (squared):", powerUpChance)
        print("Catnip chance at \(currentStepCollectible) (squared):", catnipChance)
        print("Coin chance at \(currentStepCollectible) (raw):", coinChanceNoiseMap.valueAt(atChunk: currentStepCollectible, layer: 0))
        print("PowerUp chance at \(currentStepCollectible) (raw):", powerUpChanceNoiseMap.valueAt(atChunk: currentStepCollectible, layer: 0))
        print("Catnip chance at \(currentStepCollectible) (raw):", catnipChanceNoiseMap.valueAt(atChunk: currentStepCollectible, layer: 0))
        
        

        var attempts = 0
        let coinSpacing: CGFloat = 40
        let coinChunkSize = Int.random(in: 1...3)

        if coinChance > 0.4 {
            while attempts < 10 {
                attempts += 1
                let coinY = CGFloat.random(in: scene.size.height / 3.2 ... scene.size.height / 1.5)
                var rects: [CGRect] = []
                var isValid = true

                for i in 0..<coinChunkSize {
                    let coinX = scene.size.width + 30 + CGFloat(i) * coinSpacing
                    let rect = CGRect(x: coinX - 15, y: coinY - 15, width: 30, height: 30)
                    rects.append(rect)
                    if obstacleRects.contains(where: { $0.intersects(rect.insetBy(dx: -10, dy: -10)) }) {
                        isValid = false
                        break
                    }
                }

                if isValid {
                    for r in rects {
                        let coin = SpawnFactory.createCoin(
                            at: CGPoint(x: r.midX, y: r.midY),
                            characterCategory: PhysicsCategory.player,
                            coinCategory: PhysicsCategory.coin
                        )
                        scene.addChild(coin)
                    }
                    break
                }
            }
        }

        if powerUpCoolDown > 0 {
            powerUpCoolDown -= 1
        } else {
            if powerUpChance + Double(powerUpBonus) > 0.55 {
                attempts = 0
                while attempts < 10 {
                    attempts += 1
                    let powerUpY = CGFloat.random(in: scene.size.height / 3.2 ... scene.size.height / 1.5)
                    let powerUpX = scene.size.width + CGFloat.random(in: 20...60)
                    let rect = CGRect(x: powerUpX - 20, y: powerUpY - 20, width: 40, height: 40)

                    if !obstacleRects.contains(where: { $0.intersects(rect.insetBy(dx: -10, dy: -10)) }) {
                        let powerUp = SpawnFactory.createPowerUp(
                            at: CGPoint(x: powerUpX, y: powerUpY),
                            characterCategory: PhysicsCategory.player,
                            powerUpCategory: PhysicsCategory.powerUp
                        )
                        scene.addChild(powerUp)
                        powerUpBonus = 0
                        powerUpCoolDown = 5
                        break
                    }
                }
            } else {
                powerUpBonus += 0.01
            }
        }
        
        if catnipCoolDown > 0 {
            catnipCoolDown -= 1
        } else {
            if catnipChance + Double(catnipBonus) > 0.65 {
                attempts = 0
                while attempts < 10 {
                    attempts += 1
                    let catnipY = CGFloat.random(in: scene.size.height / 3.2 ... scene.size.height / 1.5)
                    let catnipX = scene.size.width + CGFloat.random(in: 80...140)
                    let catnipRect = CGRect(x: catnipX - 20, y: catnipY - 20, width: 40, height: 40)

                    if !obstacleRects.contains(where: { $0.intersects(catnipRect.insetBy(dx: -10, dy: -10)) }) {
                        let catnip = SpawnFactory.createCatnip(at: CGPoint(x: catnipX, y: catnipY),
                                                               characterCategory: PhysicsCategory.player,
                                                               catnipCategory: PhysicsCategory.catnip)
                        scene.addChild(catnip)
                        catnipBonus = 0
                        catnipCoolDown = 10
                        break
                    }
                }
            } else {
                catnipBonus += 0.005
            }
        }
        currentStepCollectible += 1
    }
}
