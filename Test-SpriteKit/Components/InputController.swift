import Foundation
import SpriteKit

extension GameScene {
    func setupSwipeRecognizers() {
        swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        swipeUpRecognizer?.direction = .up
        self.view?.addGestureRecognizer(swipeUpRecognizer!)
        
        swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
        swipeDownRecognizer?.direction = .down
        self.view?.addGestureRecognizer(swipeDownRecognizer!)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.view?.addGestureRecognizer(tapRecognizer)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            parry()
        }
    }
    
    @objc func handleSwipes(_ sender: UISwipeGestureRecognizer) {
        if sender.state == .ended {
            switch sender.direction {
            case .up:
                jump()
            case .down:
                duck()
            default:
                break
            }
        }
    }
    
    func parry() {
//        guard player?.color == .orange else { return }
        
        // Parry cooldown
        let timeSinceLastParry = lastUpdateTime - lastParryTime
        guard timeSinceLastParry > Constants.parryCooldown else {
//            print("Parry on cooldown.")
            return
        }
        lastParryTime = lastUpdateTime
        
        guard let player = player else { return }
        player.color = .green
                
        // Check the area for projectiles.
        self.enumerateChildNodes(withName: "Projectile") { (node, stop) in
            let distance = hypot(node.position.x - player.position.x, node.position.y - player.position.y)
            
            if distance < Constants.parryRadius {
                print("Parry successful!")
                node.removeFromParent() // Instantly remove projectile
                // TODO: Animate parry with sprites
                stop.pointee = true
            }
        }
        
        // Adjust wait variable to match the parry sprite animation sequence
        let wait = SKAction.wait(forDuration: 0.3)
        // Cosmetic : return to previous state color
        let restoreState = SKAction.run {
            if self.player?.color == .green {
                self.player?.color = .orange
            }
        }
        player.run(SKAction.sequence([wait, restoreState]))
    }
    
    // Vertical ray to detect overhead platforms
    private func getVerticalHit() -> (node: SKNode, distance: CGFloat)? {
        guard let player = player else { return nil }
        
        var closestHit: (node: SKNode, distance: CGFloat)?
        var closestDistance: CGFloat = .infinity
        
        let rayStart = player.position
        let rayEnd = CGPoint(x: player.position.x, y: player.position.y + Constants.jumpSnapRayLength)
        
        physicsWorld.enumerateBodies(alongRayStart: rayStart, end: rayEnd) { (body, hitPoint, _, _) in
            if let node = body.node, (node.name == "SemiSolidPlatform" || node.name == "SolidPlatform") {
                let distance = hypot(hitPoint.x - player.position.x, hitPoint.y - player.position.y)
                if distance < closestDistance {
                    closestDistance = distance
                    closestHit = (node: node, distance: distance)
                }
            }
        }
        return closestHit
    }
    
    // Diagonal ray to detect incoming platforms
    private func getDiagonalHit() -> (node: SKNode, distance: CGFloat)? {
        guard let player = player else { return nil }

        var closestHit: (node: SKNode, distance: CGFloat)?
        var closestDistance: CGFloat = .infinity

        let rayStart = player.position
        // Diagonal ray length is currently equal to jumpSnapRayLength; upon testing we can try out using a proper hypotenuse formula
        let rayEnd = CGPoint(x: player.position.x + Constants.jumpSnapRayLength, y: player.position.y + Constants.jumpSnapRayLength)
        
        physicsWorld.enumerateBodies(alongRayStart: rayStart, end: rayEnd) { (body, hitPoint, _, _) in
            if let node = body.node, (node.name == "SemiSolidPlatform" || node.name == "SolidPlatform") {
                let distance = hypot(hitPoint.x - player.position.x, hitPoint.y - player.position.y)
                if distance < closestDistance {
                    closestDistance = distance
                    closestHit = (node: node, distance: distance)
                }
            }
        }
        return closestHit
    }
    
    func findJumpTarget() -> SKNode? {
        let verticalHitResult = getVerticalHit()
        let diagonalHitResult = getDiagonalHit()

        // If only the vertical ray detects a platform, it is not valid
        if verticalHitResult != nil && diagonalHitResult == nil {
            return nil
        }

        // If only the diagonal ray detects a platform;
        if verticalHitResult == nil, let dHit = diagonalHitResult {
            // Check if it's a solid platform and the player is too close to its left edge.
            if dHit.node.name == "SolidPlatform" {
                let platformWidth = dHit.node.frame.size.width
                let platformLeftEdgeX = dHit.node.position.x - (platformWidth / 2)

                let distanceToLeftEdge = platformLeftEdgeX - player!.position.x
                if distanceToLeftEdge < Constants.jumpSnapRayLength / 4 {   // Min. Jump length is approx. 1/4 of the ray length
                    return nil // It's too close to the edge, invalidate the target.
                }
            }
            
            // Otherwise (it's a semi-solid platform or a far-away solid one), it's a valid target.
            return dHit.node
        }

        // If both rays detect the same platform, check its type.
        if let vHit = verticalHitResult, let dHit = diagonalHitResult, vHit.node == dHit.node {
            if vHit.node.name == "SemiSolidPlatform" {
                // Valid target if it's semi-solid.
                return vHit.node
            } else if vHit.node.name == "SolidPlatform" {
                // Invalid target if it's solid.
                return nil
            }
        }

        return nil
    }
    
    func calculateMinimumJumpForce(to targetY: CGFloat, distanceX: CGFloat) -> CGFloat {
        guard let player = player else { return 0 }
        
        // 1. Calculate the required vertical distance to travel from the player's current position.
        // We use the top of the player's hitbox as the starting point.
        let startY = player.position.y + Constants.playerHitboxHeight
        let distanceY = targetY - startY
        
        // 2. Calculate the ideal velocity needed in a vacuum using the physics formula.
        // Formula: v = sqrt(-2 * g * d)
        let idealVelocity = sqrt(-2 * Constants.gravity * distanceY)
        
        // 3. Add a compensation factor for air resistance.
        let minJumpDistance = Constants.jumpSnapRayLength / 4   // Any closer than this, and the jump will be invalid
        let xyRatio = min(1.9, max(1.4, distanceX / minJumpDistance))   // The further away the player is from the platform, the more force should be applied.
//        print("distance x : \(distanceX)")
//        print("ratio: \(xyRatio)")
        let resistanceCompensation: CGFloat = sqrt(Constants.airResistance) * xyRatio   // Scale compensation with air resistance
        
        let requiredImpulse = idealVelocity * resistanceCompensation
        
        return requiredImpulse
    }

    func jump() {
        // Must be grounded and can jump in order to proceed
        guard currentSurface.isGrounded && canJump else { return }
        // Disable double-jumping
        canJump = false
        
        if let targetPlatform = findJumpTarget(), let player = player {
            let playerX = player.position.x
            let platformSize = targetPlatform.frame.size
            let targetPos = targetPlatform.position
            let platformLeftEdge = targetPos.x - (platformSize.width / 2)
            let platformRightEdge = targetPos.x + (platformSize.width / 2)
            let jumpVelocity: CGFloat
            
            let isUnderPlatform = (playerX >= platformLeftEdge && playerX <= platformRightEdge) // Separate logic for jumping when directly below a platform
            if isUnderPlatform {
                jumpVelocity = 1.5 * (targetPos.y - player.position.y)  // Hard coded jump height for when directly below platform
            } else {
                jumpVelocity = calculateMinimumJumpForce(to: targetPos.y, distanceX: platformLeftEdge - playerX)
            }
            
            player.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpVelocity))
