import XCTest
import SpriteKit
@testable import StarWarsBattle

final class SpaceshipNodeTests: XCTestCase {

    func testInitialHP() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        XCTAssertEqual(ship.hp, GameConstants.maxHP)
    }

    func testInitialScore() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        XCTAssertEqual(ship.score, 0)
    }

    func testTakeDamageReducesHP() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        ship.takeDamage()
        XCTAssertEqual(ship.hp, GameConstants.maxHP - 1)
    }

    func testTakeDamageDoesNotGoBelowZero() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        for _ in 0..<20 { ship.takeDamage() }
        XCTAssertEqual(ship.hp, 0)
    }

    func testIsDeadWhenHPZero() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        XCTAssertFalse(ship.isDead)
        for _ in 0..<10 { ship.takeDamage() }
        XCTAssertTrue(ship.isDead)
    }

    func testMoveClampedToMaxX() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        ship.size = CGSize(width: 60, height: 40)
        ship.position = CGPoint(x: 500, y: 200)
        let bounds = CGRect(x: 0, y: 0, width: 590, height: 820)
        ship.applyVelocity(CGVector(dx: 1000, dy: 0), deltaTime: 1.0, bounds: bounds)
        XCTAssertLessThanOrEqual(ship.position.x, bounds.maxX, "Ship must not exceed right bound")
    }

    func testMoveClampedToMinX() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        ship.size = CGSize(width: 60, height: 40)
        ship.position = CGPoint(x: 50, y: 200)
        let bounds = CGRect(x: 30, y: 0, width: 560, height: 820)
        ship.applyVelocity(CGVector(dx: -1000, dy: 0), deltaTime: 1.0, bounds: bounds)
        XCTAssertGreaterThanOrEqual(ship.position.x, bounds.minX, "Ship must not exceed left bound")
    }

    func testMoveClampedToMinY() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        ship.size = CGSize(width: 60, height: 40)
        ship.position = CGPoint(x: 200, y: 30)
        let bounds = CGRect(x: 0, y: 20, width: 590, height: 800)
        ship.applyVelocity(CGVector(dx: 0, dy: -1000), deltaTime: 1.0, bounds: bounds)
        XCTAssertGreaterThanOrEqual(ship.position.y, bounds.minY)
    }

    func testImperialPhysicsCategory() {
        let ship = SpaceshipNode(imageName: "imperial_spaceship")
        // Imperial ship must detect contact with REBEL bullets (not its own)
        ship.setupPhysics(category: PhysicsCategory.imperialShip,
                          contactTest: PhysicsCategory.rebelBullet)
        XCTAssertEqual(ship.physicsBody?.categoryBitMask, PhysicsCategory.imperialShip)
        XCTAssertEqual(ship.physicsBody?.contactTestBitMask, PhysicsCategory.rebelBullet)
        XCTAssertEqual(ship.physicsBody?.collisionBitMask, 0)
    }
}
