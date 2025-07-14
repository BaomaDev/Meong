//
//  PlayerEntity.swift
//  ADA-CasualGame
//
//  Created by Jesse Robinson Junior Simanjuntak on 14/07/25.
//


import Foundation
import SpriteKit

class PlayerEntity: SKSpriteNode {
    // MARK: - Properties
    private var currentState: PlayerState = .falling
    private var currentSurface: SurfaceType = .none
    private var canJump = true
    private var isDropping = false
    private var isDucking = false
    private var isParrying = false
    
    // Parry system
    private var lastParryTime: TimeInterval = 0
    private var parryStartTime: TimeInterval = 0
    
    // Original dimensions for ducking
    private let originalSize = CGSize(width: Constants.playerHitboxWidth, height: Constants.playerHitboxHeight)
    
    // Taking hits
    var distance: Int = 3
    var hearts: Int = 9
    var isInvincible: Bool = false
    
    // MARK: - Computed Properties
    var state: PlayerState {
        return currentState
    }
    
    var surfaceType: SurfaceType {
        return currentSurface
    }
    
    var isGrounded: Bool {
        return currentSurface.isGrounded
    }
    
    var isInParryWindow: Bool {
        return isParrying && (CACurrentMediaTime() - parryStartTime < 0.3)
    }
    
    var canPerformJump: Bool {
        return currentSurface.isGrounded && canJump
    }
    
    var isInDropState: Bool {
        return isDropping
    }
    
    // MARK: - Initialization
    static func create(at position: CGPoint) -> PlayerEntity {
        let playerSize = CGSize(width: Constants.playerHitboxWidth, height: Constants.playerHitboxHeight)
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
        physicsBody?.linearDamping = Constants.airResistance
        physicsBody?.categoryBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
        physicsBody?.contactTestBitMask = PhysicsCategory.projectile | PhysicsCategory.obstacle
    }
    
    // MARK: - State Management
    func updateState(surfaceType: SurfaceType, velocity: CGVector) {
        let previousSurface = currentSurface
        currentSurface = surfaceType
        
        // Update player state based on surface and velocity
        if surfaceType.isGrounded {
            if isDucking {
                currentState = .ducking
            } else {
                currentState = .running
            }
        } else {
            currentState = velocity.dy > 0 ? .jumping : .falling
        }
        
        // Handle state transitions
        handleStateTransition(from: previousSurface, to: surfaceType)
        updateVisualState()
        updatePhysicsForMovement(velocity: velocity)
    }
    
    private func handleStateTransition(from previousSurface: SurfaceType, to newSurface: SurfaceType) {
        // Landing transition
        if !previousSurface.isGrounded && newSurface.isGrounded {
            canJump = true
        }
        
        // Takeoff transition
        if previousSurface.isGrounded && !newSurface.isGrounded {
            // Player left the ground
        }
    }
    
    private func updateVisualState() {
        if isParrying {
            color = .green
            return
        }
        
        switch currentState {
        case .running:
            color = .orange
        case .jumping, .falling:
            color = .yellow
        case .ducking:
            color = .red
        }
    }
    
    private func updatePhysicsForMovement(velocity: CGVector) {
        guard !isDropping else { return }
        
        if velocity.dy > 0 {
            // Moving up - only collide with ground and solid platforms
            physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
        } else {
            // Moving down - collide with everything
            physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
        }
    }
    
    // MARK: - Actions
    func jump(targetPlatform: SKNode? = nil) -> Bool {
        guard canPerformJump else { return false }
        
        canJump = false
        let jumpVelocity: CGFloat
        
        if let targetPlatform = targetPlatform {
            jumpVelocity = calculateJumpForce(to: targetPlatform)
        } else {
            jumpVelocity = Constants.jumpForce
        }
        
        physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpVelocity))
        
        return true
    }
    
    func duck() {
        guard currentSurface.isGrounded else { return }
        
        switch currentSurface {
        case .semiSolidPlatform:
            dropThroughPlatform()
        case .ground, .solidPlatform:
            performDuck()
        case .none:
            break
        }
    }
    
    func parry(currentTime: TimeInterval) -> Bool {
        let timeSinceLastParry = currentTime - lastParryTime
        guard timeSinceLastParry > Constants.parryCooldown else {
            print("Parry on cooldown: \(timeSinceLastParry) / \(Constants.parryCooldown)")
            return false
        }
        
        lastParryTime = currentTime
        isParrying = true
        parryStartTime = currentTime
        
        print("Parry activated!")
        
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
        isDropping = true
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
        
        let wait = SKAction.wait(forDuration: 0.5)
        let restoreCollision = SKAction.run { [weak self] in
            self?.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
            self?.isDropping = false
        }
        
        run(SKAction.sequence([wait, restoreCollision]))
    }
    
    private func performDuck() {
        isDucking = true
        
        let duckSize = CGSize(width: Constants.playerHitboxWidth + (Constants.playerHitboxHeight / 2),
                              height: Constants.playerHitboxHeight / 2)
        let adjustY = CGFloat(Constants.playerHitboxHeight / 4)
        
        // Apply duck transformation
        size = duckSize
        position.y -= adjustY
        physicsBody = SKPhysicsBody(rectangleOf: duckSize)
        setupPhysics()
        
        // Restore after duration
        let wait = SKAction.wait(forDuration: 0.5)
        let restore = SKAction.run { [weak self] in
            self?.restoreFromDuck(adjustY: adjustY)
        }
        
        run(SKAction.sequence([wait, restore]))
    }
    
    private func restoreFromDuck(adjustY: CGFloat) {
        isDucking = false
        size = originalSize
        position.y += adjustY
        physicsBody = SKPhysicsBody(rectangleOf: originalSize)
        setupPhysics()
    }
    
    private func calculateJumpForce(to targetPlatform: SKNode) -> CGFloat {
        let playerX = position.x
        let platformSize = targetPlatform.frame.size
        let targetPos = targetPlatform.position
        let platformLeftEdge = targetPos.x - (platformSize.width / 2)
        let platformRightEdge = targetPos.x + (platformSize.width / 2)
        
        let isUnderPlatform = (playerX >= platformLeftEdge && playerX <= platformRightEdge)
        
        if isUnderPlatform {
            return 1.5 * (targetPos.y - position.y)
        } else {
            return calculateMinimumJumpForce(to: targetPos.y, distanceX: platformLeftEdge - playerX)
        }
    }
    
    private func calculateMinimumJumpForce(to targetY: CGFloat, distanceX: CGFloat) -> CGFloat {
        let startY = position.y + Constants.playerHitboxHeight
        let distanceY = targetY - startY
        
        let idealVelocity = sqrt(-2 * Constants.gravity * distanceY)
        
        let minJumpDistance = Constants.jumpSnapRayLength / 4
        let xyRatio = min(1.9, max(1.4, distanceX / minJumpDistance))
        let resistanceCompensation: CGFloat = sqrt(Constants.airResistance) * xyRatio
        
        return idealVelocity * resistanceCompensation
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

        print("Player was hit by a projectile!")
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

        print("Player was hit by an obstacle!")
    }
}
