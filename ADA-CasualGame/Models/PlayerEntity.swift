import Foundation
import SpriteKit

class PlayerEntity: SKSpriteNode {
    // MARK: - Properties
    var currentState: PlayerState = .airborne
    var currentSurface: SurfaceType = .none
    private let originalSize = CGSize(width: playerHitboxWidth, height: playerHitboxHeight)
    
    // Movement Variables
    var canJump = true
    var canDuck = true
    var canDive = false
    var isParrying = false
    
    var queuedAction: MovementAction?
    
    var lastParryTime: TimeInterval = 0
    var parryStartTime: TimeInterval = 0
    
    var isInParryWindow: Bool {
        return isParrying && (CACurrentMediaTime() - parryStartTime < 0.3)
    }
    
    // Health / Distance
    var distance: Int = 3
    var hearts: Int = 9
    var coins: Int = 0

    var isInvincible: Bool = false
    
    // Particles
    var lastParticleTime: TimeInterval = 0
    let particleInterval: TimeInterval = 0.05
    
    // MARK: - Initialization
    static func create(at position: CGPoint) -> PlayerEntity {
        let texture = SKTexture(imageNamed: "CatRunning_00000")
        let playerSize = CGSize(width: playerHitboxWidth, height: playerHitboxHeight)
        let player = PlayerEntity(texture: texture, color: .clear, size: playerSize)
        player.name = "Player"
        
        // let playerSize = CGSize(width: playerHitboxWidth, height: playerHitboxHeight)
        //let player = PlayerEntity(color: .yellow, size: playerSize)
        player.position = position
        // player.name = "Player"
        
        // Setup physics
        player.physicsBody = SKPhysicsBody(rectangleOf: playerSize)
        player.setupPhysics()
        
        let xConstraint = SKConstraint.positionX(SKRange(constantValue: player.position.x))
        player.constraints = [xConstraint]
        
        player.startRunningAnimation()
        
        return player
    }
    
    // MARK: - Physics Setup
    func setupPhysics() {
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = false
        physicsBody?.restitution = 0.0
        physicsBody?.linearDamping = airResistance
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
        physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.obstacle
    }
    
    // MARK: - Collision Handling
    func updateDistance(_ newDistance: Int) {
        distance = min(newDistance, 3)
        GameState.shared.playerDistance = newDistance
    }
    
    func handleProjectileHit(projectileNode: SKNode) {
        knockAway(node: projectileNode)
        guard !isInvincible else { return }
        
        hearts -= 1
        distance -= 1
        updateDistance(distance)  // ✅ Implementasikan updateDistance sesuai kebutuhan
        isInvincible = true
        
        // Nonaktifkan kontak sementara dengan projectile
        physicsBody?.contactTestBitMask &= ~PhysicsCategory.projectile
        physicsBody?.collisionBitMask &= ~PhysicsCategory.projectile
        
        EffectsFactory.shared.playSound(soundKey: "hurt.mp3", volumeKey: 1.5)
        EffectsFactory.shared.playHaptic(intensity: 1.0, sharpness: 0.1, type: .hapticContinuous, duration: 0.3)
        
        // Blink effect
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        let repeatBlink = SKAction.repeat(blink, count: 5)
        self.run(repeatBlink)
        
        // Waktu invincibility
        let wait = SKAction.wait(forDuration: 1.0)
        let reset = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isInvincible = false
            self.setupPhysics() // Kembalikan bitmask ke default
        }
        
        self.run(SKAction.sequence([wait, reset]))
        
