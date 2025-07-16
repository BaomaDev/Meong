import Foundation
import SpriteKit

extension GameScene {
    func setupSwipeRecognizers() {
//        swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
//        swipeUpRecognizer?.direction = .up
//        self.view?.addGestureRecognizer(swipeUpRecognizer!)
//        
//        swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipes(_:)))
//        swipeDownRecognizer?.direction = .down
//        self.view?.addGestureRecognizer(swipeDownRecognizer!)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.view?.addGestureRecognizer(tapRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.view?.addGestureRecognizer(panRecognizer)
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let player = player else { return }
        
        switch sender.state {
        case .began:
            // Record the start point when the player first touches down.
            panStartPoint = sender.location(in: self.view)
            
        case .ended:
            // When the player lifts their finger, determine the swipe's direction and distance.
            guard let startPoint = panStartPoint else { return }
            let endPoint = sender.location(in: self.view)
            
            // Calculate the vertical and horizontal distance of the swipe.
            let deltaY = endPoint.y - startPoint.y
            let deltaX = endPoint.x - startPoint.x
            
            // We only care about swipes that are primarily vertical.
            guard abs(deltaY) > abs(deltaX) else {
                panStartPoint = nil
                return
            }

            // A small threshold to prevent accidental taps from registering as swipes.
            let swipeThreshold: CGFloat = 30.0
            
            if deltaY < -swipeThreshold { // Negative deltaY means finger moved UP.
                let swipeDistance = -deltaY // Make the distance positive
                let targetPlatform = findJumpTarget()
    
                player.panContolledJump(swipeDistance: swipeDistance, target: targetPlatform)
            } else if deltaY > swipeThreshold { // Positive deltaY means finger moved DOWN.
//                print("Swipe DOWN detected. Performing Duck.")
                duck()
            }
            
            // Reset the start point for the next pan.
            panStartPoint = nil
            
        default:
            break
        }
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
            
            if distance < parryRadius {
//                print("Parry successful!")
                node.removeFromParent()
                stop.pointee = true
            }
        }
    }
    
    func jump() {
        guard let player = player else { return }
        
        // Find jump target using existing logic
        let targetPlatform = findJumpTarget()
        player.jump(targetPlatform: targetPlatform)
    }
    
    func duck() {
        guard let player = player else { return }
        if player.currentState == .ducking {
            return
        } else {
            player.duck()
        }
    }
    
    // MARK: - Jump Target Finding (existing logic)
    
    // Vertical ray to detect overhead platforms
    private func getVerticalHit() -> (node: SKNode, distance: CGFloat)? {
        guard let player = player else { return nil }
        
        var closestHit: (node: SKNode, distance: CGFloat)?
        var closestDistance: CGFloat = .infinity
        
        let rayStart = player.position
        let rayEnd = CGPoint(x: player.position.x, y: player.position.y + jumpSnapRayLength)
        
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
    private func getDiagonalHit() -> (node: SKNode, distance: CGFloat )? {
        guard let player = player else { return nil }

        var closestHit: (node: SKNode, distance: CGFloat)?
        var closestDistance: CGFloat = .infinity

        let rayStart = player.position
        let rayEnd = CGPoint(x: player.position.x + hypot(jumpSnapRayLength, jumpSnapRayLength), y: player.position.y + jumpSnapRayLength)
        
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
    
    private func findJumpTarget() -> SKNode? {
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
                if distanceToLeftEdge < jumpSnapRayLength/4 {
                    return nil // Too close to the edge
                }
            }
            
            return dHit.node
        }

        // If both rays detect the same platform, check its type
        if let vHit = verticalHitResult, let dHit = diagonalHitResult, vHit.node == dHit.node {
            if vHit.node.name == "SemiSolidPlatform" {
                let platformWidth = dHit.node.frame.size.width
                let platformRightEdgeX = dHit.node.position.x + platformWidth/2

                let distanceToRightEdge = platformRightEdgeX - player.position.x
                if distanceToRightEdge < gameSpeed/2 {
                    return nil // Too close to the edge
                } else {
                    return vHit.node
                }
            }
        }

        return nil
    }
}
