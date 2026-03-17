import XCTest
import SpriteKit
@testable import StarWarsBattle

final class HUDNodeTests: XCTestCase {

    func testInitialHPLabel() {
        let hud = HUDNode(playerName: "IMPERIAL")
        XCTAssertTrue(hud.hpText.contains("10"), "HP label should show initial HP of 10")
    }

    func testInitialScoreLabel() {
        let hud = HUDNode(playerName: "IMPERIAL")
        XCTAssertTrue(hud.scoreText.contains("0"), "Score label should start at 0")
    }

    func testUpdateHP() {
        let hud = HUDNode(playerName: "IMPERIAL")
        hud.update(hp: 7, score: 0)
        XCTAssertTrue(hud.hpText.contains("7"))
    }

    func testUpdateScore() {
        let hud = HUDNode(playerName: "REBEL")
        hud.update(hp: 10, score: 5)
        XCTAssertTrue(hud.scoreText.contains("5"))
    }

    func testHUDRotatedForPlayer1() {
        let hud = HUDNode(playerName: "IMPERIAL")
        XCTAssertEqual(hud.zRotation, CGFloat.pi / 2, accuracy: 0.001)
    }
}
