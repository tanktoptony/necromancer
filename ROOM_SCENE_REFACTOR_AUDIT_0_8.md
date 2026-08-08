# Room Scene Refactor Audit — 0.8

## Architecture

PASS — `main.tscn` now runs `barge_room_manager.gd`, not the 0.7 giant-world controller.

PASS — eight major barge compartments are independent `.tscn` scenes under `scenes/barge/`.

PASS — the old continuous `vania_world.gd`, old prototype `main.gd`, and legacy `scenes/rooms/` were removed from the active project.

PASS — every room owns Background, Gameplay, and Foreground nodes.

## Door graph

Validated transition route:

Receiving Hold -> Quarantine Gallery -> Rib Gate -> Hull Breach -> Chain Crypt -> Winch Shaft -> Upper Orlop -> Rib Gate shortcut -> Upper Orlop -> Ossuary Deck.

Every non-final door targets an existing room and an existing named spawn marker in that room.

Horizontal boundaries now use explicit room portals. The Rib Gate hatch and Winch Shaft top use vertical portals.

## Grave Hook

PASS — the room manager asks only the currently loaded room for Hook anchors.

PASS — no global world-space Hook anchor table remains.

PASS — no indoor Hook anchor exceeds 260 pixels of authored range.

PASS — the Winch Shaft uses five short local pulls rather than one long teleport.

PASS — Hook landing points are authored offsets attached to the target ring.

This structurally prevents the 0.7 bug where Q could select a ring in another compartment and drag the player through room boundaries.

## Rib Gate progression

PASS — the Rib Gate is encountered before the Grave Hook.

PASS — the gate scene has a visible floor break / hatch route before the sealed gate.

PASS — returning from the Upper Orlop places the player on the far side of the same gate room.

PASS — gate-open state persists in `GameState`.

## Hull Breach

The old Drowned Hold was replaced by a layered Hull Breach composition:

1. far shoreline / sea
2. damaged hull gameplay plane
3. foreground broken ribs and chains

The normal traversal route uses four visible broken decks. Static audit checks required upward rises and horizontal gaps against the current player jump envelope.

The water is now an explicit local hazard and recovers to room-local safe points.

## Camera

PASS — room entry itself does not run a sightseeing sweep.

PASS — each room owns a camera offset and zoom profile.

PASS — only explicit POI triggers may temporarily bias the camera, and they do not disable player input.

## Encounters

PASS — enemies are instantiated from the current room's local spawn markers.

PASS — leaving a room removes its enemies and projectiles from the scene tree.

PASS — player and raised army persist through transitions and reform at the destination entrance.

This removes cross-room enemy navigation and seam-wedging as a system-level behavior.

## UI / messaging

PASS — non-priority notes are limited to one active plus one queued note.

PASS — corpse availability humor is shown at most once per room entry lifecycle instead of once per corpse.

PASS — room-local tutorial prompts replace giant Hook guide lines; the line is only shown while Q is held or during the first Hook tutorial.

## Reference music

PASS — no copyrighted reference music ships in this package.

The project checks locally for one of:

- `assets/music/reference_water_level.ogg`
- `assets/music/reference_water_level.mp3`
- `assets/music/reference_water_level.wav`

and loops it when present.

## Static audit

`python tools/audit_0_8_room_scenes.py`

PASS — room graph, resource existence, target spawn points, local Hook contracts, Hull Breach jumps, scene layers, script delimiters, duplicate functions, and empty reference-music slot.

Godot runtime execution is not available in the build environment, so engine-level validation remains the first local playtest step.
