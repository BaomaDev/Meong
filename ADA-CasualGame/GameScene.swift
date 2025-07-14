import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Properties
    var player: SKSpriteNode?
    var swipeUpRecognizer: UISwipeGestureRecognizer?
    var swipeDownRecognizer: UISwipeGestureRecognizer?
    
    var currentSurface: SurfaceType = .none
    var canJump = true
    var isDropping = false

    // Timers to implement cooldown
    var lastUpdateTime: TimeInterval = 0
    var lastParryTime: TimeInterval = 0

    // MARK: - Scene Lifecycle (Initializers)
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.1, alpha: 1.0)
        physicsWorld.gravity = CGVector(dx: 0, dy: Constants.gravity)
        physicsWorld.contactDelegate = self

        createGround()
        createPlayer()
        setupSwipeRecognizers()
        startSpawningPlatforms()
        startSpawningProjectiles()
    }
    
    override func update(_ currentTime: TimeInterval) {
        self.lastUpdateTime = currentTime
        let previousSurface = currentSurface
        currentSurface = getSurfaceType()

        if !previousSurface.isGrounded && currentSurface.isGrounded {
            player?.color = .orange
            canJump = true
        }
        
        if previousSurface.isGrounded && !currentSurface.isGrounded {
            player?.color = .yellow
        }
        
        if !isDropping {
            if let playerVelocity = player?.physicsBody?.velocity.dy, playerVelocity > 0 {
                // When moving up, collide with ground and solid platforms.
                player?.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
            } else {
                // When moving down, collide with everything.
                player?.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
            }
        }
        
        // Remove projectiles that are off screen
        self.enumerateChildNodes(withName: "Projectile") { (node, stop) in
            if node.position.x < -50 || node.position.y < -50 {
                node.removeFromParent()
            }
        }
    }

    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody

        // Order the bodies by their category bitmask for consistent checks
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }

        // Check for collision between player and projectile
        if firstBody.categoryBitMask == PhysicsCategory.player && secondBody.categoryBitMask == PhysicsCategory.projectile {
            print("Player was hit by a projectile!")
            // Remove the projectile that hit the player
            secondBody.node?.removeFromParent()
        }
    }
    
    func didEnd(_ contact: SKPhysicsContact) { }
}
