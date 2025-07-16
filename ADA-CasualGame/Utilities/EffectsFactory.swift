import SpriteKit
import CoreHaptics // For haptic feedback

/// A singleton class to manage all game-wide visual and audio effects.
class EffectsFactory {
    
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
    func playSound(soundKey: String) {
        guard let scene = scene else { return }
        // playSoundFileNamed is a simple way to play a short sound effect.
        // 'waitForCompletion: false' allows the game to continue without waiting for the sound to finish.
        let playAction = SKAction.playSoundFileNamed(soundKey, waitForCompletion: false)
        scene.run(playAction)
    }
    
    /// Triggers haptic feedback on the device.
    /// - Parameter strength: A value from 0.0 to 1.0 representing the intensity.
    func playHaptic(strength: Double) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        // Create a sharp, intense haptic event.
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(strength))
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(strength))
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
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
            
            // **THE FIX**: Set a handler to automatically restart the engine if it's stopped by the system.
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic engine stopped for reason: \(reason). Attempting to restart.")
                do {
                    // Try to restart the engine.
                    try self.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            
        } catch {
            print("There was an error creating the haptic engine: \(error.localizedDescription)")
        }
    }
}
