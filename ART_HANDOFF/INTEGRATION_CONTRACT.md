# Art Integration Contract

The goal is asset replacement without requiring gameplay-code rewrites.

## Enemy paths
Each enemy's production frames go here:

`res://assets/sprites/enemy_types/<archetype>/enemy_0.png` through `enemy_7.png`

Archetype folders:
- `grave_guard`
- `lantern_tosser`
- `bilge_crawler`
- `hook_brute`
- `bell_keeper`
- `hanged_sailor`
- `bone_crow`
- `coffin_mimic`

All enemy frames: **96×80 REQUIRED** for the current integration pass.

## World-art paths intended for direct replacement
- `res://assets/vania11/grave_lantern_chunky.png`
- `res://assets/vania11/platform_trim.png`
- `res://assets/vania11/deck_trim.png`
- `res://assets/vania11/stairs.png`
- `res://assets/vania11/railing.png`
- `res://assets/vania11/rib_gate.png`
- `res://assets/vania11/breakable_candle.png`
- `res://assets/vania11/bone_urn.png`
- `res://assets/vania11/grave_ash.png`
- `res://assets/vania11/flesh_pickup.png`
- `res://assets/vania11/hanging_hook.png`

The current files in this folder are **temporary placeholders** and should not be treated as style references.

## Map paths
Current map assets are under `res://assets/vania10/`.
A new art agent may replace them in place or provide a complete replacement set with a manifest.

Runtime expects:
- `map_parchment.png` — 600×330
- `map_room_explored.png`
- `map_room_current.png`
- `map_room_hidden.png`
- `map_player.png`
- `map_hook.png`
- `map_gate.png`
- `map_heart.png`

Additional connector textures are strongly desired so `map_overlay.gd` can stop drawing route lines procedurally.

## Hook visual rule
The Grave Lantern is the world object. Do not design a floating reticle as the primary artifact.
The ideal final implementation uses sprite states/glow sprites. Code-drawn circles/arcs are temporary VFX only and should be removable.

## Platform readability rule
If a player can stand on it, the art must communicate a top surface before the collision overlay is enabled.
If a ledge is Grave-Hook-only, its art should visibly differ by position/context, not by arbitrary invisible collision behavior.

## Raised-dead rule
Do not create a generic “friendly guard” replacement for every recruited enemy. Raised followers preserve the hostile archetype silhouette.

## Source control / delivery
Return a ZIP containing only the changed/new files while preserving the relative `res://` folder paths. Also include a `CHANGED_ASSETS.md` listing every path.
