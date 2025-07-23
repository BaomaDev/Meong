import SpriteKit

class TutorialManager {
    private weak var scene: GameScene?
    private var completionHandler: (() -> Void)?
    private var messageNode: SKLabelNode?

    init(scene: GameScene) {
        self.scene = scene
    }

    /// Starts the tutorial sequence.
    /// - Parameter completion: A closure that will be called when the tutorial is finished.
    func start(completion: @escaping () -> Void) {
        self.completionHandler = completion
        runTutorialSequence()
    }

    private func runTutorialSequence() {
        guard let scene = scene else { return }

        // Define the new sequence of tutorial steps
        let sequence = SKAction.sequence([
            // Welcome Message
            SKAction.run { self.showMessage("Welcome! Let's learn the moves.") },
            SKAction.wait(forDuration: 3.5),

            // 1. Teach Normal Jump (over a low obstacle)
            SKAction.run { self.teachJump() },
            SKAction.wait(forDuration: 4.0),

            // 2. Teach Ducking
            SKAction.run { self.teachDuck() },
            SKAction.wait(forDuration: 4.0),
            
            // 3. Teach different obstacle interactions
            SKAction.run { self.teachObstacles() },
            SKAction.wait(forDuration: 6.0),

            // 4. Teach High Jump (to land on a high platform)
            SKAction.run { self.teachHighJump() },
            SKAction.wait(forDuration: 5.0),

            // 5. Teach Semi-Solid Platforms & Dropping
            SKAction.run { self.teachPlatforms() },
            SKAction.wait(forDuration: 5.0),

            // End of Tutorial
            SKAction.run { self.endTutorial() }
        ])
        scene.run(sequence)
    }

    /// Displays a message on the screen.
    private func showMessage(_ text: String, duration: TimeInterval = 3.0) {
        guard let scene = scene, let camera = scene.camera else { return }
        
        messageNode?.removeFromParent()

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = 28
        label.fontColor = .white
        label.position = CGPoint(x: camera.position.x, y: camera.position.y + 100)
        label.zPosition = 100
        label.alpha = 0

        self.messageNode = label
        scene.addChild(label)

        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let wait = SKAction.wait(forDuration: duration - 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        
        label.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }

    private func teachJump() {
        guard let scene = scene else { return }
        showMessage("Swipe UP to jump over obstacles.")
        
        // Spawn a low obstacle that requires a simple jump
        let obstaclePosition = CGPoint(x: scene.size.width + 100, y: groundHeight + 15)
        let obstacle = SpawnFactory.createStepable(at: obstaclePosition)
        scene.addChild(obstacle)
    }
    
    private func teachDuck() {
        guard let scene = scene else { return }
        showMessage("Swipe DOWN to duck under things.")
        
        // Spawn an obstacle that must be ducked under
        let obstaclePosition = CGPoint(x: scene.size.width + 150, y: groundHeight + 30)
        let obstacle = SpawnFactory.createDuckable(at: obstaclePosition)
        scene.addChild(obstacle)
    }
    
    private func teachObstacles() {
        guard let scene = scene else { return }
        showMessage("Some obstacles you must DODGE, others you can STEP on.")

        // Spawn a "NoTouch" obstacle that must be avoided entirely
        let noTouchPosition = CGPoint(x: scene.size.width + 120, y: groundHeight + 15)
        let noTouchObstacle = SpawnFactory.createNoTouch(at: noTouchPosition)
        scene.addChild(noTouchObstacle)
        
        // Spawn a "Stepable" obstacle shortly after
        let stepablePosition = CGPoint(x: scene.size.width + 400, y: groundHeight + 15)
        let stepableObstacle = SpawnFactory.createStepable(at: stepablePosition)
        scene.addChild(stepableObstacle)
    }

    private func teachHighJump() {
        guard let scene = scene else { return }
        showMessage("Swipe UP HIGHER to land on tall platforms.")
        
        // Spawn a tall, solid platform that requires a high jump to reach
        let platformPosition = CGPoint(x: scene.size.width + 200, y: platformHeight)
        let platformSize = CGSize(width: 300, height: platformThickness)
        let tallPlatform = SpawnFactory.createSolidPlatform(at: platformPosition, size: platformSize)
        scene.addChild(tallPlatform)
    }
    
    private func teachPlatforms() {
        guard let scene = scene else { return }
        showMessage("You can land on these platforms too.")
        
        // Spawn a semi-solid platform for the player to land on
        let platformPosition = CGPoint(x: scene.size.width + 250, y: platformHeight)
        let platformSize = CGSize(width: 400, height: platformThickness)
        let platform = SpawnFactory.createSemiSolidPlatform(at: platformPosition, size: platformSize)
        scene.addChild(platform)

        // Show a follow-up message about dropping down
        let dropMessageAction = SKAction.sequence([
            SKAction.wait(forDuration: 2),
            SKAction.run {
                self.showMessage("Swipe DOWN on them to drop through.")
            }
        ])
        scene.run(dropMessageAction)
    }

    private func endTutorial() {
        showMessage("Good luck!", duration: 2.0)
        completionHandler?()
    }
}
