import SpriteKit

class BackgroundView {
    private weak var scene: SKScene?
    private var backgrounds: [SKSpriteNode] = []
    private var isPaused: Bool = false
    private var rereAppear: Int = 0

    init(scene: SKScene) {
        self.scene = scene
    }

    func setupScrollingBackground(imageNamed: String) {
        guard let scene = scene else { return }

        // Remove existing backgrounds to prevent duplicates on restart
        for bg in backgrounds {
            bg.removeFromParent()
        }
        backgrounds.removeAll() // Clear the array

        let texture = SKTexture(imageNamed: imageNamed)
        let scale = scene.size.height / texture.size().height

        for i in 0..<2 {
            let background = SKSpriteNode(texture: texture)
            background.anchorPoint = .zero
            background.size = CGSize(
                width: texture.size().width * scale,
                height: scene.size.height
            )
            background.position = CGPoint(x: CGFloat(i) * background.size.width, y: 0)
            background.zPosition = -9
            background.name = "scrollingBackground"
            scene.addChild(background)
            backgrounds.append(background)
        }
        
        // Give the second background an initial chance to spawn the easter egg
        if let secondBackground = backgrounds.last {
            trySpawningEasterEgg(on: secondBackground)
        }
    }

    func pauseScrolling() {
        isPaused = true
    }
    
    func updateBackgroundPosition(gameSpeed: CGFloat) {
        guard !isPaused else { return }
        guard gameSpeed > 0 else { return }

        for background in backgrounds {
            background.position.x -= gameSpeed * 0.016

            // When a background moves off-screen...
            if background.position.x <= -background.size.width {
                // 1. Remove all children (the old easter egg) before repositioning. ✅
                background.removeAllChildren()
                
                // 2. Reposition the background segment.
                background.position.x += background.size.width * 2
                
                // 3. Give it a new chance to spawn an easter egg. ✅
                trySpawningEasterEgg(on: background)
            }
        }
    }
    
    private func trySpawningEasterEgg(on background: SKSpriteNode) {
        // Use a constant for the spawn chance for clarity
        let spawnChance = 0.01 // 1% chance * 2 rolls for increased rarity
        
        if Double.random(in: 0...1) <= spawnChance {
            if Double.random(in: 0...1) <= spawnChance {
                var easterEggFrames: [SKTexture] = []
                for i in 0...68 {
                    let textureName = String(format: "easter-egg-%d", i)
                    easterEggFrames.append(SKTexture(imageNamed: textureName))
                }

                let animationAction = SKAction.animate(with: easterEggFrames, timePerFrame: 0.05)
                
                let easterEgg = SKSpriteNode(texture: easterEggFrames[0])
                easterEgg.setScale(0.25)
                easterEgg.position = CGPoint(x: background.size.width * 0.5,
                                              y: groundHeight + 55) // Assuming groundHeight is accessible
                easterEgg.zPosition = 1
                easterEgg.run(SKAction.repeatForever(animationAction))
                
                // Add the new easter egg as a child
                background.addChild(easterEgg)
                
                // Update stats
                rereAppear += 1
                let stats = LiveStats(rereAppearances: rereAppear)
                AchievementManager.shared.updateProgress(stats)
            }
        }
    }
}
