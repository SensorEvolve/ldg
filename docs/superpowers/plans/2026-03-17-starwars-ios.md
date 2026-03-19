# Star Wars iOS — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an iPad-only 1v1 split-screen space shooter in Swift + SpriteKit, porting the StarWars_rust game with touch controls.

**Architecture:** Two players share one iPad in landscape, each holding a short side. Player 1's nodes live in scene space; Player 2's nodes live inside an `SKNode` container rotated `π` so everything mirrors automatically. All bullets are added to the scene root in scene-space coordinates.

**Tech Stack:** Swift 5.9+, SpriteKit, XCTest, Xcode 15+, iOS 16+, iPad only.

> **Note on naming:** The Xcode product name is `StarWarsBattle` (clearer than the repo folder `ldg`). All file paths, scheme names, and `@testable import` statements in this plan use `StarWarsBattle`. The spec's `ldg.xcodeproj` entry is the repo folder path — the product name inside it is `StarWarsBattle`.

---

## Chunk 1: Project Setup & Assets

### Task 1: Create the Xcode project

**Files:**
- Create: `StarWarsBattle/StarWarsBattle.xcodeproj` (via Xcode GUI)
- Delete: `StarWarsBattle/StarWarsBattle/GameScene.sks`
- Delete: `StarWarsBattle/StarWarsBattle/Actions.sks`

- [ ] **Step 1: Create project via Xcode**

  Open Xcode → File → New → Project → iOS → **Game**
  - Product Name: `StarWarsBattle`
  - Language: `Swift`
  - Game Technology: `SpriteKit`
  - Save to: `/Users/ethereum/Developer/ldg/`

- [ ] **Step 2: Delete unused SpriteKit scene files**

  In Xcode's Project Navigator, select and delete:
  - `GameScene.sks`
  - `Actions.sks`

  Choose "Move to Trash" when prompted.

