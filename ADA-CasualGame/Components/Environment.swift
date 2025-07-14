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
        let duration = distance / Constants.gameSpeed * 2
        
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
        let duration = distance / Constants.gameSpeed * 2
        
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}

extension GameScene {
    // Initializer
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

    // Initializer (2)
    func createPlayer() {
        let playerSize = CGSize(width: Constants.playerHitboxWidth, height: Constants.playerHitboxHeight)
        player = SKSpriteNode(color: .yellow, size: playerSize)
        // Spawn point
        player?.position = CGPoint(x: 150, y: 125)
        player?.physicsBody = SKPhysicsBody(rectangleOf: player!.size)
        reapplyPlayerPhysics()
        self.addChild(player!)
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
            platform.startMoving(across: self) // **MODIFIED**
        } else {
            let platform = SolidPlatform.create(at: platformPosition, size: platformSize)
            self.addChild(platform)
            platform.startMoving(across: self) // **MODIFIED**
        }
    }
    
    func startSpawningPlatforms() {
        // TODO: Scale frequency with game speed?
        let spawnAction = SKAction.run(spawnPlatform)
        // Spawn every 5 seconds (can add random variation with withRange: N)
        let waitAction = SKAction.wait(forDuration: 5.0)
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
    
    // Ray cast directly below player to identify surface type
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
