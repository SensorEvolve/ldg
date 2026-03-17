import XCTest
@testable import StarWarsBattle

final class GameConstantsTests: XCTestCase {

    func testShipSpeed() {
        XCTAssertEqual(GameConstants.shipSpeed, 300)
    }

    func testBulletSpeed() {
        XCTAssertEqual(GameConstants.bulletSpeed, 600)
    }

    func testMaxBullets() {
        XCTAssertEqual(GameConstants.maxBullets, 3)
    }

    func testMaxHP() {
        XCTAssertEqual(GameConstants.maxHP, 10)
    }

    func testPhysicsCategoriesAreUnique() {
        let categories: [UInt32] = [
            PhysicsCategory.imperialShip,
            PhysicsCategory.rebelShip,
            PhysicsCategory.imperialBullet,
            PhysicsCategory.rebelBullet,
        ]
        XCTAssertEqual(Set(categories).count, 4, "All physics categories must be unique bit flags")
    }

    func testAllPhysicsCategoriesAreDistinctBitFlags() {
        // Each category must occupy a unique bit position
        XCTAssertEqual(PhysicsCategory.imperialShip   & PhysicsCategory.rebelShip,      0)
        XCTAssertEqual(PhysicsCategory.imperialShip   & PhysicsCategory.imperialBullet, 0)
        XCTAssertEqual(PhysicsCategory.imperialShip   & PhysicsCategory.rebelBullet,    0)
        XCTAssertEqual(PhysicsCategory.rebelShip      & PhysicsCategory.imperialBullet, 0)
        XCTAssertEqual(PhysicsCategory.rebelShip      & PhysicsCategory.rebelBullet,    0)
        XCTAssertEqual(PhysicsCategory.imperialBullet & PhysicsCategory.rebelBullet,    0)
    }
}
