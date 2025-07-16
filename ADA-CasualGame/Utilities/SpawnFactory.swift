//
//  SpawnFactory.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 16/07/25.
//

import Foundation
import SpriteKit

class SpawnFactory {
    static func createCoin(at position: CGPoint, characterCategory: UInt32, coinCategory: UInt32) -> SKSpriteNode {
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.setScale(0.07)
        coin.position = position
        coin.zPosition = 1

        coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width / 2)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = characterCategory
        coin.physicsBody?.collisionBitMask = 0
        
        let moveDistance = UIScreen.main.bounds.width + 100
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDistance / gameSpeed))
        let remove = SKAction.removeFromParent()
        coin.run(SKAction.sequence([move, remove]))

        return coin
    }

    static func createPowerUp(at position: CGPoint, characterCategory: UInt32, powerUpCategory: UInt32) -> SKSpriteNode {
        let powerUp = SKSpriteNode(imageNamed: "cat food")
        powerUp.setScale(0.015)
        powerUp.position = position
        powerUp.zPosition = 1

        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: powerUp.size.width / 2)
        powerUp.physicsBody?.isDynamic = false
        powerUp.physicsBody?.categoryBitMask = powerUpCategory
        powerUp.physicsBody?.contactTestBitMask = characterCategory
        powerUp.physicsBody?.collisionBitMask = 0
        
        let moveDistance = UIScreen.main.bounds.width + 100
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDistance / gameSpeed))
        let remove = SKAction.removeFromParent()
        powerUp.run(SKAction.sequence([move, remove]))

        return powerUp
    }
}

