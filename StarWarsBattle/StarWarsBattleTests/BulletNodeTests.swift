import XCTest
import SpriteKit
@testable import StarWarsBattle

final class BulletNodeTests: XCTestCase {

    func testImperialBulletIsRed() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: 600))
        XCTAssertEqual(bullet.color, UIColor.red)
    }

    func testRebelBulletIsBlue() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: -600))
        XCTAssertEqual(bullet.color, UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0))
    }

    func testBulletSize() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: 600))
        XCTAssertEqual(bullet.size, CGSize(width: 5, height: 15))
    }

    func testImperialBulletPhysicsCategory() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: 600))
        XCTAssertEqual(bullet.physicsBody?.categoryBitMask, PhysicsCategory.imperialBullet)
        XCTAssertEqual(bullet.physicsBody?.contactTestBitMask, PhysicsCategory.rebelShip)
        XCTAssertEqual(bullet.physicsBody?.collisionBitMask, 0)
    }

    func testRebelBulletPhysicsCategory() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: -600))
        XCTAssertEqual(bullet.physicsBody?.categoryBitMask, PhysicsCategory.rebelBullet)
        XCTAssertEqual(bullet.physicsBody?.contactTestBitMask, PhysicsCategory.imperialShip)
        XCTAssertEqual(bullet.physicsBody?.collisionBitMask, 0)
    }

    func testBulletVelocityStored() {
        let vel = CGVector(dx: 0, dy: 600)
        let bullet = BulletNode(velocity: vel)
        XCTAssertEqual(bullet.bulletVelocity.dx, vel.dx)
        XCTAssertEqual(bullet.bulletVelocity.dy, vel.dy)
    }

    func testImperialBulletPhysicsVelocitySet() {
        let vel = CGVector(dx: 0, dy: 600)
        let bullet = BulletNode(velocity: vel)
        XCTAssertEqual(bullet.physicsBody?.velocity.dx, vel.dx, accuracy: 0.01)
        XCTAssertEqual(bullet.physicsBody?.velocity.dy, vel.dy, accuracy: 0.01)
    }

    func testBulletIsDynamicForContactCallbacks() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: 600))
        XCTAssertTrue(bullet.physicsBody?.isDynamic == true)
    }

    func testBulletOutOfBoundsTop() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: 600))
        bullet.position = CGPoint(x: 400, y: 1221)  // > sceneHeight(1180) + 20
        XCTAssertTrue(bullet.isOutOfBounds(sceneHeight: 1180))
    }

    func testBulletOutOfBoundsBottom() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: -600))
        bullet.position = CGPoint(x: 400, y: -30)
        XCTAssertTrue(bullet.isOutOfBounds(sceneHeight: 1180))
    }

    func testBulletInBounds() {
        let bullet = BulletNode(velocity: CGVector(dx: 0, dy: 600))
        bullet.position = CGPoint(x: 400, y: 500)
        XCTAssertFalse(bullet.isOutOfBounds(sceneHeight: 1180))
    }
}
