import Foundation

let customGravity: CGFloat = -24
let groundHeight: CGFloat = 60
let playerHitboxWidth: CGFloat = 50
let playerHitboxHeight: CGFloat = 50
let defaultJumpHeight: CGFloat = 120
let defaultJumpDistance: CGFloat = 300
let airResistance: CGFloat = 5
let diveForce: CGFloat = 60
let landingDuration: CGFloat = 0.5
    
let jumpSnapRayLength: CGFloat = 240.0
let throwVelocity: CGFloat = -10.0
var gameSpeed: CGFloat = 300.0
var speedScalingFactor: CGFloat = 2.0
let platformHeight = 10.0
let projectileSpeed = 450.0

let parryRadius: CGFloat = 100.0 // The area around the player to check for projectiles
let parryCooldown: TimeInterval = 2.0 // 2 seconds

enum PlayerState {
    case running
    case airborne
    case ducking
    case diving
    case parrying
    case landing
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
