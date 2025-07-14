import Foundation
import SpriteKit

class NoTouch: SKSpriteNode {
    static func create() -> NoTouch {
        let notouch = NoTouch(color: .red, size: CGSize(width: 20, height: 20))
        notouch.name = "Projectile"
        
        notouch.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        notouch.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        notouch.physicsBody?.affectedByGravity = false       // Exclude from gravity; projectiles have more predictable parabolic trajectories.
        notouch.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect contact with player
        notouch.physicsBody?.collisionBitMask = PhysicsCategory.none     // Can move through air
        
        return notouch
    }
}
