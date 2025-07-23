//
//  PlayerMovement.swift
//  ADA-CasualGame
//
//  Created by Savio Enoson on 23/07/25.
//

import Foundation
import SpriteKit

extension PlayerEntity {
    // MARK: - Jump
    func jump(swipeDistance: Double) {
        guard self.currentState != .landing else { return }
        guard self.currentSurface.isGrounded && canJump else {
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
        
        EffectsFactory.shared.playSound(soundKey: "jump.mp3", volumeKey: 1.0)
//        EffectsFactory.shared.playSound(soundKey: "normaljump.mp3")
//        EffectsFactory.shared.playHaptic(strength: 0.5)
        
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
    
    private func highJump() {
        guard self.position.y <= platformHeight else {
            normalJump()
            return
        }
        
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
        EffectsFactory.shared.playSound(soundKey: "highjumpie.mp3", volumeKey: 1.0) // Or highJump.mp3
        EffectsFactory.shared.playSound(soundKey: "highJump.mp3", volumeKey: 1.0)
//        EffectsFactory.shared.playHaptic(strength: 1.0)
        
        // Run the chosen jumpAction followed by its corresponding completion action.
        self.run(SKAction.sequence([jumpAction, wait, restoreAction]))
    }
    
    // MARK: - Duck / Dive
    func duck() {
        guard self.currentState != .landing else {return}
        if self.currentState == .ducking {
            self.queuedAction = .duck
            return
        }
        
        switch currentSurface {
        case .semiSolidPlatform:
            dropThroughPlatform()
        case .ground, .solidPlatform:
            performDuck()
        case .none:
            performDive()
        }
    }
    
    private func performDive() {
        guard !isInCatnipMode else { return }
        
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
        
        EffectsFactory.shared.playSound(soundKey: "duck.wav", volumeKey: 1.0)
        
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
    
    // MARK: - Parry
    
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
    
    // MARK: - State Management
    func updateState(currentSurface: SurfaceType) {
        guard self.currentState != .landing else {return}
        let previousState = self.currentState
        let previousSurface = self.currentSurface
        
        let particlePosition = CGPoint(x: self.position.x, y: self.position.y - self.size.height / 2)
        
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
                EffectsFactory.shared.createParticleEffect(at: particlePosition, amount: 4, surfaceType: currentSurface)
            } else {
                softLanding()
                EffectsFactory.shared.createParticleEffect(at: particlePosition, amount: 2, surfaceType: currentSurface)
            }
            canJump = true
            
        } else if !currentSurface.isGrounded && previousSurface.isGrounded {
            handleGoingAirborne()
            EffectsFactory.shared.createParticleEffect(at: particlePosition, amount: 2, surfaceType: currentSurface)
        }
        
        self.currentSurface = currentSurface
        updateColor()
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
        EffectsFactory.shared.screenShake(strength: 0.3)
        
        let wait = SKAction.wait(forDuration: landingDuration)
        let transitionToRunning = SKAction.run {
            if self.currentState == .landing {
                self.currentState = .running
            }
        }
        
        EffectsFactory.shared.playSound(soundKey: "landing.mp3", volumeKey: 1.0)
        EffectsFactory.shared.playHaptic(intensity: 1.0, sharpness: 0.1, type: .hapticTransient)
        
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
    
    // MARK: - Helpers
    private func handleGoingAirborne() {
        // Falling or jumping
        self.currentState = .airborne
        self.canDive = true
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
        let diagonalRayEnd = CGPoint(x: self.position.x + 100, y: self.position.y + platformHeight)
        
        self.scene?.physicsWorld.enumerateBodies(alongRayStart: diagonalRayStart, end: diagonalRayEnd) { (body, point, normal, stop) in
            if body.node?.name == "SolidPlatform" {
                isBlocked = true
                stop.pointee = true
            }
        }
        
        return isBlocked
    }
    
    private func isCloseToGround() -> Bool {
        let playerFeetY = self.position.y - (self.size.height / 2)
        let distanceToGround = playerFeetY - groundHeight
        
        return distanceToGround <= (defaultJumpHeight / 2)
    }
    
    func applyHorizontalMovementTransformation(withYAdjustment adjustY: CGFloat = 0) {
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

    func applyVerticalMovementTransformation(withYAdjustment adjustY: CGFloat = 0) {
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

    func restoreOriginalShape(withYAdjustment adjustY: CGFloat = 0) {
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
}
