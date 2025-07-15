import Foundation
import SpriteKit

class PlayerEntity: SKSpriteNode {
    // MARK: - Properties
    var currentState: PlayerState = .airborne
    
    private var currentSurface: SurfaceType = .none
    private var canJump = true
    private var canDuck = true
    private var canDive = false
    private var isParrying = false
    
    // Parry system
    private var lastParryTime: TimeInterval = 0
    private var parryStartTime: TimeInterval = 0
    
    // Original dimensions for ducking
    private let originalSize = CGSize(width: playerHitboxWidth, height: playerHitboxHeight)
    
    // Taking hits
    var distance: Int = 3
    var hearts: Int = 9
    var isInvincible: Bool = false
    
    // MARK: - Computed Properties
    var state: PlayerState {
        return currentState
    }
    
    var surfaceType: SurfaceType = .none
    
    var isGrounded: Bool {
        return currentSurface.isGrounded
    }
    
    var isInParryWindow: Bool {
        return isParrying && (CACurrentMediaTime() - parryStartTime < 0.3)
    }
    
    // MARK: - Initialization
    static func create(at position: CGPoint) -> PlayerEntity {
        let playerSize = CGSize(width: playerHitboxWidth, height: playerHitboxHeight)
        let player = PlayerEntity(color: .yellow, size: playerSize)
        player.position = position
        player.name = "Player"
        
        // Setup physics
        player.physicsBody = SKPhysicsBody(rectangleOf: playerSize)
        player.setupPhysics()
        
        return player
    }
    
    // MARK: - Physics Setup
    private func setupPhysics() {
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = false
        physicsBody?.restitution = 0.0
        physicsBody?.linearDamping = airResistance
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
        physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.obstacle
    }
    
    // MARK: - State Management
    func updateState(currentSurface: SurfaceType) {
        guard self.currentState != .landing else {return}
        let previousState = self.currentState
        let previousSurface = self.surfaceType
        
        if currentSurface.isGrounded && !previousSurface.isGrounded {
            // Check HOW we landed.
            if previousState == .diving {
                restoreOriginalShape()
                // If we landed from a dive, enter the .landing state via an action.
                self.currentState = .landing
                
                let wait = SKAction.wait(forDuration: landingDuration)
                let transitionToRunning = SKAction.run {
                    if self.currentState == .landing {
                        self.currentState = .running
                    }
                }
                
                self.run(SKAction.sequence([wait, transitionToRunning]))
                
            } else {
                // It was a normal landing, so we can run immediately.
                self.currentState = .running
            }
        } else if !currentSurface.isGrounded && previousSurface.isGrounded {
            // Falling or jumping
            self.currentState = .airborne
            self.canDive = true
        }
        self.surfaceType = currentSurface
        
        if isParrying {
            color = .green
            return
        }
        
        switch currentState {
        case .running:
            color = .orange
        case .airborne:
            color = .orange
        case .ducking:
            color = .red
        case .diving:
            color = .orange
        case .landing:
            color = .red
        default:
            color = .orange
        }
    }
    
    // MARK: - Actions
    func jump(targetPlatform: SKNode? = nil) {
        // 1. Check if the player can perform an action.
        guard self.currentState != .landing else {return}
        guard self.currentState == .running && canJump else { return }
//        print("trying to jump! -> state:\(self.currentState); canJump: \(self.canJump)")
        
        canJump = false
        self.currentState = .airborne
        
        let adjustY = playerHitboxHeight * -0.125
        applyVerticalMovementTransformation(withYAdjustment: adjustY)
        
        // --- 2. Determine Jump Parameters ---
        
        var jumpHeight: CGFloat
        var horizontalDistance: CGFloat
        
        if let targetPlatform = targetPlatform {
            let playerHeight = self.frame.height
            let platformHeight = platformHeight + playerHeight/2
            
            // The vertical distance from the top of the player to the top of the platform.
            jumpHeight = targetPlatform.position.y + platformHeight - self.position.y + playerHeight
            // The horizontal distance determines the duration of the jump.
            let minJumpDistance = max(gameSpeed/3 , defaultJumpDistance)
            horizontalDistance = max(minJumpDistance, targetPlatform.position.x - self.position.x)
            
        } else {
            jumpHeight = defaultJumpHeight
            // A fixed horizontal distance for the default jump's timing.
            horizontalDistance = defaultJumpDistance
        }
        // --- 3. Create and Run the Scripted Jump Action ---
        
        let startY = self.position.y
        // The duration of our vertical animation is timed to the world's horizontal movement.
        let duration = horizontalDistance / 4 / gameSpeed
        
        // Temporarily disable gravity while the scripted action is running.
        self.physicsBody?.affectedByGravity = false
        
        // Create the custom action.
        let jumpAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
            // 't' is the progress of the action from 0.0 to 1.0.
            let t = elapsedTime / duration
            
//            let easingT = sin(t * .pi / 2)
            let easingT = 1 - pow(1 - t, 3) // Cubic ease-out
            
            // Calculate the new Y position.
            node.position.y = startY + (jumpHeight * easingT)
        }
        
        // When the action is complete, re-enable gravity to let the player fall.
        let completion = SKAction.run {
            self.physicsBody?.affectedByGravity = true
            self.restoreOriginalShape()
            self.canJump = true
        }
        
