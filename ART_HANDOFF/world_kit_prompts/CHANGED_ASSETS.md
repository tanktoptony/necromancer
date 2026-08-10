# World Kit Consistency Pass

Replaced at native resolution:

- `res://assets/vania11/grave_ash.png` — 20x20
- `res://assets/vania11/flesh_pickup.png` — 20x20
- `res://assets/vania11/railing.png` — 96x40
- `res://assets/vania11/stairs.png` — 96x64
- `res://assets/vania11/rib_gate.png` — 72x220
- `res://assets/vania11/hanging_hook.png` — 40x56
- `res://assets/vania10/map_parchment.png` — 600x330

Added:

- `res://assets/vania10/map_connector_horizontal.png` — 18x18
- `res://assets/vania10/map_connector_vertical.png` — 18x18
- `res://assets/vania10/map_connector_corner.png` — 18x18
- `res://assets/vania10/map_connector_sealed.png` — 18x18

Integration:

- `res://scripts/map_overlay.gd` now renders textured connector sprites instead of procedural `draw_line()` / `draw_circle()` route graphics.
