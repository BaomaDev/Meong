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

    init(player: PlayerEntity) {
        let texture = SKTexture(imageNamed: "emak")

        // Target width (for example)
        let targetWidth: CGFloat = 80
        let aspectRatio = texture.size().height / texture.size().width
        let targetHeight = targetWidth * aspectRatio

        super.init(texture: texture, color: .clear, size: CGSize(width: targetWidth, height: targetHeight))  // ✅ calculated size

        self.name = "Chaser"
        self.zPosition = 1
        self.player = player

        let initialDistance = max(CGFloat(player.distance) * 80.0, 1200)
        self.anchorPoint = CGPoint(x: 0.7, y: 0.2)
        self.position = CGPoint(x: player.position.x - initialDistance, y: player.position.y)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
}

