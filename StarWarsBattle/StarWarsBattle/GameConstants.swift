import CoreGraphics
import Foundation

enum GameConstants {
    static let shipSpeed: CGFloat    = 300   // pt/sec — matches Rust SHIP_SPEED=5 @ 60fps
    static let bulletSpeed: CGFloat  = 600   // pt/sec — matches Rust BULLET_VEL=10 @ 60fps
    static let maxBullets: Int       = 3
    static let maxHP: Int            = 10
    static let joystickRadius: CGFloat   = 60
    static let joystickDeadZone: CGFloat = 5
    static let fireButtonSize: CGFloat   = 80
    static let controlMargin: CGFloat    = 30
    static let dividerWidth: CGFloat     = 2
    static let fireRepeatInterval: TimeInterval = 0.18
}
