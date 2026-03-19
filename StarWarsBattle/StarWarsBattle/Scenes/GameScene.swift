import SpriteKit
import UIKit
import AVFoundation

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
    private var imperialFireTouches: Set<ObjectIdentifier> = []
    private var rebelFireTouches: Set<ObjectIdentifier> = []

    // MARK: - Fire hold state
    private var imperialFireHeld = false
    private var rebelFireHeld = false
    private var imperialFireCooldown: TimeInterval = 0
    private var rebelFireCooldown: TimeInterval = 0

    // MARK: - Audio
    private var laserAction: SKAction!
    private var explosionAction: SKAction!
    private var victoryPlayer: AVAudioPlayer?

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
        preloadSounds()
    }

    // MARK: - Audio setup

    private func preloadSounds() {
        laserAction = SKAction.playSoundFileNamed("laser.caf", waitForCompletion: false)
        explosionAction = SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false)
    }

    private func playVictoryMusic() {
        guard let url = Bundle.main.url(forResource: "victory", withExtension: "mp3") else { return }
        victoryPlayer = try? AVAudioPlayer(contentsOf: url)
        victoryPlayer?.play()
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
        // Imperial — scene space, bottom half
        // zRotation π = 90° left from previous up (π/2), now faces left
        let imp = SpaceshipNode(imageName: "imperial_spaceship")
        imp.size = CGSize(width: imp.size.width * 0.5, height: imp.size.height * 0.5)
        imp.position = CGPoint(x: size.width / 2, y: size.height / 4)
        imp.zRotation = CGFloat.pi
        imp.setupPhysics(category: PhysicsCategory.imperialShip,
                         contactTest: PhysicsCategory.rebelBullet)
        addChild(imp)
        imperialShip = imp

        // Rebel — player2Container local space, mirrors to top half
        // local zRotation 0 = 90° right from previous up (π/2); scene = container π + 0 = π (faces left)
        let reb = SpaceshipNode(imageName: "rebel_spaceship")
        reb.size = CGSize(width: reb.size.width * 0.5, height: reb.size.height * 0.5)
        reb.position = CGPoint(x: size.width / 2, y: size.height / 4)
        reb.zRotation = 0
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
            // At π rotation dimensions are unchanged; top of ship = position.y + size.height/2
            let noseY = imp.position.y + imp.size.height / 2
            let bullet = BulletNode(velocity: CGVector(dx: 0, dy: GameConstants.bulletSpeed))
            bullet.position = CGPoint(x: imp.position.x, y: noseY)
            addChild(bullet)
            imperialBullets.append(bullet)

        case .rebel:
            // Rebel local zRotation 0 — top of ship in local space = position.y + size.height/2
            let localNose = CGPoint(x: reb.position.x, y: reb.position.y + reb.size.height / 2)
            let sceneNose = convert(localNose, from: player2Container)
            // Rebel bullet travels DOWN in scene space (toward imperial)
            let bullet = BulletNode(velocity: CGVector(dx: 0, dy: -GameConstants.bulletSpeed))
            bullet.position = sceneNose
            addChild(bullet)
            rebelBullets.append(bullet)
        }

        run(laserAction)
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
        updateFireHold(dt: TimeInterval(dt))
    }

    private func updateShipMovement(dt: CGFloat) {
        guard let imp = imperialShip, let reb = rebelShip else { return }

        let halfHeight = size.height / 2
        // At π rotation dimensions are unchanged (no axis swap unlike π/2)
        let impScreenW = imp.size.width / 2
        let impScreenH = imp.size.height / 2

        let impBounds = CGRect(
            x: impScreenW,
            y: impScreenH,
            width: size.width - impScreenW * 2,
            height: halfHeight - impScreenH - GameConstants.dividerWidth
        )
        imp.applyVelocity(imperialJoystick.velocityVector, deltaTime: dt, bounds: impBounds)

        let rebScreenW = reb.size.width / 2
        let rebScreenH = reb.size.height / 2
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

    private func updateFireHold(dt: TimeInterval) {
        if imperialFireHeld {
            imperialFireCooldown -= dt
            if imperialFireCooldown <= 0 {
                spawnBullet(player: .imperial)
                imperialFireCooldown = GameConstants.fireRepeatInterval
            }
        }
        if rebelFireHeld {
            rebelFireCooldown -= dt
            if rebelFireCooldown <= 0 {
                spawnBullet(player: .rebel)
                rebelFireCooldown = GameConstants.fireRepeatInterval
            }
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
            run(explosionAction)
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
            run(explosionAction)
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
                    imperialFireTouches.insert(id)
                    imperialFireHeld = true
                    imperialFireCooldown = 0
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
                    rebelFireTouches.insert(id)
                    rebelFireHeld = true
                    rebelFireCooldown = 0
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
                victoryPlayer?.stop()
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
            if imperialFireTouches.contains(id) {
                imperialFireTouches.remove(id)
                if imperialFireTouches.isEmpty { imperialFireHeld = false }
            }
            if rebelFireTouches.contains(id) {
                rebelFireTouches.remove(id)
                if rebelFireTouches.isEmpty { rebelFireHeld = false }
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
        playVictoryMusic()

        let cx = size.width / 2
        let cy = size.height / 2

        // --- Dark overlay ---
        let overlay = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        overlay.fillColor = UIColor(red: 0.03, green: 0.03, blue: 0.07, alpha: 0.88)
        overlay.strokeColor = .clear
        overlay.zPosition = 10
        addChild(overlay)

        // --- Blue radial glow behind title ---
        let glowSize = CGSize(width: size.width * 0.9, height: size.height * 0.4)
        let glow = SKShapeNode(ellipseOf: glowSize)
        glow.fillColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 0.12)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: cx, y: cy + 60)
        glow.zPosition = 11
        addChild(glow)

        // --- Scattered stars ---
        let starPositions: [(CGFloat, CGFloat)] = [
            (0.08, 0.82), (0.18, 0.55), (0.28, 0.90), (0.42, 0.68),
            (0.55, 0.78), (0.67, 0.92), (0.75, 0.60), (0.85, 0.85),
            (0.92, 0.72), (0.12, 0.38), (0.35, 0.25), (0.60, 0.30),
            (0.80, 0.42), (0.48, 0.15), (0.22, 0.12)
        ]
        for (fx, fy) in starPositions {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.8...1.5))
            star.fillColor = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.2...0.5))
            star.strokeColor = .clear
            star.position = CGPoint(x: size.width * fx, y: size.height * fy)
            star.zPosition = 11
            addChild(star)
        }

        // --- "— VICTORY —" eyebrow label ---
        let eyebrow = SKLabelNode(fontNamed: "Helvetica")
        eyebrow.text = "— VICTORY —"
        eyebrow.fontSize = 14
        eyebrow.fontColor = UIColor.white.withAlphaComponent(0.3)
        eyebrow.horizontalAlignmentMode = .center
        eyebrow.position = CGPoint(x: cx, y: cy + 130)
        eyebrow.zPosition = 12
        addChild(eyebrow)

        // --- "GAME OVER" title ---
        let goLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        goLabel.text = "GAME OVER"
        goLabel.fontSize = 64
        goLabel.fontColor = .white
        goLabel.horizontalAlignmentMode = .center
        goLabel.position = CGPoint(x: cx, y: cy + 40)
        goLabel.zPosition = 12
        // Blue glow via a blurred duplicate underneath
        let goGlow = goLabel.copy() as! SKLabelNode
        goGlow.fontColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 0.55)
        goGlow.zPosition = 11
        goGlow.xScale = 1.04; goGlow.yScale = 1.04
        addChild(goGlow)
        addChild(goLabel)

        // --- Winner label ---
        let winLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        winLabel.text = winner ?? ""
        winLabel.fontSize = 26
        winLabel.fontColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1)
        winLabel.horizontalAlignmentMode = .center
        winLabel.position = CGPoint(x: cx, y: cy - 12)
        winLabel.zPosition = 12
        // Gold glow duplicate
        let winGlow = winLabel.copy() as! SKLabelNode
        winGlow.fontColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.35)
        winGlow.zPosition = 11
        winGlow.xScale = 1.05; winGlow.yScale = 1.05
        addChild(winGlow)
        addChild(winLabel)

        // --- Thin divider ---
        let divPath = CGMutablePath()
        divPath.move(to: CGPoint(x: cx - 50, y: cy - 44))
        divPath.addLine(to: CGPoint(x: cx + 50, y: cy - 44))
        let divider = SKShapeNode(path: divPath)
        divider.strokeColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 0.5)
        divider.lineWidth = 1
        divider.zPosition = 12
        addChild(divider)

        // --- Play Again button ---
        let btnW: CGFloat = 220
        let btnH: CGFloat = 52
        let btnY = cy - 110

        let btnBG = SKShapeNode(rect: CGRect(x: -btnW/2, y: -btnH/2, width: btnW, height: btnH),
                                cornerRadius: 7)
        btnBG.fillColor = UIColor(red: 0.10, green: 0.23, blue: 0.43, alpha: 1)
        btnBG.strokeColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 0.55)
        btnBG.lineWidth = 1
        btnBG.position = CGPoint(x: cx, y: btnY)
        btnBG.zPosition = 12
        btnBG.name = "playAgain"
        addChild(btnBG)

        let btnLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        btnLabel.text = "▶  PLAY AGAIN"
        btnLabel.fontSize = 16
        btnLabel.fontColor = .white
        btnLabel.horizontalAlignmentMode = .center
        btnLabel.verticalAlignmentMode = .center
        btnLabel.position = CGPoint(x: cx, y: btnY)
        btnLabel.zPosition = 13
        btnLabel.name = "playAgain"
        addChild(btnLabel)

        // Pulsing blue outer glow on button
        let glowBtn = SKShapeNode(rect: CGRect(x: -btnW/2 - 6, y: -btnH/2 - 6,
                                               width: btnW + 12, height: btnH + 12),
                                  cornerRadius: 10)
        glowBtn.fillColor = .clear
        glowBtn.strokeColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 0)
        glowBtn.lineWidth = 6
        glowBtn.position = CGPoint(x: cx, y: btnY)
        glowBtn.zPosition = 11
        addChild(glowBtn)

        let brighten = SKAction.customAction(withDuration: 1.0) { node, t in
            let alpha = 0.12 + 0.28 * sin(Float(t) * .pi)
            (node as? SKShapeNode)?.strokeColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: CGFloat(alpha))
        }
        let dim = SKAction.customAction(withDuration: 1.0) { node, t in
            let alpha = 0.40 - 0.28 * sin(Float(t) * .pi)
            (node as? SKShapeNode)?.strokeColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: CGFloat(alpha))
        }
        glowBtn.run(SKAction.repeatForever(SKAction.sequence([brighten, dim])))
    }
}