- [ ] **Step 3: Delete the generated GameScene.swift**

  Delete `GameScene.swift` (Xcode's stub). We will replace it with our own.
  Choose "Move to Trash".

- [ ] **Step 4: Create folder groups in Xcode**

  In Xcode's Project Navigator, right-click `StarWarsBattle` group → New Group:
  - `Scenes`
  - `Nodes`

- [ ] **Step 5: Verify the project builds**

  ```
  Cmd+B in Xcode
  ```
  Expected: Build Succeeded (no source errors yet — we deleted the template files).

- [ ] **Step 6: Commit**

  The `ldg` repo is already initialised. The Xcode project lives inside it:

  ```bash
  cd /Users/ethereum/Developer/ldg
  git add StarWarsBattle/
  git commit -m "chore: initial Xcode SpriteKit project"
  ```

---

### Task 2: Lock orientation to landscape iPad only

**Files:**
- Modify: `StarWarsBattle/StarWarsBattle/Info.plist`
- Modify: `StarWarsBattle/StarWarsBattle/GameViewController.swift`

- [ ] **Step 1: Edit Info.plist — supported orientations**

  In Xcode, select `Info.plist`. Add/update:
  - Key: `UISupportedInterfaceOrientations` → Array:
    - `UIInterfaceOrientationLandscapeLeft`
    - `UIInterfaceOrientationLandscapeRight`
  - Key: `UISupportedInterfaceOrientations~ipad` → Array:
    - `UIInterfaceOrientationLandscapeLeft`
    - `UIInterfaceOrientationLandscapeRight`
  - Key: `UIRequiresFullScreen` → Boolean → `YES`
  - Key: `UIDeviceFamily` → Array → `2` (iPad only)

- [ ] **Step 2: Override in GameViewController**

  Replace the contents of `GameViewController.swift` with a stub that compiles
  before `MenuScene` exists. We will update this reference in Task 11.

  ```swift
  import UIKit
  import SpriteKit

  class GameViewController: UIViewController {

      override func viewDidLoad() {
          super.viewDidLoad()

          guard let skView = view as? SKView else { return }
          skView.ignoresSiblingOrder = true
          skView.showsFPS = false
          skView.showsNodeCount = false

          // Placeholder — replaced with MenuScene in Task 11
          let scene = SKScene(size: skView.bounds.size)
          scene.backgroundColor = .black
          scene.scaleMode = .resizeFill
          skView.presentScene(scene)
      }

      override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
          return .landscape
      }

      override var prefersStatusBarHidden: Bool {
          return true
      }

      override var shouldAutorotate: Bool {
          return false
      }
  }
  ```

- [ ] **Step 3: Build and verify**

  ```bash
  xcodebuild build \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    2>&1 | tail -3
  ```

  Expected last line: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Info.plist \
          StarWarsBattle/StarWarsBattle/GameViewController.swift
  git commit -m "chore: lock to landscape iPad only"
  ```

---

### Task 3: Download and add assets

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Assets.xcassets/bg_version_2.jpg`
- Create: `StarWarsBattle/StarWarsBattle/Assets.xcassets/imperial_spaceship.png`
- Create: `StarWarsBattle/StarWarsBattle/Assets.xcassets/rebel_spaceship.png`
- Create: `StarWarsBattle/StarWarsBattle/explosion.mp3`
- Create: `StarWarsBattle/StarWarsBattle/laser.mp3`

- [ ] **Step 1: Download image assets**

  ```bash
  cd /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle

  curl -L "https://raw.githubusercontent.com/SensorEvolve/StarWars_rust/master/assets/bg_version_2.jpg" \
    -o bg_version_2.jpg

  curl -L "https://raw.githubusercontent.com/SensorEvolve/StarWars_rust/master/assets/imperial_spaceship.png" \
    -o imperial_spaceship.png

  curl -L "https://raw.githubusercontent.com/SensorEvolve/StarWars_rust/master/assets/rebel_spaceship.png" \
    -o rebel_spaceship.png
  ```

  Expected: 3 files downloaded, each > 0 bytes.
  ```bash
  ls -lh bg_version_2.jpg imperial_spaceship.png rebel_spaceship.png
  ```

- [ ] **Step 2: Download sound assets**

  ```bash
  curl -L "https://raw.githubusercontent.com/SensorEvolve/StarWars_rust/master/assets/explosion.mp3" \
    -o explosion.mp3

  curl -L "https://raw.githubusercontent.com/SensorEvolve/StarWars_rust/master/assets/laser.mp3" \
    -o laser.mp3
  ```

  Expected: 2 files downloaded.
  ```bash
  ls -lh explosion.mp3 laser.mp3
  ```

- [ ] **Step 3: Add images to Assets.xcassets**

  In Xcode:
  1. Select `Assets.xcassets` in the Project Navigator.
  2. Drag `bg_version_2.jpg`, `imperial_spaceship.png`, `rebel_spaceship.png` from Finder into the asset catalog.
  3. For each image, set "Scales" to "Single Scale" in the Attributes inspector.

- [ ] **Step 4: Add sound files to the project**

  In Xcode:
  1. Right-click the `StarWarsBattle` group (not the asset catalog) → "Add Files to StarWarsBattle..."
  2. Select `explosion.mp3` and `laser.mp3`.
  3. Ensure "Copy items if needed" is checked and the target is `StarWarsBattle`.

- [ ] **Step 5: Verify assets are bundled correctly**

  Build and check the app bundle contains all 5 assets:

  ```bash
  xcodebuild build \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    CONFIGURATION_BUILD_DIR=/tmp/StarWarsBattleBuild \
    2>&1 | tail -3
  ```

  Expected: `** BUILD SUCCEEDED **`

  ```bash
  ls /tmp/StarWarsBattleBuild/StarWarsBattle.app/ | grep -E "(bg_version_2|spaceship|explosion|laser)"
  ```

  Expected: 5 files listed (`bg_version_2.jpg`, `imperial_spaceship.png`,
  `rebel_spaceship.png`, `explosion.mp3`, `laser.mp3`).

- [ ] **Step 6: Commit**

  ```bash
  git add .
  git commit -m "chore: add game assets from StarWars_rust repo"
  ```

---

## Chunk 2: Constants, Physics, and Core Nodes

### Task 4: GameConstants and PhysicsCategory

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/GameConstants.swift`
- Create: `StarWarsBattle/StarWarsBattle/PhysicsCategory.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/GameConstantsTests.swift`

- [ ] **Step 1: Add the test target**

  In Xcode: File → New → Target → iOS Unit Testing Bundle.
  - Product Name: `StarWarsBattleTests`
  - Ensure it tests the `StarWarsBattle` scheme.

- [ ] **Step 2: Write the failing test**

  Create `StarWarsBattleTests/GameConstantsTests.swift`:

  ```swift
  import XCTest
  @testable import StarWarsBattle

  final class GameConstantsTests: XCTestCase {

      func testShipSpeed() {
          XCTAssertEqual(GameConstants.shipSpeed, 300)
      }

      func testBulletSpeed() {
          XCTAssertEqual(GameConstants.bulletSpeed, 600)
      }

      func testMaxBullets() {
          XCTAssertEqual(GameConstants.maxBullets, 3)
      }

      func testMaxHP() {
          XCTAssertEqual(GameConstants.maxHP, 10)
      }

      func testPhysicsCategoriesAreUnique() {
          let categories: [UInt32] = [
              PhysicsCategory.imperialShip,
              PhysicsCategory.rebelShip,
              PhysicsCategory.imperialBullet,
              PhysicsCategory.rebelBullet,
          ]
          XCTAssertEqual(Set(categories).count, 4, "All physics categories must be unique bit flags")
      }

      func testAllPhysicsCategoriesAreDistinctBitFlags() {
          // Each category must occupy a unique bit position
          XCTAssertEqual(PhysicsCategory.imperialShip   & PhysicsCategory.rebelShip,      0)
          XCTAssertEqual(PhysicsCategory.imperialShip   & PhysicsCategory.imperialBullet, 0)
          XCTAssertEqual(PhysicsCategory.imperialShip   & PhysicsCategory.rebelBullet,    0)
          XCTAssertEqual(PhysicsCategory.rebelShip      & PhysicsCategory.imperialBullet, 0)
          XCTAssertEqual(PhysicsCategory.rebelShip      & PhysicsCategory.rebelBullet,    0)
          XCTAssertEqual(PhysicsCategory.imperialBullet & PhysicsCategory.rebelBullet,    0)
      }
  }
  ```

- [ ] **Step 3: Run test to verify it fails**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/GameConstantsTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `GameConstants` not found.

- [ ] **Step 4: Create GameConstants.swift**

  ```swift
  import CoreGraphics

  enum GameConstants {
      static let shipSpeed: CGFloat    = 300   // pt/sec — matches Rust SHIP_SPEED=5 @ 60fps
      static let bulletSpeed: CGFloat  = 600   // pt/sec — matches Rust BULLET_VEL=10 @ 60fps
      static let maxBullets: Int       = 3
      static let maxHP: Int            = 10
      static let joystickRadius: CGFloat   = 60
      static let joystickDeadZone: CGFloat = 5
      static let fireButtonSize: CGFloat   = 80
      static let controlMargin: CGFloat    = 30
      static let dividerWidth: CGFloat     = 2
  }
  ```

- [ ] **Step 5: Create PhysicsCategory.swift**

  ```swift
  import Foundation

  struct PhysicsCategory {
      static let imperialShip:   UInt32 = 1 << 0  // 1
      static let rebelShip:      UInt32 = 1 << 1  // 2
      static let imperialBullet: UInt32 = 1 << 2  // 4
      static let rebelBullet:    UInt32 = 1 << 3  // 8
  }
  ```

- [ ] **Step 6: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/GameConstantsTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All tests PASS.

- [ ] **Step 7: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/GameConstants.swift \
          StarWarsBattle/StarWarsBattle/PhysicsCategory.swift \
          StarWarsBattle/StarWarsBattleTests/GameConstantsTests.swift
  git commit -m "feat: add GameConstants and PhysicsCategory"
  ```

---

### Task 5: BulletNode

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Nodes/BulletNode.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/BulletNodeTests.swift`

- [ ] **Step 1: Write failing tests**

  Create `StarWarsBattleTests/BulletNodeTests.swift`:

  ```swift
  import XCTest
  import SpriteKit
  @testable import StarWarsBattle

  final class BulletNodeTests: XCTestCase {

      func testImperialBulletIsRed() {
          let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
          XCTAssertEqual(bullet.color, UIColor.red)
      }

      func testRebelBulletIsBlue() {
          let bullet = BulletNode(velocity: CGVector(dx: -600, dy: 0))
          XCTAssertEqual(bullet.color, UIColor(red: 0.3, green: 0.5, blue: 1.0, alpha: 1.0))
      }

      func testBulletSize() {
          let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
          XCTAssertEqual(bullet.size, CGSize(width: 15, height: 5))
      }

      func testImperialBulletPhysicsCategory() {
          let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
          XCTAssertEqual(bullet.physicsBody?.categoryBitMask, PhysicsCategory.imperialBullet)
          XCTAssertEqual(bullet.physicsBody?.contactTestBitMask, PhysicsCategory.rebelShip)
          XCTAssertEqual(bullet.physicsBody?.collisionBitMask, 0)
      }

      func testRebelBulletPhysicsCategory() {
          let bullet = BulletNode(velocity: CGVector(dx: -600, dy: 0))
          XCTAssertEqual(bullet.physicsBody?.categoryBitMask, PhysicsCategory.rebelBullet)
          XCTAssertEqual(bullet.physicsBody?.contactTestBitMask, PhysicsCategory.imperialShip)
          XCTAssertEqual(bullet.physicsBody?.collisionBitMask, 0)
      }

      func testBulletVelocityStored() {
          let vel = CGVector(dx: 600, dy: 0)
          let bullet = BulletNode(velocity: vel)
          XCTAssertEqual(bullet.bulletVelocity.dx, vel.dx)
          XCTAssertEqual(bullet.bulletVelocity.dy, vel.dy)
      }

      func testImperialBulletPhysicsVelocitySet() {
          let vel = CGVector(dx: 600, dy: 0)
          let bullet = BulletNode(velocity: vel)
          XCTAssertEqual(bullet.physicsBody?.velocity.dx, vel.dx, accuracy: 0.01)
          XCTAssertEqual(bullet.physicsBody?.velocity.dy, vel.dy, accuracy: 0.01)
      }

      func testBulletIsDynamicForContactCallbacks() {
          let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
          XCTAssertTrue(bullet.physicsBody?.isDynamic == true,
                        "Bullets must be dynamic so SKPhysics contact callbacks fire against static ships")
      }

      func testBulletOutOfBoundsRight() {
          let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
          bullet.position = CGPoint(x: 1201, y: 200)  // > sceneWidth(1180) + 20
          XCTAssertTrue(bullet.isOutOfBounds(sceneWidth: 1180))
      }

      func testBulletOutOfBoundsLeft() {
          let bullet = BulletNode(velocity: CGVector(dx: -600, dy: 0))
          bullet.position = CGPoint(x: -30, y: 200)
          XCTAssertTrue(bullet.isOutOfBounds(sceneWidth: 1180))
      }

      func testBulletInBounds() {
          let bullet = BulletNode(velocity: CGVector(dx: 600, dy: 0))
          bullet.position = CGPoint(x: 500, y: 200)
          XCTAssertFalse(bullet.isOutOfBounds(sceneWidth: 1180))
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/BulletNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `BulletNode` not found.

- [ ] **Step 3: Create BulletNode.swift**

  ```swift
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
      /// Called each frame by GameScene. Position is updated by the physics engine.
      /// - Parameter sceneWidth: Full scene width in points.
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
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/BulletNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All 11 tests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Nodes/BulletNode.swift \
          StarWarsBattle/StarWarsBattleTests/BulletNodeTests.swift
  git commit -m "feat: add BulletNode with physics categories"
  ```

---

### Task 6: SpaceshipNode

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Nodes/SpaceshipNode.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/SpaceshipNodeTests.swift`

- [ ] **Step 1: Write failing tests**

  Create `StarWarsBattleTests/SpaceshipNodeTests.swift`:

  ```swift
  import XCTest
  import SpriteKit
  @testable import StarWarsBattle

  final class SpaceshipNodeTests: XCTestCase {

      func testInitialHP() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          XCTAssertEqual(ship.hp, GameConstants.maxHP)
      }

      func testInitialScore() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          XCTAssertEqual(ship.score, 0)
      }

      func testTakeDamageReducesHP() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          ship.takeDamage()
          XCTAssertEqual(ship.hp, GameConstants.maxHP - 1)
      }

      func testTakeDamageDoesNotGoBelowZero() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          for _ in 0..<20 { ship.takeDamage() }
          XCTAssertEqual(ship.hp, 0)
      }

      func testIsDeadWhenHPZero() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          XCTAssertFalse(ship.isDead)
          for _ in 0..<10 { ship.takeDamage() }
          XCTAssertTrue(ship.isDead)
      }

      func testMoveClampedToMaxX() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          ship.size = CGSize(width: 60, height: 40)
          ship.position = CGPoint(x: 500, y: 200)
          let bounds = CGRect(x: 0, y: 0, width: 590, height: 820)
          ship.applyVelocity(CGVector(dx: 1000, dy: 0), deltaTime: 1.0, bounds: bounds)
          XCTAssertLessThanOrEqual(ship.position.x, bounds.maxX, "Ship must not exceed right bound")
      }

      func testMoveClampedToMinX() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          ship.size = CGSize(width: 60, height: 40)
          ship.position = CGPoint(x: 50, y: 200)
          let bounds = CGRect(x: 30, y: 0, width: 560, height: 820)
          ship.applyVelocity(CGVector(dx: -1000, dy: 0), deltaTime: 1.0, bounds: bounds)
          XCTAssertGreaterThanOrEqual(ship.position.x, bounds.minX, "Ship must not exceed left bound")
      }

      func testMoveClampedToMinY() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          ship.size = CGSize(width: 60, height: 40)
          ship.position = CGPoint(x: 200, y: 30)
          let bounds = CGRect(x: 0, y: 20, width: 590, height: 800)
          ship.applyVelocity(CGVector(dx: 0, dy: -1000), deltaTime: 1.0, bounds: bounds)
          XCTAssertGreaterThanOrEqual(ship.position.y, bounds.minY)
      }

      func testImperialPhysicsCategory() {
          let ship = SpaceshipNode(imageName: "imperial_spaceship")
          // Imperial ship must detect contact with REBEL bullets (not its own)
          ship.setupPhysics(category: PhysicsCategory.imperialShip,
                            contactTest: PhysicsCategory.rebelBullet)
          XCTAssertEqual(ship.physicsBody?.categoryBitMask, PhysicsCategory.imperialShip)
          XCTAssertEqual(ship.physicsBody?.contactTestBitMask, PhysicsCategory.rebelBullet)
          XCTAssertEqual(ship.physicsBody?.collisionBitMask, 0)
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/SpaceshipNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `SpaceshipNode` not found.

- [ ] **Step 3: Create SpaceshipNode.swift**

  ```swift
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
      /// - Parameters:
      ///   - velocity: Points per second in the ship's parent coordinate space.
      ///   - deltaTime: Seconds since last frame.
      ///   - bounds: Allowed rect for the ship's position (center point).
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
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/SpaceshipNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All 9 tests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Nodes/SpaceshipNode.swift \
          StarWarsBattle/StarWarsBattleTests/SpaceshipNodeTests.swift
  git commit -m "feat: add SpaceshipNode with movement clamping and combat"
  ```

---

## Chunk 3: Control Nodes

### Task 7: JoystickNode

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Nodes/JoystickNode.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/JoystickNodeTests.swift`

- [ ] **Step 1: Write failing tests**

  Create `StarWarsBattleTests/JoystickNodeTests.swift`:

  ```swift
  import XCTest
  import SpriteKit
  @testable import StarWarsBattle

  final class JoystickNodeTests: XCTestCase {

      func testInitialVelocityIsZero() {
          let joystick = JoystickNode()
          let vel = joystick.velocityVector
          XCTAssertEqual(vel.dx, 0)
          XCTAssertEqual(vel.dy, 0)
      }

      func testDeadZoneReturnsZeroVelocity() {
          let joystick = JoystickNode()
          // Offset of 3pt — inside dead zone of 5pt
          joystick.setThumbOffset(CGVector(dx: 3, dy: 0))
          XCTAssertEqual(joystick.velocityVector.dx, 0)
          XCTAssertEqual(joystick.velocityVector.dy, 0)
      }

      func testPureRightVelocity() {
          let joystick = JoystickNode()
          joystick.setThumbOffset(CGVector(dx: 60, dy: 0))
          let vel = joystick.velocityVector
          XCTAssertEqual(vel.dx, GameConstants.shipSpeed, accuracy: 0.01)
          XCTAssertEqual(vel.dy, 0, accuracy: 0.01)
      }

      func testPureUpVelocity() {
          let joystick = JoystickNode()
          joystick.setThumbOffset(CGVector(dx: 0, dy: 60))
          let vel = joystick.velocityVector
          XCTAssertEqual(vel.dx, 0, accuracy: 0.01)
          XCTAssertEqual(vel.dy, GameConstants.shipSpeed, accuracy: 0.01)
      }

      func testDiagonalVelocityIsNormalized() {
          let joystick = JoystickNode()
          joystick.setThumbOffset(CGVector(dx: 60, dy: 60))
          let vel = joystick.velocityVector
          let magnitude = sqrt(vel.dx * vel.dx + vel.dy * vel.dy)
          XCTAssertEqual(magnitude, GameConstants.shipSpeed, accuracy: 0.1)
      }

      func testOffsetClampedToRadius() {
          let joystick = JoystickNode()
          // Push past radius
          joystick.setThumbOffset(CGVector(dx: 200, dy: 0))
          let vel = joystick.velocityVector
          // Velocity should still be exactly shipSpeed (not more)
          XCTAssertEqual(vel.dx, GameConstants.shipSpeed, accuracy: 0.01)
      }

      func testResetStopsVelocity() {
          let joystick = JoystickNode()
          joystick.setThumbOffset(CGVector(dx: 60, dy: 0))
          joystick.reset()
          XCTAssertEqual(joystick.velocityVector.dx, 0)
          XCTAssertEqual(joystick.velocityVector.dy, 0)
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/JoystickNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `JoystickNode` not found.

- [ ] **Step 3: Create JoystickNode.swift**

  ```swift
  import SpriteKit
  import UIKit

  class JoystickNode: SKNode {

      // MARK: - Visuals
      private let baseRing: SKShapeNode
      private let thumb: SKShapeNode

      // MARK: - State
      /// Raw offset of the thumb from the joystick center, clamped to joystickRadius.
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

      /// Update thumb position from a raw offset vector (in joystick local coordinates).
      /// The offset is clamped to joystickRadius.
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

      /// Returns true if a point (in this node's parent coordinate space) is within the
      /// joystick touch area (1.5× radius for generous hit testing).
      func containsPoint(_ point: CGPoint) -> Bool {
          let dx = point.x - position.x
          let dy = point.y - position.y
          return sqrt(dx * dx + dy * dy) <= GameConstants.joystickRadius * 1.5
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/JoystickNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All 7 tests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Nodes/JoystickNode.swift \
          StarWarsBattle/StarWarsBattleTests/JoystickNodeTests.swift
  git commit -m "feat: add JoystickNode with dead-zone and velocity calculation"
  ```

---

### Task 8: FireButtonNode

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Nodes/FireButtonNode.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/FireButtonNodeTests.swift`

- [ ] **Step 1: Write failing tests**

  Create `StarWarsBattleTests/FireButtonNodeTests.swift`:

  ```swift
  import XCTest
  import SpriteKit
  @testable import StarWarsBattle

  final class FireButtonNodeTests: XCTestCase {

      func testContainsPointInsideTouchArea() {
          let btn = FireButtonNode()
          btn.position = CGPoint(x: 50, y: 50)
          // A point 30pt from center — inside 40pt radius
          XCTAssertTrue(btn.containsPoint(CGPoint(x: 75, y: 50)))
      }

      func testDoesNotContainPointOutsideTouchArea() {
          let btn = FireButtonNode()
          btn.position = CGPoint(x: 50, y: 50)
          // A point 50pt from center — outside 40pt radius
          XCTAssertFalse(btn.containsPoint(CGPoint(x: 105, y: 50)))
      }

      func testTouchRadiusIsHalfFireButtonSize() {
          // Touch radius = fireButtonSize / 2 = 40pt
          XCTAssertEqual(FireButtonNode.touchRadius, GameConstants.fireButtonSize / 2)
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/FireButtonNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `FireButtonNode` not found.

- [ ] **Step 3: Create FireButtonNode.swift**

  ```swift
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
      func containsPoint(_ point: CGPoint) -> Bool {
          let dx = point.x - position.x
          let dy = point.y - position.y
          return sqrt(dx * dx + dy * dy) <= FireButtonNode.touchRadius
      }
  }
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/FireButtonNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Nodes/FireButtonNode.swift \
          StarWarsBattle/StarWarsBattleTests/FireButtonNodeTests.swift
  git commit -m "feat: add FireButtonNode with tap area hit-testing"
  ```

---

### Task 9: HUDNode

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Nodes/HUDNode.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/HUDNodeTests.swift`

- [ ] **Step 1: Write failing tests**

  Create `StarWarsBattleTests/HUDNodeTests.swift`:

  ```swift
  import XCTest
  import SpriteKit
  @testable import StarWarsBattle

  final class HUDNodeTests: XCTestCase {

      func testInitialHPLabel() {
          let hud = HUDNode(playerName: "IMPERIAL")
          XCTAssertTrue(hud.hpText.contains("10"), "HP label should show initial HP of 10")
      }

      func testInitialScoreLabel() {
          let hud = HUDNode(playerName: "IMPERIAL")
          XCTAssertTrue(hud.scoreText.contains("0"), "Score label should start at 0")
      }

      func testUpdateHP() {
          let hud = HUDNode(playerName: "IMPERIAL")
          hud.update(hp: 7, score: 0)
          XCTAssertTrue(hud.hpText.contains("7"))
      }

      func testUpdateScore() {
          let hud = HUDNode(playerName: "REBEL")
          hud.update(hp: 10, score: 5)
          XCTAssertTrue(hud.scoreText.contains("5"))
      }

      func testHUDRotatedForPlayer1() {
          let hud = HUDNode(playerName: "IMPERIAL")
          XCTAssertEqual(hud.zRotation, CGFloat.pi / 2, accuracy: 0.001)
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/HUDNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `HUDNode` not found.

- [ ] **Step 3: Create HUDNode.swift**

  ```swift
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
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/HUDNodeTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Nodes/HUDNode.swift \
          StarWarsBattle/StarWarsBattleTests/HUDNodeTests.swift
  git commit -m "feat: add HUDNode with HP and score display"
  ```

---

## Chunk 4: GameScene

### Task 10: GameScene — setup and layout

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Scenes/GameScene.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/GameSceneTests.swift`

- [ ] **Step 1: Write failing tests for GameScene state**

  Create `StarWarsBattleTests/GameSceneTests.swift`:

  ```swift
  import XCTest
  import SpriteKit
  @testable import StarWarsBattle

  final class GameSceneTests: XCTestCase {

      var scene: GameScene!

      override func setUp() {
          super.setUp()
          scene = GameScene(size: CGSize(width: 1180, height: 820))
          scene.scaleMode = .resizeFill
          // Force scene to set up its contents
          let view = SKView(frame: CGRect(x: 0, y: 0, width: 1180, height: 820))
          view.presentScene(scene)
      }

      func testSceneHasImperialShip() {
          XCTAssertNotNil(scene.imperialShip)
      }

      func testSceneHasRebelShip() {
          XCTAssertNotNil(scene.rebelShip)
      }

      func testImperialShipStartsInLeftHalf() {
          let ship = scene.imperialShip!
          XCTAssertLessThan(ship.position.x, scene.size.width / 2,
                            "Imperial ship must start in the left half")
      }

      func testRebelShipStartsInRightHalfInSceneSpace() {
          // Rebel ship is inside the player2 container, so we check its scene position
          let ship = scene.rebelShip!
          let scenePos = scene.convert(ship.position, from: ship.parent!)
          XCTAssertGreaterThanOrEqual(scenePos.x, scene.size.width / 2,
                                      "Rebel ship must start in the right half (scene space)")
      }

      func testGameIsNotOverAtStart() {
          XCTAssertFalse(scene.isGameOver)
      }

      func testImperialBulletCountStartsAtZero() {
          XCTAssertEqual(scene.imperialBullets.count, 0)
      }

      func testRebelBulletCountStartsAtZero() {
          XCTAssertEqual(scene.rebelBullets.count, 0)
      }

      func testCanFireImperialWhenUnderMax() {
          XCTAssertTrue(scene.canFire(player: .imperial))
      }

      func testCannotFireWhenAtMax() {
          for _ in 0..<GameConstants.maxBullets {
              scene.spawnBullet(player: .imperial)
          }
          XCTAssertFalse(scene.canFire(player: .imperial))
      }

      func testGameOverWhenImperialHPZero() {
          scene.imperialShip!.takeDamage()
          scene.imperialShip!.takeDamage()
          // Drain all HP
          for _ in 0..<GameConstants.maxHP {
              scene.imperialShip!.takeDamage()
          }
          scene.checkGameOver()
          XCTAssertTrue(scene.isGameOver)
      }

      func testWinnerIsRebelWhenImperialDies() {
          for _ in 0..<GameConstants.maxHP { scene.imperialShip!.takeDamage() }
          scene.checkGameOver()
          XCTAssertEqual(scene.winner, "Rebel Wins!")
      }

      func testWinnerIsImperialWhenRebelDies() {
          for _ in 0..<GameConstants.maxHP { scene.rebelShip!.takeDamage() }
          scene.checkGameOver()
          XCTAssertEqual(scene.winner, "Imperial Wins!")
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/GameSceneTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `GameScene` not found.

- [ ] **Step 3: Create GameScene.swift**

  ```swift
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
      // Maps UITouch → which player owns it
      private var touchOwner: [ObjectIdentifier: Player] = [:]
      // For joystick: maps touch to its start location (in parent coord space)
      private var joystickTouchStart: [ObjectIdentifier: CGPoint] = [:]

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
              x: size.width / 2 - GameConstants.dividerWidth / 2,
              y: 0,
              width: GameConstants.dividerWidth,
              height: size.height
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
          // Imperial — scene space
          let imp = SpaceshipNode(imageName: "imperial_spaceship")
          imp.position = CGPoint(x: 100, y: size.height / 2)
          imp.setupPhysics(category: PhysicsCategory.imperialShip,
                           contactTest: PhysicsCategory.rebelBullet)
          addChild(imp)
          imperialShip = imp

          // Rebel — player2Container local space
          let reb = SpaceshipNode(imageName: "rebel_spaceship")
          reb.position = CGPoint(x: 100, y: size.height / 2)
          reb.setupPhysics(category: PhysicsCategory.rebelShip,
                           contactTest: PhysicsCategory.imperialBullet)
          player2Container.addChild(reb)
          rebelShip = reb
      }

      private func setupControls() {
          let m = GameConstants.controlMargin
          let r = GameConstants.joystickRadius
          let fb = GameConstants.fireButtonSize / 2

          // --- Player 1 controls (scene space, left short side) ---

          // Joystick: bottom-left corner
          imperialJoystick = JoystickNode()
          imperialJoystick.position = CGPoint(x: m + r, y: m + r)
          addChild(imperialJoystick)

          // Fire button: top-left corner
          imperialFireButton = FireButtonNode()
          imperialFireButton.position = CGPoint(x: m + fb, y: size.height - m - fb)
          addChild(imperialFireButton)

          // HUD: center of left edge
          imperialHUD = HUDNode(playerName: "IMPERIAL")
          imperialHUD.position = CGPoint(x: m, y: size.height / 2)
          addChild(imperialHUD)

          // --- Player 2 controls (player2Container local space, mirrors Player 1) ---

          rebelJoystick = JoystickNode()
          rebelJoystick.position = CGPoint(x: m + r, y: m + r)
          player2Container.addChild(rebelJoystick)

          rebelFireButton = FireButtonNode()
          rebelFireButton.position = CGPoint(x: m + fb, y: size.height - m - fb)
          player2Container.addChild(rebelFireButton)

          rebelHUD = HUDNode(playerName: "REBEL")
          rebelHUD.position = CGPoint(x: m, y: size.height / 2)
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
              // Spawn at Imperial ship's nose, velocity travels right
              let noseX = imp.position.x + imp.size.width / 2
              let bullet = BulletNode(velocity: CGVector(dx: GameConstants.bulletSpeed, dy: 0))
              bullet.position = CGPoint(x: noseX, y: imp.position.y)
              addChild(bullet)
              imperialBullets.append(bullet)

          case .rebel:
              // Rebel is in player2Container. Convert nose position to scene space.
              let localNose = CGPoint(x: reb.position.x + reb.size.width / 2, y: reb.position.y)
              let sceneNose = convert(localNose, from: player2Container)
              // NOTE: The spec describes velocity as (+bulletSpeed, 0) in container local space,
              // but bullets are added to the SCENE ROOT (not the container), so the equivalent
              // scene-space velocity is (-bulletSpeed, 0). Do NOT change this to +bulletSpeed.
              let bullet = BulletNode(velocity: CGVector(dx: -GameConstants.bulletSpeed, dy: 0))
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

          let halfWidth = size.width / 2
          let shipHalfW = imp.size.width / 2
          let shipHalfH = imp.size.height / 2

          // Imperial bounds (scene space)
          let impBounds = CGRect(
              x: shipHalfW,
              y: shipHalfH,
              width: halfWidth - shipHalfW - GameConstants.dividerWidth,
              height: size.height - shipHalfH * 2
          )
          imp.applyVelocity(imperialJoystick.velocityVector, deltaTime: dt, bounds: impBounds)

          // Rebel bounds (player2Container local space — symmetric)
          let rebHalfW = reb.size.width / 2
          let rebHalfH = reb.size.height / 2
          let rebBounds = CGRect(
              x: rebHalfW,
              y: rebHalfH,
              width: halfWidth - rebHalfW - GameConstants.dividerWidth,
              height: size.height - rebHalfH * 2
          )
          reb.applyVelocity(rebelJoystick.velocityVector, deltaTime: dt, bounds: rebBounds)
      }

      private func updateBullets() {
          // Physics engine moves bullets via body.velocity — just cull out-of-bounds ones.
          var aliveImperial: [BulletNode] = []
          for bullet in imperialBullets {
              if bullet.isOutOfBounds(sceneWidth: size.width) {
                  bullet.removeFromParent()
              } else {
                  aliveImperial.append(bullet)
              }
          }
          imperialBullets = aliveImperial

          var aliveRebel: [BulletNode] = []
          for bullet in rebelBullets {
              if bullet.isOutOfBounds(sceneWidth: size.width) {
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

          // Imperial bullet hits Rebel ship
          if (a.categoryBitMask == PhysicsCategory.imperialBullet &&
              b.categoryBitMask == PhysicsCategory.rebelShip) ||
             (b.categoryBitMask == PhysicsCategory.imperialBullet &&
              a.categoryBitMask == PhysicsCategory.rebelShip) {

              let bullet = (a.categoryBitMask == PhysicsCategory.imperialBullet
                  ? a.node : b.node) as? BulletNode
              bullet?.removeFromParent()
              if let b = bullet { imperialBullets.removeAll { $0 === b } }
              rebelShip?.takeDamage()
              imperialShip?.addScore()
              run(SKAction.playSoundFileNamed("explosion.mp3", waitForCompletion: false))
              checkGameOver()
          }

          // Rebel bullet hits Imperial ship
          if (a.categoryBitMask == PhysicsCategory.rebelBullet &&
              b.categoryBitMask == PhysicsCategory.imperialShip) ||
             (b.categoryBitMask == PhysicsCategory.rebelBullet &&
              a.categoryBitMask == PhysicsCategory.imperialShip) {

              let bullet = (a.categoryBitMask == PhysicsCategory.rebelBullet
                  ? a.node : b.node) as? BulletNode
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

              if scenePoint.x < size.width / 2 {
                  // Player 1 touch
                  touchOwner[id] = .imperial
                  if imperialJoystick.containsPoint(scenePoint) {
                      let localPoint = CGPoint(x: scenePoint.x - imperialJoystick.position.x,
                                              y: scenePoint.y - imperialJoystick.position.y)
                      imperialJoystick.setThumbOffset(CGVector(dx: localPoint.x, dy: localPoint.y))
                      joystickTouchStart[id] = imperialJoystick.position
                  } else if imperialFireButton.containsPoint(scenePoint) {
                      spawnBullet(player: .imperial)
                  }
              } else {
                  // Player 2 touch — convert to container local space
                  touchOwner[id] = .rebel
                  let localPoint = convert(scenePoint, to: player2Container)
                  if rebelJoystick.containsPoint(localPoint) {
                      let offset = CGPoint(x: localPoint.x - rebelJoystick.position.x,
                                          y: localPoint.y - rebelJoystick.position.y)
                      rebelJoystick.setThumbOffset(CGVector(dx: offset.x, dy: offset.y))
                      joystickTouchStart[id] = rebelJoystick.position
                  } else if rebelFireButton.containsPoint(localPoint) {
                      spawnBullet(player: .rebel)
                  }
              }
          }
      }

      override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
          guard !isGameOver else { return }
          for touch in touches {
              let id = ObjectIdentifier(touch)
              guard let owner = touchOwner[id] else { continue }
              let scenePoint = touch.location(in: self)

              switch owner {
              case .imperial:
                  guard let startPos = joystickTouchStart[id] else { continue }
                  let offset = CGVector(dx: scenePoint.x - startPos.x,
                                       dy: scenePoint.y - startPos.y)
                  imperialJoystick.setThumbOffset(offset)

              case .rebel:
                  guard let startPos = joystickTouchStart[id] else { continue }
                  let localPoint = convert(scenePoint, to: player2Container)
                  let offset = CGVector(dx: localPoint.x - startPos.x,
                                       dy: localPoint.y - startPos.y)
                  rebelJoystick.setThumbOffset(offset)
              }
          }
      }

      // MARK: - Touch ended / cancelled

      override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
          if isGameOver {
              for touch in touches {
                  let point = touch.location(in: self)
                  let nodes = self.nodes(at: point)
                  if nodes.contains(where: { $0.name == "playAgain" }) {
                      let newScene = GameScene(size: size)
                      newScene.scaleMode = scaleMode
                      view?.presentScene(newScene, transition: .fade(withDuration: 0.3))
                      return  // new scene replaces this one; no further cleanup needed
                  }
              }
              // Game over but no play-again tap: fall through to cleanup
          }

          // Always clean up touch state (also runs for in-flight touches when game ends)
          for touch in touches {
              let id = ObjectIdentifier(touch)
              if let owner = touchOwner[id] {
                  switch owner {
                  case .imperial: imperialJoystick.reset()
                  case .rebel:    rebelJoystick.reset()
                  }
              }
              touchOwner.removeValue(forKey: id)
              joystickTouchStart.removeValue(forKey: id)
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
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/GameSceneTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All 11 tests PASS.

- [ ] **Step 5: Build and run on iPad Simulator**

  In Xcode, select an iPad simulator (e.g., iPad 10th generation) and run (`Cmd+R`).
  Verify:
  - Both ships appear on screen, one each side
  - The center divider is visible
  - HUD labels visible on both short sides
  - Joystick and fire button visible in corners

- [ ] **Step 6: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Scenes/GameScene.swift \
          StarWarsBattle/StarWarsBattleTests/GameSceneTests.swift
  git commit -m "feat: implement GameScene with split-screen, touch controls, and game logic"
  ```

---

## Chunk 5: MenuScene & Final Integration

### Task 11: MenuScene

**Files:**
- Create: `StarWarsBattle/StarWarsBattle/Scenes/MenuScene.swift`
- Create: `StarWarsBattle/StarWarsBattleTests/MenuSceneTests.swift`

- [ ] **Step 1: Write failing tests**

  Create `StarWarsBattleTests/MenuSceneTests.swift`:

  ```swift
  import XCTest
  import SpriteKit
  @testable import StarWarsBattle

  final class MenuSceneTests: XCTestCase {

      var scene: MenuScene!

      override func setUp() {
          super.setUp()
          scene = MenuScene(size: CGSize(width: 1180, height: 820))
          let view = SKView(frame: CGRect(x: 0, y: 0, width: 1180, height: 820))
          view.presentScene(scene)
      }

      func testSceneHasTitleLabel() {
          let label = scene.childNode(withName: "//titleLabel")
          XCTAssertNotNil(label, "MenuScene must have a title label")
      }

      func testSceneHasPlayButton() {
          let btn = scene.childNode(withName: "//playButton")
          XCTAssertNotNil(btn, "MenuScene must have a play button")
      }

      func testSceneHasBackground() {
          let bg = scene.childNode(withName: "//menuBackground")
          XCTAssertNotNil(bg, "MenuScene must have a background node")
      }
  }
  ```

- [ ] **Step 2: Run to verify failure**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/MenuSceneTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: Build error — `MenuScene` not found.

- [ ] **Step 3: Create MenuScene.swift**

  ```swift
  import SpriteKit
  import UIKit

  class MenuScene: SKScene {

      override func didMove(to view: SKView) {
          setupBackground()
          setupTitle()
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
          container.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
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
  ```

- [ ] **Step 4: Run tests to verify they pass**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    -only-testing:StarWarsBattleTests/MenuSceneTests \
    2>&1 | grep -E "(PASS|FAIL|error:)"
  ```

  Expected: All 3 tests PASS.

- [ ] **Step 5: Wire MenuScene into GameViewController**

  Update `StarWarsBattle/StarWarsBattle/GameViewController.swift` — replace the placeholder scene with `MenuScene`:

  ```swift
  import UIKit
  import SpriteKit

  class GameViewController: UIViewController {

      override func viewDidLoad() {
          super.viewDidLoad()

          guard let skView = view as? SKView else { return }
          skView.ignoresSiblingOrder = true
          skView.showsFPS = false
          skView.showsNodeCount = false

          let scene = MenuScene(size: skView.bounds.size)
          scene.scaleMode = .resizeFill
          skView.presentScene(scene)
      }

      override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
          return .landscape
      }

      override var prefersStatusBarHidden: Bool {
          return true
      }

      override var shouldAutorotate: Bool {
          return false
      }
  }
  ```

- [ ] **Step 6: Build to confirm no errors**

  ```bash
  xcodebuild build \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    2>&1 | tail -3
  ```

  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

  ```bash
  git add StarWarsBattle/StarWarsBattle/Scenes/MenuScene.swift \
          StarWarsBattle/StarWarsBattle/GameViewController.swift \
          StarWarsBattle/StarWarsBattleTests/MenuSceneTests.swift
  git commit -m "feat: add MenuScene and wire into GameViewController"
  ```

---

### Task 12: End-to-end smoke test on iPad Simulator

- [ ] **Step 1: Run all tests**

  ```bash
  xcodebuild test \
    -project /Users/ethereum/Developer/ldg/StarWarsBattle/StarWarsBattle.xcodeproj \
    -scheme StarWarsBattle \
    -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
    2>&1 | grep -E "(Test Suite|PASS|FAIL|error:)"
  ```

  Expected: All test suites PASS, 0 failures.

- [ ] **Step 2: Launch on iPad Simulator and verify visually**

  Run (`Cmd+R`) on iPad 10th generation simulator. Check:
  - Menu scene loads with background + title + PLAY button
  - Tapping PLAY transitions to game scene
  - Both ships visible in their halves
  - Joystick in bottom-outer corners, fire button in top-outer corners
  - HUD (HP + Score) visible at center of each short edge, rotated to read correctly
  - Joystick moves ship when dragged
  - Fire button spawns a bullet (up to 3 at a time per player)
  - Bullets travel toward the opponent
  - HP decrements on hit; game over overlay appears at 0 HP
  - "PLAY AGAIN" restarts the game

- [ ] **Step 3: Final commit**

  ```bash
  git add .
  git commit -m "feat: complete Star Wars iOS game — split-screen touch controls, SpriteKit"
  ```
