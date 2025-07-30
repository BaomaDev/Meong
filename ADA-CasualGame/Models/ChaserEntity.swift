//
//  ChaserEntity.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 16/07/25.
//

import Foundation
import SpriteKit

class ChaserEntity: SKSpriteNode {
    // Reference to the player
    weak var player: PlayerEntity?
    private static var animationTextures: [String: [SKTexture]] = [:]

    init(player: PlayerEntity) {
        let texture = SKTexture(imageNamed: "Mak_Intro_00000")

        // Target width (for example)
        let targetWidth: CGFloat = 110
        let targetHeight : CGFloat = 110

        super.init(texture: texture, color: .clear, size: CGSize(width: targetWidth, height: targetHeight))  // ✅ calculated size

        self.name = "Chaser"
        self.zPosition = 1
        self.player = player

        let initialDistance = max(CGFloat(player.distance) * 80.0, 1200)
        self.anchorPoint = CGPoint(x: 0.7, y: 0.2)
        self.position = CGPoint(x: player.position.x - initialDistance, y: player.position.y - 10)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func preloadAnimationTextures() {
        guard animationTextures.isEmpty else { return }
        
        let animations: [String: ClosedRange<Int>] = [
            "Mak_Run": 0...5, "Mak_Intro": 0...23, "Mak_Idle": 0...11,
            "Mak_Terbang": 0...59, "Mak_Nangkep": 0...30
        ]
        
        for (name, range) in animations {
            let textures = range.map { SKTexture(imageNamed: String(format: "\(name)_%05d", $0)) }
            animationTextures[name] = textures
        }
    }

    func updateFollowPosition() {
        guard let player = player else { return }

        let followDistance = CGFloat(player.distance) * 40.0
        let targetX = player.position.x - followDistance
        let targetY = player.position.y

        let currentPosition = self.position
        let lerpFactor: CGFloat = 0.05

        let newX = currentPosition.x + (targetX - currentPosition.x) * lerpFactor
        let newY = currentPosition.y + (targetY - currentPosition.y) * lerpFactor

        self.position = CGPoint(x: newX, y: newY)
    }
    
    func startRunningAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimation()
        
        guard let textures = ChaserEntity.animationTextures["Mak_Run"] else { return }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "emakRunAnimation")
    }
    
    func startIntroAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimation()
        
        guard let textures = ChaserEntity.animationTextures["Mak_Intro"] else { return }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "emakIntroAnimation")
    }
    
    func startIdleAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimation()
        
        guard let textures = ChaserEntity.animationTextures["Mak_Idle"] else { return }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "emakIdleAnimation")
    }
    
    func startFlyingAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimation()
        
        guard let textures = ChaserEntity.animationTextures["Mak_Terbang"] else { return }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.08, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        self.run(repeatAnimation, withKey: "emakFlyingAnimation")
    }
    
    func startCatchAnimation() {
        // Generate texture names based on your file naming
        stopAllAnimation()
        
        guard let textures = ChaserEntity.animationTextures["Mak_Nangkep"] else { return }

         // Create animation
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1, resize: false, restore: false)

        self.run(animation, withKey: "emakCatchAnimation")
    }
    
    func stopAllAnimation() {
        self.removeAction(forKey: "emakIdleAnimation")
        self.removeAction(forKey: "emakFlyingAnimation")
        self.removeAction(forKey: "emakIntroAnimation")
        self.removeAction(forKey: "emakRunAnimation")
        self.removeAction(forKey: "emakCatchAnimation")
    }
}

