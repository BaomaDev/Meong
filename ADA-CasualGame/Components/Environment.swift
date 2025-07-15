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
        let distance = scene.size.width + self.size.width * 2
        let duration = distance / Constants.gameSpeed
        
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
        let distance = scene.size.width + self.size.width * 2
        let duration = distance / Constants.gameSpeed
        
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}

extension GameScene {
    // Ground creation
    func createGround() {
        let groundSize = CGSize(width: self.size.width, height: Constants.groundHeight)
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
        let platformSize = CGSize(width: 500, height: Constants.platformHeight)
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
        let obstacleY = Constants.groundHeight + 40 // Position slightly above ground
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
    
    func startSpawningObstacles() {
        let spawnAction = SKAction.run(spawnObstacle)
        let waitAction = SKAction.wait(forDuration: 4.0, withRange: 1.5) // Spawn setiap 2.5-5.5 detik
        
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
}

//func spawnObstacle(in scene: SKScene) {
//    let obstacleY = Constants.groundHeight + 20
//    let position = CGPoint(x: scene.size.width + 100, y: obstacleY)
//    
//    switch Int.random(in: 0...3) {
//    case 0:
//        let obstacle = NoTouchObstacle.create(at: position)
//        scene.addChild(obstacle)
//        obstacle.startMoving(across: scene)
//        
//    case 1:
//        let obstacle = StepableObstacle.create(at: position)
//        scene.addChild(obstacle)
//        obstacle.startMoving(across: scene)
//        
//    case 2:
//        let obstacle = DuckableObstacle.create(at: position)
//        scene.addChild(obstacle)
//        obstacle.startMoving(across: scene)
//        
//    case 3:
//        let obstacle = MovingObstacle.create(at: position)
//        scene.addChild(obstacle)
//        obstacle.startMoving(across: scene)
//        
//    default: break
//    }
//}
//
//func startSpawningObstacles(in scene: SKScene) {
//    let spawn = SKAction.run { spawnObstacle(in: scene) }
//    let wait = SKAction.wait(forDuration: 3.0, withRange: 1.5)
//    let sequence = SKAction.sequence([spawn, wait])
//    scene.run(SKAction.repeatForever(sequence), withKey: "spawnObstacles")
//}
