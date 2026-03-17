import SpriteKit
import UIKit

enum Player { case imperial, rebel }

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Public state (exposed for testing)
    private(set) var imperialShip: SpaceshipNode?
    private(set) var rebelShip: SpaceshipNode?
    private(set) var imperialBullets: [BulletNode] = []
    private(set) var rebelBullets: [BulletNode] = []
    private(set) var isGameOver = false
    private(set) var winner: String?

    // MARK: - Private nodes
    private var player2Container: SKNode!
    private var imperialJoystick: JoystickNode!
    private var rebelJoystick: JoystickNode!
    private var imperialFireButton: FireButtonNode!
    private var rebelFireButton: FireButtonNode!
    private var imperialHUD: HUDNode!
    private var rebelHUD: HUDNode!

    // MARK: - Touch tracking
    private var touchOwner: [ObjectIdentifier: Player] = [:]
    private var joystickTouchStart: [ObjectIdentifier: CGPoint] = [:]

    // MARK: - Time
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self

        setupBackground()
        setupDivider()
        setupPlayer2Container()
        setupShips()
        setupControls()
    }

    // MARK: - Setup helpers

    private func setupBackground() {
        let bg = SKSpriteNode(imageNamed: "bg_version_2")
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.size = size
        bg.zPosition = -1
        addChild(bg)
    }

    private func setupDivider() {
        let divider = SKShapeNode(rect: CGRect(
            x: size.width / 2 - GameConstants.dividerWidth / 2,
            y: 0,
            width: GameConstants.dividerWidth,
            height: size.height
        ))
        divider.fillColor = .white
        divider.strokeColor = .clear
        divider.alpha = 0.3
        addChild(divider)
    }

    private func setupPlayer2Container() {
        player2Container = SKNode()
        player2Container.position = CGPoint(x: size.width, y: size.height)
        player2Container.zRotation = .pi
        addChild(player2Container)
    }

    private func setupShips() {
        // Imperial — scene space
        let imp = SpaceshipNode(imageName: "imperial_spaceship")
        imp.position = CGPoint(x: 100, y: size.height / 2)
        imp.setupPhysics(category: PhysicsCategory.imperialShip,
                         contactTest: PhysicsCategory.rebelBullet)
        addChild(imp)
        imperialShip = imp

        // Rebel — player2Container local space
        let reb = SpaceshipNode(imageName: "rebel_spaceship")
        reb.position = CGPoint(x: 100, y: size.height / 2)
        reb.setupPhysics(category: PhysicsCategory.rebelShip,
                         contactTest: PhysicsCategory.imperialBullet)
        player2Container.addChild(reb)
        rebelShip = reb
    }

    private func setupControls() {
        let m = GameConstants.controlMargin
        let r = GameConstants.joystickRadius
        let fb = GameConstants.fireButtonSize / 2

        // --- Player 1 controls (scene space, left short side) ---
        imperialJoystick = JoystickNode()
        imperialJoystick.position = CGPoint(x: m + r, y: m + r)
        addChild(imperialJoystick)

        imperialFireButton = FireButtonNode()
        imperialFireButton.position = CGPoint(x: m + fb, y: size.height - m - fb)
        addChild(imperialFireButton)

        imperialHUD = HUDNode(playerName: "IMPERIAL")
        imperialHUD.position = CGPoint(x: m, y: size.height / 2)
        addChild(imperialHUD)

        // --- Player 2 controls (player2Container local space, mirrors Player 1) ---
        rebelJoystick = JoystickNode()
        rebelJoystick.position = CGPoint(x: m + r, y: m + r)
        player2Container.addChild(rebelJoystick)

        rebelFireButton = FireButtonNode()
        rebelFireButton.position = CGPoint(x: m + fb, y: size.height - m - fb)
        player2Container.addChild(rebelFireButton)

        rebelHUD = HUDNode(playerName: "REBEL")
        rebelHUD.position = CGPoint(x: m, y: size.height / 2)
        player2Container.addChild(rebelHUD)
    }

    // MARK: - Game logic (exposed for testing)

    func canFire(player: Player) -> Bool {
        switch player {
        case .imperial: return imperialBullets.count < GameConstants.maxBullets
        case .rebel:    return rebelBullets.count < GameConstants.maxBullets
        }
    }

    func spawnBullet(player: Player) {
        guard canFire(player: player) else { return }
        guard let imp = imperialShip, let reb = rebelShip else { return }

        switch player {
        case .imperial:
            let noseX = imp.position.x + imp.size.width / 2
            let bullet = BulletNode(velocity: CGVector(dx: GameConstants.bulletSpeed, dy: 0))
            bullet.position = CGPoint(x: noseX, y: imp.position.y)
            addChild(bullet)
            imperialBullets.append(bullet)

        case .rebel:
            let localNose = CGPoint(x: reb.position.x + reb.size.width / 2, y: reb.position.y)
            let sceneNose = convert(localNose, from: player2Container)
            // Rebel bullets travel LEFT in scene space (toward Imperial ship)
            let bullet = BulletNode(velocity: CGVector(dx: -GameConstants.bulletSpeed, dy: 0))
            bullet.position = sceneNose
            addChild(bullet)
            rebelBullets.append(bullet)
        }

        run(SKAction.playSoundFileNamed("laser.mp3", waitForCompletion: false))
    }

    func checkGameOver() {
        guard !isGameOver else { return }
        if imperialShip?.isDead == true {
            isGameOver = true
            winner = "Rebel Wins!"
            showGameOverOverlay()
        } else if rebelShip?.isDead == true {
            isGameOver = true
            winner = "Imperial Wins!"
            showGameOverOverlay()
        }
    }

    // MARK: - Update loop

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }
        let dt = lastUpdateTime == 0 ? 0 : CGFloat(min(currentTime - lastUpdateTime, 1.0 / 30.0))
        lastUpdateTime = currentTime

        updateShipMovement(dt: dt)
        updateBullets()
        updateHUDs()
    }

    private func updateShipMovement(dt: CGFloat) {
        guard let imp = imperialShip, let reb = rebelShip else { return }

        let halfWidth = size.width / 2
        let shipHalfW = imp.size.width / 2
        let shipHalfH = imp.size.height / 2

        let impBounds = CGRect(
            x: shipHalfW,
            y: shipHalfH,
            width: halfWidth - shipHalfW - GameConstants.dividerWidth,
            height: size.height - shipHalfH * 2
        )
        imp.applyVelocity(imperialJoystick.velocityVector, deltaTime: dt, bounds: impBounds)

        let rebHalfW = reb.size.width / 2
        let rebHalfH = reb.size.height / 2
        let rebBounds = CGRect(
            x: rebHalfW,
            y: rebHalfH,
            width: halfWidth - rebHalfW - GameConstants.dividerWidth,
            height: size.height - rebHalfH * 2
        )
        reb.applyVelocity(rebelJoystick.velocityVector, deltaTime: dt, bounds: rebBounds)
    }

    private func updateBullets() {
        var aliveImperial: [BulletNode] = []
        for bullet in imperialBullets {
            if bullet.isOutOfBounds(sceneWidth: size.width) {
                bullet.removeFromParent()
            } else {
                aliveImperial.append(bullet)
            }
        }
        imperialBullets = aliveImperial

        var aliveRebel: [BulletNode] = []
        for bullet in rebelBullets {
            if bullet.isOutOfBounds(sceneWidth: size.width) {
                bullet.removeFromParent()
            } else {
                aliveRebel.append(bullet)
            }
        }
        rebelBullets = aliveRebel
    }

    private func updateHUDs() {
        if let imp = imperialShip {
            imperialHUD.update(hp: imp.hp, score: imp.score)
        }
        if let reb = rebelShip {
            rebelHUD.update(hp: reb.hp, score: reb.score)
        }
    }

    // MARK: - Physics contact

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        if (a.categoryBitMask == PhysicsCategory.imperialBullet &&
            b.categoryBitMask == PhysicsCategory.rebelShip) ||
           (b.categoryBitMask == PhysicsCategory.imperialBullet &&
            a.categoryBitMask == PhysicsCategory.rebelShip) {

            let bullet = (a.categoryBitMask == PhysicsCategory.imperialBullet
                ? a.node : b.node) as? BulletNode
            bullet?.removeFromParent()
            if let b = bullet { imperialBullets.removeAll { $0 === b } }
            rebelShip?.takeDamage()
            imperialShip?.addScore()
            run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
            checkGameOver()
        }

        if (a.categoryBitMask == PhysicsCategory.rebelBullet &&
            b.categoryBitMask == PhysicsCategory.imperialShip) ||
           (b.categoryBitMask == PhysicsCategory.rebelBullet &&
            a.categoryBitMask == PhysicsCategory.imperialShip) {

            let bullet = (a.categoryBitMask == PhysicsCategory.rebelBullet
                ? a.node : b.node) as? BulletNode
            bullet?.removeFromParent()
            if let b = bullet { rebelBullets.removeAll { $0 === b } }
            imperialShip?.takeDamage()
            rebelShip?.addScore()
            run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
            checkGameOver()
        }
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        for touch in touches {
            let scenePoint = touch.location(in: self)
            let id = ObjectIdentifier(touch)

            if scenePoint.x < size.width / 2 {
                touchOwner[id] = .imperial
                if imperialJoystick.contains(scenePoint) {
                    let localPoint = CGPoint(x: scenePoint.x - imperialJoystick.position.x,
                                            y: scenePoint.y - imperialJoystick.position.y)
                    imperialJoystick.setThumbOffset(CGVector(dx: localPoint.x, dy: localPoint.y))
                    joystickTouchStart[id] = imperialJoystick.position
                } else if imperialFireButton.contains(scenePoint) {
                    spawnBullet(player: .imperial)
                }
            } else {
                touchOwner[id] = .rebel
                let localPoint = convert(scenePoint, to: player2Container)
                if rebelJoystick.contains(localPoint) {
                    let offset = CGPoint(x: localPoint.x - rebelJoystick.position.x,
                                        y: localPoint.y - rebelJoystick.position.y)
                    rebelJoystick.setThumbOffset(CGVector(dx: offset.x, dy: offset.y))
                    joystickTouchStart[id] = rebelJoystick.position
                } else if rebelFireButton.contains(localPoint) {
                    spawnBullet(player: .rebel)
                }
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isGameOver else { return }
        for touch in touches {
            let id = ObjectIdentifier(touch)
            guard let owner = touchOwner[id] else { continue }
            let scenePoint = touch.location(in: self)

            switch owner {
            case .imperial:
                guard let startPos = joystickTouchStart[id] else { continue }
                let offset = CGVector(dx: scenePoint.x - startPos.x,
                                     dy: scenePoint.y - startPos.y)
                imperialJoystick.setThumbOffset(offset)

            case .rebel:
                guard let startPos = joystickTouchStart[id] else { continue }
                let localPoint = convert(scenePoint, to: player2Container)
                let offset = CGVector(dx: localPoint.x - startPos.x,
                                     dy: localPoint.y - startPos.y)
                rebelJoystick.setThumbOffset(offset)
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            for touch in touches {
                let point = touch.location(in: self)
                let nodes = self.nodes(at: point)
                if nodes.contains(where: { $0.name == "playAgain" }) {
                    let newScene = GameScene(size: size)
                    newScene.scaleMode = scaleMode
                    view?.presentScene(newScene, transition: .fade(withDuration: 0.3))
                    return
                }
            }
        }

        for touch in touches {
            let id = ObjectIdentifier(touch)
            if let owner = touchOwner[id] {
                switch owner {
                case .imperial: imperialJoystick.reset()
                case .rebel:    rebelJoystick.reset()
                }
            }
            touchOwner.removeValue(forKey: id)
            joystickTouchStart.removeValue(forKey: id)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Game over overlay

    private func showGameOverOverlay() {
        let overlay = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        overlay.fillColor = UIColor.black.withAlphaComponent(0.75)
        overlay.strokeColor = .clear
        overlay.zPosition = 10
        addChild(overlay)

        let goLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        goLabel.text = "GAME OVER"
        goLabel.fontSize = 72
        goLabel.fontColor = .white
        goLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        goLabel.zPosition = 11
        addChild(goLabel)

        let winLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        winLabel.text = winner ?? ""
        winLabel.fontSize = 48
        winLabel.fontColor = .yellow
        winLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 10)
        winLabel.zPosition = 11
        addChild(winLabel)

        let playAgainLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        playAgainLabel.text = "PLAY AGAIN"
        playAgainLabel.fontSize = 32
        playAgainLabel.fontColor = .white
        playAgainLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 90)
        playAgainLabel.zPosition = 11
        playAgainLabel.name = "playAgain"

        let btnBG = SKShapeNode(rect: CGRect(x: -120, y: -22, width: 240, height: 50),
                                cornerRadius: 10)
        btnBG.fillColor = UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 0.8)
        btnBG.strokeColor = .clear
        btnBG.zPosition = 10
        btnBG.name = "playAgain"
        playAgainLabel.addChild(btnBG)
        addChild(playAgainLabel)
    }
}
