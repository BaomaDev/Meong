//
//  BackgroundView.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 23/07/25.
//

import SpriteKit

class BackgroundView {
    private weak var scene: SKScene?
    private var backgrounds: [SKSpriteNode] = []
    private var isPaused: Bool = false

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
        
        if Double.random(in: 0...1) <= 0.005 { // 0.5% chance
            var easterEggFrames: [SKTexture] = []
            for i in 0...68 {
                // Use the correct filename format to load each frame.
                let textureName = String(format: "easter-egg-%d", i)
                easterEggFrames.append(SKTexture(imageNamed: textureName))
            }

            let animationAction = SKAction.animate(with: easterEggFrames, timePerFrame: 0.05)
            
            let easterEgg = SKSpriteNode(texture: easterEggFrames[0])
            easterEgg.setScale(0.25)
            
            if let secondBackground = backgrounds.last {
                easterEgg.position = CGPoint(x: secondBackground.size.width * 0.5,
                                             y: groundHeight + 55)
                easterEgg.zPosition = 1
                easterEgg.run(SKAction.repeatForever(animationAction))
                secondBackground.addChild(easterEgg)
            }
        }
    }
    
    func pauseScrolling() {
        isPaused = true
    }
    
    // --- MODIFY THIS EXISTING METHOD ---
    func updateBackgroundPosition(gameSpeed: CGFloat) {
        guard !isPaused else { return } // ← Only scroll if not paused
        guard gameSpeed > 0 else { return }

        for background in backgrounds {
            background.position.x -= gameSpeed * 0.016

            if background.position.x <= -background.size.width {
                background.position.x += background.size.width * 2
            }
        }
    }
}
