import Foundation
import SpriteKit

class NoTouch: SKSpriteNode {
    static func create() -> NoTouch {
        let notouch = NoTouch(color: .red, size: CGSize(width: 10, height: 30))
        notouch.name = "Projectile"
        
        notouch.physicsBody = SKPhysicsBody(rectangleOf: notouch.size)
        notouch.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        notouch.physicsBody?.affectedByGravity = false       // Exclude from gravity; projectiles have more predictable parabolic trajectories.
        notouch.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect contact with player
        notouch.physicsBody?.collisionBitMask = PhysicsCategory.none     // Can move through air
        
        return notouch
    }
}

extension NoTouch {
    func startMoving(across scene: SKScene) {
        // Menggunakan game speed yang sama dengan platform
        let distance = worldMoveDistance
        let duration = round(distance / gameSpeed / speedScalingStep) * speedScalingStep
        
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}
