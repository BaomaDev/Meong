//
//  PlayerMovement.swift
//  ADA-CasualGame
//
//  Created by Savio Enoson on 23/07/25.
//

import Foundation
import SpriteKit

extension PlayerEntity {
    // MARK: - State Management
    func updateState(currentSurface: SurfaceType) {
        guard !isDropping else { return }
        
        // Ignore landing / jumping logic when flying
        if currentState == .flying {
            if let scene = self.scene as? GameScene {
                // Check if the interval has passed since the last star was released.
                if scene.lastUpdateTime - lastParticleTime > particleInterval {
                    // Update the timer to now.
                    lastParticleTime = scene.lastUpdateTime
                    
                    // Call the factory to create a single star particle at the player's center.
                    EffectsFactory.shared.createParticleEffect(at: self.position, key: "star", amount: 1)
                }
            }
            return
        }
        
        // If a duck command is queued, perform that first.
        if self.currentState != .ducking && self.queuedAction == .duck {
            if self.currentState == .airborne || self.currentState == .running { // Override checking
                self.performDuck()
            } else {
                self.duck()
            }
            self.queuedAction = nil
            return
        } else {
            let previousState = self.currentState
            let previousSurface = self.currentSurface
            
            if currentState == .airborne || currentState == .diving {
                let isLanding = currentSurface.isGrounded && !previousSurface.isGrounded && (self.physicsBody?.velocity.dy ?? 0) <= 0
                if isLanding && self.action(forKey: "jumpAction") == nil {    // Disable landing logic when going through semi solid platforms
                    // Handle landing
                    if previousState == .diving {
                        hardLanding(surfaceType: currentSurface)
                    } else {
                        softLanding(surfaceType: currentSurface)
                    }
                    return
                }
            } else if currentState == .running {
                let isGoingAirborne = currentSurface == .none && previousSurface.isPlatform
                if isGoingAirborne {
                    handleGoingAirborne()
                }
            }
        }
    }
    
    private func hardLanding(surfaceType: SurfaceType) {
        let particlePosition = CGPoint(x: self.position.x, y: self.position.y - self.size.height / 2)
        
        let amount: Int
        let surfaceKey: String
        if surfaceType == .ground {
            surfaceKey = "dirt"
            amount = 12
            EffectsFactory.shared.playSound(soundKey: "landing.mp3")
        } else if surfaceType == .semiSolidPlatform {
            surfaceKey = "spark"
            amount = 3
            EffectsFactory.shared.playSound(soundKey: "landing_wire.mp3")
        } else {
            surfaceKey = "smoke"
            amount = 4
            EffectsFactory.shared.playSound(soundKey: "landingConcrete.mp3")
        }
        
        EffectsFactory.shared.screenShake(strength: 0.3)
        EffectsFactory.shared.playHaptic(intensity: 1.0, sharpness: 0.1, type: .hapticTransient)
        EffectsFactory.shared.createParticleEffect(at: particlePosition, key: surfaceKey, amount: amount)
        
        if surfaceType == .semiSolidPlatform {
            self.startTiptoeAnimation()
        } else {
            self.startRunningAnimation()
        }
        
        self.currentSurface = surfaceType
        self.currentState = .running
        self.canJump = true
    }
    
