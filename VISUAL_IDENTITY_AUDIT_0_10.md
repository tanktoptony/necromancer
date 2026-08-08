# Vania Pass 0.10 — Visual Identity & Roster Audit

## Goal
Replace prototype-looking traversal/map artifacts with authored game art while preserving the 0.9.1 room-scene architecture and expanding the enemy roster without widening the scope into another room refactor.

## Implemented
- Purple Grave Lantern replaces abstract Hook-ring visuals.
- Grave Hook pickup receives dedicated lantern/chain relic art.
- One-way collision platforms receive art-derived plank/iron visual lips.
- Door portals use illustrated bulkhead art while retaining existing transition logic.
- Map receives parchment frame, textured room tiles, and illustrated markers.
- Lantern Tosser receives visible lantern accessory.
- Bilge Crawler and Hanged Sailor archetypes added to AI state machine and placed in encounters.

## Intentional constraints
- Room background paintings are not being repainted in this pass.
- Existing enemy base sprite sheet remains the common animation source; archetype silhouette is currently created through scale, palette, movement language and accessories.
- New corpse archetypes use the existing three follower roles for now.
- No copyrighted reference music is included.

## Validation
`audit_0_10_visual_identity.py`, `audit_gdscript_blocks.py`, and the previous 0.9 Raise/Command audit all pass in the packaging environment.
