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
    var coins: Int = 0
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
                EffectsFactory.shared.screenShake(strength: 0.5)
                
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
    func panContolledJump(swipeDistance: Double, target: SKNode? = nil) {
        guard self.currentState != .landing else { return }
        guard self.surfaceType.isGrounded && canJump else { return }
        
        // --- Call the appropriate jump based on the swipe distance ---
        if swipeDistance < 100 {
            // Short Swipe: Perform a normal jump.
            print("Short swipe detected (\(swipeDistance)). Performing Normal Jump.")
            normalJump()
        } else {
            // Long Swipe: Try to find a target for a high jump.
            print("Long swipe detected (\(swipeDistance)). Performing High Jump.")
            if let target = target {
                highJump(to: target)
            } else {
                // If no target is found for a high jump, fall back to a normal jump.
                normalJump()
            }
        }
    }
    
    func jump(targetPlatform: SKNode? = nil) {
        guard self.currentState != .landing else { return }
        guard self.surfaceType.isGrounded && canJump else { return }
        
        switch currentState {
        case .ducking:
            if let target = targetPlatform {
                highJump(to: target)
            } else {
                normalJump()
            }
        default:
            normalJump()
        }
    }

    private func normalJump() {
        canJump = false
        self.currentState = .airborne
        
        let adjustY = playerHitboxHeight * -0.125
        applyVerticalMovementTransformation(withYAdjustment: adjustY)
        
        // --- Define Jump Parameters ---
        let jumpHeight = defaultJumpHeight
        let horizontalDistance = defaultJumpDistance
        
        // --- Create and Run the Scripted Jump Action ---
        let startY = self.position.y
        let duration = horizontalDistance / 4 / gameSpeed
        
        self.physicsBody?.affectedByGravity = false
        
        EffectsFactory.shared.playSound(soundKey: "jump.mp3")
        EffectsFactory.shared.playHaptic(strength: 0.5)
        
        let jumpAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
            let t = elapsedTime / duration
            let easingT = 1 - pow(1 - t, 3) // Cubic ease-out
            node.position.y = startY + (jumpHeight * easingT)
        }
        
        let completion = SKAction.run {
            self.physicsBody?.affectedByGravity = true
            self.restoreOriginalShape()
            self.canJump = true
        }
        
        self.run(SKAction.sequence([jumpAction, completion]))
    }

    private func highJump(to targetPlatform: SKNode) {
        // Calculate jump parameters based on the target
        let jumpHeight = targetPlatform.position.y - self.position.y + playerHitboxHeight*2
        let horizontalDistance = max(defaultJumpDistance + gameSpeed/2, targetPlatform.position.x + playerHitboxWidth*2 - self.position.x)
        
        canJump = false
        self.currentState = .airborne
        
        let adjustY = playerHitboxHeight * -0.125
        applyVerticalMovementTransformation(withYAdjustment: adjustY)
        
        // --- Create and Run the Scripted Jump Action ---
        let startY = self.position.y
        let duration = horizontalDistance / 4 / gameSpeed
        
        self.physicsBody?.affectedByGravity = false
        
        // High jump
        EffectsFactory.shared.playSound(soundKey: "jump.mp3")
        EffectsFactory.shared.playHaptic(strength: 1.0)
        
        let jumpAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
            let t = elapsedTime / duration
            let easingT = 1 - pow(1 - t, 3) // Cubic ease-out
            node.position.y = startY + (jumpHeight * easingT)
        }
        
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
        // This line makes the player ignore semi-solid platforms.
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
        
        // **NEW**: Create an action to move the player down quickly.
        let moveAction = SKAction.moveBy(x: 0, y: -platformHeight*2, duration: 0.05)
        
        // This is the existing action that restores the collision rules after a delay.
        let wait = SKAction.wait(forDuration: 0.33)
        let restoreCollision = SKAction.run {
            self.setupPhysics()
        }
        let restoreSequence = SKAction.sequence([wait, restoreCollision])
        
        // Use a group to run both the downward movement and the restoration timer simultaneously.
        let groupAction = SKAction.group([moveAction, restoreSequence])
        
        run(groupAction)
    }
    
    private func performDive() {
        self.currentState = .diving
        self.canDive = false
        
        let adjustY = self.size.height * (0.34/2)
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
        
        EffectsFactory.shared.playSound(soundKey: "duck.wav")
        
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
        // Define the target shape: wider and shorter (the "duck" shape).
        let duckSize = CGSize(width: playerHitboxWidth + (playerHitboxHeight / 2),
                              height: playerHitboxHeight / 2)
        
        // 1. **Instantly** update the physics body to the final duck shape.
        let physicsSize = CGSize(width: duckSize.width * 0.9, height: duckSize.height)
        self.physicsBody = SKPhysicsBody(rectangleOf: physicsSize)
        setupPhysics()
        
        // 2. **Animate** the visual change smoothly over a short duration.
        let resizeAction = SKAction.resize(toWidth: duckSize.width,
                                           height: duckSize.height,
                                           duration: transformDuration)
        let moveAction = SKAction.moveBy(x: 0, y: adjustY, duration: transformDuration)
        
        // Run the visual animations together.
        self.run(SKAction.group([resizeAction, moveAction]))
    }

    private func applyVerticalMovementTransformation(withYAdjustment adjustY: CGFloat = 0) {
        // Define the target shape: narrower and taller.
        let jumpSize = CGSize(width: playerHitboxWidth * 0.67,
                              height: playerHitboxHeight * 1.33)
        
        // 1. **Instantly** update the physics body to the final jump shape.
        let physicsSize = CGSize(width: jumpSize.width * 0.9, height: jumpSize.height)
        self.physicsBody = SKPhysicsBody(rectangleOf: physicsSize)
        setupPhysics()
        
        // 2. **Animate** the visual change smoothly.
        let resizeAction = SKAction.resize(toWidth: jumpSize.width,
                                           height: jumpSize.height,
                                           duration: transformDuration)
        let moveAction = SKAction.moveBy(x: 0, y: adjustY, duration: transformDuration)
        
        self.run(SKAction.group([resizeAction, moveAction]))
    }

    private func restoreOriginalShape(withYAdjustment adjustY: CGFloat = 0) {
        let originalSize = CGSize(width: playerHitboxWidth, height: playerHitboxHeight)

        // 1. **Instantly** restore the physics body to the original shape.
        let physicsSize = CGSize(width: originalSize.width * 0.9, height: originalSize.height)
        self.physicsBody = SKPhysicsBody(rectangleOf: physicsSize)
        setupPhysics()

        // 2. **Animate** the visual restoration smoothly.
        let resizeAction = SKAction.resize(toWidth: originalSize.width,
                                           height: originalSize.height,
                                           duration: transformDuration)
        let moveAction = SKAction.moveBy(x: 0, y: adjustY, duration: transformDuration)
        
        self.run(SKAction.group([resizeAction, moveAction]))
    }
    
    // MARK: - Collision Handling
    func updateDistance(_ newDistance: Int) {
        distance = min(newDistance, 3)
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
    
    func applyPowerUp() {
        distance += 1
        updateDistance(distance)
    }
}
