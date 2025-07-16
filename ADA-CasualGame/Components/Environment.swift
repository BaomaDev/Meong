import Foundation
import SpriteKit

class SemiSolidPlatform: SKSpriteNode {
    static func create(at position: CGPoint, size: CGSize) -> SemiSolidPlatform {
        // TODO: Add assets based on biome type
        let platform = SemiSolidPlatform(color: .blue, size: size)
        platform.position = position
        platform.name = "SemiSolidPlatform"
        
        // Create an edge-based body for the top surface only
        let topEdge = SKPhysicsBody(edgeFrom: CGPoint(x: -size.width / 2, y: size.height / 2),
                                    to: CGPoint(x: size.width / 2, y: size.height / 2))
        platform.physicsBody = topEdge  // Set the top edge
        platform.physicsBody?.isDynamic = false
        
        // Assign the specific semi-solid category
        platform.physicsBody?.categoryBitMask = PhysicsCategory.semiSolidPlatform
        platform.physicsBody?.collisionBitMask = PhysicsCategory.player
        return platform
    }
    
    func startMoving(across scene: SKScene) {
        // Controls game speed!
        // TODO: Use a more clearly defined game speed metric (i.e. Meters)
        let distance = worldMoveDistance
        let duration = round(distance / gameSpeed / speedScalingStep) * speedScalingStep
        
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}

class SolidPlatform: SKSpriteNode {
    static func create(at position: CGPoint, size: CGSize) -> SolidPlatform {
        let platform = SolidPlatform(color: .white, size: size)
        platform.position = position
        platform.name = "SolidPlatform"
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        // Assign the specific solid category
        platform.physicsBody?.categoryBitMask = PhysicsCategory.solidPlatform
        platform.physicsBody?.collisionBitMask = PhysicsCategory.player
        return platform
    }
    
    func startMoving(across scene: SKScene) {
        // Controls game speed!
        // TODO: Use a more clearly defined game speed metric (i.e. Meters)
        let distance = worldMoveDistance
        let duration = round(distance / gameSpeed / speedScalingStep) * speedScalingStep
        
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}

extension GameScene {
    // Ground creation
    func createGround() {
        let groundSize = CGSize(width: self.size.width, height: groundHeight)
        let ground = SKSpriteNode(color: .gray, size: groundSize)
        ground.position = CGPoint(x: self.size.width / 2, y: groundSize.height / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground
        ground.physicsBody?.collisionBitMask = PhysicsCategory.player
        self.addChild(ground)
    }
    
    func spawnPlatform() {
        // Fixed spawn height and platform width for now
        // TODO: Procedurally generate platforms
        let platformSize = CGSize(width: 500, height: platformHeight)
        let platformY = 240.0
        let platformPosition = CGPoint(x: self.size.width + platformSize.width, y: platformY)
        
        if Bool.random() {
            let platform = SemiSolidPlatform.create(at: platformPosition, size: platformSize)
            self.addChild(platform)
            platform.startMoving(across: self)
        } else {
            let platform = SolidPlatform.create(at: platformPosition, size: platformSize)
            self.addChild(platform)
            platform.startMoving(across: self)
        }
    }
    
    func startSpawningPlatforms() {
        // TODO: Scale frequency with game speed?
        let spawnAction = SKAction.run(spawnPlatform)
        // Spawn every 5 seconds (can add random variation with withRange: N)
        let waitAction = SKAction.wait(forDuration: 5.0)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    func spawnObstacle() {
        let obstacleY = groundHeight + 40 // Position slightly above ground
        let position = CGPoint(x: self.size.width + 50, y: obstacleY)
        
        // Randomly choose between NoTouch, Stepable, and Duckable obstacles
        let randomChoice = Int.random(in: 0...3)
        
        switch randomChoice {
        case 0:
            let obstacle = NoTouch.create()
            obstacle.position = position
            self.addChild(obstacle)
            obstacle.startMoving(across: self)
            
        case 1:
            let obstacle = Stepable.create()
            obstacle.position = position
            self.addChild(obstacle)
            obstacle.startMoving(across: self)
            
        case 2:
            let obstacle = Duckable.create()
            obstacle.position = position
            self.addChild(obstacle)
            obstacle.startMoving(across: self)
            
        case 3:
            let obstacle = Moving.create()
            obstacle.position = position
            self.addChild(obstacle)
            obstacle.startMoving(across: self)
            
        default:
            break
        }
    }
    
    func spawnCoinsAndPowerUps() {
            guard let player = self.player else { return }

            // Get all obstacle frames to avoid overlapping
            let obstacleNodes = self.children.compactMap {
                $0.physicsBody?.categoryBitMask == PhysicsCategory.obstacle ? $0 as? SKSpriteNode : nil
            }
            let obstacleRects = obstacleNodes.map { $0.calculateAccumulatedFrame() }

            let coinSpacing: CGFloat = 40.0
            let coinChunkSize = Int.random(in: 1...3)
            var attempts = 0

            while attempts < 10 {
                attempts += 1
                let coinY = CGFloat.random(in: self.size.height / 3.2 ... self.size.height / 1.5)

                var coinChunkRects: [CGRect] = []
                var allValid = true

                for i in 0..<coinChunkSize {
                    let coinX = self.size.width + 30 + CGFloat(i) * coinSpacing
                    let coinRect = CGRect(x: coinX - 15, y: coinY - 15, width: 30, height: 30)
                    coinChunkRects.append(coinRect)

                    if obstacleRects.contains(where: { $0.intersects(coinRect.insetBy(dx: -10, dy: -10)) }) {
                        allValid = false
                        break
                    }
                }

                if allValid {
                    for rect in coinChunkRects {
                        let coin = SpawnFactory.createCoin(at: CGPoint(x: rect.midX, y: rect.midY), characterCategory: PhysicsCategory.player, coinCategory: PhysicsCategory.coin)
                        self.addChild(coin)
                    }
                    break
                }
            }

            // Power-up spawning with 25% chance
            if Int.random(in: 0..<4) == 0 {
                attempts = 0
                while attempts < 10 {
                    attempts += 1
                    let powerUpY = CGFloat.random(in: self.size.height / 3.2 ... self.size.height / 1.5)
                    let powerUpX = self.size.width + CGFloat.random(in: 20...60)
                    let powerUpRect = CGRect(x: powerUpX - 20, y: powerUpY - 20, width: 40, height: 40)

                    if !obstacleRects.contains(where: { $0.intersects(powerUpRect.insetBy(dx: -10, dy: -10)) }) {
                        let powerUp = SpawnFactory.createPowerUp(at: CGPoint(x: powerUpX, y: powerUpY), characterCategory: PhysicsCategory.player, powerUpCategory: PhysicsCategory.powerUp)
                        self.addChild(powerUp)
                        break
                    }
                }
            }
        }
    
    func startSpawningObstacles() {
        let spawnAction = SKAction.run(spawnObstacle)
        let waitAction = SKAction.wait(forDuration: 4.0, withRange: 1.5) // Spawn setiap 2.5-5.5 detik
        
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    func startSpawningCoinsAndPowerUps() {
        let spawnCoinsAndPower = SKAction.run(spawnCoinsAndPowerUps)
        let wait = SKAction.wait(forDuration: 5.0, withRange: 2.0)

        run(SKAction.repeatForever(SKAction.sequence([spawnCoinsAndPower, wait])))
    }
}