        //        print("Player was hit by a projectile!")
    }
    
    func handleObstacleHit(obstacleNode: SKNode) {
        knockAway(node: obstacleNode)
        guard !isInvincible else { return }

        hearts -= 1
        distance -= 1
        updateDistance(distance)
        isInvincible = true

        // ✅ Safely unwrap physicsBody before modifying
        if let body = self.physicsBody {
            body.contactTestBitMask &= ~PhysicsCategory.obstacle
            body.collisionBitMask &= ~PhysicsCategory.obstacle
        } else {
            print("⚠️ Warning: physicsBody is nil during obstacle hit!")
        }
        
        EffectsFactory.shared.playSound(soundKey: "hurt.mp3", volumeKey: 1.5)
        EffectsFactory.shared.playHaptic(intensity: 2.0, sharpness: 0.1, type: .hapticContinuous, duration: 0.3)

        // Blink effect
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        let repeatBlink = SKAction.repeat(blink, count: 5)
        self.run(repeatBlink)

        // Restore physics after invincibility ends
        let wait = SKAction.wait(forDuration: 1.0)
        let reset = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isInvincible = false
            self.setupPhysics()
        }

        self.run(SKAction.sequence([wait, reset]))
    }
    
    func applyPowerUp() {
        distance += 1
        updateDistance(distance)
    }
    
    func applyCatnip() {
        let isInCatnipMode = currentState == .flying
        guard !isInCatnipMode else { return }
        currentState = .flying
        isInvincible = true

        // This ensures the player is not stuck in a blinking, stretched, or ducked state.
        self.removeAllActions() // Stop any ongoing visual animations (like blinking or stretching)
        self.alpha = 1.0        // Ensure player is fully visible
        restoreOriginalShape()  // Reset size and physics body to default

        // Modify physics and game settings
        gameSpeed *= 2.0
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.contactTestBitMask = 0
        self.physicsBody?.collisionBitMask = 0

        let fixedHoverY: CGFloat = 280

        let flyToFixedY = SKAction.moveTo(y: fixedHoverY, duration: 0.6)
        flyToFixedY.timingMode = .easeOut

        let hoverUp = SKAction.moveBy(x: 0, y: 15, duration: 0.3)
        let hoverDown = SKAction.moveBy(x: 0, y: -15, duration: 0.3)
        let singleHoverCycle = SKAction.sequence([hoverUp, hoverDown])

        let catnipDuration: TimeInterval = 5.0
        let hoverRepetitions = Int(catnipDuration / (hoverUp.duration + hoverDown.duration))
        let remainingWaitTime = catnipDuration.truncatingRemainder(dividingBy: (hoverUp.duration + hoverDown.duration))

        let catnipTimer = SKAction.sequence([
            flyToFixedY,
            SKAction.repeat(singleHoverCycle, count: hoverRepetitions),
            SKAction.wait(forDuration: remainingWaitTime),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                // Clean up catnip specific actions/states
                self.removeAction(forKey: "catnipModeSequence") // Remove the sequence itself
                self.isInvincible = false
                self.currentState = .airborne
                gameSpeed /= 2.0
                
                // Restore original physics and visual state
                self.setupPhysics()
                self.physicsBody?.affectedByGravity = true
                self.alpha = 1.0 // Ensure alpha is reset if it wasn't already
                self.restoreOriginalShape() // Crucial for resetting size after catnip
            }
        ])

        self.run(catnipTimer, withKey: "catnipModeSequence")
    }
    
    private func knockAway(node: SKNode) {
        // 1. Change the physics so the object can fly freely.
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
        node.physicsBody?.contactTestBitMask = PhysicsCategory.none
        node.physicsBody?.affectedByGravity = true
        
        // 2. Apply a strong upward and rightward impulse to send it flying off-screen.
        let knockbackImpulse = CGVector(dx: 150, dy: 300)
        node.physicsBody?.applyImpulse(knockbackImpulse)
        
        // 3. Apply a comical rotation effect.
        let spinAction = SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.5))
        node.run(spinAction)
        
        // TODO: Play knock sound effect
        
        // The existing cleanup logic in GameScene's update() will remove the node once it's off-screen.
    }
    
    func startRunningAnimation() {
        // Generate texture names based on your file naming
        let textureNames = (0...11).map { String(format: "CatRunning_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

        // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.08, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "runAnimation")
    }
    
    func stopRunningAnimation() {
        self.removeAction(forKey: "runAnimation")
    }
}
