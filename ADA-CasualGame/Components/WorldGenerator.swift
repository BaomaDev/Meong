//
//  WorldGenerator.swift
//  ADA-CasualGame
//
//  Created by Jesse Robinson Junior Simanjuntak on 17/07/25.
//


import SpriteKit

class WorldGenerator {
    private weak var scene: SKScene?

    init(scene: SKScene) {
        self.scene = scene
    }

    func setupEnvironment() {
        createGround()
        startSpawningPlatforms()
        startSpawningObstacles()
        startSpawningProjectiles()
        startSpawningCoinsAndPowerUps()
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

    private func spawnPlatform() {
        guard let scene = scene else { return }
        let platformSize = CGSize(width: 500, height: platformHeight)
        let platformY = 240.0
        let platformPosition = CGPoint(x: scene.size.width + platformSize.width, y: platformY)

        let platform: SKSpriteNode
        if Bool.random() {
            platform = SpawnFactory.createSemiSolidPlatform(at: platformPosition, size: platformSize)
        } else {
            platform = SpawnFactory.createSolidPlatform(at: platformPosition, size: platformSize)
        }
        scene.addChild(platform)
    }

    private func startSpawningPlatforms() {
        let spawnAction = SKAction.run(spawnPlatform)
        let waitAction = SKAction.wait(forDuration: 5.0)
        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }

    private func spawnObstacle() {
        guard let scene = scene else { return }
        let obstacleY = groundHeight + 40
        let position = CGPoint(x: scene.size.width + 50, y: obstacleY)
        
        let randomChoice = Int.random(in: 0...3)
        var obstacle: SKSpriteNode?

        switch randomChoice {
        case 0:
            obstacle = SpawnFactory.createNoTouch(at: position)
        case 1:
            obstacle = SpawnFactory.createStepable(at: position)
        case 2:
            obstacle = SpawnFactory.createDuckable(at: position)
        case 3:
            let movingPosition = CGPoint(x: scene.size.width + 50, y: groundHeight + 30)
            obstacle = SpawnFactory.createMoving(at: movingPosition)
        default:
            break
        }
        
        if let obstacle = obstacle {
            scene.addChild(obstacle)
        }
    }

    private func startSpawningObstacles() {
        let spawnAction = SKAction.run(spawnObstacle)
        let waitAction = SKAction.wait(forDuration: 4.0, withRange: 1.5)
        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    private func spawnProjectile() {
        guard let scene = scene else { return }
        let projectile = SpawnFactory.createProjectile(in: scene)
        scene.addChild(projectile)
    }

    private func startSpawningProjectiles() {
        let spawnAction = SKAction.run(spawnProjectile)
        let waitAction = SKAction.wait(forDuration: 6.0, withRange: 2.0)
        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }

    private func spawnCoinsAndPowerUps() {
        guard let scene = scene else { return }
        // Get all obstacle frames to avoid overlapping
        let obstacleNodes = scene.children.compactMap {
            $0.physicsBody?.categoryBitMask == PhysicsCategory.obstacle ? $0 as? SKSpriteNode : nil
        }
        let obstacleRects = obstacleNodes.map { $0.calculateAccumulatedFrame() }

        let coinSpacing: CGFloat = 40.0
        let coinChunkSize = Int.random(in: 1...3)
        var attempts = 0

        while attempts < 10 {
            attempts += 1
            let coinY = CGFloat.random(in: scene.size.height / 3.2 ... scene.size.height / 1.5)
            var coinChunkRects: [CGRect] = []
            var allValid = true

            for i in 0..<coinChunkSize {
                let coinX = scene.size.width + 30 + CGFloat(i) * coinSpacing
                let coinRect = CGRect(x: coinX - 15, y: coinY - 15, width: 30, height: 30)
                coinChunkRects.append(coinRect)

                if obstacleRects.contains(where: { $0.intersects(coinRect.insetBy(dx: -10, dy: -10)) }) {
                    allValid = false
                    break
                }
            }

            if allValid {
                for rect in coinChunkRects {
                    let coin = SpawnFactory.createCoin(at: CGPoint(x: rect.midX, y: rect.midY),
                                                     characterCategory: PhysicsCategory.player,
                                                     coinCategory: PhysicsCategory.coin)
                    scene.addChild(coin)
                }
                break
            }
        }

        // Power-up spawning with 25% chance
        if Int.random(in: 0..<4) == 0 {
            attempts = 0
            while attempts < 10 {
                attempts += 1
                let powerUpY = CGFloat.random(in: scene.size.height / 3.2 ... scene.size.height / 1.5)
                let powerUpX = scene.size.width + CGFloat.random(in: 20...60)
                let powerUpRect = CGRect(x: powerUpX - 20, y: powerUpY - 20, width: 40, height: 40)

                if !obstacleRects.contains(where: { $0.intersects(powerUpRect.insetBy(dx: -10, dy: -10)) }) {
                    let powerUp = SpawnFactory.createPowerUp(at: CGPoint(x: powerUpX, y: powerUpY),
                                                           characterCategory: PhysicsCategory.player,
                                                           powerUpCategory: PhysicsCategory.powerUp)
                    scene.addChild(powerUp)
                    break
                }
            }
        }
    }

    private func startSpawningCoinsAndPowerUps() {
        let spawnCoinsAndPower = SKAction.run(spawnCoinsAndPowerUps)
        let wait = SKAction.wait(forDuration: 5.0, withRange: 2.0)
        scene?.run(SKAction.repeatForever(SKAction.sequence([spawnCoinsAndPower, wait])))
    }
}
