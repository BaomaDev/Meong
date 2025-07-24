import SpriteKit
import CoreHaptics // For haptic feedback

/// A singleton class to manage all game-wide visual and audio effects.
class EffectsFactory {
    // MARK: - Assets
    private let groundParticleTextures = ["dirt_01", "dirt_02", "dirt_03"]
    private let platformParticleTextures = ["smoke_01", "smoke_02", "smoke_03"]
    private let starParticleTextures = ["star_01", "star_02", "star_03"]
    private let sparkParticleTextures = ["spark_01", "spark_02", "spark_03"]
    
    // MARK: - Singleton Instance
    static let shared = EffectsFactory()
    
    // MARK: - Properties
    
    // A weak reference to the main game scene to run actions on.
    private weak var scene: SKScene?
    
    // A reference to the background music node to allow for control (start, stop, fade).
    private var bgmNode: SKAudioNode?
    
    // A haptic engine instance for generating feedback.
    private var hapticEngine: CHHapticEngine?
    
    // Private initializer to ensure it's a true singleton.
    private init() {
        prepareHaptics()
    }
    
    // MARK: - Setup
    
    /// Initializes the factory with a reference to the main game scene.
    /// This should be called once in the GameScene's `didMove(to:)` method.
    /// - Parameter scene: The main SKScene of the game.
    func initialize(with scene: SKScene) {
        self.scene = scene
    }
    
    // MARK: - Public Methods
    
    /// Plays a one-off sound effect.
    /// - Parameter soundKey: The filename of the sound to play (e.g., "jump.wav").
    func playSound(soundKey: String, volumeKey: Float) {
        guard let scene = scene else { return }
        
        // 1. Create an audio node
        let audioNode = SKAudioNode(fileNamed: soundKey)
        audioNode.autoplayLooped = false // Prevent looping
        
        // 2. Set volume (0.0 to 1.0)
        audioNode.run(SKAction.changeVolume(to: volumeKey, duration: 0))
        
        // 3. Add to the scene
        scene.addChild(audioNode)
        
        // 4. Play the sound once
        audioNode.run(SKAction.sequence([
            SKAction.play(),  // Explicitly play the sound
            SKAction.wait(forDuration: 0.5), // Brief delay to ensure playback
            SKAction.removeFromParent() // Remove after playing
        ]))
    }
    
    /// Triggers haptic feedback on the device.
    /// - Parameter strength: A value from 0.0 to 1.0 representing the intensity.
    func playHaptic(
        intensity: Float,
        sharpness: Float,
        type: CHHapticEvent.EventType = .hapticTransient,
        duration: TimeInterval? = nil
    ) {
        guard let hapticEngine = hapticEngine,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        // Start the haptic engine
        do {
            try hapticEngine.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
            return
        }

        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)

        let event: CHHapticEvent
        if let duration = duration, type == .hapticContinuous {
            // Continous
            event = CHHapticEvent(
                eventType: type,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: 0,
                duration: duration
            )
        } else {
            // Transient (tap or anything yang ga continous)
            event = CHHapticEvent(
                eventType: type,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: 0
            )
        }
        
