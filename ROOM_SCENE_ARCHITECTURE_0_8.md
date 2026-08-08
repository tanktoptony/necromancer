# Vania Pass 0.8 — Room Scene Architecture

## Why this refactor exists

The 0.7 barge behaved like a single open world measuring roughly five thousand pixels across. Background panels, collisions, enemies, hook anchors, camera bounds, and progression gates all lived in one large controller. That made room seams visible and allowed systems such as the Grave Hook to reason across spaces that should have been physically separate compartments.

0.8 treats the barge like a Castlevania/Bloodstained structure: individual authored rooms joined by explicit doors and hatches.

## Scene contract

Every major room now contains:

- `Background` — environmental art / far layer
- `Gameplay/Collision` — room-local floor and platform bodies
- `Gameplay/Doors` — explicit portals to named adjacent rooms
- `SpawnPoints` — matching named arrival locations
- `SafePoints` — fall/reform recovery positions
- `EnemySpawns` — local encounter definitions
- `HookAnchors` — room-local traversal targets
- `Foreground` — selective occluding set dressing

The room root stores its title, physical dimensions, camera profile, room intro, and optional point-of-interest camera beat.

## Room manager responsibilities

`barge_room_manager.gd` owns systems that must persist between rooms:

- Player
- Raised army
- Health and upgrade state
- Combat feedback
- UI and map
- Reference music slot
- Room loading and transitions

Enemies and hostile projectiles belong to the instantiated room. Leaving a room removes that encounter from the tree. This prevents off-screen AI accidents and room-seam pathfinding.

## Hook rules

The manager asks only the currently instantiated room for `RoomHookAnchor` nodes. Anchors use local coordinates and authored landing offsets. No global anchor list exists.

Indoor anchors are capped at short ranges in the audit. The Hook therefore behaves as a deliberate traversal tool inside the barge instead of a long-range teleport across rooms.

## Camera rules

Room entry does not take control away for a vista sweep. Each room can define a small default offset/zoom. Rare POI triggers may briefly bias the camera while the player remains controllable.

## Rendering direction

The new Hull Breach demonstrates the intended 2–3 layer format:

1. Far exterior
2. Gameplay hull interior
3. Foreground broken ribs/chains

The remaining rooms are organized into the same Background / Gameplay / Foreground hierarchy even where their existing art is still flattened. Future art replacement can happen room-by-room without changing world coordinates or neighboring collisions.

## Static audit

Run:

`python tools/audit_0_8_room_scenes.py`

It checks room resources, portal targets, target spawn points, local Hook contracts, indoor Hook ranges, Hull Breach jump requirements, required scene layers, script structure, and the empty copyrighted-reference-music slot.
