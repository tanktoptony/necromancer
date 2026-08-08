# Necromancer: First Dawn — Vania Pass 0.5.2 Playability Audit

## Scope

This pass audits the exact 0.5.1 Collision Pass package that produced the Chain Locker soft-lock screenshot. The audit covers critical-route reachability, hook targeting, world collision, viewport and HUD placement, message behavior, enemy decision-making, follower locomotion, restart state, and resource/script integrity.

## Confirmed 0.5.1 defects

1. **Chain Locker hook soft-lock**
   - Hook selection always chose the nearest available ring.
   - After the first pull, that same ring remained nearest.
   - The next shaft ring therefore never became the active target.
   - The first derived landing coordinate also sat beside, rather than safely above, the visible shelf.

2. **Unsafe hook destination model**
   - Every hook destination was calculated as `ring position + 26px`.
   - This assumed every ring had identical geometry beneath it.
   - Several rings did not have a valid landing surface at that derived point.

3. **Collision mismatch in the shaft**
   - One upper shaft collision platform did not correspond to a clearly walkable visual surface.
   - The Chain Locker had no right-side lower wall, allowing the player to walk into an unbuilt void.

4. **Cramped viewport and HUD overlap**
   - The 384×216 viewport made actors occupy too much of the visible play space.
   - The camera sat 76px above the player, pushing the player toward the bottom message overlay.
   - At the bottom of the world, camera limits forced the player directly behind the message panel.

5. **Message congestion**
   - Short explicit timers overrode the length-based timing system.
   - Priority notes interrupted and requeued active notes, making information appear to flash or repeat.
   - Repeated edge conditions could enqueue the same note every frame.

6. **Weak Grave Hook acquisition**
   - The upgrade used the same toast system as ordinary jokes and combat notes.
   - Combat did not pause, and the pickup had no presentation beat.

7. **Follower “ice skates”**
   - Followers assigned full horizontal speed instantly whenever outside a 13px dead zone.
   - There was no acceleration curve, proportional slowing, or reliable ledge hesitation.
   - Formation targets flipped immediately when the player changed direction.

8. **Enemy behavior remained overly direct**
   - Most archetypes still collapsed toward the player rather than selecting useful positions.
   - Melee enemies had no spacing slots.
   - Enemies did not react to the player beginning an attack.
   - Hopper leaps did not verify a landing surface.
   - Sentry projectiles passed through world collision.

9. **Restart duplication gap**
   - The original dead guard respawned after checkpoint reload even when that guard was already represented in the persisted army.

10. **Optional route range gaps**
    - The Heart Gantry and upper Atrium anchors were outside practical range from their intended approach platforms.

## 0.5.2 corrections

### Critical route and collisions

- Every hook ring now has an explicit safe landing coordinate.
- Hook selection prefers reachable anchors above the player and ignores the landing point already occupied.
- The Chain Locker sequence is now:
  1. Chain floor → lower visible shaft shelf
  2. Lower shelf → upper visible shaft shelf
  3. Upper shelf → Winch Loft floor
- A solid lower-right Chain Locker wall prevents entry into the unbuilt void.
- The invisible third shaft platform was removed.
- The two remaining shaft collisions align with the visible wooden shelves.

### Verified movement envelope

- Jump velocity: 306 px/s
- Gravity: 900 px/s²
- Maximum jump height: **52.0px**
- Flat-ground jump range at full speed: **118.3px**

Drowned Pit route:

- Deck 1 → Deck 2: 54px gap, 29px rise — reachable
- Deck 2 → Deck 3: overlapping footprint, downward — reachable
- Deck 3 → Deck 4: 17px gap, 20px rise — reachable

Hook route:

- Chain floor → Lower Shaft ring: 250.0px / 300px range
- Lower Shaft → Upper Shaft ring: 199.8px / 220px range
- Upper Shaft → Winch Loft ring: 245.6px / 310px range

### Viewport and interface

- Internal viewport increased from 384×216 to **640×360**.
- Window override increased to **1280×720** for a clean 2× scale.
- Camera offset reduced from -76px to -24px.
- Camera bottom limit extends beyond the physical world so lower-room actors remain above the dedicated message strip.
- Notes now occupy an opaque 42px lower HUD strip instead of floating over characters.
- `T` dismisses the current non-critical message.
- Duplicate notes are rejected before entering the queue.
- Minimum practical message durations were increased.
- The map is expanded to 560×320.

### Grave Hook fanfare

- Claiming the Grave Hook pauses player, enemy, and follower physics.
- A full relic acquisition panel, screen flash, title, description, and control reminder are shown.
- After fanfare, a persistent upper-right objective card remains until the first successful hook.
- Prompts name the selected destination, such as `UPPER SHAFT` or `WINCH LOFT`.

### Enemy AI

- Enemies now use PATROL, ALERT, POSITION, WINDUP, ATTACK, RECOVER, BACKSTEP, HURT, and DEAD states.
- Enemies receive combat-slot offsets to reduce stacking.
- Walkers position before entering melee range.
- Chargers establish distance before committing and retreat when crowded.
- Sentries maintain a wider firing distance and reposition in short controlled bursts.
- Hoppers verify a landing surface before committing to a leap.
- Enemies can backstep when the player begins a close-range attack.
- Windups and recovery windows are longer and easier to read.
- Projectiles now collide with the world as well as the player.

### Followers

- Instant full-speed movement was replaced with acceleration and braking.
- Speed scales with distance to the desired formation point.
- Formation direction blends instead of flipping instantly.
- Followers stop and hesitate at ledges.
- Followers only teleport after a sustained navigation failure or excessive separation.
- Combat spacing and attack cadence vary by follower slot.

### State and integrity

- The starting guard has a dedicated persisted state and no longer duplicates after checkpoint reload.
- All `res://` references resolve to files in the package.
- All scripts pass static quote, delimiter, and duplicate-function checks.
- `tools/audit_project.py` reproduces the static integrity and critical-route calculations.

## Remaining prototype risks

- This environment cannot launch the Godot runtime, so engine-level execution remains the final validation step.
- Followers still use local steering and recovery rather than a full navigation graph.
- Hook travel is authored for the current anchor routes rather than generalized arbitrary grappling.
- Collision is still hand-authored against concept-room art and should remain visible through the F3 overlay during testing.
