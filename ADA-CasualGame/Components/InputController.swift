import Foundation
import SpriteKit

extension GameScene {
    func setupSwipeRecognizers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.view?.addGestureRecognizer(tapRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.view?.addGestureRecognizer(panRecognizer)
    }

    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let player = player else { return }
        
        switch sender.state {
        case .began:
            panStartPoint = sender.location(in: self.view)
            
        case .ended:
            guard let startPoint = panStartPoint else { return }
            let endPoint = sender.location(in: self.view)
            let deltaY = endPoint.y - startPoint.y
            let deltaX = endPoint.x - startPoint.x
            
            // Ignore if mostly horizontal
            guard abs(deltaY) > abs(deltaX) else {
                panStartPoint = nil
                return
            }
            
            let swipeThreshold: CGFloat = 30.0
            
            // ✅ Intercept swipes during catnip mode
            if player.currentState == .flying {
                let targetY: CGFloat
                if deltaY < -swipeThreshold {
                    // Swipe up → go to Y = 280
                    targetY = 280
                } else if deltaY > swipeThreshold {
                    // Swipe down → go to Y = 140
                    targetY = 140
                } else {
                    panStartPoint = nil
                    return
                }
                
                let moveToY = SKAction.moveTo(y: targetY, duration: 0.3)
                moveToY.timingMode = .easeOut
                player.run(moveToY)
                
                panStartPoint = nil
                return
            }

            // Normal behavior if not in catnip mode
            if deltaY < -swipeThreshold {
                let swipeDistance = -deltaY
                player.jump(swipeDistance: swipeDistance)
            } else if deltaY > swipeThreshold {
                player.duck()
            }
            
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
    
    func parry() {
        guard let player = player else { return }
        
        // Attempt to parry
        guard player.parry(currentTime: lastUpdateTime) else { return }
        
        // Check the area for projectiles
        self.enumerateChildNodes(withName: "Projectile") { (node, stop) in
            let distance = hypot(node.position.x - player.position.x, node.position.y - player.position.y)
            
            if distance < parryRadius {
                EffectsFactory.shared.playSound(soundKey: "parry_success.wav")

                
                let parrySounds = ["parry1.mp3", "parry2.mp3"]
                EffectsFactory.shared.playSound(soundKey: parrySounds.randomElement()!)

                node.removeFromParent()
                stop.pointee = true
            }
        }
    }
}
