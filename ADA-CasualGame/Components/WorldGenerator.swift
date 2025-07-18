//
//  WorldGenerator.swift
//  ADA-CasualGame
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/07/25.
//

import SpriteKit

enum NoiseLayer: Int {
    case obstacleChance = 0
    case obstacleType
    case coinChance
    case coinPos
    case powerUpChance
    case powerUpPos
    case platformChance
    case platformType
    case projectileChance
    case projectileType
}

private enum SpawnKey {
    static let platform = "spawnPlatform"
    static let obstacle = "spawnObstacle"
    static let projectile = "spawnProjectile"
    static let collectible = "spawnCollectible"
}

class WorldGenerator {
    private weak var scene: SKScene?
    private let noiseMap = WorldNoiseMap(seed: Int32.random(in: 0..<Int32.max), chunkCount: 1000, layerCount: 10) // 10 = total noise layers

    private var currentStepPlatform = 0
    private var currentStepObstacle = 0
    private var currentStepProjectile = 0
    private var currentStepCollectible = 0


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


    func setupEnvironment() {
        createGround()
        startProceduralSpawning()
    }
    
    private func stopAllSpawning() {
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
        let groundSize = CGSize(width: scene.size.width, height: groundHeight)
        let ground = SKSpriteNode(color: .gray, size: groundSize)
        ground.position = CGPoint(x: scene.size.width / 2, y: groundSize.height / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.collisionBitMask = PhysicsCategory.player
        scene.addChild(ground)
    }

    func startProceduralSpawning() {
        stopAllSpawning()
        startSpawningPlatforms()
        startSpawningObstacles()
        startSpawningProjectiles()
        startSpawningCoinsAndPowerUps()
    }

    private func startSpawningPlatforms() {
//        let speedFactor = Double(gameSpeed / baseGameSpeed) // 1.0 ... 2.0
//        let baseDelay = 4.5 / speedFactor // Delay shrinks as speed increases
//        let delay = max(0.6, baseDelay * pow(0.98, Double(currentStepPlatform)))
//        let range = min(delay * 0.3, 0.5)
        
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

        let chance = noiseMap.valueAt(atChunk: currentStepPlatform, layer: NoiseLayer.platformChance.rawValue)
        print("Platform chance at \(currentStepPlatform):", chance)
        let threshold = adaptiveThreshold(forStep: currentStepPlatform, base: 0.5)
        guard chance > threshold else { return }

        let typeVal = noiseMap.rawValueAt(atChunk: currentStepPlatform, layer: NoiseLayer.platformType.rawValue)
        let platformSize = CGSize(width: 500, height: platformHeight)
        let platformY: CGFloat = 240
        let position = CGPoint(x: scene.size.width + platformSize.width, y: platformY)

        let node: SKSpriteNode = (typeVal < 0) ?
            SpawnFactory.createSemiSolidPlatform(at: position, size: platformSize) :
            SpawnFactory.createSolidPlatform(at: position, size: platformSize)

        scene.addChild(node)
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

        let chance = noiseMap.valueAt(atChunk: currentStepObstacle, layer: NoiseLayer.obstacleChance.rawValue)
        print("Obstacle chance at \(currentStepObstacle):", chance)
        let threshold = adaptiveThreshold(forStep: currentStepObstacle, base: 0.3)
        guard chance > threshold else { return }


        let typeVal = noiseMap.rawValueAt(atChunk: currentStepObstacle, layer: NoiseLayer.obstacleType.rawValue)
        let position = CGPoint(x: scene.size.width + 50, y: groundHeight + 40)

        let obstacle: SKSpriteNode?
        switch typeVal {
        case ..<(-0.5): obstacle = SpawnFactory.createNoTouch(at: position)
        case ..<0.0: obstacle = SpawnFactory.createStepable(at: position)
        case ..<0.5: obstacle = SpawnFactory.createDuckable(at: position)
        default:
            let moveY = groundHeight + 30
            obstacle = SpawnFactory.createMoving(at: CGPoint(x: position.x, y: moveY))
        }

        if let o = obstacle {
            scene.addChild(o)
        }
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

        let chance = noiseMap.valueAt(atChunk: currentStepProjectile, layer: NoiseLayer.projectileChance.rawValue)
        let threshold = adaptiveThreshold(forStep: currentStepProjectile, base: 0.3)
        guard chance > threshold else { return }

        let projectile = SpawnFactory.createProjectile(in: scene)
        scene.addChild(projectile)
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

        let coinChance = noiseMap.valueAt(atChunk: currentStepCollectible, layer: NoiseLayer.coinChance.rawValue)
        let powerUpChance = noiseMap.valueAt(atChunk: currentStepCollectible, layer: NoiseLayer.powerUpChance.rawValue)
        print("Coin chance at \(currentStepCollectible):", coinChance)
        print("PowerUp chance at \(currentStepCollectible):", powerUpChance)

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

        if powerUpChance > 0.75 {
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
                    break
                }
            }
        }

        currentStepCollectible += 1
    }
}


