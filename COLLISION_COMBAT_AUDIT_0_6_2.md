# Vania Pass 0.6.2 — Collision & Combat Audit

## Scope

This pass uses the exact 0.6.1 package tested in Godot. No new rooms were added. The work is concentrated on character/world integrity, combat elevations, readable attack commitment, and follower recovery.

## Problems visible in the 0.6.1 playtest

- Followers could fall from the Atrium route and permanently consume or vacate an army slot.
- Followers selected enemies on disconnected vertical levels, then attempted unsafe jumps or corrections.
- Enemies could continue pursuing a target after that target moved to another platform.
- Melee range checks could hit behind an attacker or through world geometry.
- Enemy attacks could change targets after the windup had already begun.
- Several archetypes could crowd one target simultaneously.
- Dead enemies could freeze in midair because collision was disabled immediately on death.
- A single floor-ray hit was treated as enough support, allowing a tiny platform corner to look like a safe lane.

## Collision changes

- Player, enemies, and followers continue to collide only with the world layer.
- Enemy and follower edge detection now requires both near and forward support probes.
- Followers entering an invalid fall or navigation state reform beside the player on a raycast-confirmed floor. Navigation failure no longer removes an army slot.
- Follower loss is now emitted only by actual combat destruction.
- Player ledge assist covers a 13-pixel near-miss window while descending toward a normal platform.
- Dead enemies retain world collision, fall under gravity, and become raisable only once settled.
- Debug drawing updates every frame while F3 is active and includes approximate actor collision outlines.

## Combat changes

- Player attacks require facing, vertical overlap, range, and an unobstructed world ray.
- Enemies commit to the target selected during their telegraph.
- Walkers, Chargers, and Brutes only engage actors on their current combat elevation.
- Sentries may attack across elevations with line-of-sight; Hoppers retain safe cross-level movement.
- One melee enemy per target may wind up or attack at a time. Other enemies position and wait.
- Enemy lane separation prevents active enemies from visually occupying the same spot.
- Chargers sample floor support across the charge path.
- Melee attacks require the target to remain in front at the active frame.
- Light hits do not erase Brute/Charger/elite commitment. Heavy third-combo hits break their poise.
- Raised Guards and Brutes have windup/recovery phases. Raised Sentries retain a clear firing windup.

## Static validation

The included `tools/audit_0_6_2_combat_collision.py` verifies:

- Normal traversal rises and gaps fit the player movement envelope.
- All three actor types retain the world-only collision contract.
- Near/far support probing exists for enemies and followers.
- Navigation failure cannot emit follower loss.
- Enemy target lock, directional melee, charge-floor validation, poise, and corpse settling are present.
- Player attacks use world line-of-sight and hit confirmation.
- All 17 enemy spawns and their full patrol ranges remain on supporting surfaces.
- The two previously problematic room-seam floors remain merged.

All project, 0.6 combat, 0.6.1 traversal, and 0.6.2 collision/combat audits pass in the artifact environment.

## Runtime validation

The artifact environment still cannot execute the Godot editor. The first Godot run should focus on:

1. Following the player through the full Atrium ascent with three servants.
2. Leaving enemies on upper platforms while the player changes elevation.
3. Testing each edge in Follow, Hold, and Assault modes.
4. Killing an airborne Hopper and confirming the corpse falls before the raise prompt appears.
5. Testing a Charger near both the Atrium drop and the Drowned Pit.
6. Swinging across a platform edge to verify attacks do not connect through geometry.
