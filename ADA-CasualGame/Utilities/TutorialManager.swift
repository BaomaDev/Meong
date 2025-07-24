import SpriteKit

// 1. Define all the steps of the tutorial in an enum
enum TutorialStep: CaseIterable {
    case welcome
    case teachJump
    case teachDuck
    case teachParry
    case teachObstacles
    case teachHighJump
    case teachPlatforms
    case finished

    func next() -> TutorialStep? {
        guard let currentIndex = Self.allCases.firstIndex(of: self) else { return nil }
        let nextIndex = Self.allCases.index(after: currentIndex)
        guard nextIndex < Self.allCases.endIndex else { return nil }
        return Self.allCases[nextIndex]
    }
}

class TutorialManager {
    private weak var scene: GameScene?
    private var completionHandler: (() -> Void)?
    private var messageNode: SKLabelNode?
    
    private var currentStep: TutorialStep = .welcome
    private let advanceActionKey = "advanceTutorialAction"

    init(scene: GameScene) {
        self.scene = scene
    }
    
    func start(completion: @escaping () -> Void) {
        self.completionHandler = completion
        presentCurrentStep()
    }
    
    private func presentCurrentStep() {
        guard let scene = scene else { return }
        
        scene.removeAction(forKey: advanceActionKey)
        cleanupTutorialNodes()

        switch currentStep {
        case .welcome:
            showMessage("Welcome! Let's learn the moves.")
            let advance = SKAction.run { self.advance() }
            let wait = SKAction.wait(forDuration: 3.5)
            scene.run(SKAction.sequence([wait, advance]), withKey: advanceActionKey)

        case .teachJump:
            showMessage("Swipe UP to jump over obstacles.")
            spawnObstacle(for: .teachJump)
            waitForSuccess(duration: 4.0)

        case .teachDuck:
            showMessage("Swipe DOWN to duck under things.")
            spawnObstacle(for: .teachDuck)
            waitForSuccess(duration: 4.0)
            
        case .teachParry:
            showMessage("TAP to parry projectiles")
            spawnObstacle(for: .teachParry)
            // Add the follow-up message
            scene.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.7),
                SKAction.run { self.showMessage("Parry Now!") }
            ]))
            waitForSuccess(duration: 3.0)
            
        case .teachObstacles:
            showMessage("Some obstacles you must DODGE, others you can STEP on.")
            spawnObstacle(for: .teachObstacles)
            waitForSuccess(duration: 6.0)

        case .teachHighJump:
            showMessage("Swipe UP HIGHER to land on tall platforms.")
            spawnObstacle(for: .teachHighJump)
            waitForSuccess(duration: 5.0)

        case .teachPlatforms:
            showMessage("You can land on these platforms too.")
            spawnObstacle(for: .teachPlatforms)
            // Add the follow-up message
            scene.run(SKAction.sequence([
                SKAction.wait(forDuration: 2.5),
                SKAction.run { self.showMessage("Swipe DOWN on them to drop through.") }
            ]))
            waitForSuccess(duration: 5.5)

        case .finished:
            endTutorial()
        }
    }
    
    // This method is called from GameScene when the player hits an obstacle
    func playerDidFail() {
        print("Player failed step: \(currentStep). Retrying...")
        // Immediately re-run the same step
        presentCurrentStep()
    }
    
    // This method is called from GameScene on a successful parry during the tutorial
    func playerDidSucceed() {
        print("Player passed step: \(currentStep).")
        advance()
    }
    
    // Helper method to advance to the next state
    private func advance() {
        guard let nextStep = currentStep.next() else {
            endTutorial()
            return
        }
        currentStep = nextStep
        presentCurrentStep()
    }

    // Spawns the correct obstacle based on the current step
    private func spawnObstacle(for step: TutorialStep) {
        guard let scene = scene else { return }
        
        switch step {
        case .teachJump:
            let obstaclePosition = CGPoint(x: scene.size.width + 100, y: groundHeight + 15)
            let obstacle = SpawnFactory.createStepable(at: obstaclePosition)
            obstacle.name = "TutorialObstacle"
            scene.addChild(obstacle)
        case .teachDuck:
            let obstaclePosition = CGPoint(x: scene.size.width + 150, y: groundHeight + 30)
            let obstacle = SpawnFactory.createDuckable(at: obstaclePosition)
            obstacle.name = "TutorialObstacle"
            scene.addChild(obstacle)
            
        case .teachParry:
            let projectile = SpawnFactory.createTutorialProjectile(in: scene)
            projectile.name = "Projectile"
            scene.addChild(projectile)
            
        case .teachObstacles:
            let noTouchPosition = CGPoint(x: scene.size.width + 120, y: groundHeight + 15)
            let noTouchObstacle = SpawnFactory.createNoTouch(at: noTouchPosition)
            noTouchObstacle.name = "TutorialObstacle"
            scene.addChild(noTouchObstacle)
            
            let stepablePosition = CGPoint(x: scene.size.width + 400, y: groundHeight + 15)
            let stepableObstacle = SpawnFactory.createStepable(at: stepablePosition)
            stepableObstacle.name = "TutorialObstacle"
            scene.addChild(stepableObstacle)
            
        case .teachHighJump:
            let platformPosition = CGPoint(x: scene.size.width + 200, y: platformHeight)
            let platformSize = CGSize(width: 300, height: platformThickness)
            let tallPlatform = SpawnFactory.createSolidPlatform(at: platformPosition, size: platformSize)
            tallPlatform.name = "SolidPlatform"
            scene.addChild(tallPlatform)
            
        case .teachPlatforms:
            let platformPosition = CGPoint(x: scene.size.width + 250, y: platformHeight)
            let platformSize = CGSize(width: 400, height: platformThickness)
            let platform = SpawnFactory.createSemiSolidPlatform(at: platformPosition, size: platformSize)
            platform.name = "SemiSolidPlatform"
            scene.addChild(platform)
        default:
            break
        }
    }
    
    private func cleanupTutorialNodes() {
        guard let scene = scene else { return }

        let tutorialNodeNames: Set<String> = ["TutorialObstacle", "Projectile", "SolidPlatform", "SemiSolidPlatform"]
        
        scene.children.forEach { node in
            if let name = node.name, tutorialNodeNames.contains(name) {
                node.removeFromParent()
            }
        }
    }
    
    private func cleanupTutorialMessageNodes() {
        scene?.children.forEach { node in
            if node.name == "TutorialMessage" {
                node.removeFromParent()
            }
        }
    }
    
    private func waitForSuccess(duration: TimeInterval) {
        let wait = SKAction.wait(forDuration: duration)
        let advance = SKAction.run { self.advance() }
        scene?.run(SKAction.sequence([wait, advance]), withKey: advanceActionKey)
    }

    private func showMessage(_ text: String) {
        guard let scene = scene, let camera = scene.camera else { return }
        messageNode?.removeFromParent()
        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = text
        label.fontSize = 28
        label.fontColor = .white
        label.position = CGPoint(x: camera.position.x, y: camera.position.y + 75)
        label.zPosition = 100
        label.name = "TutorialMessage"
        messageNode = label
        scene.addChild(label)
    }

    private func endTutorial() {
        cleanupTutorialNodes()
        showMessage("Good luck!")
        // Use a slight delay before calling the completion handler to let the message show
        let wait = SKAction.wait(forDuration: 2.0)
        let complete = SKAction.run { self.completionHandler?() }
        let removeMessage = SKAction.run { self.cleanupTutorialNodes()}
        scene?.run(SKAction.sequence([wait, removeMessage, complete]))
    }
}
