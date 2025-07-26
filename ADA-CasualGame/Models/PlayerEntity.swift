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
    var isDropping = false
    
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
        let texture = SKTexture(imageNamed: "CatWithoutFish_00000")
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
        guard !isInvincible else {
            if currentState == .flying {
                knockAway(node: projectileNode)
            }
            return
        }
        
        hearts -= 1
        distance -= 1
        updateDistance(distance)
        isInvincible = true
        
        // Nonaktifkan kontak sementara dengan projectile
        physicsBody?.contactTestBitMask &= ~PhysicsCategory.projectile
        physicsBody?.collisionBitMask &= ~PhysicsCategory.projectile
        
        EffectsFactory.shared.playSound(soundKey: "parry2.mp3", volumeKey: 1.0)     // Smack sound
        EffectsFactory.shared.playSound(soundKey: "hurt.mp3", volumeKey: 5.0)
        EffectsFactory.shared.playHaptic(intensity: 1.0, sharpness: 0.1, type: .hapticContinuous, duration: 0.3)
        
        applyHitInvincibility()
    }
    
    func handleObstacleHit(obstacleNode: SKNode) {
        guard !isInvincible else {
            if currentState == .flying {
                knockAway(node: obstacleNode)
            }
            return
        }

        knockAway(node: obstacleNode)
        
        hearts -= 1
        distance -= 1
        updateDistance(distance)
        isInvincible = true

        if let body = self.physicsBody {
            body.contactTestBitMask &= ~PhysicsCategory.obstacle
            body.collisionBitMask &= ~PhysicsCategory.obstacle
        }
        
        EffectsFactory.shared.playSound(soundKey: "hurt.mp3", volumeKey: 5.0)
        EffectsFactory.shared.playHaptic(intensity: 2.0, sharpness: 0.1, type: .hapticContinuous, duration: 0.3)

        applyHitInvincibility()
    }
    
    private func applyHitInvincibility() {
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
    
    func applyPowerUp() {   // Whiskas
        distance += 1
        updateDistance(distance)
        
        EffectsFactory.shared.playSound(soundKey: "munch.mp3", volumeKey: 1.0)
        EffectsFactory.shared.playSound(soundKey: "speedBoost.mp3", volumeKey: 1.0)
    }
    
    func applyCatnip() {
        let isInCatnipMode = currentState == .flying
        guard !isInCatnipMode else { return }
        currentState = .flying
        isInvincible = true
        
        EffectsFactory.shared.playSound(soundKey: "powerUp.mp3", volumeKey: 1.0)

        // This ensures the player is not stuck in a blinking, stretched, or ducked state.
        self.removeAllActions() // Stop any ongoing visual animations (like blinking or stretching)
        self.alpha = 1.0        // Ensure player is fully visible
        self.restoreOriginalShape2()  // Reset size and physics body to default
        self.setScale(1.0)

        startFlyingAnimation()
        
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
                self.removeAction(forKey: "catnipModeSequence")
                self.isInvincible = false
                self.currentState = .airborne
                gameSpeed /= 2.0
                
                // Restore original physics and visual state
                self.setupPhysics()
                self.physicsBody?.affectedByGravity = true
                self.alpha = 1.0
                self.restoreOriginalShape()
                
                // 🔁 Resume running animation
                self.startRunningAnimation()
                applyHitInvincibility()
            }
        ])

        self.run(catnipTimer, withKey: "catnipModeSequence")
    }
    
    func takeCoin() {
        EffectsFactory.shared.playSound(soundKey: "coin.mp3", volumeKey: 1.0)
        EffectsFactory.shared.createParticleEffect(at: self.position, key: "bling", amount: 3)
    }
    
    private func knockAway(node: SKNode) {
        node.physicsBody?.collisionBitMask = PhysicsCategory.none
        node.physicsBody?.contactTestBitMask = PhysicsCategory.none
        node.physicsBody?.affectedByGravity = false
        
        // 2 variables to adjust knock speed and direction
        let moveDistance: CGVector
        let moveDuration: TimeInterval
        let spin: SKAction
        let knockType: String
        
        let objectName = node.name
        
        // Shared Sounds
        let surprisedSoundKeys = ["surprised1.mp3", "surprised2.mp3", "surprised3.mp3"]
        let crashSoundKeys = ["crash1.mp3", "crash2.mp3", "crash3.mp3"]
        switch objectName {
        case "Projectile":
            EffectsFactory.shared.playSound(soundKey: "parry2.mp3", volumeKey: 1.0)
            knockType = "expel"
            
        case "BapakMainCatur":
            EffectsFactory.shared.playSound(soundKey: surprisedSoundKeys.randomElement()!, volumeKey: 1.0)
            EffectsFactory.shared.playSound(soundKey: crashSoundKeys.randomElement()!, volumeKey: 0.6)
            knockType = "inplace"
            
        case "Ayam":
            EffectsFactory.shared.playSound(soundKey: "chickenHit.mp3", volumeKey: 1.0)
            EffectsFactory.shared.createParticleEffect(at: self.position, key: "feather", amount: 8)
            EffectsFactory.shared.createParticleEffect(at: self.position, key: "smoke", amount: 2)
            knockType = "expel"
            
        case "Sepeda 2":
            EffectsFactory.shared.playSound(soundKey: "surprised2.mp3", volumeKey: 1.0)
            EffectsFactory.shared.playSound(soundKey: "bikeCrash.mp3", volumeKey: 1.0)
            knockType = "flip"
            
        case "BoxPisang":
            EffectsFactory.shared.createParticleEffect(at: self.position, key: "banana", amount: 3)
            EffectsFactory.shared.playSound(soundKey: "cardboard.mp3", volumeKey: 1.0)
            knockType = "flip"

//        case "BoxBuah":
//            EffectsFactory.shared.playSound(soundKey: crashSoundKeys.randomElement()!, volumeKey: 1.0)
//            spin = SKAction.rotate(byAngle: 90, duration: 0.5)
//
//        case "GerobakSayur":
//            EffectsFactory.shared.playSound(soundKey: crashSoundKeys.randomElement()!, volumeKey: 1.0)
//            spin = SKAction.rotate(byAngle: 90, duration: 0.5)
//
//        case "Tong":
//            EffectsFactory.shared.playSound(soundKey: crashSoundKeys.randomElement()!, volumeKey: 1.0)
//            spin = SKAction.rotate(byAngle: 90, duration: 0.5)

        case "Box":
            EffectsFactory.shared.playSound(soundKey: "cardboard.mp3", volumeKey: 1.0)
            knockType = "expel"

        case "BoxBerdiri":
            EffectsFactory.shared.playSound(soundKey: "cardboard.mp3", volumeKey: 1.0)
            knockType = "expel"
            
        default:
            EffectsFactory.shared.playSound(soundKey: crashSoundKeys.randomElement()!, volumeKey: 1.0)
            knockType = "fallOver"
        }
        
        switch knockType {
        case "flip":
            moveDistance = CGVector(dx: 100, dy: -40)
            moveDuration = 0.3
            spin = SKAction.rotate(byAngle: .pi, duration: 0.25)
        case "expel":
            moveDistance = CGVector(dx: 800, dy: 600)
            moveDuration = 1.0
            spin = SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 0.5))
        case "inplace":
            moveDistance = CGVector(dx: 0, dy: 0)
            moveDuration = 0.1
            spin = SKAction.rotate(byAngle: 0, duration: 0.1)
        case "fallOver":
            moveDistance = CGVector(dx: 100, dy: -60)
            moveDuration = 0.3
            spin = SKAction.rotate(byAngle: .pi/3, duration: 0.25)
        default:
            moveDistance = CGVector(dx: 100, dy: -20)
            moveDuration = 0.3
            spin = SKAction.rotate(byAngle: .pi, duration: 0.25)
        }
        
        let moveAction = SKAction.move(by: moveDistance, duration: moveDuration)
        moveAction.timingMode = .easeOut
        
