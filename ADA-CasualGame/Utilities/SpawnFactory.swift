//
//  SpawnFactory.swift
//  ADA-CasualGame
//
//  Created by Derend Marvel Hanson Prionggo on 16/07/25.
//

import Foundation
import SpriteKit

// MARK: - Custom Obstacle Classes
class Duckable: SKSpriteNode {
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class Stepable: SKSpriteNode {
    override init(texture: SKTexture?, color: UIColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum MoveKey {
    static let platform = "movePlatform"
    static let obstacle = "moveObstacle"
    static let projectile = "moveProjectile"
    static let collectible = "moveCollectible"
}

class SpawnFactory {
    // MARK: - Reusable Movement Action
    
    static func createMovementAction(distance: CGFloat, speed: CGFloat) -> SKAction {
        let duration = TimeInterval(distance / speed)
        let moveAction = SKAction.moveBy(x: -distance, y: 0, duration: duration)
        let removeAction = SKAction.removeFromParent()
        return SKAction.sequence([moveAction, removeAction])
    }

    // MARK: - Collectibles
    
    static func createCoin(at position: CGPoint, characterCategory: UInt32, coinCategory: UInt32) -> SKSpriteNode {
        let coin = SKSpriteNode(imageNamed: "Coin")
        coin.setScale(0.07)
        coin.position = position
        coin.zPosition = 1

        coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width / 2)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = characterCategory
        coin.physicsBody?.collisionBitMask = 0
        
        coin.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.collectible)

        return coin
    }

    static func createPowerUp(at position: CGPoint, characterCategory: UInt32, powerUpCategory: UInt32) -> SKSpriteNode {
        let powerUp = SKSpriteNode(imageNamed: "Whiskas")
        powerUp.setScale(0.1)
        powerUp.position = position
        powerUp.zPosition = 1

        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: powerUp.size.width / 2)
        powerUp.physicsBody?.isDynamic = false
        powerUp.physicsBody?.categoryBitMask = powerUpCategory
        powerUp.physicsBody?.contactTestBitMask = characterCategory
        powerUp.physicsBody?.collisionBitMask = 0
        
        powerUp.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.collectible)

