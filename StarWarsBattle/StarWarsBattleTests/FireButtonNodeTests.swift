import XCTest
import SpriteKit
@testable import StarWarsBattle

final class FireButtonNodeTests: XCTestCase {

    func testContainsPointInsideTouchArea() {
        let btn = FireButtonNode()
        btn.position = CGPoint(x: 50, y: 50)
        // A point 30pt from center — inside 40pt radius
        XCTAssertTrue(btn.contains(CGPoint(x: 75, y: 50)))
    }

    func testDoesNotContainPointOutsideTouchArea() {
        let btn = FireButtonNode()
        btn.position = CGPoint(x: 50, y: 50)
        // A point 50pt from center — outside 40pt radius
        XCTAssertFalse(btn.contains(CGPoint(x: 105, y: 50)))
    }

    func testTouchRadiusIsHalfFireButtonSize() {
        // Touch radius = fireButtonSize / 2 = 40pt
        XCTAssertEqual(FireButtonNode.touchRadius, GameConstants.fireButtonSize / 2)
    }
}
