import Foundation
import SpriteKit

class Moving: SKSpriteNode {
    static func create() -> Moving {
        let textureName = Bool.random() ? "bajaj" : "gojek"
        let texture = SKTexture(imageNamed: textureName)
        let desiredSize = CGSize(width: 120, height: 120) // adjust as needed
        let moving = Moving(texture: texture, color: .clear, size: desiredSize)
        moving.name = "Moving"
        
        // Setup physics body
        moving.physicsBody = SKPhysicsBody(rectangleOf: moving.size)
        moving.physicsBody?.isDynamic = false
        moving.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        moving.physicsBody?.contactTestBitMask = PhysicsCategory.player
        moving.physicsBody?.collisionBitMask = PhysicsCategory.none // No collision, only contact
        
//        // Add visual elements to make it look more like a motorcycle
//        let wheel1 = SKSpriteNode(color: .black, size: CGSize(width: 8, height: 8))
//        wheel1.position = CGPoint(x: -moving.size.width/3, y: -moving.size.height/2)
//        moving.addChild(wheel1)
//        
//        let wheel2 = SKSpriteNode(color: .black, size: CGSize(width: 8, height: 8))
//        wheel2.position = CGPoint(x: moving.size.width/3, y: -moving.size.height/2)
//        moving.addChild(wheel2)
//        
//        // Add wheel rotation animation
//        let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 0.5)
//        let repeatRotation = SKAction.repeatForever(rotateAction)
//        wheel1.run(repeatRotation)
//        wheel2.run(repeatRotation)
        
        return moving
    }
}

extension Moving {
    func startMoving(across scene: SKScene) {
        // The motorcycle will move from right to left across the entire screen
        let startX = scene.size.width + 100 // Start off-screen right
        let endX: CGFloat = -100  // End off-screen left
        
        // Set initial position
        self.position.x = startX
        
        // Calculate movement duration based on speed
        let movementSpeed: CGFloat = 800 // pixels per second
        let distance = abs(startX - endX)
        let duration = TimeInterval(distance / movementSpeed)
        
        // Create movement action
        let moveAction = SKAction.moveTo(x: endX, duration: duration)
        
        // Add slight vertical bobbing for more realistic movement
        let bobUp = SKAction.moveBy(x: 0, y: 5, duration: 0.3)
        let bobDown = SKAction.moveBy(x: 0, y: -5, duration: 0.3)
        let bobSequence = SKAction.sequence([bobUp, bobDown])
        let bobRepeat = SKAction.repeatForever(bobSequence)
        
        // Run both actions simultaneously
        let group = SKAction.group([moveAction, bobRepeat])
        
        // Remove the node after it completes its movement
        let removeAction = SKAction.removeFromParent()
        let fullSequence = SKAction.sequence([group, removeAction])
        
        self.run(fullSequence)
    }
}
