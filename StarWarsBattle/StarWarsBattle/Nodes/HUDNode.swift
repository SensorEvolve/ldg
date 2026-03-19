import SpriteKit
import UIKit

/// Displays HP (as a glowing color bar) and score for one player.
/// Position this node at the center of the player's HUD area.
class HUDNode: SKNode {

    // MARK: - Layout constants
    private let barMaxWidth: CGFloat = 120
    private let barHeight: CGFloat   = 10

    // MARK: - Nodes
    private let nameLabel: SKLabelNode
    private let scoreLabel: SKLabelNode
    private let healthBarBG: SKShapeNode
    private let healthBarFill: SKShapeNode

    // MARK: - State
    private var currentScore = 0

    // MARK: - Test accessors
    var scoreText: String { scoreLabel.text ?? "" }
    var hpText: String { "" }   // kept for API compatibility; bar-based now

    // MARK: - Init

    init(playerName: String) {
        nameLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        scoreLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        healthBarBG = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 120, height: 10),
                                  cornerRadius: 5)
        healthBarFill = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 120, height: 10),
                                    cornerRadius: 5)
        super.init()

        // Player tag — small, subtle
        nameLabel.text = playerName
        nameLabel.fontSize = 11
        nameLabel.fontColor = UIColor.white.withAlphaComponent(0.5)
        nameLabel.horizontalAlignmentMode = .center
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: 36)

        // Score — large, gold
        scoreLabel.text = "0"
        scoreLabel.fontSize = 48
        scoreLabel.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1)
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: 10)

        // Health bar background (dark)
        healthBarBG.fillColor = UIColor(white: 1, alpha: 0.15)
        healthBarBG.strokeColor = .clear
        healthBarBG.position = CGPoint(x: -barMaxWidth / 2, y: -26)

        // Health bar fill (green initially)
        healthBarFill.fillColor = UIColor(red: 0.27, green: 1.0, blue: 0.53, alpha: 1)
        healthBarFill.strokeColor = .clear
        healthBarFill.position = CGPoint(x: -barMaxWidth / 2, y: -26)

        addChild(healthBarBG)
        addChild(healthBarFill)
        addChild(nameLabel)
        addChild(scoreLabel)

        // Rotate so text reads correctly from the short side.
        zRotation = CGFloat.pi / 2
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Update

    func update(hp: Int, score: Int) {
        // --- Health bar ---
        let fraction = CGFloat(max(0, hp)) / CGFloat(GameConstants.maxHP)
        let newWidth = max(1, barMaxWidth * fraction)
        healthBarFill.path = UIBezierPath(
            roundedRect: CGRect(x: 0, y: 0, width: newWidth, height: barHeight),
            cornerRadius: 5
        ).cgPath

        switch hp {
        case let h where h > 6:
            healthBarFill.fillColor = UIColor(red: 0.27, green: 1.0,  blue: 0.53, alpha: 1) // green
        case let h where h >= 3:
            healthBarFill.fillColor = UIColor(red: 1.0,  green: 0.84, blue: 0.0,  alpha: 1) // gold
        default:
            healthBarFill.fillColor = UIColor(red: 1.0,  green: 0.2,  blue: 0.2,  alpha: 1) // red
        }

        // --- Score ---
        if score != currentScore {
            currentScore = score
            scoreLabel.text = "\(score)"
            popScoreAnimation()
        }
    }

    // MARK: - +1 pop animation

    private func popScoreAnimation() {
        let pop = SKLabelNode(fontNamed: "Helvetica-Bold")
        pop.text = "+1"
        pop.fontSize = 20
        pop.fontColor = UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1)
        pop.horizontalAlignmentMode = .center
        pop.verticalAlignmentMode = .center
        pop.position = CGPoint(x: 0, y: 10)
        pop.zPosition = 5
        addChild(pop)

        let rise = SKAction.moveBy(x: 0, y: 40, duration: 0.5)
        let fade = SKAction.fadeOut(withDuration: 0.5)
        let group = SKAction.group([rise, fade])
        pop.run(SKAction.sequence([group, .removeFromParent()]))
    }
}
