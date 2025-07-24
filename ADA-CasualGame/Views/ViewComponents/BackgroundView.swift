//
//  BackgroundView.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 23/07/25.
//

import SpriteKit

class BackgroundView {
    private weak var scene: SKScene?
    private var backgrounds: [SKSpriteNode] = []
    private var cloudTextures: [SKTexture] = []
    
    init(scene: SKScene) {
        self.scene = scene
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
}
