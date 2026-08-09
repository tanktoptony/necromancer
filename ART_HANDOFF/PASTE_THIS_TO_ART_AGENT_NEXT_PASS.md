# Art Handoff — Next Pass (post-0.11.3)

This supersedes the priority ordering in `PASTE_THIS_TO_ART_AGENT.txt` (that file's P0/P1/P2
enemy roster and world-kit items are now DONE — see `ASSET_MANIFEST.csv`). Read
`README_FIRST.md`, `SPRITE_PRODUCTION_BRIEF.md`, and `INTEGRATION_CONTRACT.md` first; they
still define style, palette, and the 96x80 frame contract. This file only redirects priority
and adds one new hard technical requirement discovered during a 0.11.3 bugfix pass.

---

## PROMPT 1 — Map connector & tile art (highest priority, still outstanding)

```
You are producing UI/map pixel art for a Godot 4.7 gothic-Halloween Metroidvania called
NECROMANCER: FIRST DAWN. Read ART_HANDOFF/README_FIRST.md and
ART_HANDOFF/SPRITE_PRODUCTION_BRIEF.md's "Map art" section before starting.

The runtime map (scripts/map_overlay.gd) currently draws room connector lines with
Godot's draw_line()/draw_circle() — this is placeholder procedural art and violates the
project's no-procedural-production-art rule. It is the single highest-priority remaining
art gap in the project.

Deliver a real connector sprite family to replace it:
- horizontal connector segment
- vertical connector segment
- corner/turn connector (one orientation, to be flipped/rotated at runtime)
- a distinct "gate" connector variant (the route between the Rib Gate and Ossuary Deck
  should visually differ once the gate is open vs. sealed)
- door/threshold marker where a connector meets a room cell

Match the existing parchment/ink map style already in res://assets/vania10/
(map_parchment.png, map_room_explored.png, map_room_current.png, map_player.png,
map_hook.png, map_gate.png, map_heart.png) — chunky pixel-drawn ink-on-parchment linework,
not vector-smooth lines. Cell size is 18x18px; connectors run between adjacent 18px cells,
so segments should tile/align cleanly at that grid.

Return PNGs with transparent backgrounds, a CHANGED_ASSETS.md listing paths, and a contact
sheet preview.
```

## PROMPT 2 — Player attack-pose differentiation

```
You are producing player character pixel art for NECROMANCER: FIRST DAWN (Godot 4.7,
96x80 transparent PNG frame contract, hooded necromancer with a shovel — keep the existing
silhouette, this is an animation-completeness pass, not a redesign).

Read ART_HANDOFF/SPRITE_PRODUCTION_BRIEF.md's "Player art" section first.

Current state: the player has 8 frames (player_0.png..player_7.png) covering idle (0-1),
run (2-4), jump (5), and a single generic attack (6-7). Gameplay code
(scripts/player.gd, scripts/barge_room_manager.gd) already implements FOUR mechanically
distinct player attacks — a 3-hit ground combo, a heavy ground finisher, an anti-air
upward slash, and a downward plunge attack — but all four currently reuse the same
attack_6/attack_7 pose pair, so they're mechanically different but visually identical.

Produce additional frame pairs (windup + release, matching the existing 2-frame attack
cadence) for:
1. Heavy ground finisher — should read as a bigger, more committed swing than the combo.
2. Anti-air slash — shovel/blade angled upward, weight shifted up.
3. Downward plunge — shovel/blade angled down, body compact for a falling strike.

Same 96x80 canvas, same horizontal center (x=48) and foot baseline (y=74) as all existing
player frames. Do not change the idle/run/jump frames.
```

## PROMPT 3 — Thrown lantern projectile (small, optional polish)

```
Small follow-up asset for NECROMANCER: FIRST DAWN. The Lantern Tosser enemy now throws
a projectile that reuses the full world-prop lantern sprite (res://assets/vania/prop_lantern.png,
89x219, includes a mounting chain) as the flying object. It reads fine but the chain segment
was designed for a stationary hanging prop, not a thrown object.

Produce a small dedicated thrown-lantern sprite, roughly 24x24 to 32x32px, transparent
background: the same lantern body/silhouette and warm orange internal glow, without the
long mounting chain (a short broken stub of chain/handle is fine and reads well tumbling
in flight). Match the construction language of the existing lantern asset exactly — this
should look like the same object mid-throw, not a different lantern.
```

## HARD TECHNICAL REQUIREMENT — frame centering (add to every prompt above)

During a 0.11.3+ bugfix pass, several delivered frames were found to be inconsistently
centered within their 96x80 canvas relative to their sibling frames in the same animation
loop (e.g. an idle frame's silhouette sitting 10+ px left/right of its canvas center while
the other idle frame sat dead-center). Because Godot's AnimatedSprite2D draws each frame
centered on the node's fixed position, any such inconsistency makes the character visibly
snap sideways every time that animation loops. Three frames (player attack, walker idle,
walker attack, plain guard idle) had to be corrected this way; all the archetype-specific
enemy sets (lantern_tosser, grave_guard, bilge_crawler, hook_brute, bell_keeper,
hanged_sailor, bone_crow, coffin_mimic) were already fine.

Add this line to every art prompt going forward:

"QA requirement: within any set of frames used together in a single looping/played
animation, the non-transparent silhouette's horizontal center must match across all
frames in that set to within 1-2px. Verify by computing the alpha-channel bounding box
of each frame and comparing its center-x before delivery."
