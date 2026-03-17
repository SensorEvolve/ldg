import Foundation

struct PhysicsCategory {
    static let imperialShip:   UInt32 = 1 << 0  // 1
    static let rebelShip:      UInt32 = 1 << 1  // 2
    static let imperialBullet: UInt32 = 1 << 2  // 4
    static let rebelBullet:    UInt32 = 1 << 3  // 8
}
