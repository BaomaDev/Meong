//
//  BackgroundView.swift
//  ADA-CasualGame
//
//  Created by Jesse Robinson Junior Simanjuntak on 23/07/25.
//


import SpriteKit

class BackgroundView {
    private weak var scene: SKScene?
    private var backgrounds: [SKSpriteNode] = []
    private var cloudTextures: [SKTexture] = []

    init(scene: SKScene) {
        self.scene = scene
//        loadCloudTextures()
    }

    func setupScrollingBackground(imageNamed: String) {
        guard let scene = scene else { return }

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
            background.zPosition = -1
            background.name = "scrollingBackground"
            scene.addChild(background)
            backgrounds.append(background)
        }
    }

    func updateBackgroundPosition(gameSpeed: CGFloat) {
        for background in backgrounds {
            background.position.x -= gameSpeed * 0.016

            if background.position.x <= -background.size.width {
                background.position.x += background.size.width * 2
            }
        }
    }

//    private func loadCloudTextures() {
//        // Add as many cloud image names as you have
//        let cloudNames = ["cloud1", "cloud2", "cloud3"]
//        cloudTextures = cloudNames.map { SKTexture(imageNamed: $0) }
//    }
//
//    func spawnRandomClouds() {
//        guard let scene = scene else { return }
//
//        for _ in 0..<3 {
//            let cloudTexture = cloudTextures.randomElement()!
//            let cloud = SKSpriteNode(texture: cloudTexture)
//            cloud.zPosition = -0.5
//            cloud.alpha = 0.7
//            cloud.setScale(CGFloat.random(in: 0.4...0.8))
//            cloud.position = CGPoint(
//                x: scene.size.width + CGFloat.random(in: 0...200),
//                y: CGFloat.random(in: scene.size.height * 0.5...scene.size.height * 0.9)
//            )
//
//            cloud.name = "cloud"
//            scene.addChild(cloud)
//
//            let moveAction = SKAction.moveBy(x: -scene.size.width - 300, y: 0, duration: TimeInterval(CGFloat.random(in: 20...40)))
//            let removeAction = SKAction.removeFromParent()
//            cloud.run(SKAction.sequence([moveAction, removeAction]))
//        }
//    }
}
