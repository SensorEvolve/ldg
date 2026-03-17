import XCTest
import SpriteKit
@testable import StarWarsBattle

final class BulletNodeTests: XCTestCase {

    func testImperialBulletIsRed() {
        let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
        XCTAssertEqual(bullet.color, UIColor.red)
    }

    func testRebelBulletIsBlue() {
        let bullet = BulletNode(velocity: CGVector(dx: -600, dy: 0))
        // Check that it's the blue color by verifying it's not red
        XCTAssertNotEqual(bullet.color, UIColor.red)
        // Verify RGBA components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        bullet.color.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 0.3, accuracy: 0.01)
        XCTAssertEqual(g, 0.5, accuracy: 0.01)
        XCTAssertEqual(b, 1.0, accuracy: 0.01)
        XCTAssertEqual(a, 1.0, accuracy: 0.01)
    }

    func testBulletSize() {
        let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
        XCTAssertEqual(bullet.size, CGSize(width: 15, height: 5))
    }

    func testImperialBulletPhysicsCategory() {
        let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
        XCTAssertEqual(bullet.physicsBody?.categoryBitMask, PhysicsCategory.imperialBullet)
        XCTAssertEqual(bullet.physicsBody?.contactTestBitMask, PhysicsCategory.rebelShip)
        XCTAssertEqual(bullet.physicsBody?.collisionBitMask, 0)
    }

    func testRebelBulletPhysicsCategory() {
        let bullet = BulletNode(velocity: CGVector(dx: -600, dy: 0))
        XCTAssertEqual(bullet.physicsBody?.categoryBitMask, PhysicsCategory.rebelBullet)
        XCTAssertEqual(bullet.physicsBody?.contactTestBitMask, PhysicsCategory.imperialShip)
        XCTAssertEqual(bullet.physicsBody?.collisionBitMask, 0)
    }

    func testBulletVelocityStored() {
        let vel = CGVector(dx: 600, dy: 0)
        let bullet = BulletNode(velocity: vel)
        XCTAssertEqual(bullet.bulletVelocity.dx, vel.dx)
        XCTAssertEqual(bullet.bulletVelocity.dy, vel.dy)
    }

    func testImperialBulletPhysicsVelocitySet() {
        let vel = CGVector(dx: 600, dy: 0)
        let bullet = BulletNode(velocity: vel)
        if let body = bullet.physicsBody {
            XCTAssertEqual(body.velocity.dx, vel.dx, accuracy: 0.01)
            XCTAssertEqual(body.velocity.dy, vel.dy, accuracy: 0.01)
        } else {
            XCTFail("physicsBody should not be nil")
        }
    }

    func testBulletIsDynamicForContactCallbacks() {
        let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
        XCTAssertTrue(bullet.physicsBody?.isDynamic == true,
                      "Bullets must be dynamic so SKPhysics contact callbacks fire against static ships")
    }

    func testBulletOutOfBoundsRight() {
        let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
        bullet.position = CGPoint(x: 1201, y: 200)  // > sceneWidth(1180) + 20
        XCTAssertTrue(bullet.isOutOfBounds(sceneWidth: 1180))
    }

    func testBulletOutOfBoundsLeft() {
        let bullet = BulletNode(velocity: CGVector(dx: -600, dy: 0))
        bullet.position = CGPoint(x: -30, y: 200)
        XCTAssertTrue(bullet.isOutOfBounds(sceneWidth: 1180))
    }

    func testBulletInBounds() {
        let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
        bullet.position = CGPoint(x: 500, y: 200)
        XCTAssertFalse(bullet.isOutOfBounds(sceneWidth: 1180))
    }
}
