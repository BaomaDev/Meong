import Foundation
import SwiftUI

// MARK: - Environment Variables
let customGravity: CGFloat = -20
let groundHeight: CGFloat = 60
let airResistance: CGFloat = 5
let platformHeight = 240.0
let platformThickness = 7.0

// MARK: - Player Variables
let playerHitboxWidth: CGFloat = 70
let playerHitboxHeight: CGFloat = 49

// MARK: - Movement Variables
let longSwipeTreshold = 150.0           // Min. distance for pan input to trigger high jump
let shortSwipeTreshold = 50.0           // Strokes shorter than this will not be registered

let defaultJumpHeight: CGFloat = 135
let defaultJumpDistance: CGFloat = 350
let diveForce: CGFloat = 150            // Downward force applied during dive command
let landingDuration: CGFloat = 0.25     // "Ministun" duration when dive landing
let transformDuration: TimeInterval = 0.05  // Transition of hitbox between states
let parryRadius: CGFloat = 160.0 // The area around the player to check for projectiles
let parryCooldown: TimeInterval = 2.0

// MARK: - Obstacle Variables
let projectileSpeed = 450.0

// MARK: - Game Speed Variables
let worldMoveDistance: CGFloat = UIScreen.main.bounds.width * 2
let baseGameSpeed: CGFloat = 300.0
var gameSpeed: CGFloat = baseGameSpeed
let maxGameSpeed: CGFloat = 600.0
var speedScalingFactor: CGFloat = 20.0   // Speed increases every N seconds

// MARK: - World Generation Variables
let minPlatformDelay = 1.2
let minObstacleDelay = 1.0
let minProjectileDelay = 1.4
let minCollectibleDelay = 1.3

enum PlayerState {
    case running
    case airborne
    case ducking
    case diving
    case parrying
    case landing
    case flying
}

enum MovementAction {
    case normalJump, highJump, duck
}

struct PhysicsCategory {
    static let all: UInt32 = UInt32.max
    
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1          // 1
    static let ground: UInt32 = 0b10         // 2
    static let semiSolidPlatform: UInt32 = 0b100 // 4
    static let solidPlatform: UInt32 = 0b1000    // 8
    static let projectile: UInt32 = 0b10000      // 16
    static let obstacle: UInt32 = 0b100000       // 32
    static let safeZone: UInt32 = 0b1000000      // 64
    static let enemy: UInt32 = 0b10000000
    static let powerUp: UInt32 = 0b100000000
    static let coin: UInt32 = 0b1000000000
    static let catnip: UInt32 = 0b10000000000
}

enum SurfaceType {
    case none               // Falling
    case ground
    case semiSolidPlatform  // Can jump up and drop down
    case solidPlatform      // Cannot jump up directly from below, cannot drop down
    
    var isGrounded: Bool {  // Variable used for control logic (grouped into is grounded / is falling)
        return self != .none
    }
    
    var isPlatform: Bool {
        return self == .semiSolidPlatform || self == .solidPlatform
    }
}

extension Notification.Name {
    static let gameDidAutoPause = Notification.Name("gameDidAutoPause")
}
