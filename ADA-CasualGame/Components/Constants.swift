import Foundation

struct Constants {
    static let gravity: CGFloat = -24
    static let groundHeight: CGFloat = 60
    static let playerHitboxWidth: CGFloat = 50
    static let playerHitboxHeight: CGFloat = 50
    static let jumpForce: CGFloat = 150
    static let airResistance: CGFloat = 5
    
    static let jumpSnapRayLength: CGFloat = 240.0
    static let throwVelocity: CGFloat = -10.0
    static var gameSpeed: CGFloat = 400.0
    static let platformHeight = 10.0
    static let projectileSpeed = 450.0
    
    static let parryRadius: CGFloat = 100.0 // The area around the player to check for projectiles
    static let parryCooldown: TimeInterval = 2.0 // 2 seconds
}

enum PlayerState {
    case running
    case jumping
    case falling
    case ducking
}

struct PhysicsCategory {
    static let all: UInt32 = UInt32.max
    
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1          // 1
    static let ground: UInt32 = 0b10         // 2
    static let semiSolidPlatform: UInt32 = 0b100 // 4
    static let solidPlatform: UInt32 = 0b1000    // 8
    static let projectile: UInt32 = 0b10000      // 16
}

enum SurfaceType {
    case none               // Falling
    case ground
    case semiSolidPlatform  // Can jump up and drop down
    case solidPlatform      // Cannot jump up directly from below, cannot drop down
    
    var isGrounded: Bool {  // Variable used for control logic (grouped into is grounded / is falling
        return self != .none
    }
}
