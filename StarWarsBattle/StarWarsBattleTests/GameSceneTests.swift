import XCTest
import SpriteKit
@testable import StarWarsBattle

final class GameSceneTests: XCTestCase {

    var scene: GameScene!

    override func setUp() {
        super.setUp()
        scene = GameScene(size: CGSize(width: 820, height: 1180))
        scene.scaleMode = .resizeFill
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 820, height: 1180))
        view.presentScene(scene)
    }

    func testSceneHasImperialShip() {
        XCTAssertNotNil(scene.imperialShip)
    }

    func testSceneHasRebelShip() {
        XCTAssertNotNil(scene.rebelShip)
    }

    func testImperialShipStartsInBottomHalf() {
        let ship = scene.imperialShip!
        XCTAssertLessThan(ship.position.y, scene.size.height / 2,
                          "Imperial ship must start in the bottom half")
    }

    func testRebelShipStartsInTopHalfInSceneSpace() {
        let ship = scene.rebelShip!
        let scenePos = scene.convert(ship.position, from: ship.parent!)
        XCTAssertGreaterThanOrEqual(scenePos.y, scene.size.height / 2,
                                    "Rebel ship must start in the top half (scene space)")
    }

    func testGameIsNotOverAtStart() {
        XCTAssertFalse(scene.isGameOver)
    }

    func testImperialBulletCountStartsAtZero() {
        XCTAssertEqual(scene.imperialBullets.count, 0)
    }

    func testRebelBulletCountStartsAtZero() {
        XCTAssertEqual(scene.rebelBullets.count, 0)
    }

    func testCanFireImperialWhenUnderMax() {
        XCTAssertTrue(scene.canFire(player: .imperial))
    }

    func testCannotFireWhenAtMax() {
        for _ in 0..<GameConstants.maxBullets {
            scene.spawnBullet(player: .imperial)
        }
        XCTAssertFalse(scene.canFire(player: .imperial))
    }

    func testGameOverWhenImperialHPZero() {
        for _ in 0..<GameConstants.maxHP {
            scene.imperialShip!.takeDamage()
        }
        scene.checkGameOver()
        XCTAssertTrue(scene.isGameOver)
    }

    func testWinnerIsRebelWhenImperialDies() {
        for _ in 0..<GameConstants.maxHP { scene.imperialShip!.takeDamage() }
        scene.checkGameOver()
        XCTAssertEqual(scene.winner, "Rebel Wins!")
    }

    func testWinnerIsImperialWhenRebelDies() {
        for _ in 0..<GameConstants.maxHP { scene.rebelShip!.takeDamage() }
        scene.checkGameOver()
        XCTAssertEqual(scene.winner, "Imperial Wins!")
    }
}
