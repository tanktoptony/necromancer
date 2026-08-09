# Runtime Pixel Conversion — Master Handoff

The following briefs are written against the actual 0.11.3 Godot contract.

Runtime folder: `res://assets/sprites/enemy_types/<archetype>/`
Each enemy must export `enemy_0.png` through `enemy_9.png`, each exactly `96x80`.

## Bilge Crawler decision
Yes: the spider-like concept sheet was intended as Bilge Crawler direction, but it drifted too arachnid. Final canon should be a **humanoid corpse compressed into a crablike crawl**, not a literal spider.

## Current animation mapping (updated post-0.11.3: walk cycle expanded 2 -> 4 frames)
- enemy_0 = dead
- enemy_1 = hurt/rise-react
- enemy_2 = idle A
- enemy_3 = idle B
- enemy_4 = movement A
- enemy_5 = movement B
- enemy_6 = attack windup
- enemy_7 = attack release
- enemy_8 = movement C (continues the stride from 4/5, mirrored side)
- enemy_9 = movement D (completes the 4-pose cycle)

Playback order for movement is 4 -> 5 -> 8 -> 9 -> loop, NOT file order. A 2-frame
walk cycle read as a "shuffle" in playtesting, so every archetype now needs two
additional movement frames continuing the stride/wingbeat/scuttle established in 4/5.

Use the individual prompt files in this folder with the matching image under `../references/`.