//import SpriteKit
//
//class WorldGenerator {
//    private weak var scene: SKScene?
//
//    init(scene: SKScene) {
//        self.scene = scene
//    }
//
//    func setupEnvironment() {
//        createGround()
//        startSpawningPlatforms()
//        startSpawningObstacles()
//        startSpawningProjectiles()
//        startSpawningCoinsAndPowerUps()
//    }
//
//    private func createGround() {
//        guard let scene = scene else { return }
//        let groundSize = CGSize(width: scene.size.width, height: groundHeight)
//        let ground = SKSpriteNode(color: .gray, size: groundSize)
//        ground.position = CGPoint(x: scene.size.width / 2, y: groundSize.height / 2)
//        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
//        ground.physicsBody?.isDynamic = false
//        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
//        ground.physicsBody?.collisionBitMask = PhysicsCategory.player
//        scene.addChild(ground)
//    }
//
//    private func spawnPlatform() {
//        guard let scene = scene else { return }
//        let platformSize = CGSize(width: 500, height: platformHeight)
//        let platformY = 240.0
//        let platformPosition = CGPoint(x: scene.size.width + platformSize.width, y: platformY)
//
//        let platform: SKSpriteNode
//        if Bool.random() {
//            platform = SpawnFactory.createSemiSolidPlatform(at: platformPosition, size: platformSize)
//        } else {
//            platform = SpawnFactory.createSolidPlatform(at: platformPosition, size: platformSize)
//        }
//        scene.addChild(platform)
//    }
//
//    private func startSpawningPlatforms() {
//        let spawnAction = SKAction.run(spawnPlatform)
//        let waitAction = SKAction.wait(forDuration: 5.0)
//        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
//    }
//
//    private func spawnObstacle() {
//        guard let scene = scene else { return }
//        let obstacleY = groundHeight + 40
//        let position = CGPoint(x: scene.size.width + 50, y: obstacleY)
//        
//        let randomChoice = Int.random(in: 0...3)
//        var obstacle: SKSpriteNode?
//
//        switch randomChoice {
//        case 0:
//            obstacle = SpawnFactory.createNoTouch(at: position)
//        case 1:
//            obstacle = SpawnFactory.createStepable(at: position)
//        case 2:
//            obstacle = SpawnFactory.createDuckable(at: position)
//        case 3:
//            let movingPosition = CGPoint(x: scene.size.width + 50, y: groundHeight + 30)
//            obstacle = SpawnFactory.createMoving(at: movingPosition)
//        default:
//            break
//        }
//        
//        if let obstacle = obstacle {
//            scene.addChild(obstacle)
//        }
//    }
//
//    private func startSpawningObstacles() {
//        let spawnAction = SKAction.run(spawnObstacle)
//        let waitAction = SKAction.wait(forDuration: 4.0, withRange: 1.5)
//        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
//    }
//    
//    private func spawnProjectile() {
//        guard let scene = scene else { return }
//        let projectile = SpawnFactory.createProjectile(in: scene)
//        scene.addChild(projectile)
//    }
//
//    private func startSpawningProjectiles() {
//        let spawnAction = SKAction.run(spawnProjectile)
//        let waitAction = SKAction.wait(forDuration: 6.0, withRange: 2.0)
//        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
//    }
//
//    private func spawnCoinsAndPowerUps() {
//        guard let scene = scene else { return }
//        // Get all obstacle frames to avoid overlapping
//        let obstacleNodes = scene.children.compactMap {
//            $0.physicsBody?.categoryBitMask == PhysicsCategory.obstacle ? $0 as? SKSpriteNode : nil
//        }
//        let obstacleRects = obstacleNodes.map { $0.calculateAccumulatedFrame() }
//
//        let coinSpacing: CGFloat = 40.0
//        let coinChunkSize = Int.random(in: 1...3)
//        var attempts = 0
//
//        while attempts < 10 {
//            attempts += 1
//            let coinY = CGFloat.random(in: scene.size.height / 3.2 ... scene.size.height / 1.5)
//            var coinChunkRects: [CGRect] = []
//            var allValid = true
//
//            for i in 0..<coinChunkSize {
//                let coinX = scene.size.width + 30 + CGFloat(i) * coinSpacing
//                let coinRect = CGRect(x: coinX - 15, y: coinY - 15, width: 30, height: 30)
//                coinChunkRects.append(coinRect)
//
//                if obstacleRects.contains(where: { $0.intersects(coinRect.insetBy(dx: -10, dy: -10)) }) {
//                    allValid = false
//                    break
//                }
//            }
//
//            if allValid {
//                for rect in coinChunkRects {
//                    let coin = SpawnFactory.createCoin(at: CGPoint(x: rect.midX, y: rect.midY),
//                                                     characterCategory: PhysicsCategory.player,
//                                                     coinCategory: PhysicsCategory.coin)
//                    scene.addChild(coin)
//                }
//                break
//            }
//        }
//
//        // Power-up spawning with 25% chance
//        if Int.random(in: 0..<4) == 0 {
//            attempts = 0
//            while attempts < 10 {
//                attempts += 1
//                let powerUpY = CGFloat.random(in: scene.size.height / 3.2 ... scene.size.height / 1.5)
//                let powerUpX = scene.size.width + CGFloat.random(in: 20...60)
//                let powerUpRect = CGRect(x: powerUpX - 20, y: powerUpY - 20, width: 40, height: 40)
//
//                if !obstacleRects.contains(where: { $0.intersects(powerUpRect.insetBy(dx: -10, dy: -10)) }) {
//                    let powerUp = SpawnFactory.createPowerUp(at: CGPoint(x: powerUpX, y: powerUpY),
//                                                           characterCategory: PhysicsCategory.player,
//                                                           powerUpCategory: PhysicsCategory.powerUp)
//                    scene.addChild(powerUp)
//                    break
//                }
//            }
//        }
//    }
//
//    private func startSpawningCoinsAndPowerUps() {
//        let spawnCoinsAndPower = SKAction.run(spawnCoinsAndPowerUps)
//        let wait = SKAction.wait(forDuration: 5.0, withRange: 2.0)
//        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnCoinsAndPower, wait])))
//    }
//}
