import XCTest
import SpriteKit
@testable import StarWarsBattle

final class MenuSceneTests: XCTestCase {

    var scene: MenuScene!

    override func setUp() {
        super.setUp()
        scene = MenuScene(size: CGSize(width: 1180, height: 820))
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 1180, height: 820))
        view.presentScene(scene)
    }

    func testSceneHasTitleLabel() {
        let label = scene.childNode(withName: "//titleLabel")
        XCTAssertNotNil(label, "MenuScene must have a title label")
    }

    func testSceneHasPlayButton() {
        let btn = scene.childNode(withName: "//playButton")
        XCTAssertNotNil(btn, "MenuScene must have a play button")
    }

    func testSceneHasBackground() {
        let bg = scene.childNode(withName: "//menuBackground")
        XCTAssertNotNil(bg, "MenuScene must have a background node")
    }
}
