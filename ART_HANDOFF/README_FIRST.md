# NECROMANCER: FIRST DAWN — ART HANDOFF

This folder is the contract for the next sprite/environment-art pass.

## Non-negotiable
Do **not** solve production-facing visuals with Godot `Polygon2D`, `ColorRect`, `Line2D`, `_draw()` geometry, CSS-like rectangles, gradients, or programmatically painted placeholder PNGs.

Return actual transparent PNG pixel-art assets that can be dropped into the paths in `ASSET_MANIFEST.csv`.

Procedural primitives remain acceptable only for invisible/debug collision overlays and brief VFX that are not themselves presented as world objects or UI art.

## Current game identity
A gothic action Metroidvania set on a plague/corpse barge. Exploration references Bloodstained / Order of Ecclesia structurally, while the visual tone is a friendlier graveyard-storybook / Halloween gothic. The current character art has chunky Metal Slug-like expressiveness, but the game should **not** inherit Metal Slug pacing.

Dark subject matter is welcome. The world should be spooky, strange, adventurous and occasionally funny rather than relentlessly oppressive.

## Key visual contrast
- Warm orange / candle / fire = mundane living-world light.
- Violet / purple = necromancy, Grave Hook, forbidden artifacts.
- Sickly mint/green = raised-dead energy and follower state.

## Highest-priority character
**Lantern Tosser.** The concept is working and should become one of the first enemies that makes the player think, “I want that corpse in my party.”

Read `SPRITE_PRODUCTION_BRIEF.md`, `INTEGRATION_CONTRACT.md`, and `ASSET_MANIFEST.csv` before producing assets.
