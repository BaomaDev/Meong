import Foundation
import SpriteKit

class Stepable: SKSpriteNode {
    static func create() -> Stepable {
        let textureName = Bool.random() ? "gerobak-1" : "gerobak-2"
        let texture = SKTexture(imageNamed: textureName)
        let desiredSize = CGSize(width: 200, height: 200) // adjust as needed
        let stepable = Stepable(texture: texture, color: .clear, size: desiredSize)
        stepable.name = "Stepable"
        
        // Setup the complex physics for stepable obstacle
        stepable.setupStepablePhysics()
        
        return stepable
    }
    
    private func setupStepablePhysics() {
        // Remove default physics body - we'll create custom zones
        self.physicsBody = nil
        self.userData = ["obstacleType": "stepable"]
        
        // Create safe zone on top (acts as ground for stepping)
        let safeZoneHeight: CGFloat = 15
        let safeZone = SKSpriteNode(color: .green, size: CGSize(width: self.size.width, height: safeZoneHeight))
        safeZone.position = CGPoint(x: 0, y: self.size.height/2 - safeZoneHeight/2)
        safeZone.physicsBody = SKPhysicsBody(rectangleOf: safeZone.size)
        safeZone.physicsBody?.isDynamic = false
        safeZone.physicsBody?.categoryBitMask = PhysicsCategory.ground // Acts as ground so player can stand on it
        safeZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        safeZone.physicsBody?.collisionBitMask = PhysicsCategory.player
        safeZone.name = "safeZone"
        self.addChild(safeZone)
        
        // Create damage zones on left and right sides
        let damageZoneWidth: CGFloat = 15
        let damageZoneHeight = self.size.height - safeZoneHeight // Exclude top safe area
        
        // Left damage zone
        let leftDamageZone = SKSpriteNode(color: .red, size: CGSize(width: damageZoneWidth, height: damageZoneHeight))
        leftDamageZone.position = CGPoint(x: -self.size.width/2 + damageZoneWidth/2, y: -safeZoneHeight/2)
        leftDamageZone.physicsBody = SKPhysicsBody(rectangleOf: leftDamageZone.size)
        leftDamageZone.physicsBody?.isDynamic = false
        leftDamageZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        leftDamageZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        leftDamageZone.physicsBody?.collisionBitMask = PhysicsCategory.none // No collision, just contact detection
        leftDamageZone.name = "damageZone"
        self.addChild(leftDamageZone)
        
        // Right damage zone
        let rightDamageZone = SKSpriteNode(color: .red, size: CGSize(width: damageZoneWidth, height: damageZoneHeight))
        rightDamageZone.position = CGPoint(x: self.size.width/2 - damageZoneWidth/2, y: -safeZoneHeight/2)
        rightDamageZone.physicsBody = SKPhysicsBody(rectangleOf: rightDamageZone.size)
        rightDamageZone.physicsBody?.isDynamic = false
        rightDamageZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        rightDamageZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        rightDamageZone.physicsBody?.collisionBitMask = PhysicsCategory.none // No collision, just contact detection
        rightDamageZone.name = "damageZone"
        self.addChild(rightDamageZone)
        
        // Bottom collision zone (prevents player from going through bottom)
        let bottomZoneHeight: CGFloat = 10
        let bottomZone = SKSpriteNode(color: .red, size: CGSize(width: self.size.width - 30, height: bottomZoneHeight))
        bottomZone.position = CGPoint(x: 0, y: -self.size.height/2 + bottomZoneHeight/2)
        bottomZone.physicsBody = SKPhysicsBody(rectangleOf: bottomZone.size)
        bottomZone.physicsBody?.isDynamic = false
        bottomZone.physicsBody?.categoryBitMask = PhysicsCategory.ground // Acts as solid ground
        bottomZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        bottomZone.physicsBody?.collisionBitMask = PhysicsCategory.player
        bottomZone.name = "bottomZone"
        self.addChild(bottomZone)
    }
}

extension Stepable {
    func startMoving(across scene: SKScene) {
        // Use the same game speed as other obstacles
        let distance = scene.size.width + self.size.width * 2
        let duration = distance / Constants.gameSpeed * 2
        
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        self.run(SKAction.sequence([moveAction, removeAction]))
    }
}
