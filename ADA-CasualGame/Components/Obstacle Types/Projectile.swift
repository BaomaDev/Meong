import Foundation
import SpriteKit

class Projectile: SKSpriteNode {
    static func create() -> Projectile {
        let projectile = Projectile(color: .red, size: CGSize(width: 20, height: 20))
        projectile.name = "Projectile"
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.affectedByGravity = false       // Exclude from gravity; projectiles have more predictable parabolic trajectories.
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.player // Detect contact with player
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none     // Can move through air
        
        return projectile
    }
}

// Extension to handle spawning logic
extension GameScene {
    func spawnProjectile() {
        let projectile = Projectile.create()
        
        let projectileSpeed: CGFloat = min(gameSpeed * 2, 800)
        
        // Calculate a parabolic arc in which the projectile will travel
        var startPoint: CGPoint
        var endPoint: CGPoint
        var controlPoint: CGPoint // This point "pulls" the line to create a curve.

        let startX = self.size.width
        let endX: CGFloat = 50

        // 4 throw types are defined; for now when a projectile is spawned, select one at random.
        // TODO: Select throw type based on player location
        let throwType = Int.random(in: 0...3)

        switch throwType {
        case 0:
            // --- 1. Low Arc, Aimed Low -> Forces jumping / ducking ---
            startPoint = CGPoint(x: startX, y: 100)
            endPoint = CGPoint(x: endX, y: 75)
            controlPoint = CGPoint(x: self.size.width / 2, y: 300)
//            print("Path: Low Arc")

        case 1:
            // --- 2. High Arc, Aimed Low -> Hits when on Platform ---
            startPoint = CGPoint(x: startX, y: 250)
            endPoint = CGPoint(x: endX, y: 150)
            controlPoint = CGPoint(x: self.size.width / 2, y: 550)
//            print("Path: High Arc")

        case 2:
            // --- 3. Low Arc, Aimed High -> Hits player when jumping up to platform or dropping down ---
            startPoint = CGPoint(x: startX, y: 150)
            endPoint = CGPoint(x: endX, y: 250)
            controlPoint = CGPoint(x: self.size.width / 2, y: 350)
//            print("Path: Upward Arc")
            
        case 3:
            // --- 4. Diving Arc -> Accute angle of attack, forces jumping ---
            startPoint = CGPoint(x: startX, y: 450)
            endPoint = CGPoint(x: endX, y: 150)
            controlPoint = CGPoint(x: self.size.width * 0.8, y: 475) 
//            print("Path: Diving Arc")
        default:
            return
        }
        
        // Create the path
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)
        
        // Move the projectile at a set speed along the path
        let followAction = SKAction.follow(path, asOffset: false, orientToPath: false, speed: projectileSpeed)
        let removeAction = SKAction.removeFromParent()
        
        self.addChild(projectile)
        projectile.run(SKAction.sequence([followAction, removeAction]))
    }
    
    // Initializer
    func startSpawningProjectiles() {
        let spawnAction = SKAction.run(spawnProjectile)
        let waitAction = SKAction.wait(forDuration: 5.0, withRange: 2.0)    // Spawn every 2 ~ 4 seconds
        
        run(SKAction.repeatForever(SKAction.sequence([spawnAction, waitAction])))
    }
}
