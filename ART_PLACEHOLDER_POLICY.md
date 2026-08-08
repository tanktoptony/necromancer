# Art Placeholder Policy

Effective after 0.11 feedback:

Production-facing visual objects must use authored raster sprite/pixel assets.

Do not introduce new procedural “CSS-like” art for:
- Hook anchors/relics,
- doors/gates,
- platforms/stairs,
- pickups/breakables,
- map tiles/connectors/markers,
- enemies/followers,
- world props.

Allowed procedural drawing is limited to:
- debug collision visualization,
- temporary hit/slash/selection VFX that are clearly effects rather than objects,
- invisible masks/transition rectangles.

Any procedural VFX that becomes visually prominent should eventually receive sprite/VFX art as well.
