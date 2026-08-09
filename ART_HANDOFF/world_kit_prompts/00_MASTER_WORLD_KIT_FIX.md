# World-Kit Consistency Fix — Master Handoff

## The problem

The enemy roster (Grave Guard, Lantern Tosser, Hook Brute, Bell Keeper, Bilge
Crawler, Hanged Sailor, Bone Crow, Coffin Mimic — all under
`res://assets/sprites/enemy_types/`) and several world objects
(`bulkhead_door.png`, `platform_module.png`, `platform_trim.png`,
`deck_trim.png`, `bone_urn.png`, `breakable_candle.png`,
`grave_lantern_chunky.png`) are genuinely good, consistent, hand-shaded pixel
art. Keep all of those exactly as they are — do not touch or resubmit them.

A specific handful of other world/pickup/UI assets are NOT pixel art at all —
they're flat, single-tone shapes with no shading or material texture, sitting
right next to the good art in the same rooms. The result reads as two
different games stitched together. This pass exists to bring those specific
assets up to the same bar as the good ones, not to redo anything else.

## The quality bar

Open (or reference) these two files as the target fidelity — chunky, clearly
hand-shaded pixel art with real material read (wood grain, metal highlights,
cloth folds), NOT flat icon shapes:

- `res://assets/vania10/bulkhead_door.png` (40x72)
- `res://assets/vania11/platform_module.png` (128x80)
- Any enemy sprite under `res://assets/sprites/enemy_types/` (96x80 each)

## Hard technical rules (apply to every prompt in this folder)

- Real pixel art: hard edges, deliberate pixel clusters, visible material
  shading (highlight/midtone/shadow bands), not flat single-tone fills and
  not painterly/airbrushed rendering.
- Transparent PNG background.
- Match the EXACT pixel dimensions given in each prompt — the game positions
  and scales these by fixed pixel math, so a resized asset will misalign or
  clip on screen.
- Do not change the filename or add borders/labels/UI chrome.
- Keep the established palette language: warm orange = mundane fire/lantern
  light, violet = necromancy/Grave Hook energy, sickly mint = raised-dead
  state. Don't introduce new hues that clash with those roles.
- Gothic Halloween storybook tone: spooky and characterful, not gory,
  not photoreal, not generic fantasy.

## What's in this folder

| File | Fixes |
|---|---|
| 01_grave_ash_pickup.txt | Currency pickup — currently a flat purple diamond icon |
| 02_flesh_pickup.txt | Health pickup — currently a flat red heart icon |
| 03_railing.txt | Foreground railing — currently a plain rectangle with lines through it |
| 04_stairs.txt | Traversable steps — currently flat color blocks, no material |
| 05_rib_gate.txt | Bone/iron gate obstacle — currently flat, underdetailed vs. the door |
| 06_hanging_hook.txt | Ship-hardware prop — currently thin and underdetailed |
| 07_map_parchment.txt | Map background — currently a plain solid-color rectangle, not parchment at all |
| 08_map_connectors.txt | NEW asset family — map routes are still drawn with procedural lines in code; this has never had real art |

Return each as its own transparent PNG at the exact size specified, plus a
`CHANGED_ASSETS.md` listing the paths.
