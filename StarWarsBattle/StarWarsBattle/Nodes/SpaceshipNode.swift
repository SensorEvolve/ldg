import SpriteKit

class SpaceshipNode: SKSpriteNode {

    private(set) var hp: Int = GameConstants.maxHP
    private(set) var score: Int = 0

    var isDead: Bool { hp <= 0 }

    init(imageName: String) {
        let texture = SKTexture(imageNamed: imageName)
        super.init(texture: texture, color: .clear, size: texture.size())
    }

    required init?(coder aDecoder: NSCoder) { fatalError() }

    // MARK: - Combat

    func takeDamage() {
        hp = max(0, hp - 1)
    }

    func addScore() {
        score += 1
    }

    // MARK: - Movement

    /// Move the ship by velocity * deltaTime, clamped to `bounds`.
    func applyVelocity(_ velocity: CGVector, deltaTime: CGFloat, bounds: CGRect) {
        let newX = position.x + velocity.dx * deltaTime
        let newY = position.y + velocity.dy * deltaTime
        position.x = max(bounds.minX, min(newX, bounds.maxX))
        position.y = max(bounds.minY, min(newY, bounds.maxY))
    }

    // MARK: - Physics

    /// Call once after adding to scene to configure the physics body.
    func setupPhysics(category: UInt32, contactTest: UInt32) {
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.affectedByGravity = false
        body.collisionBitMask = 0
        body.categoryBitMask    = category
        body.contactTestBitMask = contactTest
        physicsBody = body
    }
}
