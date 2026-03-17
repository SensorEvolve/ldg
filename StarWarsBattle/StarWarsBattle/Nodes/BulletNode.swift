import SpriteKit
import UIKit

class BulletNode: SKSpriteNode {

    let bulletVelocity: CGVector

    init(velocity: CGVector) {
        self.bulletVelocity = velocity
        let color: UIColor = velocity.dy > 0 ? .red : UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0)
        super.init(texture: nil, color: color, size: CGSize(width: 5, height: 15))
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    func isOutOfBounds(sceneHeight: CGFloat) -> Bool {
        return position.y < -20 || position.y > sceneHeight + 20
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.affectedByGravity = false
        body.linearDamping = 0
        body.angularDamping = 0
        body.collisionBitMask = 0
        body.velocity = bulletVelocity

        if bulletVelocity.dy > 0 {
            body.categoryBitMask    = PhysicsCategory.imperialBullet
            body.contactTestBitMask = PhysicsCategory.rebelShip
        } else {
            body.categoryBitMask    = PhysicsCategory.rebelBullet
            body.contactTestBitMask = PhysicsCategory.imperialShip
        }
        physicsBody = body
    }
}
