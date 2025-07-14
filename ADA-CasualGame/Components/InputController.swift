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
        guard let player = player else { return }
        
        // Attempt to parry
        guard player.parry(currentTime: lastUpdateTime) else { return }
        
        // Check the area for projectiles
        self.enumerateChildNodes(withName: "Projectile") { (node, stop) in
            let distance = hypot(node.position.x - player.position.x, node.position.y - player.position.y)
            
            if distance < Constants.parryRadius {
                print("Parry successful!")
                node.removeFromParent()
                stop.pointee = true
            }
        }
    }
    
    func jump() {
        guard let player = player else { return }
        
        // Find jump target using existing logic
        let targetPlatform = findJumpTarget()
        
        // Attempt jump
        let jumpSuccess = player.jump(targetPlatform: targetPlatform)
        
        if jumpSuccess {
            if targetPlatform != nil {
                print("Performing calculated trajectory jump.")
            } else {
                print("No target found, performing default jump.")
            }
        }
    }
    
    func duck() {
        guard let player = player else { return }
        
        // Disable gestures during duck on ground/solid platforms
        if player.surfaceType == .ground || player.surfaceType == .solidPlatform {
            swipeUpRecognizer?.isEnabled = false
            swipeDownRecognizer?.isEnabled = false
            
            // Re-enable after duck duration
            let wait = SKAction.wait(forDuration: 0.5)
            let restore = SKAction.run { [weak self] in
                self?.swipeUpRecognizer?.isEnabled = true
                self?.swipeDownRecognizer?.isEnabled = true
            }
            self.run(SKAction.sequence([wait, restore]))
        }
        
        player.duck()
    }
    
    // MARK: - Jump Target Finding (existing logic)
    
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
        guard let player = player else { return nil }
        
        let verticalHitResult = getVerticalHit()
        let diagonalHitResult = getDiagonalHit()

        // If only the vertical ray detects a platform, it is not valid
        if verticalHitResult != nil && diagonalHitResult == nil {
            return nil
        }

        // If only the diagonal ray detects a platform
        if verticalHitResult == nil, let dHit = diagonalHitResult {
            // Check if it's a solid platform and the player is too close to its left edge
            if dHit.node.name == "SolidPlatform" {
                let platformWidth = dHit.node.frame.size.width
                let platformLeftEdgeX = dHit.node.position.x - (platformWidth / 2)

                let distanceToLeftEdge = platformLeftEdgeX - player.position.x
                if distanceToLeftEdge < Constants.jumpSnapRayLength / 4 {
                    return nil // Too close to the edge
                }
            }
            
            return dHit.node
        }

        // If both rays detect the same platform, check its type
        if let vHit = verticalHitResult, let dHit = diagonalHitResult, vHit.node == dHit.node {
            if vHit.node.name == "SemiSolidPlatform" {
                return vHit.node
            } else if vHit.node.name == "SolidPlatform" {
                return nil
            }
        }

        return nil
    }
}
