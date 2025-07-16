// In GameViewController.swift
import UIKit
import SpriteKit

class GameViewController: UIViewController {
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // We will treat the main view as our SpriteKit view.
        if let view = self.view as! SKView? {
            // Create the scene with the size of the view's bounds.
            // This is crucial to ensure our coordinate system is correct.
            let scene = GameScene(size: view.bounds.size)
            
            // Set the scale mode to scale to fit the window.
            scene.scaleMode = .aspectFill
            
            // Present the scene.
            view.presentScene(scene)
            
            // These options are great for debugging.
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return.landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
