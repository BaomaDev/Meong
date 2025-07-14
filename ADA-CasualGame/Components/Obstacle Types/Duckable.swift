import Foundation
import SpriteKit

class Duckable: SKSpriteNode {
    static func create() -> Duckable {
        let duckable = Duckable(color: .purple, size: CGSize(width: 20, height: 60))
        duckable.name = "Duckable"
        
        duckable.setupDuckablePhysics()
        
        return duckable
    }
    
    private func setupDuckablePhysics() {
        self.physicsBody = nil
        self.userData = ["obstacleType": "duckable"]
        
        // Create collision zone only on upper portion (60% of the obstacle)
        let collisionHeight = self.size.height * 0.4
        let collisionZone = SKSpriteNode(color: .clear, size: CGSize(width: self.size.width, height: collisionHeight))
        collisionZone.position = CGPoint(x: 0, y: self.size.height/2 - collisionHeight/2)
        collisionZone.physicsBody = SKPhysicsBody(rectangleOf: collisionZone.size)
        collisionZone.physicsBody?.isDynamic = false
        collisionZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        collisionZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        collisionZone.physicsBody?.collisionBitMask = PhysicsCategory.none
        collisionZone.name = "collisionZone"
        self.addChild(collisionZone)
        
        // Create visual indicator for duck zone (safe area)
        let duckZoneHeight = self.size.height * 0.6
        let duckZone = SKSpriteNode(color: .green, size: CGSize(width: self.size.width, height: duckZoneHeight))
        duckZone.position = CGPoint(x: 0, y: -self.size.height/2 + duckZoneHeight/2)
        duckZone.alpha = 0.3 // Make it semi-transparent to indicate it's a safe zone
        duckZone.name = "duckZone"
        self.addChild(duckZone)
    }
}

extension Duckable {
    func startMoving(across scene: SKScene) {
        let distance = scene.size.width + self.size.width * 2
        let duration = distance / Constants.gameSpeed * 2
        
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}
