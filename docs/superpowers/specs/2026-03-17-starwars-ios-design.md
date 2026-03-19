# Star Wars iOS — Design Spec

**Date:** 2026-03-17
**Project:** iOS/Xcode port of [StarWars_rust](https://github.com/SensorEvolve/StarWars_rust)
**Tech:** Swift + SpriteKit (no external dependencies)

---

## Overview

A 1v1 local multiplayer space combat game for **iPad only**. Two players share one device, each holding one short side of the iPad in landscape orientation. Faithful port of the original Rust/ggez game with touch controls replacing keyboard input.

---

## Scenes

| Scene | Purpose |
|-------|---------|
| `MenuScene` | Space background, game title, "Play" button. Transitions to GameScene. |
| `GameScene` | Main game loop. On game over, shows an in-scene overlay with winner text + "Play Again" button that restarts GameScene. |

No separate GameOverScene — the overlay avoids a transition flash.

---

## Game Mechanics

Faithful port of the original:

- **Ships:** Imperial (left half) vs Rebel (right half). Neither can cross the center divider at `sceneWidth / 2`.
- **Health:** 10 HP each.
- **Ship speed:** 300 pt/sec (matches original `SHIP_SPEED = 5.0` at 60 FPS).
- **Initial positions:** Imperial spawns at `(100, sceneHeight/2)` in scene space. Rebel spawns at `(100, sceneHeight/2)` in Player 2 container local space (symmetric).
- **Bullets:** Max 3 active per player. Imperial fires right (red), Rebel fires left (blue). Bullets can cross the center divider freely — only ships are bounded there.
- **Bullet speed:** 600 pt/sec (matches original `BULLET_VEL = 10.0` at 60 FPS).
- **Bullet spawn position:** `(+ship.size.width/2, 0)` in the ship's local coordinate space for both players. For Rebel (inside rotated container), this correctly places the bullet at the visual nose.
- **Bullet despawn:** Removed on hit, or when it exits the scene (`x < 0` or `x > sceneWidth` in scene space).
- **Collision:** AABB via SpriteKit `SKPhysicsBody` contact detection. Hit removes bullet and subtracts 1 HP.
- **Physics categories:**
  ```swift
  struct PhysicsCategory {
      static let imperialShip:  UInt32 = 1 << 0  // 1
      static let rebelShip:     UInt32 = 1 << 1  // 2
      static let imperialBullet: UInt32 = 1 << 2 // 4
      static let rebelBullet:   UInt32 = 1 << 3  // 8
  }
  // imperialBullet.contactTestBitMask = rebelShip
  // rebelBullet.contactTestBitMask = imperialShip
  // collisionBitMask = 0 for all (no physics bounce, contact only)
  ```
- **Score:** +1 per hit landed. Tracked separately from HP.
- **Win condition:** First player to reach 0 HP loses. Game over overlay appears with winner name and "Play Again".
- **Game loop:** 60 FPS via SpriteKit `update(_ currentTime:)`.
- **Sound:** `laser.mp3` on fire, `explosion.mp3` on hit — played via `SKAction.playSoundFileNamed`.

---

## Assets

Sourced directly from the original repo:

| File | Use |
|------|-----|
| `bg_version_2.jpg` | Space background |
| `imperial_spaceship.png` | Imperial ship sprite |
| `rebel_spaceship.png` | Rebel ship sprite |
| `laser.mp3` | Fire sound |
| `explosion.mp3` | Hit sound |

Assets added to the Xcode project's asset catalog.

---

## Orientation & Layout

- **Device:** iPad only. iPhone excluded (control scheme requires two short sides).
- **Orientation:** Landscape only (locked via `Info.plist`).
- **Split:** Vertical — left half (Imperial), right half (Rebel). Center divider: 2 pt wide line at exactly `sceneWidth / 2`.
- **Player position:** Player 1 holds the LEFT short side, Player 2 holds the RIGHT short side.
- **Rotation model:** Player 2's entire half is a single `SKNode` container positioned at the right half's origin with `.zRotation = .pi`. All of Player 2's children (ship, HUD, controls) are specified in that container's **local coordinate space** — no additional per-element rotation needed. Player 1's elements are in default scene space.

---

## Touch Controls

Each player's controls live entirely on their short side — never reaching across the screen.

**Layout per player (from their perspective, holding their short side):**

```
[ FIRE button  ]   ← top corner of short side
[ HP + Score   ]   ← middle of short side (between controllers)
[ Joystick     ]   ← bottom corner of short side
```

**Scene-space coordinates:**

| Element | Player 1 (scene coords) | Player 2 (local coords inside rotated container) |
|---------|------------------------|--------------------------------------------------|
| Fire button | top-left corner | top-left corner of container (= bottom-right in scene) |
| Score/HP | center of left edge | center of left edge of container (= center of right edge in scene) |
| Joystick | bottom-left corner | bottom-left corner of container (= top-right in scene) |

All text labels are rendered in their node's local space — they read correctly because the parent container handles the rotation.

### Touch dispatch
- Touches are split by scene-space x-position at `sceneWidth / 2`.
- Left-half touches (x < center) go to Player 1's joystick and fire button.
- Right-half touches (x ≥ center) are converted into Player 2's container local space via `convert(_:from:)` before hit-testing.

### Joystick behaviour
- Fixed-position virtual joystick (does not follow touch). Touch area radius: **60 pt**.
- Dead-zone radius: **5 pt**. If `touchOffset.length < 5`, treat as zero → ship stops.
- Ship velocity = `normalize(touchOffset) * SHIP_SPEED`. Updated every frame in `update()`.
- Clamped to player's half — cannot cross the center divider.
- Touch released → ship stops immediately.

### Fire button behaviour
- Touch target: **80 × 80 pt** circular hit area.
- Tap spawns one bullet if fewer than 3 active bullets for that player.
- No hold-to-fire — one tap, one bullet.
- Bullet spawns at the ship's nose (leading edge center) in the player's local coordinate space.
- Imperial bullet: initial velocity `(+600, 0)` in scene space (travels right).
- Rebel bullet: initial velocity `(+600, 0)` in Player 2 container's **local** space — because the container is rotated π, this travels **left** in scene space. No special casing needed.

### Multi-touch
- Each half independently tracks its own touches. A touch that starts in one half stays owned by that half for its duration.
- Touch location is obtained in scene space via `touch.location(in: gameScene)`.
- For Player 2 hit-testing, convert the scene-space point into the Player 2 container's local space: `player2Container.convert(scenePoint, from: gameScene)`, then compare against the joystick/fire button positions in that local space.

### Ship sprite orientation
- Both `imperial_spaceship.png` and `rebel_spaceship.png` are drawn **facing right** in their source images.
- Imperial ship: no additional rotation — faces right in scene space (toward Rebel).
- Rebel ship: inside the rotated container (`.zRotation = .pi`), faces right in local space = faces **left** in scene space (toward Imperial). No per-sprite rotation needed.

---

## HUD

On each player's short side, between their two controllers, in the container's local space (automatically readable from that player's perspective):

- Player name (IMPERIAL / REBEL)
- HP (e.g. `HP: 8`)
- Score (e.g. `SCORE: 3`)

---

## Menu Scene

- Space background (`bg_version_2.jpg`)
- Game title: "Star Wars Battle"
- Single "PLAY" button centered on screen

---

## Game Over Overlay

Appears in-scene when a player reaches 0 HP:

- Semi-transparent dark overlay (full screen)
- "GAME OVER" title
- Winner announcement ("Imperial Wins!" / "Rebel Wins!")
- "PLAY AGAIN" button — restarts `GameScene`

---

## Project Structure

```
ldg/
├── ldg.xcodeproj
├── ldg/
│   ├── AppDelegate.swift
│   ├── GameViewController.swift      # Hosts SKView, locks to landscape, iPad only
│   ├── Scenes/
│   │   ├── MenuScene.swift
│   │   └── GameScene.swift
│   ├── Nodes/
│   │   ├── SpaceshipNode.swift       # SKSpriteNode subclass, owns movement logic
│   │   ├── BulletNode.swift          # SKSpriteNode, travels in one direction
│   │   ├── JoystickNode.swift        # Virtual joystick, reports velocity vector
│   │   ├── FireButtonNode.swift      # Tap-to-fire, calls back to GameScene
│   │   └── HUDNode.swift            # HP + score labels, positioned on short side
│   └── Assets.xcassets/
│       ├── bg_version_2.jpg
│       ├── imperial_spaceship.png
│       ├── rebel_spaceship.png
│       └── (sounds bundled in project directly, not asset catalog)
```

---

## Out of Scope

- iPhone support
- Online multiplayer
- AI opponent
- Sound settings / mute toggle