    private func softLanding(surfaceType: SurfaceType) {
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
            let particlePosition = CGPoint(x: self.position.x, y: self.position.y - self.size.height / 2)
            let amount: Int
            let surfaceKey: String
            if surfaceType == .ground {
                surfaceKey = "dirt"
                amount = 6
                EffectsFactory.shared.playSound(soundKey: "softLanding.mp3")
            } else if surfaceType == .semiSolidPlatform {
                surfaceKey = "spark"
                amount = 1
                EffectsFactory.shared.playSound(soundKey: "landing_wire.mp3")
            } else {
                surfaceKey = "smoke"
                amount = 2
                EffectsFactory.shared.playSound(soundKey: "landingConcrete.mp3")
            }

            EffectsFactory.shared.createParticleEffect(at: particlePosition, key: surfaceKey, amount: amount)
            
            if surfaceType == .semiSolidPlatform {
                self.startTiptoeAnimation()
            } else {
                self.startRunningAnimation()
            }
            
            self.currentSurface = surfaceType
            self.currentState = .running
            self.canJump = true
        }
    }
    
    // MARK: - Jump
    func jump(swipeDistance: Double) {
        if currentState == .airborne && !canJump {
            if isCloseToGround() {
                if swipeDistance < longSwipeTreshold {
                    queuedAction = .normalJump
                } else {
                    queuedAction = .highJump
                }
            }
            return
        } else {
            // --- Call the appropriate jump based on the swipe distance ---
            if swipeDistance < longSwipeTreshold {
                normalJump()
            } else {
                if checkForSolidPlatform() {
                    normalJump()
                } else {
                    highJump()

                }
            }
        }
    }

    private func normalJump() {
        self.canJump = false
        self.currentSurface = .none
        self.currentState = .airborne
        
        // Start jump animation
        startJumpingAnimation()
        
        // --- Define Jump Parameters ---
        let jumpHeight = (self.position.y <= platformHeight) ? defaultJumpHeight : defaultJumpHeight*0.75
        let horizontalDistance = defaultJumpDistance
        
        // --- Create and Run the Scripted Jump Action ---
        let startY = self.position.y
        let duration = horizontalDistance / 4 / gameSpeed
        
        self.physicsBody?.affectedByGravity = false
        
        EffectsFactory.shared.playSound(soundKey: "jump.mp3")
        
        let jumpAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
            let t = elapsedTime / duration
            let easingT = 1 - pow(1 - t, 3) // Cubic ease-out
            node.position.y = startY + (jumpHeight * easingT)
        }
        
        let completion = SKAction.run {
            self.physicsBody?.affectedByGravity = true
        }
        
        self.run(SKAction.sequence([jumpAction, completion]), withKey: "jumpAction")
    }
    
    private func highJump() {
        guard self.position.y <= platformHeight else {
            normalJump()
            return
        }

        canJump = false
        self.currentSurface = .none
        self.currentState = .airborne

        // Start jump animation
        startHighJumpingAnimation()

        let jumpHeight = defaultJumpHeight * 1.75
        let horizontalDistance = defaultJumpDistance + gameSpeed/2
        
        let startY = self.position.y
        let duration = horizontalDistance / 3.5 / gameSpeed
        
        EffectsFactory.shared.playSound(soundKey: "highJump.mp3")
        let jumpAction = SKAction.customAction(withDuration: duration) { (node, elapsedTime) in
            let t = elapsedTime / duration
            let easingT = 1 - pow(1 - t, 3) // Cubic ease-out
            node.position.y = startY + (jumpHeight * easingT)
        }
        
        let completion = SKAction.run {
            self.physicsBody?.affectedByGravity = true
        }
        
        self.run(SKAction.sequence([jumpAction, completion]), withKey: "jumpAction")
    }
    
    // MARK: - Duck / Dive
    func duck() {
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
        if isCloseToGround() {
            self.queuedAction = .duck
            return
        }
        
        var shortDive = false   // if the dive is short, no need to transform
        if let gameScene = self.scene as? GameScene {
            let surfaceBelow = gameScene.getSurfaceType(rayLength: 80.0)
            if surfaceBelow == .semiSolidPlatform || surfaceBelow == .solidPlatform {
                shortDive = true
            }
        }
        
        // Remove any ongoing scripted jump action. This is the core of the fix.
        self.removeAction(forKey: "jumpAction")
        
        // A jump action disables gravity and changes the player's shape.
        // We must manually restore these states before we can dive.
        self.physicsBody?.affectedByGravity = true
        self.canDive = false
        
        if !shortDive {
            self.currentState = .diving
            self.startDivingAnimation()
        }
        
        // Apply a sharp downward impulse.
        // Resetting vertical velocity first makes the dive feel consistent.
        self.physicsBody?.velocity.dy = 0
        self.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -diveForce))
    }
    
    private func performDuck() {
        self.currentState = .ducking
        self.canDuck = false

        startDuckingAnimation()
        EffectsFactory.shared.playSound(soundKey: "duck.wav")

        // Restore after duration
        let wait = SKAction.wait(forDuration: 0.75)
        let restore = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.currentState = .running
            self.canDuck = true

            // ✅ Resume running animation
            self.startRunningAnimation()
        }

        run(SKAction.sequence([wait, restore]))
    }
    
    private func dropThroughPlatform() {
        // This line makes the player ignore semi-solid platforms.
        handleGoingAirborne()
        physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
        
        // **NEW**: Create an action to move the player down quickly.
        let moveAction = SKAction.moveBy(x: 0, y: -platformThickness*4, duration: 0.05)
        
        // This is the existing action that restores the collision rules after a delay.
        let wait = SKAction.wait(forDuration: 0.33)
        let restoreCollision = SKAction.run {
            EffectsFactory.shared.playSound(soundKey: "landing_wire.mp3")
            self.setupPhysics()
            self.currentState = .airborne
            self.physicsBody?.velocity.dy = 0
            self.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -diveForce/2))
            self.isDropping = false
        }
        let restoreSequence = SKAction.sequence([wait, restoreCollision])
        
        // Use a group to run both the downward movement and the restoration timer simultaneously.
        let groupAction = SKAction.group([moveAction, restoreSequence])
        
        run(groupAction)
    }
    
    // MARK: - Parry
    func parry(currentTime: TimeInterval) -> Bool {
        guard self.currentState != .flying else { return false }
        
        let timeSinceLastParry = currentTime - lastParryTime
        guard timeSinceLastParry > parryCooldown else {
            return false
        }
        
        lastParryTime = currentTime
        isParrying = true
        parryStartTime = currentTime

        // Start parry animation
        startParryAnimation()
        
        // Visual feedback with SKAction
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        
        let endParry = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isParrying = false
            
            // ✅ Resume running animation only if player is still in running state
            if self.currentState == .running {
                self.startRunningAnimation()
            }
        }
        
        self.run(SKAction.sequence([scaleUp, scaleDown, endParry]))
        
        return true
    }
    
    // MARK: - Helpers
    private func handleGoingAirborne() {
        // Falling or jumping
        self.startJumpingAnimation()
        self.currentSurface = .none
        self.currentState = .airborne
        self.canDive = true
        self.canJump = false
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
        
        return distanceToGround <= (defaultJumpHeight / 3)
    }
}
