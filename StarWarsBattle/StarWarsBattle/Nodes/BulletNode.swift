import SpriteKit
import UIKit

class BulletNode: SKSpriteNode {

    let bulletVelocity: CGVector

    /// - Parameter velocity: Scene-space velocity. dx > 0 = Imperial (travels right),
    ///   dx < 0 = Rebel (travels left).
    init(velocity: CGVector) {
        self.bulletVelocity = velocity
        let color: UIColor = velocity.dx > 0
            ? .red
            : UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)
        super.init(texture: nil, color: color, size: CGSize(width: 15, height: 5))
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    /// Returns true when the bullet has left the playfield and should be removed.
    func isOutOfBounds(sceneWidth: CGFloat) -> Bool {
        return position.x < -20 || position.x > sceneWidth + 20
    }

    // MARK: - Private

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: size)
        // isDynamic = true is REQUIRED: SpriteKit only fires contact callbacks when
        // at least one body in the pair is dynamic. Ships are static; bullets must be dynamic.
        body.isDynamic = true
        body.affectedByGravity = false
        body.linearDamping = 0
        body.angularDamping = 0
        body.collisionBitMask = 0
        // Physics engine moves the bullet; no manual position update needed.
        body.velocity = bulletVelocity

        if bulletVelocity.dx > 0 {
            body.categoryBitMask    = PhysicsCategory.imperialBullet
            body.contactTestBitMask = PhysicsCategory.rebelShip
        } else {
            body.categoryBitMask    = PhysicsCategory.rebelBullet
            body.contactTestBitMask = PhysicsCategory.imperialShip
        }
        physicsBody = body
    }
}