        return powerUp
    }
    
    static func createCatnip(at position: CGPoint, characterCategory: UInt32, catnipCategory: UInt32) -> SKSpriteNode {
        let catnip = SKSpriteNode(imageNamed: "catnip")
        catnip.setScale(0.07)
        catnip.position = position
        catnip.zPosition = 1

        catnip.physicsBody = SKPhysicsBody(circleOfRadius: catnip.size.width / 2)
        catnip.physicsBody?.isDynamic = false
        catnip.physicsBody?.categoryBitMask = catnipCategory
        catnip.physicsBody?.contactTestBitMask = characterCategory
        catnip.physicsBody?.collisionBitMask = 0
        
        catnip.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.collectible)

        return catnip
    }
    
    // MARK: - Obstacles

    static func createNoTouch(at position: CGPoint) -> SKSpriteNode {
        let textureNames = ["BapakMainCatur", "BoxPisang"]
        let textureName = textureNames.randomElement()!
        let texture = SKTexture(imageNamed: textureName)
        
        var targetWidth: CGFloat = 0
        var objectPosition = position
        
        switch textureName {
            case "BapakMainCatur":
                targetWidth = 115
                objectPosition = CGPoint(x: position.x, y: position.y + 10)
            case "BoxPisang":
                targetWidth = 70
                objectPosition = CGPoint(x: position.x, y: position.y - 15)
            default:
                targetWidth = 50
                objectPosition = CGPoint(x: position.x, y: position.y - 10)
        }
        
        let aspectRatio = texture.size().height / texture.size().width
        let targetHeight = targetWidth * aspectRatio
        let size = CGSize(width: targetWidth, height: targetHeight)
        
        let noTouch = SKSpriteNode(texture: texture, color: .clear, size: size)
        noTouch.name = textureName
        noTouch.position = objectPosition
        
        noTouch.physicsBody = SKPhysicsBody(rectangleOf: noTouch.size)
        noTouch.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        noTouch.physicsBody?.isDynamic = false
        noTouch.physicsBody?.affectedByGravity = false
        noTouch.physicsBody?.contactTestBitMask = PhysicsCategory.player
        noTouch.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        noTouch.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.obstacle)
        
        return noTouch
    }
    
    static func createMovingAlert(at position: CGPoint, in scene: SKScene) {
        print("test \(position)")
        
        let alertTexture = SKTexture(imageNamed: "alert")
        let alert = SKSpriteNode(texture: alertTexture, color: .yellow, size: CGSize(width: 40, height: 40))
        
        // Place it slightly to the left of where the moving object will appear
        alert.position = CGPoint(x: position.x - 100, y: position.y)
        alert.zPosition = 100
        alert.name = "Alert"

        let blink = SKAction.repeat(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.fadeIn(withDuration: 0.25)
        ]), count: 2)

        let remove = SKAction.removeFromParent()

        scene.addChild(alert)

        // Remove the alert after a short blink
        alert.run(SKAction.sequence([blink, SKAction.wait(forDuration: 0.2), remove]))
    }
    
    static func createMoving(at position: CGPoint) -> SKSpriteNode {
        let isChicken = Bool.random()
        let textureName = isChicken ? "Ayam" : "Sepeda 2"
        let initialTexture = SKTexture(imageNamed: "\(textureName)_00000") // use first frame of animation
        var desiredSize = CGSize(width: 50, height: 50)
        var desiredPosition = position
        
        switch textureName{
            case "Sepeda 2":
                desiredSize = CGSize(width: 100, height: 100)
                desiredPosition = CGPoint(x: position.x, y: position.y + 25)
            default:
                desiredSize = CGSize(width: 50, height: 50)
                desiredPosition = position
            break
        }
        let moving = SKSpriteNode(texture: initialTexture, color: .clear, size: desiredSize)
        
        moving.name = textureName
        moving.position = desiredPosition

        moving.physicsBody = SKPhysicsBody(rectangleOf: moving.size)
        moving.physicsBody?.isDynamic = false
        moving.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        moving.physicsBody?.contactTestBitMask = PhysicsCategory.player
        moving.physicsBody?.collisionBitMask = PhysicsCategory.none

        // Position & movement setup
        let startX = position.x + 100
        let endX: CGFloat = -100
        moving.position.x = startX
        
        let movementSpeed: CGFloat = 800
        let distance = abs(startX - endX)
        let duration = TimeInterval(distance / movementSpeed)
        
        let moveAction = SKAction.moveTo(x: endX, duration: duration)

        // Bobbing
        let bobUp = SKAction.moveBy(x: 0, y: 5, duration: 0.3)
        let bobDown = SKAction.moveBy(x: 0, y: -5, duration: 0.3)
        let bobSequence = SKAction.sequence([bobUp, bobDown])
        let bobRepeat = SKAction.repeatForever(bobSequence)

        // 🟨 Animation setup
        let frameCount = isChicken ? 6 : 8  // Adjust if Chicken/gojek have different frame counts
        let texturePrefix = "\(textureName)_"
        let textureNames = (0..<frameCount).map { String(format: "\(texturePrefix)%05d", $0) }
        let textures = textureNames.map { SKTexture(imageNamed: $0) }
        let animation = SKAction.animate(with: textures, timePerFrame: 0.05, resize: false, restore: false)
        let repeatAnimation = SKAction.repeatForever(animation)

        // 🟦 Combine all actions
        moving.run(repeatAnimation, withKey: "moveAnim")
        let group = SKAction.group([moveAction, bobRepeat])
        let removeAction = SKAction.removeFromParent()
        moving.run(SKAction.sequence([group, removeAction]), withKey: MoveKey.obstacle)

        return moving
    }
    
    static func createDuckable(at position: CGPoint) -> Duckable {
        let textureNames = ["BoxBuah", "GerobakSayur"]
        let textureName = textureNames.randomElement()!
        let texture = SKTexture(imageNamed: textureName)
        
        var targetWidth: CGFloat = 0
        var objectPosition = position
        
        switch textureName {
            case "BoxBuah":
                targetWidth = 65
            case "GerobakSayur":
                targetWidth = 160
                objectPosition = CGPoint(x: position.x, y: position.y + 30)
            default:
                targetWidth = 50
                objectPosition = CGPoint(x: position.x, y: position.y - 10)
        }
        
        let aspectRatio = texture.size().height / texture.size().width
        let targetHeight = targetWidth * aspectRatio
        let size = CGSize(width: targetWidth, height: targetHeight)
        
        let duckable = Duckable(texture: texture, color: .clear, size: size)
        duckable.name = textureName
        duckable.position = objectPosition
        duckable.userData = ["obstacleType": "duckable"]
        
        let collisionHeight = duckable.size.height * 0.4
        let collisionZone = SKSpriteNode(color: .clear, size: CGSize(width: duckable.size.width, height: collisionHeight))
        collisionZone.position = CGPoint(x: 0, y: duckable.size.height/2 - collisionHeight/2)
        collisionZone.physicsBody = SKPhysicsBody(rectangleOf: collisionZone.size)
        collisionZone.physicsBody?.isDynamic = false
        collisionZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        collisionZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        collisionZone.physicsBody?.collisionBitMask = PhysicsCategory.none
        collisionZone.name = "collisionZone"
        duckable.addChild(collisionZone)
        
        let duckZoneHeight = duckable.size.height * 0.6
        let duckZone = SKSpriteNode(color: .clear, size: CGSize(width: duckable.size.width, height: duckZoneHeight))
        duckZone.position = CGPoint(x: 0, y: -duckable.size.height/2 + duckZoneHeight/2)
        duckZone.alpha = 0.3
        duckZone.name = "duckZone"
        duckable.addChild(duckZone)
        
        duckable.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.obstacle)
        
        return duckable
    }
    
    static func createStepable(at position: CGPoint) -> Stepable {
        let textureNames = ["Tong", "Box", "BoxBerdiri"]
        let textureName = textureNames.randomElement()!
        let texture = SKTexture(imageNamed: textureName)
        
        var targetWidth: CGFloat = 0
        var objectPosition = position
        
        switch textureName {
            case "Tong":
                targetWidth = 50
                objectPosition = position
            case "Box":
                targetWidth = 50
                objectPosition = CGPoint(x: position.x, y: position.y - 10)
            case "BoxBerdiri":
                targetWidth = 40
                objectPosition = CGPoint(x: position.x, y: position.y - 10)
            default:
                targetWidth = 50
                objectPosition = CGPoint(x: position.x, y: position.y - 10)
        }
        
        let aspectRatio = texture.size().height / texture.size().width
        let targetHeight = targetWidth * aspectRatio
        let size = CGSize(width: targetWidth, height: targetHeight)
        let stepable = Stepable(texture: texture, color: .clear, size: size)
        
        stepable.name = textureName
        stepable.position = objectPosition
        stepable.userData = ["obstacleType": "stepable"]

        let safeZoneHeight: CGFloat = 15
        let safeZone = SKSpriteNode(color: .clear, size: CGSize(width: stepable.size.width, height: safeZoneHeight))
        safeZone.position = CGPoint(x: 0, y: stepable.size.height/2 - safeZoneHeight/2)
        safeZone.physicsBody = SKPhysicsBody(rectangleOf: safeZone.size)
        safeZone.physicsBody?.isDynamic = false
        safeZone.physicsBody?.categoryBitMask = PhysicsCategory.ground
        safeZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        safeZone.physicsBody?.collisionBitMask = PhysicsCategory.player
        safeZone.name = "safeZone"
        stepable.addChild(safeZone)

        let damageZoneWidth: CGFloat = 15
        let damageZoneHeight = stepable.size.height - safeZoneHeight
        
        let leftDamageZone = SKSpriteNode(color: .clear, size: CGSize(width: damageZoneWidth, height: damageZoneHeight))
        leftDamageZone.position = CGPoint(x: -stepable.size.width/2 + damageZoneWidth/2, y: -safeZoneHeight/2)
        leftDamageZone.physicsBody = SKPhysicsBody(rectangleOf: leftDamageZone.size)
        leftDamageZone.physicsBody?.isDynamic = false
        leftDamageZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        leftDamageZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        leftDamageZone.physicsBody?.collisionBitMask = PhysicsCategory.none
        leftDamageZone.name = "damageZone"
        stepable.addChild(leftDamageZone)
        
        let rightDamageZone = SKSpriteNode(color: .clear, size: CGSize(width: damageZoneWidth, height: damageZoneHeight))
        rightDamageZone.position = CGPoint(x: stepable.size.width/2 - damageZoneWidth/2, y: -safeZoneHeight/2)
        rightDamageZone.physicsBody = SKPhysicsBody(rectangleOf: rightDamageZone.size)
        rightDamageZone.physicsBody?.isDynamic = false
        rightDamageZone.physicsBody?.categoryBitMask = PhysicsCategory.obstacle
        rightDamageZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        rightDamageZone.physicsBody?.collisionBitMask = PhysicsCategory.none
        rightDamageZone.name = "damageZone"
        stepable.addChild(rightDamageZone)
        
        let bottomZoneHeight: CGFloat = 10
        let bottomZone = SKSpriteNode(color: .clear, size: CGSize(width: stepable.size.width - 30, height: bottomZoneHeight))
        bottomZone.position = CGPoint(x: 0, y: -stepable.size.height/2 + bottomZoneHeight/2)
        bottomZone.physicsBody = SKPhysicsBody(rectangleOf: bottomZone.size)
        bottomZone.physicsBody?.isDynamic = false
        bottomZone.physicsBody?.categoryBitMask = PhysicsCategory.ground
        bottomZone.physicsBody?.contactTestBitMask = PhysicsCategory.player
        bottomZone.physicsBody?.collisionBitMask = PhysicsCategory.player
        bottomZone.name = "bottomZone"
        stepable.addChild(bottomZone)
        
        stepable.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.obstacle)
        
        return stepable
    }
    
    // MARK: - Projectiles

    static func createProjectile(in scene: SKScene) -> (node: SKSpriteNode, startPoint: CGPoint) {
        let texture = SKTexture(imageNamed: "Sendal")
        
        let targetWidth: CGFloat = 30
        let aspectRatio = texture.size().height / texture.size().width
        let targetHeight = targetWidth * aspectRatio
        let size = CGSize(width: targetWidth, height: targetHeight)
        let projectile = SKSpriteNode(texture: texture, color: .clear, size: size)
        projectile.name = "Projectile"
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.isDynamic = false
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.player
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        let rotate = SKAction.rotate(byAngle: .pi, duration: 0.2)
        let spinForever = SKAction.repeatForever(rotate)
        projectile.run(spinForever)
        
        let projectileSpeed: CGFloat = min(gameSpeed * 2, 800)
        
        var startPoint: CGPoint
        var endPoint: CGPoint
        var controlPoint: CGPoint

        let startX = scene.size.width
        let endX: CGFloat = 50

        let throwType = Int.random(in: 0...3)

        switch throwType {
        case 0:
            startPoint = CGPoint(x: startX, y: 100)
            endPoint = CGPoint(x: endX, y: 75)
            controlPoint = CGPoint(x: scene.size.width / 2, y: 300)
        case 1:
            startPoint = CGPoint(x: startX, y: 250)
            endPoint = CGPoint(x: endX, y: 150)
            controlPoint = CGPoint(x: scene.size.width / 2, y: 550)
        case 2:
            startPoint = CGPoint(x: startX, y: 150)
            endPoint = CGPoint(x: endX, y: 250)
            controlPoint = CGPoint(x: scene.size.width / 2, y: 350)
        case 3:
            startPoint = CGPoint(x: startX, y: 450)
            endPoint = CGPoint(x: endX, y: 150)
            controlPoint = CGPoint(x: scene.size.width * 0.8, y: 475)
        default:
            return (projectile, .zero)
        }
        
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)
        
        let followAction = SKAction.follow(path, asOffset: false, orientToPath: false, speed: projectileSpeed)
        let removeAction = SKAction.removeFromParent()
        
        projectile.position = startPoint
        projectile.run(SKAction.sequence([followAction, removeAction]))
        
        return (projectile, startPoint)
    }
    
    static func createTutorialProjectile(in scene: SKScene) -> SKSpriteNode {
        let texture = SKTexture(imageNamed: "Sendal")
        
        let targetWidth: CGFloat = 30
        let aspectRatio = texture.size().height / texture.size().width
        let targetHeight = targetWidth * aspectRatio
        let size = CGSize(width: targetWidth, height: targetHeight)
        let projectile = SKSpriteNode(texture: texture, color: .clear, size: size)
        projectile.name = "Projectile"
        
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: 10)
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.projectile
        projectile.physicsBody?.isDynamic = false
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.player
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.none
        
        let rotate = SKAction.rotate(byAngle: .pi, duration: 0.2)
        let spinForever = SKAction.repeatForever(rotate)
        projectile.run(spinForever)
        
        let projectileSpeed: CGFloat = min(gameSpeed * 2, 800)
        
        var startPoint: CGPoint
        var endPoint: CGPoint
        var controlPoint: CGPoint

        let startX = scene.size.width
        let endX: CGFloat = 50

        startPoint = CGPoint(x: startX, y: 75)
        endPoint = CGPoint(x: endX, y: 50)
        controlPoint = CGPoint(x: scene.size.width / 2, y: 200)
        
        let path = CGMutablePath()
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, control: controlPoint)
        
        let followAction = SKAction.follow(path, asOffset: false, orientToPath: false, speed: projectileSpeed)
        let removeAction = SKAction.removeFromParent()
        
        projectile.position = startPoint
        projectile.run(SKAction.sequence([followAction, removeAction]))
        
        return projectile
    }
    
    // MARK: - Platform
    static func createSolidPlatform(at position: CGPoint, size: CGSize) -> SKSpriteNode {
        let platform = SKSpriteNode(color: .clear, size: size)
        platform.zPosition = 0
        platform.name = "SolidPlatform"
        platform.physicsBody = SKPhysicsBody(rectangleOf: platform.size)
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.categoryBitMask = PhysicsCategory.solidPlatform
        platform.physicsBody?.collisionBitMask = PhysicsCategory.player
        
        // Create the "TiangListrik" decoration as a child of the platform
        let textureNames = ["BuildingWithSignwPlatform", "BuildingTallwPlatform"]
        let textureName = textureNames.randomElement()!
        let decorationTexture = SKTexture(imageNamed: textureName)
        
        var targetWidth: CGFloat = 0
        var objectPosition = CGPoint(x: 0, y: -115)
        var platformPosition = position
        
        switch textureName {
            case "BuildingWithSignwPlatform":
                targetWidth = 325
                objectPosition = CGPoint(x: 0, y: -60)
                platformPosition.y -= 7
            case "BuildingTallwPlatform":
                targetWidth = 320
                objectPosition = CGPoint(x: 0, y: -10)
                platformPosition.y -= 20
            default:
                targetWidth = 300
                objectPosition = CGPoint(x: 0, y: -50)
        }
        
        let aspectRatio = decorationTexture.size().height / decorationTexture.size().width
        let decorationWidth = targetWidth
        let decorationHeight = decorationWidth * aspectRatio
        let decorationSize = CGSize(width: decorationWidth, height: decorationHeight)

        let decoration = SKSpriteNode(texture: decorationTexture, size: decorationSize)
        decoration.position = objectPosition // Align bottom to platform
        decoration.zPosition = -1
        decoration.name = "BuildingDecoration"
        
        platform.position = platformPosition
        platform.addChild(decoration)
        
        // Apply movement action directly from the factory
        platform.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.platform)
        
        return platform
    }
    
    static func createSemiSolidPlatform(at position: CGPoint, size: CGSize) -> SKSpriteNode {
        // This will be the actual platform with physics
        let platform = SKSpriteNode(color: .clear, size: size)
        platform.position = position
        platform.name = "SemiSolidPlatform"
        platform.zPosition = 0

        // Physics body: only the top edge is solid
        let topEdge = SKPhysicsBody(edgeFrom: CGPoint(x: -size.width / 2, y: size.height / 2),
                                    to: CGPoint(x: size.width / 2, y: size.height / 2))
        platform.physicsBody = topEdge
        platform.physicsBody?.isDynamic = false
        platform.physicsBody?.categoryBitMask = PhysicsCategory.semiSolidPlatform
        platform.physicsBody?.collisionBitMask = PhysicsCategory.player
        platform.physicsBody?.contactTestBitMask = 0

        // Create the "TiangListrik" decoration as a child of the platform
        let decorationTexture = SKTexture(imageNamed: "TiangListrik")
        let aspectRatio = decorationTexture.size().height / decorationTexture.size().width
        let decorationHeight = 300.0
        let decorationWidth = 600.0
        let decorationSize = CGSize(width: decorationWidth, height: decorationHeight)

        let decoration = SKSpriteNode(texture: decorationTexture, size: decorationSize)
        decoration.position = CGPoint(x: 0, y: -115) // Align bottom to platform
        decoration.zPosition = -1
        decoration.name = "TiangListrikDecoration"

        // Add the decoration behind the platform
        platform.addChild(decoration)

        // Add movement
        platform.run(createMovementAction(distance: worldMoveDistance, speed: gameSpeed), withKey: MoveKey.platform)

        return platform
    }
}