        // Create a pattern and player, then play the haptic
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
        }
    }

    /// Shakes the screen to add impact.
    /// - Parameter strength: A value from 0.0 to 1.0 controlling the shake intensity.
    func screenShake(strength: Double) {
        guard let camera = scene?.camera else { return }
        
        let amplitudeX = Int(10 * strength) // Shake distance in points
        let amplitudeY = Int(6 * strength)
        let duration: TimeInterval = 0.3 * strength // Shake duration in seconds
        
        var actions: [SKAction] = []
        for _ in 0...Int(duration / 0.01) {
            let moveX = CGFloat(arc4random_uniform(UInt32(amplitudeX * 2))) - CGFloat(amplitudeX)
            let moveY = CGFloat(arc4random_uniform(UInt32(amplitudeY * 2))) - CGFloat(amplitudeY)
            let shakeAction = SKAction.moveBy(x: moveX, y: moveY, duration: 0.01)
            actions.append(shakeAction)
            actions.append(shakeAction.reversed())
        }
        
        camera.run(SKAction.sequence(actions))
    }
    
    /// Starts playing the background music with a slow fade-in.
    func playBgm() {
        guard let scene = scene, bgmNode == nil else { return }
        
        let node = SKAudioNode(fileNamed: "bgm.wav")
        node.autoplayLooped = true
        node.isPositional = false // Ensures sound is not affected by camera position
        node.run(SKAction.changeVolume(to: 0, duration: 0)) // Start silent
        
        scene.addChild(node)
        self.bgmNode = node
        
        // Fade in the volume over 3 seconds.
        node.run(SKAction.changeVolume(to: 0.7, duration: 3.0))
    }
    
    /// Stops the background music with a slow fade-out.
    func stopBgm() {
        guard let bgmNode = bgmNode else { return }
        
        // Fade out the volume, then remove the node from the scene.
        let fadeOut = SKAction.changeVolume(to: 0, duration: 2.0)
        let remove = SKAction.removeFromParent()
        
        bgmNode.run(SKAction.sequence([fadeOut, remove])) {
            self.bgmNode = nil // Clear the reference
        }
    }
    
    // MARK: - Private Helpers
    /// Prepares the haptic engine for use to reduce latency on the first tap.
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // This handler is called when the engine is stopped by the system (e.g., app suspended).
            // Its main purpose is for logging or cleaning up resources.
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped for reason: \(reason).")
            }
            
            // **MODIFIED**: The reset handler is the primary place to attempt a restart after a server failure.
            hapticEngine?.resetHandler = { [weak self] in
                print("Haptic engine reset. Attempting to restart.")
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine after reset: \(error)")
                }
            }
            
        } catch {
            print("There was an error creating the haptic engine: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Particle Handler
    func createParticleEffect(at position: CGPoint, key: String, amount: Int) {
            guard let scene = scene else { return }
            
            let emitter = SKEmitterNode()
            emitter.position = position
            emitter.numParticlesToEmit = amount
            emitter.zPosition = -1
            emitter.particlePositionRange = CGVector(dx: playerHitboxWidth, dy: 0)
            
            switch key {
            case "dirt":
                let initialSize: CGFloat = 0.05
                
                emitter.particleTexture = SKTexture(imageNamed: groundParticleTextures.randomElement() ?? "dirt_01")
                emitter.particleColor = .brown
                emitter.particleColorBlendFactor = 0.8
                emitter.particleLifetime = 0.6
                emitter.particleSpeed = 80
                emitter.emissionAngleRange = .pi / 8
                emitter.xAcceleration = -gameSpeed
                emitter.yAcceleration = -150

                emitter.particleScaleSequence = SKKeyframeSequence(keyframeValues: [initialSize, initialSize * 0.2], times: [0, 1])
                
            case "smoke":
                let initialSize: CGFloat = 0.1

                emitter.particleTexture = SKTexture(imageNamed: platformParticleTextures.randomElement() ?? "smoke_01")
                emitter.particleColor = SKColor(named: "DustColor") ?? .lightGray
                emitter.particleColorBlendFactor = 0.35
                emitter.particleLifetime = 0.5
                emitter.particleSpeed = 100
                emitter.emissionAngleRange = .pi / 8
                emitter.xAcceleration = -gameSpeed
                emitter.yAcceleration = -200
                
                emitter.particleScaleSequence = SKKeyframeSequence(keyframeValues: [initialSize, initialSize * 0.2], times: [0, 1])
                
            case "star":
                let initialSize: CGFloat = 0.075

                emitter.particleTexture = SKTexture(imageNamed: starParticleTextures.randomElement() ?? "star_01")
                emitter.particleLifetime = 1.0
                emitter.particleSpeed = 0
                emitter.xAcceleration = -gameSpeed*2
                emitter.yAcceleration = -50
                emitter.particleScaleSequence = SKKeyframeSequence(keyframeValues: [initialSize, initialSize * 0.7], times: [0, 1]) // Shrinks less
                
                let rainbowColors: [SKColor] = [.red, .orange, .yellow, .green, .blue, .purple]
                let keyframeTimes: [NSNumber] = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
                emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: rainbowColors, times: keyframeTimes)
                emitter.particleColorBlendFactor = 1.0
                
            case "spark":
                let initialSize: CGFloat = 0.1

                emitter.particleTexture = SKTexture(imageNamed: sparkParticleTextures.randomElement() ?? "spark_01")
                emitter.particleColor = .yellow
                emitter.particleColorBlendFactor = 0.8
                emitter.particleLifetime = 0.6
                emitter.particleSpeed = 80
                emitter.emissionAngleRange = .pi / 8
                emitter.xAcceleration = -gameSpeed
                emitter.yAcceleration = 0

                emitter.particleScaleSequence = SKKeyframeSequence(keyframeValues: [initialSize, initialSize * 0.2], times: [0, 1])
                
            default:
                print("Warning: Unknown particle key '\(key)'")
                return
            }
            
            // --- Common Properties ---
            emitter.particleBirthRate = 200
            emitter.particleAlphaSequence = SKKeyframeSequence(keyframeValues: [0.8, 0], times: [0, 1])
            
            // --- Cleanup ---
            let waitAction = SKAction.wait(forDuration: 1.5)
            let removeAction = SKAction.removeFromParent()
            
            scene.addChild(emitter)
            emitter.run(SKAction.sequence([waitAction, removeAction]))
        }
}