//        let spinAction = SKAction.repeatForever(spin)
        let groupAction = SKAction.group([moveAction, spin])

        node.run(groupAction)
    }
    
    func startRunningAnimation() {
        print("starting run")
        
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (1...12).map { String(format: "CatRunning_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.05, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "runAnimation")
    }
    
    func startDuckingAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (0...14).map { String(format: "CatDucking_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.05, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "duckAnimation")
    }
    
    func startFlyingAnimation() {
        stopAllAnimations()
        
        let textureNames = (1...58).map { String(format: "CatFlying_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.05, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "flyingAnimation")
    }
    
    func startJumpingAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (0...22).map { String(format: "CatJumping_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.025, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "jumpAnimation")
    }
    
    func startHighJumpingAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (0...22).map { String(format: "CatJumping_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.065, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "jumpAnimation")
    }
    
    func startIntroAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (0...11).map { String(format: "CatWithoutFish_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.05, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "introAnimation")
    }
    
    func startStealingAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (0...11).map { String(format: "CatTakesFish_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.05, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "stealingAnimation")
    }
    
    func startIdleAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (0...26).map { String(format: "CatIdle_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.085, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "idleAnimation")
    }
    
    func startTiptoeAnimation() {
        print("starting tiptoe")
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (2...49).map { String(format: "CatWalk_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.035, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "tiptoeAnimation")
    }
    
    func startDivingAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (0...24).map { String(format: "CatDiving_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.01, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "divingAnimation")
    }
    
    func startParryAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimations()
        
        let textureNames = (1...12).map { String(format: "CatParry_%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.025, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "parryAnimation")
    }
    
    func stopAllAnimations() {
        self.removeAction(forKey: "parryAnimation")
        self.removeAction(forKey: "divingAnimation")
        self.removeAction(forKey: "tiptoeAnimation")
        self.removeAction(forKey: "idleAnimation")
        self.removeAction(forKey: "stealingAnimation")
        self.removeAction(forKey: "introAnimation")
        self.removeAction(forKey: "runAnimation")
        self.removeAction(forKey: "duckAnimation")
        self.removeAction(forKey: "flyingAnimation")
        self.removeAction(forKey: "jumpAnimation")
    }
}
