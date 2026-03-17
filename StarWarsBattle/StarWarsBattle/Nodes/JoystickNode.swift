import SpriteKit
import UIKit

class JoystickNode: SKNode {

    // MARK: - Visuals
    private let baseRing: SKShapeNode
    private let thumb: SKShapeNode

    // MARK: - State
    private var thumbOffset: CGVector = .zero

    /// Velocity vector in the joystick's parent coordinate space (pts/sec).
    var velocityVector: CGVector {
        let len = sqrt(thumbOffset.dx * thumbOffset.dx + thumbOffset.dy * thumbOffset.dy)
        guard len > GameConstants.joystickDeadZone else { return .zero }
        let nx = thumbOffset.dx / len
        let ny = thumbOffset.dy / len
        return CGVector(dx: nx * GameConstants.shipSpeed, dy: ny * GameConstants.shipSpeed)
    }

    // MARK: - Init

    override init() {
        let r = GameConstants.joystickRadius
        baseRing = SKShapeNode(circleOfRadius: r)
        baseRing.strokeColor = UIColor.white.withAlphaComponent(0.4)
        baseRing.lineWidth = 2
        baseRing.fillColor = UIColor.white.withAlphaComponent(0.05)

        thumb = SKShapeNode(circleOfRadius: r * 0.38)
        thumb.fillColor = UIColor.white.withAlphaComponent(0.4)
        thumb.strokeColor = .clear

        super.init()
        addChild(baseRing)
        addChild(thumb)
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Touch interface (called by GameScene)

    /// Update thumb position from a raw offset vector, clamped to joystickRadius.
    func setThumbOffset(_ offset: CGVector) {
        let len = sqrt(offset.dx * offset.dx + offset.dy * offset.dy)
        let clampedLen = min(len, GameConstants.joystickRadius)
        if len > 0 {
            thumbOffset = CGVector(dx: offset.dx / len * clampedLen,
                                  dy: offset.dy / len * clampedLen)
        } else {
            thumbOffset = .zero
        }
        thumb.position = CGPoint(x: thumbOffset.dx, y: thumbOffset.dy)
    }

    /// Reset thumb to center (touch ended).
    func reset() {
        thumbOffset = .zero
        thumb.position = .zero
    }

    // MARK: - Hit testing

    /// Returns true if a point (in this node's parent coordinate space) is within the touch area.
    func containsPoint(_ point: CGPoint) -> Bool {
        let dx = point.x - position.x
        let dy = point.y - position.y
        return sqrt(dx * dx + dy * dy) <= GameConstants.joystickRadius * 1.5
    }
}