        self.run(SKAction.sequence([jumpAction, completion]))
    }
    
    func duck() {
        guard self.currentState != .landing else {return}
        
        switch surfaceType {
        case .semiSolidPlatform:
            dropThroughPlatform()
        case .ground, .solidPlatform:
            performDuck()
        case .none:
            performDive()
        }
    }
    
    func parry(currentTime: TimeInterval) -> Bool {
        guard self.currentState != .landing else {return false}
        let timeSinceLastParry = currentTime - lastParryTime
        guard timeSinceLastParry > parryCooldown else {
//            print("Parry on cooldown: \(timeSinceLastParry) / \(parryCooldown)")
            return false
        }
        
        lastParryTime = currentTime
        isParrying = true
        parryStartTime = currentTime
        
//        print("Parry activated!")
        
        // Visual feedback with SKAction
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let endParry = SKAction.run { [weak self] in
            self?.isParrying = false
        }
        
        run(SKAction.sequence([scaleUp, scaleDown, endParry]))
        
        return true
    }
    
    // MARK: - Private Action Helpers
    private func dropThroughPlatform() {
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
        
        let wait = SKAction.wait(forDuration: 0.33)
        let restoreCollision = SKAction.run {
            self.setupPhysics()
        }
        
        run(SKAction.sequence([wait, restoreCollision]))
    }
    
    private func performDive() {
        self.currentState = .diving
        self.canDive = false
        
        let adjustY = playerHitboxHeight * -0.125
        applyVerticalMovementTransformation(withYAdjustment: adjustY)
        
        // 3. Apply a sharp downward impulse.
        // Resetting vertical velocity first makes the dive feel consistent.
        self.physicsBody?.velocity.dy = 0
        self.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -diveForce))
    }
    
    private func performDuck() {
        self.currentState = .ducking
        self.canDuck = false
        
        let adjustY = CGFloat(-playerHitboxHeight / 4)
        applyHorizontalMovementTransformation(withYAdjustment: adjustY)
        
        // Restore after duration
        let wait = SKAction.wait(forDuration: 0.75)
        let restore = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.restoreOriginalShape(withYAdjustment: adjustY)
            self.currentState = .running
            self.canDuck = true
        }
        
        run(SKAction.sequence([wait, restore]))
    }
    
    private func applyHorizontalMovementTransformation(withYAdjustment adjustY: CGFloat = 0) {
        // Define the new shape: wider and shorter (the "duck" shape).
        let duckSize = CGSize(width: playerHitboxWidth + (playerHitboxHeight / 2),
                              height: playerHitboxHeight / 2)
        
        // Apply the new size and Y-position adjustment.
        self.size = duckSize
        self.position.y += adjustY
        
        // Create an inset physics body for the new "duck" shape to prevent snagging on edges.
        let physicsSize = CGSize(width: duckSize.width * 0.9, height: duckSize.height)
        self.physicsBody = SKPhysicsBody(rectangleOf: physicsSize)
        
        setupPhysics() // Assuming this is your function to re-apply physics properties
    }

    private func applyVerticalMovementTransformation(withYAdjustment adjustY: CGFloat = 0) {
        // Define the new shape: narrower and taller.
        let jumpSize = CGSize(width: playerHitboxWidth * 0.67,
                              height: playerHitboxHeight * 1.33)
        
        // Apply the new size and Y-position adjustment.
        self.size = jumpSize
        self.position.y += adjustY
        
        // Create an inset physics body for the new "jump" shape.
        let physicsSize = CGSize(width: jumpSize.width, height: jumpSize.height)
        self.physicsBody = SKPhysicsBody(rectangleOf: physicsSize)
        
        setupPhysics()
    }

    private func restoreOriginalShape(withYAdjustment adjustY: CGFloat = 0) {
        let originalSize = CGSize(width: playerHitboxWidth, height: playerHitboxHeight)
        self.size = originalSize
        self.position.y += adjustY
        
        // Create an inset physics body for the original shape
        let physicsSize = CGSize(width: originalSize.width, height: originalSize.height)
        self.physicsBody = SKPhysicsBody(rectangleOf: physicsSize)
        
        setupPhysics()
    }
    
    // MARK: - Collision Handling
    func updateDistance(_ newDistance: Int) {
        distance = newDistance
        GameState.shared.playerDistance = newDistance
    }
    
    func handleProjectileHit() {
        guard !isInvincible else { return }

        hearts -= 1
        distance -= 1
        updateDistance(distance)  // ✅ Implementasikan updateDistance sesuai kebutuhan
        isInvincible = true

        // Nonaktifkan kontak sementara dengan projectile
        physicsBody?.contactTestBitMask &= ~PhysicsCategory.projectile
        physicsBody?.collisionBitMask &= ~PhysicsCategory.projectile

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
    
    func handleObstacleHit() {
        guard !isInvincible else { return }

        hearts -= 1
        distance -= 1
        updateDistance(distance)
        isInvincible = true

        // Nonaktifkan kontak sementara dengan obstacle
        physicsBody?.contactTestBitMask &= ~PhysicsCategory.obstacle
        physicsBody?.collisionBitMask &= ~PhysicsCategory.obstacle

        // Blink effect (sama seperti projectile hit)
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

//        print("Player was hit by an obstacle!")
    }
}
