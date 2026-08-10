# Environment Structural Redraw

The player sprites were left unchanged and used as the immutable palette,
pixel-density, silhouette-readability, and shading reference.

## Replaced at native resolution

- `res://assets/vania08/hull_breach_far.png` — 960x360
- `res://assets/vania08/hull_breach_mid.png` — 960x360
- `res://assets/vania08/hull_breach_fore.png` — 960x360
- `res://assets/vania10/bulkhead_door.png` — 40x72
- `res://assets/vania10/platform_lip.png` — 72x24
- `res://assets/vania11/platform_module.png` — 128x80
- `res://assets/vania11/platform_trim.png` — 64x18
- `res://assets/vania11/deck_trim.png` — 64x20
- `res://assets/vania11/railing.png` — 96x40
- `res://assets/vania11/stairs.png` — 96x64
- `res://assets/vania11/rib_gate.png` — 72x220

## Added

- `res://assets/vania12/bulkhead_door_frame.png` — 56x80
- `res://assets/vania12/stairs_large.png` — 144x96

## Integration fixes

- Doors now keep an authored arched frame/opening behind the moving door slab.
- One-way collisions now receive the full 80px platform module, aligned so
  the visible top edge matches the collision top.
- Solid floor trim now hangs below, rather than above, the collision top.
- Gallery, Chain Crypt, and Ossuary Deck railings tile at native pixel scale
  instead of being horizontally stretched.
- Gallery uses a native-resolution 144x96 stair sprite instead of scaling the
  96x64 source by 1.45.
- `BoneProjectile.gravity` was renamed to `gravity_acceleration` to avoid a
  Godot 4.7 `Area2D.gravity` member collision; lantern ballistics and the
  explicit no-spin behavior are unchanged.

## Validation

- All new/replaced PNGs validated for required dimensions and alpha.
- Assets imported successfully in Godot 4.7.1.
- Project completed a 20-frame headless runtime smoke test without errors.
