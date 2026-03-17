import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        setupBackground()
        setupPlayButton()
    }

    private func setupBackground() {
        let bg = SKSpriteNode(imageNamed: "bg_version_2")
        bg.name = "menuBackground"
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.size = size
        bg.zPosition = -1
        addChild(bg)
    }

    private func setupTitle() {
        let title = SKLabelNode(fontNamed: "Helvetica-Bold")
        title.name = "titleLabel"
        title.text = "STAR WARS BATTLE"
        title.fontSize = 56
        title.fontColor = .yellow
        title.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        title.zPosition = 1
        addChild(title)
    }

    private func setupPlayButton() {
        let container = SKNode()
        container.name = "playButton"
        container.position = CGPoint(x: size.width / 2, y: size.height / 2)
        container.zPosition = 1

        let bg = SKShapeNode(rect: CGRect(x: -100, y: -28, width: 200, height: 56),
                             cornerRadius: 12)
        bg.fillColor = UIColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 0.85)
        bg.strokeColor = UIColor.white.withAlphaComponent(0.4)
        bg.lineWidth = 2

        let label = SKLabelNode(fontNamed: "Helvetica-Bold")
        label.text = "PLAY"
        label.fontSize = 36
        label.fontColor = .white
        label.verticalAlignmentMode = .center

        container.addChild(bg)
        container.addChild(label)
        addChild(container)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        let tappedNodes = nodes(at: point)
        if tappedNodes.contains(where: { $0.name == "playButton" || $0.parent?.name == "playButton" }) {
            let game = GameScene(size: size)
            game.scaleMode = scaleMode
            view?.presentScene(game, transition: .fade(withDuration: 0.4))
        }
    }
}