//            print("Performing calculated trajectory jump.")

        } else {
            // --- Default Jump Logic ---
//            print("No target found, performing default jump.")
            player?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            player?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: Constants.jumpForce))
        }
    }
    
    func duck() {
        guard currentSurface.isGrounded else { return }
        
        switch currentSurface {
        // On semi-solid platforms, ducking drops the player down
        case .semiSolidPlatform:
            // Disable collision for 0.5s, allowing player to drop
            isDropping = true
            player?.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.solidPlatform
            let wait = SKAction.wait(forDuration: 0.5)

            let restoreCollision = SKAction.run {
                self.player?.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
                self.isDropping = false
            }
            self.run(SKAction.sequence([wait, restoreCollision]))
            
        // On the ground or on solid platforms, ducking lowers the player's body
        case .ground, .solidPlatform: // Can't drop through ground or solid platforms.
            player?.color = .red
            swipeUpRecognizer?.isEnabled = false
            swipeDownRecognizer?.isEnabled = false
            
            let originalSize = CGSize(width: Constants.playerHitboxWidth, height: Constants.playerHitboxHeight)
            // Elongate, while getting shorter
            let duckSize = CGSize(width: Constants.playerHitboxWidth + (Constants.playerHitboxHeight / 2),
                                  height: Constants.playerHitboxHeight / 2)
            let adjustY = CGFloat(Constants.playerHitboxHeight / 4) // When changing height, Y is anchored to the player's center. Adjust the position to keep the player grounded.
            
            // Apply new size
            player?.size = duckSize
            player?.position.y -= adjustY
            player?.physicsBody = SKPhysicsBody(rectangleOf: duckSize)
            reapplyPlayerPhysics()
            
            // Duck duration
            let wait = SKAction.wait(forDuration: 0.5)
            let restore = SKAction.run {
                self.player?.size = originalSize
                self.player?.position.y += adjustY
                self.player?.physicsBody = SKPhysicsBody(rectangleOf: originalSize)
                self.reapplyPlayerPhysics()
                
                self.swipeUpRecognizer?.isEnabled = true
                self.swipeDownRecognizer?.isEnabled = true
                self.player?.color = self.currentSurface.isGrounded ? .orange : .yellow
            }
            self.run(SKAction.sequence([wait, restore]))
            
        case .none:
            break
        }
    }

    func reapplyPlayerPhysics() {
        player?.physicsBody?.isDynamic = true
        player?.physicsBody?.allowsRotation = false
        player?.physicsBody?.restitution = 0.0  // Controls bounce
        player?.physicsBody?.linearDamping = Constants.airResistance
        player?.physicsBody?.categoryBitMask = PhysicsCategory.player
        player?.physicsBody?.collisionBitMask = PhysicsCategory.ground | PhysicsCategory.semiSolidPlatform | PhysicsCategory.solidPlatform
        player?.physicsBody?.contactTestBitMask = PhysicsCategory.projectile
    }
}
