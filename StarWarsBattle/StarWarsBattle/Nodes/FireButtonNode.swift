import SpriteKit
import UIKit

class FireButtonNode: SKNode {

    static let touchRadius: CGFloat = GameConstants.fireButtonSize / 2

    private let circle: SKShapeNode

    override init() {
        circle = SKShapeNode(circleOfRadius: FireButtonNode.touchRadius)
        circle.fillColor = UIColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 0.65)
        circle.strokeColor = UIColor.red.withAlphaComponent(0.6)
        circle.lineWidth = 2

        // Lightning bolt label
        let label = SKLabelNode(text: "⚡")
        label.fontSize = 22
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        super.init()
        addChild(circle)
        circle.addChild(label)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    /// Returns true if a point (in this node's parent coordinate space) is within the tap area.
    override func contains(_ point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        return sqrt(dx * dx + dy * dy) <= FireButtonNode.touchRadius
    }
}
