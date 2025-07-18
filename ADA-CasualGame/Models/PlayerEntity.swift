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
    private var queuedAction: MovementAction?
    
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
        
        // If a duck command is queued, perform that first.
        if self.currentState != .ducking && self.queuedAction == .duck {
            if self.currentState == .airborne { // Override checking
                self.performDuck()
            } else {
                self.duck()
            }
            self.queuedAction = nil
            return
        }
        
        if currentSurface.isGrounded && !previousSurface.isGrounded {
            // Check HOW we landed.
            if previousState == .diving {
                hardLanding()
                
            } else {
                softLanding()
            }
            
        } else if !currentSurface.isGrounded && previousSurface.isGrounded {
            handleGoingAirborne()
        }
        
        self.surfaceType = currentSurface
        updateColor()
    }
    
    private func handleGoingAirborne() {
        // Falling or jumping
        self.currentState = .airborne
        self.canDive = true
        
//        if let playerVelocity = physicsBody?.velocity.dy, playerVelocity < 0 {
//            // Moving up - only collide with ground and solid platforms
//            physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
//        } else {
//            // Moving down - collide with everything
//            physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
//        }
    }
    
    private func updateColor() {
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
    
    private func hardLanding() {
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
    }
    
    private func softLanding() {
        // If a queued action exists, perform that first
        if let action = self.queuedAction {
            switch action {
            case .normalJump:
                self.normalJump()
            case .highJump:
                self.highJump()
            default:
                break
            }
            // Clear the queue after executing.
            self.queuedAction = nil
            return
        } else {
            // It was a normal landing, so we can run immediately.
            self.currentState = .running
        }
    }
    
    // MARK: - Actions
    func jump(swipeDistance: Double) {
        guard self.currentState != .landing else { return }
        guard self.surfaceType.isGrounded && canJump else {
            if isCloseToGround() {
                if swipeDistance < longSwipeTreshold {
//                    print("queueing normal jump")
                    queuedAction = .normalJump
                } else {
//                    print("queueing high jump")
                    queuedAction = .highJump
                }
            }
            return
        }
        
        // --- Call the appropriate jump based on the swipe distance ---
        if swipeDistance < longSwipeTreshold {
            normalJump()
        } else {
            highJump()
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
    
    private func checkForSolidPlatform() -> Bool {
        // --- Raycast 1: Check Directly Above ---
        let verticalRayStart = self.position
        // The ray should be long enough to check the entire potential jump path.
        let verticalRayEnd = CGPoint(x: self.position.x, y: self.position.y + platformHeight)
        
        var isBlocked = false
        self.scene?.physicsWorld.enumerateBodies(alongRayStart: verticalRayStart, end: verticalRayEnd) { (body, point, normal, stop) in
            if body.node?.name == "SolidPlatform" {
                isBlocked = true
                stop.pointee = true // Stop searching once a block is found.
            }
        }
        
        // If the vertical path is blocked, we don't need to check again.
        if isBlocked {
            return true
        }
        
        // --- Raycast 2: Check Diagonally Forward ---
        // This ray checks the space the player will jump into.
        let diagonalRayStart = self.position
        // The horizontal component (e.g., +75) creates the acute angle.
        let diagonalRayEnd = CGPoint(x: self.position.x + 75, y: self.position.y + platformHeight)
        
        self.scene?.physicsWorld.enumerateBodies(alongRayStart: diagonalRayStart, end: diagonalRayEnd) { (body, point, normal, stop) in
            if body.node?.name == "SolidPlatform" {
                isBlocked = true
                stop.pointee = true
            }
        }
        
        return isBlocked
    }
    
    private func highJump() {
        var jumpAction: SKAction
        var wait: SKAction
        let restoreAction = SKAction.run {
            self.restoreOriginalShape()
            self.canJump = true
        }

        // --- 1. Set up the common properties for any jump ---
        canJump = false
        self.currentState = .airborne
        let adjustY = playerHitboxHeight * -0.125
        applyVerticalMovementTransformation(withYAdjustment: adjustY)

        // --- 2. Decide which type of jump to perform ---
        if checkForSolidPlatform() {
            jumpAction = SKAction.run {
                self.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                self.physicsBody?.applyImpulse(CGVector(dx: 0, dy: defaultJumpHeight*1.5))
            }

            wait = SKAction.wait(forDuration: 0.5)

        } else {
            let jumpHeight = defaultJumpHeight * 2
            let horizontalDistance = defaultJumpDistance + gameSpeed/2
            
            let startY = self.position.y
            let duration = horizontalDistance / 4 / gameSpeed
            
            jumpAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
                let t = elapsedTime / duration
                let easingT = 1 - pow(1 - t, 3) // Cubic ease-out
                node.position.y = startY + (jumpHeight * easingT)
            }
            
            wait = SKAction.wait(forDuration: 0)
        }
        
        // Play effects for either jump type
        EffectsFactory.shared.playSound(soundKey: "jump.mp3") // Or highJump.mp3
        EffectsFactory.shared.playHaptic(strength: 1.0)
        
        // Run the chosen jumpAction followed by its corresponding completion action.
        self.run(SKAction.sequence([jumpAction, wait, restoreAction]))
    }
    
    func duck() {
        guard self.currentState != .landing else {return}
        if self.currentState == .ducking {
            self.queuedAction = .duck
            return
        }
        
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
        let moveAction = SKAction.moveBy(x: 0, y: -platformThickness*2, duration: 0.05)
        
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
        guard isCloseToGround() == false else {
            self.queuedAction = .duck
            return
        }
        
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
        let duckSize = CGSize(width: playerHitboxWidth * 1.33,
                              height: playerHitboxHeight * 0.67)
        
        // 1. **Instantly** update the physics body to the final duck shape.
        let physicsSize = CGSize(width: duckSize.width, height: duckSize.height)
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
        let physicsSize = CGSize(width: jumpSize.width, height: jumpSize.height)
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
        let physicsSize = CGSize(width: originalSize.width, height: originalSize.height)
        self.physicsBody = SKPhysicsBody(rectangleOf: physicsSize)
        setupPhysics()

        // 2. **Animate** the visual restoration smoothly.
        let resizeAction = SKAction.resize(toWidth: originalSize.width,
                                           height: originalSize.height,
                                           duration: transformDuration)
        let moveAction = SKAction.moveBy(x: 0, y: adjustY, duration: transformDuration)
        
        self.run(SKAction.group([resizeAction, moveAction]))
    }
    
    private func isCloseToGround() -> Bool {
        let playerFeetY = self.position.y - (self.size.height / 2)
        let distanceToGround = playerFeetY - groundHeight
        
        return distanceToGround <= (defaultJumpHeight / 2)
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
        hearts += 1
        updateDistance(distance)
    }
}
