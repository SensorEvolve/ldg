import XCTest
import SpriteKit
@testable import StarWarsBattle

final class JoystickNodeTests: XCTestCase {

    func testInitialVelocityIsZero() {
        let joystick = JoystickNode()
        let vel = joystick.velocityVector
        XCTAssertEqual(vel.dx, 0)
        XCTAssertEqual(vel.dy, 0)
    }

    func testDeadZoneReturnsZeroVelocity() {
        let joystick = JoystickNode()
        // Offset of 3pt — inside dead zone of 5pt
        joystick.setThumbOffset(CGVector(dx: 3, dy: 0))
        XCTAssertEqual(joystick.velocityVector.dx, 0)
        XCTAssertEqual(joystick.velocityVector.dy, 0)
    }

    func testPureRightVelocity() {
        let joystick = JoystickNode()
        joystick.setThumbOffset(CGVector(dx: 60, dy: 0))
        let vel = joystick.velocityVector
        XCTAssertEqual(vel.dx, GameConstants.shipSpeed, accuracy: 0.01)
        XCTAssertEqual(vel.dy, 0, accuracy: 0.01)
    }

    func testPureUpVelocity() {
        let joystick = JoystickNode()
        joystick.setThumbOffset(CGVector(dx: 0, dy: 60))
        let vel = joystick.velocityVector
        XCTAssertEqual(vel.dx, 0, accuracy: 0.01)
        XCTAssertEqual(vel.dy, GameConstants.shipSpeed, accuracy: 0.01)
    }

    func testDiagonalVelocityIsNormalized() {
        let joystick = JoystickNode()
        joystick.setThumbOffset(CGVector(dx: 60, dy: 60))
        let vel = joystick.velocityVector
        let magnitude = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
        XCTAssertEqual(magnitude, GameConstants.shipSpeed, accuracy: 0.1)
    }

    func testOffsetClampedToRadius() {
        let joystick = JoystickNode()
        // Push past radius
        joystick.setThumbOffset(CGVector(dx: 200, dy: 0))
        let vel = joystick.velocityVector
        // Velocity should still be exactly shipSpeed (not more)
        XCTAssertEqual(vel.dx, GameConstants.shipSpeed, accuracy: 0.01)
    }

    func testResetStopsVelocity() {
        let joystick = JoystickNode()
        joystick.setThumbOffset(CGVector(dx: 60, dy: 0))
        joystick.reset()
        XCTAssertEqual(joystick.velocityVector.dx, 0)
        XCTAssertEqual(joystick.velocityVector.dy, 0)
    }
}
