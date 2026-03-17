import SpriteKit
import UIKit

/// Displays HP and score for one player.
/// Position this node at the center of the player's short edge.
/// It is pre-rotated π/2 so text reads correctly when holding that short side.
class HUDNode: SKNode {

    private let nameLabel: SKLabelNode
    private let hpLabel: SKLabelNode
    private let scoreLabel: SKLabelNode

    /// Exposed for testing only.
    var hpText: String { hpLabel.text ?? "" }
    var scoreText: String { scoreLabel.text ?? "" }

    init(playerName: String) {
        nameLabel  = SKLabelNode(fontNamed: "Helvetica-Bold")
        hpLabel    = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel = SKLabelNode(fontNamed: "Helvetica")

        super.init()

        nameLabel.text = playerName
        nameLabel.fontSize = 14
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: 24)

        hpLabel.text = "HP: \(GameConstants.maxHP)"
        hpLabel.fontSize = 18
        hpLabel.fontColor = UIColor(red: 1, green: 0.5, blue: 0.5, alpha: 1)
        hpLabel.horizontalAlignmentMode = .center
        hpLabel.verticalAlignmentMode = .center
        hpLabel.position = CGPoint(x: 0, y: 0)

        scoreLabel.text = "SCORE: 0"
        scoreLabel.fontSize = 14
        scoreLabel.fontColor = UIColor.white.withAlphaComponent(0.7)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: -24)

        addChild(nameLabel)
        addChild(hpLabel)
        addChild(scoreLabel)

        // Rotate so text reads correctly from the short side.
        // Both Player 1 (scene space) and Player 2 (container local space) use π/2
        // because the container's π rotation handles the mirroring for Player 2.
        zRotation = CGFloat.pi / 2
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    /// Call whenever HP or score changes.
    func update(hp: Int, score: Int) {
        hpLabel.text    = "HP: \(hp)"
        scoreLabel.text = "SCORE: \(score)"
    }
}
