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
    private var joystickTouches: Set<ObjectIdentifier> = []

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
            x: 0,
            y: size.height / 2 - GameConstants.dividerWidth / 2,
            width: size.width,
            height: GameConstants.dividerWidth
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
        // Imperial — scene space, bottom half, facing up
        let imp = SpaceshipNode(imageName: "imperial_spaceship")
        imp.position = CGPoint(x: size.width / 2, y: size.height / 4)
        imp.zRotation = CGFloat.pi / 2
        imp.setupPhysics(category: PhysicsCategory.imperialShip,
                         contactTest: PhysicsCategory.rebelBullet)
        addChild(imp)
        imperialShip = imp

        // Rebel — player2Container local space, mirrors to top half, facing down in scene
        let reb = SpaceshipNode(imageName: "rebel_spaceship")
        reb.position = CGPoint(x: size.width / 2, y: size.height / 4)
        reb.zRotation = CGFloat.pi / 2
        reb.setupPhysics(category: PhysicsCategory.rebelShip,
                         contactTest: PhysicsCategory.imperialBullet)
        player2Container.addChild(reb)
        rebelShip = reb
    }

    private func setupControls() {
        let m = GameConstants.controlMargin
        let r = GameConstants.joystickRadius
        let fb = GameConstants.fireButtonSize / 2

        // --- Player 1 controls (bottom edge) ---

        // Joystick: bottom-left
        imperialJoystick = JoystickNode()
        imperialJoystick.position = CGPoint(x: m + r, y: m + r)
        addChild(imperialJoystick)

        // Fire button: bottom-right
        imperialFireButton = FireButtonNode()
        imperialFireButton.position = CGPoint(x: size.width - m - fb, y: m + fb)
        addChild(imperialFireButton)

        // HUD: bottom center
        imperialHUD = HUDNode(playerName: "IMPERIAL")
        imperialHUD.position = CGPoint(x: size.width / 2, y: m + 50)
        imperialHUD.zRotation = 0
        addChild(imperialHUD)

        // --- Player 2 controls (player2Container local space → mirrors to top edge) ---

        rebelJoystick = JoystickNode()
        rebelJoystick.position = CGPoint(x: m + r, y: m + r)
        player2Container.addChild(rebelJoystick)

        rebelFireButton = FireButtonNode()
        rebelFireButton.position = CGPoint(x: size.width - m - fb, y: m + fb)
        player2Container.addChild(rebelFireButton)

        rebelHUD = HUDNode(playerName: "REBEL")
        rebelHUD.position = CGPoint(x: size.width / 2, y: m + 50)
        rebelHUD.zRotation = 0
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
            // Spawn at ship's top (nose facing up). After π/2 rotation, "top" = original right side.
            let noseY = imp.position.y + imp.size.width / 2
            let bullet = BulletNode(velocity: CGVector(dx: 0, dy: GameConstants.bulletSpeed))
            bullet.position = CGPoint(x: imp.position.x, y: noseY)
            addChild(bullet)
            imperialBullets.append(bullet)

        case .rebel:
            // Rebel nose in local space (also π/2 rotation in local coords)
            let localNose = CGPoint(x: reb.position.x, y: reb.position.y + reb.size.width / 2)
            let sceneNose = convert(localNose, from: player2Container)
            // Rebel bullet travels DOWN in scene space (toward imperial)
            let bullet = BulletNode(velocity: CGVector(dx: 0, dy: -GameConstants.bulletSpeed))
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

        let halfHeight = size.height / 2
        // After π/2 rotation: screen width = sprite.size.height, screen height = sprite.size.width
        let impScreenW = imp.size.height / 2
        let impScreenH = imp.size.width / 2

        let impBounds = CGRect(
            x: impScreenW,
            y: impScreenH,
            width: size.width - impScreenW * 2,
            height: halfHeight - impScreenH - GameConstants.dividerWidth
        )
        imp.applyVelocity(imperialJoystick.velocityVector, deltaTime: dt, bounds: impBounds)

        let rebScreenW = reb.size.height / 2
        let rebScreenH = reb.size.width / 2
        let rebBounds = CGRect(
            x: rebScreenW,
            y: rebScreenH,
            width: size.width - rebScreenW * 2,
            height: halfHeight - rebScreenH - GameConstants.dividerWidth
        )
        reb.applyVelocity(rebelJoystick.velocityVector, deltaTime: dt, bounds: rebBounds)
    }

    private func updateBullets() {
        var aliveImperial: [BulletNode] = []
        for bullet in imperialBullets {
            if bullet.isOutOfBounds(sceneHeight: size.height) {
                bullet.removeFromParent()
            } else {
                aliveImperial.append(bullet)
            }
        }
        imperialBullets = aliveImperial

        var aliveRebel: [BulletNode] = []
        for bullet in rebelBullets {
            if bullet.isOutOfBounds(sceneHeight: size.height) {
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
            guard bullet?.parent != nil else { return }
            bullet?.removeFromParent()
            if let b = bullet { imperialBullets.removeAll { $0 === b } }
            rebelShip?.takeDamage()
            imperialShip?.addScore()
            run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
            checkGameOver()

        } else if (a.categoryBitMask == PhysicsCategory.rebelBullet &&
                   b.categoryBitMask == PhysicsCategory.imperialShip) ||
                  (b.categoryBitMask == PhysicsCategory.rebelBullet &&
                   a.categoryBitMask == PhysicsCategory.imperialShip) {

            let bullet = (a.categoryBitMask == PhysicsCategory.rebelBullet
                ? a.node : b.node) as? BulletNode
            guard bullet?.parent != nil else { return }
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

            if scenePoint.y < size.height / 2 {
                // Player 1 touch (bottom half)
                touchOwner[id] = .imperial
                if imperialJoystick.contains(scenePoint) {
                    imperialJoystick.setThumbOffset(CGVector(
                        dx: scenePoint.x - imperialJoystick.position.x,
                        dy: scenePoint.y - imperialJoystick.position.y))
                    joystickTouchStart[id] = scenePoint
                    joystickTouches.insert(id)
                } else if imperialFireButton.contains(scenePoint) {
                    spawnBullet(player: .imperial)
                }
            } else {
                // Player 2 touch (top half)
                touchOwner[id] = .rebel
                let localPoint = convert(scenePoint, to: player2Container)
                if rebelJoystick.contains(localPoint) {
                    rebelJoystick.setThumbOffset(CGVector(
                        dx: localPoint.x - rebelJoystick.position.x,
                        dy: localPoint.y - rebelJoystick.position.y))
                    joystickTouchStart[id] = localPoint
                    joystickTouches.insert(id)
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
            guard let owner = touchOwner[id], joystickTouches.contains(id) else { continue }
            let scenePoint = touch.location(in: self)

            switch owner {
            case .imperial:
                guard let startPos = joystickTouchStart[id] else { continue }
                imperialJoystick.setThumbOffset(CGVector(
                    dx: scenePoint.x - startPos.x,
                    dy: scenePoint.y - startPos.y))

            case .rebel:
                guard let startPos = joystickTouchStart[id] else { continue }
                let localPoint = convert(scenePoint, to: player2Container)
                rebelJoystick.setThumbOffset(CGVector(
                    dx: localPoint.x - startPos.x,
                    dy: localPoint.y - startPos.y))
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isGameOver {
            let tappedPlayAgain = touches.contains { touch in
                let point = touch.location(in: self)
                return self.nodes(at: point).contains { $0.name == "playAgain" }
            }
            if tappedPlayAgain {
                let newScene = GameScene(size: size)
                newScene.scaleMode = scaleMode
                view?.presentScene(newScene, transition: .fade(withDuration: 0.3))
                return
            }
        }

        for touch in touches {
            let id = ObjectIdentifier(touch)
            if joystickTouches.contains(id), let owner = touchOwner[id] {
                switch owner {
                case .imperial: imperialJoystick.reset()
                case .rebel:    rebelJoystick.reset()
                }
            }
            touchOwner.removeValue(forKey: id)
            joystickTouchStart.removeValue(forKey: id)
            joystickTouches.remove(id)
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
